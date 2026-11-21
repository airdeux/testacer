import 'package:material_ui/material_ui.dart';

import '../../l10n/app_localizations.dart';
import '../access/access_repository.dart';
import '../auth/auth_models.dart';
import 'messages.dart';

/// Admin page: invite users and revoke invitations.
class InvitationsScreen extends StatefulWidget {
  const InvitationsScreen({
    super.key,
    required this.access,
    required this.currentEmail,
  });

  final AccessRepository access;

  /// The admin's own address, which cannot be revoked here.
  final String currentEmail;

  @override
  State<InvitationsScreen> createState() => _InvitationsScreenState();
}

class _InvitationsScreenState extends State<InvitationsScreen> {
  final _email = TextEditingController();
  late final Stream<List<Invitation>> _invitations =
      widget.access.watchInvitations();
  AccessRole _role = AccessRole.learner;
  String? _emailError;
  bool _busy = false;

  @override
  void dispose() {
    _email.dispose();
    super.dispose();
  }

  void _showMessage(String text) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));

  Future<void> _invite() async {
    final l10n = AppLocalizations.of(context);
    final email = normalizeEmail(_email.text);
    setState(() {
      _emailError = email.isEmpty
          ? l10n.emailRequired
          : (isValidEmail(email) ? null : l10n.emailInvalid);
    });
    if (_emailError != null) return;
    setState(() => _busy = true);
    try {
      await widget.access.invite(email, _role);
      _email.clear();
      _showMessage(l10n.invited(email));
    } on Exception {
      _showMessage(l10n.errorUnknown);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _revoke(Invitation invitation) async {
    final l10n = AppLocalizations.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.revokeConfirmTitle),
        content: Text(l10n.revokeConfirmBody(invitation.email)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(l10n.cancelButton),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(l10n.revokeButton),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      await widget.access.revoke(invitation.email);
    } on Exception {
      _showMessage(l10n.errorUnknown);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(l10n.invitationsTitle)),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 560),
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                TextField(
                  controller: _email,
                  keyboardType: TextInputType.emailAddress,
                  onSubmitted: (_) => _busy ? null : _invite(),
                  decoration: InputDecoration(
                    labelText: l10n.inviteEmailLabel,
                    errorText: _emailError,
                    border: const OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                SegmentedButton<AccessRole>(
                  segments: [
                    for (final role in AccessRole.values)
                      ButtonSegment(value: role, label: Text(roleLabel(l10n, role))),
                  ],
                  selected: {_role},
                  onSelectionChanged: (selection) =>
                      setState(() => _role = selection.single),
                ),
                const SizedBox(height: 12),
                FilledButton.icon(
                  onPressed: _busy ? null : _invite,
                  icon: const Icon(Icons.person_add_alt),
                  label: Text(l10n.inviteButton),
                ),
                const SizedBox(height: 24),
                StreamBuilder<List<Invitation>>(
                  stream: _invitations,
                  builder: (context, snapshot) {
                    if (snapshot.hasError) return Text(l10n.errorUnknown);
                    final invitations = snapshot.data;
                    if (invitations == null) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    if (invitations.isEmpty) return Text(l10n.noInvitations);
                    return Column(
                      children: [
                        for (final invitation in invitations)
                          _InvitationTile(
                            invitation: invitation,
                            isSelf: invitation.email == widget.currentEmail,
                            onRevoke: () => _revoke(invitation),
                          ),
                      ],
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _InvitationTile extends StatelessWidget {
  const _InvitationTile({
    required this.invitation,
    required this.isSelf,
    required this.onRevoke,
  });

  final Invitation invitation;
  final bool isSelf;
  final VoidCallback onRevoke;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return ListTile(
      title: Text(isSelf ? '${invitation.email} ${l10n.youLabel}' : invitation.email),
      subtitle: Text(roleLabel(l10n, invitation.role)),
      trailing: IconButton(
        tooltip: l10n.revokeTooltip,
        icon: const Icon(Icons.person_remove_outlined),
        onPressed: isSelf ? null : onRevoke,
      ),
    );
  }
}
