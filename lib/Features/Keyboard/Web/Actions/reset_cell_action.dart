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
      final buttonStyle = OutlinedButton.styleFrom(
        foregroundColor: Colors.white,
        side: const BorderSide(color: AppTheme.logoGreen),
      );
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          backgroundColor: Colors.black,
          surfaceTintColor: Colors.transparent,
          shape: const RoundedRectangleBorder(
            side: BorderSide(color: AppTheme.logoGreen),
          ),
          title: const Text(
            'Reset puzzle?',
            style: TextStyle(color: AppTheme.logoGreen),
          ),
          content: const Text(
            'This clears your answers. You can undo the reset.',
            style: TextStyle(color: Colors.white70),
          ),
          actions: [
            OutlinedButton(
              style: buttonStyle,
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('Cancel'),
            ),
            OutlinedButton(
              style: buttonStyle,
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
