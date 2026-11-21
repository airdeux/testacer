import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../config.dart';
import 'auth_models.dart';
import 'auth_service.dart';

/// [AuthService] backed by Firebase Authentication.
///
/// Google sign-in uses a popup on the web and the `google_sign_in` plugin on
/// Android (its server client ID comes from `google-services.json`).
class FirebaseAuthService implements AuthService {
  FirebaseAuthService({FirebaseAuth? auth})
      : _auth = auth ?? FirebaseAuth.instance;

  final FirebaseAuth _auth;
  final _refreshed = StreamController<AppUser?>.broadcast();
  Future<void>? _googleInit;

  @override
  Stream<AppUser?> userChanges() {
    StreamSubscription<User?>? fromFirebase;
    StreamSubscription<AppUser?>? fromRefresh;
    late final StreamController<AppUser?> controller;
    controller = StreamController<AppUser?>(
      onListen: () {
        fromFirebase = _auth.userChanges().listen(
              (user) => controller.add(_toAppUser(user)),
              onError: controller.addError,
            );
        fromRefresh = _refreshed.stream.listen(controller.add);
      },
      onCancel: () async {
        await fromFirebase?.cancel();
        await fromRefresh?.cancel();
      },
    );
    return controller.stream;
  }

  @override
  Future<void> signInWithGoogle() => _guard(() async {
        if (kIsWeb) {
          await _auth.signInWithPopup(GoogleAuthProvider());
          return;
        }
        await (_googleInit ??= GoogleSignIn.instance.initialize());
        final account = await GoogleSignIn.instance.authenticate();
        final credential = GoogleAuthProvider.credential(
          idToken: account.authentication.idToken,
        );
        await _auth.signInWithCredential(credential);
      });

  @override
  Future<void> signInWithPassword(String email, String password) =>
      _guard(() => _auth.signInWithEmailAndPassword(
            email: email,
            password: password,
          ));

  @override
  Future<void> registerWithPassword(String email, String password) =>
      _guard(() async {
        final result = await _auth.createUserWithEmailAndPassword(
          email: email,
          password: password,
        );
        await result.user?.sendEmailVerification();
      });

  @override
  Future<void> sendPasswordReset(String email) =>
      _guard(() => _auth.sendPasswordResetEmail(email: email));

  @override
  Future<void> sendSignInLink(String email) => _guard(
        () => _auth.sendSignInLinkToEmail(
          email: email,
          actionCodeSettings: ActionCodeSettings(
            url: _continueUrl(),
            handleCodeInApp: true,
            androidPackageName: androidPackageName,
            androidInstallApp: true,
            androidMinimumVersion: '1',
            // No linkDomain: Firebase uses the default Hosting domain
            // (testacer-892b3.firebaseapp.com) and rejects it when it is set
            // explicitly (INVALID_HOSTING_LINK_DOMAIN).
          ),
        ),
      );

  @override
  bool isSignInLink(String link) => _auth.isSignInWithEmailLink(link);

  @override
  Future<void> signInWithLink(String email, String link) =>
      _guard(() => _auth.signInWithEmailLink(email: email, emailLink: link));

  @override
  Future<void> sendEmailVerification() =>
      _guard(() async => _auth.currentUser?.sendEmailVerification());

  @override
  Future<bool> refreshEmailVerified() => _guard(() async {
        await _auth.currentUser?.reload();
        final user = _auth.currentUser;
        if (user == null || !user.emailVerified) return false;
        // Security rules read `email_verified` from the ID token.
        await user.getIdToken(true);
        _refreshed.add(_toAppUser(user));
        return true;
      });

  @override
  Future<void> signOut() => _guard(() async {
        if (_googleInit != null) await GoogleSignIn.instance.signOut();
        await _auth.signOut();
      });

  /// Where a sign-in link leads back to: the current page on the web
  /// (also `localhost` during development), the GitHub Pages app otherwise.
  String _continueUrl() {
    if (!kIsWeb) return webAppUrl;
    final base = Uri.base;
    return Uri(
      scheme: base.scheme,
      host: base.host,
      port: base.hasPort ? base.port : null,
      path: base.path,
    ).toString();
  }

  static AppUser? _toAppUser(User? user) {
    if (user == null) return null;
    return AppUser(
      uid: user.uid,
      email: normalizeEmail(user.email ?? ''),
      displayName: user.displayName,
      emailVerified: user.emailVerified,
      usesPassword: user.providerData.any((p) => p.providerId == 'password'),
    );
  }

  static Future<T> _guard<T>(Future<T> Function() action) async {
    try {
      return await action();
    } on FirebaseAuthException catch (e) {
      throw AuthFailure(authErrorKindFromCode(e.code), e.code);
    } on GoogleSignInException catch (e) {
      throw AuthFailure(
        e.code == GoogleSignInExceptionCode.canceled
            ? AuthErrorKind.cancelled
            : AuthErrorKind.unknown,
        e.code.name,
      );
    }
  }
}
