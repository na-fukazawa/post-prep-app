import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/draft_providers.dart';
import '../services/draft_store.dart';
import 'create_announcement.dart';
import '../widgets/announcement_card.dart';

class SchduleedAnnoucementsScreen extends ConsumerWidget {
  const SchduleedAnnoucementsScreen({Key? key}) : super(key: key);

  static const Color primary = Color(0xFF00FFCC);
  static const Color backgroundDark = Color(0xFF0E121A);
  static const Color surfaceDark = Color(0xFF161B26);
  static const Color chipBorder = Color(0xFF2A3240);
  static const Color mutedText = Color(0xFF9AA3B2);
  static const Color subduedText = Color(0xFF7C8595);

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
            return _buildBody(context, ref, filtered, filter, isDark);
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

    return Column(
      children: [
        _buildHeader(context, isDark),
        _buildFilterChips(ref, filter, isDark),
        Expanded(
          child: RefreshIndicator(
            color: primary,
            backgroundColor: surfaceDark,
            displacement: 32,
            onRefresh: () => ref.read(draftListProvider.notifier).refresh(),
            child: CustomScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              slivers: [
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
                              AnnouncementCard(draft: draft),
                              const SizedBox(height: 12),
                            ],
                          ],
                        ],
                      ),
                    ),
                  ),
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
              fontSize: 18,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.1,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 2),
          const SizedBox(height: 0),
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

  List<_Section> _buildSections(List<Draft> drafts) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final cutoff = today.add(const Duration(days: 7));
    final week = <Draft>[];
    final future = <Draft>[];

    for (final draft in drafts) {
      final date = DateTime.fromMillisecondsSinceEpoch(draft.publishAt);
      final dateOnly = DateTime(date.year, date.month, date.day);
      if (!dateOnly.isBefore(today) && !dateOnly.isAfter(cutoff)) {
        week.add(draft);
      } else if (dateOnly.isAfter(cutoff)) {
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
