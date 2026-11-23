import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:testacer/src/quiz/progress.dart';
import 'package:testacer/src/quiz/selection.dart';

void main() {
  final keys = [for (var i = 0; i < 10; i++) 'q$i'];

  test('never picks a skippable question', () {
    final picker = QuestionPicker(random: Random(1));
    final progress = {
      for (final key in keys) key: const ItemProgress(skippable: true),
    }..['q3'] = const ItemProgress();

    for (var i = 0; i < 50; i++) {
      expect(picker.pick(keys, progress), 'q3');
    }
  });

  test('returns null when everything is skippable or excluded', () {
    final picker = QuestionPicker(random: Random(1));
    final progress = {for (final key in keys) key: const ItemProgress(skippable: true)};

    expect(picker.pick(keys, progress), isNull);
    expect(picker.pick(keys, const {}, exclude: keys.toSet()), isNull);
  });

  test('questions answered wrong come up far more often than known ones', () {
    final picker = QuestionPicker(random: Random(7), recentWindow: 0);
    final progress = {
      for (final key in keys) key: const ItemProgress(box: 4),
    }..['q0'] = const ItemProgress(box: 0, wrong: 1);
    final counts = <String, int>{};

    for (var i = 0; i < 5000; i++) {
      final key = picker.pick(keys, progress)!;
      counts[key] = (counts[key] ?? 0) + 1;
    }

    // Weight 8 vs 0.5 each: q0 should get 8 / (8 + 9 × 0.5) ≈ 64 %.
    expect(counts['q0']! / 5000, closeTo(0.64, 0.04));
    expect(counts['q0']!, greaterThan(10 * counts['q1']!));
  });

  test('does not repeat any of the last 5 questions', () {
    final picker = QuestionPicker(random: Random(3));
    final recent = <String>[];

    for (var i = 0; i < 200; i++) {
      final key = picker.pick(keys, const {}, recent: recent)!;
      expect(recent.reversed.take(5), isNot(contains(key)));
      recent.add(key);
    }
  });

  test('with only two questions it still avoids the last one', () {
    final picker = QuestionPicker(random: Random(3));
    final recent = <String>['a'];

    for (var i = 0; i < 20; i++) {
      final key = picker.pick(['a', 'b'], const {}, recent: recent)!;
      expect(key, isNot(recent.last));
      recent.add(key);
    }
  });

  test('pickFresh takes a never-seen question first, then the least seen', () {
    final picker = QuestionPicker(random: Random(2));
    final progress = {
      for (final key in keys) key: const ItemProgress(box: 4, seen: 5, correct: 5),
    }
      ..['q1'] = const ItemProgress(box: 1, seen: 1, correct: 1)
      ..['q2'] = const ItemProgress(box: 0, seen: 2, wrong: 2)
      ..remove('q7') // never seen
      ..['q8'] = const ItemProgress(skippable: true); // never seen, but skippable

    expect(picker.pickFresh(keys, progress), 'q7');
    expect(picker.pickFresh(keys, progress, exclude: {'q7'}), 'q1');
    expect(picker.pickFresh(keys, progress, exclude: {'q7', 'q1'}), 'q2');
    // Recently asked ones wait, as with pick.
    expect(picker.pickFresh(keys, progress, recent: ['q7']), 'q1');
  });

  test('pickFresh chooses randomly among equally fresh questions', () {
    final picker = QuestionPicker(random: Random(3));
    final picked = {for (var i = 0; i < 200; i++) picker.pickFresh(keys, const {})};
    expect(picked, keys.toSet());
  });
}
