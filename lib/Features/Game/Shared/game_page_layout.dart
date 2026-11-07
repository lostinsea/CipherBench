import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:scioly_codebusters/library.dart';

class GamePageLayout extends ConsumerStatefulWidget {
  final GamePageConfig config;
  final bool addKeyboard;

  const GamePageLayout({
    super.key,
    required this.config,
    this.addKeyboard = true,
  });

  @override
  ConsumerState<GamePageLayout> createState() => _GamePageLayoutState();
}

class _GamePageLayoutState extends ConsumerState<GamePageLayout> {
  int _zoomPercent = 100;

  @override
  Widget build(BuildContext context) {
    final isWindows =
        !kIsWeb && defaultTargetPlatform == TargetPlatform.windows;
    final gameId = widget.config.gameId;
    final gameMode = widget.config.gameMode;
    final language = widget.config.language;

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

    final bottomInset = widget.addKeyboard ? keyboardH : desktopCommandsHeight;
    final suggestionInset = showSuggestions ? containerHeight * 2 : 0.0;
    final game = Container(
      decoration: AppTheme.backgroundGradient,
      child: Scaffold(
        backgroundColor: AppTheme.appBarBackground,
        appBar: AppBar(
          backgroundColor: AppTheme.appBarBackground,
          title: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: desktopContentWidth),
              child: Row(
                children: [
                  Text(
                    gameId,
                    style: const TextStyle(
                      shadows: [
                        Shadow(color: AppTheme.logoGreen, blurRadius: 5),
                      ],
                    ),
                  ),
                  const Spacer(),
                  if (isWindows) ...[
                    IconButton(
                      tooltip: 'Zoom out',
                      icon: const Icon(Icons.zoom_out),
                      onPressed: _zoomPercent > 75
                          ? () => setState(() => _zoomPercent -= 5)
                          : null,
                    ),
                    Text('$_zoomPercent%'),
                    IconButton(
                      tooltip: 'Zoom in',
                      icon: const Icon(Icons.zoom_in),
                      onPressed: _zoomPercent < 200
                          ? () => setState(() => _zoomPercent += 5)
                          : null,
                    ),
                  ],
                  if (isCorrect && !showComplete)
                    StyledButtonWidget(
                      valueIcon: const Icon(
                        Icons.start,
                        color: AppTheme.logoGreen,
                      ),
                      onPressed: () => provider.setPopup(true),
                      marginVertical: 5,
                      paddingHorizontal: 10,
                    ),
                ],
              ),
            ),
          ),
        ),
        body: Stack(
          fit: StackFit.expand,
          children: [
            Stack(
              children: [
                Positioned.fill(
                  top: panelHeight + padding,
                  bottom: bottomInset,
                  child: SingleChildScrollView(
                    controller: scrollController,
                    padding: EdgeInsets.fromLTRB(
                      insetPadding,
                      insetPadding,
                      insetPadding,
                      insetPadding + suggestionInset,
                    ),
                    child: Center(
                      child: ConstrainedBox(
                        constraints: BoxConstraints(
                          maxWidth: isWindows
                              ? double.infinity
                              : desktopContentWidth,
                        ),
                        child: CryptogramGridWidget(
                          gameKey: key,
                          gameId: gameId,
                          zoomPercent: isWindows
                              ? _zoomPercent * 140 ~/ 100
                              : _zoomPercent,
                          extraRowGap: isWindows
                              ? const PuzzleGeometry(140).rowHeight * 0.25
                              : 0,
                          bottomInset: suggestionInset,
                          centerRows: isWindows,
                        ),
                      ),
                    ),
                  ),
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
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(
                        maxWidth: desktopContentWidth,
                      ),
                      child: GamePageHeaderWidget(gameKey: key),
                    ),
                  ),
                ),
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 0,
                  child: widget.addKeyboard
                      ? KeyboardWidget(gameKey: key, language: language)
                      : isWindows
                      ? _WindowsGameControls(language: language)
                      : Center(
                          child: ConstrainedBox(
                            constraints: const BoxConstraints(
                              maxWidth: desktopContentWidth,
                            ),
                            child: AvailableCommandsWidget(
                              commands: KeyboardShortcutsWidget.commands(
                                language,
                              ),
                            ),
                          ),
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
    return widget.addKeyboard
        ? game
        : KeyboardShortcutsWidget(
            gameKey: key,
            language: language,
            confirmReset: isWindows,
            child: game,
          );
  }
}

class _WindowsGameControls extends StatelessWidget {
  final Language language;

  const _WindowsGameControls({required this.language});

  @override
  Widget build(BuildContext context) {
    final commands = KeyboardShortcutsWidget.commands(language);
    final help = [
      for (final entry in commands.entries)
        '${entry.value == 'Type Ñ' ? 'Ñ' : entry.value}: '
            '${switch (entry.key) {
              'Left / Right' => '←/→',
              'Up / Down' => '↑/↓',
              _ => entry.key.replaceAll(' + ', '+'),
            }}',
    ].join(' | ');
    final buttonStyle = OutlinedButton.styleFrom(
      foregroundColor: Colors.white,
      side: const BorderSide(color: AppTheme.logoGreen),
    );

    return SizedBox(
      height: desktopCommandsHeight,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: insetPadding),
        child: Row(
          children: [
            Expanded(
              child: FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Text(
                  help,
                  maxLines: 1,
                  softWrap: false,
                  style: const TextStyle(color: Colors.white70, fontSize: 14),
                ),
              ),
            ),
            const SizedBox(width: 8),
            OutlinedButton(
              style: buttonStyle,
              onPressed: () => Actions.invoke(context, UndoCellIntent()),
              child: const Text('Undo'),
            ),
            const SizedBox(width: 8),
            OutlinedButton(
              style: buttonStyle,
              onPressed: () => Actions.invoke(context, ResetCellIntent()),
              child: const Text('Reset'),
            ),
          ],
        ),
      ),
    );
  }
}
