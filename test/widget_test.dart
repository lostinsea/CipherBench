import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:scioly_codebusters/library.dart';

const _gameKey = 'Keyboard test game';
const _keyboardChildKey = ValueKey('keyboard-shortcuts-child');

class _TestGameProvider extends GameProvider {
  @override
  Game build(String gameKey) {
    return Game(
      quote: Quote(),
      cells: [
        Cell(
          text: '',
          cipher: 'A',
          plainText: 'N',
          isException: false,
          count: 1,
        ),
        Cell(
          text: '',
          cipher: 'B',
          plainText: 'X',
          isException: false,
          count: 1,
        ),
      ],
    );
  }
}

Future<void> _pumpKeyboardShortcuts(
  WidgetTester tester, {
  required ProviderContainer container,
  required Language language,
}) async {
  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: MaterialApp(
        home: KeyboardShortcutsWidget(
          gameKey: _gameKey,
          language: language,
          child: const SizedBox.expand(key: _keyboardChildKey),
        ),
      ),
    ),
  );
  Focus.of(tester.element(find.byKey(_keyboardChildKey))).requestFocus();
  await tester.pump();
}

void _selectFirstCell(ProviderContainer container) {
  container.read(gameProvider(_gameKey).notifier).selectCell(0);
}

Future<void> _sendShiftN(WidgetTester tester) async {
  await tester.sendKeyDownEvent(LogicalKeyboardKey.shiftLeft);
  await tester.sendKeyDownEvent(LogicalKeyboardKey.keyN);
  await tester.sendKeyUpEvent(LogicalKeyboardKey.keyN);
  await tester.sendKeyUpEvent(LogicalKeyboardKey.shiftLeft);
}

Future<void> _sendControlZ(WidgetTester tester) async {
  await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
  await tester.sendKeyDownEvent(LogicalKeyboardKey.keyZ);
  await tester.sendKeyUpEvent(LogicalKeyboardKey.keyZ);
  await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
}

void main() {
  group('desktop game controls', () {
    testWidgets(
      'desktop game uses physical keyboard shortcuts instead of the virtual keyboard',
      (tester) async {
        debugDefaultTargetPlatformOverride = TargetPlatform.windows;
        try {
          tester.view.physicalSize = const Size(800, 600);
          tester.view.devicePixelRatio = 1;
          addTearDown(tester.view.resetPhysicalSize);
          addTearDown(tester.view.resetDevicePixelRatio);

          await tester.pumpWidget(
            const ProviderScope(
              child: MaterialApp(
                home: GamePage(
                  gameId: 'Aristocrat',
                  gameMode: GameMode.assisted,
                  language: Language.english,
                ),
              ),
            ),
          );

          expect(find.byType(KeyboardShortcutsWidget), findsOneWidget);
          expect(find.byType(AvailableCommandsWidget), findsOneWidget);
          expect(find.byType(KeyboardWidget), findsNothing);
        } finally {
          debugDefaultTargetPlatformOverride = null;
        }
      },
    );

    testWidgets('English Shift+N types N', (tester) async {
      final container = ProviderContainer(
        overrides: [gameProvider.overrideWith(_TestGameProvider.new)],
      );
      addTearDown(container.dispose);

      await _pumpKeyboardShortcuts(
        tester,
        container: container,
        language: Language.english,
      );
      _selectFirstCell(container);
      await _sendShiftN(tester);
      await tester.pump();

      expect(
        container.read(gameProvider(_gameKey)).cells.first.text,
        equals('N'),
      );
    });

    testWidgets('Spanish Shift+N types Ñ', (tester) async {
      final container = ProviderContainer(
        overrides: [gameProvider.overrideWith(_TestGameProvider.new)],
      );
      addTearDown(container.dispose);

      await _pumpKeyboardShortcuts(
        tester,
        container: container,
        language: Language.spanish,
      );
      _selectFirstCell(container);
      await _sendShiftN(tester);
      await tester.pump();

      expect(
        container.read(gameProvider(_gameKey)).cells.first.text,
        equals('Ñ'),
      );
    });

    testWidgets('Control+Z undoes a physical keyboard letter', (tester) async {
      final container = ProviderContainer(
        overrides: [gameProvider.overrideWith(_TestGameProvider.new)],
      );
      addTearDown(container.dispose);

      await _pumpKeyboardShortcuts(
        tester,
        container: container,
        language: Language.english,
      );
      _selectFirstCell(container);
      await _sendShiftN(tester);
      await tester.pump();

      final enteredIndex = container
          .read(gameProvider(_gameKey))
          .cells
          .indexWhere((cell) => cell.text == 'N');
      expect(enteredIndex, isNonNegative);

      await _sendControlZ(tester);
      await tester.pump();

      expect(
        container.read(gameProvider(_gameKey)).cells[enteredIndex].text,
        isEmpty,
      );
    });

    testWidgets('command widget does not duplicate commands on rebuild', (
      tester,
    ) async {
      GameSetup.width = 1200;
      GameSetup.height = 800;
      final commands = KeyboardShortcutsWidget.commands(Language.spanish);
      late StateSetter rebuild;

      await tester.pumpWidget(
        MaterialApp(
          home: StatefulBuilder(
            builder: (context, setState) {
              rebuild = setState;
              return AvailableCommandsWidget(commands: commands);
            },
          ),
        ),
      );
      rebuild(() {});
      await tester.pump();
      rebuild(() {});
      await tester.pump();

      expect(find.byType(CommandWidget), findsNWidgets(commands.length));
      for (final entry in commands.entries) {
        expect(find.text(entry.key), findsOneWidget);
        expect(find.text(entry.value), findsOneWidget);
      }
    });
  });
}
