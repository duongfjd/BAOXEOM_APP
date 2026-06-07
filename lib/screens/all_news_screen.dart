import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/article_provider.dart';
import '../utils/constants.dart';
import '../widgets/article_card.dart';
import '../widgets/shimmer_loading.dart';
import 'article_detail_screen.dart';
import '../models/article.dart';

class AllNewsScreen extends ConsumerStatefulWidget {
  const AllNewsScreen({super.key});

  @override
  ConsumerState<AllNewsScreen> createState() => _AllNewsScreenState();
}

class _AllNewsScreenState extends ConsumerState<AllNewsScreen> {
  final List<String> _categories = [
    'Tất cả',
    'Chính trị',
    'Kinh doanh',
    'Công nghệ',
    'Sức khỏe',
    'Thể thao',
    'Giải trí'
  ];

  @override
  Widget build(BuildContext context) {
    final allArticlesAsyncValue = ref.watch(allArticlesProvider);
    final primaryColor = Theme.of(context).colorScheme.primary;

    return Scaffold(
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(allArticlesProvider);
          },
          color: primaryColor,
          child: CustomScrollView(
            slivers: [
              // --- APP BAR CUSTOM ---
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.only(
                    left: AppConstants.space20,
                    right: AppConstants.space20,
                    top: AppConstants.space24,
                    bottom: AppConstants.space16,
                  ),
                  child: Text(
                    'Tất cả tin',
                    style: Theme.of(context).textTheme.displayLarge?.copyWith(
                          fontSize: 32,
                          color: primaryColor,
                        ),
                  ),
                ),
              ),

              // --- FEED ---
              allArticlesAsyncValue.when(
                data: (articles) {
                  if (articles.isEmpty) {
                    return const SliverToBoxAdapter(
                      child: Center(
                        child: Padding(
                          padding: EdgeInsets.all(32),
                          child: Text('Không tìm thấy bài viết nào.'),
                        ),
                      ),
                    );
                  }

                  return SliverPadding(
                    padding: const EdgeInsets.symmetric(horizontal: AppConstants.space20, vertical: 8),
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, index) {
                          final article = articles[index];

                          return ArticleCard(
                            article: article,
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => ArticleDetailScreen(article: article),
                                ),
                              );
                            },
                          );
                        },
                        childCount: articles.length,
                      ),
                    ),
                  );
                },
                loading: () => const SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.all(20),
                    child: ShimmerLoading(),
                  ),
                ),
                error: (err, stack) => SliverToBoxAdapter(
                  child: Center(child: Text('Đã xảy ra lỗi: $err')),
                ),
              ),
              // Khoảng trống an toàn 120px để không bị thanh điều hướng lơ lửng che mất bài báo cuối cùng
              const SliverToBoxAdapter(child: SizedBox(height: 120)),
            ],
          ),
        ),
      ),
    );
  }
}
