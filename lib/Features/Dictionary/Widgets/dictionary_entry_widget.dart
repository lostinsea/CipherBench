import 'package:flutter/material.dart';
import 'package:scioly_codebusters/library.dart';

double wordWidgetSpacing = 8.0;
double entryWidgetHeight = 25 + 14 + wordH + insetPadding * 2 + 4 + 24 + 14;

class DictionaryEntryWidget extends StatelessWidget {
  final MapEntry<String, List<String>> entry;
  final int index;
  final Color curColor;
  final bool isEntryHighlighted;
  final GlobalKey entryKey;
  final Map<String, GlobalKey> wordKeys;
  final String? searchTerm;

  const DictionaryEntryWidget({
    super.key,
    required this.entry,
    required this.index,
    required this.curColor,
    required this.isEntryHighlighted,
    required this.entryKey,
    required this.wordKeys,
    required this.searchTerm,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      key: entryKey,
      padding: EdgeInsets.all(insetPadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          HeadingWidget(
            neonColor: curColor,
            title: entry.key,
            num: (index + 1).toString(),
            fontSize: 25,
            showUnderline: false,
          ),
          const SizedBox(height: padding + 10),
          Wrap(
            spacing: wordWidgetSpacing,
            runSpacing: 4,
            children: entry.value
                .map(
                  (word) => DictionaryWordWidget(
                    word: word,
                    index: index,
                    curColor: curColor,
                    isEntryHighlighted: isEntryHighlighted,
                    wordKey: wordKeys.putIfAbsent(
                      '$index-$word',
                      () => GlobalKey(),
                    ),
                    searchTerm: searchTerm,
                  ),
                )
                .toList(),
          ),
        ],
      ),
    );
  }
}
