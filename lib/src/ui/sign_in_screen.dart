import 'package:material_ui/material_ui.dart';

import '../../l10n/app_localizations.dart';
import '../auth/auth_models.dart';
import '../auth/auth_service.dart';
import '../auth/email_link_controller.dart';
import 'centered_panel.dart';
import 'messages.dart';

/// Sign-in with Google, e-mail + password, or a passwordless e-mail link.
class SignInScreen extends StatefulWidget {
  const SignInScreen({super.key, required this.auth, required this.emailLinks});

  final AuthService auth;
  final EmailLinkController emailLinks;

  @override
  State<SignInScreen> createState() => _SignInScreenState();
}

class _SignInScreenState extends State<SignInScreen> {
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _linkEmail = TextEditingController();
  bool _obscure = true;
  bool _busy = false;
  String? _emailError;
  String? _passwordError;
  String? _info;
  String? _error;

  AppLocalizations get _l10n => AppLocalizations.of(context);

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    _linkEmail.dispose();
    super.dispose();
  }

  /// Validates the fields an action needs; returns the normalised e-mail.
  String? _validate({required bool needsPassword, bool newPassword = false}) {
    final email = _email.text.trim();
    final password = _password.text;
    setState(() {
      _emailError = email.isEmpty
          ? _l10n.emailRequired
          : (isValidEmail(email) ? null : _l10n.emailInvalid);
      _passwordError = !needsPassword
          ? null
          : password.isEmpty
              ? _l10n.passwordRequired
              : (newPassword && password.length < 6
                  ? _l10n.passwordTooShort
                  : null);
    });
    if (_emailError != null || _passwordError != null) return null;
    return normalizeEmail(email);
  }

  Future<void> _run(Future<void> Function() action, {String? onSuccess}) async {
    setState(() {
      _busy = true;
      _info = null;
      _error = null;
    });
    try {
      await action();
      if (mounted && onSuccess != null) setState(() => _info = onSuccess);
    } on AuthFailure catch (failure) {
      if (mounted) setState(() => _error = authErrorMessage(_l10n, failure.kind));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _google() => _run(widget.auth.signInWithGoogle);

  void _signIn() {
    final email = _validate(needsPassword: true);
    if (email == null) return;
    _run(() => widget.auth.signInWithPassword(email, _password.text));
  }

  void _register() {
    final email = _validate(needsPassword: true, newPassword: true);
    if (email == null) return;
    _run(() => widget.auth.registerWithPassword(email, _password.text));
  }

  void _resetPassword() {
    final email = _validate(needsPassword: false);
    if (email == null) return;
    _run(
      () => widget.auth.sendPasswordReset(email),
      onSuccess: _l10n.passwordResetSent(email),
    );
  }

  void _sendLink() {
    final email = _validate(needsPassword: false);
    if (email == null) return;
    _run(
      () => widget.emailLinks.sendLink(email),
      onSuccess: _l10n.signInLinkSent(email),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = _l10n;
    final theme = Theme.of(context);
    return CenteredPanel(
      children: [
        Text(
          l10n.appTitle,
          style: theme.textTheme.headlineMedium,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 4),
        Text(
          l10n.signInTitle,
          style: theme.textTheme.titleMedium,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 24),
        ListenableBuilder(
          listenable: widget.emailLinks,
          builder: (context, _) => _EmailLinkPanel(
            controller: widget.emailLinks,
            emailField: _linkEmail,
          ),
        ),
        FilledButton.icon(
          onPressed: _busy ? null : _google,
          icon: const Icon(Icons.account_circle_outlined),
          label: Text(l10n.signInWithGoogle),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            const Expanded(child: Divider()),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Text(l10n.orDivider),
            ),
            const Expanded(child: Divider()),
          ],
        ),
        const SizedBox(height: 16),
        TextField(
          controller: _email,
          keyboardType: TextInputType.emailAddress,
          autofillHints: const [AutofillHints.email],
          textInputAction: TextInputAction.next,
          decoration: InputDecoration(
            labelText: l10n.emailLabel,
            errorText: _emailError,
            border: const OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _password,
          obscureText: _obscure,
          autofillHints: const [AutofillHints.password],
          onSubmitted: (_) => _busy ? null : _signIn(),
          decoration: InputDecoration(
            labelText: l10n.passwordLabel,
            errorText: _passwordError,
            border: const OutlineInputBorder(),
            suffixIcon: IconButton(
              tooltip: _obscure ? l10n.showPassword : l10n.hidePassword,
              icon: Icon(_obscure ? Icons.visibility : Icons.visibility_off),
              onPressed: () => setState(() => _obscure = !_obscure),
            ),
          ),
        ),
        const SizedBox(height: 12),
        FilledButton.tonal(
          onPressed: _busy ? null : _signIn,
          child: Text(l10n.signInWithPassword),
        ),
        Wrap(
          alignment: WrapAlignment.spaceBetween,
          children: [
            TextButton(
              onPressed: _busy ? null : _register,
              child: Text(l10n.register),
            ),
            TextButton(
              onPressed: _busy ? null : _resetPassword,
              child: Text(l10n.forgotPassword),
            ),
          ],
        ),
        const SizedBox(height: 8),
        OutlinedButton.icon(
          onPressed: _busy ? null : _sendLink,
          icon: const Icon(Icons.mail_outline),
          label: Text(l10n.sendSignInLink),
        ),
        const SizedBox(height: 16),
        if (_busy) const LinearProgressIndicator(),
        if (_info != null) Text(_info!, textAlign: TextAlign.center),
        if (_error != null)
          Text(
            _error!,
            textAlign: TextAlign.center,
            style: TextStyle(color: theme.colorScheme.error),
          ),
      ],
    );
  }
}

/// Shows the state of an incoming sign-in link above the sign-in options.
class _EmailLinkPanel extends StatelessWidget {
  const _EmailLinkPanel({required this.controller, required this.emailField});

  final EmailLinkController controller;
  final TextEditingController emailField;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final Widget content;
    switch (controller.status) {
      case EmailLinkStatus.idle:
        return const SizedBox.shrink();
      case EmailLinkStatus.signingIn:
        content = Row(
          children: [
            const SizedBox.square(
              dimension: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
            const SizedBox(width: 12),
            Expanded(child: Text(l10n.signingInWithLink)),
          ],
        );
      case EmailLinkStatus.needsEmail:
        content = Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(l10n.linkNeedsEmailTitle, style: theme.textTheme.titleMedium),
            const SizedBox(height: 8),
            Text(l10n.linkNeedsEmailBody),
            const SizedBox(height: 12),
            TextField(
              controller: emailField,
              keyboardType: TextInputType.emailAddress,
              decoration: InputDecoration(
                labelText: l10n.emailLabel,
                border: const OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 8),
            OverflowBar(
              alignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: controller.dismiss,
                  child: Text(l10n.cancelButton),
                ),
                FilledButton(
                  onPressed: () => controller.completeWithEmail(emailField.text),
                  child: Text(l10n.continueButton),
                ),
              ],
            ),
          ],
        );
      case EmailLinkStatus.failed:
        content = Row(
          children: [
            Expanded(
              child: Text(
                authErrorMessage(l10n, controller.error ?? AuthErrorKind.unknown) ??
                    l10n.errorUnknown,
                style: TextStyle(color: theme.colorScheme.error),
              ),
            ),
            IconButton(
              tooltip: l10n.cancelButton,
              icon: const Icon(Icons.close),
              onPressed: controller.dismiss,
            ),
          ],
        );
    }
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Card(
        child: Padding(padding: const EdgeInsets.all(16), child: content),
      ),
    );
  }
}
