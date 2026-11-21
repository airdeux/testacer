import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:testacer/src/questions/question_set_repository.dart';
import 'package:testacer/src/quiz/progress.dart';
import 'package:testacer/src/quiz/quiz_length.dart';
import 'package:testacer/src/ui/emphasized_text.dart';
import 'package:testacer/src/ui/quiz_screen.dart';

import '../support/fakes.dart';

void main() {
  late TestServices t;
  late QuestionSetInfo set;

  setUp(() {
    t = TestServices();
    set = t.questionSets.add('set1', 'Gyakorló teszt', sampleQuestions());
  });

  Future<void> pumpQuiz(WidgetTester tester, QuizLength length) async {
    await tester.pumpWidget(
      localized(
        QuizScreen(
          services: t.services,
          user: testUser(),
          questionSet: set,
          length: length,
          random: Random(1),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  /// The text of the correct option of the question on screen.
  String correctText(WidgetTester tester) {
    final questions = sampleQuestions();
    for (final q in questions) {
      if (find.text(q.wrong.first.text).evaluate().isNotEmpty) return q.correct.text;
    }
    throw StateError('no known question on screen');
  }

  String wrongText(WidgetTester tester) {
    for (final q in sampleQuestions()) {
      if (find.text(q.wrong.first.text).evaluate().isNotEmpty) return q.wrong.first.text;
    }
    throw StateError('no known question on screen');
  }

  testWidgets('shows plain options, then feedback with emphasis', (tester) async {
    await pumpQuiz(tester, QuizLength.five);

    expect(find.text(hu.quizQuestionOf(1, 3)), findsOneWidget);
    expect(find.byType(EmphasizedText), findsNothing);

    await tapVisible(tester, find.text(wrongText(tester)));

    expect(find.text(hu.answerWrong), findsOneWidget);
    expect(find.text(hu.correctAnswerLabel), findsOneWidget);
    expect(find.byType(EmphasizedText), findsOneWidget);
    expect(t.progress.saves.single, contains('box0'));
  });

  testWidgets('a correct answer moves the question up a box', (tester) async {
    await pumpQuiz(tester, QuizLength.five);

    await tapVisible(tester, find.text(correctText(tester)).first);

    expect(find.text(hu.answerCorrect), findsOneWidget);
    expect(t.progress.saves.single, contains('box1'));
  });

  testWidgets('the skippable switch is saved', (tester) async {
    await pumpQuiz(tester, QuizLength.five);
    await tapVisible(tester, find.text(wrongText(tester)));

    await tapVisible(tester, find.text(hu.markSkippable));

    expect(t.progress.saves.last, contains('skiptrue'));
  });

  testWidgets('after the last question it shows the score', (tester) async {
    await pumpQuiz(tester, QuizLength.five);

    for (var i = 0; i < 3; i++) {
      await tapVisible(tester, find.text(correctText(tester)).first);
      await tapVisible(
        tester,
        find.text(i < 2 ? hu.nextQuestion : hu.finishQuiz),
      );
    }

    expect(find.text(hu.summaryTitle), findsOneWidget);
    expect(find.text(hu.summaryScore(3, 3)), findsOneWidget);
  });

  testWidgets('closing an endless quiz shows the score so far', (tester) async {
    await pumpQuiz(tester, QuizLength.endless);
    expect(find.text(hu.quizQuestionEndless(1)), findsOneWidget);

    await tapVisible(tester, find.text(wrongText(tester)));
    await tapVisible(tester, find.byTooltip(hu.closeQuiz));

    expect(find.text(hu.summaryScore(0, 1)), findsOneWidget);
  });

  testWidgets('everything skippable → explains where to undo', (tester) async {
    t.progress.data['set1'] = {
      for (final q in sampleQuestions()) q.key: const ItemProgress(skippable: true),
    };
    await pumpQuiz(tester, QuizLength.ten);

    expect(find.text(hu.allSkipped), findsOneWidget);
  });

  testWidgets('a note on a wrong option appears after answering', (tester) async {
    await pumpQuiz(tester, QuizLength.all);
    // Answer until the question with the note is on screen.
    for (var i = 0; i < 3; i++) {
      if (find.text('A 2. kyu övszíne kék.').evaluate().isNotEmpty) break;
      await tapVisible(tester, find.text(correctText(tester)).first);
      await tapVisible(tester, find.text(hu.nextQuestion));
    }
    expect(find.text('megjegyzés'), findsNothing);

    await tapVisible(tester, find.text('A 2. kyu övszíne zöld.'));

    expect(find.text('megjegyzés'), findsOneWidget);
    expect(find.byType(Card), findsWidgets);
  });
}
