import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:scioly_codebusters/library.dart';

// List of all quotes
final quoteListProvider =
    StateNotifierProvider<QuoteListNotifier, List<SolvedQuote>>((ref) {
      return QuoteListNotifier();
    });

class QuoteListNotifier extends StateNotifier<List<SolvedQuote>> {
  QuoteListNotifier() : super(_loadHistory());

  static List<SolvedQuote> _loadHistory() {
    final database = appDatabase;
    if (database == null) {
      throw StateError('Quote database is not initialized.');
    }
    return database.completedQuotes();
  }

  void addQuote(SolvedQuote quote) {
    final database = appDatabase;
    if (database == null) {
      throw StateError('Quote database is not initialized.');
    }
    state = [...state, database.addCompletion(quote)];
  }

  Future<void> toggleFavorite(int index) async {
    final quote = state[index];
    final completionId = quote.completionId;
    final database = appDatabase;
    if (database == null || completionId == null) {
      throw StateError('Completed quote is not stored.');
    }
    database.setFavorite(completionId, !quote.isFavorite);
    quote.isFavorite = !quote.isFavorite;
    state = [...state];
  }

  Future<void> toggleFavoriteMostRecent() async {
    await toggleFavorite(state.length - 1);
  }

  bool isRecentFavorited() {
    return state[state.length - 1].isFavorite;
  }
}

// Favorites are derived from the main list
final favoriteQuotesProvider = Provider<List<SolvedQuote>>((ref) {
  final allQuotes = ref.watch(quoteListProvider);
  return allQuotes.where((q) => q.isFavorite).toList();
});
