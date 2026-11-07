import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/services.dart' show FontLoader, rootBundle;
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:scioly_codebusters/library.dart';

const _gameKey = 'finished quote test';
const _edgeClearance = 38.0;
const _previewOutputEnvironmentVariable = 'CIPHERBENCH_FINISHED_QUOTE_PREVIEW';
const _scaledPreviewOutputEnvironmentVariable =
    'CIPHERBENCH_FINISHED_QUOTE_SCALED_PREVIEW';
const _previewBoundaryKey = ValueKey('finished-quote-preview');
const _favoritedActionLabels = <String>[
  'Play Again',
  'View completed quote',
  'Unfavorite Quote',
  'Home',
];
const _unfavoritedActionLabels = <String>[
  'Play Again',
  'View completed quote',
  'Add to favorites',
  'Home',
];

class _CompletedGameProvider extends GameProvider {
  @override
  Game build(String gameKey) => Game(quote: Quote(), rating: 3);
}

class _FixedTimerNotifier extends TimerNotifier {
  @override
  double getTime() => 12.34;
}

class _BundledQuote {
  const _BundledQuote({required this.text, required this.author});

  final String text;
  final String author;
}

late Box<SolvedQuote> _quotesBox;

Finder _action(String label) => find.byWidgetPredicate(
  (widget) => widget is StyledButtonWidget && widget.value == label,
);

List<String> _actionLabels(bool favorited) =>
    favorited ? _favoritedActionLabels : _unfavoritedActionLabels;

_BundledQuote _longestBundledQuote(String assetName) {
  final quotes =
      jsonDecode(File('assets\\quotes\\$assetName').readAsStringSync())
          as Map<String, dynamic>;
  final longest = quotes.values.cast<Map<String, dynamic>>().reduce(
    (longest, quote) =>
        (quote['quote'] as String).length > (longest['quote'] as String).length
        ? quote
        : longest,
  );
  return _BundledQuote(
    text: longest['quote'] as String,
    author: longest['author'] as String,
  );
}

Future<void> _pumpFinishedQuote(
  WidgetTester tester, {
  required Size size,
  required _BundledQuote quote,
  bool favorited = true,
  double textScale = 1,
}) async {
  await _quotesBox.clear();
  await _quotesBox.add(
    SolvedQuote(
      text: quote.text,
      author: quote.author,
      rating: 3,
      solveTime: 12.34,
      gameMode: _gameKey,
      date: DateTime(2026),
      isFavorite: favorited,
    ),
  );

  final container = ProviderContainer(
    overrides: [
      gameProvider.overrideWith(_CompletedGameProvider.new),
      timerProvider.overrideWith(_FixedTimerNotifier.new),
    ],
  );
  addTearDown(container.dispose);

  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  await tester.pumpWidget(
    RepaintBoundary(
      key: _previewBoundaryKey,
      child: UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          theme: AppTheme.theme,
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(
              context,
            ).copyWith(textScaler: TextScaler.linear(textScale)),
            child: child!,
          ),
          home: Scaffold(
            body: FinishedQuoteWidget(
              quote: quote.text,
              author: quote.author,
              gameKey: _gameKey,
            ),
          ),
        ),
      ),
    ),
  );
  await tester.pump();
}

Future<void> _savePreviewIfRequested(
  WidgetTester tester, [
  String environmentVariable = _previewOutputEnvironmentVariable,
]) async {
  final path = Platform.environment[environmentVariable];
  if (path == null || path.isEmpty) return;

  final output = File(path).absolute;
  final repository = Directory.current.absolute.path.toLowerCase();
  if (output.path.toLowerCase().startsWith('$repository\\')) {
    throw ArgumentError.value(
      path,
      environmentVariable,
      'must point outside the repository',
    );
  }

  final originalAutoUpdate = autoUpdateGoldenFiles;
  autoUpdateGoldenFiles = true;
  try {
    await expectLater(
      find.byKey(_previewBoundaryKey),
      matchesGoldenFile(output.uri),
    );
  } finally {
    autoUpdateGoldenFiles = originalAutoUpdate;
  }
}

Future<void> _loadPreviewFonts() async {
  final loaders = [
    FontLoader('JetBrainsMono')
      ..addFont(rootBundle.load('assets/fonts/JetBrainsMono-Regular.ttf')),
    FontLoader('JetBrainsMonoBold')
      ..addFont(rootBundle.load('assets/fonts/JetBrainsMono-SemiBold.ttf')),
    FontLoader('MaterialIcons')
      ..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf')),
  ];
  for (final loader in loaders) {
    await loader.load();
  }
}

