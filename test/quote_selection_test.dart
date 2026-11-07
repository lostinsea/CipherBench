import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:scioly_codebusters/Features/Quotes/Util/quote_library.dart';

Map<String, String> _quote(String text) => {'quote': text, 'author': 'Author'};

void main() {
  group('selectQuote', () {
    test('keeps duplicate quote text excluded under every key', () {
      final allQuotes = <String, Map<String, String>>{
        '0': _quote('Already solved'),
        '1': _quote('Already solved'),
        '2': _quote('Unseen quote'),
      };

      final selected = selectQuote(
        allQuotes,
        completedQuoteTexts: {'Already solved'},
        random: Random(1),
      );

      expect(selected, allQuotes['2']);
    });

    test('selects from the full library when no quotes are completed', () {
      final allQuotes = <String, Map<String, String>>{
        '0': _quote('First unseen quote'),
        '1': _quote('Second unseen quote'),
      };

      final selected = selectQuote(allQuotes, random: Random(1));

      expect(allQuotes.values, contains(selected));
    });

    test(
      'throws instead of replaying a quote when all texts are completed',
      () {
        final allQuotes = <String, Map<String, String>>{
          '0': _quote('Completed once'),
          '1': _quote('Completed once'),
          '2': _quote('Completed twice'),
        };

        expect(
          () => selectQuote(
            allQuotes,
            completedQuoteTexts: {'Completed once', 'Completed twice'},
            random: Random(1),
          ),
          throwsA(isA<NoUnseenQuotesException>()),
        );
      },
    );

    test('permits a completed quote when the exclusion set is empty', () {
      final allQuotes = <String, Map<String, String>>{
        '0': _quote('Previously completed quote'),
      };

      final selected = selectQuote(
        allQuotes,
        completedQuoteTexts: const <String>{},
        random: Random(1),
      );

      expect(selected, allQuotes['0']);
    });
  });
}
