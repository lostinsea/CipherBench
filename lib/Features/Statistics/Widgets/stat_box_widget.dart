import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:scioly_codebusters/library.dart';

class StatBoxWidget extends ConsumerStatefulWidget {
  final String title;
  final String num;
  final Color neonColor;
  final String fastest;
  final String average;
  final String solved;

  const StatBoxWidget({
    super.key,
    required this.title,
    required this.num,
    required this.neonColor,
    required this.fastest,
    required this.average,
    required this.solved,
  });

  @override
  ConsumerState<StatBoxWidget> createState() => _StatBoxWidgetState();
}

class _StatBoxWidgetState extends ConsumerState<StatBoxWidget> {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(insetPadding),
      child: Column(
        children: [
          HeadingWidget(
            neonColor: widget.neonColor,
            title: widget.title,
            num: widget.num,
          ),
          // padding
          const SizedBox(height: 20),

          StatRowWidget(
            title: "Fastest",
            neonColor: widget.neonColor,
            value: "${widget.fastest}s",
          ),
          StatRowWidget(
            title: "Average",
            neonColor: widget.neonColor,
            value: "${widget.average}s",
          ),
          StatRowWidget(
            title: "Total Solved",
            neonColor: widget.neonColor,
            value: widget.solved,
          ),
        ],
      ),
    );
  }
}
