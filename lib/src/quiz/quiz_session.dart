import 'dart:math';

import '../question_format/models.dart';
import 'progress.dart';
import 'quiz_length.dart';
import 'selection.dart';

/// The question on screen, with its options in the shown (shuffled) order.
class CurrentQuestion {
  CurrentQuestion(this.question, this.options, this.correctIndex);

  final Question question;
  final List<QuestionOption> options;
  final int correctIndex;

  /// The index the user chose, once answered.
  int? chosenIndex;

  bool get isAnswered => chosenIndex != null;
  bool get isCorrect => chosenIndex == correctIndex;
}

/// One quiz run: picks questions (D-006), shuffles options (D-007) and
/// updates the progress records. Storage is the caller's job.
class QuizSession {
  QuizSession({
    required List<Question> questions,
    required Map<String, ItemProgress> progress,
    required this.length,
    QuestionPicker? picker,
    Random? random,
    DateTime Function()? clock,
  })  : _byKey = {for (final q in questions) q.key: q},
        _progress = Map.of(progress),
        _picker = picker ?? QuestionPicker(random: random),
        _random = random ?? Random(),
        _clock = clock ?? DateTime.now {
    final eligible = questions
        .where((q) => !(_progress[q.key]?.skippable ?? false))
        .length;
    final count = length.count;
    total = switch (length) {
      QuizLength.endless => null,
      QuizLength.all => eligible,
      _ => min(count!, eligible),
    };
  }

  final Map<String, Question> _byKey;
  final Map<String, ItemProgress> _progress;
  final QuestionPicker _picker;
  final Random _random;
  final DateTime Function() _clock;
  final QuizLength length;
  final _asked = <String>[];

  /// Number of questions in this quiz; `null` for an endless quiz.
  late final int? total;

  int answered = 0;
  int correctAnswers = 0;
  CurrentQuestion? current;

  /// Progress records including the answers given in this session.
  Map<String, ItemProgress> get progress => Map.unmodifiable(_progress);

  /// 1-based number of the current question.
  int get number => _asked.length;

  bool get isOver => current == null;

  /// Moves to the next question. Returns false when the quiz is over
  /// (length reached, or nothing left to ask).
  bool next() {
    final limit = total;
    if (limit != null && _asked.length >= limit) {
      current = null;
      return false;
    }
    final key = _picker.pick(
      _byKey.keys.toList(),
      _progress,
      recent: _asked,
      exclude: length == QuizLength.endless ? const {} : _asked.toSet(),
    );
    if (key == null) {
      current = null;
      return false;
    }
    _asked.add(key);
    final question = _byKey[key]!;
    final options = question.options.toList()..shuffle(_random);
    current = CurrentQuestion(
      question,
      options,
      options.indexOf(question.correct),
    );
    return true;
  }

  /// Records the answer to the current question; returns its new progress.
  ItemProgress answer(int optionIndex) {
    final question = current!;
    assert(!question.isAnswered, 'already answered');
    question.chosenIndex = optionIndex;
    answered++;
    if (question.isCorrect) correctAnswers++;
    final key = question.question.key;
    final updated = (_progress[key] ?? const ItemProgress())
        .recordAnswer(correct: question.isCorrect, at: _clock());
    _progress[key] = updated;
    return updated;
  }

  /// Marks a question skippable (or undoes it); returns its new progress.
  ItemProgress setSkippable(String key, bool value) {
    final updated = (_progress[key] ?? const ItemProgress()).withSkippable(value);
    _progress[key] = updated;
    return updated;
  }
}
