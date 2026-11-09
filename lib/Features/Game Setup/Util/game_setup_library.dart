import 'package:scioly_codebusters/library.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

class GameSetup {
  static double width = 0;
  static double height = 0;

  static void init(BuildContext context) {
    final size = MediaQuery.of(context).size;
    width = size.width;
    height = size.height;
  }

  static Future<Game> buildCryptogram(
    GameMode gameMode,
    Language language,
    String gameId,
  ) async {
    List<Cell> newCells = [];
    final store = settingsStore;
    if (store == null) throw StateError('Settings have not been initialized.');
    final prefs = store.prefs;
    Quote quote = await getNewQuote(
      language,
      skipCompletedQuotes: prefs.skipCompletedQuotes,
      useExtendedQuoteCollection: prefs.useExtendedQuoteCollection,
    );
    for (String i in quote.plainText.split('')) {
      if (isException(i, language) && gameId != "Patristocrat") {
        newCells.add(Cell(text: i, cipher: i, plainText: i, isException: true));
      } else if (gameId != "Patristocrat" || !isException(i, language)) {
        newCells.add(
          Cell(
            text: "",
            cipher: quote.key[i]!,
            plainText: i,
            isException: false,
            count: quote.frequencies[i]!,
          ),
        );
      }
    }

    return Game(quote: quote, cells: newCells, gameMode: gameMode);
  }
}

bool get usePhysicalKeyboard =>
    (!kIsWeb && defaultTargetPlatform == TargetPlatform.windows) ||
    GameSetup.width > mobileMaxWidth;
