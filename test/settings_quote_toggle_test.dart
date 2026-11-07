import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:scioly_codebusters/Features/Game Setup/Util/game_setup_library.dart';
import 'package:scioly_codebusters/Features/Game/Shared/Models/game.dart';
import 'package:scioly_codebusters/Features/Quotes/Models/solved_quote.dart';
import 'package:scioly_codebusters/Features/Quotes/Util/quote_library.dart';
import 'package:scioly_codebusters/Features/Settings/Models/setting_prefs.dart';
import 'package:scioly_codebusters/Features/Settings/settings.dart';
import 'package:scioly_codebusters/Shared/widgets/heading_widget.dart';
import 'package:scioly_codebusters/theme.dart';

class _ThreeFieldPrefsReader implements BinaryReader {
  int _byteCall = 0;
  int _valueCall = 0;

  @override
  int readByte() {
    if (_byteCall++ == 0) {
      return 3;
    }
    return const [0, 1, 2][_byteCall - 2];
  }

  @override
  dynamic read([int? typeId]) => [false, 0.4, false][_valueCall++];

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  late Box<SettingPrefs> settings;

  setUpAll(() async {
    Hive.init(null);
    Hive.registerAdapter(SolvedQuoteAdapter());
    Hive.registerAdapter(SettingPrefsAdapter());
    settings = await Hive.openBox<SettingPrefs>(
      'settings',
      bytes: Uint8List(0),
    );
    settingsBox = settings;
  });

  tearDownAll(() async {
    settingsBox = null;
    await Hive.close();
  });

  test('reads legacy three-field preferences with quote skipping enabled', () {
    final migrated = SettingPrefsAdapter().read(_ThreeFieldPrefsReader());

    expect(migrated.isBgMusicOn, isFalse);
    expect(migrated.bgVolume, 0.4);
    expect(migrated.bgMatrixOn, isFalse);
    expect(migrated.skipCompletedQuotes, isTrue);
  });

  testWidgets('persists the skip-completed-quotes switch', (tester) async {
    settingsBox = settings;
    await settings.put('prefs', SettingPrefs());

    await tester.pumpWidget(
      MaterialApp(theme: AppTheme.theme, home: Settings()),
    );
    await tester.pump();

    final heading = tester.widget<HeadingWidget>(
      find.byWidgetPredicate(
        (widget) =>
            widget is HeadingWidget && widget.title == 'Skip completed quotes',
      ),
    );
    expect(heading.neonColor, AppTheme.logoGreen);
    final headingTitle = tester.widget<Text>(
      find.text('SKIP COMPLETED QUOTES'),
    );
    expect(headingTitle.style?.color, AppTheme.logoGreen);
    expect(headingTitle.style?.fontFamily, 'JetBrainsMonoBold');
    expect(
      tester
          .widget<Text>(
            find.text('New puzzles use quotes you have not solved yet.'),
          )
          .style
          ?.color,
      Colors.white70,
    );
    expect(
      tester.widget<SwitchListTile>(find.byType(SwitchListTile)).value,
      isTrue,
    );

    await tester.tap(find.text('SKIP COMPLETED QUOTES'));
    await tester.pump();

    expect(settings.get('prefs')!.skipCompletedQuotes, isFalse);
    expect(
      tester.widget<SwitchListTile>(find.byType(SwitchListTile)).value,
      isFalse,
    );
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
  });

  test(
    'GameSetup skips all persisted completed quotes unless the toggle is off',
    () async {
      settingsBox = settings;
      final completedQuotes = await Hive.openBox<SolvedQuote>(
        'quotesBox',
        bytes: Uint8List(0),
      );
      final assetBytes = File(
        'assets\\quotes\\englishQuotes.json',
      ).readAsBytesSync();
      final messenger =
          TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
      messenger.setMockMessageHandler('flutter/assets', (message) async {
        final assetName = utf8.decode(
          message!.buffer.asUint8List(
            message.offsetInBytes,
            message.lengthInBytes,
          ),
        );
        return assetName == 'assets/quotes/englishQuotes.json'
            ? ByteData.sublistView(assetBytes)
            : null;
      });
      addTearDown(
        () => messenger.setMockMessageHandler('flutter/assets', null),
      );
      final englishQuotes = jsonDecode(utf8.decode(assetBytes)) as Map;
      expect(englishQuotes, hasLength(1007));

      await completedQuotes.addAll(
        englishQuotes.values.cast<Map>().map(
          (quote) => SolvedQuote(
            text: quote['quote'] as String,
            author: quote['author'] as String,
            rating: 0,
            solveTime: 0,
            gameMode: 'assisted',
            date: DateTime(2026),
          ),
        ),
      );
      await settings.put('prefs', SettingPrefs());

      await expectLater(
        GameSetup.buildCryptogram(
          GameMode.assisted,
          Language.english,
          'Aristocrat',
        ),
        throwsA(isA<NoUnseenQuotesException>()),
      );

      await settings.put(
        'prefs',
        settings.get('prefs')!.copyWith(skipCompletedQuotes: false),
      );
      final game = await GameSetup.buildCryptogram(
        GameMode.assisted,
        Language.english,
        'Aristocrat',
      );

      expect(game.quote.ogQuote, isNotEmpty);
      expect(
        completedQuotes.values.map((quote) => quote.text),
        contains(game.quote.ogQuote),
      );
    },
  );
}
