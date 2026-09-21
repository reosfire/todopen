import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:crypto/crypto.dart';
import 'package:todopen/global_constants.dart';
import 'package:url_launcher/url_launcher.dart';
import 'web_auth.dart' as web_auth;

class DropboxService {
  /// HTTP client, injectable so tests can drive the token/401 paths.
  final http.Client _http;

  DropboxService({http.Client? httpClient})
    : _http = httpClient ?? http.Client();

  // ── Token storage keys ──
  static const _keyAccessToken = 'dbx_access_token';
  static const _keyRefreshToken = 'dbx_refresh_token';
  static const _keyExpiresAt = 'dbx_expires_at';
  static const _keyCodeVerifier = 'dbx_code_verifier';

  String? _accessToken;
  String? _refreshToken;
  DateTime? _expiresAt;

  bool get isSignedIn => _accessToken != null;

  /// Set when the refresh token itself is rejected (revoked, or the app's
  /// access was removed). Sync cannot recover without a fresh interactive
  /// sign-in, so callers must stop retrying and prompt the user.
  bool _authExpired = false;
  bool get authExpired => _authExpired;

  /// Invoked once when authentication is permanently lost, so the app can
  /// stop its poll loop and tell the user instead of failing silently.
  void Function()? onAuthLost;

  /// De-duplicates concurrent refreshes: the sync engine fires several
  /// requests in parallel, and without this each one would race to spend the
  /// same refresh token.
  Future<bool>? _refreshInFlight;

  // ───── Initialise ─────

  /// Loads saved tokens and, on web, finishes any pending OAuth redirect.
  Future<void> init() async {
    await _loadTokens();

    // On web, check if Dropbox just redirected us back with a code.
    final code = web_auth.getAuthCodeFromUrl();
    if (code != null) {
      web_auth.clearUrlAuthCode();

      if (web_auth.isInPopup()) {
        // Running inside the OAuth popup — relay the code to the parent window
        // via BroadcastChannel and close this popup.
        web_auth.sendCodeToOpenerAndClose(code);
        return;
      }

      // Fallback: same-tab redirect (mobile deep-link, or legacy web flow).
      final verifier = await _loadCodeVerifier();
      if (verifier != null) {
        await _exchangeCode(code, verifier);
      }
    }
  }

  // ───── Sign-in / out ─────

