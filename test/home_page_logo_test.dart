import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:scioly_codebusters/Features/Settings/Models/setting_prefs.dart';
import 'package:scioly_codebusters/library.dart';

late Directory _hiveDirectory;
late Box<SettingPrefs> _testSettingsBox;

Future<void> _pumpHomePage(WidgetTester tester, Size size) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  await tester.pumpWidget(
    ProviderScope(
      child: MaterialApp(
        theme: AppTheme.theme,
        navigatorObservers: [routeObserver],
        home: const HomePage(),
      ),
    ),
  );
  await tester.pump();
}

Finder _homeLogo() => find.byType(HomeLogo);

void _expectLogoAsset(WidgetTester tester, String path) {
  final image = tester.widget<Image>(
    find.descendant(of: _homeLogo(), matching: find.byType(Image)),
  );
  expect(
    image.image,
    isA<AssetImage>().having((asset) => asset.assetName, 'assetName', path),
  );
}

Finder _button(String label) {
  return find.ancestor(of: find.text(label), matching: find.byType(InkWell));
}

const _homeButtonLabels = [
  'Aristocrat',
  'Patristocrat',
  'Xenocrypt',
  'View Dictionary',
  'View Solved Puzzles',
];

void main() {
  setUpAll(() async {
    _hiveDirectory = await Directory.systemTemp.createTemp(
      'codebusters-home-logo-',
    );
    Hive.init(_hiveDirectory.path);
    if (!Hive.isAdapterRegistered(3)) {
      Hive.registerAdapter(SettingPrefsAdapter());
    }
    _testSettingsBox = await Hive.openBox<SettingPrefs>('settings');
    settingsBox = _testSettingsBox;
    await _testSettingsBox.put('prefs', SettingPrefs(bgMatrixOn: false));
  });

  tearDownAll(() async {
    settingsBox = null;
    await _testSettingsBox.close();
    await Hive.close();
    await _hiveDirectory.delete(recursive: true);
  });

  group('HomePage logo layout', () {
    testWidgets('Windows positions a 96px logo in the lower-left strip', (
      tester,
    ) async {
      debugDefaultTargetPlatformOverride = TargetPlatform.windows;
      try {
        await _pumpHomePage(tester, const Size(1100, 720));

        expect(_homeLogo(), findsOneWidget);
        final logoRect = tester.getRect(_homeLogo());
        expect(logoRect.size, const Size(96, 96));
        expect(logoRect.left, 26);
        expect(logoRect.bottom, 699);
        _expectLogoAsset(tester, 'assets/image/cipherbench-mark.png');

        for (final label in _homeButtonLabels) {
          expect(_button(label), findsOneWidget);
          expect(tester.getRect(_button(label)).overlaps(logoRect), isFalse);
        }
        expect(find.text('WINDOWS DESKTOP'), findsNothing);
        expect(tester.takeException(), isNull);
      } finally {
        debugDefaultTargetPlatformOverride = null;
      }
    });

    testWidgets('Windows keeps an 80px logo clear of buttons at 800 by 600', (
      tester,
    ) async {
      debugDefaultTargetPlatformOverride = TargetPlatform.windows;
      try {
        await _pumpHomePage(tester, const Size(800, 600));

        final logoRect = tester.getRect(_homeLogo());
        expect(logoRect.size, const Size(80, 80));
        expect(logoRect.left, 26);
        expect(logoRect.bottom, 579);

        for (final label in _homeButtonLabels) {
          expect(tester.getRect(_button(label)).overlaps(logoRect), isFalse);
        }
        expect(find.text('WINDOWS DESKTOP'), findsNothing);
        expect(tester.takeException(), isNull);
      } finally {
        debugDefaultTargetPlatformOverride = null;
      }
    });

    testWidgets(
      'mobile keeps the original centered logo in the scroll column',
      (tester) async {
        debugDefaultTargetPlatformOverride = TargetPlatform.android;
        try {
          await _pumpHomePage(tester, const Size(800, 600));

          final logoRect = tester.getRect(_homeLogo());
          expect(logoRect.size, const Size(400, 400));
          expect(logoRect.center.dx, 400);
          expect(logoRect.top, 111);
          _expectLogoAsset(tester, 'assets/image/scioly-logo.png');
          expect(
            tester.getRect(_button('Aristocrat')).top,
            greaterThan(logoRect.bottom),
          );
          expect(tester.takeException(), isNull);
        } finally {
          debugDefaultTargetPlatformOverride = null;
        }
      },
    );
  });
}
