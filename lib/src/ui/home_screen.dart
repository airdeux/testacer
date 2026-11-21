import 'package:material_ui/material_ui.dart';

import '../../l10n/app_localizations.dart';
import '../access/access_repository.dart';
import '../auth/auth_models.dart';
import '../auth/auth_service.dart';
import 'centered_panel.dart';
import 'invitations_screen.dart';
import 'messages.dart';

/// Start page after sign-in. The quiz arrives in Phase 3.
class HomeScreen extends StatelessWidget {
  const HomeScreen({
    super.key,
    required this.auth,
    required this.access,
    required this.user,
    required this.role,
  });

  final AuthService auth;
  final AccessRepository access;
  final AppUser user;
  final AccessRole role;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return CenteredPanel(
      appBar: AppBar(
        title: Text(l10n.appTitle),
        actions: [
          if (role == AccessRole.admin)
            IconButton(
              tooltip: l10n.invitationsTitle,
              icon: const Icon(Icons.group_add_outlined),
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => InvitationsScreen(
                    access: access,
                    currentEmail: user.email,
                  ),
                ),
              ),
            ),
          IconButton(
            tooltip: l10n.signOut,
            icon: const Icon(Icons.logout),
            onPressed: auth.signOut,
          ),
        ],
      ),
      children: [
        Text(
          l10n.homeGreeting(user.greetingName),
          style: Theme.of(context).textTheme.headlineSmall,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        Center(child: Chip(label: Text(roleLabel(l10n, role)))),
        const SizedBox(height: 24),
        Text(l10n.homeComingSoon, textAlign: TextAlign.center),
      ],
    );
  }
}
