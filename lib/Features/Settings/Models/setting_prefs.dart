class SettingPrefs {
  bool isBgMusicOn;

  double bgVolume;

  bool bgMatrixOn;

  bool skipCompletedQuotes;

  bool frequencyWordOrder;

  bool useExtendedQuoteCollection;

  SettingPrefs({
    this.isBgMusicOn = true,
    this.bgVolume = 1.0,
    this.bgMatrixOn = true,
    this.skipCompletedQuotes = true,
    this.frequencyWordOrder = true,
    this.useExtendedQuoteCollection = true,
  });

  SettingPrefs copyWith({
    bool? isBgMusicOn,
    double? bgVolume,
    bool? bgMatrixOn,
    bool? skipCompletedQuotes,
    bool? frequencyWordOrder,
    bool? useExtendedQuoteCollection,
  }) {
    return SettingPrefs(
      isBgMusicOn: isBgMusicOn ?? this.isBgMusicOn,
      bgVolume: bgVolume ?? this.bgVolume,
      bgMatrixOn: bgMatrixOn ?? this.bgMatrixOn,
      skipCompletedQuotes: skipCompletedQuotes ?? this.skipCompletedQuotes,
      frequencyWordOrder: frequencyWordOrder ?? this.frequencyWordOrder,
      useExtendedQuoteCollection:
          useExtendedQuoteCollection ?? this.useExtendedQuoteCollection,
    );
  }
}
