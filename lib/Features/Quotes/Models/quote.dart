class Quote {
  final int? id;
  final String ogQuote;
  final String author;
  final String cipherText; //should be uppercase
  final String plainText; //should be uppercase
  final Map<String, int> frequencies; // of plainText
  final Map<String, String> key; //plainText -> cipherText

  Quote({
    this.id,
    this.ogQuote = "",
    this.author = "",
    this.cipherText = "",
    this.plainText = "",
    this.frequencies = const {},
    this.key = const {},
  });
}
