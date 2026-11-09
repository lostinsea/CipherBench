import 'dart:developer' as dev;
import 'dart:ui' show AppExitResponse;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'library.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logging/logging.dart';

final RouteObserver<ModalRoute<void>> routeObserver =
    RouteObserver<ModalRoute<void>>();
void main() async {
  Logger.root.level = kDebugMode ? Level.FINE : Level.INFO;
  Logger.root.onRecord.listen((record) {
    dev.log(
      record.message,
      time: record.time,
      level: record.level.value,
      name: record.loggerName,
      zone: record.zone,
      error: record.error,
      stackTrace: record.stackTrace,
    );
  });

  WidgetsFlutterBinding.ensureInitialized();
  appDatabase = await AppDatabase.open();
  settingsStore = SettingsStore(appDatabase!);

  AudioController? audioController;
  if (!kIsWeb) {
    audioController = AudioController();
    await audioController.initialize();
  }
  AppLifecycleListener(
    onExitRequested: () async {
      audioController?.dispose();
      settingsStore?.dispose();
      appDatabase?.close();
      return AppExitResponse.exit;
    },
  );
  runApp(
    ProviderScope(
      child: MaterialApp(
        home: HomePage(audioCont: audioController),
        theme: AppTheme.theme,
        debugShowCheckedModeBanner: false,
        navigatorObservers: [routeObserver],
      ),
    ),
  );
}
