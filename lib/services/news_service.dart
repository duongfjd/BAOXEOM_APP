import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/article.dart';

class NewsService {
  final _supabase = Supabase.instance.client;

  Future<List<Article>> fetchArticles({String? category, String? searchQuery, int limit = 20, int offset = 0}) async {
    try {
      var query = _supabase.from('articles').select();

      if (category != null && category != 'Tất cả') {
        query = query.eq('category', category);
      }

      if (searchQuery != null && searchQuery.isNotEmpty) {
        query = query.ilike('title_vi', '%$searchQuery%');
      }

      final response = await query.order('published_at', ascending: false).range(offset, offset + limit - 1);
      return response.map((data) => Article.fromMap(data)).toList();
    } catch (e, stack) {
      throw Exception('Failed to fetch articles: $e');
    }
  }

  Future<List<Article>> fetchHotNews() async {
    try {
      // For now, let's just fetch the 5 latest articles as "Hot News"
      // In a real app, this might be filtered by a 'is_hot' flag
      final response = await _supabase
          .from('articles')
          .select()
          .order('published_at', ascending: false)
          .limit(5);

      return response.map((data) => Article.fromMap(data)).toList();
    } catch (e) {
      throw Exception('Failed to fetch hot news: $e');
    }
  }
}
