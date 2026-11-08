bool _isLetter(int code) => (code >= 65 && code <= 90) || code == 209;

String _collapseStars(String query) {
  final pattern = StringBuffer();
  var previousStar = false;
  for (final code in query.codeUnits) {
    if (code != 42 || !previousStar) pattern.writeCharCode(code);
    previousStar = code == 42;
  }
  return pattern.toString();
}

bool _matchesWildcard(String word, String pattern) {
  var wordIndex = 0;
  var patternIndex = 0;
  int? starIndex;
  var retryIndex = 0;

  while (wordIndex < word.length) {
    if (patternIndex < pattern.length) {
      final expected = pattern.codeUnitAt(patternIndex);
      if (expected == 42) {
        starIndex = patternIndex++;
        retryIndex = wordIndex;
        continue;
      }
      final current = word.codeUnitAt(wordIndex);
      if (expected == current || (expected == 63 && _isLetter(current))) {
        wordIndex++;
        patternIndex++;
        continue;
      }
    }
    if (starIndex == null ||
        retryIndex == word.length ||
        !_isLetter(word.codeUnitAt(retryIndex))) {
      return false;
    }
    wordIndex = ++retryIndex;
    patternIndex = starIndex + 1;
  }
  while (patternIndex < pattern.length &&
      pattern.codeUnitAt(patternIndex) == 42) {
    patternIndex++;
  }
  return patternIndex == pattern.length;
}

List<MapEntry<String, List<String>>> searchDictionaryEntries(
  Iterable<MapEntry<String, List<String>>> entries,
  String query,
) {
  final text = query.trim().replaceAll('’', "'").toUpperCase();
  if (text.isEmpty) return const [];
  final hasWildcard = text.contains('?') || text.contains('*');
  final pattern = hasWildcard ? _collapseStars(text) : text;
  final minimumLength = pattern.length - '*'.allMatches(pattern).length;
  final matches = <MapEntry<String, List<String>>>[];
  for (final entry in entries) {
    final words = entry.value
        .where(
          (word) => hasWildcard
              ? word.length >= minimumLength && _matchesWildcard(word, pattern)
              : word.startsWith(text),
        )
        .toList();
    if (words.isNotEmpty) matches.add(MapEntry(entry.key, words));
  }
  return matches;
}
