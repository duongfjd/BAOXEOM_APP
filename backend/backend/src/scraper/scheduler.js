const { pool } = require('../db');
const { fetchAllRssArticles } = require('./rssParser');
const { extractArticleDetail } = require('./htmlExtractor');
const { summarizeArticle } = require('../aiService');

// Cấu hình giới hạn số lượng bài viết xử lý trong một mẻ quét (để tối ưu chi phí AI và tài nguyên hệ thống)
const MAX_ARTICLES_PER_BATCH = 15;

/**
 * Kiểm tra xem bài viết đã tồn tại trong database chưa qua URL
 * @param {string} url URL của bài báo
 * @returns {Promise<boolean>} Trả về true nếu đã tồn tại, ngược lại false
 */
const checkArticleExists = async (url) => {
  const client = await pool.connect();
  try {
    const result = await client.query('SELECT id FROM articles WHERE url = $1 LIMIT 1', [url]);
    return result.rows.length > 0;
  } catch (error) {
    console.error(`❌ Lỗi kiểm tra trùng lặp DB cho URL (${url}):`, error.message);
    // Nếu lỗi DB, tạm thời coi như đã tồn tại để tránh ném lỗi gây crash luồng quét
    return true;
  } finally {
    client.release();
  }
};

/**
 * Lưu bài báo đã xử lý hoàn chỉnh vào cơ sở dữ liệu
 * @param {Object} articleData Dữ liệu gốc từ RSS & Extractor
 * @param {Object} aiResult Kết quả tóm tắt, phân loại từ Gemini AI
 */
const saveArticleToDB = async (articleData, aiResult) => {
  const client = await pool.connect();
  try {
    const insertQuery = `
      INSERT INTO articles (
        url, 
        original_title, 
        title_vi, 
        summary_vi, 
        category, 
        published_at, 
        source_name, 
        author, 
        url_to_image, 
        full_content_vi
      )
      VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10)
      ON CONFLICT (url) DO NOTHING
      RETURNING id;
    `;

    const result = await client.query(insertQuery, [
      articleData.url,
      articleData.title, // tiêu đề gốc từ RSS
      aiResult.title_vi || articleData.title,
      aiResult.summary_vi || '',
      aiResult.category || articleData.category_hint || 'Khác',
      articleData.published_at,
      articleData.source_name,
      articleData.author || null,
      articleData.urlToImage || null,
      aiResult.full_content_vi || ''
    ]);

    if (result.rows.length > 0) {
      console.log(`✅ Đã lưu vào DB thành công: [${aiResult.category || 'Khác'}] ${aiResult.title_vi}`);
    } else {
      console.log(`⏩ Bỏ qua lưu bài viết do trùng lặp URL (ON CONFLICT): ${articleData.url}`);
    }
  } catch (error) {
    console.error(`❌ Lỗi khi lưu bài viết vào database (${articleData.url}):`, error.message);
  } finally {
    client.release();
  }
};

/**
 * Tiến trình chính: Quét RSS -> Lọc trùng -> Cào chi tiết -> Gọi AI xử lý -> Lưu DB
 */
const runScraperPipeline = async () => {
  console.log('🏁 ==========================================');
  console.log('🚀 KHỞI ĐỘNG TIẾN TRÌNH CÀO DỮ LIỆU TỰ ĐỘNG:', new Date().toLocaleString());
  console.log('🏁 ==========================================');

  try {
    // 1. Quét tin tức mới từ các nguồn RSS VnExpress
    const rssArticles = await fetchAllRssArticles();
    if (!rssArticles || rssArticles.length === 0) {
      console.log('ℹ️ Không tìm thấy bài viết nào từ RSS.');
      return;
    }

    let processedCount = 0;

    // 2. Lọc và xử lý từng bài viết
    for (const article of rssArticles) {
      // Dừng tiến trình nếu đã đạt giới hạn batch để bảo vệ tài nguyên
      if (processedCount >= MAX_ARTICLES_PER_BATCH) {
        console.log(`⚠️ Đã đạt giới hạn xử lý tối đa ${MAX_ARTICLES_PER_BATCH} bài viết mới cho mẻ này.`);
        break;
      }

      const exists = await checkArticleExists(article.url);
      if (exists) {
        // console.log(`⏩ Bỏ qua (Đã tồn tại trong DB): ${article.title}`);
        continue;
      }

      console.log(`🆕 Phát hiện bài viết mới: "${article.title}"`);
      console.log(`🔗 Link: ${article.url}`);

      // 3. Cào nội dung chi tiết bài viết (Full-text) và ảnh đại diện
      const detail = await extractArticleDetail(article.url);
      if (!detail || !detail.fullText) {
        console.warn(`⚠️ Bỏ qua bài viết này do không trích xuất được nội dung chi tiết.`);
        continue;
      }

      // Hợp nhất dữ liệu cào được
      const enrichedArticle = {
        ...article,
        author: detail.author,
        urlToImage: detail.urlToImage
      };

      // 4. Gửi nội dung bài viết sang Gemini AI xử lý (Dịch, tóm tắt, phân loại)
      // Tối ưu hóa chuỗi gửi lên AI (giới hạn ký tự để tránh vượt token limit không cần thiết)
      const textToAnalyze = detail.fullText.substring(0, 8000); 
      const aiResult = await summarizeArticle(enrichedArticle.title, textToAnalyze);

      if (!aiResult) {
        console.warn(`⚠️ Không nhận được phản hồi hợp lệ từ AI. Bỏ qua bài viết: ${enrichedArticle.title}`);
        continue;
      }

      // 5. Lưu vào cơ sở dữ liệu
      await saveArticleToDB(enrichedArticle, aiResult);
      processedCount++;
    }

    console.log(`🏁 Tiến trình cào dữ liệu hoàn tất. Đã xử lý thêm mới thành công ${processedCount} bài viết.`);
  } catch (error) {
    console.error('❌ Lỗi hệ thống trong tiến trình cào dữ liệu:', error);
  }
};

module.exports = {
  runScraperPipeline
};
