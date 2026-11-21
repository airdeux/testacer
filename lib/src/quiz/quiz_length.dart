/// How many questions one quiz asks.
enum QuizLength {
  one(1),
  five(5),
  ten(10),

  /// Every question that is not skippable, once each.
  all(null),

  /// Until the user closes the quiz.
  endless(null);

  const QuizLength(this.count);

  final int? count;

  static QuizLength fromName(Object? name) => values.firstWhere(
        (length) => length.name == name,
        orElse: () => QuizLength.ten,
      );
}
