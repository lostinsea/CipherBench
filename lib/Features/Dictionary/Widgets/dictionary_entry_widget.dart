import 'package:flutter/material.dart';
import 'package:scioly_codebusters/library.dart';

double wordWidgetSpacing = 8.0;

class DictionaryEntryWidget extends StatelessWidget {
  final MapEntry<String, List<String>> entry;
  final int index;
  final Color curColor;
  final bool isEntryHighlighted;
  final Key entryKey;
  final String? searchTerm;
  final bool compactRow;
  final bool showHeading;
  final List<String>? displayedWords;

  const DictionaryEntryWidget({
    super.key,
    required this.entry,
    required this.index,
    required this.curColor,
    required this.isEntryHighlighted,
    required this.entryKey,
    required this.searchTerm,
    this.compactRow = false,
    this.showHeading = true,
    this.displayedWords,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      key: entryKey,
      padding: compactRow
          ? const EdgeInsets.symmetric(horizontal: insetPadding)
          : EdgeInsets.all(insetPadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: compactRow
            ? MainAxisAlignment.center
            : MainAxisAlignment.start,
        children: [
          if (showHeading) ...[
            HeadingWidget(
              neonColor: curColor,
              title: entry.key,
              num: (index + 1).toString(),
              fontSize: 25,
              showUnderline: false,
            ),
            if (!compactRow) const SizedBox(height: padding + 10),
          ],
          if ((displayedWords ?? entry.value).isNotEmpty)
            Wrap(
              spacing: wordWidgetSpacing,
              runSpacing: 4,
              children: [
                for (final word in displayedWords ?? entry.value)
                  DictionaryWordWidget(
                    word: word,
                    index: index,
                    curColor: curColor,
                    isEntryHighlighted: isEntryHighlighted,
                    wordKey: ValueKey('word-${entry.key}-$word'),
                    searchTerm: searchTerm,
                  ),
              ],
            ),
        ],
      ),
    );
  }
}
