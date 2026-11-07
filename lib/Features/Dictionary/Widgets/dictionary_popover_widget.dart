import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:scioly_codebusters/library.dart';

class DictionaryPopoverWidget extends ConsumerStatefulWidget {
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
  ConsumerState<DictionaryPopoverWidget> createState() =>
      _DictionaryPopoverWidgetState();
}

class _DictionaryPopoverWidgetState
    extends ConsumerState<DictionaryPopoverWidget> {
  final ScrollController _wordsController = ScrollController();
  int? _wordStart;

  @override
  void dispose() {
    _wordsController.dispose();
    super.dispose();
  }

  void _scrollWords(int direction) {
    if (!_wordsController.hasClients) return;
    final position = _wordsController.position;
    final target =
        (_wordsController.offset +
                direction * position.viewportDimension * 0.75)
            .clamp(0.0, position.maxScrollExtent);
    if (target != _wordsController.offset) {
      _wordsController.animateTo(
        target,
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOut,
      );
    }
  }

  void _onPointerSignal(PointerSignalEvent event) {
    if (event is! PointerScrollEvent ||
        event.scrollDelta.dx != 0 ||
        event.scrollDelta.dy == 0 ||
        !_wordsController.hasClients) {
      return;
    }
    GestureBinding.instance.pointerSignalResolver.register(event, (resolved) {
      final position = _wordsController.position;
      final delta = (resolved as PointerScrollEvent).scrollDelta.dy;
      _wordsController.jumpTo(
        (_wordsController.offset + delta).clamp(0.0, position.maxScrollExtent),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final gameKey = "${widget.gameId} (${toTitleCase(widget.gameMode.name)})";
    final keyboard = ref.read(keyboardProvider(gameKey).notifier);
    final provider = ref.read(gameProvider(gameKey).notifier);
    final patternMap = ref.watch(patternMapProvider(widget.dictionaryId)).map;
    final selectedIdx = ref.watch(
      gameProvider(gameKey).select((s) => s.selectedIdx),
    );
    final cells = ref.watch(gameProvider(gameKey).select((s) => s.cells));
    final wordStart = getWordStart(selectedIdx, cells);
    final words = getSuggestedWords(cells, wordStart, patternMap);
    final isWindows =
        !kIsWeb && defaultTargetPlatform == TargetPlatform.windows;
    const suggestionColor = Colors.lightBlueAccent;

    if (_wordStart != wordStart) {
      _wordStart = wordStart;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && _wordsController.hasClients) {
          _wordsController.jumpTo(0);
        }
      });
    }

    final wordList = words.isEmpty
        ? const Center(
            child: Text(
              'No matching words',
              style: TextStyle(color: Colors.white70),
            ),
          )
        : Listener(
            onPointerSignal: _onPointerSignal,
            child: ScrollbarTheme(
              data: const ScrollbarThemeData(
                thumbColor: WidgetStatePropertyAll(suggestionColor),
                trackColor: WidgetStatePropertyAll(Color(0xFF152A35)),
                trackBorderColor: WidgetStatePropertyAll(Colors.white38),
                thickness: WidgetStatePropertyAll(6),
                radius: Radius.circular(3),
              ),
              child: Scrollbar(
                controller: _wordsController,
                interactive: true,
                trackVisibility: true,
                thumbVisibility: true,
                scrollbarOrientation: ScrollbarOrientation.bottom,
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: ListView.builder(
                    controller: _wordsController,
                    scrollDirection: Axis.horizontal,
                    itemCount: words.length,
                    itemBuilder: (context, index) {
                      final word = words[index];
                      final button = StyledButtonWidget(
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
                          if (widget.gameMode == GameMode.assisted) {
                            curWord = curWord.toSet().toList();
                          }
                          provider.selectCell(wordStart);
                          for (var j = 0; j < word.length; j++) {
                            keyboard.pressKey("", false);
                            provider.incrementCell(1);
                          }
                          provider.selectCell(wordStart);
                          for (final letter in curWord) {
                            keyboard.pressKey(letter, false);
                          }
                        },
                      );
                      return isWindows ? button : Align(child: button);
                    },
                  ),
                ),
              ),
            ),
          );

    return Positioned(
      bottom: widget.bottomInset,
      left: 0,
      right: 0,
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: desktopContentWidth),
          child: Container(
            width: desktopContentWidth,
            height: isWindows ? desktopSuggestionsHeight : containerHeight * 2,
            decoration: BoxDecoration(
              color: Colors.black,
              border: isWindows ? Border.all(color: suggestionColor) : null,
            ),
            child: isWindows
                ? Padding(
                    padding: const EdgeInsets.fromLTRB(12, 6, 12, 6),
                    child: Column(
                      children: [
                        SizedBox(
                          height: 24,
                          child: Row(
                            children: [
                              const Text(
                                'MATCHING WORDS',
                                style: TextStyle(
                                  color: suggestionColor,
                                  fontFamily: 'JetBrainsMonoBold',
                                  fontSize: 12,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                '${words.length}',
                                style: const TextStyle(
                                  color: Colors.white70,
                                  fontSize: 12,
                                ),
                              ),
                              const Spacer(),
                              IconButton(
                                tooltip: 'Previous suggestions',
                                color: suggestionColor,
                                icon: const Icon(Icons.chevron_left),
                                iconSize: 20,
                                constraints: const BoxConstraints.tightFor(
                                  width: 28,
                                  height: 24,
                                ),
                                padding: EdgeInsets.zero,
                                onPressed: words.isEmpty
                                    ? null
                                    : () => _scrollWords(-1),
                              ),
                              IconButton(
                                tooltip: 'Next suggestions',
                                color: suggestionColor,
                                icon: const Icon(Icons.chevron_right),
                                iconSize: 20,
                                constraints: const BoxConstraints.tightFor(
                                  width: 28,
                                  height: 24,
                                ),
                                padding: EdgeInsets.zero,
                                onPressed: words.isEmpty
                                    ? null
                                    : () => _scrollWords(1),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 4),
                        Expanded(child: wordList),
                      ],
                    ),
                  )
                : wordList,
          ),
        ),
      ),
    );
  }
}
