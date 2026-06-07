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
          return data['async'] as String;
        }
      }
      print('FPT TTS Error: ${response.statusCode} - ${response.body}');
      return null;
    } catch (e) {
      print('FPT TTS Exception: $e');
      return null;
    }
  }

  // Hàm chờ file audio sẵn sàng (vì FPT cần thời gian gen file)
  Future<bool> waitForAudioReady(String url) async {
    int maxRetries = 20; // Thử tối đa 20 lần (khoảng 60 giây)
    int delayMs = 3000; // Mỗi lần cách nhau 3 giây
    bool isCorsBlocked = false;

    for (int i = 0; i < maxRetries; i++) {
      try {
        final response = await http.head(Uri.parse(url));
        if (response.statusCode == 200) {
          return true; // File đã sẵn sàng
        }
      } catch (e) {
        // Nếu chạy trên Web không tắt CORS, http.head sẽ bắn exception
        if (kIsWeb && e.toString().contains('Failed to fetch')) {
          isCorsBlocked = true;
          break; // Thoát vòng lặp để dùng fallback
        }
        // Bỏ qua các lỗi mạng tạm thời khác
      }
      await Future.delayed(Duration(milliseconds: delayMs));
    }

    // FALLBACK cho Web bị chặn CORS:
    if (isCorsBlocked) {
      // Đợi thêm 15 giây (tổng cộng đủ lâu để FPT gen xong bài báo dài)
      await Future.delayed(const Duration(seconds: 15));
      return true; // Giả định là file đã xong
    }

    return false; // Quá thời gian chờ
  }
}
