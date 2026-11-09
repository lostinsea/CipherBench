import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:scioly_codebusters/library.dart';

class GamePageLayout extends ConsumerStatefulWidget {
  final GamePageConfig config;

  const GamePageLayout({super.key, required this.config});

  @override
  ConsumerState<GamePageLayout> createState() => _GamePageLayoutState();
}

class _GamePageLayoutState extends ConsumerState<GamePageLayout> {
  int _zoomPercent = 100;

  @override
  Widget build(BuildContext context) {
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

    ref.listen<bool>(gameProvider(key).select((s) => s.showSuggestions), (
      previous,
      next,
    ) {
      if (!next) return;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        ref
            .read(scrollProvider(key).notifier)
            .scrollToSelected(ref.read(gameProvider(key)).selectedIdx);
      });
    });

    const bottomInset = desktopCommandsHeight;
    final suggestionInset = showSuggestions
        ? desktopSuggestionsHeight + desktopSuggestionsGap * 2
        : 0.0;
    final puzzleScrollView = SingleChildScrollView(
      controller: scrollController,
      padding: const EdgeInsets.all(insetPadding),
      child: Center(
        child: CryptogramGridWidget(
          gameKey: key,
          gameId: gameId,
          zoomPercent: _zoomPercent * 140 ~/ 100,
          extraRowGap: const PuzzleGeometry(140).rowHeight * 0.25,
          bottomInset: 0,
          centerRows: true,
        ),
      ),
    );
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
            Padding(
              padding: const EdgeInsets.all(windowsScreenInset),
              child: Stack(
                children: [
                  Positioned.fill(
                    top: panelHeight + padding,
                    bottom: bottomInset + suggestionInset,
                    child: ScrollbarTheme(
                      data: const ScrollbarThemeData(
                        thumbColor: WidgetStatePropertyAll(AppTheme.logoGreen),
                        trackColor: WidgetStatePropertyAll(Colors.transparent),
                        trackBorderColor: WidgetStatePropertyAll(
                          Colors.transparent,
                        ),
                        thickness: WidgetStatePropertyAll(6),
                        radius: Radius.circular(3),
                      ),
                      child: Scrollbar(
                        controller: scrollController,
                        thumbVisibility: true,
                        trackVisibility: true,
                        interactive: true,
                        scrollbarOrientation: ScrollbarOrientation.right,
                        child: puzzleScrollView,
                      ),
                    ),
                  ),
                  if (showSuggestions)
                    DictionaryPopoverWidget(
                      gameId: gameId,
                      gameMode: gameMode,
                      dictionaryId: language.name,
                      bottomInset: bottomInset + desktopSuggestionsGap,
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
                    child: _WindowsGameControls(language: language),
                  ),
                ],
              ),
            ),
            if (showComplete)
              FinishedQuoteWidget(quote: quote, author: author, gameKey: key),
          ],
        ),
      ),
    );
    return KeyboardShortcutsWidget(
      gameKey: key,
      language: language,
      confirmReset: true,
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
              'Left / Up / Right / Down' => '← ↑ → ↓',
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
