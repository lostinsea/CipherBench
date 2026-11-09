import 'dart:math';
import 'package:scioly_codebusters/library.dart';
export 'quote_types.dart';

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
  bool skipCompletedQuotes = true,
  bool useExtendedQuoteCollection = true,
}) async {
  final database = appDatabase;
  if (database == null) throw StateError('Quote database is not initialized.');
  final selected = database.randomQuote(
    language,
    skipCompletedQuotes: skipCompletedQuotes,
    useExtendedQuoteCollection: useExtendedQuoteCollection,
  );
  final tempOgQuote = selected.text;
  final tempAuthor = selected.author;
  String tempPlainText = removeAccentsButKeepEnye(tempOgQuote.toUpperCase());
  Map<String, String> tempKey = generateKey(tempPlainText, language);
  String tempCipherText = generateCipherText(tempPlainText, tempKey);
  Map<String, int> tempFrequencies = getFrequencies(tempPlainText);
  return Quote(
    id: selected.id,
    ogQuote: tempOgQuote,
    author: tempAuthor,
    plainText: tempPlainText,
    key: tempKey,
    cipherText: tempCipherText,
    frequencies: tempFrequencies,
  );
}
