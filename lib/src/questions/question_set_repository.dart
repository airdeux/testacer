import '../question_format/models.dart';

/// Summary of a stored question set (`questionSets/{setId}`).
class QuestionSetInfo {
  const QuestionSetInfo({
    required this.id,
    required this.title,
    required this.questionCount,
    this.importedAt,
  });

  final String id;
  final String title;
  final int questionCount;
  final DateTime? importedAt;
}

/// Question sets in Firestore (D-008). Implemented with Firestore and with a
/// fake in the tests.
abstract interface class QuestionSetRepository {
  /// All sets, sorted by title.
  Stream<List<QuestionSetInfo>> watchSets();

  /// The questions of a set, sorted by their number.
  Future<List<Question>> loadQuestions(String setId);

  /// Creates a set (when [setId] is null) or replaces the questions of an
  /// existing one. Questions keep their keys, so progress on unchanged
  /// questions is kept; questions missing from the new file are removed.
  /// Returns the set's id. Admins only.
  Future<String> importSet({
    String? setId,
    required String title,
    required String sourceFile,
    required List<Question> questions,
  });
}
