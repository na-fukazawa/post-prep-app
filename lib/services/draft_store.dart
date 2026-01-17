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
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getStringList(_key) ?? <String>[];
    return raw.map((s) {
      final m = jsonDecode(s) as Map<String, dynamic>;
      return Draft.fromJson(m);
    }).toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  Future<void> saveDraft(Draft draft) async {
    final prefs = await SharedPreferences.getInstance();
    final list = prefs.getStringList(_key) ?? <String>[];
    final decoded = list.map((s) => jsonDecode(s) as Map<String, dynamic>).toList();

    // replace if id exists
    final idx = decoded.indexWhere((m) => (m['id'] as String) == draft.id);
    final encoded = draft.toJson();
    if (idx >= 0) {
      decoded[idx] = encoded;
    } else {
      decoded.add(encoded);
    }

    final toStore = decoded.map((m) => jsonEncode(m)).toList();
    await prefs.setStringList(_key, toStore);
  }

  Future<void> deleteDraft(String id) async {
    final prefs = await SharedPreferences.getInstance();
    final list = prefs.getStringList(_key) ?? <String>[];
    final decoded = list.map((s) => jsonDecode(s) as Map<String, dynamic>).toList();
    decoded.removeWhere((m) => (m['id'] as String) == id);
    final toStore = decoded.map((m) => jsonEncode(m)).toList();
    await prefs.setStringList(_key, toStore);
  }
}
