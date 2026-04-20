import 'package:flutter/material.dart';
import '../models/article.dart';
import '../services/mock_service.dart';
import '../utils/constants.dart';
import '../widgets/article_card.dart';
import 'article_detail_screen.dart';

class BookmarksScreen extends StatelessWidget {
  const BookmarksScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Mocking bookmarked articles for now
    final List<Article> bookmarkedArticles = MockService.getMockArticles().take(3).toList();

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Đã lưu',
          style: Theme.of(context).textTheme.titleLarge,
        ),
      ),
      body: bookmarkedArticles.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.bookmark_border_rounded,
                    size: 80,
                    color: Colors.grey.withOpacity(0.5),
                  ),
                  const SizedBox(height: AppConstants.space16),
                  Text(
                    'Chưa có bài viết nào được lưu',
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: Colors.grey,
                        ),
                  ),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(AppConstants.space16),
              itemCount: bookmarkedArticles.length,
              itemBuilder: (context, index) {
                return ArticleCard(
                  article: bookmarkedArticles[index],
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ArticleDetailScreen(
                          article: bookmarkedArticles[index],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
    );
  }
}
