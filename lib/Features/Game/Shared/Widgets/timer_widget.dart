import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:scioly_codebusters/library.dart';

class TimerWidget extends ConsumerStatefulWidget {
  final String timerId;
  final Color color;

  const TimerWidget({
    super.key,
    required this.timerId,
    this.color = AppTheme.logoGreen,
  });

  @override
  ConsumerState<TimerWidget> createState() => _TimerWidgetState();
}

class _TimerWidgetState extends ConsumerState<TimerWidget> {
  late TimerNotifier timer;

  @override
  void initState() {
    super.initState();
    timer = ref.read(timerProvider(widget.timerId).notifier);
    var game = ref.read(gameProvider(widget.timerId).notifier);
    if (game.cellCount() > 0 && !game.isCorrect()) {
      timer.start(); // Or whatever you need to do on screen load
    }
  }

  @override
  void dispose() {
    // Automatically pause the timer when leaving the screen
    timer.pause();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final time = ref.watch(timerProvider(widget.timerId));
    return Container(
      decoration: BoxDecoration(
        color: widget.color.withAlpha(50),
        border: Border.all(color: widget.color, width: 1),
      ),
      width: !kIsWeb && defaultTargetPlatform == TargetPlatform.windows
          ? 128
          : 100,
      padding: EdgeInsets.all(padding),
      child: Center(
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            '${time}s',
            maxLines: 1,
            softWrap: false,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: widget.color,
              fontSize: 30,
              fontFamily: 'JetBrainsMonoBold',
              shadows: [Shadow(color: widget.color, blurRadius: 10)],
            ),
          ),
        ),
      ),
    );
  }
}
