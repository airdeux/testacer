// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Hungarian (`hu`).
class AppLocalizationsHu extends AppLocalizations {
  AppLocalizationsHu([String locale = 'hu']) : super(locale);

  @override
  String get appTitle => 'TestAcer';

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
  String get homeComingSoon =>
      'A gyakorlás a következő fejlesztési lépésben érkezik.';

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
}
