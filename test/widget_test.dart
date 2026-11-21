// App-level widget tests: which screen the sign-in and access state leads to.
import 'package:flutter_test/flutter_test.dart';
import 'package:testacer/src/access/access_repository.dart';
import 'package:testacer/src/app.dart';
import 'package:testacer/src/auth/email_link_controller.dart';

import 'support/fakes.dart';

void main() {
  late FakeAuthService auth;
  late FakeAccessRepository access;

  setUp(() {
    auth = FakeAuthService();
    access = FakeAccessRepository();
  });

  Future<void> pumpApp(WidgetTester tester) async {
    await tester.pumpWidget(
      TestAcerApp(
        auth: auth,
        access: access,
        emailLinks: EmailLinkController(
          auth: auth,
          store: FakeEmailLinkStore(),
          links: const Stream<Uri>.empty(),
        ),
      ),
    );
    await tester.pump();
  }

  testWidgets('signed out → sign-in screen', (tester) async {
    await pumpApp(tester);
    auth.emit(null);
    await tester.pumpAndSettle();

    expect(find.text(hu.signInTitle), findsOneWidget);
  });

  testWidgets('unverified password account → verify e-mail', (tester) async {
    await pumpApp(tester);
    auth.emit(testUser(usesPassword: true, emailVerified: false));
    await tester.pumpAndSettle();

    expect(find.text(hu.verifyEmailTitle), findsOneWidget);
  });

  testWidgets('not on the allowlist → not invited, until invited',
      (tester) async {
    await pumpApp(tester);
    auth.emit(testUser());
    await tester.pump();
    access.roles.add(null);
    await tester.pumpAndSettle();

    expect(find.text(hu.notInvitedTitle), findsOneWidget);

    access.roles.add(AccessRole.learner);
    await tester.pumpAndSettle();

    expect(find.text(hu.homeGreeting('Teszt Elek')), findsOneWidget);
    expect(find.text(hu.roleLearner), findsOneWidget);
  });

  testWidgets('admins see the invitations button', (tester) async {
    await pumpApp(tester);
    auth.emit(testUser(email: 'admin@example.com'));
    await tester.pump();
    access.roles.add(AccessRole.admin);
    await tester.pumpAndSettle();

    expect(find.byTooltip(hu.invitationsTitle), findsOneWidget);
  });

  testWidgets('an allowlist read error offers a retry', (tester) async {
    await pumpApp(tester);
    auth.emit(testUser());
    await tester.pump();
    access.roles.addError(Exception('permission-denied'));
    await tester.pumpAndSettle();

    expect(find.text(hu.accessErrorTitle), findsOneWidget);
    expect(find.text(hu.retry), findsOneWidget);
  });
}
