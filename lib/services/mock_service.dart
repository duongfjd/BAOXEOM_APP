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
        fullContentVi: 'Nội dung đầy đủ của bài báo số $index sẽ được hiển thị ở đây. ' * 20,
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
