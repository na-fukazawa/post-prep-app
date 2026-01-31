import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';
import '../providers/draft_providers.dart';
import '../services/draft_store.dart';
import 'create_announcement.dart';

class PostPreparerationScreen extends ConsumerStatefulWidget {
  const PostPreparerationScreen({Key? key, required this.draftId}) : super(key: key);

  final String draftId;

  @override
  ConsumerState<PostPreparerationScreen> createState() => _PostPreparerationScreenState();
}

class _PostPreparerationScreenState extends ConsumerState<PostPreparerationScreen> {
  static const Color primary = Color(0xFF00FFCC);
  static const Color backgroundDark = Color(0xFF0E121A);
  static const Color surfaceDark = Color(0xFF161B26);
  static const Color surfaceDarkElevated = Color(0xFF1B2230);
  static const Color mutedText = Color(0xFF9AA3B2);
  static const Color subduedText = Color(0xFF7C8595);
  static const String instagramIconAsset = 'assets/icons/instagram.jpg';
  static const String xIconAsset = 'assets/icons/x.jpg';

  late final PageController _pageController;
  int _currentImageIndex = 0;

  static const List<String> previewImages = [
    'https://lh3.googleusercontent.com/aida-public/AB6AXuA1-L2pzadFAl73MEesP1ktDxNsaeVSg79ZDB82JN8bKuxQsRPBH_pdpZrmblPii1CQcIUs131V4-qCVCVQOrYm1QKqGlKdfBdRjjMC1cfbeQp41--t0ygT2XzVTS8mMXb7iF721S1JVtD_nylEF1B6OZkfcXUdaCZ1lWhW5cOLBlcrtYe4b4aGXhjnXNLG6TRDYCajAnkts7zN05rGF55hEuISADKRZVHwckKF4H2Uldwl2TeCXz7dNL95heNoq0dmFYPFZwXSuFPc',
    'https://lh3.googleusercontent.com/aida-public/AB6AXuDzh9YKMlrsA0RKU6EFe4jj-sxLQCOvnV-vq5sjpbP5XK1NEzvb8gPYs1OsEvvmmFGQY68DWUPKDHXF8mPsatSiLkUrRy1jRmdMoN2gElPUg2dSNP4MMlemea4AjBSj9lHX1nCqsbTIPLBHqth7QUsTsxOOo2HOYJeEF1uiRfEApqh3_Nz8GShw1O75AiW6lniMJZQhz6nsfjYPmk78WdoCohFFYoHAufZIFepp71eSQsFEU-mwXmsYbqcnWa1nhc4PlVP_rgQ2cGCX',
    'https://lh3.googleusercontent.com/aida-public/AB6AXuBxXiBK-BrGdvUoD_GZrj8MYhOyN0AtHW4UXWpbWvMLv0mowtXUN4iUCo9y8pQQC-zWPoHBPgTVt-gAUk2RdP8mkx423v9cSRvGrl8XR85OE8ofV5XBCcuSmxcjlFiyu4ewbMs-EZ11COSAGnNIq0QCB__t7nz__9l9kdnmmdrnfdUs-96s5S_3AHQ5XWV6YWZIEcWNgMKO2l36Dh5G-q8nEkQhhSrvxYxZWWQnbaVwyOdJ4LhkyljjoTENIczndPcnYiZ0TeOnVpn4',
    'https://lh3.googleusercontent.com/aida-public/AB6AXuA5eIpaRB6EVvGKbIgEEYMseCzGHUYtQ6FHbyxwXag82A8wwj54JaeFYaM3xTrtliWkp2lpty6TFIvFzzeS-LI6vJYDUggJCQnyxqPEFdOb-KhuS751adRnkl9PRnJiMqaXMwDeYSU1t2W4ixUpMudDOQ8d82udY_SW7uEObRtpGQnnMINOb0b68p-Fzq1oBQ0Yufg8UzjZcm7vC9bwhy6fIMvD-fddWAwt0oRddq6H977OxubNZZ9KVYEeyNMm2xkaxRaSD60Uj_Q4',
  ];

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final draftsAsync = ref.watch(draftListProvider);

