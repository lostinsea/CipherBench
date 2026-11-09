import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/services.dart' show FontLoader, rootBundle;
import 'package:flutter_test/flutter_test.dart';
import 'package:scioly_codebusters/Features/Settings/Models/setting_prefs.dart';
import 'package:scioly_codebusters/library.dart';

import 'database_test_utils.dart';

const _gameKey = 'Aristocrat (Manual)';
const _lastFrequency = '9999';
const _previewKey = ValueKey('plural-suggestions-preview');

Future<void> _savePluralPreview(WidgetTester tester) async {
  final path = Platform.environment['CIPHERBENCH_PLURALS_PREVIEW'];
  if (path == null || path.isEmpty) return;
  final file = File(path).absolute;
  if (file.path.toLowerCase().startsWith(
    '${Directory.current.absolute.path.toLowerCase()}\\',
  )) {
    throw ArgumentError.value(path, 'CIPHERBENCH_PLURALS_PREVIEW');
  }
  final original = autoUpdateGoldenFiles;
  autoUpdateGoldenFiles = true;
  try {
    await expectLater(find.byKey(_previewKey), matchesGoldenFile(file.uri));
  } finally {
    autoUpdateGoldenFiles = original;
  }
}

Cell _cell(
  String plainText, {
  required String cipher,
  int count = 1,
  bool isException = false,
}) {
  return Cell(
    text: isException ? plainText : '',
    cipher: cipher,
    plainText: plainText,
    count: count,
    isException: isException,
  );
}

List<Cell> _puzzleCells({required int wordCount}) {
  final cells = <Cell>[];
  for (var word = 0; word < wordCount; word++) {
    for (final (index, letter) in 'ABCDE'.split('').indexed) {
      cells.add(
        _cell(
          letter,
          cipher: 'C$word$index',
          count: word == wordCount - 1 && index == 4 ? 9999 : index + 1,
        ),
      );
    }
    cells.add(_cell(' ', cipher: ' ', isException: true));
  }
  return cells;
}

class _LongSuggestionsGameProvider extends GameProvider {
  @override
  Game build(String gameKey) {
    return Game(
      quote: Quote(),
      gameMode: GameMode.manual,
      showSuggestions: true,
      cells: _puzzleCells(wordCount: 70),
    );
  }
}

class _ShortSuggestionsGameProvider extends GameProvider {
  @override
  Game build(String gameKey) {
    return Game(
      quote: Quote(),
      gameMode: GameMode.manual,
      showSuggestions: true,
      cells: _puzzleCells(wordCount: 2),
    );
  }
}

class _SelectedCellGameProvider extends GameProvider {
  @override
  Game build(String gameKey) {
    final cells = _puzzleCells(wordCount: 70);
    final selectedIndex = 68 * 6 + 4;
    cells[selectedIndex] = cells[selectedIndex].copyWith(
      text: 'E',
      isSelected: true,
    );
    return Game(
      quote: Quote(),
      selectedIdx: selectedIndex,
      gameMode: GameMode.manual,
      cells: cells,
    );
  }
}

class _LongPatternMapProvider extends PatternMapProvider {
  @override
  PatternMap build(String dictionaryId) {
    final map = PatternMap();
    for (var start = 0; start < 22; start++) {
      map.addWord(
        String.fromCharCodes(List.generate(5, (offset) => 65 + start + offset)),
      );
    }
    return map;
  }
}

class _ShortPatternMapProvider extends PatternMapProvider {
  @override
  PatternMap build(String dictionaryId) {
    final map = PatternMap();
    map.addWord('ABCDE');
    return map;
  }
}

class _PluralSuggestionsGameProvider extends GameProvider {
  @override
  Game build(String gameKey) => Game(
    quote: Quote(),
    gameMode: GameMode.manual,
    showSuggestions: true,
    cells: [
      for (final (index, letter) in 'DREAMS'.split('').indexed)
        _cell(letter, cipher: 'C$index'),
      _cell(' ', cipher: ' ', isException: true),
    ],
  );
}

class _PluralSuggestionsPatternMapProvider extends PatternMapProvider {
  @override
  PatternMap build(String dictionaryId) => PatternMap.fromList(
    ['FRIEND', 'APPLES'],
    regularPlurals: ['DREAMS', 'APPLES'],
    verbForms: ['WALKED'],
    descriptiveForms: ['BOLDER'],
  );
}

