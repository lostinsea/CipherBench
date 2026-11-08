import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:scioly_codebusters/library.dart';

void main() {
  testWidgets('dictionary groups and words are borderless', (tester) async {
    final entryKey = GlobalKey();
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          home: Scaffold(
            body: DictionaryEntryWidget(
              entry: const MapEntry('ABBA', ['DEED', 'NOON']),
              index: 0,
              curColor: AppTheme.logoGreen,
              isEntryHighlighted: false,
              entryKey: entryKey,
              searchTerm: null,
            ),
          ),
        ),
      ),
    );

    expect(tester.widget<Container>(find.byKey(entryKey)).decoration, isNull);
    expect(find.text('ABBA'), findsOneWidget);
    expect(find.text('DEED'), findsOneWidget);
    expect(find.text('NOON'), findsOneWidget);
    final headingFinder = find.descendant(
      of: find.byType(DictionaryEntryWidget),
      matching: find.byType(HeadingWidget),
    );
    expect(tester.widget<HeadingWidget>(headingFinder).showUnderline, isFalse);
    final headingContainer = find
        .descendant(of: headingFinder, matching: find.byType(Container))
        .first;
    expect(tester.widget<Container>(headingContainer).decoration, isNull);
    final wordContainer = find.descendant(
      of: find.byType(DictionaryWordWidget).first,
      matching: find.byType(Container),
    );
    expect(tester.widget<Container>(wordContainer.first).decoration, isNull);
    expect(tester.takeException(), isNull);
  });

  testWidgets('statistics keeps heading underline but no row dividers', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          home: Scaffold(
            body: const StatBoxWidget(
              title: 'All Time',
              num: '01',
              neonColor: AppTheme.logoGreen,
              fastest: '12.00',
              average: '20.00',
              solved: '3',
            ),
          ),
        ),
      ),
    );

    final category = find
        .descendant(
          of: find.byType(StatBoxWidget),
          matching: find.byType(Container),
        )
        .first;
    expect(tester.widget<Container>(category).decoration, isNull);
    expect(find.text('ALL TIME'), findsOneWidget);
    expect(find.text('FASTEST'), findsOneWidget);
    expect(find.text('AVERAGE'), findsOneWidget);
    expect(find.text('TOTAL SOLVED'), findsOneWidget);
    final headingFinder = find.descendant(
      of: find.byType(StatBoxWidget),
      matching: find.byType(HeadingWidget),
    );
    expect(tester.widget<HeadingWidget>(headingFinder).showUnderline, isTrue);
    final headingContainer = find
        .descendant(of: headingFinder, matching: find.byType(Container))
        .first;
    final headingDecoration =
        tester.widget<Container>(headingContainer).decoration! as BoxDecoration;
    expect(headingDecoration.border, isNotNull);
    for (final row in tester.widgetList<StatRowWidget>(
      find.byType(StatRowWidget),
    )) {
      final rowContainer = find
          .descendant(of: find.byWidget(row), matching: find.byType(Container))
          .first;
      expect(tester.widget<Container>(rowContainer).decoration, isNull);
    }
    expect(tester.takeException(), isNull);
  });
}
