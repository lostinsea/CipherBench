import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:scioly_codebusters/library.dart';

const _gameKey = 'Keyboard test game';
const _keyboardChildKey = ValueKey('keyboard-shortcuts-child');
const _puzzleViewportKey = ValueKey('puzzle-viewport');
const _rapidScrollViewportKey = ValueKey('rapid-scroll-viewport');
const _puzzleHeaderKey = ValueKey('puzzle-header');
const _puzzleCommandsKey = ValueKey('puzzle-commands');
const _scrollGameKey = 'Scroll test game';
const _rapidScrollGameKey = 'Rapid scroll test game';
const _animatedScrollGameKey = 'Animated scroll test game';
const _scrollSelectedIndex = 160;
const _responsiveGridGameKey = 'Aristocrat (Assisted)';
const _windowsGameBodyInset = 38.0;
const _englishWindowsHelp =
    'Undo: Ctrl+Z | Reset: Ctrl+Backspace | Erase: Backspace | Move: ← ↑ → ↓';
const _spanishWindowsHelp =
    'Undo: Ctrl+Z | Reset: Ctrl+Backspace | Erase: Backspace | Move: ← ↑ → ↓ | Ñ: Shift+N';

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

class _VerticalShortcutGameProvider extends GameProvider {
  @override
  Game build(String gameKey) {
    return Game(
      quote: Quote(),
      selectedIdx: 1,
      cells: [
        for (var index = 0; index < 4; index++)
          Cell(
            text: '',
            cipher: '$index',
            plainText: '$index',
            isException: false,
            isSelected: index == 1,
            count: 1,
          ),
      ],
    );
  }
}

class _ResizeGameProvider extends GameProvider {
  @override
  Game build(String gameKey) {
    final previous = Game(
      quote: Quote(),
      selectedIdx: 0,
      gameMode: GameMode.assisted,
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
    return Game(
      quote: Quote(),
      selectedIdx: 1,
      gameMode: GameMode.manual,
      history: [previous],
      cells: [
        Cell(
          text: 'N',
          cipher: 'A',
          plainText: 'N',
          isException: false,
          isSelected: false,
          count: 1,
        ),
        Cell(
          text: 'X',
          cipher: 'B',
          plainText: 'X',
          isException: false,
          isSelected: true,
          count: 1,
        ),
      ],
    );
  }
}

class _ScrollGameProvider extends GameProvider {
  @override
  Game build(String gameKey) {
    return Game(
      quote: Quote(),
      selectedIdx: _scrollSelectedIndex,
      gameMode: GameMode.manual,
      cells: [
        for (var index = 0; index < 180; index++)
          Cell(
            text: index == _scrollSelectedIndex ? 'TARGET' : '',
            cipher: 'C$index',
            plainText: 'N',
            isException: false,
            isSelected: index == _scrollSelectedIndex,
            count: 1,
          ),
      ],
    );
  }
}

class _RapidScrollGameProvider extends GameProvider {
  @override
  Game build(String gameKey) {
    return Game(
      quote: Quote(),
      gameMode: GameMode.manual,
      cells: [
        for (var index = 0; index < 24; index++)
          Cell(
            text: 'selected-$index',
            cipher: 'C$index',
            plainText: 'N',
            isException: false,
            isSelected: index == 0,
            count: 1,
          ),
      ],
    );
  }
}

class _AnimatedScrollGameProvider extends GameProvider {
  @override
  Game build(String gameKey) {
    return Game(
      quote: Quote(),
      selectedIdx: 10,
      gameMode: GameMode.manual,
      cells: [
        for (var index = 0; index < 80; index++)
          Cell(
            text: 'selected-$index',
            cipher: 'C$index',
            plainText: 'N',
            isException: false,
            isSelected: index == 10,
            count: 1,
          ),
      ],
    );
  }
}

class _ResponsiveGridGameProvider extends GameProvider {
  @override
  Game build(String gameKey) {
    return Game(
      quote: Quote(),
      selectedIdx: 0,
      gameMode: GameMode.manual,
      cells: [
        for (var index = 0; index < 40; index++)
          Cell(
            text: index == 0 ? 'A' : '',
            cipher: 'C$index',
            plainText: 'A',
            isException: false,
            isSelected: index == 0,
            count: 1,
          ),
      ],
    );
  }
}

List<List<Rect>> _renderedGridCellBoundsByRow(WidgetTester tester) {
  final cells = find.descendant(
    of: find.byType(CryptogramGridWidget),
    matching: find.byType(AnimatedContainer),
  );
  final cellsByTop = <double, List<Rect>>{};
  for (var index = 0; index < cells.evaluate().length; index++) {
    final bounds = tester.getRect(cells.at(index));
    (cellsByTop[bounds.top] ??= []).add(bounds);
  }
  final rows = cellsByTop.entries.toList()
    ..sort((first, second) => first.key.compareTo(second.key));
  return [for (final row in rows) row.value];
}

void _expectRenderedGridRowsCentered(
  WidgetTester tester, {
  required int rowCount,
}) {
  final rows = _renderedGridCellBoundsByRow(tester);
  final gridCenter = tester.getRect(find.byType(LayoutBuilder)).center.dx;

  expect(rows, hasLength(rowCount));
  for (final row in rows) {
    var left = row.first.left;
    var right = row.first.right;
    for (final bounds in row.skip(1)) {
      left = bounds.left < left ? bounds.left : left;
      right = bounds.right > right ? bounds.right : right;
    }
    expect((left + right) / 2, closeTo(gridCenter, 0.001));
  }
}

Future<void> _pumpResponsiveGame(
  WidgetTester tester,
  ProviderContainer container,
) {
  return tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: const MaterialApp(
        home: GamePageLayout(
          config: GamePageConfig(
            gameId: 'Aristocrat',
            gameMode: GameMode.assisted,
            language: Language.english,
          ),
          addKeyboard: false,
        ),
      ),
    ),
  );
}

