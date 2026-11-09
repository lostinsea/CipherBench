class SolvedQuote {
  final int? completionId;
  final int quoteId;
  final String text;
  final String author;
  final int rating;
  final double solveTime;
  final String gameMode;
  bool isFavorite;
  final DateTime date;

  SolvedQuote({
    this.completionId,
    required this.quoteId,
    required this.text,
    required this.author,
    required this.rating,
    required this.solveTime,
    required this.gameMode,
    required this.date,
    this.isFavorite = false,
  });
}
