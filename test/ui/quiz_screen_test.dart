import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:testacer/src/localization.dart';
import 'package:testacer/src/question_format/models.dart';
import 'package:testacer/src/questions/question_set_repository.dart';
import 'package:testacer/src/quiz/progress.dart';
import 'package:testacer/src/quiz/quiz_length.dart';
import 'package:testacer/src/ui/emphasized_text.dart';
import 'package:testacer/src/ui/quiz_screen.dart';
import 'package:testacer/src/ui/trivia_sheet.dart';

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

    expect(find.text(hu.quizQuestionOf(1, 5)), findsOneWidget);
    expect(find.byType(EmphasizedText), findsNothing);

    await tapVisible(tester, find.text(wrongText(tester)));

    expect(find.text(hu.answerWrong), findsOneWidget);
    expect(find.text(hu.correctAnswerLabel), findsOneWidget);
    expect(find.byType(EmphasizedText), findsOneWidget);
    expect(t.progress.saves.single, contains('box0'));
  });

  testWidgets('Következő is right below the options, above the feedback',
      (tester) async {
    await pumpQuiz(tester, QuizLength.five);
    final wrong = wrongText(tester);
    await tapVisible(tester, find.text(wrong));

    final next = tester.getTopLeft(find.text(hu.nextQuestion)).dy;
    expect(next, greaterThan(tester.getTopLeft(find.text(wrong)).dy));
    expect(next, lessThan(tester.getTopLeft(find.text(hu.answerWrong)).dy));
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
    // 3 questions, 5 asked: two of them come again (D-019).
    await pumpQuiz(tester, QuizLength.five);

    for (var i = 0; i < 5; i++) {
      expect(find.text(hu.quizQuestionOf(i + 1, 5)), findsOneWidget);
      await tapVisible(tester, find.text(correctText(tester)).first);
      await tapVisible(
        tester,
        find.text(i < 4 ? hu.nextQuestion : hu.finishQuiz),
      );
    }

    expect(find.text(hu.summaryTitle), findsOneWidget);
    expect(find.text(hu.summaryScore(5, 5)), findsOneWidget);
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
    await pumpQuiz(tester, QuizLength.twentyFive);
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

  testWidgets('the note is bluish on light, yellowish on dark', (tester) async {
    Future<Color?> noteColor(Brightness brightness) async {
      await tester.pumpWidget(const SizedBox());
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(brightness: brightness),
          locale: const Locale('hu'),
          localizationsDelegates: appLocalizationsDelegates,
          supportedLocales: appSupportedLocales,
          home: QuizScreen(
            services: t.services,
            user: testUser(),
            questionSet: set,
            length: QuizLength.twentyFive,
            random: Random(1),
          ),
        ),
      );
      await tester.pumpAndSettle();
      for (var i = 0; i < 3; i++) {
        if (find.text('A 2. kyu övszíne kék.').evaluate().isNotEmpty) break;
        await tapVisible(tester, find.text(correctText(tester)).first);
        await tapVisible(tester, find.text(hu.nextQuestion));
      }
      await tapVisible(tester, find.text('A 2. kyu övszíne zöld.'));
      return tester.widget<Text>(find.text('megjegyzés')).style?.color;
    }

    expect(await noteColor(Brightness.light), noteColorLight);
    expect(await noteColor(Brightness.dark), noteColorDark);
  });

  group('timer', () {
    late DateTime time;

    Future<void> pumpTimed(WidgetTester tester, QuizLength length) async {
      time = DateTime(2026, 11, 25, 10);
      await tester.pumpWidget(
        localized(
          QuizScreen(
            services: t.services,
            user: testUser(),
            questionSet: set,
            length: length,
            random: Random(1),
            now: () => time,
          ),
        ),
      );
      await tester.pumpAndSettle();
    }

    testWidgets('starts with the first question and keeps counting',
        (tester) async {
      await pumpTimed(tester, QuizLength.five);
      expect(find.text('00:00:00'), findsOneWidget);

      time = time.add(const Duration(hours: 1, minutes: 2, seconds: 3));
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('01:02:03'), findsOneWidget);
    });

    testWidgets('stops when the last question is answered; the result shows it',
        (tester) async {
      await pumpTimed(tester, QuizLength.one);
      time = time.add(const Duration(seconds: 42));
      await tapVisible(tester, find.text(wrongText(tester)));

      time = time.add(const Duration(minutes: 5));
      await tester.pump(const Duration(seconds: 1));
      expect(find.text('00:00:42'), findsOneWidget);

      await tapVisible(tester, find.text(hu.finishQuiz));
      expect(find.text(hu.summaryTime('00:00:42')), findsOneWidget);
    });

    testWidgets('keeps running while questions are left', (tester) async {
      await pumpTimed(tester, QuizLength.five);
      await tapVisible(tester, find.text(wrongText(tester)));

      time = time.add(const Duration(seconds: 7));
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('00:00:07'), findsOneWidget);
    });
  });

  group('trivia (D-016)', () {
    const tatami = Trivia(
      title: 'A tatamiról',
      body: 'Tudtad, hogy\n- a ***„Tatami”*** **szalmából** készült?',
      keywords: ['tatami'],
    );
    const kyu = Trivia(title: 'Övek', body: 'Övszínek…', keywords: ['kyu']);

    Future<void> answer(WidgetTester tester, String startKey, {bool right = true}) async {
      t.questionSets.trivia['set1'] = [tatami, kyu];
      await tester.pumpWidget(
        localized(
          QuizScreen(
            services: t.services,
            user: testUser(),
            questionSet: set,
            length: QuizLength.one,
            startKey: startKey,
            random: Random(1),
          ),
        ),
      );
      await tester.pumpAndSettle();
      final question = sampleQuestions().firstWhere((q) => q.key == startKey);
      final option = right ? question.correct : question.wrong.first;
      await tester.tap(find.text(option.text));
      await tester.pumpAndSettle();
    }

    testWidgets('pops up after a right answer when a keyword matches', (tester) async {
      await answer(tester, sampleQuestions()[2].key); // „Tatami”
      expect(find.byType(TriviaSheet), findsOneWidget);
      expect(find.text('A tatamiról'), findsOneWidget);
      expect(find.text('Övek'), findsNothing);

      await tester.tap(find.text(hu.triviaClose));
      await tester.pumpAndSettle();
      expect(find.byType(TriviaSheet), findsNothing);
      expect(find.text(hu.answerCorrect), findsOneWidget); // feedback still there
    });

    testWidgets('and after a wrong one', (tester) async {
      await answer(tester, sampleQuestions()[1].key, right: false); // 2. kyu
      expect(find.text('Övek'), findsOneWidget);
    });

    testWidgets('nothing pops up without a matching keyword', (tester) async {
      await answer(tester, sampleQuestions()[0].key); // „Yoshi”
      expect(find.byType(TriviaSheet), findsNothing);
    });
  });
}
