import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:scioly_codebusters/library.dart';

class GamePage extends ConsumerWidget {
  final String gameId;
  final GameMode gameMode;
  final Language language;

  const GamePage({
    super.key,
    required this.gameId,
    required this.gameMode,
    required this.language,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    GameSetup.init(context);
    final GamePageConfig config = GamePageConfig(
      gameId: gameId,
      gameMode: gameMode,
      language: language,
    );
    return GamePageLayout(config: config);
  }
}
