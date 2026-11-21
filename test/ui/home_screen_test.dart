import 'package:flutter_test/flutter_test.dart';
import 'package:testacer/src/access/access_repository.dart';
import 'package:testacer/src/quiz/quiz_length.dart';
import 'package:testacer/src/settings/user_settings.dart';
import 'package:testacer/src/ui/home_screen.dart';
import 'package:testacer/src/ui/quiz_screen.dart';

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

  testWidgets('uses the remembered set when there are several', (tester) async {
    t.questionSets
      ..add('a', 'Első', sampleQuestions())
      ..add('b', 'Második', sampleQuestions().take(2).toList());
    t.settings.settings.value = const UserSettings(activeSetId: 'b');
    await pumpHome(tester);

    expect(find.text('Második'), findsOneWidget);
    expect(find.text(hu.questionCount(2)), findsOneWidget);
  });

  testWidgets('tells learners and admins when there is no set', (tester) async {
    await pumpHome(tester, role: AccessRole.admin);

    expect(
      find.text('${hu.noQuestionSets} ${hu.noQuestionSetsAdmin}'),
      findsOneWidget,
    );
  });
}