class _EmptyPatternMapProvider extends PatternMapProvider {
  @override
  PatternMap build(String dictionaryId) => PatternMap();
}

class _FrequencySuggestionsGameProvider extends GameProvider {
  @override
  Game build(String gameKey) => Game(
    quote: Quote(),
    gameMode: GameMode.manual,
    showSuggestions: true,
    cells: [
      for (final (index, letter) in 'LOVE'.split('').indexed)
        _cell(letter, cipher: 'C$index'),
      _cell(' ', cipher: ' ', isException: true),
    ],
  );
}

class _FrequencySuggestionsPatternMapProvider extends PatternMapProvider {
  @override
  PatternMap build(String dictionaryId) =>
      PatternMap.fromList(['ZINC', 'LOVE']);
}

class _ProductionPatternSuggestionsGameProvider extends GameProvider {
  @override
  Game build(String gameKey) {
    final letters = gameKey.startsWith('ABCC')
        ? 'OEFF'.split('')
        : 'OEEF'.split('');
    return Game(
      quote: Quote(),
      gameMode: GameMode.manual,
      showSuggestions: true,
      cells: [
        for (final (index, letter) in letters.indexed)
          _cell(letter, cipher: 'C$index'),
        _cell(' ', cipher: ' ', isException: true),
      ],
    );
  }
}

