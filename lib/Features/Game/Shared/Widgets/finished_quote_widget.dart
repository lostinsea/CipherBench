import 'package:flutter/material.dart';
import 'package:scioly_codebusters/library.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class FinishedQuoteWidget extends ConsumerStatefulWidget {
  final String quote;
  final String author;
  final String gameKey;
  const FinishedQuoteWidget({
    super.key,
    required this.quote,
    required this.author,
    required this.gameKey,
  });

  @override
  ConsumerState<FinishedQuoteWidget> createState() =>
      _FinishedQuoteWidgetState();
}

class _FinishedQuoteWidgetState extends ConsumerState<FinishedQuoteWidget>
    with SingleTickerProviderStateMixin {
  late final AnimationController _animationController;
  bool isFavorited = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = ref.read(gameProvider(widget.gameKey).notifier);

    final time = ref.read(timerProvider(widget.gameKey).notifier).getTime();
    int rating = ref.watch(
      gameProvider(widget.gameKey).select((s) => s.rating),
    );
    List<Icon> stars = [];
    for (int i = 0; i < rating; i++) {
      stars.add(Icon(Icons.star, color: Colors.yellow));
    }
    for (int i = 0; i < (3 - rating); i++) {
      stars.add(Icon(Icons.star_border, color: Colors.yellow));
    }

    List<String> messages = ["Good job!", "Congratulations!", "Perfect!"];
    isFavorited = ref.read(quoteListProvider.notifier).isRecentFavorited();

    return Container(
      color: Colors.black.withAlpha(100),
      child: Center(
        child: Container(
          width: (MediaQuery.sizeOf(context).width - 50).clamp(
            0.0,
            desktopContentWidth,
          ),
          padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 20),
          decoration: BoxDecoration(
            color: Colors.black,
            border: Border.all(color: AppTheme.logoGreen, width: 1),
            boxShadow: [BoxShadow(color: AppTheme.logoGreen, blurRadius: 5)],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              QuoteDisplayWidget(quote: widget.quote, author: widget.author),
              SizedBox(height: 5),
              Row(
                children: [
                  ...stars,
                  Spacer(),
                  Icon(Icons.timer_outlined, color: Colors.redAccent),
                  Text(
                    "${time.toString()}s",
                    style: TextStyle(color: Colors.redAccent),
                  ),
                ],
              ),
              SizedBox(height: 15),
              Text(
                messages[rating - 1],
                style: TextStyle(fontSize: 18, color: AppTheme.logoGreen),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              StyledButtonWidget(
                value: "Play Again",
                bgColor: Colors.redAccent,
                onPressed: () async {
                  await buttonClickSound();
                  // Make sure context is still valid with mounted
                  if (!context.mounted) return;
                  Navigator.of(context).pop();
                  provider.destroy();
                },
              ),
              const SizedBox(height: 20),
              StyledButtonWidget(
                value: "View Quote",
                bgColor: AppTheme.logoGreen,
                onPressed: () async {
                  await buttonClickSound();
                  // Make sure context is still valid with mounted
                  if (!context.mounted) return;
                  provider.setPopup(false);
                },
              ),
              const SizedBox(height: 20),
              StyledButtonWidget(
                value: isFavorited == true
                    ? "Unfavorite Quote"
                    : "Favorite Quote",
                bgColor: Colors.blueAccent,
                onPressed: () async {
                  await buttonClickSound();
                  await ref
                      .read(quoteListProvider.notifier)
                      .toggleFavoriteMostRecent();
                  setState(() {
                    isFavorited = !isFavorited;
                  });
                },
              ),
              const SizedBox(height: 20),
              StyledButtonWidget(
                value: "Home",
                bgColor: Colors.yellowAccent,
                onPressed: () async {
                  await buttonClickSound();
                  // Make sure context is still valid with mounted
                  if (!context.mounted) return;
                  Navigator.of(context).popUntil((route) => route.isFirst);
                  provider.destroy();
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
