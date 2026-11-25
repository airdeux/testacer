/// The time spent on one quiz: started with the first question, stopped
/// when the last one is answered (or the quiz is closed).
class QuizClock {
  QuizClock({DateTime Function()? now}) : _now = now ?? DateTime.now;

  final DateTime Function() _now;
  DateTime? _started;
  DateTime? _stopped;

  /// Starts from zero (also when already running).
  void start() {
    _started = _now();
    _stopped = null;
  }

  /// Freezes the time; does nothing if not running.
  void stop() {
    if (running) _stopped = _now();
  }

  bool get running => _started != null && _stopped == null;

  Duration get elapsed {
    final started = _started;
    if (started == null) return Duration.zero;
    return (_stopped ?? _now()).difference(started);
  }
}

/// `hh:mm:ss`, e.g. `00:04:07`; hours go past 99 if needed.
String formatElapsed(Duration duration) {
  String two(int n) => n.toString().padLeft(2, '0');
  final seconds = duration.inSeconds < 0 ? 0 : duration.inSeconds;
  return '${two(seconds ~/ 3600)}:${two(seconds ~/ 60 % 60)}:${two(seconds % 60)}';
}
