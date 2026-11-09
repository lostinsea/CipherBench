import 'dart:collection';
import 'package:scioly_codebusters/library.dart';

enum WordForm { regularPlural, irregularPlural, verb, descriptive }

class PatternMap {
  final SplayTreeMap<String, List<String>> _map = SplayTreeMap(
    (a, b) =>
        a.length == b.length ? a.compareTo(b) : a.length.compareTo(b.length),
  );
  final Set<String> _defaultWords = {};
  final Map<String, Set<WordForm>> _forms = {};
  Map<String, List<String>>? _frequencyMap;
  final Map<String, int>? _scores;

  PatternMap([this._scores]);
  PatternMap.fromList(
    List<String> list, {
    Iterable<String> regularPlurals = const [],
    Iterable<String> irregularPlurals = const [],
    Iterable<String> verbForms = const [],
    Iterable<String> descriptiveForms = const [],
    Map<String, int>? frequencyScores,
  }) : _scores = frequencyScores {
    for (var word in list) {
      addWord(word);
    }
    for (final word in irregularPlurals) {
      _addForm(word, WordForm.irregularPlural, defaultVisible: true);
    }
    for (final word in regularPlurals) {
      _addForm(word, WordForm.regularPlural);
    }
    for (final word in verbForms) {
      _addForm(word, WordForm.verb);
    }
    for (final word in descriptiveForms) {
      _addForm(word, WordForm.descriptive);
    }
  }

  void _indexWord(String word) {
    final key = getPatternKey(word);
    final words = _map.putIfAbsent(key, () => []);
    words.add(word);
    _frequencyMap = null;
  }

  void addWord(String word) {
    word = word.toUpperCase();
    final isNew = !_defaultWords.contains(word) && !_forms.containsKey(word);
    _defaultWords.add(word);
    if (isNew) _indexWord(word);
  }

  void _addForm(String word, WordForm form, {bool defaultVisible = false}) {
    word = word.toUpperCase();
    final isNew = !_defaultWords.contains(word) && !_forms.containsKey(word);
    _forms.putIfAbsent(word, () => {}).add(form);
    if (defaultVisible) _defaultWords.add(word);
    if (isNew) _indexWord(word);
  }

  PatternMap copy() {
    final copy = PatternMap(_scores);
    _map.forEach((key, words) {
      copy._map[key] = List<String>.of(words);
    });
    copy._defaultWords.addAll(_defaultWords);
    _forms.forEach((word, forms) {
      copy._forms[word] = Set<WordForm>.of(forms);
    });
    return copy;
  }

  bool isRegularPlural(String word) =>
      !_defaultWords.contains(word.toUpperCase()) &&
      (_forms[word.toUpperCase()]?.contains(WordForm.regularPlural) ?? false);

  Set<WordForm> formsFor(String word) =>
      Set.unmodifiable(_forms[word.toUpperCase()] ?? const <WordForm>{});

  bool isVisible(
    String word, {
    bool showRegularPlurals = false,
    bool showVerbForms = false,
    bool showDescriptiveForms = false,
  }) {
    word = word.toUpperCase();
    if (_defaultWords.contains(word)) return true;
    final forms = _forms[word];
    return forms != null &&
        ((showRegularPlurals && forms.contains(WordForm.regularPlural)) ||
            (showVerbForms && forms.contains(WordForm.verb)) ||
            (showDescriptiveForms && forms.contains(WordForm.descriptive)));
  }

  List<MapEntry<String, List<String>>> visibleEntries({
    bool showRegularPlurals = false,
    bool showVerbForms = false,
    bool showDescriptiveForms = false,
  }) {
    if (showRegularPlurals && showVerbForms && showDescriptiveForms) {
      return _map.entries.toList();
    }
    final visible = <MapEntry<String, List<String>>>[];
    for (final entry in _map.entries) {
      final words = entry.value
          .where(
            (word) => isVisible(
              word,
              showRegularPlurals: showRegularPlurals,
              showVerbForms: showVerbForms,
              showDescriptiveForms: showDescriptiveForms,
            ),
          )
          .toList();
      if (words.isNotEmpty) visible.add(MapEntry(entry.key, words));
    }
    return visible;
  }

  Map<String, List<String>> get map => _map;

  Map<String, List<String>> mapForOrder({bool frequencyOrder = false}) {
    if (!frequencyOrder) return _map;
    final scores = _scores ?? appDatabase?.englishFrequencyScores;
    if (scores == null) {
      throw StateError(
        'Frequency scores are unavailable before database initialization.',
      );
    }
    return _frequencyMap ??= _FrequencyOrderedMap(_map, scores);
  }
}

class _FrequencyOrderedMap extends MapBase<String, List<String>> {
  final Map<String, List<String>> _source;
  final Map<String, int> _scores;
  final Map<String, List<String>> _sorted = {};

  _FrequencyOrderedMap(this._source, this._scores);

  @override
  List<String>? operator [](Object? key) {
    final words = _source[key];
    if (words == null || key is! String) return null;
    return _sorted.putIfAbsent(
      key,
      () => List<String>.of(words)
        ..sort((a, b) {
          final byFrequency = (_scores[b] ?? 0).compareTo(_scores[a] ?? 0);
          return byFrequency != 0 ? byFrequency : a.compareTo(b);
        }),
    );
  }

  @override
  Iterable<String> get keys => _source.keys;

  @override
  void operator []=(String key, List<String> value) =>
      throw UnsupportedError('Frequency order is read-only');

  @override
  void clear() => throw UnsupportedError('Frequency order is read-only');

  @override
  List<String>? remove(Object? key) =>
      throw UnsupportedError('Frequency order is read-only');
}
