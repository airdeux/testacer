import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:testacer/src/access/access_repository.dart';
import 'package:testacer/src/app_version.dart';
import 'package:testacer/src/quiz/quiz_length.dart';
import 'package:testacer/src/reminders/reminder_notifications.dart';
import 'package:testacer/src/reminders/reminder_settings.dart';
import 'package:testacer/src/settings/user_settings.dart';
import 'package:testacer/src/ui/home_screen.dart';
import 'package:testacer/src/ui/quiz_screen.dart';
import 'package:testacer/src/ui/reminder_settings_screen.dart';

import '../support/fakes.dart';

void main() {
  late TestServices t;

  setUp(() => t = TestServices());

  Future<void> pumpHome(WidgetTester tester, {AccessRole role = AccessRole.learner}) async {
    await tester.pumpWidget(
      localized(HomeScreen(services: t.services, user: testUser(), role: role)),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('shows the only set and starts a quiz with the chosen length',
      (tester) async {
    t.questionSets.add('set1', 'Gyakorló teszt', sampleQuestions());
    await pumpHome(tester);

    expect(find.text('Gyakorló teszt'), findsOneWidget);
    expect(find.text(hu.questionCount(3)), findsOneWidget);

    await tapVisible(tester, find.text('5'));
    expect(t.settings.settings.value.quizLength, QuizLength.five);

    await tapVisible(tester, find.text(hu.startQuiz));
    expect(find.byType(QuizScreen), findsOneWidget);
    expect(tester.widget<QuizScreen>(find.byType(QuizScreen)).length, QuizLength.five);
  });

  testWidgets('the title shows the app version', (tester) async {
    t.questionSets.add('set1', 'Gyakorló teszt', sampleQuestions());
    await pumpHome(tester);

    expect(find.text('${hu.appTitle}  ${appVersionLabel()}'), findsOneWidget);
  });

  testWidgets('the lengths are 5, 10, 25 and Mind', (tester) async {
    t.questionSets.add('set1', 'Gyakorló teszt', sampleQuestions());
    await pumpHome(tester);

    for (final label in ['5', '10', '25', hu.quizLengthAll]) {
      expect(find.text(label), findsOneWidget);
    }
    expect(find.text('1'), findsNothing);
    expect(find.text('∞'), findsNothing);

    await tapVisible(tester, find.text('25'));
    expect(t.settings.settings.value.quizLength, QuizLength.twentyFive);
  });

  testWidgets('Mind reminds that the Bébikönnyű questions come too (D-020)',
      (tester) async {
    t.questionSets.add('set1', 'Gyakorló teszt', sampleQuestions());
    await pumpHome(tester);
    await tapVisible(tester, find.text(hu.quizLengthAll));
    expect(t.settings.settings.value.quizLength, QuizLength.all);

    await tapVisible(tester, find.text(hu.startQuiz));
    expect(find.text(hu.allQuizTitle(3)), findsOneWidget);
    expect(find.text(hu.allQuizBody), findsOneWidget);

    await tester.tap(find.text(hu.cancelButton));
    await tester.pumpAndSettle();
    expect(find.byType(QuizScreen), findsNothing);

    await tapVisible(tester, find.text(hu.startQuiz));
    await tester.tap(find.text(hu.allQuizStart));
    await tester.pumpAndSettle();
    expect(tester.widget<QuizScreen>(find.byType(QuizScreen)).length,
        QuizLength.all);
  });

  testWidgets('the other lengths start without a question', (tester) async {
    t.questionSets.add('set1', 'Gyakorló teszt', sampleQuestions());
    await pumpHome(tester);

    await tapVisible(tester, find.text(hu.startQuiz));

    expect(find.byType(AlertDialog), findsNothing);
    expect(tester.widget<QuizScreen>(find.byType(QuizScreen)).length,
        QuizLength.ten);
  });

  testWidgets('uses the remembered set when there are several', (tester) async {
    t.questionSets
      ..add('a', 'Első', sampleQuestions())
      ..add('b', 'Második', sampleQuestions().take(2).toList());
    t.settings.settings.value = const UserSettings(activeSetId: 'b');
    await pumpHome(tester);

    expect(find.text('Második'), findsOneWidget);
    expect(find.text(hu.questionCount(2)), findsOneWidget);
  });

  testWidgets('re-plans reminders for the active set, again after a quiz',
      (tester) async {
    t.questionSets.add('set1', 'Gyakorló teszt', sampleQuestions());
    const on = ReminderSettings(enabled: true);
    t.settings.settings.value = const UserSettings(reminders: on);
    await pumpHome(tester);

    expect(t.reminders.syncs, [('set1', on)]);

    // A settings change that does not touch reminders: no re-plan.
    await tapVisible(tester, find.text('5'));
    expect(t.reminders.syncs, hasLength(1));

    await tapVisible(tester, find.text(hu.startQuiz));
    Navigator.of(tester.element(find.byType(QuizScreen))).pop();
    await tester.pumpAndSettle();
    expect(t.reminders.syncs, hasLength(2));
  });

  testWidgets('opens the reminder settings; no button without reminders',
      (tester) async {
    t.questionSets.add('set1', 'Gyakorló teszt', sampleQuestions());
    await pumpHome(tester);

    await tapVisible(tester, find.text(hu.remindersTitle));
    expect(find.byType(ReminderSettingsScreen), findsOneWidget);
  });

  testWidgets('the web has no reminder button', (tester) async {
    t.reminders.supported = false;
    t.questionSets.add('set1', 'Gyakorló teszt', sampleQuestions());
    await pumpHome(tester);

    expect(find.text(hu.remindersTitle), findsNothing);
    expect(t.reminders.syncs, isEmpty);
  });

  testWidgets('a tapped reminder opens an endless quiz with its question',
      (tester) async {
    final questions = sampleQuestions();
    t.questionSets.add('set1', 'Gyakorló teszt', questions);
    t.reminders.launches.add(ReminderLaunch(setId: 'set1', key: questions[1].key));
    await pumpHome(tester);

    final quiz = tester.widget<QuizScreen>(find.byType(QuizScreen));
    expect(quiz.length, QuizLength.endless);
    expect(quiz.startKey, questions[1].key);
    expect(t.reminders.launches.pending, isNull);

    // A tap while the app is open does the same.
    Navigator.of(tester.element(find.byType(QuizScreen))).pop();
    await tester.pumpAndSettle();
    t.reminders.launches.add(ReminderLaunch(setId: 'set1', key: questions[2].key));
    await tester.pumpAndSettle();
    expect(
      tester.widget<QuizScreen>(find.byType(QuizScreen)).startKey,
      questions[2].key,
    );
  });

  testWidgets('a reminder of a removed set only explains', (tester) async {
    t.questionSets.add('set1', 'Gyakorló teszt', sampleQuestions());
    t.reminders.launches.add(const ReminderLaunch(setId: 'gone', key: 'k'));
    await pumpHome(tester);

    expect(find.byType(QuizScreen), findsNothing);
    expect(find.text(hu.reminderSetMissing), findsOneWidget);
  });

  testWidgets('signing out cancels the reminders', (tester) async {
    t.questionSets.add('set1', 'Gyakorló teszt', sampleQuestions());
    await pumpHome(tester);

    await tapVisible(tester, find.byTooltip(hu.signOut));
    expect(t.reminders.clears, 1);
  });

  testWidgets('tells learners and admins when there is no set', (tester) async {
    await pumpHome(tester, role: AccessRole.admin);

    expect(
      find.text('${hu.noQuestionSets} ${hu.noQuestionSetsAdmin}'),
      findsOneWidget,
    );
  });
}
