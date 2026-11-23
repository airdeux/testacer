import '../question_format/models.dart';
import '../quiz/progress.dart';

/// How many earlier keys a question remembers.
const maxPreviousKeys = 10;

/// Prepares [incoming] questions for replacing [existing] ones in a set
/// (D-017). A question's key comes from its correct answer, so fixing a typo
/// there gives it a new key; when a question with a new key has the same
/// number as one that disappears, it remembers that one's key (and its
/// history), so progress recorded under it is carried over. Unchanged
/// questions keep their history.
List<Question> withKeyHistory(
  List<Question> incoming,
  Iterable<Question> existing,
) {
  final existingByKey = {for (final question in existing) question.key: question};
  final incomingKeys = {for (final question in incoming) question.key};
  final removedByOrder = {
    for (final question in existing)
      if (!incomingKeys.contains(question.key)) question.order: question,
  };
  return [
    for (final question in incoming)
      if (existingByKey[question.key] case final same?)
        question.withPreviousKeys(same.previousKeys)
      else if (removedByOrder[question.order] case final old?)
        question.withPreviousKeys(
          [old.key, ...old.previousKeys].take(maxPreviousKeys).toList(),
        )
      else
        question,
  ];
}

/// [progress] for [questions], using a record kept under an earlier key of a
/// question when there is none under its current key (D-017).
Map<String, ItemProgress> carryOverProgress(
  Map<String, ItemProgress> progress,
  Iterable<Question> questions,
) {
  final result = Map.of(progress);
  for (final question in questions) {
    if (result.containsKey(question.key)) continue;
    for (final key in question.previousKeys) {
      final item = progress[key];
      if (item != null) {
        result[question.key] = item;
        break;
      }
    }
  }
  return result;
}
