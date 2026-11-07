import 'dart:convert';
import 'dart:math';
import 'package:flutter/services.dart';
import 'package:scioly_codebusters/library.dart';

enum Language { english, spanish }

class NoUnseenQuotesException implements Exception {
  const NoUnseenQuotesException();

  @override
  String toString() => 'No unseen quotes remain for this language.';
}

//class QuoteLibrary {
List<String> getAlphabet(Language language) {
  if (language == Language.spanish) {
    return 'abcdefghijklmnopqrstuvwxyzñ'.toUpperCase().split('');
  }
  return 'abcdefghijklmnopqrstuvwxyz'.toUpperCase().split('');
}

//takes in a single character
bool isException(String i, Language language) {
  return !getAlphabet(language).contains(i.toUpperCase());
}

Map<String, String> generateKey(String text, Language language) {
  var alphabet = getAlphabet(language);
  var shuffled = List<String>.from(alphabet);
  final rand = Random();
  // Fisher-Yates shuffle
  for (int i = shuffled.length - 1; i > 0; i--) {
    int j = rand.nextInt(i + 1);
    var temp = shuffled[i];
    shuffled[i] = shuffled[j];
    shuffled[j] = temp;
  }
  // Ensure no letter maps to itself (derangement)
  for (int i = 0; i < alphabet.length; i++) {
    if (shuffled[i] == alphabet[i]) {
      int swapWith = (i == alphabet.length - 1) ? i - 1 : i + 1;
      var temp = shuffled[i];
      shuffled[i] = shuffled[swapWith];
      shuffled[swapWith] = temp;
    }
  }
  // Create a mapping from original alphabet to shuffled alphabet
  Map<String, String> tempKey = {};
  for (int i = 0; i < alphabet.length; i++) {
    tempKey[alphabet[i]] = shuffled[i];
  }
  // Map non-alphabet characters to themselves
  for (String i in text.split('')) {
    if (!alphabet.contains(i)) tempKey[i] = i;
  }
  return tempKey;
}

String generateCipherText(String text, Map<String, String> tempKey) {
  String ans = "";
  for (String i in text.split('')) {
    ans += tempKey[i]!;
  }
  return ans;
}

Map<String, int> getFrequencies(String text) {
  final Map<String, int> tempFrequencies = {};
  for (var char in text.split('')) {
    tempFrequencies[char] = (tempFrequencies[char] ?? 0) + 1;
  }
  return tempFrequencies;
}

Future<Quote> getNewQuote(
  Language language, {
  Set<String> completedQuoteTexts = const {},
}) async {
  Map<dynamic, dynamic>? randQuote;
  String tempOgQuote;
  if (language == Language.spanish) {
    randQuote = await getQuote(
      "assets/quotes/spanishQuotes.json",
      completedQuoteTexts: completedQuoteTexts,
    );
    tempOgQuote =
        "Hola como estas? Espero que estes bien. Este es un ejemplo de cita en español para probar el sistema. Necesito mas palabras para llenar espacio, asi que eso es lo que estoy haciendo. Parece que necesito aun mas palabras. ¿Es esto suficiente? Supongo que solo hay una manera de averiguarlo...";
  } else {
    randQuote = await getQuote(
      "assets/quotes/englishQuotes.json",
      completedQuoteTexts: completedQuoteTexts,
    );
    tempOgQuote =
        "hello, world! What a wonderful time to be alive. Don't you think so? I need some more words to fill space so that is what this is. Looks like I need even more words. Is this enough? I guess there's only one way to find out...";
  }
  // don't delete these comments
  //puzzle one: that, people, without
  tempOgQuote = randQuote["quote"] ?? tempOgQuote;
  // tempOgQuote =
  //     "In photography, everything is so ordinary; it takes a lot of looking before you learn to see the extraordinary.";
  // tempOgQuote = "Sun spreads through the treetops like an epidemic.";
  // tempOgQuote = "Love goes out the door when money comes innuendo.";
  String tempAuthor = randQuote["author"] ?? "Please Try Again";
  // String tempAuthor = "David Bailey";
  // String tempAuthor = "Dave Bonta";
  // String tempAuthor = "Groucho Marx";
  String tempPlainText = removeAccentsButKeepEnye(tempOgQuote.toUpperCase());
  Map<String, String> tempKey = generateKey(tempPlainText, language);
  String tempCipherText = generateCipherText(tempPlainText, tempKey);
  Map<String, int> tempFrequencies = getFrequencies(tempPlainText);
  return Quote(
    ogQuote: tempOgQuote,
    author: tempAuthor,
    plainText: tempPlainText,
    key: tempKey,
    cipherText: tempCipherText,
    frequencies: tempFrequencies,
  );
}

Future<Map> loadQuotes(String file) async {
  String jsonQuotes = await rootBundle.loadString(file);
  Map decoded = jsonDecode(jsonQuotes);
  return decoded;
}

Map selectQuote(
  Map allQuotes, {
  Set<String> completedQuoteTexts = const {},
  Random? random,
}) {
  if (allQuotes.isEmpty) throw StateError('Quote library is empty.');
  final rand = random ?? Random();
  if (completedQuoteTexts.isEmpty) {
    return allQuotes[rand.nextInt(allQuotes.length).toString()] as Map;
  }

  final available = [
    for (final quote in allQuotes.values.cast<Map>())
      if (!completedQuoteTexts.contains(quote['quote'])) quote,
  ];
  if (available.isEmpty) throw const NoUnseenQuotesException();
  return available[rand.nextInt(available.length)];
}

Future<Map> getQuote(
  String file, {
  Set<String> completedQuoteTexts = const {},
}) async {
  final allQuotes = await loadQuotes(file);
  return selectQuote(allQuotes, completedQuoteTexts: completedQuoteTexts);
}
