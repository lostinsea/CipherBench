import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:scioly_codebusters/library.dart';

class GamePageLayout extends ConsumerWidget {
  final GamePageConfig config;
  final bool addKeyboard;

  const GamePageLayout({
    super.key,
    required this.config,
    this.addKeyboard = true,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final gameId = config.gameId;
    final gameMode = config.gameMode;
    final language = config.language;

    final key = "$gameId (${toTitleCase(gameMode.name)})";
    final provider = ref.read(gameProvider(key).notifier);
    final scrollController = ref.watch(scrollProvider(key));
    final quote = ref.watch(gameProvider(key).select((s) => s.quote.ogQuote));
    final author = ref.watch(gameProvider(key).select((s) => s.quote.author));
    final bool isCorrect = ref.watch(
      gameProvider(key).select((s) => s.isCorrect),
    );
    final showComplete = ref.watch(
      gameProvider(key).select((s) => s.showComplete),
    );
    final showSuggestions = ref.watch(
      gameProvider(key).select((s) => s.showSuggestions),
    );

    final bottomInset = addKeyboard ? keyboardH : desktopCommandsHeight;
    final game = Container(
      constraints: BoxConstraints.tightForFinite(height: screenH),
      decoration: AppTheme.backgroundGradient,
      child: Scaffold(
        backgroundColor: AppTheme.appBarBackground,
        appBar: AppBar(
          backgroundColor: AppTheme.appBarBackground,
          title: Text(
            gameId,
            style: TextStyle(
              shadows: [Shadow(color: AppTheme.logoGreen, blurRadius: 5)],
            ),
          ),
          actions: [
            if (isCorrect && !showComplete)
              StyledButtonWidget(
                valueIcon: Icon(Icons.start, color: AppTheme.logoGreen),
                onPressed: () => provider.setPopup(true),
                marginVertical: 5,
                paddingHorizontal: 10,
              ),
          ],
        ),
        body: Stack(
          fit: StackFit.expand,
          children: [
            Stack(
              children: [
                SingleChildScrollView(
                  controller: scrollController,
                  padding: EdgeInsets.fromLTRB(
                    insetPadding,
                    insetPadding + panelHeight,
                    insetPadding,
                    insetPadding + bottomInset + (containerHeight * 2),
                  ),
                  child: Column(children: [CryptogramGridWidget(gameKey: key)]),
                ),
                if (showSuggestions)
                  AnimatedBuilder(
                    animation: scrollController,
                    builder: (context, child) {
                      return DictionaryPopoverWidget(
                        gameId: gameId,
                        gameMode: gameMode,
                        dictionaryId: language.name,
                        bottomInset: bottomInset,
                      );
                    },
                  ),
                Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  child: GamePageHeaderWidget(gameKey: key),
                ),
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 0,
                  child: addKeyboard
                      ? KeyboardWidget(gameKey: key, language: language)
                      : AvailableCommandsWidget(
                          commands: KeyboardShortcutsWidget.commands(language),
                        ),
                ),
              ],
            ),
            if (showComplete)
              FinishedQuoteWidget(quote: quote, author: author, gameKey: key),
          ],
        ),
      ),
    );
    return addKeyboard
        ? game
        : KeyboardShortcutsWidget(
            gameKey: key,
            language: language,
            child: game,
          );
  }
}
