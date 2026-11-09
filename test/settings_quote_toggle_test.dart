import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:scioly_codebusters/Features/Game Setup/Util/game_setup_library.dart';
import 'package:scioly_codebusters/Features/Game/Shared/Models/game.dart';
import 'package:scioly_codebusters/Features/Quotes/Util/app_database.dart';
import 'package:scioly_codebusters/Features/Quotes/Util/quote_types.dart';
import 'package:scioly_codebusters/Features/Settings/audio_controller.dart';
import 'package:scioly_codebusters/Features/Settings/Models/setting_prefs.dart';
import 'package:scioly_codebusters/Features/Settings/Models/settings_store.dart';
import 'package:scioly_codebusters/Features/Settings/settings.dart';
import 'package:scioly_codebusters/Shared/widgets/heading_widget.dart';
import 'package:scioly_codebusters/theme.dart';

import 'database_test_utils.dart';

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
      final store = settingsStore!;
      unawaited(store.save(store.prefs.copyWith(isBgMusicOn: _isPlaying)));
    }
  }

  @override
  void setBgVolume(double volume) {
    lastVolume = volume;
  }
}

Finder _heading(String title) => find.byWidgetPredicate(
  (widget) => widget is HeadingWidget && widget.title == title,
);

Finder _switchForHeading(String title) =>
    find.ancestor(of: _heading(title), matching: find.byType(SwitchListTile));

void main() {
  late AppDatabase database;

  setUp(() {
    database = openSeedDatabase();
    installDatabase(database);
  });

  tearDown(closeInstalledDatabase);

  test(
    'defaults and copyWith preserve the extended quote collection choice',
    () {
      final defaults = SettingPrefs();

      expect(defaults.useExtendedQuoteCollection, isTrue);
      expect(
        defaults
            .copyWith(useExtendedQuoteCollection: false)
            .useExtendedQuoteCollection,
        isFalse,
      );
      expect(defaults.useExtendedQuoteCollection, isTrue);
    },
  );

  testWidgets('persists the skip-completed-quotes switch', (tester) async {
    await tester.pumpWidget(
      MaterialApp(theme: AppTheme.theme, home: Settings()),
    );
    await tester.pump();

    final heading = tester.widget<HeadingWidget>(
      _heading('Skip completed quotes'),
    );
    expect(heading.neonColor, AppTheme.logoGreen);
    expect(
      tester.widget<Text>(find.text('SKIP COMPLETED QUOTES')).style?.color,
      AppTheme.logoGreen,
    );
    expect(
      tester
          .widget<SwitchListTile>(_switchForHeading('Skip completed quotes'))
          .value,
      isTrue,
    );

    await tester.tap(find.text('SKIP COMPLETED QUOTES'));
    await tester.pump();

    expect(settingsStore!.prefs.skipCompletedQuotes, isFalse);
    expect(database.readSettings().skipCompletedQuotes, isFalse);
    expect(
      tester
          .widget<SwitchListTile>(_switchForHeading('Skip completed quotes'))
          .value,
      isFalse,
    );
  });

  testWidgets('settings switches reflect and persist all preferences', (
    tester,
  ) async {
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
      'Use extended quote collection',
      'Skip completed quotes',
      'Frequency based word list order',
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
    expect(settingsStore!.prefs.isBgMusicOn, isFalse);

    await tester.tap(_switchForHeading('Matrix Effect'));
    await tester.pump();
    expect(settingsStore!.prefs.bgMatrixOn, isFalse);

    await tester.ensureVisible(
      _switchForHeading('Use extended quote collection'),
    );
    await tester.tap(_switchForHeading('Use extended quote collection'));
    await tester.pump();
    expect(settingsStore!.prefs.useExtendedQuoteCollection, isFalse);

    await tester.ensureVisible(_switchForHeading('Skip completed quotes'));
    await tester.tap(_switchForHeading('Skip completed quotes'));
    await tester.pump();
    expect(settingsStore!.prefs.skipCompletedQuotes, isFalse);

    await tester.ensureVisible(
      _switchForHeading('Frequency based word list order'),
    );
    await tester.tap(_switchForHeading('Frequency based word list order'));
    await tester.pump();
    expect(settingsStore!.prefs.frequencyWordOrder, isFalse);

    final restartedStore = SettingsStore(database);
    addTearDown(restartedStore.dispose);
    expect(restartedStore.prefs.isBgMusicOn, isFalse);
    expect(restartedStore.prefs.bgMatrixOn, isFalse);
    expect(restartedStore.prefs.useExtendedQuoteCollection, isFalse);
    expect(restartedStore.prefs.skipCompletedQuotes, isFalse);
    expect(restartedStore.prefs.frequencyWordOrder, isFalse);
  });

  testWidgets('music slider follows the music switch and does not update off', (
    tester,
  ) async {
    await settingsStore!.save(settingsStore!.prefs.copyWith(bgVolume: 0.4));
    final audio = _FakeAudioController(isPlaying: true);

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.theme,
        home: Settings(audioCont: audio),
      ),
    );
    await tester.pump();

    final slider = find.byType(Slider);
    await tester.drag(slider, const Offset(80, 0));
    await tester.pump();
    expect(audio.lastVolume, isNotNull);
    expect(settingsStore!.prefs.bgVolume, audio.lastVolume);

    final volumeBeforeDisablingMusic = settingsStore!.prefs.bgVolume;
    await tester.tap(_switchForHeading('Background Music'));
    await tester.pump();
    await tester.drag(slider, const Offset(-80, 0));
    await tester.pump();

    expect(settingsStore!.prefs.bgVolume, volumeBeforeDisablingMusic);
    expect(audio.lastVolume, volumeBeforeDisablingMusic);
  });

  testWidgets('settings headings omit underlines without changing defaults', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(theme: AppTheme.theme, home: Settings()),
    );
    await tester.pump();

    for (final title in const [
      'Background Music',
      'Matrix Effect',
      'Skip completed quotes',
      'Use extended quote collection',
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
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final audio = _FakeAudioController(isPlaying: true);

    for (final size in const [Size(1100, 720), Size(800, 600)]) {
      await tester.binding.setSurfaceSize(size);
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.theme,
          home: Settings(audioCont: audio),
        ),
      );
      await tester.pump();

      final groupBounds = tester.getRect(find.byType(ListView));
      final musicSwitchBounds = tester.getRect(
        _switchForHeading('Background Music'),
      );
      final extendedSwitch = _switchForHeading('Use extended quote collection');
      await tester.ensureVisible(extendedSwitch);
      final extendedSwitchBounds = tester.getRect(extendedSwitch);

      expect(groupBounds.width, lessThanOrEqualTo(700));
      expect(groupBounds.center.dx, closeTo(size.width / 2, 1));
      expect(extendedSwitchBounds.left, closeTo(musicSwitchBounds.left, 1));
      expect(extendedSwitchBounds.right, closeTo(musicSwitchBounds.right, 1));
    }
  });

  test('GameSetup uses persisted quote collection preferences', () async {
    await settingsStore!.save(
      settingsStore!.prefs.copyWith(
        skipCompletedQuotes: false,
        useExtendedQuoteCollection: false,
      ),
    );

    final game = await GameSetup.buildCryptogram(
      GameMode.assisted,
      Language.english,
      'Aristocrat',
    );

    expect(game.quote.id, inInclusiveRange(1, 1007));
  });
}
