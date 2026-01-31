import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/settings_store.dart';

final settingsStoreProvider = Provider<SettingsStore>((ref) => SettingsStore());

class SettingsNotifier extends AsyncNotifier<AppSettings> {
  @override
  Future<AppSettings> build() async {
    final store = ref.read(settingsStoreProvider);
    return store.loadSettings();
  }

  AppSettings _currentSettings() {
    return state.value ?? AppSettings.defaults();
  }

  Future<void> save(AppSettings settings) async {
    final store = ref.read(settingsStoreProvider);
    await store.saveSettings(settings);
    state = AsyncValue.data(settings);
  }

  Future<void> updateNotifications(bool enabled) async {
    final current = _currentSettings();
    await save(current.copyWith(notificationsEnabled: enabled));
  }

  Future<void> updateDefaults({required String hashtags, required String template}) async {
    final current = _currentSettings();
    await save(current.copyWith(defaultHashtags: hashtags, defaultTemplate: template));
  }
}

final settingsProvider = AsyncNotifierProvider<SettingsNotifier, AppSettings>(SettingsNotifier.new);
