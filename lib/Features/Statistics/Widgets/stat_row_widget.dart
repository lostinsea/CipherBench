import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class StatRowWidget extends ConsumerStatefulWidget {
  final String title;
  final Color neonColor;
  final String value;

  const StatRowWidget({
    super.key,
    required this.title,
    required this.neonColor,
    required this.value,
  });

  @override
  ConsumerState<StatRowWidget> createState() => _StatRowWidgetState();
}

class _StatRowWidgetState extends ConsumerState<StatRowWidget> {
  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          Transform.translate(
            offset: Offset(10, 0),
            child: Text(
              widget.title.toUpperCase(),
              style: TextStyle(color: Colors.white, fontSize: 18),
            ),
          ),
          Spacer(),
          Text(
            widget.value,
            style: TextStyle(
              color: widget.neonColor,
              fontSize: 18,
              shadows: [
                Shadow(color: widget.neonColor, blurRadius: 5),
                Shadow(color: widget.neonColor, blurRadius: 10),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
