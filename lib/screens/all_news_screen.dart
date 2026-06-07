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
    // We can use selectedCategoryProvider and searchQueryProvider if they are available
    // For now, we'll just read from them or fallback to UI state
    final selectedCategory = ref.watch(selectedCategoryProvider);
    final searchQuery = ref.watch(searchQueryProvider);
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
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Tất cả tin',
                        style: Theme.of(context).textTheme.displayLarge?.copyWith(
                              fontSize: 32,
                              color: primaryColor,
                            ),
                      ),
                      Container(
                        decoration: BoxDecoration(
                          color: const Color(0xFFEBE5D9), // Light beige
                          shape: BoxShape.circle,
                        ),
                        child: IconButton(
                          icon: Icon(Icons.filter_alt_outlined, color: primaryColor),
                          onPressed: () {},
                        ),
                      )
                    ],
                  ),
                ),
              ),

              // --- SEARCH BAR ---
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: AppConstants.space20),
                  child: Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFFEBE5D9),
                      borderRadius: BorderRadius.circular(24),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
                    child: TextField(
                      onChanged: (value) => ref.read(searchQueryProvider.notifier).update(value),
                      decoration: InputDecoration(
                        hintText: 'Tìm kiếm tin tức...',
                        hintStyle: TextStyle(color: primaryColor.withOpacity(0.5)),
                        prefixIcon: Icon(Icons.search, color: primaryColor.withOpacity(0.6)),
                        border: InputBorder.none,
                      ),
                    ),
                  ),
                ),
              ),

              // --- CATEGORIES ---
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.only(top: 16, bottom: 8),
                  child: SizedBox(
                    height: 40,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: _categories.length,
                      padding: const EdgeInsets.symmetric(horizontal: AppConstants.space20),
                      itemBuilder: (context, index) {
                        final category = _categories[index];
                        final isSelected = selectedCategory == category;
                        return Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: GestureDetector(
                            onTap: () => ref.read(selectedCategoryProvider.notifier).update(category),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                              decoration: BoxDecoration(
                                color: isSelected ? primaryColor.withOpacity(0.1) : Colors.white,
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: isSelected ? Colors.transparent : Colors.grey.withOpacity(0.2),
                                ),
                              ),
                              child: Text(
                                category,
                                style: TextStyle(
                                  color: isSelected ? primaryColor : primaryColor.withOpacity(0.7),
                                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ),

              // --- FEED ---
              allArticlesAsyncValue.when(
                data: (articles) {
                  // Filter locally if needed
                  final filteredArticles = articles.where((a) {
                    final matchesCategory = selectedCategory == 'Tất cả' || a.category == selectedCategory;
                    final matchesSearch = searchQuery.isEmpty || a.titleVi.toLowerCase().contains(searchQuery.toLowerCase());
                    return matchesCategory && matchesSearch;
                  }).toList();

                  if (filteredArticles.isEmpty) {
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
                    padding: const EdgeInsets.symmetric(horizontal: AppConstants.space20, vertical: 16),
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, index) {
                          final article = filteredArticles[index];

                          // First item is the TIN HOT banner
                          if (index == 0) {
                            return _buildHotNewsBanner(context, article);
                          }

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
                        childCount: filteredArticles.length,
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
              const SliverToBoxAdapter(child: SizedBox(height: 40)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHotNewsBanner(BuildContext context, Article article) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ArticleDetailScreen(article: article),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        width: double.infinity,
        height: 200,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          image: DecorationImage(
            image: CachedNetworkImageProvider(article.urlToImage ?? ''),
            fit: BoxFit.cover,
            colorFilter: ColorFilter.mode(
              Colors.black.withOpacity(0.4),
              BlendMode.darken,
            ),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 16,
              offset: const Offset(0, 8),
            )
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.red.shade700,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Text(
                  'TIN HOT',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Text(
                article.titleVi,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  fontFamily: Theme.of(context).textTheme.titleLarge?.fontFamily,
                  height: 1.3,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
