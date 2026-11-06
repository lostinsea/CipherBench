import 'package:scioly_codebusters/Features/Game/Shared/Models/cell.dart';
import 'package:scioly_codebusters/theme.dart';

class PuzzleGeometry {
  const PuzzleGeometry(this.zoomPercent, {this.extraRowGap = 0});

  final int zoomPercent;
  final double extraRowGap;

  double get scale => zoomPercent / 100;
  double get cellWidth => containerWidth * scale;
  double get cellHeight => containerHeight * scale;
  double get labelHeight => decorationHeight * scale;
  double get gap => padding * scale;
  double get cellFontSize => containerFS * scale;
  double get labelFontSize => decorationTextFS * scale;
  double get exceptionFontSize => 18 * scale;
  double get rowHeight => cellHeight + 2 * labelHeight + 3 * gap + extraRowGap;

  double widthOf(Cell cell) => cellWidth + (cell.isException ? 0 : gap);
}

class PuzzleRows {
  const PuzzleRows(this.rows, this.rowByCell);

  final List<List<int>> rows;
  final List<int> rowByCell;
}

bool isPuzzleWhitespace(Cell cell) =>
    cell.isException && cell.plainText.trim().isEmpty;

PuzzleRows layoutPuzzleRows(
  List<Cell> cells,
  String gameId,
  double availableWidth,
  PuzzleGeometry geometry, {
  bool omitTrailingSpacing = false,
}) {
  final rows = <List<int>>[];
  final rowByCell = List<int>.filled(cells.length, 0);
  if (cells.isEmpty) return PuzzleRows(rows, rowByCell);

  var currentRow = <int>[];
  var rowWidth = 0.0;

  double fittedWidth(double width, int first, int last) {
    if (!omitTrailingSpacing) return width;
    while (last >= first && isPuzzleWhitespace(cells[last])) {
      width -= geometry.widthOf(cells[last]);
      last--;
    }
    if (last >= first && !cells[last].isException) width -= geometry.gap;
    return width;
  }

  void nextRow() {
    if (currentRow.isEmpty) return;
    rows.add(currentRow);
    currentRow = <int>[];
    rowWidth = 0;
  }

  void addCell(int index) {
    final width = geometry.widthOf(cells[index]);
    if (currentRow.isNotEmpty &&
        fittedWidth(rowWidth + width, currentRow.first, index) >
            availableWidth) {
      nextRow();
    }
    rowByCell[index] = rows.length;
    currentRow.add(index);
    rowWidth += width;
  }

  for (var start = 0; start < cells.length;) {
    var end = start + 1;
    if (gameId != 'Patristocrat') {
      while (end < cells.length && cells[end - 1].plainText != ' ') {
        end++;
      }
    }
    var wordWidth = 0.0;
    for (var index = start; index < end; index++) {
      wordWidth += geometry.widthOf(cells[index]);
    }
    if (currentRow.isNotEmpty &&
        fittedWidth(rowWidth + wordWidth, currentRow.first, end - 1) >
            availableWidth) {
      nextRow();
    }
    for (var index = start; index < end; index++) {
      addCell(index);
    }
    start = end;
  }
  nextRow();
  return PuzzleRows(rows, rowByCell);
}
