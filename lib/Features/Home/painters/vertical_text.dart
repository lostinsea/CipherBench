import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

class VerticalText extends CustomPainter {
  final double x;
  final Animation<double> position;
  final String text;
  final double fontsize;
  late final TextPainter _textPainter;

  VerticalText({
    required this.text,
    required this.fontsize,
    required this.position,
    required this.x,
  }) : super(repaint: position) {
    int greenColor = 50;
    int increment = text.isNotEmpty
        ? ((255 - greenColor) / text.length).toInt()
        : 0;
    final spans = <TextSpan>[];
    for (int i = 0; i < text.length; i++) {
      final curColor = Color.fromARGB(255, 0, greenColor.clamp(0, 255), 0);
      spans.add(
        TextSpan(
          text: '${text[i]}\n',
          style: TextStyle(
            color: curColor,
            fontSize: fontsize,
            height: 4 / 3,
            shadows: !kIsWeb && defaultTargetPlatform == TargetPlatform.windows
                ? [Shadow(color: curColor, blurRadius: 5)]
                : [
                    Shadow(color: curColor, blurRadius: 10),
                    Shadow(color: Colors.black, blurRadius: 15),
                    Shadow(color: Colors.white, blurRadius: 20),
                  ],
          ),
        ),
      );
      greenColor += increment;
    }
    _textPainter = TextPainter(
      text: TextSpan(children: spans),
      textDirection: TextDirection.ltr,
      textAlign: TextAlign.center,
    )..layout();
  }

  @override
  void paint(Canvas canvas, Size size) {
    _textPainter.paint(canvas, Offset(x, position.value));
  }

  @override
  bool shouldRepaint(covariant VerticalText oldPainter) {
    return oldPainter.text != text ||
        oldPainter.fontsize != fontsize ||
        oldPainter.x != x ||
        oldPainter.position != position;
  }

  void dispose() {
    _textPainter.dispose();
  }
}
