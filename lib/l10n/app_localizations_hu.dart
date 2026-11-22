// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Hungarian (`hu`).
class AppLocalizationsHu extends AppLocalizations {
  AppLocalizationsHu([String locale = 'hu']) : super(locale);

  @override
  String get appTitle => 'Kvíz-maxoló';

  @override
  String get signInTitle => 'Bejelentkezés';

  @override
  String get signInWithGoogle => 'Belépés Google-fiókkal';

  @override
  String get orDivider => 'vagy';

  @override
  String get emailLabel => 'E-mail-cím';

  @override
  String get passwordLabel => 'Jelszó';

  @override
  String get showPassword => 'Jelszó megjelenítése';

  @override
  String get hidePassword => 'Jelszó elrejtése';

  @override
  String get signInWithPassword => 'Belépés jelszóval';

  @override
  String get register => 'Regisztráció';

  @override
  String get forgotPassword => 'Elfelejtett jelszó';

  @override
  String get sendSignInLink => 'Belépési link küldése e-mailben';

  @override
  String signInLinkSent(String email) {
    return 'Elküldtük a belépési linket ide: $email. Ezen az eszközön nyisd meg.';
  }

  @override
  String passwordResetSent(String email) {
    return 'Elküldtük a jelszó-visszaállító levelet ide: $email.';
  }

  @override
  String get emailRequired => 'Add meg az e-mail-címed.';

  @override
  String get emailInvalid => 'Ez nem érvényes e-mail-cím.';

  @override
  String get passwordRequired => 'Add meg a jelszavad.';

  @override
  String get passwordTooShort => 'A jelszó legalább 6 karakter legyen.';

  @override
  String get linkNeedsEmailTitle => 'Melyik címre kérted a linket?';

  @override
  String get linkNeedsEmailBody =>
      'A linket másik eszközön vagy böngészőben kérted. Add meg ugyanazt az e-mail-címet.';

  @override
  String get continueButton => 'Tovább';

  @override
  String get cancelButton => 'Mégse';

  @override
  String get signingInWithLink => 'Belépés a linkkel…';

  @override
  String get errorInvalidEmail => 'Érvénytelen e-mail-cím.';

  @override
  String get errorUserDisabled => 'Ez a fiók le van tiltva.';

  @override
  String get errorWrongCredentials => 'Hibás e-mail-cím vagy jelszó.';

  @override
  String get errorEmailInUse =>
      'Ezzel a címmel már van fiók. Lépj be, vagy kérj belépési linket.';

  @override
  String get errorWeakPassword => 'Túl gyenge jelszó (legalább 6 karakter).';

  @override
  String get errorTooManyRequests =>
      'Túl sok próbálkozás. Várj egy kicsit, és próbáld újra.';

  @override
  String get errorNetwork => 'Nincs internetkapcsolat.';

  @override
  String get errorInvalidLink => 'A link érvénytelen vagy lejárt. Kérj újat.';

  @override
  String get errorPopupBlocked =>
      'A böngésző letiltotta a felugró ablakot. Engedélyezd, és próbáld újra.';

  @override
  String get errorNotAllowed => 'Ez a belépési mód nincs bekapcsolva.';

  @override
  String get errorAccountExists =>
      'Ehhez a címhez másik belépési mód tartozik. Lépj be azzal.';

  @override
  String get errorUnknown => 'Váratlan hiba történt. Próbáld újra.';

  @override
  String errorUnknownWithCode(String code) {
    return 'Váratlan hiba történt ($code). Próbáld újra.';
  }

  @override
  String get verifyEmailTitle => 'Erősítsd meg az e-mail-címed';

  @override
  String verifyEmailBody(String email) {
    return 'Küldtünk egy megerősítő levelet ide: $email. Kattints a benne lévő linkre, majd nyomd meg a „Megerősítettem” gombot.';
  }

  @override
  String get verifyEmailDone => 'Megerősítettem';

  @override
  String get verifyEmailResend => 'Újraküldés';

  @override
  String get verifyEmailResent => 'Újra elküldtük a megerősítő levelet.';

  @override
  String get verifyEmailNotYet =>
      'Még nincs megerősítve. Nézd meg a levélszemét mappát is.';

  @override
  String get signOut => 'Kijelentkezés';

  @override
  String get notInvitedTitle => 'Még nincs meghívásod';

  @override
  String notInvitedBody(String email) {
    return 'A(z) $email címmel még nincs meghívásod. Kérd meg az adminisztrátort, hogy hívjon meg – utána ez az oldal magától továbblép.';
  }

  @override
  String get accessErrorTitle => 'Nem sikerült ellenőrizni a hozzáférést';

  @override
  String get accessErrorBody =>
      'Ellenőrizd az internetkapcsolatot, és próbáld újra.';

  @override
  String get retry => 'Újra';

