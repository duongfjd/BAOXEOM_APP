class Article {
  final int id;
  final String url;
  final String? originalTitle;
  final String titleVi;
  final String summaryVi;
  final String category;
  final DateTime publishedAt;
  final String sourceName;
  final String? author;
  final String? urlToImage;
  final String? fullContentVi;

  Article({
    required this.id,
    required this.url,
    this.originalTitle,
    required this.titleVi,
    required this.summaryVi,
    required this.category,
    required this.publishedAt,
    required this.sourceName,
    this.author,
    this.urlToImage,
    this.fullContentVi,
  });

  factory Article.fromMap(Map<String, dynamic> map) {
    return Article(
      id: map['id'] as int,
      url: map['url'] as String,
      originalTitle: map['original_title'] as String?,
      titleVi: map['title_vi'] as String,
      summaryVi: map['summary_vi'] as String,
      category: map['category'] as String,
      publishedAt: DateTime.parse(map['published_at'] as String),
      sourceName: map['source_name'] as String,
      author: map['author'] as String?,
      urlToImage: map['url_to_image'] as String?,
      fullContentVi: map['full_content_vi'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'url': url,
      'original_title': originalTitle,
      'title_vi': titleVi,
      'summary_vi': summaryVi,
      'category': category,
      'published_at': publishedAt.toIso8601String(),
      'source_name': sourceName,
      'author': author,
      'url_to_image': urlToImage,
      'full_content_vi': fullContentVi,
    };
  }
}
