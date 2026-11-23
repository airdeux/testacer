import 'package:flutter_test/flutter_test.dart';
import 'package:testacer/src/question_format/models.dart';
import 'package:testacer/src/questions/key_history.dart';
import 'package:testacer/src/questions/question_codec.dart';
import 'package:testacer/src/quiz/progress.dart';

Question q(int order, String correct, {List<String> previous = const []}) => Question(
      order: order,
      correct: QuestionOption(text: correct),
      wrong: [QuestionOption(text: 'rossz $order')],
      line: order,
      previousKeys: previous,
    );

void main() {
  test('a fixed typo at the same number remembers the old key', () {
    final old = [q(1, 'Egy'), q(2, 'Anton Geesig nyert'), q(3, 'Három')];
    final fixed = [q(1, 'Egy'), q(2, 'Anton Geesink nyert'), q(4, 'Négy')];

    final result = withKeyHistory(fixed, old);

    expect(result[0].previousKeys, isEmpty); // unchanged
    expect(result[1].previousKeys, [old[1].key]); // same number, new text
    expect(result[2].previousKeys, isEmpty); // new number: a new question
  });

  test('history adds up over several fixes and is kept when unchanged', () {
    final first = q(5, 'Első');
    final second = withKeyHistory([q(5, 'Második')], [first]).single;
    final third = withKeyHistory([q(5, 'Harmadik')], [second]).single;
    expect(third.previousKeys, [second.key, first.key]);

    final again = withKeyHistory([q(5, 'Harmadik')], [third]).single;
    expect(again.previousKeys, third.previousKeys);
  });

  test('progress under an old key is used when the new key has none', () {
    final question = q(2, 'Anton Geesink nyert', previous: ['old2', 'older2']);
    const record = ItemProgress(box: 3, seen: 4, correct: 4, skippable: true);

    expect(carryOverProgress({'older2': record}, [question])[question.key], record);
    // A record under the current key wins.
    const fresh = ItemProgress(box: 1, seen: 1, correct: 1);
    expect(
      carryOverProgress({question.key: fresh, 'old2': record}, [question])[question.key],
      fresh,
    );
  });

  test('previous keys and trivia survive the Firestore format', () {
    final question = q(7, 'Hét', previous: ['a', 'b']);
    expect(questionFromMap(questionToMap(question)).previousKeys, ['a', 'b']);
    expect(questionToMap(q(7, 'Hét')).containsKey('previousKeys'), isFalse);

    const trivia = Trivia(title: 'Kano', body: '- **1860**', keywords: ['Kano']);
    final copy = triviaFromMap(triviaToMap(trivia))!;
    expect([copy.title, copy.body, copy.keywords], ['Kano', '- **1860**', ['Kano']]);
    expect(triviaFromMap({'title': 1}), isNull);
  });
}
