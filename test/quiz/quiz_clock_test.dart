import 'package:flutter_test/flutter_test.dart';
import 'package:testacer/src/quiz/quiz_clock.dart';
import 'package:testacer/src/quiz/quiz_length.dart';

void main() {
  late DateTime time;
  late QuizClock clock;

  setUp(() {
    time = DateTime(2026, 11, 25, 10);
    clock = QuizClock(now: () => time);
  });

  test('zero and not running before the start', () {
    expect(clock.running, isFalse);
    expect(clock.elapsed, Duration.zero);
  });

  test('counts from the start until stopped, then stays', () {
    clock.start();
    time = time.add(const Duration(seconds: 90));
    expect(clock.running, isTrue);
    expect(clock.elapsed, const Duration(seconds: 90));

    clock.stop();
    time = time.add(const Duration(minutes: 10));
    expect(clock.running, isFalse);
    expect(clock.elapsed, const Duration(seconds: 90));

    clock.stop();
    expect(clock.elapsed, const Duration(seconds: 90));
  });

  test('a new start begins from zero', () {
    clock
      ..start()
      ..stop();
    time = time.add(const Duration(minutes: 3));
    clock.start();
    time = time.add(const Duration(seconds: 5));
    expect(clock.elapsed, const Duration(seconds: 5));
  });

  test('formatElapsed shows hh:mm:ss', () {
    expect(formatElapsed(Duration.zero), '00:00:00');
    expect(formatElapsed(const Duration(seconds: 59, milliseconds: 999)), '00:00:59');
    expect(formatElapsed(const Duration(hours: 1, minutes: 2, seconds: 3)), '01:02:03');
    expect(formatElapsed(const Duration(hours: 100)), '100:00:00');
    expect(formatElapsed(const Duration(seconds: -3)), '00:00:00');
  });

  test('the stored length "all" (replaced by 25) reads as 25', () {
    expect(QuizLength.fromName('all'), QuizLength.twentyFive);
    expect(QuizLength.fromName('twentyFive'), QuizLength.twentyFive);
    expect(QuizLength.fromName('nonsense'), QuizLength.ten);
  });
}
