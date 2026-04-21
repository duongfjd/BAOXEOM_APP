import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../providers/article_provider.dart';
import '../utils/constants.dart';
import '../widgets/article_card.dart';
import '../widgets/hot_news_carousel.dart';
import '../widgets/recommended_article_card.dart';
import '../widgets/shimmer_loading.dart';
import 'article_detail_screen.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  final List<String> _categories = [
    'Tất cả',
    'Chính trị',
    'Kinh doanh',
    'Công nghệ',
    'Sức khỏe',
    'Thể thao',
    'Giải trí'
  ];

  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final selectedCategory = ref.watch(selectedCategoryProvider);
    final searchQuery = ref.watch(searchQueryProvider);
    
    final articlesAsyncValue = ref.watch(latestArticlesProvider(ArticleParams(
      category: selectedCategory,
      searchQuery: searchQuery,
      limit: 6,
      offset: 0,
    )));
    
    final hotNewsAsyncValue = ref.watch(hotNewsProvider);
    final recommendedAsyncValue = ref.watch(recommendedArticlesProvider(ArticleParams(
      category: selectedCategory,
      searchQuery: searchQuery,
      limit: 6,
      offset: 6,
    )));
    
    final formattedDate = DateFormat('EEEE, dd MMMM, yyyy', 'vi_VN').format(DateTime.now());

    return Scaffold(
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(latestArticlesProvider);
            ref.invalidate(hotNewsProvider);
          },
          color: Theme.of(context).colorScheme.primary,
          child: CustomScrollView(
            slivers: [
              // Header & Search
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(AppConstants.space16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Báo Xe Ôm',
                                style: Theme.of(context).textTheme.displayLarge?.copyWith(
                                      fontSize: 28,
                                      fontWeight: FontWeight.bold,
                                      color: Theme.of(context).colorScheme.primary,
                                    ),
                              ),
                              const SizedBox(height: AppConstants.space4),
                              Text(
                                formattedDate,
                                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                      color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                                    ),
                              ),
                            ],
                          ),
                          Container(
                            decoration: BoxDecoration(
                              color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                              shape: BoxShape.circle,
                            ),
                            child: IconButton(
                              icon: const Icon(Icons.notifications_none_rounded),
                              color: Theme.of(context).colorScheme.primary,
                              onPressed: () {},
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppConstants.space24),
                      // Search Bar
                      TextField(
                        controller: _searchController,
                        onSubmitted: (value) {
                          ref.read(searchQueryProvider.notifier).update(value);
                        },
                        decoration: InputDecoration(
                          hintText: 'Tìm kiếm tin tức...',
                          prefixIcon: const Icon(Icons.search_rounded),
                          suffixIcon: searchQuery.isNotEmpty 
                            ? IconButton(
                                icon: const Icon(Icons.clear_rounded),
                                onPressed: () {
                                  _searchController.clear();
                                  ref.read(searchQueryProvider.notifier).update('');
                                },
                              )
                            : null,
                          filled: true,
                          fillColor: Theme.of(context).colorScheme.surfaceContainerHighest.withOpacity(0.3),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(AppConstants.radius16),
                            borderSide: BorderSide.none,
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            vertical: AppConstants.space16,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Categories
              SliverToBoxAdapter(
                child: SizedBox(
                  height: 50,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: _categories.length,
                    padding: const EdgeInsets.symmetric(horizontal: AppConstants.space16),
                    itemBuilder: (context, index) {
                      final category = _categories[index];
                      final isSelected = selectedCategory == category;
                      return Padding(
                        padding: const EdgeInsets.only(right: AppConstants.space8),
                        child: FilterChip(
                          label: Text(category),
                          selected: isSelected,
                          onSelected: (selected) {
                            ref.read(selectedCategoryProvider.notifier).update(category);
                          },
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(AppConstants.radius24),
                          ),
                          showCheckmark: false,
                          backgroundColor: Theme.of(context).colorScheme.surface,
                          selectedColor: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                          labelStyle: TextStyle(
                            color: isSelected
                                ? Theme.of(context).colorScheme.primary
                                : Theme.of(context).colorScheme.onSurface,
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),

              // Hot News Carousel
              hotNewsAsyncValue.when(
                data: (articles) => SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: AppConstants.space24),
                    child: HotNewsCarousel(
                      articles: articles,
                      onArticleTap: (article) {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => ArticleDetailScreen(article: article),
                          ),
                        );
                      },
                    ),
                  ),
                ),
                loading: () => const SliverToBoxAdapter(child: SizedBox(height: 220, child: Center(child: CircularProgressIndicator()))),
                error: (err, stack) => SliverToBoxAdapter(child: Center(child: Text('Error: $err'))),
              ),

              // Latest News Header
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppConstants.space16,
                    vertical: AppConstants.space8,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Tin mới nhất',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      TextButton(
                        onPressed: () {},
                        child: const Text('Xem tất cả'),
                      ),
                    ],
                  ),
                ),
              ),

              // Feed
              articlesAsyncValue.when(
                data: (articles) => articles.isEmpty 
                  ? const SliverToBoxAdapter(child: Center(child: Padding(padding: EdgeInsets.all(32), child: Text('Không tìm thấy bài viết nào.'))))
                  : SliverPadding(
                      padding: const EdgeInsets.symmetric(horizontal: AppConstants.space16),
                      sliver: SliverList(
                        delegate: SliverChildBuilderDelegate(
                          (context, index) {
                            return ArticleCard(
                              article: articles[index],
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => ArticleDetailScreen(article: articles[index]),
                                  ),
                                );
                              },
                            );
                          },
                          childCount: articles.length,
                        ),
                      ),
                    ),
                loading: () => const SliverToBoxAdapter(child: ShimmerLoading()),
                error: (err, stack) => SliverToBoxAdapter(child: Center(child: Text('Error: $err'))),
              ),

              // Recommended News Header
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(AppConstants.space16),
                  child: Text(
                    'Đề xuất cho bạn',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ),
              ),

              // Recommended News Feed
              recommendedAsyncValue.when(
                data: (articles) => articles.isEmpty 
                  ? const SliverToBoxAdapter(child: SizedBox.shrink())
                  : SliverToBoxAdapter(
                      child: SizedBox(
                        height: 240,
                        child: ListView.builder(
                          scrollDirection: Axis.horizontal,
                          padding: const EdgeInsets.only(left: AppConstants.space16),
                          itemCount: articles.length,
                          itemBuilder: (context, index) {
                            return RecommendedArticleCard(
                              article: articles[index],
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => ArticleDetailScreen(article: articles[index]),
                                  ),
                                );
                              },
                            );
                          },
                        ),
                      ),
                    ),
                loading: () => const SliverToBoxAdapter(child: SizedBox.shrink()),
                error: (err, stack) => SliverToBoxAdapter(child: Center(child: Text('Error: $err'))),
              ),
              const SliverToBoxAdapter(child: SizedBox(height: AppConstants.space32)),
            ],
          ),
        ),
      ),
    );
  }
}
