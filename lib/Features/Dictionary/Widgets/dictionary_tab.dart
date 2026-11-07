import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:scioly_codebusters/library.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

//longest english: simultaneously
//longest spanish: responsabilidades

const _scrollbarInset = 24.0;
const _entrySpacing = 24.0;
const _windowsSearchMaxWidth = 600.0;

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

class _StableDictionaryDelegate extends SliverChildBuilderDelegate {
  _StableDictionaryDelegate(
    super.builder, {
    required super.childCount,
    super.semanticIndexCallback,
    required this.contentExtent,
  });

  final double contentExtent;

  @override
  double? estimateMaxScrollOffset(
    int firstIndex,
    int lastIndex,
    double leadingScrollOffset,
    double trailingScrollOffset,
  ) => contentExtent;
}

class DictionaryTab extends ConsumerStatefulWidget {
  final String dictionaryId;
  final List<Color> colors;

  const DictionaryTab({
    super.key,
    required this.dictionaryId,
    required this.colors,
  });

  @override
  ConsumerState<DictionaryTab> createState() => _DictionaryTabState();
}

class _DictionaryTabState extends ConsumerState<DictionaryTab> {
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  String? _searchTerm;
  int? _highlightedEntryIndex;

  final Map<int, GlobalKey> _entryKeys = {};
  final Map<String, GlobalKey> _wordKeys = {};

  bool _userInterrupted = false;
  bool _isJumping = false;
  bool _showRegularPlurals = false;

  double _contentExtent(
    BuildContext context,
    List<MapEntry<String, List<String>>> entries,
    double viewportWidth,
  ) {
    final scaler = MediaQuery.textScalerOf(context);
    final direction = Directionality.of(context);
    final defaultStyle = DefaultTextStyle.of(context).style;

    double textHeight(String text, TextStyle style) {
      final painter = TextPainter(
        text: TextSpan(text: text, style: style),
        textDirection: direction,
        textScaler: scaler,
      )..layout();
      final height = painter.height;
      painter.dispose();
      return height;
    }

    final wordStyle = defaultStyle.merge(const TextStyle(fontSize: 14));
    final wordPainter = TextPainter(
      textDirection: direction,
      textScaler: scaler,
    );
    final wordHeight = textHeight('A', wordStyle) + 10 + 2 * borderWidth;
    final headingHeight = math.max(
      textHeight(
        'A',
        defaultStyle.merge(
          const TextStyle(fontSize: 25, fontFamily: 'JetBrainsMonoBold'),
        ),
      ),
      textHeight(
            '1',
            defaultStyle.merge(
              const TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
            ),
          ) +
          6,
    );
    final wordWidths = <int, double>{};
    final availableWidth = viewportWidth - 4 * insetPadding;
    double extent = 2 * insetPadding;
    for (final entry in entries) {
      final wordLength = entry.key.length;
      final width = wordWidths.putIfAbsent(wordLength, () {
        wordPainter.text = TextSpan(text: 'M' * wordLength, style: wordStyle);
        wordPainter.layout();
        return wordPainter.width + 40 + 2 * borderWidth;
      });
      final wordsPerRow = math.max(
        1,
        ((availableWidth + wordWidgetSpacing) / (width + wordWidgetSpacing))
            .floor(),
      );
      final rows = math.max(1, (entry.value.length / wordsPerRow).ceil());
      extent +=
          2 * insetPadding +
          headingHeight +
          2 + // Account for pixel rounding in rendered heading text.
          padding +
          10 +
          rows * wordHeight +
          (rows - 1) * 4 +
          _entrySpacing;
    }
    wordPainter.dispose();
    return entries.isEmpty ? extent : extent - _entrySpacing;
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
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
    if (attempt == 0 && _scrollController.hasClients) {
      double jumpOffset = getJump(
        entries,
        targetEntryIndex,
        MediaQuery.sizeOf(context).width,
      );
      jumpOffset = jumpOffset.clamp(
        0.0,
        _scrollController.position.maxScrollExtent,
      );
      await _scrollController.animateTo(
        jumpOffset,
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOut,
      );
    }
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted || !_scrollController.hasClients) return;
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
        final targetOffset = (_scrollController.offset + scrollStep).clamp(
          0.0,
          _scrollController.position.maxScrollExtent,
        );
        await _scrollController.animateTo(
          targetOffset,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        );
        await Future.delayed(const Duration(milliseconds: 120));
        if (!mounted) return;
        _scrollToWord(wordKey, entries, targetEntryIndex, attempt + 1);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final isWindows =
        !kIsWeb && defaultTargetPlatform == TargetPlatform.windows;
    final entries = ref
        .watch(patternMapProvider(widget.dictionaryId))
        .visibleEntries(showRegularPlurals: _showRegularPlurals);

