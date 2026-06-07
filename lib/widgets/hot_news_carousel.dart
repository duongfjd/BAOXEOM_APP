import 'package:carousel_slider/carousel_slider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import '../models/article.dart';
import '../utils/constants.dart';

class HotNewsCarousel extends StatelessWidget {
  final List<Article> articles;
  final Function(Article) onArticleTap;

  const HotNewsCarousel({
    super.key,
    required this.articles,
    required this.onArticleTap,
  });

  @override
  Widget build(BuildContext context) {
    return CarouselSlider.builder(
      itemCount: articles.length,
      options: CarouselOptions(
        height: 220,
        viewportFraction: 0.9,
        enlargeCenterPage: true,
        autoPlay: true,
        autoPlayInterval: const Duration(seconds: 5),
      ),
      itemBuilder: (context, index, realIndex) {
        final article = articles[index];
        return GestureDetector(
          onTap: () => onArticleTap(article),
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: AppConstants.space4),
            child: Stack(
              children: [
                // Image Background
                ClipRRect(
                  borderRadius: BorderRadius.circular(AppConstants.radius24),
                  child: CachedNetworkImage(
                    imageUrl: article.urlToImage ?? '',
                    fit: BoxFit.cover,
                    width: double.infinity,
                    height: double.infinity,
                    placeholder: (context, url) => Image.asset(
                      AppConstants.newsPlaceholder,
                      fit: BoxFit.cover,
                    ),
                    errorWidget: (context, url, error) => Image.asset(
                      AppConstants.newsPlaceholder,
                      fit: BoxFit.cover,
                    ),
                    imageBuilder: (context, imageProvider) => Container(
                      decoration: BoxDecoration(
                        image: DecorationImage(
                          image: imageProvider,
                          fit: BoxFit.cover,
                          colorFilter: ColorFilter.mode(
                            Colors.black.withOpacity(0.3),
                            BlendMode.darken,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                // Text Info
                Positioned(
                  bottom: AppConstants.space20,
                  left: AppConstants.space20,
                  right: AppConstants.space20,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppConstants.space8,
                          vertical: AppConstants.space4,
                        ),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.primary,
                          borderRadius: BorderRadius.circular(AppConstants.radius8),
                        ),
                        child: Text(
                          'TIN NÓNG',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            fontFamily: Theme.of(context).textTheme.bodyLarge?.fontFamily,
                          ),
                        ),
                      ),
                      const SizedBox(height: AppConstants.space8),
                      Text(
                        article.titleVi,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          fontFamily: Theme.of(context).textTheme.titleLarge?.fontFamily,
                          height: 1.3,
                        ),
                      ),
                      const SizedBox(height: AppConstants.space4),
                      Text(
                        '${article.sourceName} • ${article.category}',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 12,
                          fontFamily: Theme.of(context).textTheme.bodyMedium?.fontFamily,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
