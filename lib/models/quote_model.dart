class QuoteModel {
  const QuoteModel({
    required this.content,
    required this.author,
    this.source = 'Quotable API',
    this.isFallback = false,
  });

  final String content;
  final String author;
  final String source;
  final bool isFallback;

  factory QuoteModel.fromJson(Map<String, dynamic> json) {
    return QuoteModel(
      content: json['content'] as String? ?? 'Stay focused and keep building.',
      author: json['author'] as String? ?? 'Unknown',
      source: 'Quotable API',
    );
  }

  QuoteModel asFallback() {
    return QuoteModel(
      content: content,
      author: author,
      source: 'Offline quote',
      isFallback: true,
    );
  }
}
