import 'dart:io';

void main() async {
  final request = await HttpClient().headUrl(Uri.parse('https://file01.fpt.ai/text2speech-v5/short/2026-06-07/9fe3b49d2fd72e3b7189407ac52bfd08.mp3'));
  final response = await request.close();
  print('HEAD: ${response.statusCode}');
  
  final req2 = await HttpClient().getUrl(Uri.parse('https://file01.fpt.ai/text2speech-v5/short/2026-06-07/9fe3b49d2fd72e3b7189407ac52bfd08.mp3'));
  final res2 = await req2.close();
  print('GET: ${res2.statusCode}');
}
