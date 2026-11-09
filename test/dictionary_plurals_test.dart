import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:scioly_codebusters/library.dart';

import 'database_test_utils.dart';

void main() {
  late AppDatabase database;

  setUpAll(() {
    database = openSeedDatabase();
    installDatabase(database);
  });

  tearDownAll(closeInstalledDatabase);

  test(
    'English display dictionary filters codes while retaining supported forms',
    () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final dictionary = container.read(patternMapProvider('english'));
      final allWords = dictionary.map.values.expand((words) => words).toSet();
      final defaultWords = dictionary
          .visibleEntries()
          .expand((entry) => entry.value)
          .toSet();

      expect(dictionary.map['A'], ['A', 'I']);
      expect(dictionary.map['AA'], isNull);
      expect(dictionary.map['AB'], containsAll(['OF', 'TO', 'IN', 'IS', 'IT']));
      expect(
        dictionary.map['AB'],
        isNot(contains(anyOf('IE', 'MR', 'MS', 'PC', 'PM', 'TV', 'VS'))),
      );
      expect(
        allWords,
        containsAll(['A', 'I', 'MIX', 'PARAMETER', 'DOS', 'RES']),
      );
      expect(allWords.every(isIndexedEnglishWord), isTrue);
      expect(defaultWords, isNot(contains(anyOf('AIDS', 'DOS', 'RES'))));
      expect(
        dictionary
            .visibleEntries(showRegularPlurals: true)
            .expand((entry) => entry.value),
        containsAll(['AIDS', 'DOS', 'RES']),
      );
    },
  );

  test(
    'SQLite dictionary corpus preserves base words, form classes, and source order',
    () {
      final english = database.dictionary(Language.english);
      final englishBase = english.baseWords
          .map((word) => word.toUpperCase())
          .toSet();
      final englishHeadwords = english.headwords
          .map((word) => word.toUpperCase())
          .toSet();
      final englishRegular = english.regularPlurals
          .map((word) => word.toUpperCase())
          .toSet();
      final englishIrregular = english.irregularPlurals
          .map((word) => word.toUpperCase())
          .toSet();
      final spanish = database.dictionaryWords(Language.spanish);

      expect(english.baseWords, hasLength(6462));
      expect(english.headwords, hasLength(33386));
      expect(english.irregularPlurals, hasLength(480));
      expect(english.regularPlurals, hasLength(16603));
      expect(english.verbForms, hasLength(19257));
      expect(english.descriptiveForms, hasLength(4446));
      expect(englishBase, containsAll(['A', 'I', 'MIX']));
      expect(englishHeadwords, contains('PARAMETER'));
      expect(englishRegular, containsAll(['DREAMS', 'INDEXES']));
      expect(englishIrregular, containsAll(['MICE', 'INDICES']));
      expect(spanish, hasLength(4971));
      expect(
        PatternMap.fromList(spanish).map.values.expand((words) => words),
        containsAll(['MAÑANA', 'SUEÑO', 'SOS']),
      );
      expect(english.baseWords.where(isIndexedEnglishWord), isNotEmpty);
    },
  );

  test(
    'SQLite form lists retain independently attested and hidden variants',
    () {
      final words = database.dictionary(Language.english);
      final dictionary = PatternMap.fromList(
        [...words.baseWords, ...words.headwords],
        irregularPlurals: words.irregularPlurals,
        regularPlurals: words.regularPlurals,
        verbForms: words.verbForms,
        descriptiveForms: words.descriptiveForms,
      );

      expect(dictionary.isRegularPlural('DREAMS'), isTrue);
      expect(dictionary.isRegularPlural('APPLES'), isFalse);
      expect(dictionary.isRegularPlural('MICE'), isFalse);
      expect(dictionary.isVisible('DREAMS'), isFalse);
      expect(dictionary.isVisible('APPLES'), isTrue);
      expect(dictionary.isVisible('MICE'), isTrue);
      expect(
        dictionary
            .visibleEntries(showRegularPlurals: true)
            .expand((entry) => entry.value),
        contains('DREAMS'),
      );
    },
  );

  test('puzzle suggestions hide regular plurals only when filtered', () {
    final dictionary = PatternMap.fromList(
      ['DREAM', 'FRIEND', 'APPLES', 'SOS'],
      regularPlurals: ['DREAMS', 'APPLES'],
    );
    final cells = [
      for (final letter in 'DREAMS'.split(''))
        Cell(text: '', cipher: letter, plainText: letter, isException: false),
      Cell(text: ' ', cipher: ' ', plainText: ' ', isException: true),
    ];

    expect(getSuggestedWords(cells, 0, dictionary.map), contains('DREAMS'));
    expect(
      getSuggestedWords(
        cells,
        0,
        dictionary.map,
        includeWord: (word) => !dictionary.isRegularPlural(word),
      ),
      isNot(contains('DREAMS')),
    );
  });
}
