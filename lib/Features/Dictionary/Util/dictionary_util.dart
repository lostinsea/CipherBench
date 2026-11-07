import 'package:scioly_codebusters/library.dart';

String getPatternKey(String word) {
  Map<String, String> letterMap = {};
  int nextCharCode = 'A'.codeUnitAt(0);
  StringBuffer pattern = StringBuffer();

  for (var ch in word.toLowerCase().split('')) {
    if (ch == "'") {
      pattern.write("'");
      continue;
    } else if (ch == "-") {
      pattern.write("-");
      continue;
    }
    if (!letterMap.containsKey(ch)) {
      letterMap[ch] = String.fromCharCode(nextCharCode++);
    }
    pattern.write(letterMap[ch]);
  }
  return pattern.toString();
}

List<String> getSuggestedWords(
  List<Cell> cells,
  int wordStart,
  Map<String, List<String>> dictionary, {
  bool Function(String)? includeWord,
}) {
  if (cells.isEmpty) {
    return [];
  }
  String typed = "";
  for (int j = wordStart; !cells[j].isException; j++) {
    typed += cells[j].text == "" ? "*" : cells[j].text;
  }
  final words = dictionary[getPatternKey(getWord(wordStart, cells))] ?? [];
  return words.where((word) {
    if (includeWord != null && !includeWord(word)) return false;
    for (int j = 0; j < typed.length; j++) {
      if (typed[j] != "*" && word[j].toUpperCase() != typed[j]) return false;
    }
    return true;
  }).toList();
}

int getWordStart(int i, List<Cell> cells) {
  if (cells.isEmpty || i < 0 || i >= cells.length) {
    return 0;
  }
  while (i >= 0 &&
      (!cells[i].isException ||
          cells[i].plainText == "'" ||
          cells[i].plainText == "-")) {
    i--;
  }
  return i + 1;
}

String getWord(int wordStart, List<Cell> cells) {
  if (cells.isEmpty || wordStart < 0 || wordStart >= cells.length) {
    return "";
  }
  String word = "";
  for (
    int i = wordStart;
    i < cells.length &&
        (!cells[i].isException ||
            cells[i].plainText == "'" ||
            cells[i].plainText == "-");
    i++
  ) {
    word += cells[i].plainText;
  }
  return word;
}
