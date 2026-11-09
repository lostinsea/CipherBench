import 'dart:io';

import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqlite3/sqlite3.dart';
import 'package:scioly_codebusters/Features/Quotes/Models/solved_quote.dart';
import 'package:scioly_codebusters/Features/Quotes/Util/quote_types.dart';
import 'package:scioly_codebusters/Features/Settings/Models/setting_prefs.dart';

class QuoteRecord {
  const QuoteRecord(this.id, this.text, this.author);

  final int id;
  final String text;
  final String author;
}

class DictionaryData {
  const DictionaryData({
    required this.baseWords,
    required this.headwords,
    required this.irregularPlurals,
    required this.regularPlurals,
    required this.verbForms,
    required this.descriptiveForms,
  });

  final List<String> baseWords;
  final List<String> headwords;
  final List<String> irregularPlurals;
  final List<String> regularPlurals;
  final List<String> verbForms;
  final List<String> descriptiveForms;
}

class AppDatabase {
  AppDatabase._(this._db) {
    _db.execute('PRAGMA foreign_keys = ON');
    if (_db.userVersion != 3) {
      throw StateError(
        'Unsupported CipherBench database version: ${_db.userVersion}',
      );
    }
    if (_db.select('SELECT id FROM settings WHERE id = 1').isEmpty) {
      throw StateError('CipherBench database has no settings record.');
    }
  }

  static const seedAsset = 'assets/quotes/cipherbench.sqlite3';
  static const fileName = 'cipherbench.sqlite3';

  final Database _db;
  final Map<Language, DictionaryData> _dictionaries = {};
  final Map<Language, List<String>> _baseWords = {};
  Map<String, int>? _frequencyScores;

  DictionaryData dictionary(
    Language language,
  ) => _dictionaries.putIfAbsent(language, () {
    final words = List.generate(6, (_) => <String>[]);
    for (final row in _db.select(
      'SELECT type, word FROM dictionary_entries WHERE language = ? ORDER BY sort_order',
      [language.name],
    )) {
      words[row['type'] as int].add(row['word'] as String);
    }
    return DictionaryData(
      baseWords: _baseWords.putIfAbsent(
        language,
        () => List.unmodifiable(words[0]),
      ),
      headwords: List.unmodifiable(words[1]),
      irregularPlurals: List.unmodifiable(words[2]),
      regularPlurals: List.unmodifiable(words[3]),
      verbForms: List.unmodifiable(words[4]),
      descriptiveForms: List.unmodifiable(words[5]),
    );
  });

  List<String> dictionaryWords(Language language) => _baseWords.putIfAbsent(
    language,
    () => List.unmodifiable(
      _db
          .select(
            'SELECT word FROM dictionary_entries WHERE language = ? AND type = 0 ORDER BY sort_order',
            [language.name],
          )
          .map((row) => row['word'] as String),
    ),
  );

  Map<String, int> get englishFrequencyScores =>
      _frequencyScores ??= Map.unmodifiable({
        for (final row in _db.select(
          'SELECT word, score FROM english_frequency_scores',
        ))
          row['word'] as String: row['score'] as int,
      });

  static Future<AppDatabase> open() async {
    final documents = await getApplicationDocumentsDirectory();
    final directory = Directory(
      '${documents.path}${Platform.pathSeparator}CipherBench',
    );
    await directory.create(recursive: true);
    final target = File('${directory.path}${Platform.pathSeparator}$fileName');
    if (!await target.exists()) {
      final bytes = await rootBundle.load(seedAsset);
      final temporary = File(
        '${target.path}.$pid.${DateTime.now().microsecondsSinceEpoch}.tmp',
      );
      try {
        await temporary.writeAsBytes(Uint8List.sublistView(bytes), flush: true);
        if (!await target.exists()) {
          await temporary.rename(target.path);
        }
      } finally {
        if (await temporary.exists()) await temporary.delete();
      }
    }
    return openFile(target.path);
  }

  static AppDatabase openFile(String path) {
    final database = sqlite3.open(path);
    try {
      return AppDatabase._(database);
    } catch (_) {
      database.close();
      rethrow;
    }
  }

  static AppDatabase copySeedIntoMemory(String seedPath) {
    final source = sqlite3.open(seedPath, mode: OpenMode.readOnly);
    try {
      final copy = sqlite3.copyIntoMemory(source);
      try {
        return AppDatabase._(copy);
      } catch (_) {
        copy.close();
        rethrow;
      }
    } finally {
      source.close();
    }
  }

