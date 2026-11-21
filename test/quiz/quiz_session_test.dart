import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:testacer/src/question_format/models.dart';
import 'package:testacer/src/quiz/progress.dart';
import 'package:testacer/src/quiz/quiz_length.dart';
import 'package:testacer/src/quiz/quiz_session.dart';

Question question(int n) => Question(
      order: n,
      correct: QuestionOption(text: 'helyes $n'),
      wrong: [
        QuestionOption(text: 'rossz $n a'),
        QuestionOption(text: 'rossz $n b'),
        QuestionOption(text: 'rossz $n c'),
      ],
      line: n,
    );

void main() {
  final questions = [for (var i = 1; i <= 12; i++) question(i)];
  final at = DateTime.utc(2026, 11, 21);

  QuizSession session(
    QuizLength length, {
    Map<String, ItemProgress> progress = const {},
  }) =>
      QuizSession(
        questions: questions,
        progress: progress,
        length: length,
        random: Random(42),
        clock: () => at,
      );

  test('a 10-question quiz asks 10 different questions, then ends', () {
    final quiz = session(QuizLength.ten);
    final seen = <String>{};

    while (quiz.next()) {
      seen.add(quiz.current!.question.key);
      quiz.answer(0);
    }

    expect(quiz.total, 10);
    expect(quiz.answered, 10);
    expect(seen, hasLength(10));
    expect(quiz.isOver, isTrue);
  });

  test('"all" asks every non-skippable question once', () {
    final skipped = questions.first.key;
    final quiz = session(
      QuizLength.all,
      progress: {skipped: const ItemProgress(skippable: true)},
    );
    final seen = <String>[];

    while (quiz.next()) {
      seen.add(quiz.current!.question.key);
      quiz.answer(0);
    }

    expect(seen, hasLength(11));
    expect(seen.toSet(), hasLength(11));
    expect(seen, isNot(contains(skipped)));
  });

  test('an endless quiz keeps going', () {
    final quiz = session(QuizLength.endless);

    for (var i = 0; i < 40; i++) {
      expect(quiz.next(), isTrue);
      quiz.answer(0);
    }
    expect(quiz.total, isNull);
  });

  test('options are shuffled and the correct index is tracked', () {
    final quiz = session(QuizLength.ten);
    final positions = <int>{};

    while (quiz.next()) {
      final current = quiz.current!;
      expect(current.options, hasLength(4));
      expect(current.options[current.correctIndex], same(current.question.correct));
      positions.add(current.correctIndex);
      quiz.answer(current.correctIndex);
    }

    expect(positions.length, greaterThan(1), reason: 'not always first');
  });

  test('answers update the score and the progress records', () {
    final quiz = session(QuizLength.five)..next();
    final first = quiz.current!;
    final wrongIndex = (first.correctIndex + 1) % 4;

    final wrong = quiz.answer(wrongIndex);
    quiz.next();
    final right = quiz.answer(quiz.current!.correctIndex);

    expect(first.isCorrect, isFalse);
    expect(wrong.box, 0);
    expect(wrong.wrong, 1);
    expect(right.box, 1);
    expect(quiz.answered, 2);
    expect(quiz.correctAnswers, 1);
    expect(quiz.progress[first.question.key]!.lastAt, at);
  });

  test('marking a question skippable takes it out of the rest of the quiz', () {
    final quiz = session(QuizLength.endless)..next();
    final key = quiz.current!.question.key;
    quiz.answer(0);
    quiz.setSkippable(key, true);

    for (var i = 0; i < 30; i++) {
      quiz.next();
      expect(quiz.current!.question.key, isNot(key));
      quiz.answer(0);
    }
  });

  test('a quiz with nothing to ask ends at once', () {
    final quiz = session(
      QuizLength.ten,
      progress: {
        for (final q in questions) q.key: const ItemProgress(skippable: true),
      },
    );

    expect(quiz.total, 0);
    expect(quiz.next(), isFalse);
  });
}
