import 'dart:convert';
import 'dart:io';

const String kFormatApiBaseUrl = String.fromEnvironment(
  'FORMAT_API_BASE',
  defaultValue: String.fromEnvironment(
    'EXTRACT_API_BASE',
    defaultValue: 'http://localhost:8787',
  ),
);

class LiveFormatException implements Exception {
  final String message;
  const LiveFormatException(this.message);

  @override
  String toString() => message;
}

class LiveFormatService {
  LiveFormatService({String? baseUrl}) : _baseUrl = baseUrl ?? kFormatApiBaseUrl;

  final String _baseUrl;

  Future<String> format({
    required String text,
    required String title,
    required String template,
  }) async {
    final trimmed = text.trim();
    if (trimmed.isEmpty) {
      throw const LiveFormatException('入力テキストが空です。');
    }
    final uri = Uri.parse('$_baseUrl/format');
    final client = HttpClient();
    try {
      final request = await client.postUrl(uri).timeout(const Duration(seconds: 10));
      request.headers.contentType = ContentType.json;
      request.write(jsonEncode({
        'text': trimmed,
        'title': title.trim(),
        'template': template.trim(),
      }));
      final response = await request.close().timeout(const Duration(seconds: 30));
      final body = await utf8.decodeStream(response);
      if (response.statusCode != 200) {
        throw LiveFormatException('整形に失敗しました (${response.statusCode})');
      }
      final json = jsonDecode(body);
      if (json is! Map<String, dynamic>) {
        throw const LiveFormatException('応答形式が不正です。');
      }
      final data = json['data'];
      if (data is! Map<String, dynamic>) {
        throw const LiveFormatException('整形結果が取得できませんでした。');
      }
      final formattedText = data['formatted_text'];
      if (formattedText is! String || formattedText.trim().isEmpty) {
        throw const LiveFormatException('整形結果が空でした。');
      }
      return formattedText;
    } on SocketException {
      throw const LiveFormatException('サーバーに接続できませんでした。');
    } on FormatException {
      throw const LiveFormatException('応答の解析に失敗しました。');
    } finally {
      client.close(force: true);
    }
  }
}
