import 'dart:convert';
import 'dart:io';

const String kFormatApiBaseUrl = String.fromEnvironment(
  'FORMAT_API_BASE',
  defaultValue: String.fromEnvironment(
    'EXTRACT_API_BASE',
    defaultValue: 'http://localhost:8787',
  ),
);

class FormatResult {
  final String text;
  final bool budgetExceeded;
  final bool cacheHit;

  const FormatResult({
    required this.text,
    this.budgetExceeded = false,
    this.cacheHit = false,
  });
}

class LiveFormatException implements Exception {
  final String message;
  const LiveFormatException(this.message);

  @override
  String toString() => message;
}

class LiveFormatService {
  LiveFormatService({String? baseUrl}) : _baseUrl = baseUrl ?? kFormatApiBaseUrl;

  final String _baseUrl;

  Future<FormatResult> format({
    required String text,
    required String title,
    required String template,
    String? prompt,
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
        if (prompt != null && prompt.trim().isNotEmpty) 'prompt': prompt.trim(),
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
      final budgetExceeded = json['budget_exceeded'] == true || data['budget_exceeded'] == true;
      final cacheHit = json['cache_hit'] == true;
      return FormatResult(
        text: formattedText,
        budgetExceeded: budgetExceeded,
        cacheHit: cacheHit,
      );
    } on SocketException {
      throw const LiveFormatException('サーバーに接続できませんでした。');
    } on FormatException {
      throw const LiveFormatException('応答の解析に失敗しました。');
    } finally {
      client.close(force: true);
    }
  }
}
