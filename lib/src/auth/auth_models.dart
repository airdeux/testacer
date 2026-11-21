/// The signed-in user, independent of Firebase types.
class AppUser {
  const AppUser({
    required this.uid,
    required this.email,
    required this.emailVerified,
    required this.usesPassword,
    this.displayName,
  });

  final String uid;

  /// Lower-case e-mail address.
  final String email;

  final String? displayName;
  final bool emailVerified;

  /// True if the account has the e-mail/password provider. Accounts created
  /// with a password must verify their e-mail before they get access.
  final bool usesPassword;

  bool get needsEmailVerification => usesPassword && !emailVerified;

  /// Display name, or the part of the e-mail address before the `@`.
  String get greetingName {
    final name = displayName?.trim() ?? '';
    return name.isNotEmpty ? name : email.split('@').first;
  }
}

/// Sign-in problems the UI can explain to the user.
enum AuthErrorKind {
  invalidEmail,
  userDisabled,
  wrongCredentials,
  emailInUse,
  weakPassword,
  tooManyRequests,
  network,
  invalidLink,
  popupBlocked,
  notAllowed,
  accountExists,

  /// The user closed the Google window; nothing to report.
  cancelled,
  unknown,
}

/// Thrown by an `AuthService` when an operation fails.
class AuthFailure implements Exception {
  const AuthFailure(this.kind, [this.code]);

  final AuthErrorKind kind;

  /// The original error code, for logs.
  final String? code;

  @override
  String toString() => 'AuthFailure(${kind.name}${code == null ? '' : ', $code'})';
}

/// Maps a Firebase Authentication error code to an [AuthErrorKind].
AuthErrorKind authErrorKindFromCode(String code) => switch (code) {
      'invalid-email' || 'missing-email' => AuthErrorKind.invalidEmail,
      'user-disabled' => AuthErrorKind.userDisabled,
      'user-not-found' ||
      'wrong-password' ||
      'invalid-credential' ||
      'invalid-login-credentials' =>
        AuthErrorKind.wrongCredentials,
      'email-already-in-use' => AuthErrorKind.emailInUse,
      'weak-password' => AuthErrorKind.weakPassword,
      'too-many-requests' => AuthErrorKind.tooManyRequests,
      'network-request-failed' => AuthErrorKind.network,
      'invalid-action-code' ||
      'expired-action-code' =>
        AuthErrorKind.invalidLink,
      'popup-blocked' => AuthErrorKind.popupBlocked,
      'operation-not-allowed' => AuthErrorKind.notAllowed,
      'account-exists-with-different-credential' ||
      'credential-already-in-use' =>
        AuthErrorKind.accountExists,
      'popup-closed-by-user' ||
      'cancelled-popup-request' ||
      'web-context-canceled' ||
      'web-context-cancelled' =>
        AuthErrorKind.cancelled,
      _ => AuthErrorKind.unknown,
    };

/// Trims and lower-cases an e-mail address, as stored in the allowlist.
String normalizeEmail(String email) => email.trim().toLowerCase();

final _emailPattern = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');

/// A light syntax check; Firebase does the real validation.
bool isValidEmail(String email) => _emailPattern.hasMatch(email.trim());
