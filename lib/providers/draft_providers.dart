import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/draft_store.dart';

enum DraftFilter {
  all,
  scheduled,
  draft,
  posted,
  failed,
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
      case DraftFilter.failed:
        return '投稿失敗';
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

  Future<void> save(Draft draft) async {
    final store = ref.read(draftStoreProvider);
    await store.saveDraft(draft);
    await refresh();
  }

  Future<void> clearAll() async {
    final store = ref.read(draftStoreProvider);
    await store.clearAllDrafts();
    await refresh();
  }

  Future<void> updateStatus(Draft draft, String status) async {
    final store = ref.read(draftStoreProvider);
    final updated = Draft(
      id: draft.id,
      rawText: draft.rawText,
      generated: draft.generated,
      status: status,
      createdAt: draft.createdAt,
      title: draft.title,
      publishAt: draft.publishAt,
      targets: draft.targets,
      captionX: draft.captionX,
      captionInstagram: draft.captionInstagram,
      hashtags: draft.hashtags,
      eventDate: draft.eventDate,
      venue: draft.venue,
      performers: draft.performers,
      ticketPrice: draft.ticketPrice,
      ticketUrl: draft.ticketUrl,
      imageUrls: draft.imageUrls,
    );
    await store.saveDraft(updated);
    await refresh();
  }

  Future<void> markScheduled(Draft draft) async {
    await updateStatus(draft, 'scheduled');
  }

  Future<void> markPosted(Draft draft) async {
    await updateStatus(draft, 'posted');
  }

  Future<void> markFailed(Draft draft) async {
    await updateStatus(draft, 'failed');
  }
}

final draftListProvider = AsyncNotifierProvider<DraftListNotifier, List<Draft>>(DraftListNotifier.new);
