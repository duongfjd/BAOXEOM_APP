import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

class FptTtsService {
  static const String _apiKey = '1dmDUtFhXmx95Ly9wUOMuDMctwrRNYhI';
  static const String _apiUrl = 'https://api.fpt.ai/hmi/tts/v5';

  Future<String?> generateAudioUrl(String text, String voice, int speed) async {
    try {
      // Giới hạn 5000 ký tự theo yêu cầu của FPT API
      final safeText = text.length > 4900 ? text.substring(0, 4900) : text;

      debugPrint('FPT TTS: Gửi yêu cầu chuyển đổi văn bản sang giọng nói (${safeText.length} ký tự)...');
      final response = await http.post(
        Uri.parse(_apiUrl),
        headers: {
          'api-key': _apiKey,
          'speed': speed.toString(),
          'voice': voice,
        },
        body: safeText,
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['error'] == 0 && data['async'] != null) {
          final asyncUrl = data['async'] as String;
          debugPrint('FPT TTS: Nhận liên kết sinh audio bất đồng bộ thành công: $asyncUrl');
          return asyncUrl;
        }
      }
      debugPrint('FPT TTS Error: ${response.statusCode} - ${response.body}');
      return null;
    } catch (e) {
      debugPrint('FPT TTS Exception: $e');
      return null;
    }
  }

  // Hàm chờ file audio sẵn sàng (vì FPT cần thời gian gen file)
  Future<bool> waitForAudioReady(String url) async {
    int maxRetries = 40; // Tăng lên thử tối đa 40 lần (khoảng 120 giây) để tránh timeout bài báo dài
    int delayMs = 3000; // Mỗi lần cách nhau 3 giây
    bool isCorsBlocked = false;

    debugPrint('FPT TTS: Bắt đầu chờ file audio sẵn sàng tại link: $url');

    for (int i = 0; i < maxRetries; i++) {
      try {
        debugPrint('FPT TTS: Kiểm tra trạng thái file (lần ${i + 1}/$maxRetries)...');
        final response = await http.head(Uri.parse(url));
        debugPrint('FPT TTS: Kết quả HTTP Status: ${response.statusCode}');
        if (response.statusCode == 200) {
          debugPrint('FPT TTS: File audio đã sẵn sàng hoàn toàn để phát!');
          return true; // File đã sẵn sàng
        }
      } catch (e) {
        debugPrint('FPT TTS: Lỗi kiểm tra trạng thái file: $e');
        // Nếu chạy trên Web không tắt CORS, http.head sẽ bắn exception
        if (kIsWeb && e.toString().contains('Failed to fetch')) {
          isCorsBlocked = true;
          debugPrint('FPT TTS: Phát hiện trình duyệt chặn CORS. Sử dụng cơ chế đợi thay thế (CORS fallback).');
          break; // Thoát vòng lặp để dùng fallback
        }
        // Bỏ qua các lỗi mạng tạm thời khác
      }
      await Future.delayed(Duration(milliseconds: delayMs));
    }

    // FALLBACK cho Web bị chặn CORS:
    if (isCorsBlocked) {
      // Đợi thêm 30 giây (tổng cộng đủ lâu để FPT gen xong bài báo dài)
      debugPrint('FPT TTS: Đang đợi 30 giây để đảm bảo file audio được sinh xong trên server FPT...');
      await Future.delayed(const Duration(seconds: 30));
      debugPrint('FPT TTS: Hết thời gian chờ fallback, chuyển sang phát nhạc.');
      return true; // Giả định là file đã xong
    }

    debugPrint('FPT TTS: Quá thời gian chờ (120 giây) mà file vẫn chưa sẵn sàng trên FPT.');
    return false; // Quá thời gian chờ
  }
}
