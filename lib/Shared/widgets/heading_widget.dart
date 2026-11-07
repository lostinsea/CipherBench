import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class HeadingWidget extends ConsumerWidget {
  final Color neonColor;
  final String title;
  final String num;
  final Icon? numIcon;
  final double fontSize;
  final bool showUnderline;

  const HeadingWidget({
    super.key,
    required this.neonColor,
    required this.title,
    this.num = "",
    this.numIcon,
    this.fontSize = 18,
    this.showUnderline = true,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      decoration: showUnderline
          ? BoxDecoration(
              border: Border(bottom: BorderSide(color: neonColor, width: 2)),
            )
          : null,
      padding: showUnderline
          ? const EdgeInsets.only(bottom: 10)
          : EdgeInsets.zero,
      child: Row(
        children: [
          Container(
            color: neonColor,
            padding: EdgeInsets.symmetric(vertical: 3, horizontal: 10),
            margin: EdgeInsets.fromLTRB(0, 0, 15, 0),
            child:
                numIcon ??
                Text(
                  num,
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: fontSize - 5,
                  ),
                ),
          ),

          Text(
            title.toUpperCase(),
            style: TextStyle(
              color: neonColor,
              fontFamily: 'JetBrainsMonoBold',
              fontSize: fontSize,
            ),
          ),
        ],
      ),
    );
  }
}
