const axios = require('axios');
const { JSDOM } = require('jsdom');
const { Readability } = require('@mozilla/readability');

// Danh sách các User-Agent phổ biến để fake trình duyệt thật, tránh bị block IP
const USER_AGENTS = [
  'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/121.0.0.0 Safari/537.36',
  'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/121.0.0.0 Safari/537.36',
  'Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:122.0) Gecko/20100101 Firefox/122.0',
  'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/17.3 Safari/605.1.15',
  'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/121.0.0.0 Safari/537.36 Edg/121.0.0.0'
];

/**
 * Trả về ngẫu nhiên một User-Agent từ danh sách cấu hình
 */
const getRandomUserAgent = () => {
  return USER_AGENTS[Math.floor(Math.random() * USER_AGENTS.length)];
};

/**
 * Hàm sleep tạo độ trễ ngẫu nhiên để tránh cào quá nhanh dẫn tới bị block IP
 * @param {number} minMillis milliseconds tối thiểu
 * @param {number} maxMillis milliseconds tối đa
 */
const sleepRandom = (minMillis = 1000, maxMillis = 3000) => {
  const ms = Math.floor(Math.random() * (maxMillis - minMillis + 1)) + minMillis;
  return new Promise(resolve => setTimeout(resolve, ms));
};

/**
 * Cào trang chi tiết bài viết, trích xuất text sạch, tác giả và ảnh đại diện
 * @param {string} url URL của bài báo cần cào
 * @returns {Promise<Object|null>} Trả về thông tin chi tiết bài viết hoặc null nếu lỗi
 */
const extractArticleDetail = async (url) => {
  try {
    // Độ trễ ngẫu nhiên trước khi gửi request (an toàn chuẩn Production)
    await sleepRandom(1000, 3000);

    const headers = {
      'User-Agent': getRandomUserAgent(),
      'Accept': 'text/html,application/xhtml+xml,application/xml;q=0.9,image/avif,image/webp,image/apng,*/*;q=0.8',
      'Accept-Language': 'vi-VN,vi;q=0.9,fr-FR;q=0.8,fr;q=0.7,en-US;q=0.6,en;q=0.5',
      'Cache-Control': 'no-cache',
      'Pragma': 'no-cache',
      'Referer': 'https://vnexpress.net/'
    };

    console.log(`📥 Đang cào bài viết: ${url}`);
    const response = await axios.get(url, {
      headers,
      timeout: 15000 // Timeout 15 giây để tránh treo request
    });

    if (!response.data || typeof response.data !== 'string') {
      throw new Error('Nội dung trang chi tiết trống hoặc không đúng định dạng');
    }

    // TỐI ƯU HÓA: Cắt bỏ các thẻ script và style trước khi nạp vào JSDOM
    // Việc này giúp tránh lỗi "Could not parse CSS stylesheet" của JSDOM và tăng tốc độ xử lý gấp nhiều lần.
    const optimizedHtml = response.data
      .replace(/<script\b[^<]*(?:(?!<\/script>)<[^<]*)*<\/script>/gi, '')
      .replace(/<style\b[^<]*(?:(?!<\/style>)<[^<]*)*<\/style>/gi, '');

    // Khởi tạo JSDOM từ HTML đã tối ưu
    const dom = new JSDOM(optimizedHtml, { url });
    const document = dom.window.document;

    // Trích xuất metadata ảnh đại diện (thường nằm ở thẻ og:image)
    const ogImage = document.querySelector('meta[property="og:image"]')?.getAttribute('content') || '';
    
    // Trích xuất metadata tác giả (name="author" hoặc og:author)
    const author = document.querySelector('meta[name="author"]')?.getAttribute('content') ||
                   document.querySelector('meta[property="article:author"]')?.getAttribute('content') ||
                   '';

    // Sử dụng @mozilla/readability để tự động lọc và bóc tách nội dung chính của bài báo
    const reader = new Readability(document);
    const parsedArticle = reader.parse();

    if (!parsedArticle || !parsedArticle.textContent) {
      throw new Error('Không thể bóc tách nội dung bằng Readability');
    }

    // Làm sạch và định dạng nội dung thu được
    const cleanText = parsedArticle.textContent
      .replace(/\s+/g, ' ') // Gom các khoảng trắng thừa
      .trim();

    return {
      title: parsedArticle.title || '',
      fullText: cleanText,
      author: author || parsedArticle.byline || 'VnExpress',
      urlToImage: ogImage,
      excerpt: parsedArticle.excerpt || ''
    };
  } catch (error) {
    console.error(`❌ Lỗi khi cào chi tiết bài viết (${url}):`, error.message);
    return null;
  }
};

module.exports = {
  extractArticleDetail,
  sleepRandom
};
