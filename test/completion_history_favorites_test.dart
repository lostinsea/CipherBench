import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:scioly_codebusters/library.dart';
import 'package:sqlite3/sqlite3.dart';

import 'database_test_utils.dart';

const _gameMode = 'Aristocrat';

late QuoteRecord _completionQuote;

class _CompletedPuzzleProvider extends GameProvider {
  @override
  Game build(String gameKey) => Game(
    quote: Quote(
      id: _completionQuote.id,
      ogQuote: _completionQuote.text,
      author: _completionQuote.author,
    ),
    cells: [
      Cell(
        text: '',
        cipher: 'B',
        plainText: 'A',
        isException: false,
        isLit: true,
      ),
      Cell(text: '', cipher: 'C', plainText: 'B', isException: false),
    ],
  );
}

class _FixedCompletionTimer extends TimerNotifier {
  @override
  double getTime() => 12.34;
}

File _newDatabaseFile(String name) {
  final file = createSeedDatabaseCopy(name);
  addTearDown(() {
    if (file.existsSync()) file.deleteSync();
  });
  return file;
}

QuoteRecord _seedQuote(int id) {
  final seed = sqlite3.open(seedDatabasePath, mode: OpenMode.readOnly);
  try {
    final row = seed.select(
      'SELECT id, text, author FROM quotes WHERE id = ?',
      [id],
    ).single;
    return QuoteRecord(
      row['id'] as int,
      row['text'] as String,
      row['author'] as String,
    );
  } finally {
    seed.close();
  }
}

SolvedQuote _completion({
  required int quoteId,
  required DateTime date,
  required int rating,
  required double solveTime,
  bool isFavorite = false,
}) => SolvedQuote(
  quoteId: quoteId,
  text: 'Ignored when history is reloaded',
  author: 'Ignored when history is reloaded',
  rating: rating,
  solveTime: solveTime,
  gameMode: _gameMode,
  date: date,
  isFavorite: isFavorite,
);

