enum Language { english, spanish }

class NoUnseenQuotesException implements Exception {
  const NoUnseenQuotesException();

  @override
  String toString() => 'No unseen quotes remain for this language.';
}

class NoEligibleQuotesException implements Exception {
  const NoEligibleQuotesException();

  @override
  String toString() => 'No quotes are available in the selected collection.';
}
