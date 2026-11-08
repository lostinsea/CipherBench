import 'package:flutter_test/flutter_test.dart';
import 'package:scioly_codebusters/Features/Dictionary/Util/dictionary_search.dart';
import 'package:scioly_codebusters/library.dart';

void main() {
  final entries = [
    const MapEntry('ABC', ['CAT', 'COT', 'CUT', 'DOG', 'ING']),
    const MapEntry('ABCD', ['CART', 'CANT', 'RING', 'INDEX', 'INDEXES']),
    const MapEntry("AB'C", ["CAN'T"]),
  ];

  List<List<String>> results(String query) => [
    for (final entry in searchDictionaryEntries(entries, query))
      [entry.key, ...entry.value],
  ];

  test('plain queries search by prefix and ignore case', () {
    expect(results(' ind '), [
      ['ABCD', 'INDEX', 'INDEXES'],
    ]);
    expect(results(''), isEmpty);
    expect(results('missing'), isEmpty);
  });

  test('question mark matches exactly one letter', () {
    expect(results('C?T'), [
      ['ABC', 'CAT', 'COT', 'CUT'],
    ]);
    expect(results('C??T'), [
      ['ABCD', 'CART', 'CANT'],
    ]);
    expect(results('C?'), isEmpty);
  });

  test('asterisk matches zero or more letters', () {
    expect(results('C*T'), [
      ['ABC', 'CAT', 'COT', 'CUT'],
      ['ABCD', 'CART', 'CANT'],
    ]);
    expect(results('*ING'), [
      ['ABC', 'ING'],
      ['ABCD', 'RING'],
    ]);
    expect(results("CAN'T"), [
      ["AB'C", "CAN'T"],
    ]);
    expect(
      results('C*T').expand((entry) => entry.skip(1)),
      isNot(contains("CAN'T")),
    );
  });

  test('wildcards also match Spanish enye', () {
    final spanish = PatternMap.fromList(spanishWordList).visibleEntries();
    expect(
      searchDictionaryEntries(spanish, 'MA?ANA').expand((entry) => entry.value),
      contains('MAÑANA'),
    );
    expect(
      searchDictionaryEntries(spanish, '*ÑO').expand((entry) => entry.value),
      contains('SUEÑO'),
    );
  });

  test('repeated stars do not backtrack through long nonmatches', () {
    final manyStars = List.filled(24, '*').join();
    final longWords = [
      const MapEntry('A', ['ELECTROENCEPHALOGRAPHIC']),
    ];
    expect(searchDictionaryEntries(longWords, '${manyStars}ZZ'), isEmpty);
    expect(
      searchDictionaryEntries(longWords, '${manyStars}GRAPHIC').single.value,
      ['ELECTROENCEPHALOGRAPHIC'],
    );
  });
}
