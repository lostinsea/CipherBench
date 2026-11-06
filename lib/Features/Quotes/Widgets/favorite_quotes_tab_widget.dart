import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:scioly_codebusters/library.dart';
import 'package:flutter/material.dart';

class FavoritesTab extends ConsumerWidget {
  const FavoritesTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final favorites = ref.watch(favoriteQuotesProvider);

    List<Color> colors = [
      AppTheme.logoGreen,
      Colors.redAccent,
      Colors.blueAccent,
      Colors.yellowAccent,
    ];

    return favorites.isEmpty
        ? const Center(
            child: Text(
              "No favorite quotes yet.",
              style: TextStyle(color: Colors.white),
            ),
          )
        : ListView.builder(
            itemCount: favorites.length,
            itemBuilder: (context, index) {
              final reverseIndex = favorites.length - 1 - index;
              final quote = favorites[reverseIndex];
              final quoteIndex = ref.read(quoteListProvider).indexOf(quote);
              return Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(
                    maxWidth: desktopContentWidth,
                  ),
                  child: QuoteCard(
                    quote: quote,
                    color: colors[index % colors.length],
                    onFavoriteToggle: () => ref
                        .read(quoteListProvider.notifier)
                        .toggleFavorite(quoteIndex),
                  ),
                ),
              );
            },
          );
  }
}
