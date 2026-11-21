import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:testacer/src/auth/auth_models.dart';
import 'package:testacer/src/auth/email_link_controller.dart';
import 'package:testacer/src/ui/sign_in_screen.dart';

import '../support/fakes.dart';

void main() {
  late FakeAuthService auth;
  late FakeEmailLinkStore store;
  late EmailLinkController emailLinks;

  setUp(() {
    auth = FakeAuthService();
    store = FakeEmailLinkStore();
    emailLinks = EmailLinkController(
      auth: auth,
      store: store,
      links: const Stream<Uri>.empty(),
    );
  });

  Future<void> pumpScreen(WidgetTester tester) => tester.pumpWidget(
        localized(SignInScreen(auth: auth, emailLinks: emailLinks)),
      );

  Future<void> enter(WidgetTester tester, String label, String text) =>
      tester.enterText(find.widgetWithText(TextField, label), text);

  testWidgets('password sign-in needs an e-mail and a password', (tester) async {
    await pumpScreen(tester);

    await tapVisible(tester, find.text(hu.signInWithPassword));

    expect(find.text(hu.emailRequired), findsOneWidget);
    expect(find.text(hu.passwordRequired), findsOneWidget);
    expect(auth.calls, isEmpty);
  });

  testWidgets('password sign-in uses the normalised e-mail', (tester) async {
    await pumpScreen(tester);

    await enter(tester, hu.emailLabel, ' Tanulo@Example.com ');
    await enter(tester, hu.passwordLabel, 'titok123');
    await tapVisible(tester, find.text(hu.signInWithPassword));

    expect(auth.calls, ['password:tanulo@example.com']);
  });

  testWidgets('a failed sign-in shows the reason', (tester) async {
    auth.nextFailure = const AuthFailure(AuthErrorKind.wrongCredentials);
    await pumpScreen(tester);

    await enter(tester, hu.emailLabel, 'tanulo@example.com');
    await enter(tester, hu.passwordLabel, 'rossz');
    await tapVisible(tester, find.text(hu.signInWithPassword));

    expect(find.text(hu.errorWrongCredentials), findsOneWidget);
  });

  testWidgets('a cancelled Google sign-in shows nothing', (tester) async {
    auth.nextFailure = const AuthFailure(AuthErrorKind.cancelled);
    await pumpScreen(tester);

    await tapVisible(tester, find.text(hu.signInWithGoogle));

    expect(auth.calls, ['google']);
    expect(find.text(hu.errorUnknown), findsNothing);
  });

  testWidgets('registration requires at least 6 characters', (tester) async {
    await pumpScreen(tester);

    await enter(tester, hu.emailLabel, 'uj@example.com');
    await enter(tester, hu.passwordLabel, '12345');
    await tapVisible(tester, find.text(hu.register));

    expect(find.text(hu.passwordTooShort), findsOneWidget);
    expect(auth.calls, isEmpty);
  });

  testWidgets('sending a sign-in link confirms and remembers the address',
      (tester) async {
    await pumpScreen(tester);

    await enter(tester, hu.emailLabel, 'tanulo@example.com');
    await tapVisible(tester, find.text(hu.sendSignInLink));

    expect(auth.calls, ['sendLink:tanulo@example.com']);
    expect(store.email, 'tanulo@example.com');
    expect(find.text(hu.signInLinkSent('tanulo@example.com')), findsOneWidget);
  });

  testWidgets('a link opened on another device asks for the address',
      (tester) async {
    await pumpScreen(tester);

    await emailLinks.handleLink(Uri.parse('https://x.hu/?mode=signIn'));
    await tester.pumpAndSettle();
    expect(find.text(hu.linkNeedsEmailTitle), findsOneWidget);

    await tester.enterText(
      find.widgetWithText(TextField, hu.emailLabel).first,
      'tanulo@example.com',
    );
    await tapVisible(tester, find.text(hu.continueButton));

    expect(auth.calls, ['linkSignIn:tanulo@example.com']);
    expect(find.text(hu.linkNeedsEmailTitle), findsNothing);
  });
}
