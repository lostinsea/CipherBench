import 'package:flutter/material.dart';

class DictionaryWordWidget extends StatelessWidget {
  final String word;
  final int index;
  final Color curColor;
  final bool isEntryHighlighted;
  final Key wordKey;
  final String? searchTerm;

  const DictionaryWordWidget({
    super.key,
    required this.word,
    required this.index,
    required this.curColor,
    required this.isEntryHighlighted,
    required this.wordKey,
    required this.searchTerm,
  });

  @override
  Widget build(BuildContext context) {
    final isWordHighlighted = isEntryHighlighted && searchTerm != null;
    return Container(
      key: wordKey,
      decoration: isWordHighlighted
          ? BoxDecoration(color: Colors.orange.withAlpha(100))
          : null,
      padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
      child: Text(
        word,
        style: TextStyle(
          fontSize: 14,
          color: isWordHighlighted ? Colors.white : curColor,
          fontWeight: isWordHighlighted ? FontWeight.bold : FontWeight.normal,
        ),
      ),
    );
  }
}
