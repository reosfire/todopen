import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:todopen/services/dropbox_service.dart';

/// Records the requests a service makes so a test can assert on their order
/// and on the bearer token each one carried.
class _Recorder {
  final List<http.BaseRequest> requests = [];

  MockClient client(Future<http.Response> Function(http.Request req) handler) {
    return MockClient((req) async {
      requests.add(req);
      return handler(req);
    });
  }

  Iterable<http.BaseRequest> get tokenRequests =>
      requests.where((r) => r.url.path.contains('oauth2/token'));

  Iterable<http.BaseRequest> get apiRequests =>
      requests.where((r) => !r.url.path.contains('oauth2/token'));

  static String? bearerOf(http.BaseRequest req) =>
      req.headers['Authorization']?.replaceFirst('Bearer ', '');
}

http.Response _tokenOk(String access, {int expiresIn = 14400}) =>
    http.Response(
      jsonEncode({'access_token': access, 'expires_in': expiresIn}),
      200,
    );

bool _isToken(http.BaseRequest req) => req.url.path.contains('oauth2/token');

/// A signed-in session whose access token is still comfortably valid.
void _seedValidSession() {
  SharedPreferences.setMockInitialValues({
    'dbx_access_token': 'stale-token',
    'dbx_refresh_token': 'refresh-token',
    'dbx_expires_at': DateTime.now()
        .add(const Duration(hours: 4))
        .toIso8601String(),
  });
}

