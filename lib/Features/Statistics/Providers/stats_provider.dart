import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:scioly_codebusters/library.dart';

final statsProvider = Provider.family<QuoteStats, String>((ref, gameModeKey) {
  final allQuotes = ref.watch(quoteListProvider);
  final quotes = allQuotes
      .where((q) => q.rating >= 2 && q.gameMode == gameModeKey)
      .toList();

  final now = DateTime.now();
  final startOfThisWeek = DateTime(
    now.year,
    now.month,
    now.day - (now.weekday - DateTime.monday),
  );
  final startOfLastWeek = DateTime(
    startOfThisWeek.year,
    startOfThisWeek.month,
    startOfThisWeek.day - 7,
  );
  final startOfNextWeek = DateTime(
    startOfThisWeek.year,
    startOfThisWeek.month,
    startOfThisWeek.day + 7,
  );
  bool inWeek(DateTime date, DateTime start, DateTime end) =>
      !date.isBefore(start) && date.isBefore(end);

  List<SolvedQuote> thisWeek = quotes
      .where((q) => inWeek(q.date, startOfThisWeek, startOfNextWeek))
      .toList();

  List<SolvedQuote> lastWeek = quotes
      .where((q) => inWeek(q.date, startOfLastWeek, startOfThisWeek))
      .toList();

  double avg(List<SolvedQuote> qs) => qs.isEmpty
      ? 0
      : qs.map((q) => q.solveTime).reduce((a, b) => a + b) / qs.length;

  double fastest(List<SolvedQuote> qs) => qs.isEmpty
      ? 0
      : qs.map((q) => q.solveTime).reduce((a, b) => a < b ? a : b);

  return QuoteStats(
    avgSolveTimeAll: avg(quotes),
    avgSolveTimeThisWeek: avg(thisWeek),
    avgSolveTimeLastWeek: avg(lastWeek),
    fastestSolveTimeAll: fastest(quotes),
    fastestSolveTimeThisWeek: fastest(thisWeek),
    fastestSolveTimeLastWeek: fastest(lastWeek),
    totalSolvedAll: quotes.length,
    totalSolvedThisWeek: thisWeek.length,
    totalSolvedLastWeek: lastWeek.length,
  );
});
