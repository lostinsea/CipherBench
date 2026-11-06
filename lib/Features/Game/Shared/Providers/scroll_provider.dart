import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:scioly_codebusters/library.dart';

// Notifier that manages a ScrollController
class ScrollControllerNotifier
    extends AutoDisposeFamilyNotifier<ScrollController, String> {
  List<int> _rowByCell = const [];
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
    List<int> rowByCell,
    PuzzleGeometry geometry,
    double width,
    double height,
    double bottomInset,
  ) {
    final changed =
        _lastWidth != width ||
        _lastHeight != height ||
        _rowHeight != geometry.rowHeight ||
        _bottomInset != bottomInset ||
        _rowByCell.length != rowByCell.length;
    _rowByCell = rowByCell;
    _rowHeight = geometry.rowHeight;
    _bottomInset = bottomInset;
    _lastWidth = width;
    _lastHeight = height;
    return changed;
  }

  void scrollToSelected(int index) {
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
    if (target != null) {
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
