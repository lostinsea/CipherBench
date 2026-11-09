import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:scioly_codebusters/Features/Dictionary/Util/dictionary_search.dart';
import 'package:scioly_codebusters/library.dart';

import 'database_test_utils.dart';

void main() {
  late AppDatabase database;

  setUpAll(() {
    database = openSeedDatabase();
    installDatabase(database);
  });

  tearDownAll(closeInstalledDatabase);

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
    final spanish = PatternMap.fromList(
      database.dictionaryWords(Language.spanish),
    ).visibleEntries();
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

  testWidgets(
    'production Dictionary search reveals a descriptive form after its toggle',
    (tester) async {
      debugDefaultTargetPlatformOverride = TargetPlatform.windows;
      tester.view.physicalSize = const Size(800, 600);
      tester.view.devicePixelRatio = 1;
      try {
        await tester.pumpWidget(
          ProviderScope(
            child: MaterialApp(
              theme: AppTheme.theme,
              home: const Scaffold(
                body: DictionaryTab(
                  dictionaryId: 'english',
                  colors: [Colors.green],
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        await tester.enterText(find.byType(TextField), 'WEER');
        await tester.pump(const Duration(milliseconds: 150));
        final weer = find.descendant(
          of: find.byType(DictionaryWordWidget),
          matching: find.text('WEER'),
        );
        expect(find.text('0 matching words'), findsOneWidget);
        expect(weer, findsNothing);

        await tester.tap(find.byType(Switch).at(2));
        await tester.pumpAndSettle();
        expect(find.text('1 matching words'), findsOneWidget);
        expect(weer, findsOneWidget);
        expect(tester.takeException(), isNull);
      } finally {
        debugDefaultTargetPlatformOverride = null;
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      }
    },
  );
}
