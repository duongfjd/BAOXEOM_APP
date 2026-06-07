import 'dart:ui';
import 'package:audioplayers/audioplayers.dart';

class GoogleTranslateTtsService {
  final AudioPlayer _audioPlayer = AudioPlayer();
  List<String> _chunks = [];
  int _currentIndex = 0;
  bool _isPlaying = false;
  
  VoidCallback? onComplete;

  GoogleTranslateTtsService() {
    _audioPlayer.onPlayerStateChanged.listen((state) {
      if (state == PlayerState.completed) {
        if (_isPlaying) {
          _playNext();
        }
      }
    });
  }

  Future<void> speakVietnamese(String text) async {
    // Google Translate giới hạn 200 ký tự mỗi request
    // Tự động chia nhỏ văn bản để "không giới hạn ký tự" như yêu cầu
    _chunks = _splitText(text, 200);
    _currentIndex = 0;
    _isPlaying = true;
    if (_chunks.isNotEmpty) {
      await _playNext();
    }
  }

  Future<void> _playNext() async {
    if (!_isPlaying) return;

    if (_currentIndex >= _chunks.length) {
      _isPlaying = false;
      onComplete?.call();
      return;
    }
    
    try {
      String chunk = _chunks[_currentIndex];
      String encodedText = Uri.encodeComponent(chunk);
      String googleTtsUrl = 
          'https://translate.google.com/translate_tts?ie=UTF-8&client=tw-ob&tl=vi&q=$encodedText';

      await _audioPlayer.play(UrlSource(googleTtsUrl));
      _currentIndex++;
    } catch (e) {
      print("Lỗi phát giọng Google: $e");
      _currentIndex++;
      _playNext();
    }
  }

  Future<void> pause() async {
    _isPlaying = false;
    await _audioPlayer.pause();
  }

  Future<void> resume() async {
    _isPlaying = true;
    await _audioPlayer.resume();
  }

  Future<void> stop() async {
    _isPlaying = false;
    await _audioPlayer.stop();
  }

  void dispose() {
    _isPlaying = false;
    _audioPlayer.dispose();
  }

  List<String> _splitText(String text, int maxLength) {
    List<String> chunks = [];
    // Tách theo câu trước để ngắt giọng tự nhiên
    List<String> sentences = text.replaceAll(RegExp(r'\s+'), ' ').split(RegExp(r'(?<=[.!?])\s+'));
    
    for (String sentence in sentences) {
      if (sentence.length <= maxLength) {
        chunks.add(sentence.trim());
      } else {
        // Nếu một câu vẫn dài hơn 200 ký tự, tách theo dấu phẩy hoặc từ
        List<String> words = sentence.split(' ');
        String currentChunk = '';
        for (String word in words) {
          if ((currentChunk + word).length > maxLength) {
            chunks.add(currentChunk.trim());
            currentChunk = word + ' ';
          } else {
            currentChunk += word + ' ';
          }
        }
        if (currentChunk.trim().isNotEmpty) {
          chunks.add(currentChunk.trim());
        }
      }
    }
    return chunks;
  }
}
