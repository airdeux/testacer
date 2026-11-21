import 'package:material_ui/material_ui.dart';

import '../access/access_repository.dart';
import '../auth/auth_models.dart';
import '../auth/auth_service.dart';
import '../auth/email_link_controller.dart';
import 'centered_panel.dart';
import 'home_screen.dart';
import 'sign_in_screen.dart';
import 'status_screens.dart';

/// Chooses the screen from the sign-in state:
/// signed out → sign-in; unverified password account → verify e-mail;
/// otherwise the access check ([AccessGate]).
class AuthGate extends StatefulWidget {
  const AuthGate({
    super.key,
    required this.auth,
    required this.access,
    required this.emailLinks,
  });

  final AuthService auth;
  final AccessRepository access;
  final EmailLinkController emailLinks;

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  late final Stream<AppUser?> _users = widget.auth.userChanges();

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<AppUser?>(
      stream: _users,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const LoadingScreen();
        }
        final user = snapshot.data;
        if (user == null) {
          return SignInScreen(auth: widget.auth, emailLinks: widget.emailLinks);
        }
        if (user.needsEmailVerification) {
          return VerifyEmailScreen(auth: widget.auth, user: user);
        }
        return AccessGate(
          key: ValueKey(user.email),
          auth: widget.auth,
          access: widget.access,
          user: user,
        );
      },
    );
  }
}

/// Lets the user in only if their address is on the allowlist; switches
/// automatically when the admin invites them.
class AccessGate extends StatefulWidget {
  const AccessGate({
    super.key,
    required this.auth,
    required this.access,
    required this.user,
  });

  final AuthService auth;
  final AccessRepository access;
  final AppUser user;

  @override
  State<AccessGate> createState() => _AccessGateState();
}

class _AccessGateState extends State<AccessGate> {
  late Stream<AccessRole?> _role = widget.access.watchRole(widget.user.email);

  void _retry() =>
      setState(() => _role = widget.access.watchRole(widget.user.email));

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<AccessRole?>(
      stream: _role,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return AccessErrorScreen(auth: widget.auth, onRetry: _retry);
        }
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const LoadingScreen();
        }
        final role = snapshot.data;
        if (role == null) {
          return NotInvitedScreen(auth: widget.auth, user: widget.user);
        }
        return HomeScreen(
          auth: widget.auth,
          access: widget.access,
          user: widget.user,
          role: role,
        );
      },
    );
  }
}
