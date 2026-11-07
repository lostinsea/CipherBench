import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:scioly_codebusters/library.dart';

class MoveCellAction extends Action<MoveCellIntent> {
  final String gameKey;
  final WidgetRef ref;

  MoveCellAction({required this.gameKey, required this.ref});

  @override
  void invoke(covariant MoveCellIntent intent) {
    final game = ref.read(gameProvider(gameKey).notifier);
    final isWindows =
        !kIsWeb && defaultTargetPlatform == TargetPlatform.windows;
    switch (intent.direction) {
      case CellDirection.right:
        game.incrementCell(1, immediateScroll: isWindows);
      case CellDirection.left:
        game.incrementCell(-1, immediateScroll: isWindows);
      case CellDirection.up:
        game.moveVertical(-1);
      case CellDirection.down:
        game.moveVertical(1);
    }
  }
}

enum CellDirection { left, right, up, down }

class MoveCellIntent extends Intent {
  final CellDirection direction;
  const MoveCellIntent(this.direction);
}