Rect _actionRowBounds(WidgetTester tester, List<String> actionLabels) {
  final bounds = actionLabels.map((label) => tester.getRect(_action(label)));
  return bounds.reduce(
    (combined, bounds) => Rect.fromLTRB(
      combined.left < bounds.left ? combined.left : bounds.left,
      combined.top < bounds.top ? combined.top : bounds.top,
      combined.right > bounds.right ? combined.right : bounds.right,
      combined.bottom > bounds.bottom ? combined.bottom : bounds.bottom,
    ),
  );
}

void _expectCompactActionRow(
  WidgetTester tester,
  Size size,
  List<String> actionLabels,
) {
  final actionBounds = <Rect>[
    for (final label in actionLabels) tester.getRect(_action(label)),
  ];
  final rowBounds = _actionRowBounds(tester, actionLabels);

  for (var index = 0; index < actionBounds.length; index++) {
    final bounds = actionBounds[index];
    expect(bounds.top, closeTo(actionBounds.first.top, 0.1));
    expect(bounds.bottom, closeTo(actionBounds.first.bottom, 0.1));
    expect(bounds.height, closeTo(actionBounds.first.height, 0.1));
    expect(
      bounds.width,
      lessThanOrEqualTo((size.width - 2 * _edgeClearance) / 4),
    );
    final labelFinder = find.descendant(
      of: _action(actionLabels[index]),
      matching: find.byType(Text),
    );
    final labelBounds = tester.getRect(labelFinder);
    expect(labelBounds.left, greaterThanOrEqualTo(bounds.left));
    expect(labelBounds.right, lessThanOrEqualTo(bounds.right));
    expect(labelBounds.top, greaterThanOrEqualTo(bounds.top));
    expect(labelBounds.bottom, lessThanOrEqualTo(bounds.bottom));
    final label = tester.widget<Text>(labelFinder);
    expect(label.semanticsLabel, actionLabels[index]);
    expect(label.maxLines, 2);
    final paragraph = tester.renderObject<RenderParagraph>(
      find.descendant(of: labelFinder, matching: find.byType(RichText)),
    );
    expect(paragraph.didExceedMaxLines, isFalse);
    final glyphBoxes = paragraph.getBoxesForSelection(
      TextSelection(baseOffset: 0, extentOffset: label.data!.length),
    );
    expect(glyphBoxes, isNotEmpty);
    for (final box in glyphBoxes) {
      final paintedBounds = MatrixUtils.transformRect(
        paragraph.getTransformTo(null),
        box.toRect(),
      );
      expect(
        paintedBounds.left,
        greaterThanOrEqualTo(bounds.left + 1),
        reason: '${actionLabels[index]} has glyphs clipped at the left',
      );
      expect(
        paintedBounds.right,
        lessThanOrEqualTo(bounds.right - 1),
        reason: '${actionLabels[index]} has glyphs clipped at the right',
      );
      expect(
        paintedBounds.top,
        greaterThanOrEqualTo(bounds.top + 1),
        reason: '${actionLabels[index]} has glyphs clipped at the top',
      );
      expect(
        paintedBounds.bottom,
        lessThanOrEqualTo(bounds.bottom - 1),
        reason: '${actionLabels[index]} has glyphs clipped at the bottom',
      );
    }
    expect(
      label.data!.split('\n').length,
      lessThanOrEqualTo(2),
      reason: '${actionLabels[index]} must fit in at most two lines',
    );
  }
  expect(rowBounds.left, greaterThanOrEqualTo(_edgeClearance));
  expect(rowBounds.right, lessThanOrEqualTo(size.width - _edgeClearance));
  expect(rowBounds.bottom, lessThanOrEqualTo(size.height - _edgeClearance));
  expect(tester.takeException(), isNull);
}

void _expectOnScreen(WidgetTester tester, Finder finder, Size size) {
  final bounds = tester.getRect(finder);
  expect(bounds.left, greaterThanOrEqualTo(0));
  expect(bounds.top, greaterThanOrEqualTo(0));
  expect(bounds.right, lessThanOrEqualTo(size.width));
  expect(bounds.bottom, lessThanOrEqualTo(size.height));
}

Future<void> _runWindowsTest(
  WidgetTester tester,
  Future<void> Function() body,
) async {
  debugDefaultTargetPlatformOverride = TargetPlatform.windows;
  try {
    await body();
  } finally {
    debugDefaultTargetPlatformOverride = null;
    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
  }
}

