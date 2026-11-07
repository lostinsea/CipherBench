import 'dart:ui' show Tristate;
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:scioly_codebusters/library.dart';

const _gameId = 'Aristocrat';
const _assistedKey = '$_gameId (Assisted)';

class _ModeSpecificGameProvider extends GameProvider {
  @override
  Game build(String gameKey) {
    return Game(
      quote: Quote(),
      cells: gameKey == _assistedKey
          ? [
              Cell(
                text: '',
                cipher: 'A',
                plainText: 'A',
                isException: false,
                count: 1,
              ),
            ]
          : const [],
    );
  }
}

class _ExhaustedGameProvider extends GameProvider {
  @override
  Game build(String gameKey) => Game(quote: Quote());

  @override
  Future<void> buildCryptogram(
    GameMode gameMode,
    Language language,
    String gameId,
  ) async {
    throw NoUnseenQuotesException();
  }
}

class _SuccessfulGameProvider extends GameProvider {
  @override
  Game build(String gameKey) => Game(quote: Quote());

  @override
  Future<void> buildCryptogram(
    GameMode gameMode,
    Language language,
    String gameId,
  ) async {
    state = Game(quote: Quote(), gameMode: gameMode);
  }
}

class _RecordingNavigatorObserver extends NavigatorObserver {
  final pushedRoutes = <Route<dynamic>>[];

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    pushedRoutes.add(route);
    super.didPush(route, previousRoute);
  }
}

Future<void> _pumpGameSetup(
  WidgetTester tester,
  ProviderContainer container, {
  TextScaler textScaler = TextScaler.noScaling,
  NavigatorObserver? navigatorObserver,
}) {
  return tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: MaterialApp(
        theme: AppTheme.theme,
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context).copyWith(textScaler: textScaler),
          child: child!,
        ),
        navigatorObservers: navigatorObserver == null
            ? const []
            : [navigatorObserver],
        home: const GamePageSetup(gameId: _gameId, language: Language.english),
      ),
    ),
  );
}

Finder _outlinedButton(String label) =>
    find.widgetWithText(OutlinedButton, label);

Finder _semanticButton(String label) => find.bySemanticsLabel(label);

Finder _modeSelector() => find.byType(SegmentedButton<GameMode>);

SegmentedButton<GameMode> _segmentedModeControl(WidgetTester tester) =>
    tester.widget<SegmentedButton<GameMode>>(_modeSelector());

void _expectSelectedSemantics(
  WidgetTester tester,
  String label, {
  required bool selected,
}) {
  final node = tester.getSemantics(_semanticButton(label));
  expect(
    node.flagsCollection.isSelected,
    selected ? Tristate.isTrue : Tristate.isFalse,
  );
}

Rect _combinedBounds(WidgetTester tester, List<Finder> finders) {
  final bounds = finders.map(tester.getRect).toList();
  return bounds.reduce(
    (combined, bounds) => Rect.fromLTRB(
      combined.left < bounds.left ? combined.left : bounds.left,
      combined.top < bounds.top ? combined.top : bounds.top,
      combined.right > bounds.right ? combined.right : bounds.right,
      combined.bottom > bounds.bottom ? combined.bottom : bounds.bottom,
    ),
  );
}

