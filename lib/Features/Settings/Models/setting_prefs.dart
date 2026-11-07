import 'package:hive/hive.dart';
part 'setting_prefs.g.dart'; // Needed for generated code

@HiveType(typeId: 3)
class SettingPrefs extends HiveObject {
  @HiveField(0)
  bool isBgMusicOn;

  @HiveField(1)
  double bgVolume;

  @HiveField(2)
  bool bgMatrixOn;

  @HiveField(3, defaultValue: true)
  bool skipCompletedQuotes;

  SettingPrefs({
    this.isBgMusicOn = true,
    this.bgVolume = 1.0,
    this.bgMatrixOn = true,
    this.skipCompletedQuotes = true,
  });

  SettingPrefs copyWith({
    bool? isBgMusicOn,
    double? bgVolume,
    bool? bgMatrixOn,
    bool? skipCompletedQuotes,
  }) {
    return SettingPrefs(
      isBgMusicOn: isBgMusicOn ?? this.isBgMusicOn,
      bgVolume: bgVolume ?? this.bgVolume,
      bgMatrixOn: bgMatrixOn ?? this.bgMatrixOn,
      skipCompletedQuotes: skipCompletedQuotes ?? this.skipCompletedQuotes,
    );
  }
}
