import 'package:scioly_codebusters/library.dart';
import 'package:scioly_codebusters/Features/Settings/Models/setting_prefs.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:hive/hive.dart';

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
    final prefs = settingsBox?.get('prefs') as SettingPrefs?;
    final completedQuoteTexts = prefs?.skipCompletedQuotes ?? true
        ? Hive.box<SolvedQuote>(
            'quotesBox',
          ).values.map((quote) => quote.text).toSet()
        : <String>{};
    Quote quote = await getNewQuote(
      language,
      completedQuoteTexts: completedQuoteTexts,
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