void _ignoreGamePageListTileMaterialWarning() {
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

void main() {
  late Box<SolvedQuote> quotes;

  setUpAll(() async {
    Hive.init(null);
    Hive.registerAdapter(SolvedQuoteAdapter());
    quotes = await Hive.openBox<SolvedQuote>('quotesBox', bytes: Uint8List(0));
  });

  tearDownAll(() async {
    await quotes.close();
    await Hive.close();
  });

  testWidgets(
    'keeps the game setup compact, centered, and overflow-free at Windows sizes',
    (tester) async {
      addTearDown(() => tester.binding.setSurfaceSize(null));

      for (final size in const [Size(1100, 720), Size(800, 600)]) {
        final container = ProviderContainer(
          overrides: [gameProvider.overrideWith(_ModeSpecificGameProvider.new)],
        );
        addTearDown(container.dispose);
        await tester.binding.setSurfaceSize(size);
        await _pumpGameSetup(tester, container);
        await tester.pump();

        final content = find.byWidgetPredicate(
          (widget) =>
              widget is ConstrainedBox && widget.constraints.maxWidth == 700,
        );
        expect(content, findsOneWidget);
        final bounds = tester.getRect(content);
        expect(bounds.width, lessThanOrEqualTo(700));
        expect(bounds.center.dx, closeTo(size.width / 2, 1));
        expect(bounds.left, greaterThanOrEqualTo(windowsScreenInset));
        expect(
          size.width - bounds.right,
          greaterThanOrEqualTo(windowsScreenInset),
        );
        expect(tester.takeException(), isNull);

        await tester.pumpWidget(const SizedBox.shrink());
        await tester.pump();
      }
    },
  );

  testWidgets('separates the mode, play, and reference controls on Windows', (
    tester,
  ) async {
    addTearDown(() => tester.binding.setSurfaceSize(null));

    for (final size in const [Size(1100, 720), Size(800, 600)]) {
      final container = ProviderContainer(
        overrides: [gameProvider.overrideWith(_ModeSpecificGameProvider.new)],
      );
      addTearDown(container.dispose);
      await tester.binding.setSurfaceSize(size);
      await _pumpGameSetup(tester, container);
      await tester.pump();

      final modeBounds = tester.getRect(_modeSelector());
      final playBounds = _combinedBounds(tester, [
        _outlinedButton('Continue Puzzle'),
        _outlinedButton('New Puzzle'),
      ]);
      final referenceBounds = _combinedBounds(tester, [
        _outlinedButton('Stats'),
        _outlinedButton('How to Play'),
      ]);

      expect(find.text('OPTIONS'), findsNothing);
      expect(playBounds.top - modeBounds.bottom, greaterThanOrEqualTo(56));
      expect(referenceBounds.top - playBounds.bottom, greaterThanOrEqualTo(56));
      expect(
        tester.getRect(_outlinedButton('New Puzzle')).left -
            tester.getRect(_outlinedButton('Continue Puzzle')).right,
        closeTo(20, 1),
      );
      expect(
        tester.getRect(_outlinedButton('How to Play')).left -
            tester.getRect(_outlinedButton('Stats')).right,
        closeTo(20, 1),
      );

      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump();
    }
  });

  testWidgets('keeps key labels visible at 200% text scaling', (tester) async {
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.binding.setSurfaceSize(const Size(800, 600));
    final container = ProviderContainer(
      overrides: [gameProvider.overrideWith(_ModeSpecificGameProvider.new)],
    );
    addTearDown(container.dispose);
    await _pumpGameSetup(
      tester,
      container,
      textScaler: const TextScaler.linear(2),
    );
    await tester.pump();

    expect(find.byType(SingleChildScrollView), findsOneWidget);
    for (final label in const [
      'Continue Puzzle',
      'New Puzzle',
      'How to Play',
    ]) {
      final text = find.text(label);
      final bounds = tester.getRect(text);
      expect(tester.widget<Text>(text).overflow, isNot(TextOverflow.ellipsis));
      expect(bounds.left, greaterThanOrEqualTo(windowsScreenInset));
      expect(bounds.right, lessThanOrEqualTo(800 - windowsScreenInset));
    }
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'switches modes through a segmented option selector without navigating',
    (tester) async {
      final navigatorObserver = _RecordingNavigatorObserver();
      final container = ProviderContainer(
        overrides: [gameProvider.overrideWith(_ModeSpecificGameProvider.new)],
      );
      addTearDown(container.dispose);
      await _pumpGameSetup(
        tester,
        container,
        navigatorObserver: navigatorObserver,
      );
      await tester.pump();
      navigatorObserver.pushedRoutes.clear();

      final stats = _outlinedButton('Stats');
      final howToPlay = _outlinedButton('How to Play');
      expect(_modeSelector(), findsOneWidget);
      expect(_outlinedButton('Assisted'), findsNothing);
      expect(_outlinedButton('Manual'), findsNothing);
      expect(stats, findsOneWidget);
      expect(howToPlay, findsOneWidget);
      expect(_segmentedModeControl(tester).selected, {GameMode.assisted});
      _expectSelectedSemantics(tester, 'Assisted', selected: true);
      _expectSelectedSemantics(tester, 'Manual', selected: false);

      expect(find.text('Continue Puzzle'), findsOneWidget);
      expect(find.text('New Puzzle'), findsOneWidget);
      expect(
        tester
            .widget<OutlinedButton>(_outlinedButton('Continue Puzzle'))
            .style
            ?.backgroundColor
            ?.resolve(const <WidgetState>{}),
        AppTheme.logoGreen,
      );
      expect(
        tester
            .widget<OutlinedButton>(_outlinedButton('New Puzzle'))
            .style
            ?.backgroundColor
            ?.resolve(const <WidgetState>{}),
        Colors.transparent,
      );

      await tester.tap(find.text('Manual'));
      await tester.pump();

      expect(container.read(gameModeProvider(_gameId)), GameMode.manual);
      expect(_segmentedModeControl(tester).selected, {GameMode.manual});
      expect(navigatorObserver.pushedRoutes, isEmpty);
      expect(find.text('Continue Puzzle'), findsNothing);
      expect(find.text('New Puzzle'), findsOneWidget);
      _expectSelectedSemantics(tester, 'Assisted', selected: false);
      _expectSelectedSemantics(tester, 'Manual', selected: true);
      expect(
        tester
            .widget<OutlinedButton>(_outlinedButton('New Puzzle'))
            .style
            ?.backgroundColor
            ?.resolve(const <WidgetState>{}),
        AppTheme.logoGreen,
      );

      await tester.tap(find.text('Assisted'));
      await tester.pump();

      expect(container.read(gameModeProvider(_gameId)), GameMode.assisted);
      expect(_segmentedModeControl(tester).selected, {GameMode.assisted});
      expect(navigatorObserver.pushedRoutes, isEmpty);
      expect(find.text('Continue Puzzle'), findsOneWidget);
      expect(find.text('New Puzzle'), findsOneWidget);
    },
  );

  testWidgets('continues the in-progress puzzle for the selected mode', (
    tester,
  ) async {
    _ignoreGamePageListTileMaterialWarning();
    final navigatorObserver = _RecordingNavigatorObserver();
    final container = ProviderContainer(
      overrides: [gameProvider.overrideWith(_ModeSpecificGameProvider.new)],
    );
    addTearDown(container.dispose);
    await _pumpGameSetup(
      tester,
      container,
      navigatorObserver: navigatorObserver,
    );
    await tester.pump();
    navigatorObserver.pushedRoutes.clear();

    await tester.tap(_outlinedButton('Continue Puzzle'));
    await tester.pump();

    expect(navigatorObserver.pushedRoutes, hasLength(1));
    final route = navigatorObserver.pushedRoutes.single;
    expect(route, isA<MaterialPageRoute<void>>());
    final gamePage =
        (route as MaterialPageRoute<void>).builder(
              tester.element(find.byType(GamePageSetup)),
            )
            as GamePage;
    expect(gamePage.gameId, _gameId);
    expect(gamePage.gameMode, GameMode.assisted);
    expect(gamePage.language, Language.english);
  });

  testWidgets('starts a new puzzle with the selected game configuration', (
    tester,
  ) async {
    _ignoreGamePageListTileMaterialWarning();
    final navigatorObserver = _RecordingNavigatorObserver();
    final container = ProviderContainer(
      overrides: [gameProvider.overrideWith(_SuccessfulGameProvider.new)],
    );
    addTearDown(container.dispose);
    await _pumpGameSetup(
      tester,
      container,
      navigatorObserver: navigatorObserver,
    );
    await tester.pump();
    navigatorObserver.pushedRoutes.clear();

    await tester.tap(_outlinedButton('New Puzzle'));
    await tester.pump();

    expect(navigatorObserver.pushedRoutes, hasLength(1));
    final route = navigatorObserver.pushedRoutes.single;
    expect(route, isA<MaterialPageRoute<void>>());
    final gamePage =
        (route as MaterialPageRoute<void>).builder(
              tester.element(find.byType(GamePageSetup)),
            )
            as GamePage;
    expect(gamePage.gameId, _gameId);
    expect(gamePage.gameMode, GameMode.assisted);
    expect(gamePage.language, Language.english);
  });

  testWidgets(
    'shows an exhausted-quote message when a new puzzle is unavailable',
    (tester) async {
      final container = ProviderContainer(
        overrides: [gameProvider.overrideWith(_ExhaustedGameProvider.new)],
      );
      addTearDown(container.dispose);
      await _pumpGameSetup(tester, container);
      await tester.pump();

      await tester.tap(_outlinedButton('New Puzzle'));
      await tester.pump();

      expect(find.byType(SnackBar), findsOneWidget);
      expect(
        find.textContaining('No unseen quotes remain for this language.'),
        findsOneWidget,
      );
      expect(find.byType(GamePage), findsNothing);
    },
  );

  testWidgets('opens the mode-specific statistics and instructions', (
    tester,
  ) async {
    final container = ProviderContainer(
      overrides: [gameProvider.overrideWith(_ModeSpecificGameProvider.new)],
    );
    addTearDown(container.dispose);
    await _pumpGameSetup(tester, container);
    await tester.pump();

    await tester.tap(_outlinedButton('Stats'));
    await tester.pumpAndSettle();
    expect(find.byType(StatsPage), findsOneWidget);
    expect(find.text('Solve Statistics - $_assistedKey'), findsOneWidget);

    await tester.pageBack();
    await tester.pumpAndSettle();
    await tester.tap(_outlinedButton('How to Play'));
    await tester.pumpAndSettle();
    expect(find.byType(AristocratInstructionsPage), findsOneWidget);
  });
}
