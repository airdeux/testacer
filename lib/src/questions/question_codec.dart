import '../question_format/models.dart';

/// Firestore representation of a question
/// (`questionSets/{setId}/questions/{key}`, see docs/architecture.md).
Map<String, Object?> questionToMap(Question question) => {
      'order': question.order,
      if (question.prompt != null) 'prompt': question.prompt,
      'correct': _optionToMap(question.correct),
      'wrong': [for (final option in question.wrong) _optionToMap(option)],
      if (question.previousKeys.isNotEmpty) 'previousKeys': question.previousKeys,
    };

Question questionFromMap(Map<String, Object?> map) => Question(
      order: (map['order'] as num).toInt(),
      prompt: map['prompt'] as String?,
      correct: _optionFromMap(map['correct']! as Map<String, Object?>),
      wrong: [
        for (final option in map['wrong']! as List<Object?>)
          _optionFromMap(option! as Map<String, Object?>),
      ],
      line: 0,
      previousKeys: [
        for (final key in (map['previousKeys'] as List<Object?>?) ?? const [])
          if (key is String) key,
      ],
    );

/// Firestore representation of a trivia item (in the set document's
/// `trivia` list, D-016).
Map<String, Object?> triviaToMap(Trivia trivia) => {
      'title': trivia.title,
      'body': trivia.body,
      'keywords': trivia.keywords,
    };

Trivia? triviaFromMap(Object? data) => switch (data) {
      {
        'title': final String title,
        'body': final String body,
        'keywords': final List<Object?> keywords,
      } =>
        Trivia(
          title: title,
          body: body,
          keywords: [for (final k in keywords) if (k is String) k],
        ),
      _ => null,
    };

Map<String, Object?> _optionToMap(QuestionOption option) => {
      'text': option.text,
      if (option.marks.isNotEmpty)
        'marks': [
          for (final mark in option.marks)
            {'start': mark.start, 'end': mark.end, 'kind': mark.kind.name},
        ],
      if (option.note != null) 'note': option.note,
    };

QuestionOption _optionFromMap(Map<String, Object?> map) => QuestionOption(
      text: map['text']! as String,
      marks: [
        for (final mark in (map['marks'] as List<Object?>?) ?? const [])
          if (mark case {'start': final num start, 'end': final num end, 'kind': final String kind})
            EmphasisMark(
              start.toInt(),
              end.toInt(),
              MarkKind.values.byName(kind),
            ),
      ],
      note: map['note'] as String?,
    );
