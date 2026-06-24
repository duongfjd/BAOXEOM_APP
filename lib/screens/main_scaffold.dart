import 'dart:ui' show ImageFilter;
import 'package:flutter/material.dart';
import 'home_screen.dart';
import 'all_news_screen.dart';
import 'bookmarks_screen.dart';
import 'profile_screen.dart';

class MainScaffold extends StatefulWidget {
  const MainScaffold({super.key});

  @override
  State<MainScaffold> createState() => _MainScaffoldState();
}

class _MainScaffoldState extends State<MainScaffold> {
  int _currentIndex = 0;

  late final List<Widget> _screens = [
    HomeScreen(onNavigateToAllNews: () {
      setState(() {
        _currentIndex = 1;
      });
    }),
    const AllNewsScreen(),
    const BookmarksScreen(),
    const ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F5EE), // Nền kem ngà nhẹ
      // Sử dụng Stack để xếp chồng viên thuốc lên trên danh sách tin tức
      body: Stack(
        children: [
          // Lớp dưới: Nội dung màn hình hiện tại với hiệu ứng chuyển cảnh
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 350),
            switchInCurve: Curves.easeOutCubic,
            switchOutCurve: Curves.easeInCubic,
            transitionBuilder: (Widget child, Animation<double> animation) {
              return FadeTransition(
                opacity: animation,
                child: SlideTransition(
                  position: Tween<Offset>(
                    begin: const Offset(0.02, 0.0), // Trượt ngang rất nhẹ nhàng
                    end: Offset.zero,
                  ).animate(animation),
                  child: child,
                ),
              );
            },
            child: SizedBox(
              key: ValueKey<int>(_currentIndex),
              child: _screens[_currentIndex],
            ),
          ),

          // Lớp trên: Viên thuốc nổi độc lập
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
                  // Bóng đổ kép tạo độ nổi 3D đặc trưng của Liquid Glass
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
                      // 1. Tạo độ mờ đục xuyên thấu (Glassmorphism)
                      BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 25.0, sigmaY: 25.0),
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.15), // Độ trong suốt của kính
                            borderRadius: BorderRadius.circular(34),
                          ),
                        ),
                      ),
                      
                      // 2. Vẽ viền khúc xạ ánh sáng (Liquid Highlight Border)
                      CustomPaint(
                        painter: LiquidGlassBorderPainter(),
                        child: Container(),
                      ),

                      // 3. Lớp Icon điều hướng bên trong
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          _buildNavItem(Icons.home_rounded, Icons.home_outlined, "Trang chủ", 0),
                          _buildNavItem(Icons.article_rounded, Icons.article_outlined, "Tất cả tin", 1),
                          _buildNavItem(Icons.bookmark_rounded, Icons.bookmark_border_rounded, "Đã lưu", 2),
                          _buildNavItem(Icons.person_rounded, Icons.person_outline_rounded, "Hồ sơ", 3),
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

  Widget _buildNavItem(IconData activeIcon, IconData inactiveIcon, String label, int index) {
    final isSelected = _currentIndex == index;
    final icon = isSelected ? activeIcon : inactiveIcon;
    return GestureDetector(
      onTap: () => setState(() => _currentIndex = index),
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
                        colors: [Color(0xFF00C6FF), Color(0xFF0072FF)],
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
                color: isSelected ? const Color(0xFF00B2FE) : const Color(0xFF1A3038).withOpacity(0.6),
              ),
            )
          ],
        ),
      ),
    );
  }
}

// CustomPainter để vẽ đường viền "bắt sáng" phía trên cho khối kính lỏng
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
