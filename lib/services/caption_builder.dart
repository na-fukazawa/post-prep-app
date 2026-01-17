import 'dart:core';

class CaptionBuilder {
  /// Build a caption from raw pasted text.
  /// This is a simple, template-based extractor. It looks for some common
  /// date/venue/price cues and falls back to including the raw text.
  static String buildCaption(String rawText) {
    final lines = rawText
        .split(RegExp(r"\r?\n"))
        .map((l) => l.trim())
        .where((l) => l.isNotEmpty)
        .toList();

    final title = lines.isNotEmpty ? lines.first : 'イベント情報';

    // Simple heuristics
    final date = _extractDate(rawText) ?? '';
    final venue = _extractByKeywords(rawText, [r'場所', r'会場', r'venue']) ?? '';
    final price = _extractByKeywords(rawText, [r'料金', r'金額', r'price']) ?? '';

    final buffer = StringBuffer();
    buffer.writeln(title);
    if (date.isNotEmpty) buffer.writeln('日時: $date');
    if (venue.isNotEmpty) buffer.writeln('場所: $venue');
    if (price.isNotEmpty) buffer.writeln('料金: $price');

    buffer.writeln('\n詳細:');
    buffer.writeln(rawText.trim());

    buffer.writeln('\n---\n');
    buffer.writeln('※詳しい投稿は手動でご確認ください。');
    buffer.writeln('#イベント #告知');

    return buffer.toString();
  }

  static String? _extractByKeywords(String text, List<String> keywords) {
    final lines = text.split(RegExp(r"\r?\n"));
    for (final k in keywords) {
      final re = RegExp(r'(?i)\b' + k + r'[:：\s]*([^\n]+)');
      for (final line in lines) {
        final m = re.firstMatch(line);
        if (m != null) {
          return m.group(1)?.trim();
        }
      }
    }
    return null;
  }

  static String? _extractDate(String text) {
    // Try several common date-like patterns
    final patterns = [
      RegExp(r'\d{4}[-/]\d{1,2}[-/]\d{1,2}'),
      RegExp(r'\d{1,2}月\s*\d{1,2}日'),
      RegExp(r'\d{1,2}/\d{1,2}'),
      RegExp(r'\d{1,2}[:]\d{2}'),
    ];

    for (final p in patterns) {
      final m = p.firstMatch(text);
      if (m != null) return m.group(0)?.trim();
    }

    // Try line prefixes like 日時:
    final byKey = _extractByKeywords(text, [r'日時', r'Date', r'date']);
    if (byKey != null) return byKey;

    return null;
  }
}
