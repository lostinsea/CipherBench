import 'package:flutter_test/flutter_test.dart';
import 'package:scioly_codebusters/library.dart';

import 'database_test_utils.dart';

void main() {
  late AppDatabase database;

  setUpAll(() {
    database = openSeedDatabase();
  });

  tearDownAll(() => database.close());

  test(
    'English form visibility defaults off and preserves independently attested words',
    () {
      final dictionary = PatternMap.fromList(
        ['BASE', 'ATTESTED'],
        regularPlurals: ['CATS', 'ATTESTED', 'MULTIFORM'],
        verbForms: ['WALKED', 'ATTESTED', 'MULTIFORM'],
        descriptiveForms: ['BRIGHTER', 'ATTESTED', 'MULTIFORM'],
      );

      Set<String> visibleWords({
        bool showRegularPlurals = false,
        bool showVerbForms = false,
        bool showDescriptiveForms = false,
      }) => dictionary
          .visibleEntries(
            showRegularPlurals: showRegularPlurals,
            showVerbForms: showVerbForms,
            showDescriptiveForms: showDescriptiveForms,
          )
          .expand((entry) => entry.value)
          .toSet();

      expect(dictionary.isVisible('CATS'), isFalse);
      expect(dictionary.isVisible('WALKED'), isFalse);
      expect(dictionary.isVisible('BRIGHTER'), isFalse);
      expect(dictionary.isVisible('ATTESTED'), isTrue);
      expect(dictionary.isVisible('MULTIFORM'), isFalse);
      expect(dictionary.formsFor('MULTIFORM'), {
        WordForm.regularPlural,
        WordForm.verb,
        WordForm.descriptive,
      });
      expect(dictionary.copy().formsFor('ATTESTED'), {
        WordForm.regularPlural,
        WordForm.verb,
        WordForm.descriptive,
      });
      expect(
        dictionary.isVisible('MULTIFORM', showRegularPlurals: true),
        isTrue,
      );
      expect(dictionary.isVisible('MULTIFORM', showVerbForms: true), isTrue);
      expect(
        dictionary.isVisible('MULTIFORM', showDescriptiveForms: true),
        isTrue,
      );
      expect(
        dictionary.isVisible(
          'MULTIFORM',
          showRegularPlurals: true,
          showVerbForms: true,
          showDescriptiveForms: true,
        ),
        isTrue,
      );
      expect(visibleWords(), {'BASE', 'ATTESTED'});
      expect(visibleWords(showRegularPlurals: true), {
        'BASE',
        'ATTESTED',
        'CATS',
        'MULTIFORM',
      });
      expect(visibleWords(showVerbForms: true), {
        'BASE',
        'ATTESTED',
        'WALKED',
        'MULTIFORM',
      });
      expect(visibleWords(showDescriptiveForms: true), {
        'BASE',
        'ATTESTED',
        'BRIGHTER',
        'MULTIFORM',
      });
      expect(
        visibleWords(
          showRegularPlurals: true,
          showVerbForms: true,
          showDescriptiveForms: true,
        ),
        {'BASE', 'ATTESTED', 'CATS', 'WALKED', 'BRIGHTER', 'MULTIFORM'},
      );
    },
  );

  test('puzzle suggestions can apply the same English form filter', () {
    final dictionary = PatternMap.fromList(
      ['CAT'],
      regularPlurals: ['CATS'],
      verbForms: ['CATS'],
    );
    final cells = [
      for (final letter in 'CATS'.split(''))
        Cell(text: '', cipher: letter, plainText: letter, isException: false),
      Cell(text: ' ', cipher: ' ', plainText: ' ', isException: true),
    ];

    expect(getSuggestedWords(cells, 0, dictionary.map), ['CATS']);
    expect(
      getSuggestedWords(
        cells,
        0,
        dictionary.map,
        includeWord: dictionary.isVisible,
      ),
      isEmpty,
    );
  });

  test(
    'SQLite dictionaries preserve Spanish words without English form filters',
    () {
      final words = database.dictionaryWords(Language.spanish);
      final dictionary = PatternMap.fromList(words);
      final allWords = dictionary.map.values.expand((words) => words).toSet();
      final defaultWords = dictionary
          .visibleEntries()
          .expand((entry) => entry.value)
          .toSet();

      expect(words, hasLength(4971));
      expect(allWords, containsAll(['MAÑANA', 'SUEÑO', 'SOS']));
      expect(defaultWords, allWords);
    },
  );

  test(
    'frequency ordering uses SQLite scores with deterministic fallbacks and ties',
    () {
      final scores = database.englishFrequencyScores;
      expect(scores, isNotEmpty);

      final dictionary = PatternMap.fromList(
        ['ZINC', 'LOVE', 'HOPE', 'ABLE'],
        frequencyScores: const {'ZINC': 1, 'LOVE': 5, 'HOPE': 5},
      );
      final pattern = getPatternKey('LOVE');

      expect(dictionary.map[pattern], ['ZINC', 'LOVE', 'HOPE', 'ABLE']);
      expect(dictionary.mapForOrder()[pattern], [
        'ZINC',
        'LOVE',
        'HOPE',
        'ABLE',
      ]);
      expect(dictionary.mapForOrder(frequencyOrder: true)[pattern], [
        'HOPE',
        'LOVE',
        'ZINC',
        'ABLE',
      ]);

      dictionary.addWord('DOPE');
      expect(dictionary.mapForOrder(frequencyOrder: true)[pattern], [
        'HOPE',
        'LOVE',
        'ZINC',
        'ABLE',
        'DOPE',
      ]);
    },
  );
}
