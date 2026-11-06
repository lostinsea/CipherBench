import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:scioly_codebusters/library.dart';

// Notifier that manages a ScrollController
class ScrollControllerNotifier
    extends AutoDisposeFamilyNotifier<ScrollController, String> {
  @override
  ScrollController build(String arg) {
    final controller = ScrollController();
    ref.onDispose(() => controller.dispose());
    return controller;
  }

  // alter algorithm for if the dicitionary popover is there
  void scrollToSelected(double position, {double? bottomInset}) {
    if (!state.hasClients) return;
    var scrollHeight =
        state.position.viewportDimension -
        (containerHeight + 2 * decorationHeight) -
        (bottomInset ?? keyboardH) -
        panelHeight -
        containerHeight * 2;
    if ((position - state.offset) > scrollHeight) {
      state.animateTo(
        position - (scrollHeight) + (containerHeight + 2 * decorationHeight),
        duration: Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else if ((position - state.offset) < 0) {
      state.animateTo(
        position,
        duration: Duration(milliseconds: 300),
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