void main() {
  setUpAll(() async {
    await _loadPreviewFonts();
    Hive.init(null);
    if (!Hive.isAdapterRegistered(2)) {
      Hive.registerAdapter(SolvedQuoteAdapter());
    }
    _quotesBox = await Hive.openBox<SolvedQuote>(
      'quotesBox',
      bytes: base64Decode(''),
    );
  });

  tearDownAll(() async {
    await Hive.close();
  });

  testWidgets(
    'Windows keeps all completed-puzzle actions compact in one bottom row',
    (tester) async {
      await _runWindowsTest(tester, () async {
        final quote = _BundledQuote(
          text: 'A concise completed puzzle quote.',
          author: 'CipherBench',
        );

        for (final favorited in [true, false]) {
          final actionLabels = _actionLabels(favorited);
          for (final size in const [Size(1100, 720), Size(800, 600)]) {
            await _pumpFinishedQuote(
              tester,
              size: size,
              quote: quote,
              favorited: favorited,
            );

            for (final label in actionLabels) {
              expect(_action(label), findsOneWidget);
            }
            _expectCompactActionRow(tester, size, actionLabels);
          }
        }
      });
    },
  );

  testWidgets(
    'Windows keeps the longest bundled quotes and fixed actions accessible',
    (tester) async {
      await _runWindowsTest(tester, () async {
        for (final assetName in const [
          'englishQuotes.json',
          'spanishQuotes.json',
        ]) {
          final quote = _longestBundledQuote(assetName);
          const size = Size(800, 600);
          await _pumpFinishedQuote(
            tester,
            size: size,
            quote: quote,
            favorited: true,
          );

          final quoteText = find.textContaining(quote.text);
          final authorText = find.text('-${quote.author}');
          expect(quoteText, findsOneWidget);
          expect(authorText, findsOneWidget);
          expect(_action('Unfavorite Quote'), findsOneWidget);

          await tester.ensureVisible(quoteText);
          await tester.pump();
          _expectOnScreen(tester, quoteText, size);

          await tester.ensureVisible(authorText);
          await tester.pump();
          _expectOnScreen(tester, authorText, size);

          // Moving through the quote must not scroll the persistent action row away.
          _expectCompactActionRow(tester, size, _favoritedActionLabels);
        }
      });
    },
  );

  testWidgets(
    'Windows keeps both favorite states readable at larger text scales',
    (tester) async {
      await _runWindowsTest(tester, () async {
        for (final scale in [1.5, 2.0]) {
          for (final favorited in [false, true]) {
            const size = Size(800, 600);
            await _pumpFinishedQuote(
              tester,
              size: size,
              quote: const _BundledQuote(
                text: 'The interpretation of dreams is a great art.',
                author: 'Paracelsus',
              ),
              favorited: favorited,
              textScale: scale,
            );
            _expectCompactActionRow(tester, size, _actionLabels(favorited));
            if (scale == 1.5 && !favorited) {
              await _savePreviewIfRequested(
                tester,
                _scaledPreviewOutputEnvironmentVariable,
              );
            }
          }
        }
      });
    },
  );

  testWidgets('renders a deterministic completion popup preview directly', (
    tester,
  ) async {
    await _runWindowsTest(tester, () async {
      await _pumpFinishedQuote(
        tester,
        size: const Size(800, 600),
        quote: _longestBundledQuote('englishQuotes.json'),
        favorited: false,
      );

      _expectCompactActionRow(
        tester,
        const Size(800, 600),
        _unfavoritedActionLabels,
      );
      await _savePreviewIfRequested(tester);
    });
  });

  testWidgets('Windows keeps actions reachable while the quote area scrolls', (
    tester,
  ) async {
    await _runWindowsTest(tester, () async {
      final longestEnglishQuote = _longestBundledQuote('englishQuotes.json');
      final scrollingQuote = _BundledQuote(
        text: List.filled(8, longestEnglishQuote.text).join('\n'),
        author: longestEnglishQuote.author,
      );
      const size = Size(800, 600);

      await _pumpFinishedQuote(
        tester,
        size: size,
        quote: scrollingQuote,
        favorited: true,
      );

      final quoteText = find.textContaining(longestEnglishQuote.text);
      final quoteScrollView = find.ancestor(
        of: quoteText,
        matching: find.byType(Scrollable),
      );
      expect(quoteScrollView, findsOneWidget);
      final actionRowBeforeScroll = _actionRowBounds(
        tester,
        _favoritedActionLabels,
      );

      await tester.drag(quoteScrollView, const Offset(0, -250));
      await tester.pump();

      expect(
        tester.state<ScrollableState>(quoteScrollView).position.pixels,
        greaterThan(0),
      );
      expect(
        _actionRowBounds(tester, _favoritedActionLabels).top,
        closeTo(actionRowBeforeScroll.top, 0.1),
      );
      _expectCompactActionRow(tester, size, _favoritedActionLabels);
    });
  });
}
