import 'package:flutter/material.dart';
import 'package:scioly_codebusters/library.dart';

class AvailableCommandsWidget extends StatelessWidget {
  final Map<String, String> commands;
  const AvailableCommandsWidget({super.key, required this.commands});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: screenW,
      height: desktopCommandsHeight,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            for (final entry in commands.entries)
              CommandWidget(command: entry.key, description: entry.value),
          ],
        ),
      ),
    );
  }
}
