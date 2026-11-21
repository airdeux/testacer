import 'dart:async';

import 'package:flutter/foundation.dart';

import 'auth_models.dart';
import 'auth_service.dart';
import 'email_link_store.dart';

enum EmailLinkStatus {
  /// No sign-in link is being handled.
  idle,

  /// Signing in with a received link.
  signingIn,

  /// A link arrived, but the address it was sent to is unknown on this
  /// device; the UI asks for it and calls [EmailLinkController.completeWithEmail].
  needsEmail,

  /// Signing in with the link failed; see [EmailLinkController.error].
  failed,
}

/// Sends passwordless sign-in links and completes sign-in when such a link
/// opens the app (Android App Link) or the web page.
class EmailLinkController extends ChangeNotifier {
  EmailLinkController({
    required this._auth,
    required this._store,
    required this._links,
    this._onSignInLink,
  });

  final AuthService _auth;
  final EmailLinkStore _store;
  final Stream<Uri> _links;
  final void Function()? _onSignInLink;
  StreamSubscription<Uri>? _subscription;
  String? _pendingLink;

  EmailLinkStatus _status = EmailLinkStatus.idle;
  EmailLinkStatus get status => _status;

  AuthErrorKind? _error;
  AuthErrorKind? get error => _error;

  /// Starts listening for incoming links (the initial link included).
  void start() {
    _subscription ??= _links.listen((uri) => unawaited(handleLink(uri)));
  }

  /// Sends a sign-in link and remembers the address on this device.
  Future<void> sendLink(String email) async {
    final address = normalizeEmail(email);
    await _auth.sendSignInLink(address);
    await _store.write(address);
  }

  /// Handles one incoming link; other links are ignored.
  Future<void> handleLink(Uri uri) async {
    final link = uri.toString();
    if (!_auth.isSignInLink(link)) return;
    _onSignInLink?.call();
    final email = await _store.read();
    if (email == null) {
      _pendingLink = link;
      _setStatus(EmailLinkStatus.needsEmail);
      return;
    }
    await _complete(email, link);
  }

  /// Completes a pending link with the address typed by the user.
  Future<void> completeWithEmail(String email) async {
    final link = _pendingLink;
    if (link == null) return;
    await _complete(normalizeEmail(email), link);
  }

  /// Forgets a pending or failed link.
  void dismiss() {
    _pendingLink = null;
    _error = null;
    _setStatus(EmailLinkStatus.idle);
  }

  Future<void> _complete(String email, String link) async {
    _error = null;
    _setStatus(EmailLinkStatus.signingIn);
    try {
      await _auth.signInWithLink(email, link);
      await _store.clear();
      _pendingLink = null;
      _setStatus(EmailLinkStatus.idle);
    } on AuthFailure catch (failure) {
      _error = failure.kind;
      _setStatus(EmailLinkStatus.failed);
    }
  }

  void _setStatus(EmailLinkStatus status) {
    _status = status;
    notifyListeners();
  }

  @override
  void dispose() {
    unawaited(_subscription?.cancel());
    super.dispose();
  }
}
