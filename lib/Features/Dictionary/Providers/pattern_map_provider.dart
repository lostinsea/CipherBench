import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:scioly_codebusters/library.dart';

class PatternMapProvider extends FamilyNotifier<PatternMap, String> {
  @override
  PatternMap build(String arg) {
    if (arg == "english") {
      return PatternMap.fromList([
        ...englishWordList,
        ...englishIrregularPlurals,
        ...englishIndependentHeadwords,
      ], regularPlurals: englishRegularPlurals);
    } else {
      return PatternMap.fromList(spanishWordList);
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
