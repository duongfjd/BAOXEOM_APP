const { initDB, pool } = require('./src/db');
const { fetchNews } = require('./src/newsService');
const { summarizeArticle } = require('./src/aiService');
const { runScraperPipeline } = require('./src/scraper/scheduler');

const runPipeline = async () => {
  console.log('🚀 [GitHub Action / 1-Time Run] Khởi chạy cả 2 luồng tin tức tự động...', new Date().toLocaleString());
  try {
    await initDB();

    // 1. Chạy luồng RSS Scraper mới
    console.log('📡 1. Đang chạy luồng RSS Scraper...');
    await runScraperPipeline();

    // 2. Chạy luồng NewsAPI cũ
    console.log('📡 2. Đang chạy luồng NewsAPI...');
    const articles = await fetchNews();
    if (!articles || articles.length === 0) {
      console.log('ℹ️ [NewsAPI] Không có bài báo mới nào.');
    } else {
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
          console.log(`🤖 [NewsAPI] AI đang phân tích bài viết: ${article.title}`);

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
            console.log(`✅ [NewsAPI] Đã lưu vào DB: ${aiResult.title_vi}`);
          }
        } catch (error) {
          console.error(`❌ [NewsAPI] Lỗi bài báo (${article.title}):`, error.message);
        } finally {
          client.release();
        }
      }
    }
    console.log('🎉 Hoàn thành cả 2 luồng tin tức!');
  } catch (error) {
    console.error('❌ Lỗi nghiêm trọng khi chạy luồng tin tức:', error.message);
  } finally {
    process.exit(0);
  }
};

runPipeline();