  /// Opens the Dropbox OAuth page — in a popup on web, or an external browser
  /// on mobile.  On web, waits until the popup relays the auth code back.
  Future<void> signIn() async {
    final verifier = _generateCodeVerifier();
    final challenge = _generateCodeChallenge(verifier);
    await _saveCodeVerifier(verifier);

    final redirectUri = _redirectUri;
    final uri = Uri.https('www.dropbox.com', '/oauth2/authorize', {
      'client_id': dropboxAppKey,
      'response_type': 'code',
      'code_challenge': challenge,
      'code_challenge_method': 'S256',
      'redirect_uri': redirectUri,
      'token_access_type': 'offline',
    });

    if (kIsWeb) {
      final code = await web_auth.openAuthPopupAndWaitForCode(uri.toString());
      if (code != null) {
        final codeVerifier = await _loadCodeVerifier();
        if (codeVerifier != null) {
          await _exchangeCode(code, codeVerifier);
        }
      }
    } else {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  /// Called on mobile when the app receives the redirect with the auth code.
  Future<bool> handleRedirectCode(String code) async {
    final verifier = await _loadCodeVerifier();
    if (verifier == null) return false;
    return _exchangeCode(code, verifier);
  }

  Future<void> signOut() async {
    _accessToken = null;
    _refreshToken = null;
    _expiresAt = null;
    _authExpired = false;
    _refreshInFlight = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyAccessToken);
    await prefs.remove(_keyRefreshToken);
    await prefs.remove(_keyExpiresAt);
    await prefs.remove(_keyCodeVerifier);
  }

  // ───── Retry with exponential backoff ─────

  static const _maxRetries = 5;
  static const _initialDelayMs = 500;
  static const _maxDelayMs = 30000;
  final _rng = Random();

  bool _isRetryable(int statusCode) =>
      statusCode == 429 || // rate limit
      statusCode == 500 ||
      statusCode == 502 ||
      statusCode == 503 ||
      statusCode == 507;

  /// Executes [request] with up to [_maxRetries] retries using exponential
  /// backoff + jitter.  The first attempt fires immediately.
  ///
  /// After exhausting retries it returns the last response as-is.
  Future<http.Response> _retryWithBackoff(
    Future<http.Response> Function() request, {
    bool retryOn409 = true,
  }) async {
    late http.Response response;
    for (var attempt = 0; attempt <= _maxRetries; attempt++) {
      if (attempt > 0) {
        final baseDelay = (_initialDelayMs * (1 << (attempt - 1))).clamp(
          0,
          _maxDelayMs,
        );
        final jitter = (baseDelay * 0.25 * (2 * _rng.nextDouble() - 1)).round();
        final delay = (baseDelay + jitter).clamp(0, _maxDelayMs);
        await Future.delayed(Duration(milliseconds: delay));
      }
      try {
        response = await request();
      } catch (e) {
        // Network-level error (DNS, socket, TLS …).
        if (attempt == _maxRetries) rethrow;
        debugPrint('Dropbox request error (attempt $attempt): $e');
        continue;
      }
      if (!_isRetryable(response.statusCode) || attempt == _maxRetries) {
        return response;
      }
      if (response.statusCode == 409 && !retryOn409) return response;
      debugPrint(
        'Dropbox retryable ${response.statusCode} – '
        'retry ${attempt + 1}/$_maxRetries',
      );
    }
    return response;
  }

  /// Issue an authenticated POST with token refresh and retry/backoff.
  ///
  /// Exposed so the sync layer can add endpoints (conditional upload,
  /// batch delete) without duplicating auth handling.
  ///
  /// [retryOn409] must be false for conditional writes: there a 409 means
  /// "you lost the compare-and-swap", and retrying with the same stale rev
  /// would just fail again while hiding the conflict from the caller.
  Future<http.Response> sendAuthorized(
    Uri url, {
    Map<String, String> extraHeaders = const {},
    List<int>? body,
    bool retryOn409 = true,
  }) {
    return _authorizedPost(
      url,
      extraHeaders: extraHeaders,
      body: body,
      retryOn409: retryOn409,
    );
  }

  /// The single path every authenticated request takes.
  ///
  /// Expiry is handled twice, deliberately:
  ///
  /// 1. *Proactively*, via [_ensureValidToken], which refreshes shortly before
  ///    the recorded expiry. This is the common case and costs no failed
  ///    requests.
  /// 2. *Reactively*, on a 401. The recorded expiry is only a local guess: the
  ///    device clock can be wrong, the process can be suspended past the
  ///    deadline, and Dropbox can invalidate a token early. When that happens
  ///    the token is refreshed once and the request replayed, so a recoverable
  ///    expiry never surfaces to the caller as a failure.
  ///
  /// The retry budget in [_retryWithBackoff] is per-attempt, so a 401 refresh
  /// does not consume it.
  Future<http.Response> _authorizedPost(
    Uri url, {
    Map<String, String> extraHeaders = const {},
    List<int>? body,
    bool retryOn409 = true,
  }) async {
    await _ensureValidToken();

    Future<http.Response> attempt() => _retryWithBackoff(
      () => _http.post(
        url,
        headers: {'Authorization': 'Bearer $_accessToken', ...extraHeaders},
        body: body,
      ),
      retryOn409: retryOn409,
    );

    final response = await attempt();
    if (response.statusCode != 401) return response;

    // The access token was rejected despite looking valid locally. Refresh
    // once and replay; a second 401 means the problem is not the token's age.
    if (!await _refreshAccessToken()) {
      throw DropboxAuthException(
        'Dropbox authentication expired and could not be renewed',
      );
    }
    final retried = await attempt();
    if (retried.statusCode == 401) {
      _markAuthExpired();
      throw DropboxAuthException('Dropbox rejected the renewed access token');
    }
    return retried;
  }

  // ───── File operations ─────

  Future<void> uploadBinaryFile(String remotePath, List<int> bytes) async {
    final response = await _authorizedPost(
      Uri.parse('https://content.dropboxapi.com/2/files/upload'),
      extraHeaders: {
        'Content-Type': 'application/octet-stream',
        'Dropbox-API-Arg': jsonEncode({
          'path': remotePath,
          'mode': 'overwrite',
          'autorename': false,
          'mute': true,
        }),
      },
      body: bytes,
    );

    if (response.statusCode != 200) {
      throw Exception(
        'Dropbox upload failed (${response.statusCode}): '
        '${response.body}',
      );
    }
  }

  /// Download [remotePath] as raw bytes. Returns `null` when the file does
  /// not exist (Dropbox 409 / path not found).
  Future<Uint8List?> downloadBinaryFile(String remotePath) async {
    final response = await _authorizedPost(
      Uri.parse('https://content.dropboxapi.com/2/files/download'),
      extraHeaders: {
        'Dropbox-API-Arg': jsonEncode({'path': remotePath}),
      },
    );

    if (response.statusCode == 409) return null;
    if (response.statusCode != 200) {
      throw Exception(
        'Dropbox download failed (${response.statusCode}): '
        '${response.body}',
      );
    }

    return response.bodyBytes;
  }

  /// Delete the file at [remotePath]. Silently succeeds if the file does
  /// not exist.
  Future<void> deleteFile(String remotePath) async {
    final response = await _authorizedPost(
      Uri.parse('https://api.dropboxapi.com/2/files/delete_v2'),
      extraHeaders: {'Content-Type': 'application/json'},
      body: utf8.encode(jsonEncode({'path': remotePath})),
    );

    // Ignore "not found" – the file is already gone.
    if (response.statusCode == 409) return;
    if (response.statusCode != 200) {
      throw Exception(
        'Dropbox delete failed (${response.statusCode}): '
        '${response.body}',
      );
    }
  }

  /// Download a subfolder as a zip archive.
  /// [folderPath] must be a non-root path (e.g. `/tasks`).
  /// Returns the raw bytes of the zip, or `null` on error / empty folder.
  Future<List<int>?> downloadFolderZip(String folderPath) async {
    final response = await _authorizedPost(
      Uri.parse('https://content.dropboxapi.com/2/files/download_zip'),
      extraHeaders: {
        'Dropbox-API-Arg': jsonEncode({'path': folderPath}),
      },
    );

    // 409 means the folder doesn't exist (no entities of that type yet).
    if (response.statusCode == 409) return null;
    if (response.statusCode != 200) {
      debugPrint(
        'Dropbox download_zip failed (${response.statusCode}): '
        '${response.body}',
      );
      return null;
    }

    return response.bodyBytes;
  }

  // ───── Folder cursor & longpoll ─────

  /// Get a cursor for the app folder's current state using
  /// `list_folder/get_latest_cursor`.  The cursor can later be passed to
  /// [longpollForChanges].
  Future<String?> getLatestCursor() async {
    final response = await _authorizedPost(
      Uri.parse(
        'https://api.dropboxapi.com/2/files/list_folder/get_latest_cursor',
      ),
      extraHeaders: {'Content-Type': 'application/json'},
      body: utf8.encode(
        jsonEncode({'path': '', 'recursive': true, 'include_deleted': false}),
      ),
    );

    if (response.statusCode != 200) {
      debugPrint(
        'get_latest_cursor failed (${response.statusCode}): '
        '${response.body}',
      );
      return null;
    }

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    return data['cursor'] as String?;
  }

  /// Long-poll Dropbox for changes.  Blocks for up to [timeout] seconds
  /// (30-480, default 120).  Returns `true` when remote files have changed,
  /// `false` on timeout, and `null` on error (e.g. cursor reset).
  Future<bool?> longpollForChanges(String cursor, {int timeout = 120}) async {
    try {
      final response = await _http
          .post(
            Uri.parse(
              'https://notify.dropboxapi.com/2/files/list_folder/longpoll',
            ),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({'cursor': cursor, 'timeout': timeout}),
          )
          .timeout(Duration(seconds: timeout + 120));

      if (response.statusCode != 200) {
        debugPrint(
          'longpoll failed (${response.statusCode}): '
          '${response.body}',
        );
        return null;
      }

      final data = jsonDecode(response.body) as Map<String, dynamic>;
      return data['changes'] as bool? ?? false;
    } catch (e) {
      debugPrint('longpoll error: $e');
      return null;
    }
  }

  // ───── PKCE helpers ─────

  String _generateCodeVerifier() {
    const chars =
        'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789-._~';
    final rng = Random.secure();
    return List.generate(128, (_) => chars[rng.nextInt(chars.length)]).join();
  }

  String _generateCodeChallenge(String verifier) {
    final bytes = utf8.encode(verifier);
    final digest = sha256.convert(bytes);
    return base64UrlEncode(digest.bytes).replaceAll('=', '');
  }

  // ───── Token management ─────

  String get _redirectUri {
    if (kIsWeb) {
      return web_auth.getAppRedirectUri();
    }
    return 'todopen://auth';
  }

  Future<bool> _exchangeCode(String code, String codeVerifier) async {
    final response = await _http.post(
      Uri.parse('https://api.dropboxapi.com/oauth2/token'),
      headers: {'Content-Type': 'application/x-www-form-urlencoded'},
      body: {
        'code': code,
        'grant_type': 'authorization_code',
        'client_id': dropboxAppKey,
        'redirect_uri': _redirectUri,
        'code_verifier': codeVerifier,
      },
    );

    // The auth code is single-use, so this verifier can never be replayed
    // whatever the outcome. Drop it now rather than leaving it at rest until
    // the next sign-out.
    await _clearCodeVerifier();

    if (response.statusCode != 200) {
      debugPrint('Dropbox token exchange failed: ${response.body}');
      return false;
    }

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    _accessToken = data['access_token'] as String;
    _refreshToken = data['refresh_token'] as String?;
    final expiresIn = data['expires_in'] as int? ?? 14400;
    _expiresAt = DateTime.now().add(Duration(seconds: expiresIn));
    await _saveTokens();
    return true;
  }

  /// Exchange the refresh token for a new access token.
  ///
  /// Returns true when the access token was renewed. Concurrent callers share
  /// one in-flight request rather than each spending the refresh token.
  Future<bool> _refreshAccessToken() {
    if (_refreshToken == null) return Future.value(false);
    return _refreshInFlight ??= _doRefresh().whenComplete(() {
      _refreshInFlight = null;
    });
  }

  Future<bool> _doRefresh() async {
    final http.Response response;
    try {
      response = await _http.post(
        Uri.parse('https://api.dropboxapi.com/oauth2/token'),
        headers: {'Content-Type': 'application/x-www-form-urlencoded'},
        body: {
          'grant_type': 'refresh_token',
          'refresh_token': _refreshToken!,
          'client_id': dropboxAppKey,
        },
      );
    } catch (e) {
      // Offline, DNS failure, TLS error … The refresh token is still good, so
      // keep it and let the caller retry later.
      debugPrint('Dropbox token refresh error (will retry): $e');
      return false;
    }

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      _accessToken = data['access_token'] as String;
      // Dropbox may rotate the refresh token; keep the old one when it does
      // not, since dropping it would strand us at the next expiry.
      _refreshToken = data['refresh_token'] as String? ?? _refreshToken;
      final expiresIn = data['expires_in'] as int? ?? 14400;
      _expiresAt = DateTime.now().add(Duration(seconds: expiresIn));
      _authExpired = false;
      await _saveTokens();
      return true;
    }

    // Only a 400/401 with an invalid-grant error means the refresh token is
    // genuinely dead. Anything else (429, 5xx) is transient, and discarding
    // the refresh token there would sign the user out over a blip — which is
    // what used to happen for every non-200.
    if (_isInvalidGrant(response)) {
      debugPrint('Dropbox refresh token rejected: ${response.body}');
      _markAuthExpired();
      return false;
    }

    debugPrint(
      'Dropbox token refresh failed transiently '
      '(${response.statusCode}): ${response.body}',
    );
    return false;
  }

