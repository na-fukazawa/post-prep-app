import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/draft_providers.dart';
import '../services/draft_store.dart';
import 'post_prep_screen.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({Key? key}) : super(key: key);

  static const Color primary = Color(0xFF00FFCC);
  static const Color backgroundLight = Color(0xFFF0F2F4);
  static const Color backgroundDark = Color(0xFF0E121A);
  static const Color surfaceDark = Color(0xFF161B26);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final filter = ref.watch(draftFilterProvider);
    final draftsAsync = ref.watch(draftListProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? backgroundDark : backgroundLight,
      body: SafeArea(
        child: draftsAsync.when(
          data: (drafts) {
            final filtered = _applyFilter(drafts, filter);
            return RefreshIndicator(
              onRefresh: () => ref.read(draftListProvider.notifier).refresh(),
              child: _buildBody(context, ref, filtered, filter, isDark),
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (_, __) => _buildErrorState(context, ref),
        ),
      ),
      floatingActionButton: _buildFab(context, ref),
      bottomNavigationBar: _buildBottomNav(context, isDark),
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
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 140),
            sliver: SliverList(
              delegate: SliverChildListDelegate(
                [
                  for (final section in sections) ...[
                    _sectionHeader(section.title),
                    const SizedBox(height: 8),
                    for (final draft in section.items) ...[
                      _announcementCard(
                        context,
                        ref,
                        draft: draft,
                        isDark: isDark,
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

  Widget _buildHeader(BuildContext context, bool isDark) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '投稿予定一覧',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : Colors.black,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            'ローカル保存のスケジュール',
            style: TextStyle(
              fontSize: 12,
              color: isDark ? Colors.white54 : Colors.black54,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChips(WidgetRef ref, DraftFilter active, bool isDark) {
    return SizedBox(
      height: 56,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
        scrollDirection: Axis.horizontal,
        itemCount: DraftFilter.values.length,
        separatorBuilder: (_, __) => const SizedBox(width: 10),
        itemBuilder: (context, index) {
          final filter = DraftFilter.values[index];
          final selected = filter == active;
          final chipColor = selected ? primary : Colors.transparent;
          final borderColor = isDark ? Colors.white12 : Colors.grey.shade300;
          final textColor = selected
              ? Colors.black
              : (isDark ? Colors.white70 : Colors.grey.shade700);

          return GestureDetector(
            onTap: () => ref.read(draftFilterProvider.notifier).state = filter,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 9),
              decoration: BoxDecoration(
                color: chipColor,
                borderRadius: BorderRadius.circular(12),
                border: selected ? null : Border.all(color: borderColor),
                boxShadow: selected
                    ? [BoxShadow(color: primary.withOpacity(0.2), blurRadius: 16)]
                    : null,
              ),
              child: Center(
                child: Text(
                  filter.label,
                  style: TextStyle(fontWeight: FontWeight.bold, color: textColor),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context, bool isDark) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Text(
          'まだ告知がありません。新規作成から追加しましょう。',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: isDark ? Colors.white70 : Colors.black54,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }

  Widget _sectionHeader(String text) {
    return Text(
      text.toUpperCase(),
      style: const TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.bold,
        color: Colors.grey,
        letterSpacing: 2,
      ),
    );
  }

  Widget _announcementCard(
    BuildContext context,
    WidgetRef ref, {
    required Draft draft,
    required bool isDark,
  }) {
    final status = draft.status;
    final isFailed = status == 'failed';
    final isDraft = status == 'draft';
    final isScheduled = status == 'scheduled';
    final isPosted = status == 'posted';
    final title = _titleFromDraft(draft);
    final subtitle = _subtitleFromDraft(draft);
    final timeLabel = _formatDateLabel(draft.createdAt);

    final borderColor = isFailed
        ? Colors.red.withOpacity(0.3)
        : (isDark ? Colors.white10 : Colors.grey.shade200);

    return InkWell(
      onTap: () => _openEditor(context, ref, initialRaw: draft.rawText),
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isDark ? surfaceDark : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: borderColor),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 12,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildThumbnail(isFailed: isFailed),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: isDark ? Colors.white : Colors.black,
                          ),
                        ),
                      ),
                      Icon(
                        Icons.more_horiz,
                        color: isDark ? Colors.white54 : Colors.grey.shade500,
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
                      color: isFailed
                          ? Colors.red.shade300
                          : (isDark ? Colors.white54 : Colors.grey.shade600),
                    ),
                  ),
                  const SizedBox(height: 12),
                  if (isFailed)
                    Align(
                      alignment: Alignment.centerRight,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red.shade600,
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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
                          isDark: isDark,
                          isScheduled: isScheduled,
                          isDraft: isDraft,
                          isPosted: isPosted,
                          timeLabel: timeLabel,
                        ),
                        if (!isDraft)
                          Row(
                            children: [
                              Icon(Icons.schedule, size: 14, color: Colors.grey.shade400),
                              const SizedBox(width: 4),
                              Text(
                                timeLabel,
                                style: TextStyle(fontSize: 11, color: Colors.grey.shade400),
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
      ),
    );
  }

  Widget _buildStatusBadge({
    required bool isDark,
    required bool isScheduled,
    required bool isDraft,
    required bool isPosted,
    required String timeLabel,
  }) {
    Color bg;
    Color fg;
    IconData icon;
    String text;

    if (isScheduled) {
      bg = primary.withOpacity(0.12);
      fg = primary;
      icon = Icons.notifications_active;
      text = 'リマインド設定中';
    } else if (isDraft) {
      bg = isDark ? Colors.white10 : Colors.grey.shade200;
      fg = isDark ? Colors.white60 : Colors.grey.shade600;
      icon = Icons.edit_note;
      text = '下書き';
    } else if (isPosted) {
      bg = isDark ? Colors.white10 : Colors.grey.shade200;
      fg = isDark ? Colors.white60 : Colors.grey.shade600;
      icon = Icons.check_circle_outline;
      text = '投稿済み';
    } else {
      bg = isDark ? Colors.white10 : Colors.grey.shade200;
      fg = isDark ? Colors.white60 : Colors.grey.shade600;
      icon = Icons.info_outline;
      text = '未設定';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(8)),
      child: Row(
        children: [
          Icon(icon, size: 14, color: fg),
          const SizedBox(width: 4),
          Text(text, style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: fg)),
          if (isDraft) ...[
            const SizedBox(width: 6),
            Text('•', style: TextStyle(color: fg)),
            const SizedBox(width: 6),
            Text(timeLabel, style: TextStyle(fontSize: 11, color: fg)),
          ],
        ],
      ),
    );
  }

  Widget _buildThumbnail({required bool isFailed}) {
    return Container(
      width: 88,
      height: 88,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        gradient: LinearGradient(
          colors: isFailed
              ? [Colors.grey.shade700, Colors.grey.shade500]
              : [const Color(0xFF222937), const Color(0xFF3E4A63)],
        ),
      ),
      child: Stack(
        children: [
          Center(
            child: Icon(
              Icons.image,
              color: Colors.white.withOpacity(0.6),
              size: 32,
            ),
          ),
          Positioned(
            bottom: -4,
            right: -4,
            child: Row(
              children: [
                _platformBadge('X', dark: true),
                const SizedBox(width: 4),
                _platformBadge('Ig', dark: true),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _platformBadge(String text, {required bool dark}) {
    return Container(
      width: 24,
      height: 24,
      decoration: BoxDecoration(
        color: dark ? Colors.black : Colors.white,
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

  Widget _buildFab(BuildContext context, WidgetRef ref) {
    return FloatingActionButton.extended(
      backgroundColor: primary,
      onPressed: () => _openEditor(context, ref),
      label: Row(
        children: const [
          Text('新規作成', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
          SizedBox(width: 8),
          Icon(Icons.add, color: Colors.black),
        ],
      ),
    );
  }

  Widget _buildBottomNav(BuildContext context, bool isDark) {
    return Container(
      padding: const EdgeInsets.only(bottom: 18, top: 8),
      decoration: BoxDecoration(
        color: (isDark ? surfaceDark : Colors.white).withOpacity(0.95),
        border: Border(top: BorderSide(color: isDark ? Colors.white10 : Colors.grey.shade200)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _navItem(icon: Icons.home, label: 'ホーム', active: true),
          _navItem(icon: Icons.calendar_month, label: 'カレンダー'),
          _navItem(icon: Icons.settings, label: '設定'),
        ],
      ),
    );
  }

  Widget _navItem({required IconData icon, required String label, bool active = false}) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: active ? primary : Colors.grey.shade500),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 10,
            color: active ? primary : Colors.grey.shade500,
            fontWeight: active ? FontWeight.bold : FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Future<void> _openEditor(BuildContext context, WidgetRef ref, {String? initialRaw}) async {
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => PostPrepScreen(initialRaw: initialRaw)),
    );
    await ref.read(draftListProvider.notifier).refresh();
  }

  String _titleFromDraft(Draft draft) {
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

  List<_Section> _buildSections(List<Draft> drafts) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final cutoff = today.add(const Duration(days: 7));
    final week = <Draft>[];
    final future = <Draft>[];

    for (final draft in drafts) {
      final date = DateTime.fromMillisecondsSinceEpoch(draft.createdAt);
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
}

class _Section {
  const _Section(this.title, this.items);

  final String title;
  final List<Draft> items;
}
