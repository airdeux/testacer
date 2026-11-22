import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:testacer/src/questions/question_set_repository.dart';
import 'package:testacer/src/reminders/reminder_settings.dart';
import 'package:testacer/src/ui/reminder_settings_screen.dart';

import '../support/fakes.dart';

void main() {
  late TestServices t;
  late QuestionSetInfo set;

  setUp(() {
    t = TestServices();
    set = t.questionSets.add('set1', 'Gyakorló teszt', sampleQuestions());
  });

  Future<void> pumpScreen(
    WidgetTester tester, {
    ReminderSettings initial = const ReminderSettings(),
  }) async {
    await tester.pumpWidget(
      localized(
        ReminderSettingsScreen(
          services: t.services,
          user: testUser(),
          questionSet: set,
          initial: initial,
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  FilledButton saveButton(WidgetTester tester) => tester.widget<FilledButton>(
        find.widgetWithText(FilledButton, hu.saveButton),
      );

  testWidgets('switching on and saving stores the default window', (tester) async {
    await pumpScreen(tester);

    expect(find.text(hu.remindersPerDay(14)), findsOneWidget);
    expect(saveButton(tester).onPressed, isNull); // nothing changed yet

    await tapVisible(tester, find.text(hu.remindersEnable));
    await tapVisible(tester, find.text(hu.saveButton));

    final saved = t.settings.settings.value.reminders;
    expect(saved.enabled, isTrue);
    expect(saved.windows, [ReminderWindow.standard]);
    expect(find.text(hu.remindersSaved), findsOneWidget);
  });

  testWidgets('a refused permission keeps reminders off', (tester) async {
    t.reminders
      ..enabled = false
      ..permission = false;
    await pumpScreen(tester);

    await tapVisible(tester, find.text(hu.remindersEnable));

    expect(
      tester.widget<SwitchListTile>(find.byType(SwitchListTile)).value,
      isFalse,
    );
    expect(find.text(hu.remindersPermissionDenied(hu.appTitle)), findsOneWidget);
  });

  testWidgets('days, extra windows and removal', (tester) async {
    await pumpScreen(tester, initial: const ReminderSettings(enabled: true));

    // Untick Saturday and Sunday.
    await tapVisible(tester, find.text(hu.dayShort6));
    await tapVisible(tester, find.text(hu.dayShort7));
    await tapVisible(tester, find.text(hu.remindersAddWindow));
    expect(find.text(hu.remindersWindowTitle(2)), findsOneWidget);

    await tapVisible(tester, find.byTooltip(hu.remindersRemoveWindow).last);
    expect(find.text(hu.remindersWindowTitle(2)), findsNothing);

    await tapVisible(tester, find.text(hu.saveButton));
    expect(
      t.settings.settings.value.reminders.windows.single.days,
      {1, 2, 3, 4, 5},
    );
  });

  testWidgets('a window without days cannot be saved', (tester) async {
    await pumpScreen(
      tester,
      initial: const ReminderSettings(
        enabled: true,
        windows: [
          ReminderWindow(days: {3}, start: 9 * 60, end: 10 * 60, everyMinutes: 60),
        ],
      ),
    );

    await tapVisible(tester, find.text(hu.dayShort3));

    expect(find.text(hu.remindersNoDays), findsOneWidget);
    expect(saveButton(tester).onPressed, isNull);
  });

  testWidgets('fits a small phone with two windows', (tester) async {
    tester.view
      ..physicalSize = const Size(320 * 3, 640 * 3)
      ..devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    await pumpScreen(
      tester,
      initial: const ReminderSettings(
        enabled: true,
        windows: [ReminderWindow.standard, ReminderWindow.standard],
      ),
    );
    expect(tester.takeException(), isNull);
    expect(find.text(hu.remindersWindowTitle(2)), findsOneWidget);
  });

  testWidgets('answering in the notification can be chosen', (tester) async {
    await pumpScreen(tester, initial: const ReminderSettings(enabled: true));
    expect(find.text(hu.remindersModeOpenHint), findsOneWidget);

    await tapVisible(tester, find.text(hu.remindersModeTrueFalse));
    expect(find.text(hu.remindersModeTrueFalseHint), findsOneWidget);
    await tapVisible(tester, find.text(hu.saveButton));

    expect(t.settings.settings.value.reminders.mode, ReminderMode.trueFalse);
  });

  testWidgets('sends a test notification', (tester) async {
    await pumpScreen(tester);

    await tapVisible(tester, find.text(hu.remindersTest));

    expect(t.reminders.tests, 1);
    expect(find.text(hu.remindersTestSent), findsOneWidget);
  });
}
