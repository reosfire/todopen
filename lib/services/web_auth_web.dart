import 'dart:async';
import 'dart:js_interop';
import 'package:web/web.dart' as web;

/// On web, reads the `code` query parameter from the current URL.
/// Returns null if no code is present.
String? getAuthCodeFromUrl() {
  final uri = Uri.parse(web.window.location.href);
  return uri.queryParameters['code'];
}

/// Removes the `code` query param from the browser URL bar
/// without reloading the page.
void clearUrlAuthCode() {
  final uri = Uri.parse(web.window.location.href);
  final cleanParams = Map<String, String>.from(uri.queryParameters)
    ..remove('code');
  final cleanUri = uri.replace(
    queryParameters: cleanParams.isEmpty ? null : cleanParams,
  );
  final cleanUrl = cleanUri.toString();
  web.window.history.replaceState(''.toJSBox, '', cleanUrl);
}

/// Returns the base URL of the app (origin + base path).
/// https://reosfire.github.io/todopen or http://localhost:8080
String getAppRedirectUri() {
  final origin = web.window.location.origin;
  if (origin.contains("github.io")) {
    return '$origin/todopen';
  } else {
    return "http://localhost:8080";
  }
}

/// Returns true when this page was opened as a popup (has a window.opener).
bool isInPopup() => web.window.opener != null;

/// Sends [code] to the opener window via BroadcastChannel, then closes the popup.
void sendCodeToOpenerAndClose(String code) {
  final channel = web.BroadcastChannel('dropbox_oauth');
  channel.postMessage('dropbox_code:$code'.toJS);
  channel.close();
  web.window.close();
}

/// Opens [authUrl] in a popup and returns a Future that completes with the
/// OAuth code once the popup relays it back, or null if cancelled / blocked.
Future<String?> openAuthPopupAndWaitForCode(String authUrl) {
  final completer = Completer<String?>();
  final channel = web.BroadcastChannel('dropbox_oauth');

  final popup = web.window.open(
    authUrl,
    'dropbox_auth',
    'width=600,height=700,scrollbars=yes,resizable=yes',
  );

  if (popup == null) {
    // Popup was blocked by the browser.
    channel.close();
    completer.complete(null);
    return completer.future;
  }

  late web.EventListener jsListener;
  late Timer pollTimer;

  void cleanup() {
    channel.removeEventListener('message', jsListener);
    channel.close();
    pollTimer.cancel();
  }

  jsListener = ((web.Event event) {
    final msg = event as web.MessageEvent;
    final data = msg.data;
    if (data == null || !data.isA<JSString>()) return;
    final str = (data as JSString).toDart;
    if (!str.startsWith('dropbox_code:')) return;
    final code = str.substring('dropbox_code:'.length);
    cleanup();
    completer.complete(code);
  }).toJS as web.EventListener;

  channel.addEventListener('message', jsListener);

  // Detect popup closed by the user without completing auth.
  pollTimer = Timer.periodic(const Duration(seconds: 1), (_) {
    if (popup.closed) {
      cleanup();
      if (!completer.isCompleted) completer.complete(null);
    }
  });

  return completer.future;
}
