import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:scioly_codebusters/library.dart';

void main() {
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

  test('puzzle suggestions can use the same default English visibility', () {
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

  test('Spanish dictionary ignores English form visibility controls', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    final dictionary = container.read(patternMapProvider('spanish'));
    final allWords = dictionary.map.values.expand((words) => words).toSet();
    final defaultWords = dictionary
        .visibleEntries()
        .expand((entry) => entry.value)
        .toSet();

    expect(defaultWords, allWords);
    expect(defaultWords, isNotEmpty);
  });

  test(
    'frequency order changes suggestions without changing dictionary order',
    () {
      final dictionary = PatternMap.fromList(['ZINC', 'LOVE']);
      final original = dictionary.map[getPatternKey('LOVE')]!;

      expect(
        englishFrequencyScores['LOVE'],
        greaterThan(englishFrequencyScores['ZINC']!),
      );
      expect(original, ['ZINC', 'LOVE']);
      expect(dictionary.mapForOrder()[getPatternKey('LOVE')], original);
      expect(
        dictionary.mapForOrder(frequencyOrder: true)[getPatternKey('LOVE')],
        ['LOVE', 'ZINC'],
      );
      expect(dictionary.visibleEntries().single.value, ['ZINC', 'LOVE']);
      expect(original, ['ZINC', 'LOVE']);

      dictionary.addWord('HOPE');
      final ranked = dictionary.mapForOrder(
        frequencyOrder: true,
      )[getPatternKey('LOVE')]!;
      expect(ranked, contains('HOPE'));
      expect(ranked.first, isNot('ZINC'));
      expect(dictionary.mapForOrder()[getPatternKey('LOVE')], [
        'ZINC',
        'LOVE',
        'HOPE',
      ]);
    },
  );
}
