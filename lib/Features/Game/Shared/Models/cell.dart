class Cell {
  final String text; //user entered letter
  final String cipher; //displayed cryptogram letter
  final String plainText;
  final bool isLit;
  final bool isDuplicate;
  final bool isSelected;
  final bool isException;
  final bool isCorrect;
  final int count;

  Cell({
    required this.text,
    required this.cipher,
    required this.plainText,
    required this.isException,
    this.isLit = false,
    this.isDuplicate = false,
    this.isSelected = false,
    this.isCorrect = false,
    this.count = 0,
  });

  Cell copyWith({
    String? text,
    String? cipher,
    String? plainText,
    bool? isException,
    bool? isLit,
    bool? isDuplicate,
    bool? isSelected,
    bool? isCorrect,
    int? count,
  }) {
    return Cell(
      text: text ?? this.text,
      cipher: cipher ?? this.cipher,
      plainText: plainText ?? this.plainText,
      isException: isException ?? this.isException,
      isLit: isLit ?? this.isLit,
      isDuplicate: isDuplicate ?? this.isDuplicate,
      isSelected: isSelected ?? this.isSelected,
      isCorrect: isCorrect ?? this.isCorrect,
      count: count ?? this.count,
    );
  }
}
