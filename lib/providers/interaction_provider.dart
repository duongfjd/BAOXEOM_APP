import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/article.dart';
import '../services/interaction_service.dart';
import 'auth_provider.dart';

final interactionServiceProvider = Provider((ref) => InteractionService());

class UserInteractions {
  final Set<int> bookmarkedArticleIds;
  final Set<int> likedArticleIds;

  const UserInteractions({
    this.bookmarkedArticleIds = const {},
    this.likedArticleIds = const {},
  });

  UserInteractions copyWith({
    Set<int>? bookmarkedArticleIds,
    Set<int>? likedArticleIds,
  }) {
    return UserInteractions(
      bookmarkedArticleIds: bookmarkedArticleIds ?? this.bookmarkedArticleIds,
      likedArticleIds: likedArticleIds ?? this.likedArticleIds,
    );
  }
}

class InteractionNotifier extends AsyncNotifier<UserInteractions> {
  @override
  FutureOr<UserInteractions> build() async {
    final authState = ref.watch(authProvider);
    final service = ref.watch(interactionServiceProvider);
    
    if (authState is AsyncData && authState.value != null) {
      final userId = authState.value!.id;
      try {
        final bookmarks = await service.getUserBookmarks(userId);
        final likes = await service.getUserLikes(userId);
        return UserInteractions(
          bookmarkedArticleIds: bookmarks.toSet(),
          likedArticleIds: likes.toSet(),
        );
      } catch (e) {
        // Return default empty on error, but could throw
        return const UserInteractions();
      }
    }
    return const UserInteractions();
  }

  Future<void> toggleBookmark(int articleId) async {
    final authState = ref.read(authProvider);
    if (authState is! AsyncData || authState.value == null) {
      throw Exception('Bạn cần đăng nhập để sử dụng tính năng này.');
    }
    final userId = authState.value!.id;
    
    final currentState = state.value ?? const UserInteractions();
    final updatedBookmarks = Set<int>.from(currentState.bookmarkedArticleIds);
    final isBookmarked = updatedBookmarks.contains(articleId);
    
    if (isBookmarked) {
      updatedBookmarks.remove(articleId);
    } else {
      updatedBookmarks.add(articleId);
    }
    
    // Optimistic update
    state = AsyncValue.data(currentState.copyWith(bookmarkedArticleIds: updatedBookmarks));

    try {
      final service = ref.read(interactionServiceProvider);
      final result = await service.toggleBookmark(userId, articleId);
      if (result != !isBookmarked) {
        // Revert or refresh
        ref.invalidateSelf();
      }
      ref.invalidate(bookmarkedArticlesProvider);
    } catch (e) {
      state = AsyncValue.data(currentState);
      rethrow;
    }
  }

  Future<void> toggleLike(int articleId) async {
    final authState = ref.read(authProvider);
    if (authState is! AsyncData || authState.value == null) {
      throw Exception('Bạn cần đăng nhập để sử dụng tính năng này.');
    }
    final userId = authState.value!.id;
    
    final currentState = state.value ?? const UserInteractions();
    final updatedLikes = Set<int>.from(currentState.likedArticleIds);
    final isLiked = updatedLikes.contains(articleId);
    
    if (isLiked) {
      updatedLikes.remove(articleId);
    } else {
      updatedLikes.add(articleId);
    }
    
    // Optimistic update
    state = AsyncValue.data(currentState.copyWith(likedArticleIds: updatedLikes));

    try {
      final service = ref.read(interactionServiceProvider);
      final result = await service.toggleLike(userId, articleId);
      if (result != !isLiked) {
        ref.invalidateSelf();
      }
    } catch (e) {
      state = AsyncValue.data(currentState);
      rethrow;
    }
  }
}

final interactionProvider = AsyncNotifierProvider<InteractionNotifier, UserInteractions>(InteractionNotifier.new);

final bookmarkedArticlesProvider = FutureProvider<List<Article>>((ref) async {
  final authState = ref.watch(authProvider);
  if (authState is AsyncData && authState.value != null) {
    final service = ref.watch(interactionServiceProvider);
    return service.fetchBookmarkedArticles(authState.value!.id);
  }
  return [];
});
