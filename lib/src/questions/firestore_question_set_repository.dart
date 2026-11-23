import 'package:cloud_firestore/cloud_firestore.dart';

import '../question_format/models.dart';
import 'key_history.dart';
import 'question_codec.dart';
import 'question_set_repository.dart';

class FirestoreQuestionSetRepository implements QuestionSetRepository {
  FirestoreQuestionSetRepository({FirebaseFirestore? firestore})
      : _db = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _db;

  /// Firestore allows 500 writes per batch; stay well below.
  static const _batchSize = 400;

  CollectionReference<Map<String, dynamic>> get _sets =>
      _db.collection('questionSets');

  @override
  Stream<List<QuestionSetInfo>> watchSets() => _sets.snapshots().map(
        (query) => [
          for (final doc in query.docs)
            QuestionSetInfo(
              id: doc.id,
              title: (doc.data()['title'] as String?) ?? doc.id,
              questionCount: (doc.data()['questionCount'] as num?)?.toInt() ?? 0,
              importedAt: (doc.data()['importedAt'] as Timestamp?)?.toDate(),
            ),
        ]..sort((a, b) => a.title.compareTo(b.title)),
      );

  @override
  Future<List<Question>> loadQuestions(String setId) async {
    final query = await _sets.doc(setId).collection('questions').get();
    return [for (final doc in query.docs) questionFromMap(doc.data())]
      ..sort((a, b) => a.order.compareTo(b.order));
  }

  @override
  Future<List<Trivia>> loadTrivia(String setId) async {
    final snapshot = await _sets.doc(setId).get();
    final items = snapshot.data()?['trivia'] as List<Object?>? ?? const [];
    return [for (final item in items) ?triviaFromMap(item)];
  }

  @override
  Future<String> importSet({
    String? setId,
    required String title,
    required String sourceFile,
    required List<Question> questions,
    List<Trivia> trivia = const [],
  }) async {
    final setDoc = setId == null ? _sets.doc() : _sets.doc(setId);
    final questionsRef = setDoc.collection('questions');
    final existingDocs =
        setId == null ? const [] : (await questionsRef.get()).docs;
    final oldKeys = {for (final doc in existingDocs) doc.id};
    final incoming = withKeyHistory(questions, [
      for (final doc in existingDocs) questionFromMap(doc.data()),
    ]);
    final newKeys = {for (final q in incoming) q.key};

    final writes = <void Function(WriteBatch)>[
      (batch) => batch.set(setDoc, {
            'title': title,
            'sourceFile': sourceFile,
            'questionCount': questions.length,
            'importedAt': FieldValue.serverTimestamp(),
            'trivia': [for (final item in trivia) triviaToMap(item)],
          }),
      for (final question in incoming)
        (batch) => batch.set(questionsRef.doc(question.key), questionToMap(question)),
      for (final key in oldKeys.difference(newKeys))
        (batch) => batch.delete(questionsRef.doc(key)),
    ];
    for (var start = 0; start < writes.length; start += _batchSize) {
      final batch = _db.batch();
      for (final write in writes.skip(start).take(_batchSize)) {
        write(batch);
      }
      await batch.commit();
    }
    return setDoc.id;
  }
}