  QuoteRecord randomQuote(
    Language language, {
    required bool useExtendedQuoteCollection,
    required bool skipCompletedQuotes,
  }) {
    final languageName = language.name;
    final extended = useExtendedQuoteCollection ? 1 : 0;
    final eligible = _db.select(
      'SELECT 1 FROM quotes WHERE language = ? AND (? = 1 OR extended = 0) LIMIT 1',
      [languageName, extended],
    );
    if (eligible.isEmpty) throw const NoEligibleQuotesException();

    final rows = _db.select(
      '''
      SELECT q.id, q.text, q.author
      FROM quotes AS q
      WHERE q.language = ?
        AND (? = 1 OR q.extended = 0)
        AND (? = 0 OR NOT EXISTS (
          SELECT 1
          FROM completed_quotes AS completed
          JOIN quotes AS solved ON solved.id = completed.quote_id
          WHERE solved.canonical_id = q.canonical_id
        ))
      ORDER BY RANDOM()
      LIMIT 1
      ''',
      [languageName, extended, skipCompletedQuotes ? 1 : 0],
    );
    if (rows.isEmpty) throw const NoUnseenQuotesException();
    final row = rows.single;
    return QuoteRecord(
      row['id'] as int,
      row['text'] as String,
      row['author'] as String,
    );
  }

  List<SolvedQuote> completedQuotes() => [
    for (final row in _db.select('''
      SELECT completed.id, completed.quote_id, q.text, q.author,
             completed.rating, completed.solve_time, completed.game_mode,
             completed.is_favorite, completed.completed_at
      FROM completed_quotes AS completed
      JOIN quotes AS q ON q.id = completed.quote_id
      ORDER BY completed.id
    '''))
      SolvedQuote(
        completionId: row['id'] as int,
        quoteId: row['quote_id'] as int,
        text: row['text'] as String,
        author: row['author'] as String,
        rating: row['rating'] as int,
        solveTime: row['solve_time'] as double,
        gameMode: row['game_mode'] as String,
        isFavorite: (row['is_favorite'] as int) == 1,
        date: DateTime.fromMillisecondsSinceEpoch(row['completed_at'] as int),
      ),
  ];

  SolvedQuote addCompletion(SolvedQuote quote) {
    _db.execute(
      '''
      INSERT INTO completed_quotes
        (quote_id, rating, solve_time, game_mode, is_favorite, completed_at)
      VALUES (?, ?, ?, ?, ?, ?)
      ''',
      [
        quote.quoteId,
        quote.rating,
        quote.solveTime,
        quote.gameMode,
        quote.isFavorite ? 1 : 0,
        quote.date.millisecondsSinceEpoch,
      ],
    );
    return SolvedQuote(
      completionId: _db.lastInsertRowId,
      quoteId: quote.quoteId,
      text: quote.text,
      author: quote.author,
      rating: quote.rating,
      solveTime: quote.solveTime,
      gameMode: quote.gameMode,
      isFavorite: quote.isFavorite,
      date: quote.date,
    );
  }

  void setFavorite(int completionId, bool favorite) {
    _db.execute('UPDATE completed_quotes SET is_favorite = ? WHERE id = ?', [
      favorite ? 1 : 0,
      completionId,
    ]);
    if (_db.updatedRows != 1) {
      throw StateError('Completed quote $completionId no longer exists.');
    }
  }

  SettingPrefs readSettings() {
    final rows = _db.select('SELECT * FROM settings WHERE id = 1');
    if (rows.isEmpty) throw StateError('CipherBench settings are missing.');
    final row = rows.single;
    return SettingPrefs(
      isBgMusicOn: (row['is_bg_music_on'] as int) == 1,
      bgVolume: row['bg_volume'] as double,
      bgMatrixOn: (row['bg_matrix_on'] as int) == 1,
      skipCompletedQuotes: (row['skip_completed_quotes'] as int) == 1,
      frequencyWordOrder: (row['frequency_word_order'] as int) == 1,
      useExtendedQuoteCollection:
          (row['use_extended_quote_collection'] as int) == 1,
    );
  }

  void saveSettings(SettingPrefs prefs) {
    _db.execute(
      '''
      UPDATE settings
      SET is_bg_music_on = ?, bg_volume = ?, bg_matrix_on = ?,
          skip_completed_quotes = ?, frequency_word_order = ?,
          use_extended_quote_collection = ?
      WHERE id = 1
      ''',
      [
        prefs.isBgMusicOn ? 1 : 0,
        prefs.bgVolume,
        prefs.bgMatrixOn ? 1 : 0,
        prefs.skipCompletedQuotes ? 1 : 0,
        prefs.frequencyWordOrder ? 1 : 0,
        prefs.useExtendedQuoteCollection ? 1 : 0,
      ],
    );
    if (_db.updatedRows != 1) {
      throw StateError('CipherBench settings could not be saved.');
    }
  }

  void close() => _db.close();
}
