import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:scioly_codebusters/library.dart';

const _timerId = 'timer widget test';

class _EmptyGameProvider extends GameProvider {
  @override
  Game build(String gameId) => Game(quote: Quote());
}

class _TestTimerNotifier extends TimerNotifier {
  void setTime(int seconds) => state = seconds;
}

Future<void> _pumpTimer(
  WidgetTester tester,
  ProviderContainer container,
) {
  return tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: const MaterialApp(
        home: Scaffold(body: Center(child: TimerWidget(timerId: _timerId))),
      ),
    ),
  );
}

void main() {
  test('caps displayed timer seconds at the four-digit limit', () {
    expect(cappedTimerSeconds(const Duration(seconds: 999)), 999);
    expect(cappedTimerSeconds(const Duration(seconds: 1000)), 1000);
    expect(cappedTimerSeconds(const Duration(seconds: 9999)), 9999);
    expect(cappedTimerSeconds(const Duration(seconds: 10000)), 9999);
  });

  testWidgets('Windows timer keeps suffixed values centered inside its border', (
    tester,
  ) async {
    debugDefaultTargetPlatformOverride = TargetPlatform.windows;
    final container = ProviderContainer(
      overrides: [
        gameProvider.overrideWith(_EmptyGameProvider.new),
        timerProvider.overrideWith(_TestTimerNotifier.new),
      ],
    );
    addTearDown(container.dispose);

    try {
      tester.view.physicalSize = const Size(800, 600);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await _pumpTimer(tester, container);
      final timer =
          container.read(timerProvider(_timerId).notifier) as _TestTimerNotifier;
      final border = find.descendant(
        of: find.byType(TimerWidget),
        matching: find.byWidgetPredicate(
          (widget) =>
              widget is Container && widget.decoration is BoxDecoration,
        ),
      );

      expect(tester.getRect(border).width, 128);

      for (final seconds in [99, 100, 9999]) {
        timer.setTime(seconds);
        await tester.pump();

        final text = find.text('${seconds}s');
        expect(text, findsOneWidget);

        final borderRect = tester.getRect(border);
        final textRect = tester.getRect(text);
        expect(textRect.left, greaterThanOrEqualTo(borderRect.left));
        expect(textRect.right, lessThanOrEqualTo(borderRect.right));
        expect(textRect.top, greaterThanOrEqualTo(borderRect.top));
        expect(textRect.bottom, lessThanOrEqualTo(borderRect.bottom));
        expect(textRect.center.dx, closeTo(borderRect.center.dx, 0.1));
      }
    } finally {
      debugDefaultTargetPlatformOverride = null;
    }
  });
}
