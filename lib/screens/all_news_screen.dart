import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/article_provider.dart';
import '../utils/constants.dart';
import '../widgets/article_card.dart';
import '../widgets/shimmer_loading.dart';
import 'article_detail_screen.dart';

class AllNewsScreen extends ConsumerWidget {
  const AllNewsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final allArticlesAsyncValue = ref.watch(allArticlesProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Tất cả tin',
          style: Theme.of(context).textTheme.titleLarge,
        ),
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(allArticlesProvider);
        },
        color: Theme.of(context).colorScheme.primary,
        child: allArticlesAsyncValue.when(
          data: (articles) {
            if (articles.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.article_outlined,
                      size: 80,
                      color: Colors.grey.withOpacity(0.5),
                    ),
                    const SizedBox(height: AppConstants.space16),
                    Text(
                      'Chưa có bài báo nào',
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                            color: Colors.grey,
                          ),
                    ),
                  ],
                ),
              );
            }
            return ListView.builder(
              padding: const EdgeInsets.all(AppConstants.space16),
              itemCount: articles.length,
              itemBuilder: (context, index) {
                return ArticleCard(
                  article: articles[index],
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ArticleDetailScreen(
                          article: articles[index],
                        ),
                      ),
                    );
                  },
                );
              },
            );
          },
          loading: () => const Padding(
            padding: EdgeInsets.only(top: AppConstants.space16),
            child: ShimmerLoading(),
          ),
          error: (err, stack) => Center(child: Text('Đã xảy ra lỗi: $err')),
        ),
      ),
    );
  }
}
