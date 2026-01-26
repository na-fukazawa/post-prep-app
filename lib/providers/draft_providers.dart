import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/draft_store.dart';

enum DraftFilter {
  all,
  scheduled,
  draft,
  posted,
}

extension DraftFilterLabel on DraftFilter {
  String get label {
    switch (this) {
      case DraftFilter.all:
        return 'すべて';
      case DraftFilter.scheduled:
        return '予約済み';
      case DraftFilter.draft:
        return '下書き';
      case DraftFilter.posted:
        return '投稿済み';
    }
  }
}

final draftFilterProvider = StateProvider<DraftFilter>((ref) => DraftFilter.all);

final draftStoreProvider = Provider<DraftStore>((ref) => DraftStore());

class DraftListNotifier extends AsyncNotifier<List<Draft>> {
  @override
  Future<List<Draft>> build() async {
    final store = ref.read(draftStoreProvider);
    return store.loadDrafts();
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final store = ref.read(draftStoreProvider);
      return store.loadDrafts();
    });
  }

  Future<void> delete(String id) async {
    final store = ref.read(draftStoreProvider);
    await store.deleteDraft(id);
    await refresh();
  }

  Future<void> markScheduled(Draft draft) async {
    final store = ref.read(draftStoreProvider);
    final updated = Draft(
      id: draft.id,
      rawText: draft.rawText,
      generated: draft.generated,
      status: 'scheduled',
      createdAt: draft.createdAt,
    );
    await store.saveDraft(updated);
    await refresh();
  }
}

final draftListProvider = AsyncNotifierProvider<DraftListNotifier, List<Draft>>(DraftListNotifier.new);
