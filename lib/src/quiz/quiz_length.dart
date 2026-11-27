/// How many questions one quiz asks.
enum QuizLength {
  five(5),
  ten(10),
  twentyFive(25),

  /// Every question exactly once, „Bébikönnyű” ones included, in random
  /// order (D-020).
  all(null),

  /// Until the user closes the quiz; only for a question opened from a
  /// reminder, not offered on the start page.
  endless(null);

  const QuizLength(this.count);

  /// Fixed number of questions; `null` for [all] and [endless].
  final int? count;

  /// The lengths offered on the start page.
  static const choices = [five, ten, twentyFive, all];

  /// The stored setting; anything not offered any more (`one`, `endless`)
  /// becomes 10.
  static QuizLength fromName(Object? name) => choices.firstWhere(
        (length) => length.name == name,
        orElse: () => QuizLength.ten,
      );
}