void main() {
  test(
    'rejects invalid quote foreign keys without creating a phantom completion',
    () {
      final database = AppDatabase.openFile(
        _newDatabaseFile('completion-invalid-foreign-key').path,
      );
      addTearDown(database.close);

      expect(
        () => database.addCompletion(
          _completion(
            quoteId: 999999,
            date: DateTime(2026, 11, 8),
            rating: 3,
            solveTime: 4.5,
          ),
        ),
        throwsA(isA<SqliteException>()),
      );
      expect(database.completedQuotes(), isEmpty);
    },
  );

  test(
    'stores stable quote and distinct completion IDs with joined history metadata after reopen',
    () {
      final file = _newDatabaseFile('completion-history-restart');
      final database = AppDatabase.openFile(file.path);
      const quoteId = 42;
      final sourceQuote = _seedQuote(quoteId);
      final saved = database.addCompletion(
        _completion(
          quoteId: quoteId,
          date: DateTime(2026, 11, 3, 9, 45),
          rating: 3,
          solveTime: 18.75,
          isFavorite: true,
        ),
      );
      expect(saved.completionId, isNotNull);
      expect(saved.completionId, isNot(quoteId));
      database.close();

      final reopened = AppDatabase.openFile(file.path);
      addTearDown(reopened.close);
      final history = reopened.completedQuotes();
      expect(history, hasLength(1));
      final completion = history.single;
      expect(completion.completionId, saved.completionId);
      expect(completion.quoteId, quoteId);
      expect(completion.text, sourceQuote.text);
      expect(completion.author, sourceQuote.author);
      expect(completion.date, DateTime(2026, 11, 3, 9, 45));
      expect(completion.gameMode, _gameMode);
      expect(completion.rating, 3);
      expect(completion.solveTime, 18.75);
      expect(completion.isFavorite, isTrue);
    },
  );

  test(
    'completion and favorite providers react per completion and persist after reopen',
    () async {
      final file = _newDatabaseFile('completion-favorite-provider-restart');
      final database = AppDatabase.openFile(file.path);
      installDatabase(database);
      addTearDown(() {
        if (appDatabase != null) closeInstalledDatabase();
      });

      final container = ProviderContainer();
      addTearDown(container.dispose);
      final favoriteLengths = <int>[];
      final subscription = container.listen<List<SolvedQuote>>(
        favoriteQuotesProvider,
        (_, favorites) => favoriteLengths.add(favorites.length),
        fireImmediately: true,
      );
      addTearDown(subscription.close);

      final history = container.read(quoteListProvider.notifier);
      history.addQuote(
        _completion(
          quoteId: 42,
          date: DateTime(2026, 11, 2),
          rating: 2,
          solveTime: 8,
          isFavorite: true,
        ),
      );
      history.addQuote(
        _completion(
          quoteId: 42,
          date: DateTime(2026, 11, 3),
          rating: 3,
          solveTime: 6,
        ),
      );
      expect(container.read(quoteListProvider), hasLength(2));
      expect(container.read(favoriteQuotesProvider), hasLength(1));

      await history.toggleFavorite(1);
      expect(container.read(favoriteQuotesProvider), hasLength(2));
      await history.toggleFavorite(0);
      expect(
        container.read(favoriteQuotesProvider).single.completionId,
        container.read(quoteListProvider)[1].completionId,
      );
      expect(favoriteLengths, [0, 1, 2, 1]);

      final completionIds = container
          .read(quoteListProvider)
          .map((quote) => quote.completionId)
          .toSet();
      expect(completionIds, hasLength(2));
      container.dispose();
      closeInstalledDatabase();

      final reopened = AppDatabase.openFile(file.path);
      addTearDown(reopened.close);
      expect(
        reopened.completedQuotes().map(
          (quote) => (quote.quoteId, quote.isFavorite, quote.rating),
        ),
        [(42, false, 2), (42, true, 3)],
      );
    },
  );

  testWidgets(
    'finished popup and history cards toggle the saved completion favorite',
    (tester) async {
      final file = _newDatabaseFile('completion-favorite-widget-restart');
      final database = AppDatabase.openFile(file.path);
      _completionQuote = _seedQuote(42);
      installDatabase(database);
      addTearDown(() {
        if (appDatabase != null) closeInstalledDatabase();
      });

      final container = ProviderContainer(
        overrides: [
          gameProvider.overrideWith(_CompletedPuzzleProvider.new),
          timerProvider.overrideWith(_FixedCompletionTimer.new),
        ],
      );
      addTearDown(container.dispose);

      final puzzle = container.read(gameProvider(_gameMode).notifier);
      puzzle.setLetter('A', false);
      expect(container.read(quoteListProvider), isEmpty);
      puzzle.setLetter('B', false);
      final completion = container.read(quoteListProvider).single;
      final completedGame = container.read(gameProvider(_gameMode));
      expect(completedGame.isCorrect, isTrue);
      expect(completedGame.showComplete, isTrue);
      expect(completion.quoteId, _completionQuote.id);
      expect(completion.completionId, isNot(_completionQuote.id));
      expect(completion.rating, 3);
      expect(completion.solveTime, 12.34);
      expect(completion.isFavorite, isFalse);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            theme: AppTheme.theme,
            home: Scaffold(
              body: FinishedQuoteWidget(
                quote: _completionQuote.text,
                author: _completionQuote.author,
                gameKey: _gameMode,
              ),
            ),
          ),
        ),
      );
      await tester.pump();

      await tester.tap(
        find.byWidgetPredicate(
          (widget) =>
              widget is StyledButtonWidget &&
              widget.value == 'Add to favorites',
        ),
      );
      await tester.pump();
      expect(container.read(favoriteQuotesProvider), hasLength(1));
      expect(
        find.byWidgetPredicate(
          (widget) =>
              widget is StyledButtonWidget &&
              widget.value == 'Unfavorite Quote',
        ),
        findsOneWidget,
      );

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            theme: AppTheme.theme,
            home: const QuoteHomePage(),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text(_completionQuote.text), findsOneWidget);
      expect(find.text('- ${_completionQuote.author}'), findsOneWidget);
      expect(find.text(_gameMode), findsOneWidget);
      expect(find.text('12.34'), findsOneWidget);
      expect(
        find.descendant(
          of: find.byType(QuoteCard),
          matching: find.byIcon(Icons.star),
        ),
        findsNWidgets(3),
      );

      Finder cardFavoriteButton() => find.descendant(
        of: find.byType(QuoteCard),
        matching: find.byType(IconButton),
      );

      await tester.tap(cardFavoriteButton());
      await tester.pump();
      expect(container.read(favoriteQuotesProvider), isEmpty);
      await tester.tap(find.text('Favorites'));
      await tester.pumpAndSettle();
      expect(find.text('No favorite quotes yet.'), findsOneWidget);

      await tester.tap(find.text('All Quotes'));
      await tester.pumpAndSettle();
      await tester.tap(cardFavoriteButton());
      await tester.pump();
      await tester.tap(find.text('Favorites'));
      await tester.pumpAndSettle();
      expect(find.byType(QuoteCard), findsOneWidget);
      await tester.tap(cardFavoriteButton());
      await tester.pump();
      expect(container.read(favoriteQuotesProvider), isEmpty);

      final completionId = completion.completionId;
      container.dispose();
      closeInstalledDatabase();
      final reopened = AppDatabase.openFile(file.path);
      addTearDown(reopened.close);
      expect(reopened.completedQuotes().single.completionId, completionId);
      expect(reopened.completedQuotes().single.isFavorite, isFalse);
    },
  );
}
