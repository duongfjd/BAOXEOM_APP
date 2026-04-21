import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/article.dart';
import '../services/news_service.dart';

final newsServiceProvider = Provider((ref) => NewsService());

class ArticleParams {
  final String? category;
  final String? searchQuery;
  final int limit;
  final int offset;

  ArticleParams({
    this.category,
    this.searchQuery,
    this.limit = 6,
    this.offset = 0,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ArticleParams &&
          runtimeType == other.runtimeType &&
          category == other.category &&
          searchQuery == other.searchQuery &&
          limit == other.limit &&
          offset == other.offset;

  @override
  int get hashCode => category.hashCode ^ searchQuery.hashCode ^ limit.hashCode ^ offset.hashCode;
}

final latestArticlesProvider = FutureProvider.family<List<Article>, ArticleParams>((ref, params) async {
  final service = ref.watch(newsServiceProvider);
  return service.fetchArticles(
    category: params.category,
    searchQuery: params.searchQuery,
    limit: params.limit,
    offset: params.offset,
  );
});

final recommendedArticlesProvider = FutureProvider.family<List<Article>, ArticleParams>((ref, params) async {
  final service = ref.watch(newsServiceProvider);
  return service.fetchArticles(
    category: params.category,
    searchQuery: params.searchQuery,
    limit: params.limit,
    offset: params.offset,
  );
});

final allArticlesProvider = FutureProvider<List<Article>>((ref) async {
  final service = ref.watch(newsServiceProvider);
  return service.fetchArticles(limit: 50); // Fetch a larger chunk for "all articles"
});

final hotNewsProvider = FutureProvider<List<Article>>((ref) async {
  final service = ref.watch(newsServiceProvider);
  return service.fetchHotNews();
});

class SelectedCategoryNotifier extends Notifier<String> {
  @override
  String build() => 'Tất cả';
  
  void update(String value) => state = value;
}

final selectedCategoryProvider = NotifierProvider<SelectedCategoryNotifier, String>(SelectedCategoryNotifier.new);

class SearchQueryNotifier extends Notifier<String> {
  @override
  String build() => '';
  
  void update(String value) => state = value;
}

final searchQueryProvider = NotifierProvider<SearchQueryNotifier, String>(SearchQueryNotifier.new);
