const Parser = require('rss-parser');
const parser = new Parser();

// Danh sách các luồng RSS của VnExpress được cấu hình theo yêu cầu của dự án
const RSS_FEEDS = [
  { category: 'Trang chủ', url: 'https://vnexpress.net/rss/tin-moi-nhat.rss' },
  { category: 'Thế giới', url: 'https://vnexpress.net/rss/the-gioi.rss' },
  { category: 'Thời sự', url: 'https://vnexpress.net/rss/thoi-su.rss' },
  { category: 'Kinh doanh', url: 'https://vnexpress.net/rss/kinh-doanh.rss' },
  { category: 'Giải trí', url: 'https://vnexpress.net/rss/giai-tri.rss' },
  { category: 'Thể thao', url: 'https://vnexpress.net/rss/the-thao.rss' },
  { category: 'Pháp luật', url: 'https://vnexpress.net/rss/phap-luat.rss' },
  { category: 'Giáo dục', url: 'https://vnexpress.net/rss/giao-duc.rss' },
  { category: 'Sức khỏe', url: 'https://vnexpress.net/rss/suc-khoe.rss' },
  { category: 'Gia đình', url: 'https://vnexpress.net/rss/gia-dinh.rss' },
  { category: 'Du lịch', url: 'https://vnexpress.net/rss/du-lich.rss' },
  { category: 'Khoa học', url: 'https://vnexpress.net/rss/khoa-hoc.rss' },
  { category: 'Khoa học & Công nghệ', url: 'https://vnexpress.net/rss/khoa-hoc-cong-nghe.rss' }, // hỗ trợ dự phòng
  { category: 'Thư giãn', url: 'https://vnexpress.net/rss/thu-gian.rss' },
  { category: 'Tin xem nhiều', url: 'https://vnexpress.net/rss/tin-xem-nhieu.rss' }
];

/**
 * Quét một kênh RSS cụ thể và trả về danh sách các bài viết
 * @param {Object} feed { category, url }
 * @returns {Promise<Array>} Danh sách các bài viết từ RSS
 */
const fetchFeed = async (feed) => {
  try {
    console.log(`🌐 Đang quét RSS [${feed.category}]: ${feed.url}`);
    const parsed = await parser.parseURL(feed.url);
    
    return parsed.items.map(item => {
      // VnExpress đôi khi trả về link có query parameter hoặc hash, ta làm sạch URL
      let cleanUrl = item.link || '';
      if (cleanUrl.includes('#')) {
        cleanUrl = cleanUrl.split('#')[0];
      }
      if (cleanUrl.includes('?')) {
        cleanUrl = cleanUrl.split('?')[0];
      }

      return {
        title: item.title,
        url: cleanUrl,
        published_at: item.pubDate ? new Date(item.pubDate) : new Date(),
        category_hint: feed.category,
        source_name: 'VnExpress'
      };
    });
  } catch (error) {
    console.error(`❌ Lỗi khi đọc RSS [${feed.category}]: ${error.message}`);
    return [];
  }
};

/**
 * Quét toàn bộ danh sách các kênh RSS VnExpress, loại bỏ các bài viết trùng lặp
 * @returns {Promise<Array>} Danh sách bài viết không trùng lặp
 */
const fetchAllRssArticles = async () => {
  console.log('🔄 Bắt đầu tiến trình quét toàn bộ nguồn RSS VnExpress...');
  const allArticles = [];
  const seenUrls = new Set();

  for (const feed of RSS_FEEDS) {
    const articles = await fetchFeed(feed);
    for (const article of articles) {
      if (article.url && !seenUrls.has(article.url)) {
        seenUrls.add(article.url);
        allArticles.push(article);
      }
    }
  }

  console.log(`✅ Hoàn tất quét RSS. Tìm thấy tổng cộng ${allArticles.length} bài viết độc nhất.`);
  return allArticles;
};

module.exports = {
  fetchAllRssArticles,
  RSS_FEEDS
};
