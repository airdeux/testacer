import 'package:web/web.dart' as web;

/// Removes the sign-in link parameters from the page address, so reloading
/// the page does not try to use the (already used) link again.
void removeQueryFromUrl() {
  final location = web.window.location;
  final clean = '${location.origin}${location.pathname}${location.hash}';
  web.window.history.replaceState(null, '', clean);
}
