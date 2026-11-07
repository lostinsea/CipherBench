import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:scioly_codebusters/library.dart';

class GameProvider extends FamilyNotifier<Game, String> {
  @override
  Game build(String arg) {
    return Game(quote: Quote());
  }

  void setSuggestions(bool value) {
    state = state.copyWith(
      showSuggestions: value,
      usedHints: value ? true : state.usedHints,
    );
  }

  void setPopup(bool value) {
    state = state.copyWith(showComplete: value);
  }

  String setLetter(String letter, bool saveHistory) {
    int index = state.selectedIdx;
    String currLetter = state.cells[index].text;
    if (currLetter == letter) {
      nextCell(index - 1);
      return currLetter;
    }
    var newCells = [...state.cells].setLetter(index, letter);
    var newHistory = saveHistory
        ? [...state.history, state.copyWith()]
        : state.history;
    state = state.copyWith(
      cells: newCells,
      history: newHistory,
      isPerfect: currLetter == "" ? state.isPerfect : false,
    );
    nextCell(index - 1);
    if (state.gameMode == GameMode.assisted) markDuplicate();
    if (!state.isCorrect) checkAnswer();
    if (state.showCorrect) markCorrect();
    if (!state.showCorrect) markIncorrect();
    return currLetter;
  }

  void markDuplicate() {
    state = state.copyWith(cells: [...state.cells].markDuplicates());
  }

  void markCorrect() {
    state = state.copyWith(
      cells: [...state.cells].markCorrect(),
      showCorrect: true,
      usedHints: true,
    );
  }

  void markIncorrect() {
    state = state.copyWith(
      cells: [...state.cells].markIncorrect(),
      showCorrect: false,
    );
  }

  void selectCell(int index, {bool immediateScroll = false}) {
    state = state.copyWith(
      cells: [...state.cells].selectCell(index),
      selectedIdx: index,
    );
    if (state.showCorrect) markCorrect();
    if (!state.showCorrect) markIncorrect();
    if (state.gameMode == GameMode.assisted) {
      state = state.copyWith(cells: [...state.cells].highlightCells(index));
    }
    ref
        .read(scrollProvider(arg).notifier)
        .scrollToSelected(index, immediate: immediateScroll);
  }

  //nexCell(-1) goes to first valid cell
  void nextCell(int idx) {
    int og = idx;
    while (idx < state.cells.length - 1) {
      idx++;
      if (idx == og) break;
      if (state.cells[idx].text.isEmpty) {
        selectCell(idx);
        break;
      }
      if (idx == state.cells.length - 1) idx = -1;
    }
  }

  void incrementCell(int increment, {bool immediateScroll = false}) {
    int idx = state.selectedIdx;
    idx += increment;
    while (idx < state.cells.length &&
        idx >= 0 &&
        state.cells[idx].isException) {
      idx += increment;
    }
    if (idx < state.cells.length && idx >= 0) {
      selectCell(idx, immediateScroll: immediateScroll);
    }
  }

  void moveVertical(int direction) {
    final target = ref
        .read(scrollProvider(arg).notifier)
        .verticalNeighbor(state.selectedIdx, direction, state.cells);
    if (target != null) selectCell(target, immediateScroll: true);
  }

  void undo() {
    if (state.history.isEmpty) return;
    bool isCorrect = state.isCorrect;
    bool showCorrect = state.showCorrect;
    bool showSuggestions = state.showSuggestions;
    bool usedHints = state.usedHints;
    int rating = state.rating;
    state = state.history.last;
    state = state.copyWith(
      isCorrect: isCorrect,
      showCorrect: showCorrect,
      usedHints: usedHints,
      showSuggestions: showSuggestions,
      rating: rating,
      isPerfect: false,
    );
    selectCell(state.selectedIdx);
  }

  void reset() {
    final newHistory = [...state.history, state.copyWith()];
    state = state.copyWith(
      cells: [...state.cells].reset(),
      history: newHistory,
      isPerfect: false,
    );
    nextCell(-1);
  }

  void checkAnswer() {
    if (state.isCorrect) return;
    for (int i = 0; i < state.cells.length; i++) {
      if (state.cells[i].text != state.cells[i].plainText) return;
    }
    ref.read(timerProvider(arg).notifier).pause();
    final time = ref.read(timerProvider(arg).notifier).getTime();
    var stars = 2;
    if (state.usedHints == true) {
      stars = 1;
    } else if (state.isPerfect) {
      stars = 3;
    }
    state = state.copyWith(rating: stars);
    final newQuote = SolvedQuote(
      text: state.quote.ogQuote,
      author: state.quote.author,
      rating: stars,
      solveTime: time,
      gameMode: arg,
      date: DateTime.now(),
    );
    ref.read(quoteListProvider.notifier).addQuote(newQuote);
    state = state.copyWith(isCorrect: true, showComplete: true);
    markCorrect();
  }

  void hint() {
    String letter = state.cells[state.selectedIdx].plainText;
    ref.read(keyboardProvider(arg).notifier).pressKey(letter, true);
    state = state.copyWith(usedHints: true);
  }

  void saveHistory() {
    state = state.copyWith(history: [...state.history, state.copyWith()]);
  }

  void destroy() {
    state = Game(quote: Quote(), selectedIdx: -1);
  }

  Future<void> buildCryptogram(
    GameMode gameMode,
    Language language,
    String gameId,
  ) async {
    state = await GameSetup.buildCryptogram(gameMode, language, gameId);
    nextCell(-1);
    ref.read(keyboardProvider(arg).notifier).reset();
    ref.read(timerProvider(arg).notifier).restart();
  }

  //timer widget uses in init state
  bool isCorrect() => state.isCorrect;
  int cellCount() => state.cells.length;

  /* for Patristocrats
  void insertCell(String txt, int idx) {
    final updated = [...state];
    updated.insert(idx, Cell(text: txt, isLit: false, isSelected: false, count: 0));
    state = [...updated];
  }*/

  /*
  void removeCell() {
    if (state.isNotEmpty) {
      state = [...state]..removeLast();
    }
  }*/
}

final gameProvider = NotifierProvider.family<GameProvider, Game, String>(
  GameProvider.new,
);
