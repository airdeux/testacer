import 'package:material_ui/material_ui.dart';

import '../../l10n/app_localizations.dart';
import '../auth/auth_models.dart';
import '../auth/auth_service.dart';
import 'centered_panel.dart';
import 'messages.dart';

/// Shown to password accounts until their e-mail address is verified.
class VerifyEmailScreen extends StatefulWidget {
  const VerifyEmailScreen({super.key, required this.auth, required this.user});

  final AuthService auth;
  final AppUser user;

  @override
  State<VerifyEmailScreen> createState() => _VerifyEmailScreenState();
}

class _VerifyEmailScreenState extends State<VerifyEmailScreen> {
  bool _busy = false;
  String? _message;

  Future<void> _run(Future<String?> Function() action) async {
    setState(() {
      _busy = true;
      _message = null;
    });
    String? message;
    try {
      message = await action();
    } on AuthFailure catch (failure) {
      if (mounted) {
        message = authErrorMessage(AppLocalizations.of(context), failure.kind);
      }
    }
    if (mounted) {
      setState(() {
        _busy = false;
        _message = message;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return CenteredPanel(
      children: [
        Text(
          l10n.verifyEmailTitle,
          style: Theme.of(context).textTheme.headlineSmall,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 16),
        Text(l10n.verifyEmailBody(widget.user.email), textAlign: TextAlign.center),
        const SizedBox(height: 24),
        FilledButton(
          onPressed: _busy
              ? null
              : () => _run(() async => await widget.auth.refreshEmailVerified()
                  ? null
                  : l10n.verifyEmailNotYet),
          child: Text(l10n.verifyEmailDone),
        ),
        const SizedBox(height: 8),
        OutlinedButton(
          onPressed: _busy
              ? null
              : () => _run(() async {
                    await widget.auth.sendEmailVerification();
                    return l10n.verifyEmailResent;
                  }),
          child: Text(l10n.verifyEmailResend),
        ),
        TextButton(
          onPressed: _busy ? null : widget.auth.signOut,
          child: Text(l10n.signOut),
        ),
        if (_busy) const LinearProgressIndicator(),
        if (_message != null) Text(_message!, textAlign: TextAlign.center),
      ],
    );
  }
}

/// Signed in, but the address is not on the allowlist (yet).
class NotInvitedScreen extends StatelessWidget {
  const NotInvitedScreen({super.key, required this.auth, required this.user});

  final AuthService auth;
  final AppUser user;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return CenteredPanel(
      children: [
        Text(
          l10n.notInvitedTitle,
          style: Theme.of(context).textTheme.headlineSmall,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 16),
        Text(l10n.notInvitedBody(user.email), textAlign: TextAlign.center),
        const SizedBox(height: 24),
        OutlinedButton(onPressed: auth.signOut, child: Text(l10n.signOut)),
      ],
    );
  }
}

/// The allowlist could not be read (offline, or a rules problem).
class AccessErrorScreen extends StatelessWidget {
  const AccessErrorScreen({
    super.key,
    required this.auth,
    required this.onRetry,
  });

  final AuthService auth;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return CenteredPanel(
      children: [
        Text(
          l10n.accessErrorTitle,
          style: Theme.of(context).textTheme.headlineSmall,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 16),
        Text(l10n.accessErrorBody, textAlign: TextAlign.center),
        const SizedBox(height: 24),
        FilledButton(onPressed: onRetry, child: Text(l10n.retry)),
        TextButton(onPressed: auth.signOut, child: Text(l10n.signOut)),
      ],
    );
  }
}
