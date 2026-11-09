import 'dart:io';

import 'package:scioly_codebusters/Features/Quotes/Util/app_database.dart';
import 'package:scioly_codebusters/Features/Settings/Models/settings_store.dart';
import 'package:scioly_codebusters/theme.dart';

const seedDatabasePath = 'assets\\quotes\\cipherbench.sqlite3';

AppDatabase openSeedDatabase() =>
    AppDatabase.copySeedIntoMemory(seedDatabasePath);

void installDatabase(AppDatabase database) {
  appDatabase = database;
  settingsStore = SettingsStore(database);
}

void closeInstalledDatabase() {
  settingsStore?.dispose();
  settingsStore = null;
  appDatabase?.close();
  appDatabase = null;
}

File createSeedDatabaseCopy(String name) {
  final file = File('test\\.$name.sqlite3');
  if (file.existsSync()) file.deleteSync();
  return File(seedDatabasePath).copySync(file.path);
}