void _ignoreHeaderListTileMaterialWarning() {
  final previousErrorHandler = FlutterError.onError;
  FlutterError.onError = (details) {
    if (details.exceptionAsString().contains(
      'ListTile background color or ink splashes may be invisible',
    )) {
      return;
    }
    previousErrorHandler?.call(details);
  };
  addTearDown(() => FlutterError.onError = previousErrorHandler);
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

Future<void> _sendControlBackspace(WidgetTester tester) async {
  await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
  await tester.sendKeyDownEvent(LogicalKeyboardKey.backspace);
  await tester.sendKeyUpEvent(LogicalKeyboardKey.backspace);
  await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
}

Future<void> _pumpDesktopGameControls(
  WidgetTester tester, {
  required ProviderContainer container,
  required Language language,
}) {
  return tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: MaterialApp(
        home: GamePageLayout(
          config: GamePageConfig(
            gameId: 'Aristocrat',
            gameMode: GameMode.manual,
            language: language,
          ),
          addKeyboard: false,
        ),
      ),
    ),
  );
}

void _expectResizeGameAnswers(
  ProviderContainer container, {
  required List<String> answers,
}) {
  expect(
    container
        .read(gameProvider('Aristocrat (Manual)'))
        .cells
        .map((cell) => cell.text),
    answers,
  );
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
          expect(find.byType(AvailableCommandsWidget), findsNothing);
          expect(find.text(_englishWindowsHelp), findsOneWidget);
          expect(find.widgetWithText(OutlinedButton, 'Undo'), findsOneWidget);
          expect(find.widgetWithText(OutlinedButton, 'Reset'), findsOneWidget);
          expect(find.byType(KeyboardWidget), findsNothing);
        } finally {
          debugDefaultTargetPlatformOverride = null;
        }
      },
    );

    testWidgets('Windows zoom controls use taller rows at displayed 100%', (
      tester,
    ) async {
      debugDefaultTargetPlatformOverride = TargetPlatform.windows;
      try {
        await tester.pumpWidget(
          const ProviderScope(
            child: MaterialApp(
              home: GamePageLayout(
                config: GamePageConfig(
                  gameId: 'Aristocrat',
                  gameMode: GameMode.assisted,
                  language: Language.english,
                ),
              ),
            ),
          ),
        );

        final zoomIn = find.byTooltip('Zoom in');
        final zoomOut = find.byTooltip('Zoom out');
        final zoomInButton = find.ancestor(
          of: find.byIcon(Icons.zoom_in),
          matching: find.byType(IconButton),
        );
        final zoomOutButton = find.ancestor(
          of: find.byIcon(Icons.zoom_out),
          matching: find.byType(IconButton),
        );
        CryptogramGridWidget grid() => tester.widget<CryptogramGridWidget>(
          find.byType(CryptogramGridWidget),
        );
        PuzzleGeometry geometry() =>
            PuzzleGeometry(grid().zoomPercent, extraRowGap: grid().extraRowGap);

        expect(find.text('100%'), findsOneWidget);
        expect(grid().zoomPercent, 140);
        expect(grid().extraRowGap, closeTo(22.75, 0.0001));
        expect(grid().centerRows, isTrue);
        expect(geometry().cellWidth, 28);
        expect(geometry().cellHeight, 35);
        expect(geometry().rowHeight, closeTo(113.75, 0.0001));
        expect(tester.widget<IconButton>(zoomOutButton).onPressed, isNotNull);

        await tester.tap(zoomOut);
        await tester.pump();
        expect(find.text('95%'), findsOneWidget);
        expect(grid().zoomPercent, 133);

        for (var zoom = 95; zoom > 75; zoom -= 5) {
          await tester.tap(zoomOut);
          await tester.pump();
        }
        expect(find.text('75%'), findsOneWidget);
        expect(grid().zoomPercent, 105);
        expect(geometry().rowHeight, closeTo(91, 0.0001));
        expect(tester.widget<IconButton>(zoomOutButton).onPressed, isNull);

        await tester.tap(zoomIn);
        await tester.pump();
        expect(find.text('80%'), findsOneWidget);
        expect(grid().zoomPercent, 112);

        for (var zoom = 80; zoom < 200; zoom += 5) {
          await tester.tap(zoomIn);
          await tester.pump();
        }
        expect(find.text('200%'), findsOneWidget);
        expect(grid().zoomPercent, 280);
        expect(geometry().rowHeight, closeTo(204.75, 0.0001));
        expect(tester.widget<IconButton>(zoomInButton).onPressed, isNull);
      } finally {
        debugDefaultTargetPlatformOverride = null;
      }
    });

    testWidgets('Android keeps the default puzzle row height', (tester) async {
      debugDefaultTargetPlatformOverride = TargetPlatform.android;
      try {
        await tester.pumpWidget(
          const ProviderScope(
            child: MaterialApp(
              home: GamePageLayout(
                config: GamePageConfig(
                  gameId: 'Aristocrat',
                  gameMode: GameMode.assisted,
                  language: Language.english,
                ),
              ),
            ),
          ),
        );

        expect(find.byTooltip('Zoom out'), findsNothing);
        expect(find.byTooltip('Zoom in'), findsNothing);
        final grid = tester.widget<CryptogramGridWidget>(
          find.byType(CryptogramGridWidget),
        );
        expect(grid.zoomPercent, 100);
        expect(grid.extraRowGap, 0);
        expect(grid.centerRows, isFalse);
        expect(
          PuzzleGeometry(
            grid.zoomPercent,
            extraRowGap: grid.extraRowGap,
          ).rowHeight,
          65,
        );
      } finally {
        debugDefaultTargetPlatformOverride = null;
      }
    });

    testWidgets(
      'Windows pins compact help and mouse controls in one bottom row',
      (tester) async {
        _ignoreHeaderListTileMaterialWarning();
        final container = ProviderContainer(
          overrides: [gameProvider.overrideWith(_ResizeGameProvider.new)],
        );
        addTearDown(container.dispose);
        debugDefaultTargetPlatformOverride = TargetPlatform.windows;
        try {
          tester.view.devicePixelRatio = 1;
          addTearDown(tester.view.resetPhysicalSize);
          addTearDown(tester.view.resetDevicePixelRatio);

          for (final size in const [Size(800, 600), Size(1100, 720)]) {
            for (final language in const [Language.english, Language.spanish]) {
              tester.view.physicalSize = size;
              await _pumpDesktopGameControls(
                tester,
                container: container,
                language: language,
              );
              await tester.pump();

              final help = language == Language.english
                  ? _englishWindowsHelp
                  : _spanishWindowsHelp;
              expect(find.text(help), findsOneWidget);

              final undo = find.widgetWithText(OutlinedButton, 'Undo');
              final reset = find.widgetWithText(OutlinedButton, 'Reset');
              expect(undo, findsOneWidget);
              expect(reset, findsOneWidget);

              final helpBounds = tester.getRect(find.text(help));
              final undoBounds = tester.getRect(undo);
              final resetBounds = tester.getRect(reset);
              final headerBounds = tester.getRect(
                find.byType(GamePageHeaderWidget),
              );
              final puzzleViewportBounds = tester.getRect(
                find.byType(SingleChildScrollView),
              );

              expect(
                headerBounds.left,
                greaterThanOrEqualTo(_windowsGameBodyInset),
              );
              expect(
                headerBounds.right,
                lessThanOrEqualTo(size.width - _windowsGameBodyInset),
              );
              expect(
                headerBounds.top,
                greaterThanOrEqualTo(_windowsGameBodyInset),
              );
              expect(
                puzzleViewportBounds.left,
                greaterThanOrEqualTo(_windowsGameBodyInset),
              );
              expect(
                puzzleViewportBounds.right,
                lessThanOrEqualTo(size.width - _windowsGameBodyInset),
              );
              expect(
                puzzleViewportBounds.bottom,
                lessThanOrEqualTo(size.height - _windowsGameBodyInset),
              );
              expect(
                undoBounds.center.dy,
                closeTo(resetBounds.center.dy, 0.001),
              );
              expect(
                helpBounds.center.dy,
                closeTo(undoBounds.center.dy, 0.001),
              );
              expect(
                resetBounds.right,
                lessThanOrEqualTo(size.width - _windowsGameBodyInset),
              );
              expect(
                helpBounds.left,
                greaterThanOrEqualTo(_windowsGameBodyInset),
              );
              expect(
                resetBounds.bottom,
                lessThanOrEqualTo(size.height - _windowsGameBodyInset),
              );
              if (size.width == 800) {
                expect(helpBounds.right, lessThanOrEqualTo(undoBounds.left));
              }
              expect(tester.takeException(), isNull);
            }
          }
        } finally {
          debugDefaultTargetPlatformOverride = null;
        }
      },
    );

    testWidgets(
      'Android retains its existing command strip without mouse controls',
      (tester) async {
        _ignoreHeaderListTileMaterialWarning();
        final container = ProviderContainer(
          overrides: [gameProvider.overrideWith(_ResizeGameProvider.new)],
        );
        addTearDown(container.dispose);
        debugDefaultTargetPlatformOverride = TargetPlatform.android;
        try {
          await _pumpDesktopGameControls(
            tester,
            container: container,
            language: Language.spanish,
          );

          expect(find.byType(AvailableCommandsWidget), findsOneWidget);
          expect(find.text(_englishWindowsHelp), findsNothing);
          expect(find.text(_spanishWindowsHelp), findsNothing);
          expect(find.widgetWithText(OutlinedButton, 'Undo'), findsNothing);
          expect(find.widgetWithText(OutlinedButton, 'Reset'), findsNothing);
        } finally {
          debugDefaultTargetPlatformOverride = null;
        }
      },
    );

    testWidgets('Windows Undo button uses the shared undo action', (
      tester,
    ) async {
      _ignoreHeaderListTileMaterialWarning();
      final container = ProviderContainer(
        overrides: [gameProvider.overrideWith(_ResizeGameProvider.new)],
      );
      addTearDown(container.dispose);
      debugDefaultTargetPlatformOverride = TargetPlatform.windows;
      try {
        await _pumpDesktopGameControls(
          tester,
          container: container,
          language: Language.english,
        );
        _expectResizeGameAnswers(container, answers: ['N', 'X']);

        await tester.tap(find.widgetWithText(OutlinedButton, 'Undo'));
        await tester.pump();

        _expectResizeGameAnswers(container, answers: ['', '']);
      } finally {
        debugDefaultTargetPlatformOverride = null;
      }
    });

    testWidgets('Windows keyboard reset confirms before changing answers', (
      tester,
    ) async {
      _ignoreHeaderListTileMaterialWarning();
      final container = ProviderContainer(
        overrides: [gameProvider.overrideWith(_ResizeGameProvider.new)],
      );
      addTearDown(container.dispose);
      debugDefaultTargetPlatformOverride = TargetPlatform.windows;
      try {
        await _pumpDesktopGameControls(
          tester,
          container: container,
          language: Language.english,
        );

        await _sendControlBackspace(tester);
        await tester.pump();
        expect(find.text('Reset puzzle?'), findsOneWidget);
        final dialog = tester.widget<AlertDialog>(find.byType(AlertDialog));
        final shape = dialog.shape! as RoundedRectangleBorder;
        expect(dialog.backgroundColor, Colors.black);
        expect(shape.side.color, AppTheme.logoGreen);
        expect(shape.borderRadius, BorderRadius.zero);
        expect(
          tester.widget<Text>(find.text('Reset puzzle?')).style!.color,
          AppTheme.logoGreen,
        );
        expect(
          tester
              .widget<Text>(
                find.text('This clears your answers. You can undo the reset.'),
              )
              .style!
              .color,
          Colors.white70,
        );
        for (final label in ['Cancel', 'Reset']) {
          final button = tester.widget<OutlinedButton>(
            find.descendant(
              of: find.byType(AlertDialog),
              matching: find.widgetWithText(OutlinedButton, label),
            ),
          );
          expect(button.style!.foregroundColor!.resolve({}), Colors.white);
          expect(
            button.style!.side!.resolve({})!.color,
            AppTheme.logoGreen,
          );
        }
        await tester.tap(find.text('Cancel'));
        await tester.pumpAndSettle();
        _expectResizeGameAnswers(container, answers: ['N', 'X']);

        await _sendControlBackspace(tester);
        await tester.pump();
        expect(find.text('Reset puzzle?'), findsOneWidget);
        await tester.tap(
          find.descendant(
            of: find.byType(AlertDialog),
            matching: find.text('Reset'),
          ),
        );
        await tester.pumpAndSettle();
        _expectResizeGameAnswers(container, answers: ['', '']);

        await _sendControlZ(tester);
        await tester.pump();
        _expectResizeGameAnswers(container, answers: ['N', 'X']);
      } finally {
        debugDefaultTargetPlatformOverride = null;
      }
    });

    testWidgets('Windows mouse reset confirms and returns focus to shortcuts', (
      tester,
    ) async {
      _ignoreHeaderListTileMaterialWarning();
      final container = ProviderContainer(
        overrides: [gameProvider.overrideWith(_ResizeGameProvider.new)],
      );
      addTearDown(container.dispose);
      debugDefaultTargetPlatformOverride = TargetPlatform.windows;
      try {
        await _pumpDesktopGameControls(
          tester,
          container: container,
          language: Language.english,
        );

        final reset = find.widgetWithText(OutlinedButton, 'Reset');
        await tester.tap(reset);
        await tester.pump();
        expect(find.text('Reset puzzle?'), findsOneWidget);
        await tester.tap(find.text('Cancel'));
        await tester.pumpAndSettle();
        _expectResizeGameAnswers(container, answers: ['N', 'X']);

        await tester.tap(reset);
        await tester.pump();
        expect(find.text('Reset puzzle?'), findsOneWidget);
        await tester.tap(
          find.descendant(
            of: find.byType(AlertDialog),
            matching: find.text('Reset'),
          ),
        );
        await tester.pumpAndSettle();
        _expectResizeGameAnswers(container, answers: ['', '']);

        await _sendControlZ(tester);
        await tester.pump();
        _expectResizeGameAnswers(container, answers: ['N', 'X']);
      } finally {
        debugDefaultTargetPlatformOverride = null;
      }
    });

    testWidgets(
      'Windows puzzle grid fills the inset viewport and reflows after resize',
      (tester) async {
        _ignoreHeaderListTileMaterialWarning();
        final originalGameSize = (GameSetup.width, GameSetup.height);
        addTearDown(() {
          GameSetup.width = originalGameSize.$1;
          GameSetup.height = originalGameSize.$2;
        });
        final container = ProviderContainer(
          overrides: [
            gameProvider.overrideWith(_ResponsiveGridGameProvider.new),
          ],
        );
        addTearDown(container.dispose);
        debugDefaultTargetPlatformOverride = TargetPlatform.windows;
        try {
          tester.view.physicalSize = const Size(800, 600);
          tester.view.devicePixelRatio = 1;
          GameSetup.width = 800;
          GameSetup.height = 600;
          addTearDown(tester.view.resetPhysicalSize);
          addTearDown(tester.view.resetDevicePixelRatio);
          await _pumpResponsiveGame(tester, container);

          final grid = find.byType(LayoutBuilder);
          expect(grid, findsOneWidget);
          expect(
            tester.getSize(grid).width,
            closeTo(800 - 2 * _windowsGameBodyInset - 2 * insetPadding, 0.001),
          );
          _expectRenderedGridRowsCentered(tester, rowCount: 2);
          final narrowRows = _renderedGridCellBoundsByRow(tester);
          expect(
            narrowRows.last.length,
            lessThanOrEqualTo(narrowRows.first.length),
          );

          final gameBeforeResize = container.read(
            gameProvider(_responsiveGridGameKey),
          );
          tester.view.physicalSize = const Size(2000, 600);
          GameSetup.width = 2000;
          await tester.pump();

          expect(
            tester.getSize(grid).width,
            closeTo(2000 - 2 * _windowsGameBodyInset - 2 * insetPadding, 0.001),
          );
          _expectRenderedGridRowsCentered(tester, rowCount: 1);
          expect(
            container.read(gameProvider(_responsiveGridGameKey)),
            same(gameBeforeResize),
          );
        } finally {
          debugDefaultTargetPlatformOverride = null;
        }
      },
    );

    testWidgets('Android puzzle grid keeps the desktop width cap', (
      tester,
    ) async {
      _ignoreHeaderListTileMaterialWarning();
      final originalGameSize = (GameSetup.width, GameSetup.height);
      addTearDown(() {
        GameSetup.width = originalGameSize.$1;
        GameSetup.height = originalGameSize.$2;
      });
      final container = ProviderContainer(
        overrides: [gameProvider.overrideWith(_ResponsiveGridGameProvider.new)],
      );
      addTearDown(container.dispose);
      debugDefaultTargetPlatformOverride = TargetPlatform.android;
      try {
        tester.view.physicalSize = const Size(2000, 600);
        tester.view.devicePixelRatio = 1;
        GameSetup.width = 2000;
        GameSetup.height = 600;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        await _pumpResponsiveGame(tester, container);

        expect(
          tester.getSize(find.byType(LayoutBuilder)).width,
          desktopContentWidth,
        );
        final mobileRows = _renderedGridCellBoundsByRow(tester);
        expect(
          mobileRows.first.first.left,
          closeTo(tester.getRect(find.byType(LayoutBuilder)).left, 0.001),
        );
      } finally {
        debugDefaultTargetPlatformOverride = null;
      }
    });

    testWidgets('Windows resize and zoom preserve answer selection and undo', (
      tester,
    ) async {
      const gameKey = 'Aristocrat (Manual)';
      final container = ProviderContainer(
        overrides: [gameProvider.overrideWith(_ResizeGameProvider.new)],
      );
      addTearDown(container.dispose);
      debugDefaultTargetPlatformOverride = TargetPlatform.windows;
      try {
        tester.view.physicalSize = const Size(800, 600);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        await tester.pumpWidget(
          UncontrolledProviderScope(
            container: container,
            child: const MaterialApp(
              home: Scaffold(
                body: SizedBox(
                  width: 800,
                  child: CryptogramGridWidget(
                    gameKey: gameKey,
                    gameId: 'Aristocrat',
                    zoomPercent: 100,
                    bottomInset: 0,
                  ),
                ),
              ),
            ),
          ),
        );

        final before = container.read(gameProvider(gameKey));
        expect(
          tester
              .widget<CryptogramGridWidget>(find.byType(CryptogramGridWidget))
              .centerRows,
          isFalse,
        );
        expect(before.selectedIdx, 1);
        expect(before.cells.map((cell) => cell.text), ['N', 'X']);
        expect(before.history, hasLength(1));

        await tester.pumpWidget(
          UncontrolledProviderScope(
            container: container,
            child: const MaterialApp(
              home: Scaffold(
                body: SizedBox(
                  width: 1000,
                  child: CryptogramGridWidget(
                    gameKey: gameKey,
                    gameId: 'Aristocrat',
                    zoomPercent: 105,
                    bottomInset: 0,
                  ),
                ),
              ),
            ),
          ),
        );
        await tester.pump();

        final after = container.read(gameProvider(gameKey));
        expect(after.selectedIdx, before.selectedIdx);
        expect(after.cells.map((cell) => cell.text), ['N', 'X']);
        expect(after.history, hasLength(1));

        container.read(gameProvider(gameKey).notifier).undo();
        expect(container.read(gameProvider(gameKey)).selectedIdx, 0);
        expect(
          container.read(gameProvider(gameKey)).cells.map((cell) => cell.text),
          ['', ''],
        );
      } finally {
        debugDefaultTargetPlatformOverride = null;
      }
    });

    test('scroll layout updates when only the row height changes', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final notifier = container.read(scrollProvider('row-height').notifier);
      const rows = PuzzleRows(
        [
          [0, 1],
        ],
        [0, 0],
      );
      const standard = PuzzleGeometry(140);
      const windows = PuzzleGeometry(140, extraRowGap: 22.75);

      expect(notifier.updateLayout(rows, standard, 200, 600, 0), isTrue);
      expect(notifier.updateLayout(rows, standard, 200, 600, 0), isFalse);
      expect(notifier.updateLayout(rows, windows, 200, 600, 0), isTrue);
    });

    testWidgets(
      'scrolling a selected cell follows Windows rows with extra gap',
      (tester) async {
        final container = ProviderContainer(
          overrides: [gameProvider.overrideWith(_ScrollGameProvider.new)],
        );
        addTearDown(container.dispose);
        tester.view.physicalSize = const Size(800, 600);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        await tester.pumpWidget(
          UncontrolledProviderScope(
            container: container,
            child: MaterialApp(
              home: Scaffold(
                body: Stack(
                  children: [
                    Positioned.fill(
                      top: panelHeight + padding,
                      bottom: desktopCommandsHeight,
                      child: KeyedSubtree(
                        key: _puzzleViewportKey,
                        child: Consumer(
                          builder: (context, ref, child) {
                            return SingleChildScrollView(
                              controller: ref.watch(
                                scrollProvider(_scrollGameKey),
                              ),
                              padding: const EdgeInsets.all(insetPadding),
                              child: child,
                            );
                          },
                          child: const CryptogramGridWidget(
                            gameKey: _scrollGameKey,
                            gameId: 'Aristocrat',
                            zoomPercent: 200,
                            extraRowGap: 22.75,
                            bottomInset: 0,
                          ),
                        ),
                      ),
                    ),
                    const Positioned(
                      top: 0,
                      left: 0,
                      right: 0,
                      child: SizedBox(
                        key: _puzzleHeaderKey,
                        height: panelHeight + padding,
                      ),
                    ),
                    const Positioned(
                      left: 0,
                      right: 0,
                      bottom: 0,
                      child: SizedBox(
                        key: _puzzleCommandsKey,
                        height: desktopCommandsHeight,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        final selectedCell = find.ancestor(
          of: find.text('TARGET'),
          matching: find.byType(AnimatedContainer),
        );
        final selectedBounds = tester.getRect(selectedCell);
        final headerBounds = tester.getRect(find.byKey(_puzzleHeaderKey));
        final commandsBounds = tester.getRect(find.byKey(_puzzleCommandsKey));

        expect(
          container.read(scrollProvider(_scrollGameKey)).offset,
          greaterThan(0),
        );
        expect(selectedBounds.top, greaterThanOrEqualTo(headerBounds.bottom));
        expect(selectedBounds.bottom, lessThanOrEqualTo(commandsBounds.top));
      },
    );

    testWidgets(
      'rapid Windows ArrowDown repeats keep the current selected row in view',
      (tester) async {
        debugDefaultTargetPlatformOverride = TargetPlatform.windows;
        final container = ProviderContainer(
          overrides: [gameProvider.overrideWith(_RapidScrollGameProvider.new)],
        );
        addTearDown(container.dispose);
        try {
          await tester.pumpWidget(
            UncontrolledProviderScope(
              container: container,
              child: MaterialApp(
                home: Scaffold(
                  body: Align(
                    alignment: Alignment.topLeft,
                    child: SizedBox(
                      width: 96,
                      height: 200,
                      child: KeyboardShortcutsWidget(
                        gameKey: _rapidScrollGameKey,
                        language: Language.english,
                        child: Consumer(
                          builder: (context, ref, child) {
                            return SingleChildScrollView(
                              key: _rapidScrollViewportKey,
                              controller: ref.watch(
                                scrollProvider(_rapidScrollGameKey),
                              ),
                              padding: const EdgeInsets.all(insetPadding),
                              child: child,
                            );
                          },
                          child: const CryptogramGridWidget(
                            gameKey: _rapidScrollGameKey,
                            gameId: 'Patristocrat',
                            zoomPercent: 200,
                            bottomInset: 0,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          );
          Focus.of(
            tester.element(find.byKey(_rapidScrollViewportKey)),
          ).requestFocus();
          await tester.pump();

          final viewport = find.byKey(_rapidScrollViewportKey);
          for (var index = 1; index <= 12; index++) {
            await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
            await tester.pump();

            expect(
              container.read(gameProvider(_rapidScrollGameKey)).selectedIdx,
              index,
            );
            final selectedBounds = tester.getRect(
              find.ancestor(
                of: find.text('selected-$index'),
                matching: find.byType(AnimatedContainer),
              ),
            );
            final viewportBounds = tester.getRect(viewport);
            expect(
              selectedBounds.top,
              greaterThanOrEqualTo(viewportBounds.top),
            );
            expect(
              selectedBounds.bottom,
              lessThanOrEqualTo(viewportBounds.bottom),
            );
          }
        } finally {
          debugDefaultTargetPlatformOverride = null;
        }
      },
    );

    testWidgets(
      'Android ArrowRight keeps scrolling animated when it crosses the viewport',
      (tester) async {
        debugDefaultTargetPlatformOverride = TargetPlatform.android;
        final container = ProviderContainer(
          overrides: [gameProvider.overrideWith(_RapidScrollGameProvider.new)],
        );
        addTearDown(container.dispose);
        try {
          await tester.pumpWidget(
            UncontrolledProviderScope(
              container: container,
              child: MaterialApp(
                home: Scaffold(
                  body: Align(
                    alignment: Alignment.topLeft,
                    child: SizedBox(
                      width: 96,
                      height: 200,
                      child: KeyboardShortcutsWidget(
                        gameKey: _rapidScrollGameKey,
                        language: Language.english,
                        child: Consumer(
                          builder: (context, ref, child) {
                            return SingleChildScrollView(
                              key: _rapidScrollViewportKey,
                              controller: ref.watch(
                                scrollProvider(_rapidScrollGameKey),
                              ),
                              padding: const EdgeInsets.all(insetPadding),
                              child: child,
                            );
                          },
                          child: const CryptogramGridWidget(
                            gameKey: _rapidScrollGameKey,
                            gameId: 'Patristocrat',
                            zoomPercent: 200,
                            bottomInset: 0,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          );
          Focus.of(
            tester.element(find.byKey(_rapidScrollViewportKey)),
          ).requestFocus();
          await tester.pump();

          final scroll = container.read(scrollProvider(_rapidScrollGameKey));
          final initialOffset = scroll.offset;
          await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
          await tester.pump();

          expect(
            container.read(gameProvider(_rapidScrollGameKey)).selectedIdx,
            1,
          );
          expect(scroll.offset, initialOffset);

          await tester.pump(const Duration(milliseconds: 300));
          expect(scroll.offset, greaterThan(initialOffset));
        } finally {
          debugDefaultTargetPlatformOverride = null;
        }
      },
    );

    testWidgets(
      'Windows ArrowRight cancels an in-flight scroll for a visible cell',
      (tester) async {
        debugDefaultTargetPlatformOverride = TargetPlatform.windows;
        final container = ProviderContainer(
          overrides: [
            gameProvider.overrideWith(_AnimatedScrollGameProvider.new),
          ],
        );
        addTearDown(container.dispose);
        try {
          await tester.pumpWidget(
            UncontrolledProviderScope(
              container: container,
              child: MaterialApp(
                home: Scaffold(
                  body: Align(
                    alignment: Alignment.topLeft,
                    child: SizedBox(
                      width: 288,
                      height: 200,
                      child: KeyboardShortcutsWidget(
                        gameKey: _animatedScrollGameKey,
                        language: Language.english,
                        child: Consumer(
                          builder: (context, ref, child) {
                            return SingleChildScrollView(
                              key: _rapidScrollViewportKey,
                              controller: ref.watch(
                                scrollProvider(_animatedScrollGameKey),
                              ),
                              padding: const EdgeInsets.all(insetPadding),
                              child: child,
                            );
                          },
                          child: const CryptogramGridWidget(
                            gameKey: _animatedScrollGameKey,
                            gameId: 'Patristocrat',
                            zoomPercent: 100,
                            bottomInset: 0,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          );
          Focus.of(
            tester.element(find.byKey(_rapidScrollViewportKey)),
          ).requestFocus();
          await tester.pumpAndSettle();

          final scroll = container.read(scrollProvider(_animatedScrollGameKey));
          unawaited(
            scroll.animateTo(
              scroll.position.maxScrollExtent,
              duration: const Duration(milliseconds: 300),
              curve: Curves.linear,
            ),
          );
          await tester.pump();
          await tester.pump(const Duration(milliseconds: 25));
          final inFlightOffset = scroll.offset;
          expect(inFlightOffset, greaterThan(0));

          await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
          await tester.pump();
          expect(
            container.read(gameProvider(_animatedScrollGameKey)).selectedIdx,
            11,
          );

          await tester.pump(const Duration(milliseconds: 350));
          expect(scroll.offset, closeTo(inFlightOffset, 0.001));

          final selectedBounds = tester.getRect(
            find.ancestor(
              of: find.text('selected-11'),
              matching: find.byType(AnimatedContainer),
            ),
          );
          final viewportBounds = tester.getRect(
            find.byKey(_rapidScrollViewportKey),
          );
          expect(selectedBounds.top, greaterThanOrEqualTo(viewportBounds.top));
          expect(
            selectedBounds.bottom,
            lessThanOrEqualTo(viewportBounds.bottom),
          );
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

    testWidgets('Windows ArrowUp and ArrowDown change puzzle lines', (
      tester,
    ) async {
      debugDefaultTargetPlatformOverride = TargetPlatform.windows;
      final container = ProviderContainer(
        overrides: [
          gameProvider.overrideWith(_VerticalShortcutGameProvider.new),
        ],
      );
      addTearDown(container.dispose);
      try {
        await _pumpKeyboardShortcuts(
          tester,
          container: container,
          language: Language.english,
        );
        final scrollSubscription = container.listen(
          scrollProvider(_gameKey),
          (_, _) {},
        );
        addTearDown(scrollSubscription.close);
        container
            .read(scrollProvider(_gameKey).notifier)
            .updateLayout(
              const PuzzleRows(
                [
                  [0, 1],
                  [2, 3],
                ],
                [0, 0, 1, 1],
              ),
              const PuzzleGeometry(100),
              200,
              600,
              0,
            );

        await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
        await tester.pump();
        expect(container.read(gameProvider(_gameKey)).selectedIdx, 3);

        await tester.sendKeyEvent(LogicalKeyboardKey.arrowUp);
        await tester.pump();
        expect(container.read(gameProvider(_gameKey)).selectedIdx, 1);
      } finally {
        debugDefaultTargetPlatformOverride = null;
      }
    });

    testWidgets('mobile ignores ArrowUp and ArrowDown shortcuts', (
      tester,
    ) async {
      debugDefaultTargetPlatformOverride = TargetPlatform.android;
      final container = ProviderContainer(
        overrides: [
          gameProvider.overrideWith(_VerticalShortcutGameProvider.new),
        ],
      );
      addTearDown(container.dispose);
      try {
        await _pumpKeyboardShortcuts(
          tester,
          container: container,
          language: Language.english,
        );
        final scrollSubscription = container.listen(
          scrollProvider(_gameKey),
          (_, _) {},
        );
        addTearDown(scrollSubscription.close);
        container
            .read(scrollProvider(_gameKey).notifier)
            .updateLayout(
              const PuzzleRows(
                [
                  [0, 1],
                  [2, 3],
                ],
                [0, 0, 1, 1],
              ),
              const PuzzleGeometry(100),
              200,
              600,
              0,
            );

        await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
        await tester.pump();

        expect(container.read(gameProvider(_gameKey)).selectedIdx, 1);
      } finally {
        debugDefaultTargetPlatformOverride = null;
      }
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
