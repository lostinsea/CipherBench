import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:scioly_codebusters/library.dart';

void main() {
  test('English plurals are indexed with the correct visibility flag', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    final dictionary = container.read(patternMapProvider('english'));
    final allWords = dictionary.map.values.expand((words) => words).toSet();
    final defaultWords = dictionary
        .visibleEntries()
        .expand((entry) => entry.value)
        .toSet();
    final original = englishWordList.map((word) => word.toUpperCase()).toSet();
    final regular = englishRegularPlurals
        .map((word) => word.toUpperCase())
        .toSet();
    final irregular = englishIrregularPlurals
        .map((word) => word.toUpperCase())
        .toSet();
    final independent = englishIndependentHeadwords
        .map((word) => word.toUpperCase())
        .toSet();

    for (final word in [
      'DREAMS',
      'LUNCHES',
      'BANS',
      'BEEFS',
      'BUSSES',
      'GRANDS',
      'GROSSES',
      'MEDIUMS',
      'NOS',
      'PERSONS',
      'SALMONS',
      'SHRIMPS',
      'SOLES',
    ]) {
      expect(allWords, contains(word));
      expect(dictionary.isRegularPlural(word), isTrue);
      expect(defaultWords, isNot(contains(word)));
    }
    for (final word in [
      'DREAM',
      'LUNCH',
      'APPLES',
      'SOS',
      'WORKS',
      'HIS',
      'ITS',
      'CHILDREN',
      'MICE',
      'BRETHREN',
      'GENII',
      'INDICES',
      'MAXIMA',
      'MINIMA',
      'MONIES',
      'PHENOMENA',
      'STAVES',
    ]) {
      expect(defaultWords, contains(word));
      expect(dictionary.isRegularPlural(word), isFalse);
    }
    expect(regular.length, 2262);
    expect(irregular.length, 34);
    expect(independent.length, 144);
    expect(regular, contains('INDEXES'));
    expect(defaultWords, isNot(contains('INDEXES')));
    expect(regular, isNot(contains('LEAFS')));
    expect(regular.length, englishRegularPlurals.length);
    expect(irregular.length, englishIrregularPlurals.length);
    expect(independent.length, englishIndependentHeadwords.length);
    expect(regular.intersection(original), isEmpty);
    expect(regular.intersection(irregular), isEmpty);
    expect(regular.intersection(independent), isEmpty);
    expect(irregular.intersection(original), isEmpty);
    expect(independent.intersection(original), isEmpty);
    expect(defaultWords, containsAll(original));
    expect(defaultWords, containsAll(irregular));
    expect(defaultWords, containsAll(independent));
    expect(
      defaultWords.length,
      original.length + irregular.length + independent.length,
    );
    expect(allWords.length, defaultWords.length + regular.length);
    expect(allWords, containsAll(defaultWords));
    expect(
      dictionary.visibleEntries(showRegularPlurals: true).length,
      dictionary.map.length,
    );
    expect(
      dictionary.map.values
          .expand((words) => words)
          .where((word) => word == 'APPLES'),
      hasLength(1),
    );
    expect(dictionary.copy().isRegularPlural('DREAMS'), isTrue);
    final sosCells = [
      for (final letter in 'SOS'.split(''))
        Cell(text: '', cipher: letter, plainText: letter, isException: false),
      Cell(text: ' ', cipher: ' ', plainText: ' ', isException: true),
    ];
    expect(
      getSuggestedWords(
        sosCells,
        0,
        dictionary.map,
        includeWord: (word) => !dictionary.isRegularPlural(word),
      ),
      contains('SOS'),
    );
    final indexCells = [
      for (final letter in 'INDICES'.split(''))
        Cell(text: '', cipher: letter, plainText: letter, isException: false),
      Cell(text: ' ', cipher: ' ', plainText: ' ', isException: true),
    ];
    expect(
      getSuggestedWords(
        indexCells,
        0,
        dictionary.map,
        includeWord: (word) => !dictionary.isRegularPlural(word),
      ),
      contains('INDICES'),
    );
    expect(
      container.read(patternMapProvider('spanish')).isRegularPlural('SUEÑOS'),
      isFalse,
    );
  });

  test('puzzle suggestions hide regular plurals until enabled', () {
    final dictionary = PatternMap.fromList(
      ['DREAM', 'FRIEND', 'APPLES', 'SOS'],
      regularPlurals: ['DREAMS', 'APPLES'],
    );
    expect(dictionary.isRegularPlural('APPLES'), isFalse);
    expect(
      dictionary.visibleEntries().expand((entry) => entry.value),
      containsAll(['APPLES', 'SOS']),
    );
    final cells = [
      for (final letter in 'DREAMS'.split(''))
        Cell(text: '', cipher: letter, plainText: letter, isException: false),
      Cell(text: ' ', cipher: ' ', plainText: ' ', isException: true),
    ];
    expect(
      getSuggestedWords(
        cells,
        0,
        dictionary.map,
        includeWord: (word) => !dictionary.isRegularPlural(word),
      ),
      isNot(contains('DREAMS')),
    );
    expect(getSuggestedWords(cells, 0, dictionary.map), contains('DREAMS'));
    expect(
      dictionary.visibleEntries().expand((entry) => entry.value),
      isNot(contains('DREAMS')),
    );
    expect(
      dictionary
          .visibleEntries(showRegularPlurals: true)
          .expand((entry) => entry.value),
      contains('DREAMS'),
    );
    cells[0] = cells[0].copyWith(text: 'F');
    expect(getSuggestedWords(cells, 0, dictionary.map), ['FRIEND']);
  });
}