  /// True when Dropbox says the grant itself is bad, rather than that it is
  /// busy or broken.
  bool _isInvalidGrant(http.Response response) {
    if (response.statusCode != 400 && response.statusCode != 401) return false;
    try {
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final error = data['error'];
      final tag = error is String
          ? error
          : (error is Map ? error['.tag'] : null);
      return tag == 'invalid_grant' || tag == 'invalid_request';
    } catch (_) {
      // Unparseable body on a 400/401: treat as fatal, since we have no
      // evidence it is transient and retrying forever is worse.
      return true;
    }
  }

  /// Latch permanent auth loss and notify the app exactly once. The tokens are
  /// cleared because they are now useless, but the notification is what stops
  /// the sync loop from retrying into a wall.
  void _markAuthExpired() {
    if (_authExpired) return;
    _authExpired = true;
    _accessToken = null;
    _refreshToken = null;
    _expiresAt = null;
    unawaited(_clearPersistedTokens());
    onAuthLost?.call();
  }

  /// Drop the stored tokens without touching [_authExpired] — unlike
  /// [signOut], which is a deliberate user action and clears the latch.
  Future<void> _clearPersistedTokens() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_keyAccessToken);
      await prefs.remove(_keyRefreshToken);
      await prefs.remove(_keyExpiresAt);
    } catch (e) {
      debugPrint('Clearing Dropbox tokens failed: $e');
    }
  }

  Future<void> _ensureValidToken() async {
    if (_authExpired) {
      throw DropboxAuthException('Dropbox sign-in has expired');
    }
    if (_accessToken == null) throw Exception('Not signed in to Dropbox');
    if (_expiresAt != null &&
        DateTime.now().isAfter(
          _expiresAt!.subtract(const Duration(minutes: 5)),
        )) {
      // A failure here is not fatal on its own: the token may still work, and
      // if it does not the 401 path will refresh and replay.
      await _refreshAccessToken();
      if (_authExpired) {
        throw DropboxAuthException('Dropbox sign-in has expired');
      }
    }
  }

  // ───── Persistence ─────

  Future<void> _saveTokens() async {
    final prefs = await SharedPreferences.getInstance();
    if (_accessToken != null) {
      await prefs.setString(_keyAccessToken, _accessToken!);
    }
    if (_refreshToken != null) {
      await prefs.setString(_keyRefreshToken, _refreshToken!);
    }
    if (_expiresAt != null) {
      await prefs.setString(_keyExpiresAt, _expiresAt!.toIso8601String());
    }
  }

  Future<void> _loadTokens() async {
    final prefs = await SharedPreferences.getInstance();
    _accessToken = prefs.getString(_keyAccessToken);
    _refreshToken = prefs.getString(_keyRefreshToken);
    final exp = prefs.getString(_keyExpiresAt);
    if (exp != null) _expiresAt = DateTime.parse(exp);
  }

  Future<void> _saveCodeVerifier(String verifier) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyCodeVerifier, verifier);
  }

  Future<String?> _loadCodeVerifier() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyCodeVerifier);
  }

  Future<void> _clearCodeVerifier() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_keyCodeVerifier);
    } catch (e) {
      // Never let losing the verifier fail a sign-in that otherwise worked.
      debugPrint('Clearing Dropbox code verifier failed: $e');
    }
  }
}

/// Thrown when Dropbox authentication is gone and cannot be renewed without
/// the user signing in again. Distinct from a transient network or API error
/// so the sync layer can stop retrying and surface it instead.
class DropboxAuthException implements Exception {
  final String message;
  const DropboxAuthException(this.message);

  @override
  String toString() => 'DropboxAuthException: $message';
}
