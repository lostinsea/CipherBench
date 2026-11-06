import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:scioly_codebusters/library.dart';
import 'dart:math';

class VerticalFallingLine extends ConsumerStatefulWidget {
  const VerticalFallingLine({super.key});

  @override
  ConsumerState<VerticalFallingLine> createState() =>
      _VerticalFallingLineState();
}

class _VerticalFallingLineState extends ConsumerState<VerticalFallingLine>
    with SingleTickerProviderStateMixin {
  late final AnimationController _animationController;
  late final Animation<double> _fallingAnimation;
  late final VerticalText _painter;
  final double fontsize = 10;
  final textBuffer = 100;

  String text = "";
  double y = 0;
  double x = 0;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 10000),
      vsync: this,
    );

    Random random = Random();
    text = englishWordList[random.nextInt(englishWordList.length)];

    y = (-(fontsize + 5) * text.length) - (random.nextDouble() * textBuffer);
    x = random.nextDouble() * GameSetup.width;

    _fallingAnimation = Tween(begin: y, end: GameSetup.height).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.linear),
    );

    _painter = VerticalText(
      text: text,
      fontsize: fontsize,
      position: _fallingAnimation,
      x: x,
    );
    _animationController.repeat();
  }

  @override
  void dispose() {
    _painter.dispose();
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return CustomPaint(painter: _painter);
  }
}