    Widget buildEntry(BuildContext context, int index) {
      final entry = entries[index];
      final curColor = widget.colors[index % widget.colors.length];
      return DictionaryEntryWidget(
        entry: entry,
        index: index,
        curColor: curColor,
        isEntryHighlighted: index == _highlightedEntryIndex,
        entryKey: _entryKeys.putIfAbsent(index, () => GlobalKey()),
        wordKeys: _wordKeys,
        searchTerm: _searchTerm,
      );
    }

    final pluralToggle = widget.dictionaryId == 'english'
        ? Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Show regular plurals',
                style: TextStyle(color: Colors.white70),
              ),
              const SizedBox(width: 12),
              Switch(
                value: _showRegularPlurals,
                activeThumbColor: AppTheme.logoGreen,
                onChanged: (value) {
                  _userInterrupted = true;
                  if (_scrollController.hasClients) {
                    _scrollController.jumpTo(0);
                  }
                  setState(() {
                    _showRegularPlurals = value;
                    _isJumping = false;
                    _highlightedEntryIndex = null;
                    _searchTerm = null;
                    _entryKeys.clear();
                    _wordKeys.clear();
                  });
                },
              ),
            ],
          )
        : null;
    final searchField = TextField(
      controller: _searchController,
      decoration: InputDecoration(
        hintText: 'Search word...',
        hintStyle: TextStyle(color: AppTheme.logoGreen),
        focusedBorder: OutlineInputBorder(
          borderSide: BorderSide(color: AppTheme.logoGreen, width: 1),
          borderRadius: BorderRadius.circular(10),
        ),
        enabledBorder: OutlineInputBorder(
          borderSide: BorderSide(color: Colors.black.withAlpha(200), width: 1),
        ),
        fillColor: Colors.black.withAlpha(150),
        suffixIcon: Icon(Icons.search, color: Colors.white),
      ),
      cursorColor: AppTheme.logoGreen,
      style: TextStyle(color: AppTheme.logoGreen),
      onSubmitted: (_) => _onSearch(entries),
    );

    return Stack(
      children: [
        Column(
          children: [
            Padding(
              padding: isWindows
                  ? const EdgeInsets.fromLTRB(
                      2 * insetPadding,
                      searchPadding,
                      _scrollbarInset,
                      searchPadding,
                    )
                  : const EdgeInsets.all(searchPadding),
              child: Row(
                children: [
                  if (isWindows && pluralToggle != null) ...[
                    pluralToggle,
                    const SizedBox(width: 32),
                  ],
                  Expanded(
                    child: isWindows
                        ? Align(
                            alignment: Alignment.centerRight,
                            child: ConstrainedBox(
                              constraints: const BoxConstraints(
                                maxWidth: _windowsSearchMaxWidth,
                              ),
                              child: searchField,
                            ),
                          )
                        : searchField,
                  ),
                  if (!isWindows && pluralToggle != null) ...[
                    const SizedBox(width: 8),
                    pluralToggle,
                  ],
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
                child: ScrollbarTheme(
                  data: isWindows
                      ? const ScrollbarThemeData(
                          thumbColor: WidgetStatePropertyAll(
                            AppTheme.logoGreen,
                          ),
                          trackColor: WidgetStatePropertyAll(
                            Colors.transparent,
                          ),
                          trackBorderColor: WidgetStatePropertyAll(
                            Colors.transparent,
                          ),
                          thickness: WidgetStatePropertyAll(6),
                          radius: Radius.circular(3),
                          crossAxisMargin: _scrollbarInset,
                        )
                      : ScrollbarTheme.of(context),
                  child: Scrollbar(
                    controller: _scrollController,
                    thumbVisibility: isWindows,
                    trackVisibility: isWindows,
                    interactive: true,
                    child: LayoutBuilder(
                      builder: (context, constraints) => isWindows
                          ? ListView.custom(
                              controller: _scrollController,
                              padding: const EdgeInsets.all(insetPadding),
                              semanticChildCount: entries.length,
                              childrenDelegate: _StableDictionaryDelegate(
                                (context, childIndex) {
                                  if (childIndex.isOdd) {
                                    return const SizedBox(
                                      height: _entrySpacing,
                                    );
                                  }
                                  return buildEntry(context, childIndex ~/ 2);
                                },
                                childCount: entries.isEmpty
                                    ? 0
                                    : entries.length * 2 - 1,
                                semanticIndexCallback: (widget, index) =>
                                    index.isEven ? index ~/ 2 : null,
                                contentExtent: _contentExtent(
                                  context,
                                  entries,
                                  constraints.maxWidth,
                                ),
                              ),
                            )
                          : ListView.separated(
                              controller: _scrollController,
                              padding: const EdgeInsets.all(insetPadding),
                              itemCount: entries.length,
                              separatorBuilder: (_, _) =>
                                  const SizedBox(height: _entrySpacing),
                              itemBuilder: buildEntry,
                            ),
                    ),
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
    );
  }
}
