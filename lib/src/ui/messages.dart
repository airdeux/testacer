import '../../l10n/app_localizations.dart';
import '../access/access_repository.dart';
import '../auth/auth_models.dart';

/// User-facing text for a sign-in problem; `null` when there is nothing to
/// report (the user cancelled). For an unexpected error the original error
/// [code], when known, is shown to help troubleshooting.
String? authErrorMessage(
  AppLocalizations l10n,
  AuthErrorKind kind, [
  String? code,
]) =>
    switch (kind) {
      AuthErrorKind.invalidEmail => l10n.errorInvalidEmail,
      AuthErrorKind.userDisabled => l10n.errorUserDisabled,
      AuthErrorKind.wrongCredentials => l10n.errorWrongCredentials,
      AuthErrorKind.emailInUse => l10n.errorEmailInUse,
      AuthErrorKind.weakPassword => l10n.errorWeakPassword,
      AuthErrorKind.tooManyRequests => l10n.errorTooManyRequests,
      AuthErrorKind.network => l10n.errorNetwork,
      AuthErrorKind.invalidLink => l10n.errorInvalidLink,
      AuthErrorKind.popupBlocked => l10n.errorPopupBlocked,
      AuthErrorKind.notAllowed => l10n.errorNotAllowed,
      AuthErrorKind.accountExists => l10n.errorAccountExists,
      AuthErrorKind.cancelled => null,
      AuthErrorKind.unknown => code == null || code.isEmpty
          ? l10n.errorUnknown
          : l10n.errorUnknownWithCode(code),
    };

String roleLabel(AppLocalizations l10n, AccessRole role) => switch (role) {
      AccessRole.admin => l10n.roleAdmin,
      AccessRole.learner => l10n.roleLearner,
    };
