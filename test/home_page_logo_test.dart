import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:scioly_codebusters/library.dart';

import 'database_test_utils.dart';

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
    final database = openSeedDatabase();
    installDatabase(database);
    await settingsStore!.save(settingsStore!.prefs.copyWith(bgMatrixOn: false));
  });

  tearDownAll(() async {
    closeInstalledDatabase();
  });

  group('HomePage logo layout', () {
    testWidgets(
      'Windows removes the SYSTEM app bar chrome but keeps Settings available',
      (tester) async {
        debugDefaultTargetPlatformOverride = TargetPlatform.windows;
        try {
          await _pumpHomePage(tester, const Size(1100, 720));

          final appBar = tester.widget<AppBar>(find.byType(AppBar));
          expect(find.text('SYSTEM'), findsNothing);
          expect(appBar.shape, isNull);
          expect(find.byIcon(Icons.settings), findsOneWidget);
          expect(_homeLogo(), findsOneWidget);
          for (final label in _homeButtonLabels) {
            expect(_button(label), findsOneWidget);
          }
          expect(
            tester
                .widgetList<HomeButtonWidget>(find.byType(HomeButtonWidget))
                .every((button) => button.num.isEmpty),
            isTrue,
          );
          expect(find.text('>'), findsNothing);

          await tester.tap(find.byIcon(Icons.settings));
          await tester.pumpAndSettle();

          expect(find.byType(Settings), findsOneWidget);
          expect(find.text('Settings'), findsOneWidget);
          expect(tester.takeException(), isNull);
        } finally {
          debugDefaultTargetPlatformOverride = null;
        }
      },
    );

    testWidgets('Windows positions a 96px logo in the lower-left strip', (
      tester,
    ) async {
      debugDefaultTargetPlatformOverride = TargetPlatform.windows;
      try {
        await _pumpHomePage(tester, const Size(1100, 720));

        expect(_homeLogo(), findsOneWidget);
        final logoRect = tester.getRect(_homeLogo());
        expect(logoRect.size, const Size(96, 96));
        expect(logoRect.left, windowsScreenInset + insetPadding);
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
        expect(logoRect.left, windowsScreenInset + insetPadding);
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
      'Windows home buttons stay compact and centered after narrowing',
      (tester) async {
        debugDefaultTargetPlatformOverride = TargetPlatform.windows;
        try {
          await _pumpHomePage(tester, const Size(1100, 720));
          final wideButtonWidths = <String, double>{
            for (final label in _homeButtonLabels)
              label: tester.getRect(_button(label)).width,
          };

          tester.view.physicalSize = const Size(800, 600);
          await tester.pump();

          for (final label in _homeButtonLabels) {
            final buttonRect = tester.getRect(_button(label));
            expect(buttonRect.width, 300);
            expect(
              buttonRect.width,
              lessThanOrEqualTo(wideButtonWidths[label]!),
            );
            expect(buttonRect.center.dx, 400);
          }
          expect(tester.takeException(), isNull);
        } finally {
          debugDefaultTargetPlatformOverride = null;
        }
      },
    );

    testWidgets(
      'Windows home buttons do not widen across the mobile width boundary',
      (tester) async {
        debugDefaultTargetPlatformOverride = TargetPlatform.windows;
        try {
          await _pumpHomePage(tester, const Size(1001, 600));
          final wideButtonWidths = <String, double>{
            for (final label in _homeButtonLabels)
              label: tester.getRect(_button(label)).width,
          };

          tester.view.physicalSize = const Size(999, 600);
          await tester.pump();

          for (final label in _homeButtonLabels) {
            final buttonRect = tester.getRect(_button(label));
            expect(buttonRect.width, 300);
            expect(
              buttonRect.width,
              lessThanOrEqualTo(wideButtonWidths[label]!),
            );
            expect(buttonRect.center.dx, 499.5);
          }
          expect(tester.takeException(), isNull);
        } finally {
          debugDefaultTargetPlatformOverride = null;
        }
      },
    );

    testWidgets(
      'Windows home buttons do not widen when the window gets taller',
      (tester) async {
        debugDefaultTargetPlatformOverride = TargetPlatform.windows;
        try {
          await _pumpHomePage(tester, const Size(800, 600));

          for (final height in [600.0, 720.0, 1000.0]) {
            tester.view.physicalSize = Size(800, height);
            await tester.pump();

            for (final label in _homeButtonLabels) {
              final buttonRect = tester.getRect(_button(label));
              expect(buttonRect.width, 300);
              expect(buttonRect.center.dx, 400);
            }
          }
          expect(tester.takeException(), isNull);
        } finally {
          debugDefaultTargetPlatformOverride = null;
        }
      },
    );
  });
}
