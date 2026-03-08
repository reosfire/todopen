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
/// https://reosfire.github.io/Todoonya or http://localhost:8080
String getAppRedirectUri() {
  final origin = web.window.location.origin;
  if (origin.contains("github.io")) {
    return '$origin/Todoonya';
  } else {
    return "http://localhost:8080";
  }
}
