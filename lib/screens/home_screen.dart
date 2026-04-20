import 'package:flutter/material.dart';
import '../models/article.dart';
import '../services/mock_service.dart';
import '../utils/constants.dart';
import '../widgets/article_card.dart';
import '../widgets/hot_news_carousel.dart';
import '../widgets/shimmer_loading.dart';
import 'article_detail_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool _isLoading = true;
  List<Article> _articles = [];
  List<Article> _hotNews = [];
  String _selectedCategory = 'Tất cả';

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
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    // Simulate API delay
    await Future.delayed(const Duration(seconds: 2));
    if (mounted) {
      setState(() {
        _articles = MockService.getMockArticles();
        _hotNews = MockService.getHotNews();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _loadData,
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
                                'Chào buổi sáng,',
                                style: Theme.of(context).textTheme.bodyMedium,
                              ),
                              Text(
                                'Tin tức hôm nay',
                                style: Theme.of(context).textTheme.displayLarge?.copyWith(
                                      fontSize: 28,
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
                        decoration: InputDecoration(
                          hintText: 'Tìm kiếm tin tức...',
                          prefixIcon: const Icon(Icons.search_rounded),
                          filled: true,
                          fillColor: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.3),
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
                      final isSelected = _selectedCategory == category;
                      return Padding(
                        padding: const EdgeInsets.only(right: AppConstants.space8),
                        child: FilterChip(
                          label: Text(category),
                          selected: isSelected,
                          onSelected: (selected) {
                            setState(() => _selectedCategory = category);
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
              if (!_isLoading)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: AppConstants.space24),
                    child: HotNewsCarousel(
                      articles: _hotNews,
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
              if (_isLoading)
                const SliverToBoxAdapter(child: ShimmerLoading())
              else
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: AppConstants.space16),
                   sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        return ArticleCard(
                          article: _articles[index],
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => ArticleDetailScreen(article: _articles[index]),
                              ),
                            );
                          },
                        );
                      },
                      childCount: _articles.length,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
