import '../models/article.dart';

class MockService {
  static List<Article> getMockArticles() {
    return List.generate(10, (index) {
      return Article(
        id: index,
        url: 'https://example.com/$index',
        titleVi: 'Bài báo số $index: Khám phá công nghệ mới trong năm 2024',
        summaryVi: 'Đây là tóm tắt cho bài báo số $index. Nội dung xoay quanh những thay đổi đột phá trong ngành công nghệ thông tin và AI.',
        category: index % 2 == 0 ? 'Công nghệ' : 'Đời sống',
        publishedAt: DateTime.now().subtract(Duration(hours: index * 2)),
        sourceName: 'VnExpress',
        author: 'Nguyễn Văn A',
        urlToImage: 'https://picsum.photos/seed/${index + 100}/800/600',
        fullContentVi: 'Đây là nội dung đầy đủ chi tiết của bài báo số $index. Hệ thống đang tiến hành thử nghiệm tính năng nghe báo nói sử dụng công nghệ của FPT AI API. Chức năng này giúp chuyển đổi các văn bản bài viết thành giọng nói tự nhiên, giúp người dùng có thể nghe tin tức một cách thuận tiện nhất khi đang di chuyển hoặc làm việc khác. Hãy trải nghiệm và cảm nhận chất lượng giọng đọc.',
      );
    });
  }

  static List<Article> getHotNews() {
    return List.generate(5, (index) {
      return Article(
        id: index + 100,
        url: 'https://example.com/hot-$index',
        titleVi: 'TIN NÓNG: Sự kiện quan trọng vừa mới diễn ra tại khu vực',
        summaryVi: 'Tóm tắt tin nóng...',
        category: 'Thời sự',
        publishedAt: DateTime.now(),
        sourceName: 'Tuổi Trẻ',
        urlToImage: 'https://picsum.photos/seed/${index + 200}/800/400',
      );
    });
  }
}
