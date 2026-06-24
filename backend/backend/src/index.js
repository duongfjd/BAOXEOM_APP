const express = require('express');
const cors = require('cors');
const path = require('path');
const cron = require('node-cron');
const { initDB, pool } = require('./db');
const { fetchNews } = require('./newsService');
const { summarizeArticle } = require('./aiService');
const { runScraperPipeline } = require('./scraper/scheduler');

const app = express();
app.use(cors());
app.use(express.json());

// Phục vụ thư mục public chứa giao diện HTML
app.use(express.static(path.join(__dirname, '../public')));

// API Endpoint cho giao diện HTML gọi tới để lấy tin tức hiển thị
app.get('/api/articles', async (req, res) => {
  try {
    const client = await pool.connect();
    // Lấy 40 bài báo mới nhất để làm phong phú giao diện người dùng
    const result = await client.query('SELECT * FROM articles ORDER BY published_at DESC LIMIT 40');
    client.release();
    res.json(result.rows);
  } catch (error) {
    console.error('❌ Lỗi khi truy xuất DB:', error);
    res.status(500).json({ error: error.message });
  }
});

/**
 * Luồng cũ thu thập dữ liệu bằng NewsAPI (giữ nguyên để cả 2 cùng chạy)
 */
const processNews = async () => {
  console.log('🚀 [NewsAPI] Bắt đầu tiến trình thu thập và xử lý...', new Date().toLocaleString());
  
  try {
    const articles = await fetchNews();
    if (!articles || articles.length === 0) {
      console.log('ℹ️ [NewsAPI] Không có bài báo mới nào.');
      return;
    }

    for (const article of articles) {
      if (article.title === '[Removed]') continue;
      
      const client = await pool.connect();
      try {
        const checkResult = await client.query('SELECT id FROM articles WHERE url = $1', [article.url]);
        if (checkResult.rows.length > 0) {
          // console.log(`⏩ [NewsAPI] Bỏ qua bài cũ: ${article.title}`);
          continue;
        }

        const contentForAi = `${article.title}\n\n${article.description || ''}\n\n${article.content || ''}`;
        console.log(`🤖 [NewsAPI] AI đang xử lý bài viết: ${article.title}`);
        
        const aiResult = await summarizeArticle(contentForAi);
        
        if (aiResult) {
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
          `;
          await client.query(insertQuery, [
            article.url,
            article.title,
            aiResult.title_vi,
            aiResult.summary_vi,
            aiResult.category,
            new Date(article.publishedAt || new Date()),
            article.source?.name || 'NewsAPI',
            article.author || null,
            article.urlToImage || null,
            aiResult.full_content_vi || ''
          ]);
          console.log(`✅ [NewsAPI] Đã lưu thành công bài: ${aiResult.title_vi}`);
        }
      } catch (error) {
        console.error(`❌ [NewsAPI] Lỗi xử lý bài báo (${article.title}):`, error.message);
      } finally {
        client.release();
      }
    }
  } catch (error) {
    console.error('❌ [NewsAPI] Lỗi hệ thống:', error.message);
  }
  console.log('🎉 [NewsAPI] Kết thúc luồng xử lý NewsAPI.');
};

const PORT = process.env.PORT || 3000;

/**
 * Khởi động toàn bộ hệ thống backend
 */
const startSystem = async () => {
  try {
    console.log('⚙️ Đang khởi tạo cơ sở dữ liệu...');
    await initDB();

    // Khởi động Express Server
    app.listen(PORT, () => {
      console.log(`🌐 Máy chủ Backend đang chạy tại: http://localhost:${PORT}`);
    });

    // Chạy thử cả 2 luồng quét tin ngay khi khởi động
    console.log('⏳ Đang chạy thử nghiệm cả 2 luồng thu thập tin tức...');
    await runScraperPipeline(); // 1. RSS Scraper mới
    await processNews();        // 2. NewsAPI cũ

    // Cấu hình chạy định kỳ cả 2 luồng tự động cứ mỗi 1 tiếng
    console.log('⏰ Đang đặt lịch Cron Job quét tin tự động cho cả 2 luồng: 1 tiếng/lần.');
    cron.schedule('0 * * * *', async () => {
      console.log('⏰ Cron Job kích hoạt: Bắt đầu quét tin mới từ cả RSS và NewsAPI.');
      await runScraperPipeline();
      await processNews();
    });

  } catch (error) {
    console.error('❌ Lỗi nghiêm trọng khi khởi động hệ thống:', error);
    process.exit(1);
  }
};

startSystem();
