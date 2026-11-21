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
  /// **'Kvíz-maxoló'**
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

  /// Unexpected sign-in error; code is the Firebase error code, shown to help troubleshooting.
  ///
  /// In hu, this message translates to:
  /// **'Váratlan hiba történt ({code}). Próbáld újra.'**
  String errorUnknownWithCode(String code);

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

  /// No description provided for @startQuiz.
  ///
  /// In hu, this message translates to:
  /// **'Gyakorlás indítása'**
  String get startQuiz;

  /// No description provided for @noQuestionSets.
  ///
  /// In hu, this message translates to:
  /// **'Még nincs kérdéssor.'**
  String get noQuestionSets;

  /// No description provided for @noQuestionSetsAdmin.
  ///
  /// In hu, this message translates to:
  /// **'Importálj egyet a „Kérdéssor importálása” gombbal (fent).'**
  String get noQuestionSetsAdmin;

  /// No description provided for @questionSetLabel.
  ///
  /// In hu, this message translates to:
  /// **'Kérdéssor'**
  String get questionSetLabel;

  /// No description provided for @questionCount.
  ///
  /// In hu, this message translates to:
  /// **'{count} kérdés'**
  String questionCount(int count);

  /// No description provided for @quizLengthLabel.
  ///
  /// In hu, this message translates to:
  /// **'Kérdések száma'**
  String get quizLengthLabel;

  /// No description provided for @quizLengthAll.
  ///
  /// In hu, this message translates to:
  /// **'Mind'**
  String get quizLengthAll;

  /// No description provided for @quizLengthEndless.
  ///
  /// In hu, this message translates to:
  /// **'Végtelen'**
  String get quizLengthEndless;

  /// No description provided for @importTitle.
  ///
  /// In hu, this message translates to:
  /// **'Kérdéssor importálása'**
  String get importTitle;

  /// No description provided for @progressTitle.
  ///
  /// In hu, this message translates to:
  /// **'Haladás'**
  String get progressTitle;

  /// No description provided for @quizQuestionOf.
  ///
  /// In hu, this message translates to:
  /// **'{current}. kérdés / {total}'**
  String quizQuestionOf(int current, int total);

  /// No description provided for @quizQuestionEndless.
  ///
  /// In hu, this message translates to:
  /// **'{current}. kérdés'**
  String quizQuestionEndless(int current);

  /// No description provided for @defaultPrompt.
  ///
  /// In hu, this message translates to:
  /// **'Melyik állítás helyes?'**
  String get defaultPrompt;

  /// No description provided for @answerCorrect.
  ///
  /// In hu, this message translates to:
  /// **'Helyes!'**
  String get answerCorrect;

  /// No description provided for @answerWrong.
  ///
  /// In hu, this message translates to:
  /// **'Nem ez a helyes válasz.'**
  String get answerWrong;

  /// No description provided for @correctAnswerLabel.
  ///
  /// In hu, this message translates to:
  /// **'A helyes válasz:'**
  String get correctAnswerLabel;

  /// No description provided for @markSkippable.
  ///
  /// In hu, this message translates to:
  /// **'Bébikönnyű – ne kérdezd többet'**
  String get markSkippable;

  /// No description provided for @nextQuestion.
  ///
  /// In hu, this message translates to:
  /// **'Következő'**
  String get nextQuestion;

  /// No description provided for @finishQuiz.
  ///
  /// In hu, this message translates to:
  /// **'Eredmény'**
  String get finishQuiz;

  /// No description provided for @closeQuiz.
  ///
  /// In hu, this message translates to:
  /// **'Gyakorlás befejezése'**
  String get closeQuiz;

  /// No description provided for @summaryTitle.
  ///
  /// In hu, this message translates to:
  /// **'Kész!'**
  String get summaryTitle;

  /// No description provided for @summaryScore.
  ///
  /// In hu, this message translates to:
  /// **'{correct} / {answered} helyes válasz'**
  String summaryScore(int correct, int answered);

  /// No description provided for @summaryNothingAsked.
  ///
  /// In hu, this message translates to:
  /// **'Nem volt mit kérdezni.'**
  String get summaryNothingAsked;

  /// No description provided for @newRound.
  ///
  /// In hu, this message translates to:
  /// **'Új kör'**
  String get newRound;

  /// No description provided for @backButton.
  ///
  /// In hu, this message translates to:
  /// **'Vissza'**
  String get backButton;

  /// No description provided for @allSkipped.
  ///
  /// In hu, this message translates to:
  /// **'Minden kérdés bébikönnyűnek van jelölve. A Haladás oldalon visszaveheted őket.'**
  String get allSkipped;

  /// No description provided for @loadError.
  ///
  /// In hu, this message translates to:
  /// **'Nem sikerült betölteni. Ellenőrizd az internetkapcsolatot.'**
  String get loadError;

  /// No description provided for @progressSeen.
  ///
  /// In hu, this message translates to:
  /// **'Megnézett kérdések: {seen} / {total}'**
  String progressSeen(int seen, int total);

  /// No description provided for @progressAccuracy.
  ///
  /// In hu, this message translates to:
  /// **'Találati arány: {percent}%'**
  String progressAccuracy(int percent);

  /// No description provided for @progressBoxesTitle.
  ///
  /// In hu, this message translates to:
  /// **'Hol tartasz'**
  String get progressBoxesTitle;

  /// No description provided for @progressUnseen.
  ///
  /// In hu, this message translates to:
  /// **'Még nem láttad'**
  String get progressUnseen;

  /// No description provided for @progressBox0.
  ///
  /// In hu, this message translates to:
  /// **'Új vagy legutóbb rontott'**
  String get progressBox0;

  /// No description provided for @progressBox1.
  ///
  /// In hu, this message translates to:
  /// **'1× jó'**
  String get progressBox1;

  /// No description provided for @progressBox2.
  ///
  /// In hu, this message translates to:
  /// **'2× jó egymás után'**
  String get progressBox2;

  /// No description provided for @progressBox3.
  ///
  /// In hu, this message translates to:
  /// **'3× jó egymás után'**
  String get progressBox3;

  /// No description provided for @progressBox4.
  ///
  /// In hu, this message translates to:
  /// **'Jól megy (4× jó)'**
  String get progressBox4;

  /// No description provided for @progressWeakTitle.
  ///
  /// In hu, this message translates to:
  /// **'Ezeket rontod a legtöbbször'**
  String get progressWeakTitle;

  /// No description provided for @progressWeakItem.
  ///
  /// In hu, this message translates to:
  /// **'{wrong} hiba / {seen} válasz'**
  String progressWeakItem(int wrong, int seen);

  /// No description provided for @progressNoWeak.
  ///
  /// In hu, this message translates to:
  /// **'Még nincs rontott kérdés.'**
  String get progressNoWeak;

  /// No description provided for @progressSkippedTitle.
  ///
  /// In hu, this message translates to:
  /// **'Bébikönnyűnek jelölt kérdések'**
  String get progressSkippedTitle;

  /// No description provided for @progressNoSkipped.
  ///
  /// In hu, this message translates to:
  /// **'Nincs bébikönnyűnek jelölt kérdés.'**
  String get progressNoSkipped;

  /// No description provided for @undoSkippable.
  ///
  /// In hu, this message translates to:
  /// **'Visszavétel'**
  String get undoSkippable;

  /// No description provided for @pickFile.
  ///
  /// In hu, this message translates to:
  /// **'Fájl kiválasztása (.md)'**
  String get pickFile;

  /// No description provided for @importFileLabel.
  ///
  /// In hu, this message translates to:
  /// **'Fájl: {name}'**
  String importFileLabel(String name);

  /// No description provided for @importTitleLabel.
  ///
  /// In hu, this message translates to:
  /// **'Kérdéssor neve'**
  String get importTitleLabel;

  /// No description provided for @importTargetLabel.
  ///
  /// In hu, this message translates to:
  /// **'Cél'**
  String get importTargetLabel;

  /// No description provided for @importTargetNew.
  ///
  /// In hu, this message translates to:
  /// **'Új kérdéssor'**
  String get importTargetNew;

  /// No description provided for @importButton.
  ///
  /// In hu, this message translates to:
  /// **'Importálás'**
  String get importButton;

  /// No description provided for @importDone.
  ///
  /// In hu, this message translates to:
  /// **'Importálva: {count} kérdés.'**
  String importDone(int count);

  /// No description provided for @importHasErrors.
  ///
  /// In hu, this message translates to:
  /// **'A fájlban hibák vannak. Javítsd őket, és válaszd ki újra.'**
  String get importHasErrors;

  /// No description provided for @importIssuesTitle.
  ///
  /// In hu, this message translates to:
  /// **'Ellenőrzés'**
  String get importIssuesTitle;

  /// No description provided for @importNoIssues.
  ///
  /// In hu, this message translates to:
  /// **'Nincs hiba.'**
  String get importNoIssues;

  /// No description provided for @importPreviewTitle.
  ///
  /// In hu, this message translates to:
  /// **'Előnézet'**
  String get importPreviewTitle;

  /// No description provided for @importReadError.
  ///
  /// In hu, this message translates to:
  /// **'A fájlt nem sikerült beolvasni (UTF-8 szöveg kell).'**
  String get importReadError;

  /// No description provided for @importReplaceNote.
  ///
  /// In hu, this message translates to:
  /// **'Meglévő kérdéssor frissítésekor a változatlan kérdések haladása megmarad.'**
  String get importReplaceNote;

  /// No description provided for @importMoreIssues.
  ///
  /// In hu, this message translates to:
  /// **'… és még {count}'**
  String importMoreIssues(int count);

  /// No description provided for @remindersTitle.
  ///
  /// In hu, this message translates to:
  /// **'Emlékeztetők'**
  String get remindersTitle;

  /// No description provided for @remindersEnable.
  ///
  /// In hu, this message translates to:
  /// **'Emlékeztetők bekapcsolása'**
  String get remindersEnable;

  /// No description provided for @remindersEnableHint.
  ///
  /// In hu, this message translates to:
  /// **'A telefon a beállított időablakokban kérdést küld; koppints rá, és válaszolj.'**
  String get remindersEnableHint;

  /// No description provided for @remindersTimeZoneNote.
  ///
  /// In hu, this message translates to:
  /// **'Az időpontok magyar idő szerint értendők.'**
  String get remindersTimeZoneNote;

  /// No description provided for @remindersWindowTitle.
  ///
  /// In hu, this message translates to:
  /// **'{number}. időablak'**
  String remindersWindowTitle(int number);

  /// No description provided for @remindersDays.
  ///
  /// In hu, this message translates to:
  /// **'Napok'**
  String get remindersDays;

  /// No description provided for @dayShort1.
  ///
  /// In hu, this message translates to:
  /// **'H'**
  String get dayShort1;

  /// No description provided for @dayShort2.
  ///
  /// In hu, this message translates to:
  /// **'K'**
  String get dayShort2;

  /// No description provided for @dayShort3.
  ///
  /// In hu, this message translates to:
  /// **'Sze'**
  String get dayShort3;

  /// No description provided for @dayShort4.
  ///
  /// In hu, this message translates to:
  /// **'Cs'**
  String get dayShort4;

  /// No description provided for @dayShort5.
  ///
  /// In hu, this message translates to:
  /// **'P'**
  String get dayShort5;

  /// No description provided for @dayShort6.
  ///
  /// In hu, this message translates to:
  /// **'Szo'**
  String get dayShort6;

  /// No description provided for @dayShort7.
  ///
  /// In hu, this message translates to:
  /// **'V'**
  String get dayShort7;

  /// No description provided for @remindersFrom.
  ///
  /// In hu, this message translates to:
  /// **'Első'**
  String get remindersFrom;

  /// No description provided for @remindersTo.
  ///
  /// In hu, this message translates to:
  /// **'Utolsó'**
  String get remindersTo;

  /// No description provided for @remindersEvery.
  ///
  /// In hu, this message translates to:
  /// **'Gyakoriság'**
  String get remindersEvery;

  /// No description provided for @everyMinutes.
  ///
  /// In hu, this message translates to:
  /// **'{minutes} percenként'**
  String everyMinutes(int minutes);

  /// No description provided for @everyHour.
  ///
  /// In hu, this message translates to:
  /// **'óránként'**
  String get everyHour;

  /// No description provided for @everyHours.
  ///
  /// In hu, this message translates to:
  /// **'{hours} óránként'**
  String everyHours(int hours);

  /// No description provided for @remindersPerDay.
  ///
  /// In hu, this message translates to:
  /// **'Naponta {count} emlékeztető'**
  String remindersPerDay(int count);

  /// No description provided for @remindersAddWindow.
  ///
  /// In hu, this message translates to:
  /// **'Időablak hozzáadása'**
  String get remindersAddWindow;

  /// No description provided for @remindersRemoveWindow.
  ///
  /// In hu, this message translates to:
  /// **'Időablak törlése'**
  String get remindersRemoveWindow;

  /// No description provided for @remindersEndBeforeStart.
  ///
  /// In hu, this message translates to:
  /// **'Az utolsó időpont nem lehet korábbi az elsőnél.'**
  String get remindersEndBeforeStart;

  /// No description provided for @remindersNoDays.
  ///
  /// In hu, this message translates to:
  /// **'Válassz legalább egy napot.'**
  String get remindersNoDays;

  /// No description provided for @saveButton.
  ///
  /// In hu, this message translates to:
  /// **'Mentés'**
  String get saveButton;

  /// No description provided for @remindersSaved.
  ///
  /// In hu, this message translates to:
  /// **'Elmentve – az emlékeztetők ütemezése frissül.'**
  String get remindersSaved;

  /// No description provided for @remindersTest.
  ///
  /// In hu, this message translates to:
  /// **'Próbaértesítés küldése'**
  String get remindersTest;

  /// No description provided for @remindersTestSent.
  ///
  /// In hu, this message translates to:
  /// **'Elküldve – nézd meg az értesítéseket.'**
  String get remindersTestSent;

  /// No description provided for @remindersTestFailed.
  ///
  /// In hu, this message translates to:
  /// **'Nem sikerült értesítést küldeni.'**
  String get remindersTestFailed;

  /// No description provided for @remindersPermissionDenied.
  ///
  /// In hu, this message translates to:
  /// **'Az értesítések le vannak tiltva. Engedélyezd őket a telefon beállításaiban: Alkalmazások → {app} → Értesítések.'**
  String remindersPermissionDenied(String app);

  /// No description provided for @remindersBatteryHint.
  ///
  /// In hu, this message translates to:
  /// **'Ha az emlékeztetők késnek vagy elmaradnak: Beállítások → Alkalmazások → {app} → Akkumulátor → Nem korlátozott. A menük neve telefononként eltérhet.'**
  String remindersBatteryHint(String app);

  /// Title of a reminder notification.
  ///
  /// In hu, this message translates to:
  /// **'Jöhet egy kérdés?'**
  String get reminderTitle;

  /// No description provided for @reminderBodySubject.
  ///
  /// In hu, this message translates to:
  /// **'Téma: {subject} – koppints, és válaszolj!'**
  String reminderBodySubject(String subject);

  /// No description provided for @reminderBodyPlain.
  ///
  /// In hu, this message translates to:
  /// **'Koppints, és válaszolj egy kérdésre!'**
  String get reminderBodyPlain;

  /// Android notification channel name.
  ///
  /// In hu, this message translates to:
  /// **'Emlékeztetők'**
  String get reminderChannelName;

  /// No description provided for @reminderChannelDescription.
  ///
  /// In hu, this message translates to:
  /// **'Gyakorló kérdések a beállított időablakokban'**
  String get reminderChannelDescription;

  /// No description provided for @reminderSetMissing.
  ///
  /// In hu, this message translates to:
  /// **'Ez a kérdéssor már nem érhető el.'**
  String get reminderSetMissing;
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
