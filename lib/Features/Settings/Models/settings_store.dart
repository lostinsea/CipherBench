import 'package:flutter/foundation.dart';
import 'package:scioly_codebusters/Features/Quotes/Util/app_database.dart';
import 'package:scioly_codebusters/Features/Settings/Models/setting_prefs.dart';

class SettingsStore extends ValueNotifier<SettingPrefs> {
  SettingsStore(this.database) : super(database.readSettings());

  final AppDatabase database;

  SettingPrefs get prefs => value;

  Future<void> save(SettingPrefs updated) async {
    database.saveSettings(updated);
    value = updated;
  }
}
