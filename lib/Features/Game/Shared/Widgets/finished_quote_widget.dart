import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:scioly_codebusters/library.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

const _windowsPopupMargin = 38.0;
const _windowsPopupMaxWidth = 760.0;

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
    final isWindows =
        !kIsWeb && defaultTargetPlatform == TargetPlatform.windows;
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

    final actions = [
      StyledButtonWidget(
        value: "Play Again",
        fittedLabel: isWindows ? "Play Again" : null,
        bgColor: Colors.redAccent,
        onPressed: () async {
          await buttonClickSound();
          if (!context.mounted) return;
          Navigator.of(context).pop();
          provider.destroy();
        },
      ),
      StyledButtonWidget(
        value: "View completed quote",
        fittedLabel: isWindows ? "View completed\nquote" : null,
        bgColor: AppTheme.logoGreen,
        onPressed: () async {
          await buttonClickSound();
          if (!context.mounted) return;
          provider.setPopup(false);
        },
      ),
      StyledButtonWidget(
        value: isFavorited ? "Unfavorite Quote" : "Add to favorites",
        fittedLabel: isWindows
            ? (isFavorited ? "Unfavorite\nQuote" : "Add to\nfavorites")
            : null,
        bgColor: Colors.blueAccent,
        onPressed: () async {
          await buttonClickSound();
          await ref.read(quoteListProvider.notifier).toggleFavoriteMostRecent();
          setState(() {
            isFavorited = !isFavorited;
          });
        },
      ),
      StyledButtonWidget(
        value: "Home",
        fittedLabel: isWindows ? "Home" : null,
        bgColor: Colors.yellowAccent,
        onPressed: () async {
          await buttonClickSound();
          if (!context.mounted) return;
          Navigator.of(context).popUntil((route) => route.isFirst);
          provider.destroy();
        },
      ),
    ];

    return Container(
      color: Colors.black.withAlpha(100),
      child: LayoutBuilder(
        builder: (context, constraints) => Center(
          child: Container(
            width: isWindows
                ? (constraints.maxWidth - _windowsPopupMargin * 2).clamp(
                    0.0,
                    _windowsPopupMaxWidth,
                  )
                : (MediaQuery.sizeOf(context).width - 50).clamp(
                    0.0,
                    desktopContentWidth,
                  ),
            constraints: isWindows
                ? BoxConstraints(
                    maxHeight: constraints.maxHeight - _windowsPopupMargin * 2,
                  )
                : null,
            padding: EdgeInsets.symmetric(
              vertical: 20,
              horizontal: isWindows ? _windowsPopupMargin : 20,
            ),
            decoration: BoxDecoration(
              color: Colors.black,
              border: Border.all(color: AppTheme.logoGreen, width: 1),
              boxShadow: [BoxShadow(color: AppTheme.logoGreen, blurRadius: 5)],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (isWindows)
                  Flexible(
                    child: SingleChildScrollView(
                      child: QuoteDisplayWidget(
                        quote: widget.quote,
                        author: widget.author,
                      ),
                    ),
                  )
                else
                  QuoteDisplayWidget(
                    quote: widget.quote,
                    author: widget.author,
                  ),
                const SizedBox(height: 5),
                Row(
                  children: [
                    ...stars,
                    const Spacer(),
                    const Icon(Icons.timer_outlined, color: Colors.redAccent),
                    Text(
                      "${time.toString()}s",
                      style: const TextStyle(color: Colors.redAccent),
                    ),
                  ],
                ),
                const SizedBox(height: 15),
                Text(
                  messages[rating - 1],
                  style: const TextStyle(
                    fontSize: 18,
                    color: AppTheme.logoGreen,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 20),
                if (isWindows)
                  SizedBox(
                    height: 56,
                    child: Row(
                      children: [
                        for (
                          var index = 0;
                          index < actions.length;
                          index++
                        ) ...[
                          if (index > 0) const SizedBox(width: 8),
                          Expanded(child: actions[index]),
                        ],
                      ],
                    ),
                  )
                else
                  for (var index = 0; index < actions.length; index++) ...[
                    if (index > 0) const SizedBox(height: 20),
                    actions[index],
                  ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
