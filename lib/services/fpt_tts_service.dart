import 'dart:convert';
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
          // 'Content-Type': 'application/json' // API này nhận body trực tiếp dạng string
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

    for (int i = 0; i < maxRetries; i++) {
      try {
        final response = await http.head(Uri.parse(url));
        if (response.statusCode == 200) {
          return true;
        }
      } catch (e) {
        // Bỏ qua lỗi kết nối
      }
      await Future.delayed(Duration(milliseconds: delayMs));
    }
    return false; // Quá thời gian chờ
  }
}
