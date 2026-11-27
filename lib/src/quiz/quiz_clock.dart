/// The time spent on one quiz: started with the first question, paused from
/// each answer until the next question shows (D-020), stopped when the last
/// one is answered (or the quiz is closed).
class QuizClock {
  QuizClock({DateTime Function()? now}) : _now = now ?? DateTime.now;

  final DateTime Function() _now;

  /// Time of the finished stretches.
  Duration _done = Duration.zero;

  /// Start of the current stretch, while running.
  DateTime? _since;
  bool _started = false;
  bool _stopped = false;

  /// Starts from zero (also when already running).
  void start() {
    _done = Duration.zero;
    _since = _now();
    _started = true;
    _stopped = false;
  }

  /// Holds the time until [resume]; does nothing if not running.
  void pause() {
    final since = _since;
    if (since == null) return;
    _done += _now().difference(since);
    _since = null;
  }

  /// Goes on after [pause]; does nothing after [stop] or before [start].
  void resume() {
    if (_started && !_stopped && _since == null) _since = _now();
  }

  /// Freezes the time for good (until the next [start]).
  void stop() {
    pause();
    if (_started) _stopped = true;
  }

  bool get running => _since != null;

  Duration get elapsed {
    final since = _since;
    return since == null ? _done : _done + _now().difference(since);
  }
}

/// `hh:mm:ss`, e.g. `00:04:07`; hours go past 99 if needed.
String formatElapsed(Duration duration) {
  String two(int n) => n.toString().padLeft(2, '0');
  final seconds = duration.inSeconds < 0 ? 0 : duration.inSeconds;
  return '${two(seconds ~/ 3600)}:${two(seconds ~/ 60 % 60)}:${two(seconds % 60)}';
}
