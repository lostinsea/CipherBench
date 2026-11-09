import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:scioly_codebusters/library.dart';

import 'database_test_utils.dart';

const _mode = 'Aristocrat';

SolvedQuote _solved({
  required DateTime date,
  required int rating,
  required double solveTime,
  required String gameMode,
}) => SolvedQuote(
  quoteId: 42,
  text: 'Stats fixture',
  author: 'Test',
  rating: rating,
  solveTime: solveTime,
  gameMode: gameMode,
  date: date,
);

DateTime _startOfWeek(DateTime date) {
  return DateTime(
    date.year,
    date.month,
    date.day - (date.weekday - DateTime.monday),
  );
}

DateTime _localWeekMonday(DateTime monday, int weekOffset) {
  return DateTime(monday.year, monday.month, monday.day + 7 * weekOffset);
}

void main() {
  late File databaseFile;

  setUp(() {
    databaseFile = createSeedDatabaseCopy('stats-provider');
    installDatabase(AppDatabase.openFile(databaseFile.path));
  });

  tearDown(() {
    closeInstalledDatabase();
    if (databaseFile.existsSync()) databaseFile.deleteSync();
  });

  test('returns empty statistics when no qualifying completion exists', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    final stats = container.read(statsProvider(_mode));
    expect(stats.totalSolvedAll, 0);
    expect(stats.totalSolvedThisWeek, 0);
    expect(stats.totalSolvedLastWeek, 0);
    expect(stats.avgSolveTimeAll, 0);
    expect(stats.avgSolveTimeThisWeek, 0);
    expect(stats.avgSolveTimeLastWeek, 0);
    expect(stats.fastestSolveTimeAll, 0);
    expect(stats.fastestSolveTimeThisWeek, 0);
    expect(stats.fastestSolveTimeLastWeek, 0);
  });

  test(
    'reacts to persisted completions and filters exact mode and rating threshold',
    () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final notifier = container.read(quoteListProvider.notifier);
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day, 12);
      final thisMonday = _startOfWeek(now);
      final previousSunday = DateTime(
        thisMonday.year,
        thisMonday.month,
        thisMonday.day - 1,
      );

      expect(container.read(statsProvider(_mode)).totalSolvedAll, 0);
      notifier.addQuote(
        _solved(date: today, rating: 3, solveTime: 30, gameMode: _mode),
      );
      notifier.addQuote(
        _solved(date: today, rating: 2, solveTime: 10, gameMode: _mode),
      );
      notifier.addQuote(
        _solved(date: today, rating: 1, solveTime: 1, gameMode: _mode),
      );
      notifier.addQuote(
        _solved(date: today, rating: 3, solveTime: 2, gameMode: 'Patristocrat'),
      );
      notifier.addQuote(
        _solved(
          date: previousSunday,
          rating: 2,
          solveTime: 50,
          gameMode: _mode,
        ),
      );

      final stats = container.read(statsProvider(_mode));
      expect(stats.totalSolvedAll, 3);
      expect(stats.totalSolvedThisWeek, 2);
      expect(stats.totalSolvedLastWeek, 1);
      expect(stats.avgSolveTimeAll, 30);
      expect(stats.avgSolveTimeThisWeek, 20);
      expect(stats.avgSolveTimeLastWeek, 50);
      expect(stats.fastestSolveTimeAll, 10);
      expect(stats.fastestSolveTimeThisWeek, 10);
      expect(stats.fastestSolveTimeLastWeek, 50);
      expect(appDatabase!.completedQuotes(), hasLength(5));
    },
  );

  test('partitions local calendar-week boundary fixtures without overlap', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    final notifier = container.read(quoteListProvider.notifier);
    final thisMonday = _startOfWeek(DateTime.now());
    final lastMonday = _localWeekMonday(thisMonday, -1);
    final lastSundayEnd = thisMonday.subtract(const Duration(microseconds: 1));
    final nextMonday = _localWeekMonday(thisMonday, 1);

    notifier.addQuote(
      _solved(date: lastMonday, rating: 3, solveTime: 4, gameMode: _mode),
    );
    notifier.addQuote(
      _solved(date: lastSundayEnd, rating: 3, solveTime: 5, gameMode: _mode),
    );
    notifier.addQuote(
      _solved(date: thisMonday, rating: 3, solveTime: 6, gameMode: _mode),
    );
    notifier.addQuote(
      _solved(date: nextMonday, rating: 3, solveTime: 7, gameMode: _mode),
    );

    final stats = container.read(statsProvider(_mode));
    expect(
      (
        stats.totalSolvedAll,
        stats.totalSolvedThisWeek,
        stats.totalSolvedLastWeek,
      ),
      (4, 1, 2),
      reason:
          'Local calendar weeks must include both last-week boundaries and '
          'this Monday, while excluding next Monday from this week.',
    );
  });
}