  @override
  String homeGreeting(String name) {
    return 'Szia, $name!';
  }

  @override
  String get roleAdmin => 'Adminisztrátor';

  @override
  String get roleLearner => 'Tanuló';

  @override
  String get invitationsTitle => 'Meghívások';

  @override
  String get inviteEmailLabel => 'Meghívandó e-mail-cím';

  @override
  String get inviteButton => 'Meghívás';

  @override
  String invited(String email) {
    return 'Meghívva: $email';
  }

  @override
  String get revokeTooltip => 'Meghívás visszavonása';

  @override
  String get revokeConfirmTitle => 'Visszavonod a meghívást?';

  @override
  String revokeConfirmBody(String email) {
    return '$email ezután nem fér hozzá az alkalmazáshoz.';
  }

  @override
  String get revokeButton => 'Visszavonás';

  @override
  String get youLabel => '(te)';

  @override
  String get noInvitations => 'Még nincs meghívás.';

  @override
  String get startQuiz => 'Gyakorlás indítása';

  @override
  String get noQuestionSets => 'Még nincs kérdéssor.';

  @override
  String get noQuestionSetsAdmin =>
      'Importálj egyet a „Kérdéssor importálása” gombbal (fent).';

  @override
  String get questionSetLabel => 'Kérdéssor';

  @override
  String questionCount(int count) {
    return '$count kérdés';
  }

  @override
  String get quizLengthLabel => 'Kérdések száma';

  @override
  String get quizLengthAll => 'Mind';

  @override
  String get quizLengthEndless => 'Végtelen';

  @override
  String get importTitle => 'Kérdéssor importálása';

  @override
  String get progressTitle => 'Haladás';

  @override
  String quizQuestionOf(int current, int total) {
    return '$current. kérdés / $total';
  }

  @override
  String quizQuestionEndless(int current) {
    return '$current. kérdés';
  }

  @override
  String get defaultPrompt => 'Melyik állítás helyes?';

  @override
  String get answerCorrect => 'Helyes!';

  @override
  String get answerWrong => 'Nem ez a helyes válasz.';

  @override
  String get correctAnswerLabel => 'A helyes válasz:';

  @override
  String get markSkippable => 'Bébikönnyű – ne kérdezd többet';

  @override
  String get nextQuestion => 'Következő';

  @override
  String get finishQuiz => 'Eredmény';

  @override
  String get closeQuiz => 'Gyakorlás befejezése';

  @override
  String get summaryTitle => 'Kész!';

  @override
  String summaryScore(int correct, int answered) {
    return '$correct / $answered helyes válasz';
  }

  @override
  String get summaryNothingAsked => 'Nem volt mit kérdezni.';

  @override
  String get newRound => 'Új kör';

  @override
  String get backButton => 'Vissza';

  @override
  String get allSkipped =>
      'Minden kérdés bébikönnyűnek van jelölve. A Haladás oldalon visszaveheted őket.';

  @override
  String get loadError =>
      'Nem sikerült betölteni. Ellenőrizd az internetkapcsolatot.';

  @override
  String progressSeen(int seen, int total) {
    return 'Megnézett kérdések: $seen / $total';
  }

  @override
  String progressAccuracy(int percent) {
    return 'Találati arány: $percent%';
  }

  @override
  String get progressBoxesTitle => 'Hol tartasz';

  @override
  String get progressUnseen => 'Még nem láttad';

  @override
  String get progressBox0 => 'Legutóbb rontott';

  @override
  String get progressBox1 => '1× jó';

  @override
  String get progressBox2 => '2× jó egymás után';

  @override
  String get progressBox3 => '3× jó egymás után';

  @override
  String get progressBox4 => 'Jól megy (4× jó)';

  @override
  String get progressWeakTitle => 'Ezeket rontod a legtöbbször';

  @override
  String progressWeakItem(int wrong, int seen) {
    return '$wrong hiba / $seen válasz';
  }

  @override
  String get progressNoWeak => 'Még nincs rontott kérdés.';

  @override
  String get progressSkippedRow => 'Bébikönnyűnek jelölt';

  @override
  String progressSkippedTitle(int count) {
    return 'Bébikönnyűnek jelölt kérdések ($count db)';
  }

  @override
  String get progressNoSkipped => 'Nincs bébikönnyűnek jelölt kérdés.';

  @override
  String get undoSkippable => 'Visszavétel';

  @override
  String get pickFile => 'Fájl kiválasztása (.md)';

  @override
  String importFileLabel(String name) {
    return 'Fájl: $name';
  }

  @override
  String get importTitleLabel => 'Kérdéssor neve';

  @override
  String get importTargetLabel => 'Cél';

  @override
  String get importTargetNew => 'Új kérdéssor';

  @override
  String get importButton => 'Importálás';

  @override
  String importDone(int count) {
    return 'Importálva: $count kérdés.';
  }

