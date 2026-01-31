// DraftStore は小さな永続層として SharedPreferences の StringList を
// 利用して下書きを保存します。保存形式は JSON エンコードされた Map の
// リスト（StringList）です。
//
// 注意点:
// - データ量が多くなる用途には不向き（SharedPreferences は小さなキー/値向け）
// - 文字列リストに JSON を格納するシンプルな構成のため、移行時はバージョン管理が必要
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class Draft {
  String id;
  String rawText;
  String generated;
  String status; // 'draft' | 'scheduled' | 'posted' | 'failed'
  int createdAt;
  String title;
  int publishAt;
  List<String> targets;
  String captionX;
  String captionInstagram;
  String hashtags;
  String eventDate;
  String venue;
  String performers;
  String ticketPrice;
  String ticketUrl;
  List<String> imageUrls;

  Draft({
    required this.id,
    required this.rawText,
    required this.generated,
    required this.status,
    required this.createdAt,
    this.title = '',
    int? publishAt,
    List<String>? targets,
    this.captionX = '',
    this.captionInstagram = '',
    this.hashtags = '',
    this.eventDate = '',
    this.venue = '',
    this.performers = '',
    this.ticketPrice = '',
    this.ticketUrl = '',
    List<String>? imageUrls,
  })  : publishAt = publishAt ?? createdAt,
        targets = targets ?? <String>[],
        imageUrls = imageUrls ?? <String>[];

  Map<String, dynamic> toJson() => {
        'id': id,
        'rawText': rawText,
        'generated': generated,
        'status': status,
        'createdAt': createdAt,
        'title': title,
        'publishAt': publishAt,
        'targets': targets,
        'captionX': captionX,
        'captionInstagram': captionInstagram,
        'hashtags': hashtags,
        'eventDate': eventDate,
        'venue': venue,
        'performers': performers,
        'ticketPrice': ticketPrice,
        'ticketUrl': ticketUrl,
        'imageUrls': imageUrls,
      };

  static Draft fromJson(Map<String, dynamic> j) {
    final generated = (j['generated'] as String?) ?? '';
    return Draft(
      id: j['id'] as String,
      rawText: (j['rawText'] as String?) ?? '',
      generated: generated,
      status: (j['status'] as String?) ?? 'draft',
      createdAt: j['createdAt'] as int,
      title: (j['title'] as String?) ?? '',
      publishAt: j['publishAt'] as int? ?? j['createdAt'] as int,
      targets: (j['targets'] as List?)?.map((e) => e.toString()).toList() ?? <String>[],
      captionX: (j['captionX'] as String?) ?? generated,
      captionInstagram: (j['captionInstagram'] as String?) ?? generated,
      hashtags: (j['hashtags'] as String?) ?? '',
      eventDate: (j['eventDate'] as String?) ?? '',
      venue: (j['venue'] as String?) ?? '',
      performers: (j['performers'] as String?) ?? '',
      ticketPrice: (j['ticketPrice'] as String?) ?? '',
      ticketUrl: (j['ticketUrl'] as String?) ?? '',
      imageUrls: (j['imageUrls'] as List?)?.map((e) => e.toString()).toList() ?? <String>[],
    );
  }
}

class DraftStore {
  static const _key = 'post_prep_drafts_v1';

  Future<List<Draft>> loadDrafts() async {
    // StringList を読み出して JSON をデコードし Draft に変換する。
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getStringList(_key) ?? <String>[];
    return raw.map((s) {
      final m = jsonDecode(s) as Map<String, dynamic>;
      return Draft.fromJson(m);
    }).toList()
      // 公開日時の降順にソートして最新が上に来るようにする。
      ..sort((a, b) => b.publishAt.compareTo(a.publishAt));
  }

  Future<void> saveDraft(Draft draft) async {
    // 保存処理: 既存 id があれば置き換え、なければ追加する
    final prefs = await SharedPreferences.getInstance();
    final list = prefs.getStringList(_key) ?? <String>[];
    final decoded = list.map((s) => jsonDecode(s) as Map<String, dynamic>).toList();

    // id が存在すれば更新、なければ追加
    final idx = decoded.indexWhere((m) => (m['id'] as String) == draft.id);
    final encoded = draft.toJson();
    if (idx >= 0) {
      decoded[idx] = encoded;
    } else {
      decoded.add(encoded);
    }

    // 再び JSON エンコードして保存
    final toStore = decoded.map((m) => jsonEncode(m)).toList();
    await prefs.setStringList(_key, toStore);
  }

  Future<void> deleteDraft(String id) async {
    // id の下書きを削除する
    final prefs = await SharedPreferences.getInstance();
    final list = prefs.getStringList(_key) ?? <String>[];
    final decoded = list.map((s) => jsonDecode(s) as Map<String, dynamic>).toList();
    decoded.removeWhere((m) => (m['id'] as String) == id);
    final toStore = decoded.map((m) => jsonEncode(m)).toList();
    await prefs.setStringList(_key, toStore);
  }

  Future<void> clearAllDrafts() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key);
  }
}
