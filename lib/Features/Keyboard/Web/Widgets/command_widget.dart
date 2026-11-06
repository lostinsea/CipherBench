import 'package:flutter/material.dart';
import 'package:scioly_codebusters/library.dart';

class CommandWidget extends StatelessWidget {
  final String command;
  final String description;
  const CommandWidget({
    super.key,
    required this.command,
    required this.description,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 10.0, vertical: 5.0),
      padding: EdgeInsets.all(5.0),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            decoration: BoxDecoration(
              border: BoxBorder.all(color: AppTheme.logoGreen, width: 1.0),
              borderRadius: BorderRadius.all(Radius.circular(5)),
              color: AppTheme.logoGreen.withAlpha(100),
            ),
            padding: EdgeInsets.all(5),
            child: Text(command, style: TextStyle(color: Colors.white)),
          ),
          SizedBox(height: padding * 2, width: padding * 2),
          Text(description, style: TextStyle(color: Colors.white)),
        ],
      ),
    );
  }
}
