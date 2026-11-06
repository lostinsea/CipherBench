import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:scioly_codebusters/library.dart';

class ResetCellAction extends Action<ResetCellIntent> {
  final String gameKey;
  final WidgetRef ref;
  final BuildContext? confirmationContext;

  ResetCellAction({
    required this.gameKey,
    required this.ref,
    this.confirmationContext,
  });

  @override
  Future<void> invoke(covariant ResetCellIntent intent) async {
    final context = confirmationContext;
    if (context != null) {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: const Text('Reset puzzle?'),
          content: const Text(
            'This clears your answers. You can undo the reset.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: const Text('Reset'),
            ),
          ],
        ),
      );
      if (confirmed != true || !context.mounted) return;
    }
    ref.read(keyboardProvider(gameKey).notifier).resetPuzzle();
  }
}

class ResetCellIntent extends Intent {}
