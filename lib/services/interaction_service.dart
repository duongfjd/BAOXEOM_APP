import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/article.dart';

class InteractionService {
  final _supabase = Supabase.instance.client;

  // Bookmarks
  Future<List<int>> getUserBookmarks(String userId) async {
    final response = await _supabase
        .from('bookmarks')
        .select('article_id')
        .eq('user_id', userId);
    return (response as List).map((e) => e['article_id'] as int).toList();
  }

  Future<bool> toggleBookmark(String userId, int articleId) async {
    final existing = await _supabase
        .from('bookmarks')
        .select()
        .eq('user_id', userId)
        .eq('article_id', articleId)
        .maybeSingle();

    if (existing != null) {
      // Unbookmark
      await _supabase
          .from('bookmarks')
          .delete()
          .eq('user_id', userId)
          .eq('article_id', articleId);
      return false;
    } else {
      // Bookmark
      await _supabase.from('bookmarks').insert({
        'user_id': userId,
        'article_id': articleId,
      });
      return true;
    }
  }

  Future<List<Article>> fetchBookmarkedArticles(String userId) async {
    final response = await _supabase
        .from('bookmarks')
        .select('..., articles(*)')
        .eq('user_id', userId)
        .order('created_at', ascending: false);

    return (response as List).map((e) => Article.fromMap(e['articles'])).toList();
  }

  // Likes
  Future<List<int>> getUserLikes(String userId) async {
    final response = await _supabase
        .from('likes')
        .select('article_id')
        .eq('user_id', userId);
    return (response as List).map((e) => e['article_id'] as int).toList();
  }

  Future<bool> toggleLike(String userId, int articleId) async {
    final existing = await _supabase
        .from('likes')
        .select()
        .eq('user_id', userId)
        .eq('article_id', articleId)
        .maybeSingle();

    if (existing != null) {
      // Unlike
      await _supabase
          .from('likes')
          .delete()
          .eq('user_id', userId)
          .eq('article_id', articleId);
      return false;
    } else {
      // Like
      await _supabase.from('likes').insert({
        'user_id': userId,
        'article_id': articleId,
      });
      return true;
    }
  }
}
