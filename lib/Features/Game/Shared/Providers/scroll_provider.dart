import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:scioly_codebusters/library.dart';

// Notifier that manages a ScrollController
class ScrollControllerNotifier
    extends AutoDisposeFamilyNotifier<ScrollController, String> {
  List<List<int>> _rows = const [];
  List<int> _rowByCell = const [];
  PuzzleGeometry? _geometry;
  bool _centerRows = false;
  double _rowHeight = 0;
  double _bottomInset = 0;
  double? _lastWidth;
  double? _lastHeight;

  @override
  ScrollController build(String arg) {
    final controller = ScrollController();
    ref.onDispose(() => controller.dispose());
    return controller;
  }

  bool updateLayout(
    PuzzleRows layout,
    PuzzleGeometry geometry,
    double width,
    double height,
    double bottomInset, {
    bool centerRows = false,
  }) {
    final rowByCell = layout.rowByCell;
    final changed =
        _lastWidth != width ||
        _lastHeight != height ||
        _rowHeight != geometry.rowHeight ||
        _bottomInset != bottomInset ||
        _centerRows != centerRows ||
        !listEquals(_rowByCell, rowByCell);
    _rows = layout.rows;
    _rowByCell = rowByCell;
    _geometry = geometry;
    _centerRows = centerRows;
    _rowHeight = geometry.rowHeight;
    _bottomInset = bottomInset;
    _lastWidth = width;
    _lastHeight = height;
    return changed;
  }

  int? verticalNeighbor(int index, int direction, List<Cell> cells) {
    if (direction != -1 && direction != 1) {
      throw ArgumentError.value(direction, 'direction', 'must be -1 or 1');
    }
    final geometry = _geometry;
    if (geometry == null ||
        _lastWidth == null ||
        index < 0 ||
        index >= _rowByCell.length ||
        cells.length != _rowByCell.length) {
      return null;
    }

    final sourceRow = _rowByCell[index];
    if (sourceRow >= _rows.length || cells[index].isException) return null;
    var x = _rowLeft(_rows[sourceRow], cells, geometry);
    double? sourceX;
    for (final cellIndex in _rows[sourceRow]) {
      if (cellIndex == index) {
        sourceX = x + geometry.cellWidth / 2;
        break;
      }
      x += geometry.widthOf(cells[cellIndex]);
    }
    if (sourceX == null) return null;

    for (
      var rowIndex = sourceRow + direction;
      rowIndex >= 0 && rowIndex < _rows.length;
      rowIndex += direction
    ) {
      final row = _rows[rowIndex];
      var left = _rowLeft(row, cells, geometry);
      var closestDistance = double.infinity;
      int? closest;
      for (final cellIndex in row) {
        if (!cells[cellIndex].isException) {
          final distance = (left + geometry.cellWidth / 2 - sourceX).abs();
          if (distance < closestDistance) {
            closest = cellIndex;
            closestDistance = distance;
          }
        }
        left += geometry.widthOf(cells[cellIndex]);
      }
      if (closest != null) return closest;
    }
    return null;
  }

  double _rowLeft(List<int> row, List<Cell> cells, PuzzleGeometry geometry) {
    if (!_centerRows) return 0;
    var visibleLength = row.length;
    while (visibleLength > 0 &&
        isPuzzleWhitespace(cells[row[visibleLength - 1]])) {
      visibleLength--;
    }
    var rowWidth = 0.0;
    for (var position = 0; position < visibleLength; position++) {
      rowWidth += geometry.cellWidth;
      if (!cells[row[position]].isException && position < visibleLength - 1) {
        rowWidth += geometry.gap;
      }
    }
    return (_lastWidth! - rowWidth) / 2;
  }

  void scrollToSelected(int index, {bool immediate = false}) {
    if (!state.hasClients || index < 0 || index >= _rowByCell.length) return;
    final position = insetPadding + _rowByCell[index] * _rowHeight;
    final visibleTop = state.offset + insetPadding;
    final visibleBottom =
        state.offset +
        state.position.viewportDimension -
        _bottomInset -
        insetPadding;
    double? target;
    if (position < visibleTop) {
      target = position - insetPadding;
    } else if (position + _rowHeight > visibleBottom) {
      target =
          position +
          _rowHeight +
          _bottomInset +
          insetPadding -
          state.position.viewportDimension;
    }
    if (immediate) {
      if (target != null || state.position.isScrollingNotifier.value) {
        state.jumpTo(
          (target ?? state.offset).clamp(0.0, state.position.maxScrollExtent),
        );
      }
    } else if (target != null) {
      state.animateTo(
        target.clamp(0.0, state.position.maxScrollExtent),
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }
}

final scrollProvider =
    AutoDisposeNotifierProvider.family<
      ScrollControllerNotifier,
      ScrollController,
      String
    >(ScrollControllerNotifier.new);
