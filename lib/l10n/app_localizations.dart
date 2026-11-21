import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_hu.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[Locale('hu')];

  /// No description provided for @appTitle.
  ///
  /// In hu, this message translates to:
  /// **'TestAcer'**
  String get appTitle;

  /// No description provided for @signInTitle.
  ///
  /// In hu, this message translates to:
  /// **'Bejelentkezés'**
  String get signInTitle;

  /// No description provided for @signInWithGoogle.
  ///
  /// In hu, this message translates to:
  /// **'Belépés Google-fiókkal'**
  String get signInWithGoogle;

  /// No description provided for @orDivider.
  ///
  /// In hu, this message translates to:
  /// **'vagy'**
  String get orDivider;

  /// No description provided for @emailLabel.
  ///
  /// In hu, this message translates to:
  /// **'E-mail-cím'**
  String get emailLabel;

  /// No description provided for @passwordLabel.
  ///
  /// In hu, this message translates to:
  /// **'Jelszó'**
  String get passwordLabel;

  /// No description provided for @showPassword.
  ///
  /// In hu, this message translates to:
  /// **'Jelszó megjelenítése'**
  String get showPassword;

  /// No description provided for @hidePassword.
  ///
  /// In hu, this message translates to:
  /// **'Jelszó elrejtése'**
  String get hidePassword;

  /// No description provided for @signInWithPassword.
  ///
  /// In hu, this message translates to:
  /// **'Belépés jelszóval'**
  String get signInWithPassword;

  /// No description provided for @register.
  ///
  /// In hu, this message translates to:
  /// **'Regisztráció'**
  String get register;

  /// No description provided for @forgotPassword.
  ///
  /// In hu, this message translates to:
  /// **'Elfelejtett jelszó'**
  String get forgotPassword;

  /// No description provided for @sendSignInLink.
  ///
  /// In hu, this message translates to:
  /// **'Belépési link küldése e-mailben'**
  String get sendSignInLink;

  /// No description provided for @signInLinkSent.
  ///
  /// In hu, this message translates to:
  /// **'Elküldtük a belépési linket ide: {email}. Ezen az eszközön nyisd meg.'**
  String signInLinkSent(String email);

  /// No description provided for @passwordResetSent.
  ///
  /// In hu, this message translates to:
  /// **'Elküldtük a jelszó-visszaállító levelet ide: {email}.'**
  String passwordResetSent(String email);

  /// No description provided for @emailRequired.
  ///
  /// In hu, this message translates to:
  /// **'Add meg az e-mail-címed.'**
  String get emailRequired;

  /// No description provided for @emailInvalid.
  ///
  /// In hu, this message translates to:
  /// **'Ez nem érvényes e-mail-cím.'**
  String get emailInvalid;

  /// No description provided for @passwordRequired.
  ///
  /// In hu, this message translates to:
  /// **'Add meg a jelszavad.'**
  String get passwordRequired;

  /// No description provided for @passwordTooShort.
  ///
  /// In hu, this message translates to:
  /// **'A jelszó legalább 6 karakter legyen.'**
  String get passwordTooShort;

  /// No description provided for @linkNeedsEmailTitle.
  ///
  /// In hu, this message translates to:
  /// **'Melyik címre kérted a linket?'**
  String get linkNeedsEmailTitle;

  /// No description provided for @linkNeedsEmailBody.
  ///
  /// In hu, this message translates to:
  /// **'A linket másik eszközön vagy böngészőben kérted. Add meg ugyanazt az e-mail-címet.'**
  String get linkNeedsEmailBody;

  /// No description provided for @continueButton.
  ///
  /// In hu, this message translates to:
  /// **'Tovább'**
  String get continueButton;

  /// No description provided for @cancelButton.
  ///
  /// In hu, this message translates to:
  /// **'Mégse'**
  String get cancelButton;

  /// No description provided for @signingInWithLink.
  ///
  /// In hu, this message translates to:
  /// **'Belépés a linkkel…'**
  String get signingInWithLink;

  /// No description provided for @errorInvalidEmail.
  ///
  /// In hu, this message translates to:
  /// **'Érvénytelen e-mail-cím.'**
  String get errorInvalidEmail;

  /// No description provided for @errorUserDisabled.
  ///
  /// In hu, this message translates to:
  /// **'Ez a fiók le van tiltva.'**
  String get errorUserDisabled;

  /// No description provided for @errorWrongCredentials.
  ///
  /// In hu, this message translates to:
  /// **'Hibás e-mail-cím vagy jelszó.'**
  String get errorWrongCredentials;

  /// No description provided for @errorEmailInUse.
  ///
  /// In hu, this message translates to:
  /// **'Ezzel a címmel már van fiók. Lépj be, vagy kérj belépési linket.'**
  String get errorEmailInUse;

  /// No description provided for @errorWeakPassword.
  ///
  /// In hu, this message translates to:
  /// **'Túl gyenge jelszó (legalább 6 karakter).'**
  String get errorWeakPassword;

  /// No description provided for @errorTooManyRequests.
  ///
  /// In hu, this message translates to:
  /// **'Túl sok próbálkozás. Várj egy kicsit, és próbáld újra.'**
  String get errorTooManyRequests;

  /// No description provided for @errorNetwork.
  ///
  /// In hu, this message translates to:
  /// **'Nincs internetkapcsolat.'**
  String get errorNetwork;

  /// No description provided for @errorInvalidLink.
  ///
  /// In hu, this message translates to:
  /// **'A link érvénytelen vagy lejárt. Kérj újat.'**
  String get errorInvalidLink;

  /// No description provided for @errorPopupBlocked.
  ///
  /// In hu, this message translates to:
  /// **'A böngésző letiltotta a felugró ablakot. Engedélyezd, és próbáld újra.'**
  String get errorPopupBlocked;

  /// No description provided for @errorNotAllowed.
  ///
  /// In hu, this message translates to:
  /// **'Ez a belépési mód nincs bekapcsolva.'**
  String get errorNotAllowed;

  /// No description provided for @errorAccountExists.
  ///
  /// In hu, this message translates to:
  /// **'Ehhez a címhez másik belépési mód tartozik. Lépj be azzal.'**
  String get errorAccountExists;

  /// No description provided for @errorUnknown.
  ///
  /// In hu, this message translates to:
  /// **'Váratlan hiba történt. Próbáld újra.'**
  String get errorUnknown;

  /// No description provided for @verifyEmailTitle.
  ///
  /// In hu, this message translates to:
  /// **'Erősítsd meg az e-mail-címed'**
  String get verifyEmailTitle;

  /// No description provided for @verifyEmailBody.
  ///
  /// In hu, this message translates to:
  /// **'Küldtünk egy megerősítő levelet ide: {email}. Kattints a benne lévő linkre, majd nyomd meg a „Megerősítettem” gombot.'**
  String verifyEmailBody(String email);

  /// No description provided for @verifyEmailDone.
  ///
  /// In hu, this message translates to:
  /// **'Megerősítettem'**
  String get verifyEmailDone;

  /// No description provided for @verifyEmailResend.
  ///
  /// In hu, this message translates to:
  /// **'Újraküldés'**
  String get verifyEmailResend;

  /// No description provided for @verifyEmailResent.
  ///
  /// In hu, this message translates to:
  /// **'Újra elküldtük a megerősítő levelet.'**
  String get verifyEmailResent;

  /// No description provided for @verifyEmailNotYet.
  ///
  /// In hu, this message translates to:
  /// **'Még nincs megerősítve. Nézd meg a levélszemét mappát is.'**
  String get verifyEmailNotYet;

  /// No description provided for @signOut.
  ///
  /// In hu, this message translates to:
  /// **'Kijelentkezés'**
  String get signOut;

  /// No description provided for @notInvitedTitle.
  ///
  /// In hu, this message translates to:
  /// **'Még nincs meghívásod'**
  String get notInvitedTitle;

  /// No description provided for @notInvitedBody.
  ///
  /// In hu, this message translates to:
  /// **'A(z) {email} címmel még nincs meghívásod. Kérd meg az adminisztrátort, hogy hívjon meg – utána ez az oldal magától továbblép.'**
  String notInvitedBody(String email);

  /// No description provided for @accessErrorTitle.
  ///
  /// In hu, this message translates to:
  /// **'Nem sikerült ellenőrizni a hozzáférést'**
  String get accessErrorTitle;

  /// No description provided for @accessErrorBody.
  ///
  /// In hu, this message translates to:
  /// **'Ellenőrizd az internetkapcsolatot, és próbáld újra.'**
  String get accessErrorBody;

  /// No description provided for @retry.
  ///
  /// In hu, this message translates to:
  /// **'Újra'**
  String get retry;

  /// No description provided for @homeGreeting.
  ///
  /// In hu, this message translates to:
  /// **'Szia, {name}!'**
  String homeGreeting(String name);

  /// No description provided for @homeComingSoon.
  ///
  /// In hu, this message translates to:
  /// **'A gyakorlás a következő fejlesztési lépésben érkezik.'**
  String get homeComingSoon;

  /// No description provided for @roleAdmin.
  ///
  /// In hu, this message translates to:
  /// **'Adminisztrátor'**
  String get roleAdmin;

  /// No description provided for @roleLearner.
  ///
  /// In hu, this message translates to:
  /// **'Tanuló'**
  String get roleLearner;

  /// No description provided for @invitationsTitle.
  ///
  /// In hu, this message translates to:
  /// **'Meghívások'**
  String get invitationsTitle;

  /// No description provided for @inviteEmailLabel.
  ///
  /// In hu, this message translates to:
  /// **'Meghívandó e-mail-cím'**
  String get inviteEmailLabel;

  /// No description provided for @inviteButton.
  ///
  /// In hu, this message translates to:
  /// **'Meghívás'**
  String get inviteButton;

  /// No description provided for @invited.
  ///
  /// In hu, this message translates to:
  /// **'Meghívva: {email}'**
  String invited(String email);

  /// No description provided for @revokeTooltip.
  ///
  /// In hu, this message translates to:
  /// **'Meghívás visszavonása'**
  String get revokeTooltip;

  /// No description provided for @revokeConfirmTitle.
  ///
  /// In hu, this message translates to:
  /// **'Visszavonod a meghívást?'**
  String get revokeConfirmTitle;

  /// No description provided for @revokeConfirmBody.
  ///
  /// In hu, this message translates to:
  /// **'{email} ezután nem fér hozzá az alkalmazáshoz.'**
  String revokeConfirmBody(String email);

  /// No description provided for @revokeButton.
  ///
  /// In hu, this message translates to:
  /// **'Visszavonás'**
  String get revokeButton;

  /// No description provided for @youLabel.
  ///
  /// In hu, this message translates to:
  /// **'(te)'**
  String get youLabel;

  /// No description provided for @noInvitations.
  ///
  /// In hu, this message translates to:
  /// **'Még nincs meghívás.'**
  String get noInvitations;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['hu'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'hu':
      return AppLocalizationsHu();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
