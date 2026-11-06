import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:scioly_codebusters/library.dart';

class CryptogramGridWidget extends ConsumerWidget {
  final String gameKey;
  final String gameId;
  final int zoomPercent;
  final double extraRowGap;
  final double bottomInset;
  final bool centerRows;

  const CryptogramGridWidget({
    super.key,
    required this.gameKey,
    required this.gameId,
    required this.zoomPercent,
    this.extraRowGap = 0,
    required this.bottomInset,
    this.centerRows = false,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cells = ref.watch(gameProvider(gameKey).select((s) => s.cells));
    final selectedIdx = ref.watch(
      gameProvider(gameKey).select((s) => s.selectedIdx),
    );
    final geometry = PuzzleGeometry(zoomPercent, extraRowGap: extraRowGap);
    return LayoutBuilder(
      builder: (context, constraints) {
        final layout = layoutPuzzleRows(
          cells,
          gameId,
          constraints.maxWidth,
          geometry,
          omitTrailingSpacing: centerRows,
        );
        final scroll = ref.read(scrollProvider(gameKey).notifier);
        if (scroll.updateLayout(
          layout.rowByCell,
          geometry,
          constraints.maxWidth,
          MediaQuery.sizeOf(context).height,
          bottomInset,
        )) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (context.mounted) scroll.scrollToSelected(selectedIdx);
          });
        }
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (final row in layout.rows) _buildRow(row, cells, geometry),
          ],
        );
      },
    );
  }

  Widget _buildRow(List<int> row, List<Cell> cells, PuzzleGeometry geometry) {
    var visibleLength = row.length;
    if (centerRows) {
      while (visibleLength > 0 &&
          isPuzzleWhitespace(cells[row[visibleLength - 1]])) {
        visibleLength--;
      }
    }
    return Padding(
      padding: EdgeInsets.only(bottom: geometry.extraRowGap),
      child: SizedBox(
        height: geometry.rowHeight - geometry.extraRowGap,
        child: Row(
          mainAxisAlignment: centerRows
              ? MainAxisAlignment.center
              : MainAxisAlignment.start,
          children: [
            for (var position = 0; position < visibleLength; position++) ...[
              CellWidget(
                index: row[position],
                gameKey: gameKey,
                geometry: geometry,
              ),
              if (!cells[row[position]].isException &&
                  (!centerRows || position < visibleLength - 1))
                SizedBox(width: geometry.gap),
            ],
          ],
        ),
      ),
    );
  }
}
