import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:scioly_codebusters/Features/Dictionary/Util/dictionary_search.dart';
import 'package:scioly_codebusters/library.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

const _scrollbarInset = 24.0;
const _entrySpacing = 24.0;
const _windowsSearchMaxWidth = 600.0;

enum _RowKind { heading, words, gap }

class _DictionaryRow {
  const _DictionaryRow(
    this.kind,
    this.entryIndex, [
    this.start = 0,
    this.end = 0,
  ]);

  final _RowKind kind;
  final int entryIndex;
  final int start;
  final int end;
}

class _StableDictionaryRowsDelegate extends SliverChildBuilderDelegate {
  _StableDictionaryRowsDelegate(
    super.builder, {
    required super.childCount,
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
  Timer? _searchTimer;
  String? _searchTerm;
  List<MapEntry<String, List<String>>> _searchEntries = const [];
  PatternMap? _cachedMap;
  bool? _cachedShowRegularPlurals;
  bool? _cachedShowVerbForms;
  bool? _cachedShowDescriptiveForms;
  List<MapEntry<String, List<String>>> _cachedEntries = const [];

  bool _showRegularPlurals = false;
  bool _showVerbForms = false;
  bool _showDescriptiveForms = false;

  List<_DictionaryRow> _rowsFor(
    BuildContext context,
    List<MapEntry<String, List<String>>> entries,
    double viewportWidth,
  ) {
    final scaler = MediaQuery.textScalerOf(context);
    final wordPainter = TextPainter(
      textDirection: Directionality.of(context),
      textScaler: scaler,
    );
    final widths = <int, double>{};
    final rows = <_DictionaryRow>[];
    for (var entryIndex = 0; entryIndex < entries.length; entryIndex++) {
      final entry = entries[entryIndex];
      final width = widths.putIfAbsent(entry.key.length, () {
        wordPainter.text = TextSpan(
          text: 'M' * entry.key.length,
          style: DefaultTextStyle.of(
            context,
          ).style.merge(const TextStyle(fontSize: 14)),
        );
        wordPainter.layout();
        return wordPainter.width + 20;
      });
      final perRow = math.max(
        1,
        ((viewportWidth - 4 * insetPadding + wordWidgetSpacing) /
                (width + wordWidgetSpacing))
            .floor(),
      );
      if (entryIndex > 0) rows.add(_DictionaryRow(_RowKind.gap, entryIndex));
      rows.add(_DictionaryRow(_RowKind.heading, entryIndex));
      for (var start = 0; start < entry.value.length; start += perRow) {
        rows.add(
          _DictionaryRow(
            _RowKind.words,
            entryIndex,
            start,
            math.min(start + perRow, entry.value.length),
          ),
        );
      }
    }
    wordPainter.dispose();
    return rows;
  }

  @override
  void dispose() {
    _searchTimer?.cancel();
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _onSearch(List<MapEntry<String, List<String>>> entries) {
    final query = _searchController.text.trim();
    if (_scrollController.hasClients) _scrollController.jumpTo(0);
    setState(() {
      _searchTerm = query.isEmpty ? null : query;
      _searchEntries = searchDictionaryEntries(entries, query);
    });
  }

  @override
  Widget build(BuildContext context) {
    final isWindows =
        !kIsWeb && defaultTargetPlatform == TargetPlatform.windows;
    final patternMap = ref.watch(patternMapProvider(widget.dictionaryId));
    if (!identical(_cachedMap, patternMap) ||
        _cachedShowRegularPlurals != _showRegularPlurals ||
        _cachedShowVerbForms != _showVerbForms ||
        _cachedShowDescriptiveForms != _showDescriptiveForms) {
      _cachedMap = patternMap;
      _cachedShowRegularPlurals = _showRegularPlurals;
      _cachedShowVerbForms = _showVerbForms;
      _cachedShowDescriptiveForms = _showDescriptiveForms;
      _cachedEntries = patternMap.visibleEntries(
        showRegularPlurals: _showRegularPlurals,
        showVerbForms: _showVerbForms,
        showDescriptiveForms: _showDescriptiveForms,
      );
      if (_searchTerm != null) {
        _searchEntries = searchDictionaryEntries(_cachedEntries, _searchTerm!);
      }
    }
    final entries = _searchTerm == null ? _cachedEntries : _searchEntries;

    Widget formToggle(String label, bool value, ValueChanged<bool> change) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(label, style: const TextStyle(color: Colors.white70)),
          Switch(
            value: value,
            activeThumbColor: AppTheme.logoGreen,
            onChanged: (enabled) {
              if (_scrollController.hasClients) _scrollController.jumpTo(0);
              setState(() {
                change(enabled);
              });
            },
          ),
        ],
      );
    }

    final formToggles = widget.dictionaryId == 'english'
        ? Wrap(
            spacing: 12,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              formToggle('Regular plurals', _showRegularPlurals, (value) {
                _showRegularPlurals = value;
              }),
              formToggle('Verb forms', _showVerbForms, (value) {
                _showVerbForms = value;
              }),
              formToggle('Adjectives / adverbs', _showDescriptiveForms, (
                value,
              ) {
                _showDescriptiveForms = value;
              }),
            ],
          )
        : null;
    final searchField = TextField(
      controller: _searchController,
      decoration: InputDecoration(
        hintText: 'Search word or pattern...',
        hintStyle: TextStyle(color: AppTheme.logoGreen),
        focusedBorder: OutlineInputBorder(
          borderSide: BorderSide(color: AppTheme.logoGreen, width: 1),
          borderRadius: BorderRadius.circular(10),
        ),
        enabledBorder: OutlineInputBorder(
          borderSide: BorderSide(color: Colors.black.withAlpha(200), width: 1),
        ),
        fillColor: Colors.black.withAlpha(150),
        suffixIcon: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              tooltip: 'Search help',
              icon: const Icon(Icons.help_outline, color: Colors.white70),
              onPressed: () => showDialog<void>(
                context: context,
                builder: (dialogContext) => AlertDialog(
                  backgroundColor: Colors.black,
                  surfaceTintColor: Colors.transparent,
                  shape: const RoundedRectangleBorder(
                    side: BorderSide(color: AppTheme.logoGreen),
                  ),
                  title: const Text(
                    'Search help',
                    style: TextStyle(color: AppTheme.logoGreen),
                  ),
                  content: const Text(
                    'Text finds words starting with it (CAT finds CATS).\n'
                    '? matches one letter (C?T finds CAT, COT).\n'
                    '* matches zero or more letters (C*T finds CAT, CART).\n'
                    'Wildcards match the whole word; results stay grouped by pattern.',
                    style: TextStyle(color: Colors.white70),
                  ),
                  actions: [
                    OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.white,
                        side: const BorderSide(color: AppTheme.logoGreen),
                      ),
                      onPressed: () => Navigator.of(dialogContext).pop(),
                      child: const Text('Close'),
                    ),
                  ],
                ),
              ),
            ),
            const Padding(
              padding: EdgeInsets.only(right: 12),
              child: Icon(Icons.search, color: Colors.white),
            ),
          ],
        ),
      ),
      cursorColor: AppTheme.logoGreen,
      style: TextStyle(color: AppTheme.logoGreen),
      onChanged: (_) {
        _searchTimer?.cancel();
        _searchTimer = Timer(const Duration(milliseconds: 120), () {
          if (mounted) _onSearch(_cachedEntries);
        });
      },
      onSubmitted: (_) {
        _searchTimer?.cancel();
        _onSearch(_cachedEntries);
      },
    );

    return Column(
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
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ignore: use_null_aware_elements
              if (formToggles != null) formToggles,
              if (formToggles != null) const SizedBox(height: 4),
              Align(
                alignment: Alignment.centerRight,
                child: ConstrainedBox(
                  constraints: const BoxConstraints(
                    maxWidth: _windowsSearchMaxWidth,
                  ),
                  child: searchField,
                ),
              ),
            ],
          ),
        ),
        if (_searchTerm != null)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 2 * insetPadding),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                '${_searchEntries.fold<int>(0, (total, entry) => total + entry.value.length)} matching words',
                style: const TextStyle(color: Colors.white70),
              ),
            ),
          ),
        Expanded(
          child: ScrollbarTheme(
            data: isWindows
                ? const ScrollbarThemeData(
                    thumbColor: WidgetStatePropertyAll(AppTheme.logoGreen),
                    trackColor: WidgetStatePropertyAll(Colors.transparent),
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
                builder: (context, constraints) {
                  if (_searchTerm != null && entries.isEmpty) {
                    return ListView(
                      controller: _scrollController,
                      padding: const EdgeInsets.all(insetPadding),
                      children: const [
                        Text(
                          'No matching words',
                          style: TextStyle(color: Colors.white70),
                        ),
                      ],
                    );
                  }
                  final rows = _rowsFor(context, entries, constraints.maxWidth);
                  final scaler = MediaQuery.textScalerOf(context);
                  double rowExtent(int index) => switch (rows[index].kind) {
                    _RowKind.heading => math.max(
                      52,
                      scaler.scale(25) * 1.6 + 12,
                    ),
                    _RowKind.words => math.max(34, scaler.scale(14) * 1.6 + 12),
                    _RowKind.gap => _entrySpacing,
                  };
                  final contentExtent = rows.indexed.fold<double>(
                    2 * insetPadding,
                    (total, item) => total + rowExtent(item.$1),
                  );
                  return ListView.custom(
                    controller: _scrollController,
                    padding: const EdgeInsets.all(insetPadding),
                    itemExtentBuilder: (index, dimensions) => rowExtent(index),
                    childrenDelegate: _StableDictionaryRowsDelegate(
                      (context, rowIndex) {
                        final row = rows[rowIndex];
                        if (row.kind == _RowKind.gap) {
                          return const SizedBox.shrink();
                        }
                        final entry = entries[row.entryIndex];
                        return DictionaryEntryWidget(
                          entry: entry,
                          index: row.entryIndex,
                          curColor: widget
                              .colors[row.entryIndex % widget.colors.length],
                          isEntryHighlighted: false,
                          entryKey: row.kind == _RowKind.heading
                              ? ValueKey('heading-${entry.key}')
                              : ValueKey('row-${entry.key}-${row.start}'),
                          searchTerm: null,
                          compactRow: true,
                          showHeading: row.kind == _RowKind.heading,
                          displayedWords: row.kind == _RowKind.heading
                              ? const []
                              : entry.value.sublist(row.start, row.end),
                        );
                      },
                      childCount: rows.length,
                      contentExtent: contentExtent,
                    ),
                  );
                },
              ),
            ),
          ),
        ),
      ],
    );
  }
}