Future<void> _pumpGame(
  WidgetTester tester,
  ProviderContainer container,
  Size size, {
  String gameId = 'Aristocrat',
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  await tester.pumpWidget(
    RepaintBoundary(
      key: _previewKey,
      child: UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          theme: AppTheme.theme,
          home: GamePageLayout(
            key: ValueKey(gameId),
            config: GamePageConfig(
              gameId: gameId,
              gameMode: GameMode.manual,
              language: Language.english,
            ),
            addKeyboard: false,
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

Finder _suggestionsScrollbar(ScrollController puzzleScroll) {
  return find.byWidgetPredicate(
    (widget) =>
        widget is Scrollbar &&
        widget.controller != null &&
        !identical(widget.controller, puzzleScroll),
  );
}

Finder _puzzleScrollbar(ScrollController puzzleScroll) {
  return find.byWidgetPredicate(
    (widget) =>
        widget is Scrollbar &&
        identical(widget.controller, puzzleScroll) &&
        widget.scrollbarOrientation == ScrollbarOrientation.right,
  );
}

Finder _suggestionsPanel({required bool isWindows}) {
  final height = isWindows ? desktopSuggestionsHeight : containerHeight * 2;
  return find.byWidgetPredicate(
    (widget) => widget is Container && widget.constraints?.maxHeight == height,
  );
}

Finder _selectedPuzzleCell() {
  return find.ancestor(
    of: find.descendant(
      of: find.byType(CryptogramGridWidget),
      matching: find.text('E'),
    ),
    matching: find.byType(AnimatedContainer),
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

Future<void> _withPlatform(
  TargetPlatform platform,
  Future<void> Function() body,
) async {
  debugDefaultTargetPlatformOverride = platform;
  try {
    await body();
  } finally {
    debugDefaultTargetPlatformOverride = null;
  }
}

void main() {
  setUpAll(() {
    installDatabase(openSeedDatabase());
  });

  tearDownAll(closeInstalledDatabase);

  group('dictionary suggestions', () {
    testWidgets(
      'Windows reorders English suggestions when preference changes',
      (tester) async {
        _ignoreHeaderListTileMaterialWarning();
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        await settingsStore!.save(SettingPrefs(frequencyWordOrder: false));
        await _withPlatform(TargetPlatform.windows, () async {
          final container = ProviderContainer(
            overrides: [
              gameProvider.overrideWith(_FrequencySuggestionsGameProvider.new),
              patternMapProvider.overrideWith(
                _FrequencySuggestionsPatternMapProvider.new,
              ),
            ],
          );
          addTearDown(container.dispose);
          await _pumpGame(tester, container, const Size(800, 600));

          double x(String word) => tester.getTopLeft(find.text(word)).dx;
          expect(x('ZINC'), lessThan(x('LOVE')));
          await settingsStore!.save(
            settingsStore!.prefs.copyWith(frequencyWordOrder: true),
          );
          await tester.pumpAndSettle();
          expect(x('LOVE'), lessThan(x('ZINC')));
          await settingsStore!.save(
            settingsStore!.prefs.copyWith(frequencyWordOrder: false),
          );
          await tester.pumpAndSettle();
          expect(x('ZINC'), lessThan(x('LOVE')));
          expect(tester.takeException(), isNull);
          await tester.pumpWidget(const SizedBox.shrink());
          await tester.pump(const Duration(milliseconds: 1));
        });
      },
    );

    testWidgets(
      'Windows production English form controls preserve ABCC and expand ABBC',
      (tester) async {
        _ignoreHeaderListTileMaterialWarning();
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        final originalPrefs = settingsStore!.prefs;
        addTearDown(() => settingsStore!.save(originalPrefs));
        await settingsStore!.save(
          originalPrefs.copyWith(frequencyWordOrder: false),
        );
        await _withPlatform(TargetPlatform.windows, () async {
          final container = ProviderContainer(
            overrides: [
              gameProvider.overrideWith(
                _ProductionPatternSuggestionsGameProvider.new,
              ),
            ],
          );
          addTearDown(container.dispose);
          await _pumpGame(
            tester,
            container,
            const Size(800, 600),
            gameId: 'ABCC',
          );

          final dictionary = container.read(patternMapProvider('english'));
          List<String> candidates(
            String word,
            (bool, bool, bool) state, {
            required bool frequencyOrder,
          }) => getSuggestedWords(
            [
              for (final (index, letter) in word.split('').indexed)
                _cell(letter, cipher: 'C$index'),
              _cell(' ', cipher: ' ', isException: true),
            ],
            0,
            dictionary.mapForOrder(frequencyOrder: frequencyOrder),
            includeWord: (candidate) => dictionary.isVisible(
              candidate,
              showRegularPlurals: state.$1,
              showVerbForms: state.$2,
              showDescriptiveForms: state.$3,
            ),
          );

          final states = [
            (false, false, false),
            (true, false, false),
            (false, true, false),
            (false, false, true),
            (true, true, false),
            (true, false, true),
            (false, true, true),
            (true, true, true),
          ];
          final abbcCounts = <(bool, bool, bool), int>{
            (false, false, false): 106,
            (true, false, false): 121,
            (false, true, false): 122,
            (false, false, true): 107,
            (true, true, false): 128,
            (true, false, true): 122,
            (false, true, true): 123,
            (true, true, true): 129,
          };
          var current = (false, false, false);

          Future<void> expectState((bool, bool, bool) state, int count) async {
            final controls = [
              ('PLURALS', current.$1, state.$1),
              ('VERBS', current.$2, state.$2),
              ('ADJ/ADV', current.$3, state.$3),
            ];
            for (final control in controls) {
              if (control.$2 == control.$3) continue;
              await tester.tap(
                find.text('${control.$1}: ${control.$2 ? 'ON' : 'OFF'}'),
              );
              await tester.pumpAndSettle();
            }
            current = state;
            for (final control in controls) {
              expect(
                find.text('${control.$1}: ${control.$3 ? 'ON' : 'OFF'}'),
                findsOneWidget,
              );
            }
            expect(
              find.descendant(
                of: _suggestionsPanel(isWindows: true),
                matching: find.text('$count'),
              ),
              findsOneWidget,
            );
          }

          for (final state in states) {
            final alphabetical = candidates(
              'OEFF',
              state,
              frequencyOrder: false,
            );
            final frequencyOrdered = candidates(
              'OEFF',
              state,
              frequencyOrder: true,
            );
            expect(alphabetical, hasLength(108));
            expect(frequencyOrdered.toSet(), alphabetical.toSet());
            await expectState(state, 108);
          }
          await settingsStore!.save(
            settingsStore!.prefs.copyWith(frequencyWordOrder: true),
          );
          await tester.pumpAndSettle();
          expect(
            find.descendant(
              of: _suggestionsPanel(isWindows: true),
              matching: find.text('108'),
            ),
            findsOneWidget,
          );

          await _pumpGame(
            tester,
            container,
            const Size(800, 600),
            gameId: 'ABBC',
          );
          expect(
            identical(
              dictionary,
              container.read(patternMapProvider('english')),
            ),
            isTrue,
          );
          current = (false, false, false);
          for (final state in states) {
            final alphabetical = candidates(
              'OEEF',
              state,
              frequencyOrder: false,
            );
            final frequencyOrdered = candidates(
              'OEEF',
              state,
              frequencyOrder: true,
            );
            expect(alphabetical, hasLength(abbcCounts[state]!));
            expect(frequencyOrdered.toSet(), alphabetical.toSet());
            await expectState(state, abbcCounts[state]!);
          }
          expect(
            candidates('OEEF', (false, false, false), frequencyOrder: true),
            isNot(contains('BEES')),
          );
          expect(
            candidates('OEEF', (true, false, false), frequencyOrder: true),
            contains('BEES'),
          );
          expect(
            candidates('OEEF', (false, true, false), frequencyOrder: true),
            contains('EFFS'),
          );
          expect(
            candidates('OEEF', (false, false, true), frequencyOrder: true),
            contains('WEER'),
          );

          await expectState((false, false, false), 106);
          final game = container.read(gameProvider('ABBC (Manual)').notifier);
          game.selectCell(0);
          for (final letter in 'BEES'.split('')) {
            game.setLetter(letter, false);
          }
          await tester.pumpAndSettle();
          expect(
            find.descendant(
              of: _suggestionsPanel(isWindows: true),
              matching: find.text('0'),
            ),
            findsOneWidget,
          );
          expect(find.text('BEES'), findsNothing);
          await tester.tap(find.text('PLURALS: OFF'));
          await tester.pumpAndSettle();
          expect(find.text('Reveal word'), findsOneWidget);
          await tester.tap(find.text('Reveal word'));
          await tester.pumpAndSettle();
          expect(
            find.descendant(
              of: _suggestionsPanel(isWindows: true),
              matching: find.text('BEES'),
            ),
            findsOneWidget,
          );
          await tester.tap(find.text('PLURALS: ON'));
          await tester.pumpAndSettle();
          expect(
            find.descendant(
              of: _suggestionsPanel(isWindows: true),
              matching: find.text('0'),
            ),
            findsOneWidget,
          );
          expect(find.text('BEES'), findsNothing);
          expect(tester.takeException(), isNull);
          await tester.pumpWidget(const SizedBox.shrink());
          await tester.pump(const Duration(milliseconds: 1));
        });
      },
    );

    testWidgets('Windows plural suggestions are hidden until enabled', (
      tester,
    ) async {
      _ignoreHeaderListTileMaterialWarning();
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await _withPlatform(TargetPlatform.windows, () async {
        if (Platform.environment.containsKey('CIPHERBENCH_PLURALS_PREVIEW')) {
          for (final (name, path) in [
            ('JetBrainsMono', 'assets/fonts/JetBrainsMono-Regular.ttf'),
            ('JetBrainsMonoBold', 'assets/fonts/JetBrainsMono-SemiBold.ttf'),
          ]) {
            await (FontLoader(name)..addFont(rootBundle.load(path))).load();
          }
        }
        final container = ProviderContainer(
          overrides: [
            gameProvider.overrideWith(_PluralSuggestionsGameProvider.new),
            patternMapProvider.overrideWith(
              _PluralSuggestionsPatternMapProvider.new,
            ),
          ],
        );
        addTearDown(container.dispose);
        await _pumpGame(tester, container, const Size(800, 600));

        expect(find.text('PLURALS: OFF'), findsOneWidget);
        expect(find.text('FRIEND'), findsNothing);
        expect(find.text('Reveal word'), findsOneWidget);
        await tester.tap(find.text('Reveal word'));
        await tester.pumpAndSettle();
        expect(find.text('FRIEND'), findsOneWidget);
        expect(find.text('DREAMS'), findsNothing);
        expect(find.byTooltip('Next suggestions'), findsNothing);
        expect(find.byTooltip('Previous suggestions'), findsNothing);
        await tester.tap(find.text('PLURALS: OFF'));
        await tester.pumpAndSettle();
        expect(find.text('PLURALS: ON'), findsOneWidget);
        expect(find.text('DREAMS'), findsOneWidget);
        await _savePluralPreview(tester);
        await tester.tap(find.text('PLURALS: ON'));
        await tester.pumpAndSettle();
        expect(find.text('DREAMS'), findsNothing);
        expect(tester.takeException(), isNull);
        await tester.pumpWidget(const SizedBox.shrink());
        await tester.pump(const Duration(milliseconds: 1));
      });
    });

    testWidgets('Windows form controls reveal borderless suggestions', (
      tester,
    ) async {
      _ignoreHeaderListTileMaterialWarning();
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await _withPlatform(TargetPlatform.windows, () async {
        final container = ProviderContainer(
          overrides: [
            gameProvider.overrideWith(_PluralSuggestionsGameProvider.new),
            patternMapProvider.overrideWith(
              _PluralSuggestionsPatternMapProvider.new,
            ),
          ],
        );
        addTearDown(container.dispose);
        await _pumpGame(tester, container, const Size(800, 600));
        expect(find.text('WALKED'), findsNothing);
        expect(find.text('BOLDER'), findsNothing);
        await tester.tap(find.text('VERBS: OFF'));
        await tester.pumpAndSettle();
        expect(find.text('WALKED'), findsOneWidget);
        expect(find.text('BOLDER'), findsNothing);
        await tester.tap(find.text('ADJ/ADV: OFF'));
        await tester.pumpAndSettle();
        expect(find.text('BOLDER'), findsOneWidget);
        expect(
          find.descendant(
            of: _suggestionsPanel(isWindows: true),
            matching: find.byType(StyledButtonWidget),
          ),
          findsNothing,
        );
        expect(tester.takeException(), isNull);
      });
    });

    testWidgets(
      'Windows puts a long suggestion list in its own scrollable panel and leaves the final frequency visible',
      (tester) async {
        _ignoreHeaderListTileMaterialWarning();
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        await _withPlatform(TargetPlatform.windows, () async {
          for (final size in const [Size(1100, 720), Size(800, 600)]) {
            final container = ProviderContainer(
              overrides: [
                gameProvider.overrideWith(_LongSuggestionsGameProvider.new),
                patternMapProvider.overrideWith(_LongPatternMapProvider.new),
              ],
            );
            addTearDown(container.dispose);
            await _pumpGame(tester, container, size);

            final puzzleScroll = container.read(scrollProvider(_gameKey));
            final panel = _suggestionsPanel(isWindows: true);
            final list = find.byType(ListView);
            final scrollbar = _suggestionsScrollbar(puzzleScroll);
            final labels = size.width < 1000
                ? ['PLURALS: OFF', 'VERBS: OFF', 'ADJ/ADV: OFF']
                : [
                    'SHOW REGULAR PLURALS: OFF',
                    'VERB FORMS: OFF',
                    'ADJ / ADV FORMS: OFF',
                  ];
            final buttons = [
              for (final label in labels)
                find.ancestor(
                  of: find.text(label),
                  matching: find.byType(TextButton),
                ),
            ];
            for (var index = 0; index < buttons.length - 1; index++) {
              final current = tester.getRect(buttons[index]);
              final next = tester.getRect(buttons[index + 1]);
              expect(next.left - current.right, greaterThanOrEqualTo(6));
              expect(next.center.dy, closeTo(current.center.dy, 1));
            }
            expect(
              tester.getRect(buttons.last).right,
              lessThanOrEqualTo(tester.getRect(panel).right),
            );
            expect(
              tester
                  .widget<TextButton>(buttons.first)
                  .style
                  ?.side
                  ?.resolve({})
                  ?.color,
              Colors.white24,
            );

            expect(panel, findsOneWidget);
            expect(list, findsOneWidget);
            expect(
              (tester.widget<Container>(panel).decoration! as BoxDecoration)
                  .border,
              const Border(top: BorderSide(color: Colors.lightBlueAccent)),
            );
            expect(find.text('MATCHING WORDS'), findsOneWidget);
            expect(find.text('22'), findsOneWidget);
            expect(
              tester.widget<ListView>(list).scrollDirection,
              Axis.horizontal,
            );
            expect(scrollbar, findsOneWidget);
            expect(
              tester.getRect(scrollbar).bottom - tester.getRect(list).bottom,
              closeTo(16, 0.1),
            );

            final suggestionsScroll = tester
                .widget<Scrollbar>(scrollbar)
                .controller!;
            final suggestionsScrollbar = tester.widget<Scrollbar>(scrollbar);
            expect(suggestionsScroll, isNot(same(puzzleScroll)));
            expect(suggestionsScrollbar.interactive, isTrue);
            expect(suggestionsScrollbar.trackVisibility, isTrue);
            expect(suggestionsScrollbar.thumbVisibility, isTrue);
            for (final finder in [scrollbar, _puzzleScrollbar(puzzleScroll)]) {
              final theme = ScrollbarTheme.of(tester.element(finder));
              expect(theme.trackColor!.resolve({}), Colors.transparent);
              expect(theme.trackBorderColor!.resolve({}), Colors.transparent);
            }
            expect(
              suggestionsScroll.position.axisDirection,
              AxisDirection.right,
            );
            expect(suggestionsScroll.position.maxScrollExtent, greaterThan(0));

            puzzleScroll.jumpTo(puzzleScroll.position.maxScrollExtent);
            await tester.pump();
            final lastFrequencyBounds = tester.getRect(
              find.text(_lastFrequency),
            );
            final panelBounds = tester.getRect(panel);
            expect(
              lastFrequencyBounds.bottom,
              lessThanOrEqualTo(panelBounds.top),
            );

            final beforeNextButton = suggestionsScroll.offset;
            final puzzleOffset = puzzleScroll.offset;
            expect(
              find.text(
                size.width < 1000
                    ? 'PLURALS: OFF'
                    : 'SHOW REGULAR PLURALS: OFF',
              ),
              findsOneWidget,
            );
            expect(find.byTooltip('Next suggestions'), findsNothing);
            await tester.drag(list, const Offset(-300, 0));
            await tester.pump();
            await tester.pumpAndSettle();
            expect(suggestionsScroll.offset, greaterThan(beforeNextButton));
            expect(puzzleScroll.offset, puzzleOffset);

            suggestionsScroll.jumpTo(0);
            expect(
              find.byWidgetPredicate(
                (widget) =>
                    widget is Listener && widget.onPointerSignal != null,
              ),
              findsWidgets,
            );
            await tester.pump();
            expect(suggestionsScroll.offset, 0);
            expect(puzzleScroll.offset, puzzleOffset);
            expect(tester.takeException(), isNull);
          }
          await tester.pump(const Duration(seconds: 1));
          await tester.pumpWidget(const SizedBox.shrink());
          await tester.pump(const Duration(milliseconds: 1));
        });
      },
    );

    testWidgets(
      'Windows keeps the selected cell visible when suggestions shrink the puzzle viewport',
      (tester) async {
        _ignoreHeaderListTileMaterialWarning();
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        await _withPlatform(TargetPlatform.windows, () async {
          final container = ProviderContainer(
            overrides: [
              gameProvider.overrideWith(_SelectedCellGameProvider.new),
              patternMapProvider.overrideWith(_LongPatternMapProvider.new),
            ],
          );
          addTearDown(container.dispose);
          await _pumpGame(tester, container, const Size(800, 600));

          final viewport = find.byType(SingleChildScrollView);
          expect(viewport, findsOneWidget);
          expect(_selectedPuzzleCell(), findsOneWidget);
          final beforeBounds = tester.getRect(_selectedPuzzleCell());
          final beforeViewport = tester.getRect(viewport);
          expect(beforeBounds.top, greaterThanOrEqualTo(beforeViewport.top));
          expect(beforeBounds.bottom, lessThanOrEqualTo(beforeViewport.bottom));

          container.read(gameProvider(_gameKey).notifier).setSuggestions(true);
          await tester.pumpAndSettle();

          final selectedBounds = tester.getRect(_selectedPuzzleCell());
          final viewportBounds = tester.getRect(viewport);
          expect(_suggestionsPanel(isWindows: true), findsOneWidget);
          expect(selectedBounds.top, greaterThanOrEqualTo(viewportBounds.top));
          expect(
            selectedBounds.bottom,
            lessThanOrEqualTo(viewportBounds.bottom),
          );
          expect(tester.takeException(), isNull);
          await tester.pumpWidget(const SizedBox.shrink());
          await tester.pump(const Duration(milliseconds: 1));
        });
      },
    );

    testWidgets(
      'Windows exposes long puzzle slots through its own vertical scrollbar',
      (tester) async {
        _ignoreHeaderListTileMaterialWarning();
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        await _withPlatform(TargetPlatform.windows, () async {
          final container = ProviderContainer(
            overrides: [
              gameProvider.overrideWith(_LongSuggestionsGameProvider.new),
              patternMapProvider.overrideWith(_LongPatternMapProvider.new),
            ],
          );
          addTearDown(container.dispose);
          await _pumpGame(tester, container, const Size(800, 600));

          final puzzleScroll = container.read(scrollProvider(_gameKey));
          final puzzleScrollbar = _puzzleScrollbar(puzzleScroll);
          final suggestionsScrollbar = _suggestionsScrollbar(puzzleScroll);
          final viewport = find.byType(SingleChildScrollView);
          final puzzleScrollable = find.descendant(
            of: viewport,
            matching: find.byType(Scrollable),
          );
          final finalSlot = find.text(_lastFrequency);
          final finalPuzzleCell = find
              .descendant(
                of: find.byType(CryptogramGridWidget),
                matching: find.byType(AnimatedContainer),
              )
              .at(70 * 5 - 1);

          expect(puzzleScrollbar, findsOneWidget);
          expect(suggestionsScrollbar, findsOneWidget);
          expect(viewport, findsOneWidget);
          expect(puzzleScrollable, findsOneWidget);
          final scrollbar = tester.widget<Scrollbar>(puzzleScrollbar);
          expect(scrollbar.controller, same(puzzleScroll));
          expect(scrollbar.interactive, isTrue);
          expect(scrollbar.trackVisibility, isTrue);
          expect(scrollbar.thumbVisibility, isTrue);
          expect(scrollbar.scrollbarOrientation, ScrollbarOrientation.right);
          expect(puzzleScroll.position.axisDirection, AxisDirection.down);
          expect(puzzleScroll.position.maxScrollExtent, greaterThan(0));
          expect(
            tester.getRect(finalSlot).top,
            greaterThan(tester.getRect(viewport).bottom),
          );

          final initialSuggestionOffset = tester
              .widget<Scrollbar>(suggestionsScrollbar)
              .controller!
              .offset;
          await tester.drag(viewport, const Offset(0, -2000));
          await tester.pumpAndSettle();

          expect(puzzleScroll.offset, greaterThan(0));
          await tester.scrollUntilVisible(
            finalSlot,
            200,
            scrollable: puzzleScrollable,
          );
          await tester.pumpAndSettle();
          expect(
            tester.getRect(finalSlot).top,
            greaterThanOrEqualTo(tester.getRect(viewport).top),
          );
          expect(
            tester.getRect(finalSlot).bottom,
            lessThanOrEqualTo(tester.getRect(viewport).bottom),
          );
          expect(
            tester.widget<Scrollbar>(suggestionsScrollbar).controller!.offset,
            initialSuggestionOffset,
          );

          await tester.tap(finalPuzzleCell);
          await tester.pump();
          expect(
            container.read(gameProvider(_gameKey)).selectedIdx,
            69 * 6 + 4,
          );

          final puzzleOffset = puzzleScroll.offset;
          await tester.drag(find.byType(ListView), const Offset(-300, 0));
          await tester.pumpAndSettle();
          expect(
            tester.widget<Scrollbar>(suggestionsScrollbar).controller!.offset,
            greaterThan(initialSuggestionOffset),
          );
          expect(puzzleScroll.offset, puzzleOffset);
          expect(tester.takeException(), isNull);
          await tester.pumpWidget(const SizedBox.shrink());
          await tester.pump(const Duration(milliseconds: 1));
        });
      },
    );

    testWidgets(
      'short and empty suggestions retain their existing selection behavior',
      (tester) async {
        _ignoreHeaderListTileMaterialWarning();
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        await _withPlatform(TargetPlatform.windows, () async {
          final shortContainer = ProviderContainer(
            overrides: [
              gameProvider.overrideWith(_ShortSuggestionsGameProvider.new),
              patternMapProvider.overrideWith(_ShortPatternMapProvider.new),
            ],
          );
          addTearDown(shortContainer.dispose);
          await _pumpGame(tester, shortContainer, const Size(800, 600));

          final shortPuzzleScroll = shortContainer.read(
            scrollProvider(_gameKey),
          );
          expect(shortPuzzleScroll.position.maxScrollExtent, 0);
          expect(shortPuzzleScroll.offset, 0);

          expect(find.text('ABCDE'), findsNothing);
          expect(find.text('Reveal word'), findsOneWidget);
          await tester.tap(find.text('Reveal word'));
          await tester.pumpAndSettle();
          expect(find.text('ABCDE'), findsOneWidget);
          shortContainer.read(gameProvider(_gameKey).notifier).selectCell(6);
          await tester.pumpAndSettle();
          expect(find.text('ABCDE'), findsNothing);
          expect(find.text('Reveal word'), findsOneWidget);
          shortContainer.read(gameProvider(_gameKey).notifier).selectCell(0);
          await tester.pumpAndSettle();
          await tester.tap(find.text('ABCDE'));
          await tester.pump();
          await tester.pump(const Duration(seconds: 1));
          expect(
            shortContainer
                .read(gameProvider(_gameKey))
                .cells
                .take(5)
                .map((cell) => cell.text),
            ['A', 'B', 'C', 'D', 'E'],
          );

          final emptyContainer = ProviderContainer(
            overrides: [
              gameProvider.overrideWith(_ShortSuggestionsGameProvider.new),
              patternMapProvider.overrideWith(_EmptyPatternMapProvider.new),
            ],
          );
          addTearDown(emptyContainer.dispose);
          await _pumpGame(tester, emptyContainer, const Size(800, 600));
          expect(_suggestionsPanel(isWindows: true), findsOneWidget);
          expect(find.byType(ListView), findsNothing);
          expect(find.text('ABCDE'), findsNothing);
          expect(find.text('No matching words'), findsOneWidget);
          expect(tester.takeException(), isNull);
          await tester.pumpWidget(const SizedBox.shrink());
          await tester.pump(const Duration(milliseconds: 1));
        });
      },
    );

    testWidgets('non-Windows retains the compact suggestion panel height', (
      tester,
    ) async {
      _ignoreHeaderListTileMaterialWarning();
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await _withPlatform(TargetPlatform.android, () async {
        final container = ProviderContainer(
          overrides: [
            gameProvider.overrideWith(_ShortSuggestionsGameProvider.new),
            patternMapProvider.overrideWith(_ShortPatternMapProvider.new),
          ],
        );
        addTearDown(container.dispose);
        await _pumpGame(tester, container, const Size(800, 600));

        expect(
          tester.getSize(_suggestionsPanel(isWindows: false)).height,
          containerHeight * 2,
        );
        expect(tester.takeException(), isNull);
        await tester.pumpWidget(const SizedBox.shrink());
        await tester.pump(const Duration(milliseconds: 1));
      });
    });

    testWidgets(
      'non-Windows keeps suggestion buttons above the horizontal scrollbar gutter',
      (tester) async {
        _ignoreHeaderListTileMaterialWarning();
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        await _withPlatform(TargetPlatform.android, () async {
          final container = ProviderContainer(
            overrides: [
              gameProvider.overrideWith(_ShortSuggestionsGameProvider.new),
              patternMapProvider.overrideWith(_ShortPatternMapProvider.new),
            ],
          );
          addTearDown(container.dispose);
          await _pumpGame(tester, container, const Size(800, 600));

          final suggestion = find.ancestor(
            of: find.text('ABCDE'),
            matching: find.byType(StyledButtonWidget),
          );
          final button = find.descendant(
            of: suggestion,
            matching: find.byType(InkWell),
          );
          final wordList = find.byType(ListView);

          expect(suggestion, findsOneWidget);
          expect(button, findsOneWidget);
          expect(wordList, findsOneWidget);
          final theme = ScrollbarTheme.of(
            tester.element(
              find.descendant(
                of: _suggestionsPanel(isWindows: false),
                matching: find.byType(Scrollbar),
              ),
            ),
          );
          expect(theme.trackColor!.resolve({}), const Color(0xFF152A35));
          expect(theme.trackBorderColor!.resolve({}), Colors.white38);
          expect(tester.getSize(button).height, containerHeight);
          expect(
            tester.getRect(button).bottom,
            lessThanOrEqualTo(tester.getRect(wordList).bottom - 6),
          );
          expect(tester.takeException(), isNull);
          await tester.pumpWidget(const SizedBox.shrink());
          await tester.pump(const Duration(milliseconds: 1));
        });
      },
    );
  });
}
