import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';
import 'package:sqlite3/sqlite3.dart';
import 'package:scioly_codebusters/Features/Quotes/Models/solved_quote.dart';
import 'package:scioly_codebusters/Features/Quotes/Util/app_database.dart';
import 'package:scioly_codebusters/Features/Quotes/Util/quote_library.dart';
import 'package:scioly_codebusters/Features/Settings/Models/settings_store.dart';
import 'package:scioly_codebusters/theme.dart';

import 'database_test_utils.dart';

class _TestPathProvider extends PathProviderPlatform {
  _TestPathProvider(this.documentsPath);

  final String documentsPath;

  @override
  Future<String?> getApplicationDocumentsPath() async => documentsPath;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test(
    'seed corpus has stable IDs, counts, flags, and canonical duplicates',
    () {
      final seed = sqlite3.open(seedDatabasePath, mode: OpenMode.readOnly);
      addTearDown(seed.close);

      expect(
        seed
            .select('''
        SELECT language, extended, MIN(id) AS first_id, MAX(id) AS last_id,
               COUNT(*) AS count, COUNT(DISTINCT canonical_id) AS canonical_count
        FROM quotes
        GROUP BY language, extended
        ORDER BY language, extended
        ''')
            .map(
              (row) => [
                row['language'],
                row['extended'],
                row['first_id'],
                row['last_id'],
                row['count'],
                row['canonical_count'],
              ],
            ),
        [
          ['english', 0, 1, 1007, 1007, 1007],
          ['english', 1, 1008, 3009, 2002, 2002],
          ['spanish', 0, 3010, 4016, 1007, 1006],
          ['spanish', 1, 4017, 4124, 108, 108],
        ],
      );
      expect(
        seed.select('SELECT COUNT(*) AS count FROM quotes').single['count'],
        4124,
      );
      expect(
        seed
            .select('''
        SELECT id, canonical_id FROM quotes
        WHERE language = 'spanish' AND canonical_id = 3305
        ORDER BY id
        ''')
            .map((row) => [row['id'], row['canonical_id']]),
        [
          [3305, 3305],
          [3964, 3305],
        ],
      );
    },
  );

  test('selects valid language collections and honors the extended toggle', () {
    final database = openSeedDatabase();
    addTearDown(database.close);

    for (final language in Language.values) {
      for (var selection = 0; selection < 20; selection++) {
        final original = database.randomQuote(
          language,
          skipCompletedQuotes: false,
          useExtendedQuoteCollection: false,
        );
        expect(
          original.id,
          language == Language.english
              ? inInclusiveRange(1, 1007)
              : inInclusiveRange(3010, 4016),
        );

        final fromFullCollection = database.randomQuote(
          language,
          skipCompletedQuotes: false,
          useExtendedQuoteCollection: true,
        );
        expect(
          fromFullCollection.id,
          language == Language.english
              ? inInclusiveRange(1, 3009)
              : inInclusiveRange(3010, 4124),
        );
      }
    }
  });

  test(
    'reports no eligible originals while retaining the extended collection',
    () {
      final file = createSeedDatabaseCopy('quote-selection-no-originals');
      addTearDown(() {
        if (file.existsSync()) file.deleteSync();
      });
      final seed = sqlite3.open(file.path);
      try {
        seed.execute('PRAGMA foreign_keys = ON');
        seed.execute(
          "DELETE FROM quotes WHERE language = 'english' AND extended = 0",
        );
      } finally {
        seed.close();
      }

      final database = AppDatabase.openFile(file.path);
      addTearDown(database.close);
      expect(
        () => database.randomQuote(
          Language.english,
          skipCompletedQuotes: false,
          useExtendedQuoteCollection: false,
        ),
        throwsA(isA<NoEligibleQuotesException>()),
      );
      expect(
        database
            .randomQuote(
              Language.english,
              skipCompletedQuotes: false,
              useExtendedQuoteCollection: true,
            )
            .id,
        inInclusiveRange(1008, 3009),
      );
    },
  );

  test('persists repeated completions and favorite changes independently', () {
    final database = openSeedDatabase();
    addTearDown(database.close);
    final selected = database.randomQuote(
      Language.english,
      skipCompletedQuotes: false,
      useExtendedQuoteCollection: false,
    );

    final first = database.addCompletion(
      SolvedQuote(
        quoteId: selected.id,
        text: selected.text,
        author: selected.author,
        rating: 1,
        solveTime: 12.5,
        gameMode: 'Aristocrat',
        date: DateTime(2026, 11, 8),
      ),
    );
    final second = database.addCompletion(
      SolvedQuote(
        quoteId: selected.id,
        text: selected.text,
        author: selected.author,
        rating: 3,
        solveTime: 3,
        gameMode: 'Patristocrat',
        date: DateTime(2026, 11, 9),
        isFavorite: true,
      ),
    );

    database.setFavorite(first.completionId!, true);
    database.setFavorite(second.completionId!, false);

    expect(
      database.completedQuotes().map(
        (quote) => (
          quote.completionId,
          quote.quoteId,
          quote.rating,
          quote.isFavorite,
          quote.gameMode,
        ),
      ),
      [
        (first.completionId, selected.id, 1, true, 'Aristocrat'),
        (second.completionId, selected.id, 3, false, 'Patristocrat'),
      ],
    );
  });

