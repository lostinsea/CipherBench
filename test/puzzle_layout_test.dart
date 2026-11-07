import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:scioly_codebusters/library.dart';

Cell _cell(
  String plainText, {
  String text = '',
  String cipher = 'X',
  bool isException = false,
  int count = 1,
}) {
  return Cell(
    text: text,
    cipher: cipher,
    plainText: plainText,
    isException: isException,
    count: count,
  );
}

List<Cell> _cellsFor(String text, {required String gameId}) {
  return [
    for (final character in text.split(''))
      _cell(
        character,
        isException: gameId != 'Patristocrat' && character == ' ',
      ),
  ];
}

class _GridGameProvider extends GameProvider {
  @override
  Game build(String gameKey) {
    return Game(
      quote: Quote(),
      cells: [_cell('N', text: 'N', cipher: 'Q', count: 7)],
    );
  }
}

class _CellOutlineGameProvider extends GameProvider {
  @override
  Game build(String gameKey) {
    return Game(
      quote: Quote(),
      selectedIdx: 0,
      cells: [
        _cell('A', text: 'A', cipher: 'Q', count: 7).copyWith(isSelected: true),
        _cell('B', text: 'B', cipher: 'R', count: 8),
      ],
    );
  }
}

class _TwoRowGridGameProvider extends GameProvider {
  @override
  Game build(String gameKey) {
    return Game(
      quote: Quote(),
      cells: [
        _cell('A', text: 'A', cipher: 'Q'),
        _cell('B', text: 'B', cipher: 'R'),
      ],
    );
  }
}

class _ExceptionRowGridGameProvider extends GameProvider {
  @override
  Game build(String gameKey) {
    return Game(
      quote: Quote(),
      cells: [
        _cell('A', text: 'A', cipher: 'Q'),
        _cell('!', text: '!', isException: true),
        _cell('B', text: 'B', cipher: 'R'),
      ],
    );
  }
}

class _TrailingWhitespaceGridGameProvider extends GameProvider {
  @override
  Game build(String gameKey) {
    return Game(
      quote: Quote(),
      cells: [
        _cell('A', text: 'A', cipher: 'Q'),
        _cell('B', text: 'B', cipher: 'R'),
        _cell(' ', text: ' ', isException: true),
        _cell('C', text: 'C', cipher: 'S'),
        _cell(' ', text: ' ', isException: true),
      ],
    );
  }
}

const _firstCellKey = ValueKey('first-cell');
const _secondCellKey = ValueKey('second-cell');

