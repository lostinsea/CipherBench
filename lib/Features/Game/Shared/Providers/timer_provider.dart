import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';

const int maxDisplayedTimerSeconds = 9999;

int cappedTimerSeconds(Duration elapsed) {
  final seconds = elapsed.inSeconds;
  return seconds > maxDisplayedTimerSeconds
      ? maxDisplayedTimerSeconds
      : seconds;
}

class TimerNotifier extends FamilyNotifier<int, String> {
  final Stopwatch _stopwatch = Stopwatch();
  Timer? _tick;

  @override
  int build(String timerId) {
    return 0; // Initial time in seconds
  }

  void start() {
    _stopwatch.start();
    _startTicker();
  }

  void pause() {
    if (_stopwatch.isRunning) {
      _stopwatch.stop();
    }
    _stopTicker();
  }

  void resume() {
    if (!_stopwatch.isRunning) {
      _stopwatch.start();
      _startTicker();
    }
  }

  void reset() {
    _stopwatch.reset();
    _stopTicker();
    state = 0;
  }

  void restart() {
    reset();
    start();
  }

  void _startTicker() {
    _tick?.cancel();
    _tick = Timer.periodic(const Duration(seconds: 1), (_) {
      state = cappedTimerSeconds(_stopwatch.elapsed);
    });
  }

  void _stopTicker() {
    _tick?.cancel();
    _tick = null;
  }

  void onDispose() {
    _tick?.cancel();
  }

  double getTime() =>
      (_stopwatch.elapsed.inMilliseconds / 10).roundToDouble() / 100;
}

final timerProvider = NotifierProvider.family<TimerNotifier, int, String>(
  TimerNotifier.new,
);
