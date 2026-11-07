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
import 'package:scioly_codebusters/Features/Settings/audio_controller.dart';
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

class _FakeAudioController extends AudioController {
  _FakeAudioController({required bool isPlaying}) : _isPlaying = isPlaying;

  bool _isPlaying;
  int toggleCallCount = 0;
  double? lastVolume;

  @override
  bool isBgPlaying() => _isPlaying;

  @override
  void toggleBgSound({bool updateState = true}) {
    toggleCallCount++;
    _isPlaying = !_isPlaying;
    if (updateState) {
      settingsBox!.put(
        'prefs',
        settingsBox!.get('prefs')!.copyWith(isBgMusicOn: _isPlaying),
      );
    }
  }

  @override
  void setBgVolume(double volume) {
    lastVolume = volume;
  }
}

Finder _heading(String title) {
  return find.byWidgetPredicate(
    (widget) => widget is HeadingWidget && widget.title == title,
  );
}

Finder _switchForHeading(String title) {
  return find.ancestor(
    of: _heading(title),
    matching: find.byType(SwitchListTile),
  );
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
      _heading('Skip completed quotes'),
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
      tester
          .widget<SwitchListTile>(_switchForHeading('Skip completed quotes'))
          .value,
      isTrue,
    );

    await tester.tap(find.text('SKIP COMPLETED QUOTES'));
    await tester.pump();

    expect(settings.get('prefs')!.skipCompletedQuotes, isFalse);
    expect(
      tester
          .widget<SwitchListTile>(_switchForHeading('Skip completed quotes'))
          .value,
      isFalse,
    );
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
  });

  testWidgets('settings switches reflect and persist all preferences', (
    tester,
  ) async {
    settingsBox = settings;
    await settings.put('prefs', SettingPrefs());
    final audio = _FakeAudioController(isPlaying: true);

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.theme,
        home: Settings(audioCont: audio),
      ),
    );
    await tester.pump();

    for (final title in const [
      'Background Music',
      'Matrix Effect',
      'Skip completed quotes',
    ]) {
      expect(_switchForHeading(title), findsOneWidget);
      expect(
        tester.widget<SwitchListTile>(_switchForHeading(title)).value,
        isTrue,
      );
    }

    await tester.tap(_switchForHeading('Background Music'));
    await tester.pump();
    expect(audio.toggleCallCount, 1);
    expect(settings.get('prefs')!.isBgMusicOn, isFalse);
    expect(
      tester
          .widget<SwitchListTile>(_switchForHeading('Background Music'))
          .value,
      isFalse,
    );

    await tester.tap(_switchForHeading('Matrix Effect'));
    await tester.pump();
    expect(settings.get('prefs')!.bgMatrixOn, isFalse);
    expect(
      tester.widget<SwitchListTile>(_switchForHeading('Matrix Effect')).value,
      isFalse,
    );

    await tester.tap(_switchForHeading('Skip completed quotes'));
    await tester.pump();
    expect(settings.get('prefs')!.skipCompletedQuotes, isFalse);
    expect(
      tester
          .widget<SwitchListTile>(_switchForHeading('Skip completed quotes'))
          .value,
      isFalse,
    );
  });

  testWidgets('music slider follows the music switch and does not update off', (
    tester,
  ) async {
    settingsBox = settings;
    await settings.put('prefs', SettingPrefs(bgVolume: 0.4));
    final audio = _FakeAudioController(isPlaying: true);

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.theme,
        home: Settings(audioCont: audio),
      ),
    );
    await tester.pump();

    final slider = find.byType(Slider);
    expect(slider, findsOneWidget);
    expect(
      tester.getTopLeft(slider).dy,
      greaterThanOrEqualTo(
        tester.getBottomLeft(_switchForHeading('Background Music')).dy,
      ),
    );

    await tester.drag(slider, const Offset(80, 0));
    await tester.pump();
    expect(audio.lastVolume, isNotNull);
    expect(settings.get('prefs')!.bgVolume, audio.lastVolume);

    final volumeBeforeDisablingMusic = settings.get('prefs')!.bgVolume;
    await tester.tap(_switchForHeading('Background Music'));
    await tester.pump();

    await tester.drag(slider, const Offset(-80, 0));
    await tester.pump();
    expect(settings.get('prefs')!.bgVolume, volumeBeforeDisablingMusic);
    expect(audio.lastVolume, volumeBeforeDisablingMusic);
  });

  testWidgets('settings headings omit underlines without changing defaults', (
    tester,
  ) async {
    settingsBox = settings;
    await settings.put('prefs', SettingPrefs());

    await tester.pumpWidget(
      MaterialApp(theme: AppTheme.theme, home: Settings()),
    );
    await tester.pump();

    for (final title in const [
      'Background Music',
      'Matrix Effect',
      'Skip completed quotes',
    ]) {
      expect(
        tester.widget<HeadingWidget>(_heading(title)).showUnderline,
        isFalse,
      );
    }

    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: HeadingWidget(neonColor: Colors.white, title: 'Elsewhere'),
        ),
      ),
    );
    expect(
      tester.widget<HeadingWidget>(_heading('Elsewhere')).showUnderline,
      isTrue,
    );
  });

  testWidgets('settings content is centered and compact at Windows sizes', (
    tester,
  ) async {
    settingsBox = settings;
    await settings.put('prefs', SettingPrefs());
    addTearDown(() => tester.binding.setSurfaceSize(null));

    for (final size in const [Size(1100, 720), Size(800, 600)]) {
      await tester.binding.setSurfaceSize(size);
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.theme,
          home: Settings(audioCont: _FakeAudioController(isPlaying: true)),
        ),
      );
      await tester.pump();

      final group = find.byType(ListView);
      final groupBounds = tester.getRect(group);
      final sliderBounds = tester.getRect(find.byType(Slider));
      final musicSwitchBounds = tester.getRect(
        _switchForHeading('Background Music'),
      );
      expect(groupBounds.width, lessThanOrEqualTo(700));
      expect(groupBounds.center.dx, closeTo(size.width / 2, 1));
      expect(sliderBounds.left, closeTo(musicSwitchBounds.left, 1));
      expect(sliderBounds.right, closeTo(musicSwitchBounds.right, 1));
    }
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
