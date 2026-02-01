import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/draft_store.dart';
import '../services/notification_service.dart';
import 'settings_providers.dart';

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
    await NotificationService.instance.cancelDraftNotification(id);
    await store.deleteDraft(id);
    await refresh();
  }

  Future<void> save(Draft draft) async {
    final store = ref.read(draftStoreProvider);
    await store.saveDraft(draft);
    await _syncNotificationForDraft(draft);
    await refresh();
  }

  Future<void> clearAll() async {
    final store = ref.read(draftStoreProvider);
    await NotificationService.instance.cancelAll();
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
      xTaggedUserIds: draft.xTaggedUserIds,
      xTaggedUsernames: draft.xTaggedUsernames,
    );
    await store.saveDraft(updated);
    await _syncNotificationForDraft(updated);
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

  Future<void> syncNotificationsForAll({required bool enabled}) async {
    if (!enabled) {
      await NotificationService.instance.cancelAll();
      return;
    }
    final store = ref.read(draftStoreProvider);
    final drafts = await store.loadDrafts();
    for (final draft in drafts) {
      if (draft.status == 'scheduled') {
        await NotificationService.instance.scheduleDraftNotification(draft);
      } else {
        await NotificationService.instance.cancelDraftNotification(draft.id);
      }
    }
  }

  Future<bool> _notificationsEnabled() async {
    final settings = ref.read(settingsProvider);
    if (settings.hasValue) {
      return settings.value!.notificationsEnabled;
    }
    final store = ref.read(settingsStoreProvider);
    final loaded = await store.loadSettings();
    return loaded.notificationsEnabled;
  }

  Future<void> _syncNotificationForDraft(Draft draft) async {
    final enabled = await _notificationsEnabled();
    if (draft.status == 'scheduled' && enabled) {
      await NotificationService.instance.scheduleDraftNotification(draft);
    } else {
      await NotificationService.instance.cancelDraftNotification(draft.id);
    }
  }
}

final draftListProvider = AsyncNotifierProvider<DraftListNotifier, List<Draft>>(DraftListNotifier.new);