    return Scaffold(
      backgroundColor: backgroundDark,
      body: SafeArea(
        child: draftsAsync.when(
          data: (drafts) {
            final match = drafts.where((draft) => draft.id == widget.draftId).toList();
            if (match.isEmpty) {
              return _buildMissingState(context);
            }
            final draft = match.first;
            final bodyText = _baseCaption(draft);
            final captionX = _composeCaption(draft, base: draft.captionX.isNotEmpty ? draft.captionX : bodyText);
            final captionInstagram = _composeCaption(
              draft,
              base: draft.captionInstagram.isNotEmpty ? draft.captionInstagram : bodyText,
            );
            final timeLabel = _formatDateLabel(draft.publishAt);
            final targets = _normalizedTargets(draft);
            final showX = targets.isEmpty || targets.contains('x');
            final showIg = targets.isEmpty || targets.contains('instagram');
            final isFailed = draft.status == 'failed';
            final isPosted = draft.status == 'posted';
            final heroImages = _heroImagesForDraft(draft);

            return Stack(
              children: [
                SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 140),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildHeader(context, ref, draft),
                      const SizedBox(height: 16),
                      _buildHeroImage(heroImages),
                      const SizedBox(height: 16),
                      _buildGuideCard(),
                      const SizedBox(height: 18),
                      _buildMetaRow(draft, timeLabel),
                      if (_hasEventDetails(draft)) ...[
                        const SizedBox(height: 16),
                        _buildEventCard(draft),
                      ],
                      if (isFailed) ...[
                        const SizedBox(height: 12),
                        _buildFailedCard(context, ref, draft),
                      ],
                      if (showX) ...[
                        const SizedBox(height: 16),
                        _buildShareCard(
                          context,
                          ref,
                          draft,
                          title: 'X (Twitter)',
                          subtitle: '告知ポストを作成',
                          stepLabel: 'ステップ 1: 本文',
                          badgeText: '${captionX.length}文字',
                          bodyText: captionX,
                          actionLabel: 'Xでシェア',
                        ),
                      ],
                      if (showIg) ...[
                        const SizedBox(height: 16),
                        _buildShareCard(
                          context,
                          ref,
                          draft,
                          title: 'Instagram',
                          subtitle: 'フィード・ストーリーに投稿',
                          stepLabel: 'ステップ 1: キャプション',
                          badgeText: 'ハッシュタグ付き',
                          bodyText: captionInstagram,
                          actionLabel: 'Instagramでシェア',
                        ),
                      ],
                    ],
                  ),
                ),
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 0,
                  child: _buildFooterAction(context, ref, draft, isPosted),
                ),
              ],
            );
          },
          loading: () => const Center(child: CircularProgressIndicator(color: primary)),
          error: (_, __) => _buildMissingState(context),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, WidgetRef ref, Draft draft) {
    return Row(
      children: [
        IconButton(
          onPressed: () => Navigator.of(context).pop(),
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white),
        ),
        const Spacer(),
        const Text(
          '投稿準備',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        const Spacer(),
        IconButton(
          onPressed: () async {
            await Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => CreateAnnouncementScreen(draft: draft)),
            );
            await ref.read(draftListProvider.notifier).refresh();
          },
          icon: const Icon(Icons.edit, color: subduedText),
        ),
      ],
    );
  }

  Widget _buildHeroImage(List<String> imageUrls) {
    final showDots = imageUrls.length > 1;
    return Column(
      children: [
        Center(
          child: Container(
            width: 280,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.35),
                  blurRadius: 30,
                  offset: const Offset(0, 16),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: AspectRatio(
                aspectRatio: 4 / 5,
                child: PageView.builder(
                  controller: _pageController,
                  itemCount: imageUrls.length,
                  onPageChanged: (index) => setState(() => _currentImageIndex = index),
                  itemBuilder: (context, index) {
                    final imageUrl = imageUrls[index];
                    return Image.network(
                      imageUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(
                        color: surfaceDarkElevated,
                        child: const Icon(Icons.image, color: mutedText, size: 40),
                      ),
                    );
                  },
                ),
              ),
            ),
          ),
        ),
        if (showDots) ...[
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              for (var i = 0; i < imageUrls.length; i++)
                Container(
                  width: 6,
                  height: 6,
                  margin: const EdgeInsets.symmetric(horizontal: 3),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: i == _currentImageIndex ? primary : Colors.white24,
                  ),
                ),
            ],
          ),
        ],
      ],
    );
  }

  Widget _buildGuideCard() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF0D2A2F),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFF123C3A)),
      ),
      child: const Text(
        '投稿手順:\n① 本文をコピーする ② シェアボタンを押す ③ SNSが開いたら画像を貼り付けて投稿！',
        style: TextStyle(
          fontSize: 12,
          height: 1.4,
          fontWeight: FontWeight.w600,
          color: Colors.white70,
        ),
      ),
    );
  }

  Widget _buildMetaRow(Draft draft, String timeLabel) {
    final title = _titleFromDraft(draft);
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        Row(
          children: [
            const Icon(Icons.schedule, size: 14, color: subduedText),
            const SizedBox(width: 4),
            Text(
              timeLabel,
              style: const TextStyle(fontSize: 11, color: subduedText),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildFailedCard(BuildContext context, WidgetRef ref, Draft draft) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF2B1B1B),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF5C2A2A)),
      ),
      child: Row(
        children: [
          const Icon(Icons.priority_high, color: Colors.redAccent),
          const SizedBox(width: 8),
          const Expanded(
            child: Text(
              '投稿に失敗しました。接続を確認してください。',
              style: TextStyle(color: Colors.white70, fontSize: 12),
            ),
          ),
          TextButton(
            onPressed: () => ref.read(draftListProvider.notifier).markScheduled(draft),
            child: const Text('再試行', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Widget _buildShareCard(
    BuildContext context,
    WidgetRef ref,
    Draft draft, {
    required String title,
    required String subtitle,
    required String stepLabel,
    required String badgeText,
    required String bodyText,
    required String actionLabel,
  }) {
    final platformIcon = title.toLowerCase().contains('instagram')
        ? instagramIconAsset
        : xIconAsset;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: surfaceDark,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFF1F2735)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
                ClipOval(
                  child: Image.asset(
                    platformIcon,
                    width: 28,
                    height: 28,
                    fit: BoxFit.cover,
                  ),
                ),
              const SizedBox(width: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  Text(subtitle, style: const TextStyle(fontSize: 11, color: subduedText)),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFF101723),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFF1C2433)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(stepLabel, style: const TextStyle(fontSize: 10, color: mutedText, fontWeight: FontWeight.bold)),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1F2735),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        badgeText,
                        style: const TextStyle(fontSize: 10, color: Colors.white70),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  bodyText.isEmpty ? '本文が未入力です。' : bodyText,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 12, color: Colors.white70, height: 1.4),
                ),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: () => _showFullText(context, title, bodyText),
                    child: const Text('全文を見る', style: TextStyle(color: mutedText)),
                  ),
                ),
                const SizedBox(height: 10),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () => _copyText(context, bodyText),
                    icon: const Icon(Icons.copy, size: 16, color: Colors.white70),
                    label: const Text('本文をコピー', style: TextStyle(color: Colors.white70)),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Color(0xFF2B3546)),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () => _shareText(context, ref, draft, bodyText),
              icon: const Icon(Icons.ios_share, size: 18),
              label: Text(actionLabel),
              style: ElevatedButton.styleFrom(
                backgroundColor: primary,
                foregroundColor: Colors.black,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFooterAction(BuildContext context, WidgetRef ref, Draft draft, bool isPosted) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
      decoration: BoxDecoration(
        color: backgroundDark.withOpacity(0.96),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.4),
            blurRadius: 24,
            offset: const Offset(0, -8),
          ),
        ],
      ),
      child: SizedBox(
        width: double.infinity,
        child: ElevatedButton.icon(
          onPressed: isPosted
              ? null
              : () async {
                  await ref.read(draftListProvider.notifier).markPosted(draft);
                  if (!context.mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('投稿済みに更新しました')));
                },
          icon: const Icon(Icons.check_circle),
          label: Text(isPosted ? '投稿済み' : '投稿完了としてマーク'),
          style: ElevatedButton.styleFrom(
            backgroundColor: primary,
            foregroundColor: Colors.black,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          ),
        ),
      ),
    );
  }

  bool _hasEventDetails(Draft draft) {
    return draft.eventDate.trim().isNotEmpty ||
        draft.venue.trim().isNotEmpty ||
        draft.performers.trim().isNotEmpty ||
        draft.ticketPrice.trim().isNotEmpty ||
        draft.ticketUrl.trim().isNotEmpty;
  }

  Widget _buildEventCard(Draft draft) {
    final rows = <Widget>[
      if (draft.eventDate.trim().isNotEmpty) _infoRow('日時', draft.eventDate),
      if (draft.venue.trim().isNotEmpty) _infoRow('会場', draft.venue),
      if (draft.performers.trim().isNotEmpty) _infoRow('出演者', draft.performers),
      if (draft.ticketPrice.trim().isNotEmpty) _infoRow('料金', draft.ticketPrice),
      if (draft.ticketUrl.trim().isNotEmpty) _infoRow('URL', draft.ticketUrl),
    ];

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: surfaceDark,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFF1F2735)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('イベント詳細', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          const SizedBox(height: 10),
          for (var i = 0; i < rows.length; i++) ...[
            rows[i],
            if (i != rows.length - 1) const SizedBox(height: 6),
          ],
        ],
      ),
    );
  }

  Widget _infoRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 42,
          child: Text(label, style: const TextStyle(fontSize: 11, color: mutedText)),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(fontSize: 12, color: Colors.white70),
          ),
        ),
      ],
    );
  }

  Widget _buildMissingState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('告知が見つかりませんでした。', style: TextStyle(color: Colors.white)),
          const SizedBox(height: 12),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(),
            style: ElevatedButton.styleFrom(backgroundColor: primary, foregroundColor: Colors.black),
            child: const Text('戻る'),
          ),
        ],
      ),
    );
  }

  void _showFullText(BuildContext context, String title, String text) {
    if (text.trim().isEmpty) return;
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: backgroundDark,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        final height = MediaQuery.of(context).size.height * 0.6;
        return Padding(
          padding: EdgeInsets.fromLTRB(20, 16, 20, MediaQuery.of(context).viewInsets.bottom + 20),
          child: SizedBox(
            height: height,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                ),
                const SizedBox(height: 12),
                Expanded(
                  child: SingleChildScrollView(
                    child: Text(
                      text,
                      style: const TextStyle(fontSize: 13, color: Colors.white70, height: 1.5),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _copyText(BuildContext context, String text) async {
    if (text.isEmpty) return;
    await Clipboard.setData(ClipboardData(text: text));
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('コピーしました')));
  }

  Future<void> _shareText(BuildContext context, WidgetRef ref, Draft draft, String text) async {
    if (text.isEmpty) return;
    try {
      await Share.share(text);
    } catch (_) {
      await ref.read(draftListProvider.notifier).markFailed(draft);
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('共有に失敗しました')));
    }
  }

  String _formatDateLabel(int millis) {
    final date = DateTime.fromMillisecondsSinceEpoch(millis);
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');
    final hour = date.hour.toString().padLeft(2, '0');
    final minute = date.minute.toString().padLeft(2, '0');
    return '$month/$day $hour:$minute';
  }

  List<String> _heroImagesForDraft(Draft draft) {
    if (draft.imageUrls.isNotEmpty) {
      return draft.imageUrls;
    }
    return [_imageUrlForDraft(draft)];
  }

  String _imageUrlForDraft(Draft draft) {
    final index = draft.id.hashCode.abs() % previewImages.length;
    return previewImages[index];
  }

  String _titleFromDraft(Draft draft) {
    if (draft.title.trim().isNotEmpty) return draft.title.trim();
    final raw = draft.rawText.trim();
    if (raw.isEmpty) return '無題の告知';
    final firstLine = raw.split(RegExp(r'\r?\n')).first.trim();
    return firstLine.isEmpty ? '無題の告知' : firstLine;
  }

  String _baseCaption(Draft draft) {
    final generated = draft.generated.trim();
    if (generated.isNotEmpty) return generated;
    return draft.rawText.trim();
  }

  String _composeCaption(Draft draft, {required String base}) {
    final tags = draft.hashtags.trim();
    if (tags.isEmpty) return base.trim();
    final normalized = base.trim();
    if (normalized.isEmpty) return tags;
    return '$normalized\n$tags';
  }

  Set<String> _normalizedTargets(Draft draft) {
    return draft.targets
        .map((target) => target.toLowerCase())
        .where((target) => target.isNotEmpty)
        .toSet();
  }
}
