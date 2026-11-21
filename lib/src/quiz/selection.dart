import 'dart:math';

import 'progress.dart';

/// Selection weight per Leitner box (D-006): questions answered wrong
/// (box 0) come up 16 times as often as well-known ones (box 4).
const leitnerWeights = <double>[8, 4, 2, 1, 0.5];

double weightOf(ItemProgress? progress) =>
    leitnerWeights[(progress?.box ?? 0).clamp(0, ItemProgress.maxBox)];

/// Picks the next question by weighted random choice.
class QuestionPicker {
  QuestionPicker({Random? random, this.recentWindow = 5})
      : _random = random ?? Random();

  final Random _random;

  /// How many of the most recently asked questions are left out.
  final int recentWindow;

  /// Returns the key of the next question, or `null` when every question is
  /// skippable or excluded.
  ///
  /// [recent] is the list of asked keys, oldest first. Keys in [exclude] are
  /// never picked (used to avoid repeats within one quiz).
  String? pick(
    List<String> keys,
    Map<String, ItemProgress> progress, {
    List<String> recent = const [],
    Set<String> exclude = const {},
  }) {
    final candidates = [
      for (final key in keys)
        if (!(progress[key]?.skippable ?? false) && !exclude.contains(key)) key,
    ];
    if (candidates.isEmpty) return null;

    final recentKeys = recent.reversed.take(recentWindow).toSet();
    var pool = [for (final key in candidates) if (!recentKeys.contains(key)) key];
    if (pool.isEmpty && recent.isNotEmpty) {
      // Few questions left: only avoid asking the same one twice in a row.
      pool = [for (final key in candidates) if (key != recent.last) key];
    }
    if (pool.isEmpty) pool = candidates;

    final weights = [for (final key in pool) weightOf(progress[key])];
    var target = _random.nextDouble() * weights.reduce((a, b) => a + b);
    for (var i = 0; i < pool.length; i++) {
      target -= weights[i];
      if (target < 0) return pool[i];
    }
    return pool.last;
  }
}