  test('settings defaults persist through an in-memory restart', () async {
    final database = openSeedDatabase();
    addTearDown(database.close);
    final store = SettingsStore(database);
    addTearDown(store.dispose);

    expect(store.prefs.isBgMusicOn, isTrue);
    expect(store.prefs.bgVolume, 1);
    expect(store.prefs.bgMatrixOn, isTrue);
    expect(store.prefs.skipCompletedQuotes, isTrue);
    expect(store.prefs.frequencyWordOrder, isTrue);
    expect(store.prefs.useExtendedQuoteCollection, isTrue);

    await store.save(
      store.prefs.copyWith(
        isBgMusicOn: false,
        bgVolume: 0.4,
        bgMatrixOn: false,
        skipCompletedQuotes: false,
        frequencyWordOrder: false,
        useExtendedQuoteCollection: false,
      ),
    );
    final restartedStore = SettingsStore(database);
    addTearDown(restartedStore.dispose);
    expect(restartedStore.prefs.isBgMusicOn, isFalse);
    expect(restartedStore.prefs.bgVolume, 0.4);
    expect(restartedStore.prefs.bgMatrixOn, isFalse);
    expect(restartedStore.prefs.skipCompletedQuotes, isFalse);
    expect(restartedStore.prefs.frequencyWordOrder, isFalse);
    expect(restartedStore.prefs.useExtendedQuoteCollection, isFalse);
  });

  test(
    'skips canonical duplicates and retains state after a file restart',
    () async {
      final file = createSeedDatabaseCopy('quote-selection-restart');
      addTearDown(() {
        if (file.existsSync()) file.deleteSync();
      });

      final setup = sqlite3.open(file.path);
      try {
        setup.execute('''
        INSERT INTO completed_quotes
          (quote_id, rating, solve_time, game_mode, is_favorite, completed_at)
        SELECT id, 3, 1.0, 'test', 0, 0
        FROM quotes
        WHERE language = 'spanish' AND extended = 0 AND canonical_id != 3305
        ''');
        setup.execute('''
        INSERT INTO completed_quotes
          (quote_id, rating, solve_time, game_mode, is_favorite, completed_at)
        VALUES (3305, 3, 1.0, 'test', 0, 0)
        ''');
      } finally {
        setup.close();
      }

      final database = AppDatabase.openFile(file.path);
      expect(
        () => database.randomQuote(
          Language.spanish,
          skipCompletedQuotes: true,
          useExtendedQuoteCollection: false,
        ),
        throwsA(isA<NoUnseenQuotesException>()),
      );
      database.saveSettings(
        database.readSettings().copyWith(skipCompletedQuotes: false),
      );
      database.close();

      final restarted = AppDatabase.openFile(file.path);
      addTearDown(restarted.close);
      expect(restarted.readSettings().skipCompletedQuotes, isFalse);
      expect(
        restarted
            .randomQuote(
              Language.spanish,
              skipCompletedQuotes: false,
              useExtendedQuoteCollection: false,
            )
            .id,
        inInclusiveRange(3010, 4016),
      );

      installDatabase(restarted);
      final quote = await getNewQuote(
        Language.english,
        skipCompletedQuotes: false,
        useExtendedQuoteCollection: false,
      );
      expect(quote.id, inInclusiveRange(1, 1007));
      settingsStore?.dispose();
      settingsStore = null;
      appDatabase = null;
    },
  );

  test(
    'provisions a seed in Documents once and preserves it on later launches',
    () async {
      final documents = Directory('test\\.app-database-documents').absolute;
      if (await documents.exists()) await documents.delete(recursive: true);
      await documents.create(recursive: true);
      final previousPlatform = PathProviderPlatform.instance;
      PathProviderPlatform.instance = _TestPathProvider(documents.path);
      addTearDown(() async {
        PathProviderPlatform.instance = previousPlatform;
        if (await documents.exists()) await documents.delete(recursive: true);
      });

      final first = await AppDatabase.open();
      final databaseFile = File(
        '${documents.path}${Platform.pathSeparator}CipherBench'
        '${Platform.pathSeparator}${AppDatabase.fileName}',
      );
      expect(await databaseFile.exists(), isTrue);
      expect(first.dictionaryWords(Language.english), hasLength(6462));
      expect(first.dictionaryWords(Language.spanish), hasLength(4971));
      expect(first.dictionary(Language.english).regularPlurals, isNotEmpty);

      final selected = first.randomQuote(
        Language.english,
        skipCompletedQuotes: false,
        useExtendedQuoteCollection: false,
      );
      final completion = first.addCompletion(
        SolvedQuote(
          quoteId: selected.id,
          text: selected.text,
          author: selected.author,
          rating: 2,
          solveTime: 9.5,
          gameMode: 'Aristocrat',
          date: DateTime(2026, 11, 8),
        ),
      );
      first.setFavorite(completion.completionId!, true);
      first.saveSettings(
        first.readSettings().copyWith(
          skipCompletedQuotes: false,
          useExtendedQuoteCollection: false,
        ),
      );
      first.close();

      final seeded = sqlite3.open(databaseFile.path, mode: OpenMode.readOnly);
      try {
        expect(seeded.userVersion, 3);
        expect(
          seeded.select('SELECT COUNT(*) AS count FROM quotes').single['count'],
          4124,
        );
        expect(
          seeded
              .select('SELECT COUNT(*) AS count FROM dictionary_entries')
              .single['count'],
          85605,
        );
      } finally {
        seeded.close();
      }

      final later = await AppDatabase.open();
      addTearDown(later.close);
      expect(later.readSettings().skipCompletedQuotes, isFalse);
      expect(later.readSettings().useExtendedQuoteCollection, isFalse);
      expect(
        later.completedQuotes().map(
          (quote) =>
              (quote.quoteId, quote.rating, quote.solveTime, quote.isFavorite),
        ),
        [(selected.id, 2, 9.5, true)],
      );
    },
  );
}
