const { GoogleGenerativeAI } = require('@google/generative-ai');
const axios = require('axios');
require('dotenv').config();

const geminiKey = process.env.GEMINI_API_KEY;
const fallbackApiKey = process.env.POLLINATIONS_API_KEY;
const fallbackBaseUrl = process.env.POLLINATIONS_BASE_URL || 'https://gen.pollinations.ai';
const fallbackModel = process.env.POLLINATIONS_MODEL || 'openai';

const genAI = geminiKey ? new GoogleGenerativeAI(geminiKey) : null;

/**
 * Xây dựng prompt chất lượng cao để hướng dẫn AI dịch, tóm tắt và phân loại bài viết.
 */
const buildPrompt = (originalTitle, articleContent) => `
Bạn là một Biên tập viên tin tức chuyên nghiệp. Hãy đọc tiêu đề và nội dung bài báo dưới đây, sau đó dịch thuật, biên tập lại và trả về cấu trúc JSON chứa các trường sau:

1. "title_vi": Tiêu đề bài báo dịch sang tiếng Việt một cách tự nhiên, hấp dẫn.
2. "summary_vi": Tóm tắt ngắn gọn nội dung bài báo bằng tiếng Việt trong khoảng 50-70 từ.
3. "category": Phân loại chuyên mục phù hợp nhất (Chọn một trong các chuyên mục sau: Thời sự, Thế giới, Kinh doanh, Giải trí, Thể thao, Pháp luật, Giáo dục, Sức khỏe, Gia đình, Du lịch, Khoa học & Công nghệ, Đời sống, Tin xem nhiều, hoặc Khác).
4. "full_content_vi": Viết lại hoặc dịch toàn bộ nội dung bài báo chi tiết bằng tiếng Việt một cách mượt mà, chuyên nghiệp theo phong cách báo chí. Hãy giữ lại toàn bộ số liệu, sự kiện chính và đảm bảo nội dung đầy đủ chi tiết nhất có thể.

Tiêu đề gốc: ${originalTitle}
Nội dung chi tiết gốc:
${articleContent}

LƯU Ý QUAN TRỌNG:
- Định dạng kết quả trả về bắt buộc phải tuân thủ đúng cấu trúc JSON với các key: "title_vi", "summary_vi", "category", "full_content_vi".
`;

/**
 * Trích xuất và parse chuỗi JSON từ kết quả trả về của AI một cách an toàn.
 */
const parseJsonFromModel = (rawText) => {
  let cleaned = String(rawText || '').trim();
  
  // Trích xuất JSON từ dấu { đầu tiên đến } cuối cùng để loại bỏ phần thừa (nếu có)
  const jsonMatch = cleaned.match(/\{[\s\S]*\}/);
  if (!jsonMatch) {
    console.error('❌ Thất bại khi trích xuất JSON. Raw response:', rawText);
    throw new Error('Không tìm thấy cấu trúc JSON hợp lệ trong phản hồi của AI.');
  }
  
  cleaned = jsonMatch[0];

  // Sửa lỗi AI tự động escape dấu nháy đơn thành \', điều này không hợp lệ trong JSON chuẩn
  cleaned = cleaned.replace(/\\'/g, "'");

  try {
    return JSON.parse(cleaned);
  } catch (error) {
    console.error('❌ Lỗi phân tích cú pháp JSON:', error.message);
    console.error('❌ Nội dung JSON lỗi:', cleaned);
    throw error;
  }
};

/**
 * Tóm tắt và dịch thuật bài viết sử dụng Gemini API.
 */
const summarizeWithGemini = async (prompt) => {
  if (!genAI) {
    throw new Error('Gemini API key chưa được cấu hình.');
  }

  // Sử dụng gemini-2.5-flash làm model chính và bắt buộc trả về định dạng JSON
  const model = genAI.getGenerativeModel({ 
    model: 'gemini-2.5-flash',
    generationConfig: {
      responseMimeType: 'application/json'
    }
  });

  const result = await model.generateContent(prompt);
  const responseText = result.response.text();
  return parseJsonFromModel(responseText);
};

/**
 * Tóm tắt và dịch thuật sử dụng API dự phòng Pollinations.
 */
const summarizeWithFallback = async (prompt) => {
  if (!fallbackApiKey) {
    throw new Error('API dự phòng chưa được cấu hình.');
  }

  const response = await axios.post(
    `${fallbackBaseUrl}/v1/chat/completions`,
    {
      model: fallbackModel,
      response_format: { type: "json_object" }, // ép trả về JSON đối với OpenAI-compatible API
      messages: [
        { role: 'user', content: prompt }
      ]
    },
    {
      headers: {
        Authorization: `Bearer ${fallbackApiKey}`,
        'Content-Type': 'application/json'
      },
      timeout: 30000
    }
  );

  const content = response?.data?.choices?.[0]?.message?.content;
  return parseJsonFromModel(content);
};

/**
 * Hàm điều phối chính để phân tích bài viết qua AI (có retry/fallback).
 * Hỗ trợ 2 kiểu chữ ký gọi hàm:
 * 1. summarizeArticle(articleContent) - Cho luồng cũ NewsAPI
 * 2. summarizeArticle(originalTitle, articleContent) - Cho luồng mới RSS Scraper
 */
const summarizeArticle = async (arg1, arg2) => {
  let title = 'Tin tức';
  let content = '';

  if (arg2 === undefined) {
    // Luồng cũ truyền 1 tham số: chứa toàn bộ tiêu đề + tóm tắt + nội dung ghép lại
    content = arg1;
    // Trích xuất dòng đầu tiên làm tiêu đề tạm thời
    const lines = content.split('\n').filter(l => l.trim().length > 0);
    if (lines.length > 0) {
      title = lines[0].substring(0, 100);
    }
  } else {
    // Luồng mới truyền đầy đủ 2 tham số
    title = arg1;
    content = arg2;
  }

  const prompt = buildPrompt(title, content);

  try {
    console.log(`🤖 Đang phân tích bài viết bằng Gemini AI...`);
    const geminiResult = await summarizeWithGemini(prompt);
    if (geminiResult) {
      return geminiResult;
    }
  } catch (error) {
    console.error('❌ Gemini gặp lỗi:', error.message);
  }

  // Nếu Gemini lỗi, chuyển sang API dự phòng
  try {
    console.log('ℹ️ Đang chuyển sang API dự phòng để phân tích bài viết...');
    const fallbackResult = await summarizeWithFallback(prompt);
    if (fallbackResult) {
      console.log('✅ Xử lý thành công bằng API dự phòng.');
      return fallbackResult;
    }
  } catch (error) {
    console.error('❌ Cả Gemini và API dự phòng đều gặp lỗi:', error.message);
  }

  return null;
};

module.exports = { summarizeArticle };
