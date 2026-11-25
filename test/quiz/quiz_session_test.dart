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

  test('a reminder quiz starts with its question unless it is skippable', () {
    final key = questions[7].key;
    final quiz = QuizSession(
      questions: questions,
      progress: const {},
      length: QuizLength.endless,
      firstKey: key,
      random: Random(1),
    );
    expect(quiz.next(), isTrue);
    expect(quiz.current!.question.key, key);
    expect(quiz.next(), isTrue);
    expect(quiz.current!.question.key, isNot(key));

    final skipped = QuizSession(
      questions: questions,
      progress: {key: const ItemProgress(skippable: true)},
      length: QuizLength.endless,
      firstKey: key,
      random: Random(1),
    );
    skipped.next();
    expect(skipped.current!.question.key, isNot(key));
  });

  group('at least half of a quiz is new (D-015)', () {
    List<String> run(QuizSession quiz) {
      final keys = <String>[];
      while (quiz.next()) {
        keys.add(quiz.current!.question.key);
        quiz.answer(quiz.current!.correctIndex);
      }
      return keys;
    }

    // Everything well known, except a few never-seen questions.
    Map<String, ItemProgress> knownExcept(Set<int> unseen, {Map<int, int> seenOnce = const {}}) => {
          for (var i = 0; i < questions.length; i++)
            if (!unseen.contains(i))
              questions[i].key: seenOnce.containsKey(i)
                  ? const ItemProgress(box: 1, seen: 1, correct: 1)
                  : const ItemProgress(box: 4, seen: 6, correct: 6),
        };

    test('5 questions: 3 new ones when there are enough', () {
      for (var seed = 0; seed < 20; seed++) {
        final quiz = QuizSession(
          questions: questions,
          progress: knownExcept({2, 5, 7, 9}),
          length: QuizLength.five,
          random: Random(seed),
        );
        final keys = run(quiz);
        final unseen = {2, 5, 7, 9}.map((i) => questions[i].key).toSet();
        expect(keys, hasLength(5));
        expect(keys.where(unseen.contains).length, greaterThanOrEqualTo(3));
        expect(unseen, contains(keys.first)); // the 1st, 3rd and 5th
      }
    });

    test('10 questions: 5 new ones', () {
      final unseenIdx = {0, 1, 2, 3, 4, 5};
      final quiz = QuizSession(
        questions: questions,
        progress: knownExcept(unseenIdx),
        length: QuizLength.ten,
        random: Random(4),
      );
      final keys = run(quiz);
      final unseen = unseenIdx.map((i) => questions[i].key).toSet();
      expect(keys.where(unseen.contains).length, greaterThanOrEqualTo(5));
    });

    test('too few new ones: once-seen questions fill the rest', () {
      for (var seed = 0; seed < 20; seed++) {
        final quiz = QuizSession(
          questions: questions,
          // One never seen, two seen once, the rest seen six times.
          progress: knownExcept({3}, seenOnce: {6: 1, 8: 1}),
          length: QuizLength.five,
          random: Random(seed),
        );
        final keys = run(quiz);
        // The new one and both once-seen ones are in (the in-between picks
        // may take one of them too, which only adds to the count).
        expect(keys.first, questions[3].key);
        expect(keys, containsAll([questions[6].key, questions[8].key]));
      }
    });

    test('a single question is picked the usual way', () {
      final quiz = QuizSession(
        questions: questions,
        progress: knownExcept({3}),
        length: QuizLength.one,
        random: Random(1),
      );
      expect(run(quiz), hasLength(1));
    });

    test('endless: the new ones come within the first five', () {
      final quiz = QuizSession(
        questions: questions,
        progress: knownExcept({1, 4, 10}),
        length: QuizLength.endless,
        random: Random(5),
      );
      final keys = <String>[];
      for (var i = 0; i < 5 && quiz.next(); i++) {
        keys.add(quiz.current!.question.key);
        quiz.answer(quiz.current!.correctIndex);
      }
      expect(
        keys,
        containsAll([questions[1].key, questions[4].key, questions[10].key]),
      );
    });
  });

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

  test('with fewer questions left than chosen, they come again in rounds',
      () {
    // D-019: 11 non-skippable questions, 25 asked: 11 + 11 + 3.
    final skipped = questions.first.key;
    final quiz = session(
      QuizLength.twentyFive,
      progress: {skipped: const ItemProgress(skippable: true)},
    );
    final seen = <String>[];

    while (quiz.next()) {
      seen.add(quiz.current!.question.key);
      quiz.answer(0);
    }

    expect(quiz.total, 25);
    expect(seen, hasLength(25));
    expect(seen, isNot(contains(skipped)));
    expect(seen.sublist(0, 11).toSet(), hasLength(11));
    expect(seen.sublist(11, 22).toSet(), hasLength(11));
    expect(seen.sublist(22).toSet(), hasLength(3));
    for (var i = 1; i < seen.length; i++) {
      expect(seen[i], isNot(seen[i - 1]), reason: 'no question twice in a row');
    }
  });

  test('a single question left is asked again and again', () {
    final quiz = session(
      QuizLength.five,
      progress: {
        for (final q in questions.skip(1)) q.key: const ItemProgress(skippable: true),
      },
    );
    var asked = 0;
    while (quiz.next()) {
      expect(quiz.current!.question.key, questions.first.key);
      quiz.answer(0);
      asked++;
    }
    expect(asked, 5);
  });

  test('everything skippable: nothing to ask', () {
    final quiz = session(
      QuizLength.ten,
      progress: {
        for (final q in questions) q.key: const ItemProgress(skippable: true),
      },
    );
    expect(quiz.total, 0);
    expect(quiz.next(), isFalse);
  });

  test('questions marked skippable during the quiz are not repeated', () {
    final quiz = session(QuizLength.twentyFive);
    final seen = <String>[];
    while (quiz.next()) {
      final key = quiz.current!.question.key;
      seen.add(key);
      quiz.answer(0);
      // The first 10 of the 12 get marked „Bébikönnyű” as they come: only
      // the other two can come again.
      if (seen.length <= 10) quiz.setSkippable(key, true);
    }
    expect(seen, hasLength(25));
    expect(seen.sublist(12).toSet(), seen.sublist(10, 12).toSet());
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
