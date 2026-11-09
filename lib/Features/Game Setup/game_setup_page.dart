import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:scioly_codebusters/library.dart';

class GamePageSetup extends ConsumerWidget {
  final Language language;
  final String gameId;
  const GamePageSetup({
    super.key,
    required this.gameId,
    required this.language,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final gameMode = ref.watch(gameModeProvider(gameId));
    final key = "$gameId (${toTitleCase(gameMode.name)})";
    final gmProvider = ref.read(gameModeProvider(gameId).notifier);
    final gProvider = ref.read(gameProvider(key).notifier);
    final cellCount = ref.watch(
      gameProvider(key).select((s) => s.cells.length),
    );
    final stats = ref.watch(statsProvider(key));
    final sectionStyle = Theme.of(
      context,
    ).textTheme.titleSmall?.copyWith(color: Colors.white70);

    return Container(
      decoration: AppTheme.backgroundGradient,
      child: Scaffold(
        backgroundColor: AppTheme.appBarBackground,
        appBar: AppBar(backgroundColor: AppTheme.appBarBackground),
        body: Center(
          child: SingleChildScrollView(
            padding: EdgeInsets.all(
              isWindowsDesktop ? windowsScreenInset : insetPadding,
            ),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 700),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    gameId.toUpperCase(),
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                      shadows: [
                        const Shadow(color: AppTheme.logoGreen, blurRadius: 5),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),
                  Text('GAME MODE', style: sectionStyle),
                  const SizedBox(height: 12),
                  SegmentedButton<GameMode>(
                    segments: const [
                      ButtonSegment(
                        value: GameMode.assisted,
                        label: Text('Assisted'),
                      ),
                      ButtonSegment(
                        value: GameMode.manual,
                        label: Text('Manual'),
                      ),
                    ],
                    selected: {gameMode},
                    onSelectionChanged: (selection) async {
                      gmProvider.setGameMode(selection.single);
                      await buttonClickSound();
                    },
                    style: ButtonStyle(
                      foregroundColor: WidgetStateProperty.resolveWith(
                        (states) => states.contains(WidgetState.selected)
                            ? AppTheme.logoGreen
                            : Colors.white,
                      ),
                      backgroundColor: WidgetStateProperty.resolveWith(
                        (states) => states.contains(WidgetState.selected)
                            ? AppTheme.logoGreen.withValues(alpha: 0.14)
                            : Colors.transparent,
                      ),
                      side: WidgetStateProperty.resolveWith(
                        (states) => BorderSide(
                          color: states.contains(WidgetState.selected)
                              ? AppTheme.logoGreen
                              : Colors.white70,
                        ),
                      ),
                      shape: const WidgetStatePropertyAll(StadiumBorder()),
                      padding: const WidgetStatePropertyAll(
                        EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                      ),
                      textStyle: const WidgetStatePropertyAll(
                        TextStyle(
                          fontFamily: 'JetBrainsMonoBold',
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 56),
                  Text('PLAY', style: sectionStyle),
                  const SizedBox(height: 12),
                  Wrap(
                    alignment: WrapAlignment.center,
                    spacing: 20,
                    runSpacing: 12,
                    children: [
                      if (cellCount > 0)
                        _SetupButton(
                          label: 'Continue Puzzle',
                          primary: true,
                          onPressed: () async {
                            await buttonClickSound();
                            if (!context.mounted) return;
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => GamePage(
                                  gameId: gameId,
                                  gameMode: gameMode,
                                  language: language,
                                ),
                              ),
                            );
                          },
                        ),
                      _SetupButton(
                        label: 'New Puzzle',
                        primary: cellCount == 0,
                        onPressed: () async {
                          await buttonClickSound();
                          if (!context.mounted) return;
                          try {
                            await gProvider.buildCryptogram(
                              gameMode,
                              language,
                              gameId,
                            );
                          } on NoEligibleQuotesException {
                            if (!context.mounted) return;
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                  'No original quotes are available for this language. Turn on "Use extended quote collection" in Settings to include imported quotes.',
                                ),
                              ),
                            );
                            return;
                          } on NoUnseenQuotesException {
                            if (!context.mounted) return;
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                  'No unseen quotes remain in the selected collection for this language. Turn off "Skip completed quotes" in Settings to replay them.',
                                ),
                              ),
                            );
                            return;
                          }
                          if (!context.mounted) return;
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => GamePage(
                                gameId: gameId,
                                gameMode: gameMode,
                                language: language,
                              ),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 56),
                  Wrap(
                    alignment: WrapAlignment.center,
                    spacing: 20,
                    runSpacing: 12,
                    children: [
                      _SetupButton(
                        label: 'Stats',
                        onPressed: () async {
                          await buttonClickSound();
                          if (!context.mounted) return;
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  StatsPage(widgetKey: key, stats: stats),
                            ),
                          );
                        },
                      ),
                      _SetupButton(
                        label: 'How to Play',
                        onPressed: () async {
                          await buttonClickSound();
                          if (!context.mounted) return;
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  Instructions(gameId: gameId),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _SetupButton extends StatelessWidget {
  final String label;
  final VoidCallback onPressed;
  final bool primary;

  const _SetupButton({
    required this.label,
    required this.onPressed,
    this.primary = false,
  });

  @override
  Widget build(BuildContext context) {
    final textScale = MediaQuery.textScalerOf(context).scale(14) / 14;
    final scaledWidth = 176 * textScale;
    final availableWidth =
        MediaQuery.sizeOf(context).width -
        2 * (isWindowsDesktop ? windowsScreenInset : insetPadding);
    return SizedBox(
      width: scaledWidth < availableWidth ? scaledWidth : availableWidth,
      height: 44 * textScale,
      child: OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          backgroundColor: primary ? AppTheme.logoGreen : Colors.transparent,
          foregroundColor: primary ? Colors.black : Colors.white,
          side: BorderSide(
            color: primary ? AppTheme.logoGreen : Colors.white70,
          ),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
          padding: const EdgeInsets.symmetric(horizontal: 8),
          textStyle: const TextStyle(
            fontFamily: 'JetBrainsMonoBold',
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
        ),
        child: Text(label, textAlign: TextAlign.center),
      ),
    );
  }
}
