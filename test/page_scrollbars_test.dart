import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/services.dart' show FontLoader, rootBundle;
import 'package:flutter_test/flutter_test.dart';
import 'package:scioly_codebusters/library.dart';

const _previewKey = ValueKey('dictionary-preview');

Future<void> _savePreview(WidgetTester tester, String variable) async {
  final path = Platform.environment[variable];
  if (path == null || path.isEmpty) return;
  final output = File(path).absolute;
  if (output.path.toLowerCase().startsWith(
    '${Directory.current.absolute.path.toLowerCase()}\\',
  )) {
    throw ArgumentError.value(
      path,
      variable,
      'Preview must be outside the repository',
    );
  }
  final original = autoUpdateGoldenFiles;
  autoUpdateGoldenFiles = true;
  try {
    await expectLater(find.byKey(_previewKey), matchesGoldenFile(output.uri));
  } finally {
    autoUpdateGoldenFiles = original;
  }
}

Future<void> _loadPreviewFonts() async {
  for (final (name, path) in [
    ('JetBrainsMono', 'assets/fonts/JetBrainsMono-Regular.ttf'),
    ('JetBrainsMonoBold', 'assets/fonts/JetBrainsMono-SemiBold.ttf'),
    ('MaterialIcons', 'fonts/MaterialIcons-Regular.otf'),
  ]) {
    await (FontLoader(name)..addFont(rootBundle.load(path))).load();
  }
}

class _ScrollablePatternMapProvider extends PatternMapProvider {
  @override
  PatternMap build(String arg) => PatternMap.fromList([
    for (var length = 1; length <= 30; length++) 'A' * length,
    ...'OF TO IN IS IT HE ON AS AT BE OR BY WE AN DO IF UP SO GO NO MY ME US'
        .split(' '),
  ]);
}

class _PluralPatternMapProvider extends PatternMapProvider {
  @override
  PatternMap build(String arg) => arg == 'english'
      ? PatternMap.fromList(
          ['DREAM', 'LUNCH', 'APPLES', 'CHILDREN'],
          regularPlurals: ['DREAMS', 'LUNCHES', 'APPLES'],
        )
      : PatternMap.fromList(['HOLA']);
}

Finder _dictionaryScrollbar(String dictionaryId) => find.descendant(
  of: find.byWidgetPredicate(
    (widget) => widget is DictionaryTab && widget.dictionaryId == dictionaryId,
  ),
  matching: find.byWidgetPredicate(
    (widget) => widget is Scrollbar && widget.thumbVisibility == true,
  ),
);

Future<void> _dragThumb(WidgetTester tester, Finder finder) async {
  final scrollbar = tester.widget<Scrollbar>(finder);
  expect(scrollbar.trackVisibility, isTrue);
  expect(scrollbar.interactive, isTrue);
  final controller = scrollbar.controller!;
  expect(controller.positions, hasLength(1));
  expect(controller.position.maxScrollExtent, greaterThan(0));

  final bounds = tester.getRect(finder);
  final margin = ScrollbarTheme.of(tester.element(finder)).crossAxisMargin ?? 0;
  await tester.dragFrom(
    Offset(bounds.right - margin - 4, bounds.top + 12),
    const Offset(0, 170),
  );
  await tester.pumpAndSettle();
  expect(controller.offset, greaterThan(0));
}

Future<void> _checkStableDictionaryRange(
  WidgetTester tester,
  String language,
) async {
  final scrollbarFinder = _dictionaryScrollbar(language);
  final controller = tester.widget<Scrollbar>(scrollbarFinder).controller!;
  final initialExtent = controller.position.maxScrollExtent;
  final bounds = tester.getRect(scrollbarFinder);
  final margin =
      ScrollbarTheme.of(tester.element(scrollbarFinder)).crossAxisMargin ?? 0;
  final gesture = await tester.startGesture(
    Offset(bounds.right - margin - 4, bounds.top + 12),
  );
  for (var step = 0; step < 5; step++) {
    await gesture.moveBy(const Offset(0, 12));
    await tester.pump();
    expect(
      controller.position.maxScrollExtent,
      closeTo(initialExtent, initialExtent * 0.02),
      reason: '$language scrollbar changed its travel range at step $step',
    );
  }
  await gesture.up();
  await tester.pumpAndSettle();
  expect(controller.offset, greaterThan(0));
  controller.jumpTo(initialExtent);
  await tester.pumpAndSettle();
  expect(
    controller.position.maxScrollExtent,
    closeTo(initialExtent, initialExtent * 0.02),
  );
  final lastEntryIndex =
      (language == 'english'
          ? PatternMap.fromList([
              ...englishWordList,
              ...englishIrregularPlurals,
              ...englishIndependentHeadwords,
            ], regularPlurals: englishRegularPlurals).visibleEntries().length
          : PatternMap.fromList(spanishWordList).map.length) -
      1;
  expect(
    tester
        .widgetList<DictionaryEntryWidget>(find.byType(DictionaryEntryWidget))
        .map((entry) => entry.index),
    contains(lastEntryIndex),
  );
  expect(tester.takeException(), isNull);
}

