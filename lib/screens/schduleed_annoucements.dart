import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/draft_providers.dart';
import '../services/draft_store.dart';
import 'post_prepareration.dart';
import 'create_announcement.dart';

class SchduleedAnnoucementsScreen extends ConsumerWidget {
  const SchduleedAnnoucementsScreen({Key? key}) : super(key: key);

  static const Color primary = Color(0xFF00FFCC);
  static const Color backgroundDark = Color(0xFF0E121A);
  static const Color surfaceDark = Color(0xFF161B26);
  static const Color surfaceDarkElevated = Color(0xFF1B2230);
  static const Color chipBorder = Color(0xFF2A3240);
  static const Color mutedText = Color(0xFF9AA3B2);
  static const Color subduedText = Color(0xFF7C8595);

  static const List<String> previewImages = [
    'https://lh3.googleusercontent.com/aida-public/AB6AXuA1-L2pzadFAl73MEesP1ktDxNsaeVSg79ZDB82JN8bKuxQsRPBH_pdpZrmblPii1CQcIUs131V4-qCVCVQOrYm1QKqGlKdfBdRjjMC1cfbeQp41--t0ygT2XzVTS8mMXb7iF721S1JVtD_nylEF1B6OZkfcXUdaCZ1lWhW5cOLBlcrtYe4b4aGXhjnXNLG6TRDYCajAnkts7zN05rGF55hEuISADKRZVHwckKF4H2Uldwl2TeCXz7dNL95heNoq0dmFYPFZwXSuFPc',
    'https://lh3.googleusercontent.com/aida-public/AB6AXuDzh9YKMlrsA0RKU6EFe4jj-sxLQCOvnV-vq5sjpbP5XK1NEzvb8gPYs1OsEvvmmFGQY68DWUPKDHXF8mPsatSiLkUrRy1jRmdMoN2gElPUg2dSNP4MMlemea4AjBSj9lHX1nCqsbTIPLBHqth7QUsTsxOOo2HOYJeEF1uiRfEApqh3_Nz8GShw1O75AiW6lniMJZQhz6nsfjYPmk78WdoCohFFYoHAufZIFepp71eSQsFEU-mwXmsYbqcnWa1nhc4PlVP_rgQ2cGCX',
    'https://lh3.googleusercontent.com/aida-public/AB6AXuBxXiBK-BrGdvUoD_GZrj8MYhOyN0AtHW4UXWpbWvMLv0mowtXUN4iUCo9y8pQQC-zWPoHBPgTVt-gAUk2RdP8mkx423v9cSRvGrl8XR85OE8ofV5XBCcuSmxcjlFiyu4ewbMs-EZ11COSAGnNIq0QCB__t7nz__9l9kdnmmdrnfdUs-96s5S_3AHQ5XWV6YWZIEcWNgMKO2l36Dh5G-q8nEkQhhSrvxYxZWWQnbaVwyOdJ4LhkyljjoTENIczndPcnYiZ0TeOnVpn4',
    'https://lh3.googleusercontent.com/aida-public/AB6AXuA5eIpaRB6EVvGKbIgEEYMseCzGHUYtQ6FHbyxwXag82A8wwj54JaeFYaM3xTrtliWkp2lpty6TFIvFzzeS-LI6vJYDUggJCQnyxqPEFdOb-KhuS751adRnkl9PRnJiMqaXMwDeYSU1t2W4ixUpMudDOQ8d82udY_SW7uEObRtpGQnnMINOb0b68p-Fzq1oBQ0Yufg8UzjZcm7vC9bwhy6fIMvD-fddWAwt0oRddq6H977OxubNZZ9KVYEeyNMm2xkaxRaSD60Uj_Q4',
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final filter = ref.watch(draftFilterProvider);
    final draftsAsync = ref.watch(draftListProvider);
    const isDark = true;

    return Scaffold(
      backgroundColor: backgroundDark,
      body: SafeArea(
        child: draftsAsync.when(
          data: (drafts) {
            final filtered = _applyFilter(drafts, filter);
            return RefreshIndicator(
              color: primary,
              backgroundColor: surfaceDark,
              displacement: 32,
              onRefresh: () => ref.read(draftListProvider.notifier).refresh(),
              child: _buildBody(context, ref, filtered, filter, isDark),
            );
          },
          loading: () => const Center(child: CircularProgressIndicator(color: primary)),
          error: (_, __) => _buildErrorState(context, ref),
        ),
      ),
      floatingActionButton: _buildFab(context, ref),
    );
  }

