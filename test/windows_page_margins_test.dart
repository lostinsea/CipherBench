import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:scioly_codebusters/library.dart';

void _expectPageMargins(WidgetTester tester, Finder content, Size size) {
  final bounds = tester.getRect(content);
  expect(bounds.left, greaterThanOrEqualTo(windowsScreenInset));
  expect(size.width - bounds.right, greaterThanOrEqualTo(windowsScreenInset));
  expect(tester.takeException(), isNull);
}

void main() {
  late Directory directory;
  late Box<SolvedQuote> quotes;

  setUpAll(() async {
    directory = await Directory.systemTemp.createTemp(
      'cipherbench-quote-margins-',
    );
    Hive.init(directory.path);
    if (!Hive.isAdapterRegistered(2)) {
      Hive.registerAdapter(SolvedQuoteAdapter());
    }
    quotes = await Hive.openBox<SolvedQuote>('quotesBox');
    await quotes.add(
      SolvedQuote(
        text: 'Example quote',
        author: 'Test',
        rating: 3,
        solveTime: 12,
        gameMode: 'Aristocrat',
        date: DateTime(2026, 1, 1),
        isFavorite: true,
      ),
    );
  });

  tearDownAll(() async {
    await quotes.close();
    await Hive.close();
    await directory.delete(recursive: true);
  });

  testWidgets('Windows instructions keep their content clear of both edges', (
    tester,
  ) async {
    debugDefaultTargetPlatformOverride = TargetPlatform.windows;
    tester.view.devicePixelRatio = 1;
    try {
      for (final size in const [Size(800, 600), Size(1400, 600)]) {
        tester.view.physicalSize = size;
        for (final page in const [
          AristocratInstructionsPage(),
          PatristocratInstructionsPage(),
          XenocryptInstructionsPage(),
        ]) {
          await tester.pumpWidget(
            MaterialApp(theme: AppTheme.theme, home: page),
          );
          await tester.pumpAndSettle();
          final content = find
              .descendant(
                of: find.byType(SingleChildScrollView),
                matching: find.byType(Column),
              )
              .first;
          _expectPageMargins(tester, content, size);
          await tester.pumpWidget(const SizedBox.shrink());
        }
      }
    } finally {
      debugDefaultTargetPlatformOverride = null;
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    }
  });

  testWidgets('Windows solved quote tabs keep cards inside the edge margins', (
    tester,
  ) async {
    debugDefaultTargetPlatformOverride = TargetPlatform.windows;
    tester.view.devicePixelRatio = 1;
    try {
      for (final size in const [Size(800, 600), Size(1400, 600)]) {
        tester.view.physicalSize = size;
        await tester.pumpWidget(
          ProviderScope(
            child: MaterialApp(
              theme: AppTheme.theme,
              home: const QuoteHomePage(),
            ),
          ),
        );
        await tester.pumpAndSettle();
        _expectPageMargins(tester, find.byType(TabBarView), size);
        _expectPageMargins(tester, find.byType(QuoteCard), size);
        await tester.tap(find.text('Favorites'));
        await tester.pumpAndSettle();
        _expectPageMargins(tester, find.byType(QuoteCard), size);
        await tester.pumpWidget(const SizedBox.shrink());
      }
    } finally {
      debugDefaultTargetPlatformOverride = null;
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    }
  });
}
