import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:scioly_codebusters/library.dart';

//replace with listview builder
class DictionaryPopoverWidget extends ConsumerWidget {
  final String gameId;
  final String dictionaryId;
  final GameMode gameMode;
  final double bottomInset;
  const DictionaryPopoverWidget({
    super.key,
    required this.gameId,
    required this.dictionaryId,
    required this.gameMode,
    required this.bottomInset,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final gameKey = "$gameId (${toTitleCase(gameMode.name)})";
    final keyboard = ref.read(keyboardProvider(gameKey).notifier);
    final provider = ref.read(gameProvider(gameKey).notifier);
    final patternMap = ref.watch(patternMapProvider(dictionaryId)).map;
    final scrollController = ref.watch(scrollProvider(gameKey));
    final selectedIdx = ref.watch(
      gameProvider(gameKey).select((s) => s.selectedIdx),
    );
    final cells = ref.watch(gameProvider(gameKey).select((s) => s.cells));
    int wordStart = getWordStart(selectedIdx, cells);
    final newWords = getSuggestedWords(cells, wordStart, patternMap);

    Color suggestionColor = Colors.lightBlueAccent;

    return Positioned(
      bottom: bottomInset,
      left: 0,
      right: 0,
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: desktopContentWidth),
          child: Scrollbar(
            controller: scrollController,
            interactive: true,
            trackVisibility: true,
            thumbVisibility: true,
            child: Container(
              width: desktopContentWidth,
              height: containerHeight * 2,
              color: Colors.black,
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                primary: true,
                child: Row(
                  children: [
                    ...(newWords.map((word) {
                      return StyledButtonWidget(
                        value: word,
                        marginHorizontal: 3,
                        marginVertical: 3,
                        txtColor: suggestionColor,
                        bgColor: suggestionColor,
                        paddingVertical: 0,
                        height: containerHeight,
                        addTextShadow: true,
                        onPressed: () async {
                          await keyboardClickSound();
                          keyboard.saveHistory();
                          var curWord = word
                              .toUpperCase()
                              .replaceAll("'", "")
                              .replaceAll("-", "")
                              .split("");
                          if (gameMode == GameMode.assisted) {
                            curWord = curWord.toSet().toList();
                          }
                          provider.selectCell(wordStart);
                          for (int j = 0; j < word.length; j++) {
                            keyboard.pressKey("", false);
                            provider.incrementCell(1);
                          }
                          provider.selectCell(wordStart);
                          for (String letter in curWord) {
                            keyboard.pressKey(letter, false);
                          }
                        },
                      );
                    }).toList()),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