  List<Draft> _applyFilter(List<Draft> drafts, DraftFilter filter) {
    switch (filter) {
      case DraftFilter.scheduled:
        return drafts.where((draft) => draft.status == 'scheduled').toList();
      case DraftFilter.draft:
        return drafts.where((draft) => draft.status == 'draft').toList();
      case DraftFilter.posted:
        return drafts.where((draft) => draft.status == 'posted').toList();
      case DraftFilter.failed:
        return drafts.where((draft) => draft.status == 'failed').toList();
      case DraftFilter.all:
      default:
        return drafts;
    }
  }

  Widget _buildErrorState(BuildContext context, WidgetRef ref) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('読み込みに失敗しました。', style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: primary,
              foregroundColor: Colors.black,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () => ref.read(draftListProvider.notifier).refresh(),
            child: const Text('再読み込み'),
          ),
        ],
      ),
    );
  }

  Widget _buildBody(BuildContext context, WidgetRef ref, List<Draft> drafts, DraftFilter filter, bool isDark) {
    final sections = _buildSections(drafts);

    return CustomScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      slivers: [
        SliverToBoxAdapter(child: _buildHeader(context, isDark)),
        SliverToBoxAdapter(child: _buildFilterChips(ref, filter, isDark)),
        if (drafts.isEmpty)
          SliverFillRemaining(
            hasScrollBody: false,
            child: _buildEmptyState(context, isDark),
          )
        else
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 140),
            sliver: SliverList(
              delegate: SliverChildListDelegate(
                [
                  for (final section in sections) ...[
                    _sectionHeader(section.title),
                    const SizedBox(height: 12),
                    for (final draft in section.items) ...[
                      _announcementCard(
                        context,
                        ref,
                        draft: draft,
                      ),
                      const SizedBox(height: 12),
                    ],
                  ],
                ],
              ),
            ),
          ),
      ],
    );
  }

  // ヘッダー部分のウィジェット
  Widget _buildHeader(BuildContext context, bool isDark) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '投稿予定一覧',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.2,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            'ローカル保存のスケジュール',
            style: TextStyle(
              fontSize: 12,
              color: subduedText,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  // フィルターチップのウィジェット
  Widget _buildFilterChips(WidgetRef ref, DraftFilter active, bool isDark) {
    return SizedBox(
      height: 52,
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(20, 4, 20, 8),
        scrollDirection: Axis.horizontal,
        itemCount: DraftFilter.values.length,
        separatorBuilder: (_, __) => const SizedBox(width: 10),
        itemBuilder: (context, index) {
          final filter = DraftFilter.values[index];
          final selected = filter == active;
          final chipColor = selected ? primary : const Color(0xFF111620);
          final borderColor = selected ? Colors.transparent : chipBorder;
          final textColor = selected ? Colors.black : mutedText;

          return AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            curve: Curves.easeOut,
            decoration: BoxDecoration(
              color: chipColor,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: borderColor),
              boxShadow: selected
                  ? [BoxShadow(color: primary.withOpacity(0.25), blurRadius: 18)]
                  : null,
            ),

            child: InkWell(
              borderRadius: BorderRadius.circular(12),

              // タップでフィルターを変更
              onTap: () => ref.read(draftFilterProvider.notifier).state = filter,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
                child: Center(
                  child: Text(
                    filter.label,
                    style: TextStyle(fontWeight: FontWeight.bold, color: textColor),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  // ライブ情報がない場合のウィジェット
  Widget _buildEmptyState(BuildContext context, bool isDark) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Text(
          'まだ告知がありません。新規作成から追加しましょう。',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: mutedText,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }

  // ヘッダーセクションのウィジェット
  Widget _sectionHeader(String text) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.bold,
        color: subduedText,
      ),
    );
  }

 // 告知カードのウィジェット
  Widget _announcementCard(
    BuildContext context,
    WidgetRef ref, {
    required Draft draft,
  }) {
    final status = draft.status;
    final isFailed = status == 'failed';
    final isDraft = status == 'draft';
    final isScheduled = status == 'scheduled';
    final isPosted = status == 'posted';
    final title = _titleFromDraft(draft);
    final subtitle = _subtitleFromDraft(draft);
    final timeLabel = _formatDateLabel(draft.publishAt);
    final shortDateLabel = _formatShortDateLabel(draft.publishAt);
    final imageUrl = _imageUrlForDraft(draft);
    final platforms = _platformsForDraft(draft);

    final borderColor = isFailed
        ? const Color(0xFF7D2B2B)
        : chipBorder;

    // タップで編集画面を開く
    return InkWell(
      onTap: () => _openDetail(context, ref, draft.id),
      borderRadius: BorderRadius.circular(22),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: surfaceDark,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: borderColor),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.35),
              blurRadius: 20,
              offset: const Offset(0, 12),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(22),
          child: Stack(
            children: [
              if (!isFailed)
                Positioned(
                  right: -40,
                  top: -50,
                  child: Container(
                    width: 140,
                    height: 140,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: primary.withOpacity(0.08),
                    ),
                  ),
                ),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildThumbnail(
                    isFailed: isFailed,
                    imageUrl: imageUrl,
                    platforms: platforms,
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Text(
                                title,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                  height: 1.2,
                                ),
                              ),
                            ),
                            Icon(
                              Icons.more_horiz,
                              size: 20,
                              color: Colors.white54,
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(
                          subtitle,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 13,
                            color: isFailed ? Colors.red.shade300 : mutedText,
                          ),
                        ),
                        const SizedBox(height: 14),
                        if (isFailed)
                          Align(
                            alignment: Alignment.centerLeft,
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFFB02929),
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                              onPressed: () => ref.read(draftListProvider.notifier).markScheduled(draft),
                              child: const Text('再試行', style: TextStyle(color: Colors.white)),
                            ),
                          )
                        else
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              _buildStatusBadge(
                                isScheduled: isScheduled,
                                isDraft: isDraft,
                                isPosted: isPosted,
                                timeLabel: timeLabel,
                                shortDateLabel: shortDateLabel,
                              ),
                              if (!isDraft)
                                Row(
                                  children: [
                                    Icon(Icons.schedule, size: 14, color: subduedText),
                                    const SizedBox(width: 4),
                                    Text(
                                      timeLabel,
                                      style: const TextStyle(fontSize: 11, color: subduedText),
                                    ),
                                  ],
                                ),
                            ],
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // 告知タイトルの抽出
  Widget _buildStatusBadge({
    required bool isScheduled,
    required bool isDraft,
    required bool isPosted,
    required String timeLabel,
    required String shortDateLabel,
  }) {
    Color bg;
    Color fg;
    IconData icon;
    String text;

    if (isScheduled) {
      bg = const Color(0xFF0F3A35);
      fg = primary;
      icon = Icons.notifications_active;
      text = 'リマインド設定中';
    } else if (isDraft) {
      bg = const Color(0xFF202635);
      fg = mutedText;
      icon = Icons.edit_note;
      text = '下書き';
    } else if (isPosted) {
      bg = const Color(0xFF202635);
      fg = mutedText;
      icon = Icons.check_circle_outline;
      text = '投稿済み';
    } else {
      bg = const Color(0xFF202635);
      fg = mutedText;
      icon = Icons.info_outline;
      text = '未設定';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(10)),
      child: Row(
        children: [
          Icon(icon, size: 14, color: fg),
          const SizedBox(width: 4),
          Text(text, style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: fg)),
          if (isDraft) ...[
            const SizedBox(width: 6),
            Text('•', style: TextStyle(color: fg)),
            const SizedBox(width: 6),
            Text(shortDateLabel, style: TextStyle(fontSize: 11, color: fg)),
          ],
        ],
      ),
    );
  }

  // 告知サブタイトルの抽出
  Widget _buildThumbnail({
    required bool isFailed,
    required String imageUrl,
    required List<String> platforms,
  }) {
    final image = Image.network(
      imageUrl,
      width: 88,
      height: 88,
      fit: BoxFit.cover,
      errorBuilder: (_, __, ___) => Container(
        width: 88,
        height: 88,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          color: surfaceDarkElevated,
        ),
        child: Icon(Icons.image, color: mutedText),
      ),
    );

    final imageWidget = isFailed
        ? ColorFiltered(
            colorFilter: const ColorFilter.mode(Colors.grey, BlendMode.saturation),
            child: image,
          )
        : image;

    return SizedBox(
      width: 88,
      height: 88,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          ClipRRect(borderRadius: BorderRadius.circular(14), child: imageWidget),
          if (platforms.isNotEmpty)
            Positioned(
              bottom: -6,
              right: -6,
              child: Row(
                children: [
                  for (var i = 0; i < platforms.length; i++) ...[
                    _platformBadge(platforms[i]),
                    if (i != platforms.length - 1) const SizedBox(width: 4),
                  ],
                ],
              ),
            ),
          if (isFailed)
            Positioned(
              bottom: -6,
              left: -6,
              child: _errorBadge(),
            ),
        ],
      ),
    );
  }

  Widget _platformBadge(String text) {
    return Container(
      width: 24,
      height: 24,
      decoration: BoxDecoration(
        color: Colors.black,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white24),
      ),
      child: Center(
        child: Text(
          text,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 9,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Widget _errorBadge() {
    return Container(
      width: 24,
      height: 24,
      decoration: BoxDecoration(
        color: const Color(0xFF8F1D1D),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFB02929)),
      ),
      child: const Center(
        child: Icon(Icons.priority_high, size: 14, color: Colors.white),
      ),
    );
  }

  Widget _buildFab(BuildContext context, WidgetRef ref) {
    return FloatingActionButton.extended(
      backgroundColor: primary,
      elevation: 10,
      highlightElevation: 12,
      onPressed: () => _openEditor(context, ref),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      extendedPadding: const EdgeInsets.symmetric(horizontal: 18),
      label: Row(
        children: const [
          Text('新規作成', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
          SizedBox(width: 10),
          Icon(Icons.add, color: Colors.black),
        ],
      ),
    );
  }

  Future<void> _openEditor(BuildContext context, WidgetRef ref, {String? initialRaw}) async {
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => CreateAnnouncementScreen(initialRaw: initialRaw)),
    );
    await ref.read(draftListProvider.notifier).refresh();
  }

  Future<void> _openDetail(BuildContext context, WidgetRef ref, String draftId) async {
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => PostPreparerationScreen(draftId: draftId)),
    );
    await ref.read(draftListProvider.notifier).refresh();
  }

  String _titleFromDraft(Draft draft) {
    if (draft.title.trim().isNotEmpty) return draft.title.trim();
    final raw = draft.rawText.trim();
    if (raw.isEmpty) return '無題の告知';
    final firstLine = raw.split(RegExp(r'\r?\n')).first.trim();
    return firstLine.isEmpty ? '無題の告知' : firstLine;
  }

  String _subtitleFromDraft(Draft draft) {
    final base = draft.generated.trim().isNotEmpty ? draft.generated : draft.rawText;
    final normalized = base.replaceAll(RegExp(r'\s+'), ' ').trim();
    return normalized.isEmpty ? '内容が未入力です。' : normalized;
  }

  String _formatDateLabel(int millis) {
    final date = DateTime.fromMillisecondsSinceEpoch(millis);
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');
    final hour = date.hour.toString().padLeft(2, '0');
    final minute = date.minute.toString().padLeft(2, '0');
    return '$month/$day $hour:$minute';
  }

  String _formatShortDateLabel(int millis) {
    final date = DateTime.fromMillisecondsSinceEpoch(millis);
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');
    return '$month/$day';
  }

  List<_Section> _buildSections(List<Draft> drafts) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final cutoff = today.add(const Duration(days: 7));
    final week = <Draft>[];
    final future = <Draft>[];

    for (final draft in drafts) {
      final date = DateTime.fromMillisecondsSinceEpoch(draft.publishAt);
      if (date.isBefore(cutoff)) {
        week.add(draft);
      } else {
        future.add(draft);
      }
    }

    return [
      if (week.isNotEmpty) _Section('今週の予定', week),
      if (future.isNotEmpty) _Section('今後の予定', future),
    ];
  }

  String _imageUrlForDraft(Draft draft) {
    if (draft.imageUrls.isNotEmpty) {
      return draft.imageUrls.first;
    }
    final index = draft.id.hashCode.abs() % previewImages.length;
    return previewImages[index];
  }

  List<String> _platformsForDraft(Draft draft) {
    if (draft.targets.isNotEmpty) {
      return draft.targets.map((target) {
        if (target.toLowerCase() == 'instagram') return 'Ig';
        return 'X';
      }).toList();
    }
    final index = draft.id.hashCode.abs() % 3;
    if (index == 0) return ['X'];
    if (index == 1) return ['Ig'];
    return ['X', 'Ig'];
  }
}

class _Section {
  const _Section(this.title, this.items);

  final String title;
  final List<Draft> items;
}
