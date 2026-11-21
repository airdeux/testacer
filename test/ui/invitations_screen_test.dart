import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:testacer/src/access/access_repository.dart';
import 'package:testacer/src/ui/invitations_screen.dart';

import '../support/fakes.dart';

void main() {
  late FakeAccessRepository access;

  setUp(() => access = FakeAccessRepository());

  Future<void> pumpScreen(WidgetTester tester) async {
    await tester.pumpWidget(
      localized(InvitationsScreen(access: access, currentEmail: 'admin@example.com')),
    );
    access.invitations.add(const [
      Invitation(email: 'admin@example.com', role: AccessRole.admin),
      Invitation(email: 'tanulo@example.com', role: AccessRole.learner),
    ]);
    await tester.pumpAndSettle();
  }

  testWidgets('invites the normalised address with the chosen role',
      (tester) async {
    await pumpScreen(tester);

    await tester.enterText(
      find.widgetWithText(TextField, hu.inviteEmailLabel),
      ' Uj@Example.com ',
    );
    await tapVisible(tester, find.text(hu.roleAdmin).first);
    await tapVisible(tester, find.text(hu.inviteButton));

    expect(access.calls, ['invite:uj@example.com:admin']);
    expect(find.text(hu.invited('uj@example.com')), findsOneWidget);
  });

  testWidgets('rejects an invalid address', (tester) async {
    await pumpScreen(tester);

    await tester.enterText(
      find.widgetWithText(TextField, hu.inviteEmailLabel),
      'nem-cim',
    );
    await tapVisible(tester, find.text(hu.inviteButton));

    expect(find.text(hu.emailInvalid), findsOneWidget);
    expect(access.calls, isEmpty);
  });

  testWidgets('revokes after confirmation, but never the own address',
      (tester) async {
    await pumpScreen(tester);

    final buttons = find.widgetWithIcon(IconButton, Icons.person_remove_outlined);
    expect(tester.widget<IconButton>(buttons.at(0)).onPressed, isNull);

    await tapVisible(tester, buttons.at(1));
    await tapVisible(tester, find.text(hu.revokeButton));

    expect(access.calls, ['revoke:tanulo@example.com']);
  });
}