Future<void> _pumpOutlineCells(
  WidgetTester tester, {
  required ProviderContainer container,
}) {
  return tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: MaterialApp(
        home: Scaffold(
          body: Row(
            children: const [
              CellWidget(
                key: _firstCellKey,
                index: 0,
                gameKey: 'outlines',
                geometry: PuzzleGeometry(100),
              ),
              CellWidget(
                key: _secondCellKey,
                index: 1,
                gameKey: 'outlines',
                geometry: PuzzleGeometry(100),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

BoxDecoration _cellDecoration(WidgetTester tester, Key key) {
  final decoration = tester
      .renderObject<RenderDecoratedBox>(
        find
            .descendant(
              of: find.byKey(key),
              matching: find.byType(DecoratedBox),
            )
            .first,
      )
      .decoration;
  return decoration as BoxDecoration;
}

Finder _renderedCell(String text) {
  return find.ancestor(
    of: find.text(text),
    matching: find.byType(AnimatedContainer),
  );
}

Finder _exceptionCell(PuzzleGeometry geometry) {
  return find.byWidgetPredicate(
    (widget) =>
        widget is SizedBox &&
        widget.width == geometry.cellWidth &&
        widget.height == geometry.cellHeight,
  );
}

List<List<Rect>> _renderedCellBoundsByRow(WidgetTester tester) {
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

void main() {
  group('PuzzleGeometry', () {
    test('scales all puzzle dimensions from the zoom percent', () {
      final geometry = PuzzleGeometry(150);

      expect(geometry.cellWidth, 30);
      expect(geometry.cellHeight, 37.5);
      expect(geometry.labelHeight, 21);
      expect(geometry.gap, 6);
      expect(geometry.cellFontSize, 22.5);
      expect(geometry.labelFontSize, 15);
      expect(geometry.exceptionFontSize, 27);
      expect(geometry.rowHeight, 97.5);
    });

    test('adds a constant Windows row gap independently of zoom', () {
      const extraRowGap = 22.75;
      const lowZoom = PuzzleGeometry(105, extraRowGap: extraRowGap);
      const defaultZoom = PuzzleGeometry(140, extraRowGap: extraRowGap);
      const highZoom = PuzzleGeometry(280, extraRowGap: extraRowGap);

      expect(lowZoom.rowHeight, closeTo(68.25 + 22.75, 0.0001));
      expect(defaultZoom.cellWidth, 28);
      expect(defaultZoom.cellHeight, 35);
      expect(defaultZoom.rowHeight, closeTo(91 + 22.75, 0.0001));
      expect(highZoom.rowHeight, closeTo(182 + 22.75, 0.0001));
    });

    testWidgets('scales a cell, its answer, cipher, and frequency label', (
      tester,
    ) async {
      final container = ProviderContainer(
        overrides: [gameProvider.overrideWith(_GridGameProvider.new)],
      );
      addTearDown(container.dispose);

      Future<void> pumpCell(int zoomPercent) {
        return tester.pumpWidget(
          UncontrolledProviderScope(
            container: container,
            child: MaterialApp(
              home: Scaffold(
                body: CellWidget(
                  index: 0,
                  gameKey: 'geometry',
                  geometry: PuzzleGeometry(zoomPercent),
                ),
              ),
            ),
          ),
        );
      }

      await pumpCell(100);
      await tester.pumpAndSettle();
      expect(
        tester.getSize(find.byType(AnimatedContainer)),
        const Size(20, 25),
      );
      expect(tester.widget<Text>(find.text('N')).style!.fontSize, 15);
      expect(tester.widget<Text>(find.text('Q')).style!.fontSize, 10);
      expect(tester.widget<Text>(find.text('7')).style!.fontSize, 10);

      await pumpCell(150);
      await tester.pumpAndSettle();
      expect(
        tester.getSize(find.byType(AnimatedContainer)),
        const Size(30, 37.5),
      );
      expect(tester.widget<Text>(find.text('N')).style!.fontSize, 22.5);
      expect(tester.widget<Text>(find.text('Q')).style!.fontSize, 15);
      expect(tester.widget<Text>(find.text('7')).style!.fontSize, 15);
    });

    testWidgets(
      'Windows extra row gap spaces rendered rows farther apart without resizing cells',
      (tester) async {
        final container = ProviderContainer(
          overrides: [gameProvider.overrideWith(_TwoRowGridGameProvider.new)],
        );
        addTearDown(container.dispose);

        Future<(Size, double)> pumpGrid(double extraRowGap) async {
          await tester.pumpWidget(
            UncontrolledProviderScope(
              container: container,
              child: MaterialApp(
                home: Scaffold(
                  body: Align(
                    alignment: Alignment.topLeft,
                    child: SizedBox(
                      width: 34,
                      child: CryptogramGridWidget(
                        gameKey: 'rows',
                        gameId: 'Aristocrat',
                        zoomPercent: 140,
                        extraRowGap: extraRowGap,
                        bottomInset: 0,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          );
          await tester.pumpAndSettle();
          final first = tester.getRect(_renderedCell('A'));
          final second = tester.getRect(_renderedCell('B'));
          return (first.size, second.top - first.top);
        }

        final standard = await pumpGrid(0);
        final windows = await pumpGrid(22.75);

        expect(standard.$2, closeTo(91, 0.0001));
        expect(windows.$1, standard.$1);
        expect(windows.$2, closeTo(113.75, 0.0001));
        expect(windows.$2 - standard.$2, closeTo(22.75, 0.0001));
      },
    );

    testWidgets(
      'Windows row gap preserves punctuation alignment with square cells',
      (tester) async {
        debugDefaultTargetPlatformOverride = TargetPlatform.windows;
        final container = ProviderContainer(
          overrides: [
            gameProvider.overrideWith(_ExceptionRowGridGameProvider.new),
          ],
        );
        addTearDown(container.dispose);

        Future<(double, double)> pumpGrid(
          int zoomPercent,
          double extraRowGap,
        ) async {
          final geometry = PuzzleGeometry(
            zoomPercent,
            extraRowGap: extraRowGap,
          );
          await tester.pumpWidget(
            UncontrolledProviderScope(
              container: container,
              child: MaterialApp(
                home: Scaffold(
                  body: Align(
                    alignment: Alignment.topLeft,
                    child: SizedBox(
                      width: geometry.cellWidth * 2 + geometry.gap,
                      child: CryptogramGridWidget(
                        gameKey: 'exception-rows',
                        gameId: 'Aristocrat',
                        zoomPercent: zoomPercent,
                        extraRowGap: extraRowGap,
                        bottomInset: 0,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          );
          await tester.pumpAndSettle();

          final normal = tester.getRect(_renderedCell('A'));
          final exception = tester.getRect(_exceptionCell(geometry));
          final nextRowNormal = tester.getRect(_renderedCell('B'));
          return (exception.top - normal.top, nextRowNormal.top - normal.top);
        }

        try {
          for (final zoomPercent in [140, 280]) {
            final base = await pumpGrid(zoomPercent, 0);
            final windows = await pumpGrid(zoomPercent, 22.75);
            final baseGeometry = PuzzleGeometry(zoomPercent);

            expect(windows.$1, closeTo(base.$1, 0.0001));
            expect(base.$2, closeTo(baseGeometry.rowHeight, 0.0001));
            expect(windows.$2, closeTo(baseGeometry.rowHeight + 22.75, 0.0001));
          }
        } finally {
          debugDefaultTargetPlatformOverride = null;
        }
      },
    );
  });

  group('CellWidget selected outlines', () {
    testWidgets('uses amber 2px outline for the selected Windows cell', (
      tester,
    ) async {
      debugDefaultTargetPlatformOverride = TargetPlatform.windows;
      final container = ProviderContainer(
        overrides: [gameProvider.overrideWith(_CellOutlineGameProvider.new)],
      );
      addTearDown(container.dispose);
      try {
        await _pumpOutlineCells(tester, container: container);

        var selected = _cellDecoration(tester, _firstCellKey);
        var unselected = _cellDecoration(tester, _secondCellKey);
        expect(selected.color, const Color.fromARGB(255, 3, 0, 175));
        expect(
          selected.border,
          Border.all(color: const Color(0xFFFFD54F), width: 2),
        );
        expect(unselected.border, Border.all(color: gameCellColor, width: 1));

        await tester.tap(
          find.descendant(
            of: find.byKey(_secondCellKey),
            matching: find.byType(InkWell),
          ),
        );
        await tester.pumpAndSettle();

        selected = _cellDecoration(tester, _secondCellKey);
        unselected = _cellDecoration(tester, _firstCellKey);
        expect(selected.color, const Color.fromARGB(255, 3, 0, 175));
        expect(
          selected.border,
          Border.all(color: const Color(0xFFFFD54F), width: 2),
        );
        expect(unselected.border, Border.all(color: gameCellColor, width: 1));
      } finally {
        debugDefaultTargetPlatformOverride = null;
      }
    });

    testWidgets('keeps the existing 1px green selected outline on mobile', (
      tester,
    ) async {
      debugDefaultTargetPlatformOverride = TargetPlatform.android;
      final container = ProviderContainer(
        overrides: [gameProvider.overrideWith(_CellOutlineGameProvider.new)],
      );
      addTearDown(container.dispose);
      try {
        await _pumpOutlineCells(tester, container: container);

        final selected = _cellDecoration(tester, _firstCellKey);
        expect(selected.color, const Color.fromARGB(255, 3, 0, 175));
        expect(selected.border, Border.all(color: gameCellColor, width: 1));
      } finally {
        debugDefaultTargetPlatformOverride = null;
      }
    });

    testWidgets(
      'keeps the current Windows outline amber during rapid left and right moves',
      (tester) async {
        debugDefaultTargetPlatformOverride = TargetPlatform.windows;
        final container = ProviderContainer(
          overrides: [gameProvider.overrideWith(_CellOutlineGameProvider.new)],
        );
        addTearDown(container.dispose);
        try {
          await _pumpOutlineCells(tester, container: container);
          final game = container.read(gameProvider('outlines').notifier);

          for (final direction in [1, -1, 1, -1]) {
            game.incrementCell(direction);
            await tester.pump();

            final selectedIndex = container
                .read(gameProvider('outlines'))
                .selectedIdx;
            final selectedKey = selectedIndex == 0
                ? _firstCellKey
                : _secondCellKey;
            final decoration = _cellDecoration(tester, selectedKey);
            expect(
              decoration.border,
              Border.all(color: const Color(0xFFFFD54F), width: 2),
            );
          }
        } finally {
          debugDefaultTargetPlatformOverride = null;
        }
      },
    );
  });

  group('layoutPuzzleRows', () {
    test(
      'centered Patristocrat rows omit the final regular gap when measuring',
      () {
        final cells = _cellsFor('ABCD', gameId: 'Patristocrat');
        const geometry = PuzzleGeometry(100);

        expect(
          layoutPuzzleRows(cells, 'Patristocrat', 92, geometry).rows,
          equals([
            [0, 1, 2],
            [3],
          ]),
        );
        expect(
          layoutPuzzleRows(
            cells,
            'Patristocrat',
            92,
            geometry,
            omitTrailingSpacing: true,
          ).rows,
          equals([
            [0, 1, 2, 3],
          ]),
        );
      },
    );

    test('reflows Aristocrat words at Windows effective zoom bounds', () {
      final cells = _cellsFor('AB CD', gameId: 'Aristocrat');

      expect(
        layoutPuzzleRows(
          cells,
          'Aristocrat',
          162,
          const PuzzleGeometry(105),
        ).rows,
        equals([
          [0, 1, 2, 3, 4],
        ]),
      );
      expect(
        layoutPuzzleRows(
          cells,
          'Aristocrat',
          162,
          const PuzzleGeometry(140),
        ).rows,
        equals([
          [0, 1, 2],
          [3, 4],
        ]),
      );
      expect(
        layoutPuzzleRows(
          cells,
          'Aristocrat',
          162,
          const PuzzleGeometry(280),
        ).rows,
        equals([
          [0, 1],
          [2],
          [3, 4],
        ]),
      );
    });

    test('splits an overlong word only when it cannot fit on a row', () {
      final layout = layoutPuzzleRows(
        _cellsFor('ABCDE', gameId: 'Aristocrat'),
        'Aristocrat',
        72,
        const PuzzleGeometry(100),
      );

      expect(
        layout.rows,
        equals([
          [0, 1, 2],
          [3, 4],
        ]),
      );
      expect(layout.rowByCell, equals([0, 0, 0, 1, 1]));
    });

    test('does not group Patristocrat cells into words', () {
      final layout = layoutPuzzleRows(
        _cellsFor('ABCDE', gameId: 'Patristocrat'),
        'Patristocrat',
        48,
        const PuzzleGeometry(100),
      );

      expect(
        layout.rows,
        equals([
          [0, 1],
          [2, 3],
          [4],
        ]),
      );
      expect(layout.rowByCell, equals([0, 0, 1, 1, 2]));
    });
  });

  group('ScrollControllerNotifier vertical navigation', () {
    test('uses the nearest visible x across uneven centered rows', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final notifier = container.read(scrollProvider('vertical').notifier);
      final cells = List.generate(6, (index) => _cell('$index'));

      notifier.updateLayout(
        const PuzzleRows(
          [
            [0, 1, 2, 3],
            [4, 5],
          ],
          [0, 0, 0, 0, 1, 1],
        ),
        const PuzzleGeometry(100),
        200,
        600,
        0,
        centerRows: true,
      );

      expect(notifier.verticalNeighbor(1, 1, cells), 4);
      expect(notifier.verticalNeighbor(4, -1, cells), 1);
    });

    test(
      'skips exceptions and whitespace when finding a vertical neighbor',
      () {
        final container = ProviderContainer();
        addTearDown(container.dispose);
        final notifier = container.read(scrollProvider('vertical').notifier);
        final cells = [
          _cell('A'),
          _cell('B'),
          _cell(' ', isException: true),
          _cell(',', isException: true),
          _cell('C'),
        ];

        notifier.updateLayout(
          const PuzzleRows(
            [
              [0, 1],
              [2, 3, 4],
            ],
            [0, 0, 1, 1, 1],
          ),
          const PuzzleGeometry(100),
          200,
          600,
          0,
          centerRows: true,
        );

        expect(notifier.verticalNeighbor(1, 1, cells), 4);
        expect(notifier.verticalNeighbor(4, -1, cells), 1);
      },
    );

    test('has no vertical neighbor beyond the first and last rows', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final notifier = container.read(scrollProvider('vertical').notifier);
      final cells = List.generate(4, (index) => _cell('$index'));

      notifier.updateLayout(
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

      expect(notifier.verticalNeighbor(0, -1, cells), isNull);
      expect(notifier.verticalNeighbor(3, 1, cells), isNull);
    });
  });

  testWidgets(
    'centered wrapped Aristocrat rows trim trailing space exceptions',
    (tester) async {
      final container = ProviderContainer(
        overrides: [
          gameProvider.overrideWith(_TrailingWhitespaceGridGameProvider.new),
        ],
      );
      addTearDown(container.dispose);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(
            home: Scaffold(
              body: SizedBox(
                width: 70,
                child: CryptogramGridWidget(
                  gameKey: 'trailing-whitespace',
                  gameId: 'Aristocrat',
                  zoomPercent: 100,
                  bottomInset: 0,
                  centerRows: true,
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final gridBounds = tester.getRect(find.byType(LayoutBuilder));
      final rows = _renderedCellBoundsByRow(tester);

      expect(rows, hasLength(2));
      expect(rows.map((row) => row.length), [2, 1]);
      for (final row in rows) {
        final left = row
            .map((bounds) => bounds.left)
            .reduce((left, candidate) => left < candidate ? left : candidate);
        final right = row
            .map((bounds) => bounds.right)
            .reduce(
              (right, candidate) => right > candidate ? right : candidate,
            );
        expect((left + right) / 2, closeTo(gridBounds.center.dx, 0.001));
        expect(left, greaterThanOrEqualTo(gridBounds.left));
        expect(right, lessThanOrEqualTo(gridBounds.right));
      }
      expect(tester.takeException(), isNull);
    },
  );
}
