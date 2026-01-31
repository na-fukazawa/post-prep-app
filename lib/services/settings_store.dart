import 'package:shared_preferences/shared_preferences.dart';

class AppSettings {
  final bool notificationsEnabled;
  final String defaultHashtags;
  final String defaultTemplate;

  const AppSettings({
    required this.notificationsEnabled,
    required this.defaultHashtags,
    required this.defaultTemplate,
  });

  factory AppSettings.defaults() {
    return const AppSettings(
      notificationsEnabled: true,
      defaultHashtags: '',
      defaultTemplate: '',
    );
  }

  AppSettings copyWith({
    bool? notificationsEnabled,
    String? defaultHashtags,
    String? defaultTemplate,
  }) {
    return AppSettings(
      notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
      defaultHashtags: defaultHashtags ?? this.defaultHashtags,
      defaultTemplate: defaultTemplate ?? this.defaultTemplate,
    );
  }
}

class SettingsStore {
  static const _notificationsKey = 'settings_notifications_enabled';
  static const _hashtagsKey = 'settings_default_hashtags';
  static const _templateKey = 'settings_default_template';

  Future<AppSettings> loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    final defaults = AppSettings.defaults();
    return AppSettings(
      notificationsEnabled: prefs.getBool(_notificationsKey) ?? defaults.notificationsEnabled,
      defaultHashtags: prefs.getString(_hashtagsKey) ?? defaults.defaultHashtags,
      defaultTemplate: prefs.getString(_templateKey) ?? defaults.defaultTemplate,
    );
  }

  Future<void> saveSettings(AppSettings settings) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_notificationsKey, settings.notificationsEnabled);
    await prefs.setString(_hashtagsKey, settings.defaultHashtags);
    await prefs.setString(_templateKey, settings.defaultTemplate);
  }
}
