import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:scioly_codebusters/library.dart';
import 'dart:math';

class MatrixBackgroundWidget extends ConsumerStatefulWidget {
  const MatrixBackgroundWidget({super.key});

  @override
  ConsumerState<MatrixBackgroundWidget> createState() =>
      _MatrixBackgroundWidgetState();
}

class _MatrixBackgroundWidgetState extends ConsumerState<MatrixBackgroundWidget>
    with RouteAware {
  final List<LineData> _fallingLines = [];

  Random random = Random();
  late Timer? _lineSpawnTimer;

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _startGeneratingLines();
    });
  }

  void _startGeneratingLines() {
    final interval = !kIsWeb && defaultTargetPlatform == TargetPlatform.windows
        ? const Duration(milliseconds: 400)
        : const Duration(milliseconds: 200);
    _lineSpawnTimer = Timer.periodic(interval, (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }

      final key = UniqueKey();
      final widget = VerticalFallingLine(key: key);
      setState(() {
        _fallingLines.add(LineData(widget));
      });

      Future.delayed(Duration(seconds: 10), () {
        if (!mounted) return;
        setState(() {
          _fallingLines.removeWhere((line) => line.key == key);
        });
      }); // Just deleting the created lines after 10 seconds
    });
  }

  @override
  void dispose() {
    _lineSpawnTimer?.cancel();
    routeObserver.unsubscribe(this);
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    routeObserver.subscribe(this, ModalRoute.of(context)!);
  }

  @override
  void didPushNext() {
    // When new page is pushed on route
    super.didPushNext();
    _lineSpawnTimer?.cancel();
  }

  @override
  void didPopNext() {
    // When new page is popped off route
    super.didPopNext();
    _startGeneratingLines();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(children: _fallingLines.map((line) => line.widget).toList());
  }
}

List<VerticalFallingLine> generateFallingWidgets(int len) {
  List<VerticalFallingLine> output = [];
  for (int i = 0; i < len; i++) {
    output.add(VerticalFallingLine(key: UniqueKey()));
  }
  return output;
}

class LineData {
  final Widget widget;
  final UniqueKey key;

  LineData(this.widget) : key = widget.key as UniqueKey;
}