  @override
  String get importHasErrors =>
      'A fájlban hibák vannak. Javítsd őket, és válaszd ki újra.';

  @override
  String get importIssuesTitle => 'Ellenőrzés';

  @override
  String get importNoIssues => 'Nincs hiba.';

  @override
  String get importPreviewTitle => 'Előnézet';

  @override
  String get importReadError =>
      'A fájlt nem sikerült beolvasni (UTF-8 szöveg kell).';

  @override
  String get importReplaceNote =>
      'Meglévő kérdéssor frissítésekor a változatlan kérdések haladása megmarad.';

  @override
  String importMoreIssues(int count) {
    return '… és még $count';
  }

  @override
  String get remindersTitle => 'Emlékeztetők';

  @override
  String get remindersEnable => 'Emlékeztetők bekapcsolása';

  @override
  String get remindersEnableHint =>
      'A telefon a beállított időablakokban kérdést küld; koppints rá, és válaszolj.';

  @override
  String get remindersTimeZoneNote =>
      'Az időpontok magyar idő szerint értendők.';

  @override
  String remindersWindowTitle(int number) {
    return '$number. időablak';
  }

  @override
  String get remindersDays => 'Napok';

  @override
  String get dayShort1 => 'H';

  @override
  String get dayShort2 => 'K';

  @override
  String get dayShort3 => 'Sze';

  @override
  String get dayShort4 => 'Cs';

  @override
  String get dayShort5 => 'P';

  @override
  String get dayShort6 => 'Szo';

  @override
  String get dayShort7 => 'V';

  @override
  String get remindersFrom => 'Első';

  @override
  String get remindersTo => 'Utolsó';

  @override
  String get remindersEvery => 'Gyakoriság';

  @override
  String everyMinutes(int minutes) {
    return '$minutes percenként';
  }

  @override
  String get everyHour => 'óránként';

  @override
  String everyHours(int hours) {
    return '$hours óránként';
  }

  @override
  String remindersPerDay(int count) {
    return 'Naponta $count emlékeztető';
  }

  @override
  String get remindersAddWindow => 'Időablak hozzáadása';

  @override
  String get remindersRemoveWindow => 'Időablak törlése';

  @override
  String get remindersEndBeforeStart =>
      'Az utolsó időpont nem lehet korábbi az elsőnél.';

  @override
  String get remindersNoDays => 'Válassz legalább egy napot.';

  @override
  String get saveButton => 'Mentés';

  @override
  String get remindersSaved => 'Elmentve – az emlékeztetők ütemezése frissül.';

  @override
  String get remindersTest => 'Próbaértesítés küldése';

  @override
  String get remindersTestSent => 'Elküldve – nézd meg az értesítéseket.';

  @override
  String get remindersTestFailed => 'Nem sikerült értesítést küldeni.';

  @override
  String remindersPermissionDenied(String app) {
    return 'Az értesítések le vannak tiltva. Engedélyezd őket a telefon beállításaiban: Alkalmazások → $app → Értesítések.';
  }

  @override
  String remindersBatteryHint(String app) {
    return 'Ha az emlékeztetők késnek vagy elmaradnak: Beállítások → Alkalmazások → $app → Akkumulátor → Nem korlátozott. A menük neve telefononként eltérhet.';
  }

  @override
  String get reminderTitle => 'Jöhet egy kérdés?';

  @override
  String get reminderChannelName => 'Emlékeztetők';

  @override
  String get reminderChannelDescription =>
      'Gyakorló kérdések a beállított időablakokban';

  @override
  String get reminderSetMissing => 'Ez a kérdéssor már nem érhető el.';

  @override
  String get remindersMode => 'Az értesítésben';

  @override
  String get remindersModeOpen => 'Kvíz megnyitása';

  @override
  String get remindersModeTrueFalse => 'Igaz / Hamis';

  @override
  String get remindersModeOpenHint =>
      'Koppintásra megnyílik egy kvíz egy kérdéssel; az értesítés nem árulja el, melyikkel.';

  @override
  String get remindersModeTrueFalseHint =>
      'Az értesítésben egy állítás jelenik meg: válaszolj az Igaz vagy a Hamis gombbal – az alkalmazás nem nyílik meg –, vagy nézd meg az összes választ.';

  @override
  String get reminderTrueFalseTitle => 'Igaz vagy hamis?';

  @override
  String get answerTrue => 'Igaz';

  @override
  String get answerFalse => 'Hamis';

  @override
  String get answerAll => 'Összes válasz';

  @override
  String get reminderResultCorrect => '✔ Helyes!';

  @override
  String get reminderResultWrong => '✘ Nem jó';

  @override
  String reminderCorrectStatement(String text) {
    return 'Helyes: $text';
  }

  @override
  String reminderNextStatement(String text) {
    return 'Következő – igaz vagy hamis?\n$text';
  }
}
