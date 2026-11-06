import 'package:flutter/material.dart';
import 'package:scioly_codebusters/library.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

//longest english: simultaneously
//longest spanish: responsabilidades

double getEntryHeight(int wordCount, int wordLen, double viewportWidth) {
  // Calculate how many words fit per row
  int wordsPerRow =
      ((viewportWidth - 4 * insetPadding) /
              (getWordWidgetWidth(wordLen) + wordWidgetSpacing))
          .floor();
  if (wordsPerRow < 1) wordsPerRow = 1;
  int numRows = (wordCount / wordsPerRow).ceil();
  if (numRows < 1) numRows = 1;
  return (entryWidgetHeight + (numRows - 1) * wordH)
      .toDouble(); // + heading + SizedBox
}

double getWordWidgetWidth(int len) {
  return (10.0 * len) + 40;
}

double getJump(
  List<MapEntry<String, List<String>>> entries,
  int targetEntryIndex,
  double viewportWidth,
) {
  double ans = 0;
  for (int i = 0; i < targetEntryIndex; i++) {
    final entry = entries[i];
    int wordCount = entry.value.length;
    int wordLen = entry.key.length;
    ans += getEntryHeight(wordCount, wordLen, viewportWidth);
  }
  return ans;
}

class DictionaryTab extends ConsumerStatefulWidget {
  final String dictionaryId;
  final List<Color> colors;
  final ScrollController scrollController;

  const DictionaryTab({
    super.key,
    required this.dictionaryId,
    required this.colors,
    required this.scrollController,
  });

  @override
  ConsumerState<DictionaryTab> createState() => _DictionaryTabState();
}

class _DictionaryTabState extends ConsumerState<DictionaryTab> {
  final TextEditingController _searchController = TextEditingController();
  String? _searchTerm;
  int? _highlightedEntryIndex;

  final Map<int, GlobalKey> _entryKeys = {};
  final Map<String, GlobalKey> _wordKeys = {};

  bool _userInterrupted = false;
  bool _isJumping = false;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _onSearch(List<MapEntry<String, List<String>>> entries) {
    final search = _searchController.text.trim().toLowerCase().replaceAll(
      '’',
      "'",
    );
    if (search.isEmpty) {
      setState(() {
        _highlightedEntryIndex = null;
        _searchTerm = null;
      });
      return;
    }
    int? foundEntryIndex;
    String? foundWordKey;
    for (int i = 0; i < entries.length; i++) {
      for (final word in entries[i].value) {
        if (word.toLowerCase() == search) {
          foundEntryIndex = i;
          foundWordKey = '$i-$word';
          break;
        }
      }
      if (foundEntryIndex != null) break;
    }
    setState(() {
      _highlightedEntryIndex = foundEntryIndex;
      _searchTerm = search;
    });

    if (foundWordKey != null) {
      _userInterrupted = false;
      _scrollToWord(foundWordKey, entries, foundEntryIndex!);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Word not found'),
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  void _scrollToWord(
    String wordKey,
    List<MapEntry<String, List<String>>> entries,
    int targetEntryIndex, [
    int attempt = 0,
  ]) async {
    if (_userInterrupted) {
      if (_isJumping) setState(() => _isJumping = false);
      return;
    }
    final key = _wordKeys[wordKey];
    if (attempt == 0) setState(() => _isJumping = true);

    if (attempt == 0 && key != null && key.currentContext != null) {
      Scrollable.ensureVisible(
        key.currentContext!,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
        alignment: 0.1,
      );
      setState(() => _isJumping = false);
      return;
    }

    final scrollStep = MediaQuery.sizeOf(context).height;
    if (attempt == 0 && widget.scrollController.hasClients) {
      double jumpOffset = getJump(
        entries,
        targetEntryIndex,
        MediaQuery.sizeOf(context).width.clamp(0, desktopContentWidth),
      );
      jumpOffset = jumpOffset.clamp(
        0.0,
        widget.scrollController.position.maxScrollExtent,
      );
      await widget.scrollController.animateTo(
        jumpOffset,
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOut,
      );
    }
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (_userInterrupted) {
        if (_isJumping) setState(() => _isJumping = false);
        return;
      }
      final key = _wordKeys[wordKey];
      if (key != null && key.currentContext != null) {
        Scrollable.ensureVisible(
          key.currentContext!,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
          alignment: 0.1,
        );
        setState(() => _isJumping = false);
      } else {
        final targetOffset = (widget.scrollController.offset + scrollStep)
            .clamp(0.0, widget.scrollController.position.maxScrollExtent);
        await widget.scrollController.animateTo(
          targetOffset,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        );
        await Future.delayed(const Duration(milliseconds: 120));
        _scrollToWord(wordKey, entries, targetEntryIndex, attempt + 1);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final entries = ref
        .watch(patternMapProvider(widget.dictionaryId))
        .map
        .entries
        .toList();

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: desktopContentWidth),
        child: Stack(
          children: [
            Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(searchPadding),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _searchController,
                          decoration: InputDecoration(
                            hintText: 'Search word...',
                            hintStyle: TextStyle(color: AppTheme.logoGreen),
                            focusedBorder: OutlineInputBorder(
                              borderSide: BorderSide(
                                color: AppTheme.logoGreen,
                                width: 1,
                              ),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderSide: BorderSide(
                                color: Colors.black.withAlpha(200),
                                width: 1,
                              ),
                            ),
                            fillColor: Colors.black.withAlpha(150),
                            suffixIcon: Icon(Icons.search, color: Colors.white),
                          ),
                          cursorColor: AppTheme.logoGreen,
                          style: TextStyle(color: AppTheme.logoGreen),
                          onSubmitted: (_) => _onSearch(entries),
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: NotificationListener<ScrollNotification>(
                    onNotification: (notification) {
                      if (notification is UserScrollNotification) {
                        _userInterrupted = true;
                      }
                      return false;
                    },
                    child: Scrollbar(
                      controller: widget.scrollController,
                      child: ListView.separated(
                        controller: widget.scrollController,
                        padding: const EdgeInsets.all(insetPadding),
                        itemCount: entries.length,
                        separatorBuilder: (_, _) => const SizedBox(height: 24),
                        itemBuilder: (context, index) {
                          final entry = entries[index];
                          final curColor =
                              widget.colors[index % widget.colors.length];
                          return DictionaryEntryWidget(
                            entry: entry,
                            index: index,
                            curColor: curColor,
                            isEntryHighlighted: index == _highlightedEntryIndex,
                            entryKey: _entryKeys.putIfAbsent(
                              index,
                              () => GlobalKey(),
                            ),
                            wordKeys: _wordKeys,
                            searchTerm: _searchTerm,
                          );
                        },
                      ),
                    ),
                  ),
                ),
              ],
            ),
            if (_isJumping)
              Container(
                color: Colors.black.withAlpha((0.4 * 255).toInt()),
                child: const Center(child: CircularProgressIndicator()),
              ),
          ],
        ),
      ),
    );
  }
}
