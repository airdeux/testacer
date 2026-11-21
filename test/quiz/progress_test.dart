import 'package:flutter_test/flutter_test.dart';
import 'package:testacer/src/quiz/progress.dart';

void main() {
  final at = DateTime.utc(2026, 11, 21, 18);

  test('a correct answer moves the question up one box, at most to 4', () {
    var progress = const ItemProgress();
    for (var i = 0; i < 6; i++) {
      progress = progress.recordAnswer(correct: true, at: at);
    }

    expect(progress.box, ItemProgress.maxBox);
    expect(progress.seen, 6);
    expect(progress.correct, 6);
    expect(progress.lastAt, at);
  });

  test('a wrong answer moves it back to box 0', () {
    final progress = const ItemProgress(box: 3, seen: 3, correct: 3)
        .recordAnswer(correct: false, at: at);

    expect(progress.box, 0);
    expect(progress.wrong, 1);
    expect(progress.seen, 4);
  });

  test('answering keeps the skippable flag', () {
    final progress = const ItemProgress(skippable: true)
        .recordAnswer(correct: true, at: at);

    expect(progress.skippable, isTrue);
  });

  test('survives a round trip through a map', () {
    final original = const ItemProgress(box: 2, seen: 5, correct: 3, wrong: 2)
        .withSkippable(true)
        .recordAnswer(correct: true, at: at);

    final copy = ItemProgress.fromMap(original.toMap());

    expect(copy.toMap(), original.toMap());
  });

  test('reads missing or odd fields safely', () {
    final progress = ItemProgress.fromMap({'box': 9, 'seen': 2.0});

    expect(progress.box, ItemProgress.maxBox);
    expect(progress.seen, 2);
    expect(progress.skippable, isFalse);
    expect(progress.lastAt, isNull);
  });
}
