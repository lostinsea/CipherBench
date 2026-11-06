import 'package:scioly_codebusters/library.dart';

extension CellHelpers on List<Cell> {
  List<Cell> markCorrect() => map(
    (cell) => cell.copyWith(isCorrect: cell.text == cell.plainText),
  ).toList();

  List<Cell> markIncorrect() =>
      map((cell) => cell.copyWith(isCorrect: false)).toList();

  List<Cell> markDuplicates() {
    final Map<String, Set<String>> textToCiphers = {};
    for (final cell in this) {
      textToCiphers.putIfAbsent(cell.text, () => <String>{}).add(cell.cipher);
    }
    final Set<String> duplicateTexts = textToCiphers.entries
        .where((entry) => entry.value.length > 1)
        .map((entry) => entry.key)
        .toSet();
    return map(
      (cell) => cell.copyWith(isDuplicate: duplicateTexts.contains(cell.text)),
    ).toList();
  }

  List<Cell> setLetter(int idx, String letter) {
    if (idx < 0 || idx >= length) return this;
    return map(
      (cell) => cell.copyWith(text: cell.isLit ? letter : cell.text),
    ).toList();
  }

  List<Cell> selectCell(int idx) {
    if (idx < 0 || idx >= length) return this;
    return map(
      (cell) => cell.copyWith(isSelected: false, isLit: false),
    ).toList()..[idx] = this[idx].copyWith(isSelected: true, isLit: true);
  }

  List<Cell> highlightCells(int idx) => map(
    (cell) => cell.copyWith(isLit: cell.cipher == this[idx].cipher),
  ).toList();

  List<Cell> reset() {
    return map(
      (cell) => cell.copyWith(
        text: cell.isException ? cell.text : "",
        isDuplicate: false,
        isCorrect: false,
      ),
    ).toList();
  }
}
