import 'auth_models.dart';

/// Everything the UI needs from authentication. Implemented with Firebase
/// in `FirebaseAuthService` and with a fake in the tests.
///
/// Failing operations throw [AuthFailure].
abstract interface class AuthService {
  /// The current user, then every change (sign-in, sign-out, refresh).
  Stream<AppUser?> userChanges();

  Future<void> signInWithGoogle();

  Future<void> signInWithPassword(String email, String password);

  /// Creates a password account and sends the verification e-mail.
  Future<void> registerWithPassword(String email, String password);

  Future<void> sendPasswordReset(String email);

  /// Sends a passwordless sign-in link to [email].
  Future<void> sendSignInLink(String email);

  /// Whether [link] is a sign-in link sent by [sendSignInLink].
  bool isSignInLink(String link);

  Future<void> signInWithLink(String email, String link);

  Future<void> sendEmailVerification();

  /// Reloads the user from the server and refreshes the ID token.
  /// Returns whether the e-mail address is verified now.
  Future<bool> refreshEmailVerified();

  Future<void> signOut();
}
