import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/draft_providers.dart';
import '../providers/settings_providers.dart';
import '../services/settings_store.dart';

class AppSettingScreen extends ConsumerStatefulWidget {
  const AppSettingScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<AppSettingScreen> createState() => _AppSettingScreenState();
}

class _AppSettingScreenState extends ConsumerState<AppSettingScreen> {
  static const Color primary = Color(0xFF00FFCC);
  static const Color backgroundDark = Color(0xFF0E121A);
  static const Color surfaceDark = Color(0xFF161B26);
  static const Color inputDark = Color(0xFF1F2735);
  static const Color mutedText = Color(0xFF9AA3B2);

  static const String appVersion = '0.0.1';

  late TextEditingController _hashtagsController;
  late TextEditingController _templateController;
  bool _didInit = false;

  @override
  void initState() {
    super.initState();
    _hashtagsController = TextEditingController();
    _templateController = TextEditingController();
  }

  @override
  void dispose() {
    _hashtagsController.dispose();
    _templateController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final settingsAsync = ref.watch(settingsProvider);

    return Scaffold(
      backgroundColor: backgroundDark,
      appBar: AppBar(
        backgroundColor: backgroundDark,
        elevation: 0,
        title: const Text('設定'),
      ),
      body: Listener(
        behavior: HitTestBehavior.translucent,
        onPointerDown: (_) => FocusManager.instance.primaryFocus?.unfocus(),
        child: SafeArea(
          child: settingsAsync.when(
            data: (settings) {
              if (!_didInit) {
                _hashtagsController.text = settings.defaultHashtags;
                _templateController.text = settings.defaultTemplate;
                _didInit = true;
              }
              return _buildContent(settings);
            },
            loading: () => const Center(child: CircularProgressIndicator(color: primary)),
            error: (_, __) => _buildErrorState(),
          ),
        ),
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('読み込みに失敗しました。', style: TextStyle(color: Colors.white)),
          const SizedBox(height: 12),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: primary,
              foregroundColor: Colors.black,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () => ref.invalidate(settingsProvider),
            child: const Text('再読み込み'),
          ),
        ],
      ),
    );
  }

  Widget _buildContent(AppSettings settings) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
      children: [
        _sectionTitle('通知設定'),
        _card(
          child: SwitchListTile(
            value: settings.notificationsEnabled,
            activeColor: primary,
            onChanged: (value) => ref.read(settingsProvider.notifier).updateNotifications(value),
            title: const Text('通知を有効にする', style: TextStyle(color: Colors.white)),
            subtitle: const Text('OFFの場合は通知登録を行いません。', style: TextStyle(color: mutedText)),
          ),
        ),
        const SizedBox(height: 20),
        _sectionTitle('投稿デフォルト設定'),
        _card(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('デフォルトハッシュタグ', style: TextStyle(color: mutedText)),
              const SizedBox(height: 8),
              TextField(
                controller: _hashtagsController,
                style: const TextStyle(color: Colors.white),
                keyboardAppearance: Brightness.dark,
                decoration: _inputDecoration('例: #ライブ #イベント'),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        _sectionTitle('定型文テンプレート'),
        _card(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('本文の初期テンプレート', style: TextStyle(color: mutedText)),
              const SizedBox(height: 8),
              TextField(
                controller: _templateController,
                maxLines: 4,
                style: const TextStyle(color: Colors.white),
                keyboardAppearance: Brightness.dark,
                decoration: _inputDecoration('例: 本日開催です！ぜひお越しください。'),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: () => _saveDefaults(settings),
            style: ElevatedButton.styleFrom(
              backgroundColor: primary,
              foregroundColor: Colors.black,
              padding: const EdgeInsets.symmetric(vertical: 14),
            ),
            child: const Text('保存する'),
          ),
        ),
        const SizedBox(height: 24),
        _sectionTitle('データ管理'),
        _card(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('全告知データ削除', style: TextStyle(color: Colors.white)),
              const SizedBox(height: 8),
              const Text('端末内に保存された告知をすべて削除します。', style: TextStyle(color: mutedText)),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _confirmClearAll,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFB02929),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  child: const Text('全告知データ削除'),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        _sectionTitle('バージョン'),
        Text('v$appVersion', style: const TextStyle(color: mutedText)),
      ],
    );
  }

  Widget _sectionTitle(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        text,
        style: const TextStyle(
          color: mutedText,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _card({required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: surfaceDark,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFF1F2735)),
      ),
      child: child,
    );
  }

  InputDecoration _inputDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(color: mutedText),
      filled: true,
      fillColor: inputDark,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
    );
  }

  Future<void> _saveDefaults(AppSettings settings) async {
    final hashtags = _hashtagsController.text.trim();
    final template = _templateController.text.trim();
    await ref.read(settingsProvider.notifier).updateDefaults(
          hashtags: hashtags,
          template: template,
        );
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('保存しました')));
  }

  Future<void> _confirmClearAll() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('全削除しますか？'),
        content: const Text('保存されている告知データをすべて削除します。'),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('キャンセル')),
          TextButton(onPressed: () => Navigator.of(context).pop(true), child: const Text('削除する')),
        ],
      ),
    );
    if (confirmed != true) return;
    await ref.read(draftListProvider.notifier).clearAll();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('告知データを削除しました')));
  }
}
