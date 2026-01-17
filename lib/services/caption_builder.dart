import 'dart:core';

/// CaptionBuilder は貼り付けられた生テキストから簡易的にキャプションを
/// 組み立てるユーティリティクラスです。
///
/// アプローチ:
/// - 行分割してタイトル候補を抽出（先頭行をタイトルにする）
/// - 正規表現とキーワード（日時/場所/料金）に基づく抽出を試みる
/// - 抽出できた情報をテンプレートに埋め、元の本文も「詳細:」として残す
///
/// 注意: 高度な自然言語解析ではなく、ルールベースの簡易実装です。
class CaptionBuilder {
  /// rawText からキャプション文字列を生成して返す。
  /// 出力には抽出された日時/場所/料金（存在すれば）と、元テキストの
  /// 「詳細:」セクションが含まれる。
  static String buildCaption(String rawText) {
    final lines = rawText
        .split(RegExp(r"\r?\n"))
        .map((l) => l.trim())
        .where((l) => l.isNotEmpty)
        .toList();

    // タイトルは先頭行を使う（存在しない場合はフォールバック）
    final title = lines.isNotEmpty ? lines.first : 'イベント情報';

    // 簡易ヒューリスティックで日付/場所/料金を抽出
    final date = _extractDate(rawText) ?? '';
    final venue = _extractByKeywords(rawText, [r'場所', r'会場', r'venue']) ?? '';
    final price = _extractByKeywords(rawText, [r'料金', r'金額', r'price']) ?? '';

    final buffer = StringBuffer();
    buffer.writeln(title);
    if (date.isNotEmpty) buffer.writeln('日時: $date');
    if (venue.isNotEmpty) buffer.writeln('場所: $venue');
    if (price.isNotEmpty) buffer.writeln('料金: $price');

    // 元テキストを詳細として残すことで、あとで必要な情報を確認できる。
    buffer.writeln('\n詳細:');
    buffer.writeln(rawText.trim());

    buffer.writeln('\n---\n');
    buffer.writeln('※詳しい投稿は手動でご確認ください。');
    buffer.writeln('#イベント #告知');

    return buffer.toString();
  }

  /// 指定したキーワードリストから行単位で値を抽出する。たとえば
  /// '場所: 東京' や 'venue 東京' のような形式を想定している。
  /// 大文字小文字を無視して検索する。
  static String? _extractByKeywords(String text, List<String> keywords) {
    final lines = text.split(RegExp(r"\r?\n"));
    for (final k in keywords) {
      // (?i) で大文字小文字を無視、コロンや全角コロンの後ろの内容をキャプチャ
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

  /// 複数パターンを試して日付・時刻らしき文字列を抽出する。
  /// - YYYY-MM-DD や MM月DD日 などのパターンを優先して探す
  /// - 見つからなければ、'日時:' といった行接頭辞を参照する
  static String? _extractDate(String text) {
    // よく使われそうな日付/時刻の正規表現パターン
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

    // 直接 '日時:' のようなラベルがあるならそこから取り出す
    final byKey = _extractByKeywords(text, [r'日時', r'Date', r'date']);
    if (byKey != null) return byKey;

    return null;
  }
}
