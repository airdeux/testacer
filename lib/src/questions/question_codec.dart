import '../question_format/models.dart';

/// Firestore representation of a question
/// (`questionSets/{setId}/questions/{key}`, see docs/architecture.md).
Map<String, Object?> questionToMap(Question question) => {
      'order': question.order,
      if (question.prompt != null) 'prompt': question.prompt,
      'correct': _optionToMap(question.correct),
      'wrong': [for (final option in question.wrong) _optionToMap(option)],
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
    );

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
