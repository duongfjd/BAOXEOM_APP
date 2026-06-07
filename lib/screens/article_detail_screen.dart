import 'dart:ui' show ImageFilter;
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/article.dart';
import '../utils/constants.dart';
import '../providers/interaction_provider.dart';
import 'login_screen.dart';

class FontSizeNotifier extends Notifier<double> {
  @override
  double build() => 1.0;
}

final fontSizeProvider = NotifierProvider<FontSizeNotifier, double>(FontSizeNotifier.new);

class ArticleDetailScreen extends ConsumerWidget {
  final Article article;

  const ArticleDetailScreen({super.key, required this.article});

  Future<void> _launchUrl() async {
    final Uri url = Uri.parse(article.url);
    if (!await launchUrl(url)) {
      throw Exception('Could not launch ${article.url}');
    }
  }

  void _showLoginPrompt(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        action: SnackBarAction(
          label: 'Đăng nhập',
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const LoginScreen()),
            );
          },
        ),
      ),
    );
  }

  void _showFontSizeBottomSheet(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return Consumer(
          builder: (context, ref, child) {
            final multiplier = ref.watch(fontSizeProvider);
            return Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('Chỉnh cỡ chữ', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      const Text('A', style: TextStyle(fontSize: 14)),
                      Expanded(
                        child: Slider(
                          value: multiplier,
                          min: 0.8,
                          max: 1.5,
                          divisions: 7,
                          activeColor: const Color(0xFF00C6FF),
                          onChanged: (val) {
                            ref.read(fontSizeProvider.notifier).state = val;
                          },
                        ),
                      ),
                      const Text('A', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                    ],
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            );
          }
        );
      }
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final interactionsState = ref.watch(interactionProvider);
    final isBookmarked = interactionsState.value?.bookmarkedArticleIds.contains(article.id) ?? false;
    final isLiked = interactionsState.value?.likedArticleIds.contains(article.id) ?? false;
    final fontSizeMultiplier = ref.watch(fontSizeProvider);

    return Scaffold(
      extendBody: true,
      body: Stack(
        children: [
          CustomScrollView(
        slivers: [
          // App Bar with Image
          SliverAppBar(
            expandedHeight: 300,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              background: Hero(
                tag: 'article_image_${article.id}',
                child: CachedNetworkImage(
                  imageUrl: article.urlToImage ?? '',
                  fit: BoxFit.cover,
                  color: Colors.black.withOpacity(0.2),
                  colorBlendMode: BlendMode.darken,
                  placeholder: (context, url) => Image.asset(
                    AppConstants.newsPlaceholder,
                    fit: BoxFit.cover,
                  ),
                  errorWidget: (context, url, error) => Image.asset(
                    AppConstants.newsPlaceholder,
                    fit: BoxFit.cover,
                  ),
                ),
              ),
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.share_outlined),
                onPressed: () => Share.share(article.url),
              ),
              IconButton(
                icon: Icon(isBookmarked ? Icons.bookmark_rounded : Icons.bookmark_border_rounded),
                color: isBookmarked ? Theme.of(context).colorScheme.primary : null,
                onPressed: () async {
                  try {
                    await ref.read(interactionProvider.notifier).toggleBookmark(article.id);
                  } catch (e) {
                    _showLoginPrompt(context, e.toString().replaceAll('Exception: ', ''));
                  }
                },
              ),
            ],
          ),

          // Content
          SliverToBoxAdapter(
            child: Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: Padding(
                padding: const EdgeInsets.all(AppConstants.space20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Category & Date
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppConstants.space12,
                          vertical: AppConstants.space4,
                        ),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(AppConstants.radius24),
                        ),
                        child: Text(
                          article.category,
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.primary,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ),
                      const SizedBox(width: AppConstants.space12),
                      Text(
                        DateFormat('dd MMMM, yyyy').format(article.publishedAt),
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                  const SizedBox(height: AppConstants.space16),

                  // Title
                  Text(
                    article.titleVi,
                    style: Theme.of(context).textTheme.displayLarge?.copyWith(
                          fontSize: 26,
                          height: 1.2,
                        ),
                  ),
                  const SizedBox(height: AppConstants.space16),

                  // Author & Source
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 16,
                        backgroundColor: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                        child: Text(
                          article.sourceName[0],
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.primary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(width: AppConstants.space12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              article.author ?? 'Biên tập viên',
                              style: Theme.of(context).textTheme.titleSmall,
                            ),
                            Text(
                              article.sourceName,
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          ],
                        ),
                      ),
                      OutlinedButton(
                        onPressed: _launchUrl,
                        style: OutlinedButton.styleFrom(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(AppConstants.radius24),
                          ),
                        ),
                        child: const Text('Nguồn gốc'),
                      ),
                    ],
                  ),
                  const Divider(height: AppConstants.space40),

                  // TTS Player Widget
                  TtsPlayerWidget(
                    textToSpeak: '${article.titleVi}. ${article.summaryVi}. ${article.fullContentVi ?? ''}',
                  ),
                  const SizedBox(height: AppConstants.space24),

                  // Summary
                  Container(
                    padding: const EdgeInsets.all(AppConstants.space16),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(AppConstants.radius12),
                      border: Border(
                        left: BorderSide(
                          color: Theme.of(context).colorScheme.primary,
                          width: 4,
                        ),
                      ),
                    ),
                    child: Text(
                      article.summaryVi,
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                            fontStyle: FontStyle.italic,
                            color: Theme.of(context).colorScheme.onSurfaceVariant,
                            fontSize: (16 * fontSizeMultiplier).toDouble(),
                          ),
                    ),
                  ),
                  const SizedBox(height: AppConstants.space24),

                  // Full Content
                  Text(
                    article.fullContentVi ?? 'Nội dung bài viết đang được cập nhật...',
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          fontSize: (18 * fontSizeMultiplier).toDouble(),
                          height: 1.6,
                        ),
                  ),
                  const SizedBox(height: 120), // Thay cho AppConstants.space40 để không bị che bởi thanh lơ lửng
                ],
              ),
            ),
          ),
        ),
        ],
      ),
          // VIÊN THUỐC THỦY TINH LỎNG (LIQUID GLASS)
          Positioned(
            left: 20,
            right: 20,
            bottom: 30, // Khoảng cách cách đáy màn hình
            child: SafeArea(
              child: Container(
                height: 68,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(34),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.04),
                      blurRadius: 24,
                      offset: const Offset(0, 12),
                    ),
                    BoxShadow(
                      color: const Color(0xFF1A3038).withOpacity(0.02),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(34),
                  child: Stack(
                    children: [
                      BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 25.0, sigmaY: 25.0),
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(34),
                          ),
                        ),
                      ),
                      CustomPaint(
                        painter: LiquidGlassBorderPainter(),
                        child: Container(),
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          _buildActionButton(
                            context,
                            isLiked ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                            'Yêu thích',
                            isLiked,
                            () async {
                              try {
                                await ref.read(interactionProvider.notifier).toggleLike(article.id);
                              } catch (e) {
                                _showLoginPrompt(context, e.toString().replaceAll('Exception: ', ''));
                              }
                            },
                          ),
                          _buildActionButton(context, Icons.mode_comment_outlined, 'Bình luận', false, () {}),
                          _buildActionButton(context, Icons.text_fields_rounded, 'Cỡ chữ', false, () {
                            _showFontSizeBottomSheet(context, ref);
                          }),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton(BuildContext context, IconData icon, String label, bool isSelected, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        color: Colors.transparent, // Đảm bảo bắt trọn vùng tap
        width: 65,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            isSelected
                ? ShaderMask(
                    shaderCallback: (Rect bounds) {
                      return const LinearGradient(
                        colors: [Color(0xFFFF0844), Color(0xFFFFB199)], // Gradient đỏ cam cho nút thả tim
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ).createShader(bounds);
                    },
                    child: Icon(
                      icon,
                      size: 24,
                      color: Colors.white,
                    ),
                  )
                : Icon(
                    icon,
                    size: 24,
                    color: const Color(0xFF1A3038).withOpacity(0.6),
                  ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                color: isSelected ? const Color(0xFFFF0844) : const Color(0xFF1A3038).withOpacity(0.6),
              ),
            )
          ],
        ),
      ),
    );
  }
}

class LiquidGlassBorderPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final RRect rrect = RRect.fromRectAndRadius(rect, Radius.circular(size.height / 2));
    
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          Colors.white.withOpacity(0.65), // Viền trên sáng bóng để bắt sáng
          Colors.white.withOpacity(0.1),  // Viền bên hông mờ dần
          Colors.black.withOpacity(0.05), // Viền dưới hơi tối nhẹ tạo khối chìm
        ],
        stops: const [0.0, 0.4, 1.0],
      ).createShader(rect);

    canvas.drawRRect(rrect, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class TtsPlayerWidget extends StatefulWidget {
  final String textToSpeak;
  const TtsPlayerWidget({super.key, required this.textToSpeak});

  @override
  State<TtsPlayerWidget> createState() => _TtsPlayerWidgetState();
}

class _TtsPlayerWidgetState extends State<TtsPlayerWidget> {
  final FlutterTts flutterTts = FlutterTts();
  bool isPlaying = false;

  @override
  void initState() {
    super.initState();
    _initTts();
  }

  void _initTts() async {
    try {
      // Thử dùng vi-VN trước, nếu không được thì dùng vi
      var isViVn = await flutterTts.isLanguageAvailable("vi-VN");
      if (isViVn != null && (isViVn == true || isViVn == 1)) {
        await flutterTts.setLanguage("vi-VN");
      } else {
        await flutterTts.setLanguage("vi");
      }
    } catch (e) {
      await flutterTts.setLanguage("vi-VN");
    }

    await flutterTts.setSpeechRate(0.5);
    await flutterTts.setVolume(1.0);
    await flutterTts.setPitch(1.0);

    flutterTts.setCompletionHandler(() {
      if (mounted) setState(() => isPlaying = false);
    });
  }

  @override
  void dispose() {
    flutterTts.stop();
    super.dispose();
  }

  void _togglePlay() async {
    if (isPlaying) {
      await flutterTts.stop();
      if (mounted) setState(() => isPlaying = false);
    } else {
      if (mounted) setState(() => isPlaying = true);
      await flutterTts.speak(widget.textToSpeak);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primary.withOpacity(0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Theme.of(context).colorScheme.primary.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          Container(
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: IconButton(
              icon: Icon(
                isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                color: Theme.of(context).colorScheme.primary,
              ),
              onPressed: _togglePlay,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Nghe bài báo',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
                Text(
                  isPlaying ? 'Đang phát âm thanh...' : 'Nhấn để nghe nội dung',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
