import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:scioly_codebusters/library.dart';

const _englishCodes = {
  'ALT',
  'ANS',
  'ASAP',
  'BBL',
  'BPM',
  'BPS',
  'CEO',
  'CORP',
  'CPS',
  'CWT',
  'DDS',
  'DNA',
  'EDS',
  'EMF',
  'ESP',
  'EST',
  'ETC',
  'FPS',
  'FTP',
  'FTPING',
  'FTPS',
  'IE',
  'INC',
  'INST',
  'KPH',
  'MPH',
  'MR',
  'MRS',
  'MS',
  'PC',
  'PCT',
  'PM',
  'RPM',
  'SOS',
  'STD',
  'TV',
  'UHF',
  'VHF',
  'VLF',
  'VS',
  'WPM',
};
const _englishPluralOnly = {'DOS', 'RES'};
final _romanNumeral = RegExp(
  r'^M{0,4}(CM|CD|D?C{0,3})(XC|XL|L?X{0,3})(IX|IV|V?I{0,3})$',
);

bool isIndexedEnglishWord(String word) {
  final upper = word.toUpperCase();
  return !_englishCodes.contains(upper) &&
      (upper.length < 3 || upper == 'MIX' || !_romanNumeral.hasMatch(upper));
}

final _displayedEnglishWords = Expando<List<String>>();

List<String> get englishDisplayedBaseWords {
  final database = appDatabase;
  if (database == null) throw StateError('Dictionary is not initialized.');
  return _displayedEnglishWords[database] ??= database
      .dictionaryWords(Language.english)
      .where((word) => word != 'AIDS' && isIndexedEnglishWord(word))
      .toList(growable: false);
}

bool _isIndependentEnglishWord(String word) =>
    isIndexedEnglishWord(word) &&
    !_englishPluralOnly.contains(word.toUpperCase());

class PatternMapProvider extends FamilyNotifier<PatternMap, String> {
  @override
  PatternMap build(String arg) {
    if (arg == "english") {
      final words = appDatabase!.dictionary(Language.english);
      return PatternMap.fromList(
        [
          ...englishDisplayedBaseWords,
          ...words.headwords.where(_isIndependentEnglishWord),
        ],
        irregularPlurals: words.irregularPlurals.where(isIndexedEnglishWord),
        regularPlurals: words.regularPlurals.where(isIndexedEnglishWord),
        verbForms: words.verbForms.where(isIndexedEnglishWord),
        descriptiveForms: words.descriptiveForms.where(isIndexedEnglishWord),
      );
    } else {
      return PatternMap.fromList(
        appDatabase!.dictionaryWords(Language.spanish),
      );
    }
  }

  void addWord(String word) {
    state.addWord(word);
    state = state.copy();
  }
}

final patternMapProvider =
    NotifierProvider.family<PatternMapProvider, PatternMap, String>(
      PatternMapProvider.new,
    );