/// A session whose access token is already past its recorded expiry.
void _seedExpiredSession() {
  SharedPreferences.setMockInitialValues({
    'dbx_access_token': 'stale-token',
    'dbx_refresh_token': 'refresh-token',
    'dbx_expires_at': DateTime.now()
        .subtract(const Duration(minutes: 1))
        .toIso8601String(),
  });
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('proactive refresh', () {
    test('refreshes before expiry and uses the new token', () async {
      _seedExpiredSession();
      final rec = _Recorder();

      final service = DropboxService(
        httpClient: rec.client((req) async {
          if (_isToken(req)) return _tokenOk('fresh-token');
          return http.Response('{}', 200);
        }),
      );
      await service.init();

      await service.deleteFile('/a');

      expect(rec.tokenRequests, hasLength(1));
      expect(_Recorder.bearerOf(rec.apiRequests.single), 'fresh-token');
      expect(service.authExpired, isFalse);
      expect(service.isSignedIn, isTrue);
    });
  });

  group('reactive refresh on 401', () {
    test('a 401 renews the token and replays the request', () async {
      // The recorded expiry still looks valid, so only the 401 can trigger a
      // refresh. This is the clock-skew / suspended-process case that used to
      // kill sync outright.
      _seedValidSession();
      final rec = _Recorder();

      final service = DropboxService(
        httpClient: rec.client((req) async {
          if (_isToken(req)) return _tokenOk('renewed-token');
          if (_Recorder.bearerOf(req) == 'stale-token') {
            return http.Response('expired_access_token', 401);
          }
          return http.Response('{}', 200);
        }),
      );
      await service.init();

      await service.deleteFile('/a');

      final api = rec.apiRequests.toList();
      expect(api, hasLength(2), reason: 'should replay once after refreshing');
      expect(_Recorder.bearerOf(api[0]), 'stale-token');
      expect(_Recorder.bearerOf(api[1]), 'renewed-token');
      expect(service.authExpired, isFalse);
    });

    test('download returns data rather than throwing after a 401', () async {
      _seedValidSession();
      final rec = _Recorder();

      final service = DropboxService(
        httpClient: rec.client((req) async {
          if (_isToken(req)) return _tokenOk('renewed-token');
          if (_Recorder.bearerOf(req) == 'stale-token') {
            return http.Response('expired_access_token', 401);
          }
          return http.Response.bytes([1, 2, 3], 200);
        }),
      );
      await service.init();

      final bytes = await service.downloadBinaryFile('/manifest');
      expect(bytes, [1, 2, 3]);
    });

    test('concurrent 401s share a single refresh', () async {
      _seedValidSession();
      final rec = _Recorder();

      final service = DropboxService(
        httpClient: rec.client((req) async {
          if (_isToken(req)) {
            // Hold the refresh open so every caller piles up behind it.
            await Future<void>.delayed(const Duration(milliseconds: 40));
            return _tokenOk('renewed-token');
          }
          if (_Recorder.bearerOf(req) == 'stale-token') {
            return http.Response('expired_access_token', 401);
          }
          return http.Response('{}', 200);
        }),
      );
      await service.init();

      await Future.wait([
        service.deleteFile('/a'),
        service.deleteFile('/b'),
        service.deleteFile('/c'),
      ]);

      expect(
        rec.tokenRequests,
        hasLength(1),
        reason: 'the refresh token must be spent once, not once per request',
      );
    });
  });

  group('permanent auth loss', () {
    test('a revoked refresh token signals onAuthLost and throws', () async {
      _seedExpiredSession();
      var lostCalls = 0;

      final service = DropboxService(
        httpClient: MockClient((req) async {
          if (_isToken(req)) {
            return http.Response(jsonEncode({'error': 'invalid_grant'}), 400);
          }
          return http.Response('{}', 200);
        }),
      );
      service.onAuthLost = () => lostCalls++;
      await service.init();

      await expectLater(
        service.deleteFile('/a'),
        throwsA(isA<DropboxAuthException>()),
      );

      expect(lostCalls, 1);
      expect(service.authExpired, isTrue);
      expect(service.isSignedIn, isFalse);
    });

    test('later calls fail fast without more network traffic', () async {
      _seedExpiredSession();
      final rec = _Recorder();
      var lostCalls = 0;

      final service = DropboxService(
        httpClient: rec.client((req) async {
          if (_isToken(req)) {
            return http.Response(jsonEncode({'error': 'invalid_grant'}), 400);
          }
          return http.Response('{}', 200);
        }),
      );
      service.onAuthLost = () => lostCalls++;
      await service.init();

      await expectLater(
        service.deleteFile('/a'),
        throwsA(isA<DropboxAuthException>()),
      );
      final afterFirst = rec.requests.length;

      // This is what used to spin the poll loop every 10 seconds forever.
      for (var i = 0; i < 3; i++) {
        await expectLater(
          service.deleteFile('/b'),
          throwsA(isA<DropboxAuthException>()),
        );
      }

      expect(rec.requests.length, afterFirst);
      expect(lostCalls, 1, reason: 'auth loss is reported once, not per call');
    });
  });

  group('transient refresh failures', () {
    test('a 503 keeps the session instead of signing out', () async {
      _seedExpiredSession();
      var lostCalls = 0;

      final service = DropboxService(
        httpClient: MockClient((req) async {
          if (_isToken(req)) return http.Response('unavailable', 503);
          return http.Response('{}', 200);
        }),
      );
      service.onAuthLost = () => lostCalls++;
      await service.init();

      // The refresh failed, but the existing token may still work, so the
      // request proceeds and the session survives for a later retry.
      await service.deleteFile('/a');

      expect(lostCalls, 0);
      expect(service.authExpired, isFalse);
      expect(service.isSignedIn, isTrue);
    });

    test('a network error during refresh keeps the session', () async {
      _seedExpiredSession();
      var lostCalls = 0;

      final service = DropboxService(
        httpClient: MockClient((req) async {
          if (_isToken(req)) throw const _NetworkFailure();
          return http.Response('{}', 200);
        }),
      );
      service.onAuthLost = () => lostCalls++;
      await service.init();

      await service.deleteFile('/a');

      expect(lostCalls, 0);
      expect(service.isSignedIn, isTrue);
    });
  });

  group('token rotation', () {
    test('a rotated refresh token is persisted', () async {
      _seedExpiredSession();

      final service = DropboxService(
        httpClient: MockClient((req) async {
          if (_isToken(req)) {
            return http.Response(
              jsonEncode({
                'access_token': 'fresh-token',
                'refresh_token': 'rotated-refresh',
                'expires_in': 14400,
              }),
              200,
            );
          }
          return http.Response('{}', 200);
        }),
      );
      await service.init();
      await service.deleteFile('/a');

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('dbx_refresh_token'), 'rotated-refresh');
      expect(prefs.getString('dbx_access_token'), 'fresh-token');
    });

    test('an omitted refresh token leaves the stored one intact', () async {
      _seedExpiredSession();

      final service = DropboxService(
        httpClient: MockClient((req) async {
          if (_isToken(req)) return _tokenOk('fresh-token');
          return http.Response('{}', 200);
        }),
      );
      await service.init();
      await service.deleteFile('/a');

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('dbx_refresh_token'), 'refresh-token');
    });
  });

  group('code verifier lifecycle', () {
    test('a successful exchange stores tokens and drops the verifier', () async {
      SharedPreferences.setMockInitialValues({
        'dbx_code_verifier': 'the-verifier',
      });

      final rec = _Recorder();
      final service = DropboxService(
        httpClient: rec.client((req) async {
          if (_isToken(req)) {
            return http.Response(
              jsonEncode({
                'access_token': 'new-access',
                'refresh_token': 'new-refresh',
                'expires_in': 14400,
              }),
              200,
            );
          }
          return http.Response('{}', 200);
        }),
      );

      expect(await service.handleRedirectCode('auth-code'), isTrue);

      // The verifier reached Dropbox ...
      final body = (rec.tokenRequests.single as http.Request).bodyFields;
      expect(body['code_verifier'], 'the-verifier');
      expect(body['grant_type'], 'authorization_code');

      // ... and is gone afterwards, while the tokens persist.
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('dbx_code_verifier'), isNull);
      expect(prefs.getString('dbx_refresh_token'), 'new-refresh');
      expect(service.isSignedIn, isTrue);
    });

    test('a failed exchange still drops the single-use verifier', () async {
      // The auth code is spent either way, so keeping the verifier would
      // leave a dead secret at rest with nothing able to use it.
      SharedPreferences.setMockInitialValues({
        'dbx_code_verifier': 'the-verifier',
      });

      final service = DropboxService(
        httpClient: MockClient(
          (req) async => http.Response('{"error":"invalid_grant"}', 400),
        ),
      );

      expect(await service.handleRedirectCode('auth-code'), isFalse);

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('dbx_code_verifier'), isNull);
      expect(service.isSignedIn, isFalse);
    });

    test('a redirect with no stored verifier makes no network call', () async {
      SharedPreferences.setMockInitialValues({});

      final rec = _Recorder();
      final service = DropboxService(
        httpClient: rec.client((req) async => http.Response('{}', 200)),
      );

      expect(await service.handleRedirectCode('auth-code'), isFalse);
      expect(rec.requests, isEmpty);
    });
  });
}

/// Stands in for a socket-level failure without importing dart:io, so the
/// suite still runs under the web test runner.
class _NetworkFailure implements Exception {
  const _NetworkFailure();
}