void main() {
  testWidgets('Windows Dictionary tabs each have a draggable scrollbar', (
    tester,
  ) async {
    debugDefaultTargetPlatformOverride = TargetPlatform.windows;
    tester.view.physicalSize = const Size(800, 600);
    tester.view.devicePixelRatio = 1;
    try {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            patternMapProvider.overrideWith(_ScrollablePatternMapProvider.new),
          ],
          child: MaterialApp(
            theme: AppTheme.theme,
            initialRoute: '/dictionary',
            routes: {
              '/': (_) => const SizedBox.shrink(),
              '/dictionary': (_) => const DictionaryPage(),
            },
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byTooltip('Back'), findsOneWidget);

      double? narrowViewportWidth;
      double? narrowWordRight;
      for (final size in const [Size(800, 600), Size(1400, 600)]) {
        tester.view.physicalSize = size;
        await tester.pumpAndSettle();
        final scrollbarFinder = _dictionaryScrollbar('english');
        final controller = tester
            .widget<Scrollbar>(scrollbarFinder)
            .controller!;
        controller.jumpTo(0);
        await tester.pump();
        final words = find.descendant(
          of: find.byType(DictionaryEntryWidget),
          matching: find.byType(DictionaryWordWidget),
        );
        final wordRects = tester
            .widgetList<DictionaryWordWidget>(words)
            .map((word) => tester.getRect(find.byKey(word.wordKey)))
            .toList();
        final leftmostWord = wordRects
            .map((rect) => rect.left)
            .reduce((a, b) => a < b ? a : b);
        final rightmostWord = wordRects
            .map((rect) => rect.right)
            .reduce((a, b) => a > b ? a : b);
        final scrollbarRight = tester.getRect(scrollbarFinder).right;
        expect(tester.getRect(scrollbarFinder).left, windowsScreenInset);
        final margin = ScrollbarTheme.of(
          tester.element(scrollbarFinder),
        ).crossAxisMargin!;
        final gap = scrollbarRight - margin - 6 - rightmostWord;
        expect(gap, inInclusiveRange(0, 120));
        expect(tester.widget<AppBar>(find.byType(AppBar)).bottom, isNull);
        expect(
          tester.getRect(find.text('Pattern Dictionary')).center.dy,
          closeTo(tester.getRect(find.text('English')).center.dy, 1),
        );
        expect(
          tester.getRect(find.text('Show regular plurals')).left,
          closeTo(leftmostWord, 1),
        );
        final labelBounds = tester.getRect(find.text('Show regular plurals'));
        final switchBounds = tester.getRect(find.byType(Switch));
        final searchBounds = tester.getRect(find.byType(TextField).first);
        expect(switchBounds.left - labelBounds.right, greaterThanOrEqualTo(11));
        expect(
          searchBounds.left - switchBounds.right,
          greaterThanOrEqualTo(31),
        );
        expect(searchBounds.width, inInclusiveRange(270, 600));
        expect(searchBounds.right, closeTo(scrollbarRight - margin, 1));
        expect(size.width - (scrollbarRight - margin), windowsScreenInset + 24);
        if (narrowViewportWidth == null) {
          narrowViewportWidth = tester.getRect(scrollbarFinder).width;
          narrowWordRight = rightmostWord;
        } else {
          expect(
            tester.getRect(scrollbarFinder).width - narrowViewportWidth,
            greaterThan(500),
            reason:
                'Dictionary viewport is ${tester.getRect(scrollbarFinder).width} at $size '
                '(was $narrowViewportWidth at 800x600)',
          );
          expect(rightmostWord - narrowWordRight!, greaterThan(300));
        }
        await _dragThumb(tester, scrollbarFinder);
      }
      await tester.tap(find.text('Spanish'));
      await tester.pumpAndSettle();
      await _dragThumb(tester, _dictionaryScrollbar('spanish'));
      expect(find.byType(TextField), findsOneWidget);
      expect(find.byType(Switch), findsNothing);
      expect(tester.getSize(find.byType(TextField)).width, closeTo(600, 1));
      expect(
        tester.getRect(find.byType(TextField)).right,
        closeTo(tester.getRect(_dictionaryScrollbar('spanish')).right - 24, 1),
      );
      expect(tester.takeException(), isNull);
    } finally {
      debugDefaultTargetPlatformOverride = null;
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    }
  });

  testWidgets('English Dictionary shows regular plurals only when enabled', (
    tester,
  ) async {
    debugDefaultTargetPlatformOverride = TargetPlatform.windows;
    tester.view.physicalSize = const Size(800, 600);
    tester.view.devicePixelRatio = 1;
    try {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            patternMapProvider.overrideWith(_PluralPatternMapProvider.new),
          ],
          child: MaterialApp(
            theme: AppTheme.theme,
            home: const DictionaryPage(),
          ),
        ),
      );
      await tester.pumpAndSettle();
      final toggle = find.byType(Switch);
      final plural = find.byWidgetPredicate(
        (widget) => widget is DictionaryWordWidget && widget.word == 'DREAMS',
      );
      final existing = find.byWidgetPredicate(
        (widget) => widget is DictionaryWordWidget && widget.word == 'APPLES',
      );
      expect(find.text('Show regular plurals'), findsOneWidget);
      expect(tester.widget<Switch>(toggle).value, isFalse);
      expect(plural, findsNothing);
      expect(existing, findsOneWidget);

      await tester.tap(toggle);
      await tester.pumpAndSettle();
      expect(tester.widget<Switch>(toggle).value, isTrue);
      expect(existing, findsOneWidget);
      await tester.enterText(find.byType(TextField), 'DREAMS');
      await tester.testTextInput.receiveAction(TextInputAction.done);
      for (var attempt = 0; attempt < 15; attempt++) {
        await tester.pump(const Duration(milliseconds: 600));
      }
      expect(plural, findsOneWidget);

      await tester.tap(toggle);
      await tester.pumpAndSettle();
      expect(plural, findsNothing);
      expect(existing, findsOneWidget);
      await tester.tap(find.text('Spanish'));
      await tester.pumpAndSettle();
      expect(
        find.descendant(
          of: find.byWidgetPredicate(
            (widget) =>
                widget is DictionaryTab && widget.dictionaryId == 'spanish',
          ),
          matching: toggle,
        ),
        findsNothing,
      );
      expect(tester.takeException(), isNull);
    } finally {
      debugDefaultTargetPlatformOverride = null;
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    }
  });

  testWidgets('Dictionary thumb drag stays stable and reaches both ends', (
    tester,
  ) async {
    debugDefaultTargetPlatformOverride = TargetPlatform.windows;
    tester.view.physicalSize = const Size(1100, 600);
    tester.view.devicePixelRatio = 1;
    try {
      if (Platform.environment.containsKey('CIPHERBENCH_DICTIONARY_PREVIEW') ||
          Platform.environment.containsKey(
            'CIPHERBENCH_DICTIONARY_WIDE_PREVIEW',
          )) {
        await _loadPreviewFonts();
      }
      await tester.pumpWidget(
        RepaintBoundary(
          key: _previewKey,
          child: ProviderScope(
            child: MaterialApp(
              theme: AppTheme.theme,
              home: const DictionaryPage(),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await _savePreview(tester, 'CIPHERBENCH_DICTIONARY_PREVIEW');
      await _checkStableDictionaryRange(tester, 'english');
      tester
          .widget<Scrollbar>(_dictionaryScrollbar('english'))
          .controller!
          .jumpTo(0);
      tester.view.physicalSize = const Size(1400, 600);
      await tester.pumpAndSettle();
      await _savePreview(tester, 'CIPHERBENCH_DICTIONARY_WIDE_PREVIEW');
      await tester.tap(find.text('Spanish'));
      await tester.pumpAndSettle();
      await _checkStableDictionaryRange(tester, 'spanish');
    } finally {
      debugDefaultTargetPlatformOverride = null;
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    }
  });

  testWidgets('enlarged Dictionary text keeps the last entry reachable', (
    tester,
  ) async {
    debugDefaultTargetPlatformOverride = TargetPlatform.windows;
    tester.view.physicalSize = const Size(800, 600);
    tester.view.devicePixelRatio = 1;
    try {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            theme: AppTheme.theme,
            home: MediaQuery(
              data: const MediaQueryData(
                size: Size(800, 600),
                textScaler: TextScaler.linear(1.5),
              ),
              child: const DictionaryPage(),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await _checkStableDictionaryRange(tester, 'english');
    } finally {
      debugDefaultTargetPlatformOverride = null;
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    }
  });

  testWidgets('Dictionary search reaches words near the end of the list', (
    tester,
  ) async {
    debugDefaultTargetPlatformOverride = TargetPlatform.windows;
    tester.view.physicalSize = const Size(1400, 600);
    tester.view.devicePixelRatio = 1;
    try {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            theme: AppTheme.theme,
            home: const DictionaryPage(),
          ),
        ),
      );
      await tester.pumpAndSettle();
      final target = PatternMap.fromList(
        [
          ...englishWordList,
          ...englishIrregularPlurals,
          ...englishIndependentHeadwords,
        ],
        regularPlurals: englishRegularPlurals,
      ).visibleEntries().last.value.last;
      await tester.enterText(find.byType(TextField).first, target);
      await tester.testTextInput.receiveAction(TextInputAction.done);
      for (var attempt = 0; attempt < 15; attempt++) {
        await tester.pump(const Duration(milliseconds: 600));
      }
      expect(
        find.descendant(
          of: find.byType(DictionaryWordWidget),
          matching: find.text(target),
        ),
        findsOneWidget,
      );
      expect(find.byType(CircularProgressIndicator), findsNothing);
      expect(tester.takeException(), isNull);
    } finally {
      debugDefaultTargetPlatformOverride = null;
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    }
  });

  testWidgets('Windows Stats page has a draggable scrollbar when overflowing', (
    tester,
  ) async {
    debugDefaultTargetPlatformOverride = TargetPlatform.windows;
    tester.view.physicalSize = const Size(800, 600);
    tester.view.devicePixelRatio = 1;
    try {
      await _loadPreviewFonts();
      await tester.pumpWidget(
        RepaintBoundary(
          key: _previewKey,
          child: ProviderScope(
            child: MaterialApp(
              theme: AppTheme.theme,
              home: StatsPage(
                widgetKey: 'Aristocrat (Assisted)',
                stats: QuoteStats(
                  avgSolveTimeAll: 30,
                  avgSolveTimeThisWeek: 30,
                  avgSolveTimeLastWeek: 30,
                  fastestSolveTimeAll: 15,
                  fastestSolveTimeThisWeek: 15,
                  fastestSolveTimeLastWeek: 15,
                  totalSolvedAll: 2,
                  totalSolvedThisWeek: 1,
                  totalSolvedLastWeek: 1,
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final scrollbarFinder = find.byWidgetPredicate(
        (widget) => widget is Scrollbar && widget.thumbVisibility == true,
      );
      final headerFinder = find.text(
        'Solve Statistics - Aristocrat (Assisted)',
      );
      final footerFinder = find.text(
        'Only 2-star solves and higher are counted',
      );
      expect(
        find.descendant(of: scrollbarFinder, matching: footerFinder),
        findsNothing,
      );
      double? headerHeight;
      double? footerHeight;
      for (final size in const [
        Size(800, 600),
        Size(1100, 600),
        Size(1400, 600),
      ]) {
        tester.view.physicalSize = size;
        await tester.pump();
        final scrollbar = tester.widget<Scrollbar>(scrollbarFinder);
        scrollbar.controller!.jumpTo(0);
        await tester.pump();

        final gap =
            tester.getRect(scrollbarFinder).right -
            tester.getRect(find.byType(StatBoxWidget).first).right;
        expect(gap, closeTo(78, 1));
        final column = tester.getRect(find.byType(StatBoxWidget).first);
        expect(column.center.dx, closeTo(size.width / 2, 1));
        expect(column.width, 480);
        final viewport = tester.getRect(scrollbarFinder);
        expect(viewport.width, 636);
        expect(viewport.center.dx, closeTo(size.width / 2, 1));
        final header = tester.getRect(headerFinder);
        expect(header.width, greaterThan(480));
        expect(header.center.dx, closeTo(size.width / 2, 1));
        expect(header.left, greaterThanOrEqualTo(windowsScreenInset));
        expect(viewport.top, greaterThan(header.bottom));
        headerHeight ??= header.height;
        expect(header.height, headerHeight);
        final footer = tester.getRect(footerFinder);
        expect(footer.center.dx, closeTo(size.width / 2, 1));
        expect(footer.left, greaterThanOrEqualTo(windowsScreenInset));
        expect(
          footer.right,
          lessThanOrEqualTo(size.width - windowsScreenInset),
        );
        expect(viewport.bottom, lessThanOrEqualTo(footer.top));
        footerHeight ??= footer.height;
        expect(footer.height, footerHeight);
        expect(footer.height, lessThan(50));
        final rows = find.byType(StatRowWidget);
        final valueEdges = List.generate(3, (index) {
          final row = rows.at(index);
          final value = tester.widget<StatRowWidget>(row).value;
          return tester
              .getRect(find.descendant(of: row, matching: find.text(value)))
              .right;
        });
        expect(valueEdges[1], closeTo(valueEdges[0], 1));
        expect(valueEdges[2], closeTo(valueEdges[0], 1));
        expect(
          size.width - tester.getRect(scrollbarFinder).right,
          greaterThanOrEqualTo(windowsScreenInset),
        );
        if (size.width == 1100) {
          await _savePreview(tester, 'CIPHERBENCH_STATS_PREVIEW');
        }
        await _dragThumb(tester, scrollbarFinder);
        expect(tester.getRect(headerFinder).top, header.top);
        expect(tester.getRect(footerFinder).top, footer.top);
      }
      expect(tester.takeException(), isNull);
    } finally {
      debugDefaultTargetPlatformOverride = null;
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    }
  });
}
