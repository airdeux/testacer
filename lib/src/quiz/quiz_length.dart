/// How many questions one quiz asks.
enum QuizLength {
  one(1),
  five(5),
  ten(10),
  twentyFive(25),

  /// Until the user closes the quiz.
  endless(null);

  const QuizLength(this.count);

  final int? count;

  /// The stored setting; `all` (every question, replaced by 25 on
  /// 2026-11-25) becomes 25.
  static QuizLength fromName(Object? name) => values.firstWhere(
        (length) => length.name == (name == 'all' ? 'twentyFive' : name),
        orElse: () => QuizLength.ten,
      );
}
