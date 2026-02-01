import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/draft_providers.dart';
import '../providers/settings_providers.dart';
import '../providers/x_auth_providers.dart';
import '../services/notification_service.dart';
import '../services/settings_store.dart';
import '../services/x_auth_store.dart';
import '../services/x_feature_flags.dart';

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

  late TextEditingController _templateController;
  bool _didInit = false;

  @override
  void initState() {
    super.initState();
    _templateController = TextEditingController();
    if (XFeatureFlags.enableDirectPost) {
      Future.microtask(() => ref.read(xAuthProvider.notifier).init());
    }
  }

  @override
  void dispose() {
    _templateController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final settingsAsync = ref.watch(settingsProvider);
    final xAuthState = XFeatureFlags.enableDirectPost ? ref.watch(xAuthProvider) : null;

    return Scaffold(
      backgroundColor: backgroundDark,
      appBar: AppBar(
        backgroundColor: backgroundDark,
        elevation: 0,
        centerTitle: true,
        foregroundColor: Colors.white,
        systemOverlayStyle: SystemUiOverlayStyle.light,
        title: const Text(
          '設定',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(1),
          child: Divider(height: 1, color: Color(0xFF1F2735)),
        ),
      ),
      body: Listener(
        behavior: HitTestBehavior.translucent,
        onPointerDown: (_) => FocusManager.instance.primaryFocus?.unfocus(),
        child: SafeArea(
          child: settingsAsync.when(
            data: (settings) {
              if (!_didInit) {
                _templateController.text = settings.defaultTemplate;
                _didInit = true;
              }
              return _buildContent(settings, xAuthState);
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

  Widget _buildContent(AppSettings settings, XAuthState? xAuthState) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
      children: [
        _sectionTitle('通知設定'),
        _card(
          child: SwitchListTile(
            value: settings.notificationsEnabled,
            activeColor: primary,
            onChanged: (value) async {
              if (value) {
                final granted = await NotificationService.instance.requestPermissions();
                if (!granted) {
                  if (!mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('通知が許可されていません。端末設定で許可してください。')),
                  );
                  return;
                }
              }
              await ref.read(settingsProvider.notifier).updateNotifications(value);
              await ref.read(draftListProvider.notifier).syncNotificationsForAll(enabled: value);
            },
            title: const Text('通知を有効にする', style: TextStyle(color: Colors.white)),
            subtitle: const Text('OFFの場合は通知登録を行いません。', style: TextStyle(color: mutedText)),
          ),
        ),
        const SizedBox(height: 20),
        _sectionTitle('整形テンプレート'),
        _card(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'AIがこの形式に合わせて整形します（{title} / {body} で差し込み可）',
                style: TextStyle(color: mutedText),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _templateController,
                maxLines: 4,
                style: const TextStyle(color: Colors.white),
                keyboardAppearance: Brightness.dark,
                decoration: _inputDecoration('例: 【📣LIVE INFO📣】\n{title}\n\n{body}'),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: _saveTemplate,
            style: ElevatedButton.styleFrom(
              backgroundColor: primary,
              foregroundColor: Colors.black,
              padding: const EdgeInsets.symmetric(vertical: 14),
            ),
            child: const Text('保存する'),
          ),
        ),
        if (XFeatureFlags.enableDirectPost && xAuthState != null) ...[
          _sectionTitle('X連携'),
          _card(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  xAuthState.isConnected ? '連携済み' : '未連携',
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Xの投稿と画像タグ付けをアプリ内で行います。',
                  style: TextStyle(color: mutedText),
                ),
                if (xAuthState.accounts.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  for (final account in xAuthState.accounts)
                    _accountRow(
                      account: account,
                      activeId: xAuthState.activeAccount?.userId,
                      onSwitch: () => ref.read(xAuthProvider.notifier).switchAccount(account.userId),
                      onRemove: () => ref.read(xAuthProvider.notifier).removeAccount(account.userId),
                    ),
                ],
                if (xAuthState.error != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    xAuthState.error!,
                    style: const TextStyle(color: Colors.redAccent, fontSize: 12),
                  ),
                ],
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: xAuthState.isBusy
                        ? null
                        : () async {
                            final ok = await ref.read(xAuthProvider.notifier).signIn();
                            if (!ok && mounted) {
                              final error = ref.read(xAuthProvider).error ?? 'X連携に失敗しました。';
                              ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error)));
                            }
                          },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primary,
                      foregroundColor: Colors.black,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    child: const Text('Xアカウントを追加'),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
        ],
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

  Widget _accountRow({
    required XAccount account,
    required String? activeId,
    required VoidCallback onSwitch,
    required VoidCallback onRemove,
  }) {
    final isActive = account.userId == activeId;
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: inputDark,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: isActive ? primary : Colors.white10),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  account.username.isEmpty ? 'linked' : '@${account.username}',
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
                ),
                if (account.name.isNotEmpty)
                  Text(
                    account.name,
                    style: const TextStyle(color: mutedText, fontSize: 11),
                  ),
              ],
            ),
          ),
          if (isActive)
            const Text('使用中', style: TextStyle(color: primary, fontSize: 11, fontWeight: FontWeight.bold))
          else
            TextButton(
              onPressed: onSwitch,
              child: const Text('切替', style: TextStyle(color: primary)),
            ),
          IconButton(
            onPressed: onRemove,
            icon: const Icon(Icons.delete_outline, color: Colors.white70, size: 18),
          ),
        ],
      ),
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

  Future<void> _saveTemplate() async {
    final template = _templateController.text.trim();
    await ref.read(settingsProvider.notifier).updateTemplate(template);
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
