import 'dart:math';

/// A user's record for one question (stored in `users/{uid}/progress/{setId}`).
class ItemProgress {
  const ItemProgress({
    this.box = 0,
    this.seen = 0,
    this.correct = 0,
    this.wrong = 0,
    this.lastAt,
    this.skippable = false,
  });

  /// Leitner box 0–[maxBox]: a wrong answer moves the question to box 0, a
  /// correct one moves it up one box (decision D-006).
  static const maxBox = 4;

  final int box;
  final int seen;
  final int correct;
  final int wrong;
  final DateTime? lastAt;

  /// Marked as easy / well known: never asked again until undone.
  final bool skippable;

  ItemProgress recordAnswer({required bool correct, required DateTime at}) =>
      ItemProgress(
        box: correct ? min(box + 1, maxBox) : 0,
        seen: seen + 1,
        correct: this.correct + (correct ? 1 : 0),
        wrong: wrong + (correct ? 0 : 1),
        lastAt: at,
        skippable: skippable,
      );

  ItemProgress withSkippable(bool value) => ItemProgress(
        box: box,
        seen: seen,
        correct: correct,
        wrong: wrong,
        lastAt: lastAt,
        skippable: value,
      );

  Map<String, Object?> toMap() => {
        'box': box,
        'seen': seen,
        'correct': correct,
        'wrong': wrong,
        'lastAt': lastAt?.millisecondsSinceEpoch,
        'skippable': skippable,
      };

  factory ItemProgress.fromMap(Map<String, Object?> map) {
    int read(String key) => (map[key] as num?)?.toInt() ?? 0;
    final lastAt = map['lastAt'] as num?;
    return ItemProgress(
      box: read('box').clamp(0, maxBox),
      seen: read('seen'),
      correct: read('correct'),
      wrong: read('wrong'),
      lastAt: lastAt == null
          ? null
          : DateTime.fromMillisecondsSinceEpoch(lastAt.toInt()),
      skippable: map['skippable'] == true,
    );
  }
}
