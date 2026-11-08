import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:scioly_codebusters/library.dart';

void main() {
  test(
    'every English input pool excludes letters, numerals and codes from the index',
    () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final dictionary = container.read(patternMapProvider('english'));
      expect(dictionary.map['A'], ['A', 'I']);
      expect(dictionary.map['AA'], isNull);
      expect(dictionary.map['AB'], containsAll(['OF', 'TO', 'IN', 'IS', 'IT']));
      expect(
        dictionary.map['AB'],
        isNot(contains(anyOf('IE', 'MR', 'MS', 'PC', 'PM', 'TV', 'VS'))),
      );
      final allWords = dictionary.map.values.expand((words) => words).toSet();
      expect(allWords, containsAll(['A', 'I', 'MIX', 'PARAMETER']));
      for (final code in [
        'CEO',
        'CORP',
        'DNA',
        'ETC',
        'MRS',
        'INST',
        'SOS',
        'ASAP',
        'BPM',
        'FTP',
        'FTPING',
        'FTPS',
        'RPM',
        'STD',
        'VHF',
        'III',
        'XIV',
        'XXX',
      ]) {
        expect(allWords, isNot(contains(code)), reason: '$code is not a word');
      }
      expect(allWords.every((word) => isIndexedEnglishWord(word)), isTrue);
      expect(allWords, containsAll(['DOS', 'RES']));
      expect(englishDisplayedBaseWords, isNot(contains(anyOf('TV', 'CEO'))));
      expect(
        dictionary.visibleEntries().expand((entry) => entry.value),
        isNot(contains(anyOf('AIDS', 'DOS', 'RES'))),
      );
      expect(
        dictionary
            .visibleEntries(showRegularPlurals: true)
            .expand((entry) => entry.value),
        containsAll(['AIDS', 'DOS', 'RES']),
      );
      expect(
        container
            .read(patternMapProvider('spanish'))
            .map
            .values
            .expand((words) => words),
        contains('SOS'),
      );
      expect(englishSourceHeadwords.every((word) => word.length >= 3), isTrue);
      expect(
        englishSourceRegularPlurals.every((word) => word.length >= 3),
        isTrue,
      );
      expect(
        dictionary.map.values.expand((words) => words),
        isNot(contains('BK')),
      );
      expect(
        dictionary.map.values.expand((words) => words),
        isNot(contains('XV')),
      );
    },
  );

  test('English plurals are indexed with the correct visibility flag', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    final dictionary = container.read(patternMapProvider('english'));
    final allWords = dictionary.map.values.expand((words) => words).toSet();
    final defaultWords = dictionary
        .visibleEntries()
        .expand((entry) => entry.value)
        .toSet();
    final original = englishWordList
        .where((word) => word != 'AIDS' && isIndexedEnglishWord(word))
        .map((word) => word.toUpperCase())
        .toSet();
    final regular = englishRegularPlurals
        .where(isIndexedEnglishWord)
        .map((word) => word.toUpperCase())
        .toSet();
    final irregular = englishIrregularPlurals
        .where(isIndexedEnglishWord)
        .map((word) => word.toUpperCase())
        .toSet();
    final independent = englishIndependentHeadwords
        .where(
          (word) => isIndexedEnglishWord(word) && word.toUpperCase() != 'DOS',
        )
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
      'AIRS',
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
    expect(independent.length, 142);
    expect(regular, contains('INDEXES'));
    expect(defaultWords, isNot(contains('INDEXES')));
    expect(regular, isNot(contains('LEAFS')));
    expect(regular.length, englishRegularPlurals.length);
    expect(irregular.length, englishIrregularPlurals.length);
    expect(independent.length, englishIndependentHeadwords.length - 2);
    expect(regular.intersection(original), isEmpty);
    expect(regular.intersection(irregular), isEmpty);
    expect(regular.intersection(independent), isEmpty);
    expect(irregular.intersection(original), isEmpty);
    expect(independent.intersection(original), isEmpty);
    final expectedDefault = {
      ...original,
      ...irregular,
      ...independent,
      ...englishSourceHeadwords
          .where(
            (word) => isIndexedEnglishWord(word) && word.toUpperCase() != 'RES',
          )
          .map((word) => word.toUpperCase()),
      ...englishSourceIrregularPlurals
          .where(isIndexedEnglishWord)
          .map((word) => word.toUpperCase()),
    };
    final expectedAll = {
      ...defaultWords,
      ...regular,
      ...englishSourceRegularPlurals
          .where(isIndexedEnglishWord)
          .map((word) => word.toUpperCase()),
      ...englishSourceVerbForms
          .where(isIndexedEnglishWord)
          .map((word) => word.toUpperCase()),
      ...englishSourceDescriptiveForms
          .where(isIndexedEnglishWord)
          .map((word) => word.toUpperCase()),
    };
    expect(defaultWords.length, expectedDefault.length);
    expect(defaultWords.difference(expectedDefault), isEmpty);
    expect(allWords.length, expectedAll.length);
    expect(allWords.difference(expectedAll), isEmpty);
    expect(
      dictionary
          .visibleEntries(
            showRegularPlurals: true,
            showVerbForms: true,
            showDescriptiveForms: true,
          )
          .length,
      dictionary.map.length,
    );
    expect(
      dictionary.map.values
          .expand((words) => words)
          .where((word) => word == 'APPLES'),
      hasLength(1),
    );
    expect(dictionary.copy().isRegularPlural('DREAMS'), isTrue);
    final airsCells = [
      for (final letter in 'AIRS'.split(''))
        Cell(text: '', cipher: letter, plainText: letter, isException: false),
      Cell(text: ' ', cipher: ' ', plainText: ' ', isException: true),
    ];
    expect(
      getSuggestedWords(
        airsCells,
        0,
        dictionary.map,
        includeWord: (word) => !dictionary.isRegularPlural(word),
      ),
      contains('AIRS'),
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
