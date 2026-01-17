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
  String status; // 'draft' or 'scheduled'
  int createdAt;

  Draft({
    required this.id,
    required this.rawText,
    required this.generated,
    required this.status,
    required this.createdAt,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'rawText': rawText,
        'generated': generated,
        'status': status,
        'createdAt': createdAt,
      };

  static Draft fromJson(Map<String, dynamic> j) => Draft(
        id: j['id'] as String,
        rawText: j['rawText'] as String,
        generated: j['generated'] as String,
        status: j['status'] as String,
        createdAt: j['createdAt'] as int,
      );
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
      // 作成日時の降順にソートして最新が上に来るようにする。
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
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
}
