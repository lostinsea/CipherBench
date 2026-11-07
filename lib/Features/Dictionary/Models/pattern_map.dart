import 'dart:collection';
import 'package:scioly_codebusters/library.dart';

class PatternMap {
  final SplayTreeMap<String, List<String>> _map = SplayTreeMap(
    (a, b) =>
        a.length == b.length ? a.compareTo(b) : a.length.compareTo(b.length),
  );
  final Set<String> _regularPlurals = {};

  PatternMap();
  PatternMap.fromList(
    List<String> list, {
    Iterable<String> regularPlurals = const [],
  }) {
    for (var word in list) {
      addWord(word);
    }
    for (final word in regularPlurals) {
      addWord(word, isRegularPlural: true);
    }
  }

  void addWord(String word, {bool isRegularPlural = false}) {
    word = word.toUpperCase();
    final key = getPatternKey(word);
    _map.putIfAbsent(key, () => []);
    final list = _map[key]!;
    if (list.contains(word)) return;
    if (isRegularPlural) _regularPlurals.add(word);
    list.add(word);
  }

  PatternMap copy() {
    final newMap = SplayTreeMap<String, List<String>>(
      (a, b) =>
          a.length == b.length ? a.compareTo(b) : a.length.compareTo(b.length),
    );
    _map.forEach((key, value) {
      newMap[key] = List<String>.from(value);
    });
    final copy = PatternMap();
    newMap.forEach((key, value) {
      copy._map[key] = value;
    });
    copy._regularPlurals.addAll(_regularPlurals);
    return copy;
  }

  bool isRegularPlural(String word) =>
      _regularPlurals.contains(word.toUpperCase());

  List<MapEntry<String, List<String>>> visibleEntries({
    bool showRegularPlurals = false,
  }) {
    if (showRegularPlurals || _regularPlurals.isEmpty) {
      return _map.entries.toList();
    }
    final visible = <MapEntry<String, List<String>>>[];
    for (final entry in _map.entries) {
      final words = entry.value
          .where((word) => !isRegularPlural(word))
          .toList();
      if (words.isNotEmpty) visible.add(MapEntry(entry.key, words));
    }
    return visible;
  }

  Map<String, List<String>> get map => _map;
}
