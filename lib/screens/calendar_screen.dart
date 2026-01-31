import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/draft_providers.dart';
import '../services/draft_store.dart';
import 'post_prepareration.dart';

class CalendarScreen extends ConsumerStatefulWidget {
  const CalendarScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends ConsumerState<CalendarScreen> {
  static const Color primary = Color(0xFF00FFCC);
  static const Color backgroundDark = Color(0xFF0E121A);
  static const Color surfaceDark = Color(0xFF161B26);
  static const Color surfaceDarkElevated = Color(0xFF1B2230);
  static const Color mutedText = Color(0xFF9AA3B2);
  static const Color subduedText = Color(0xFF7C8595);

  late DateTime _focusedMonth;
  late DateTime _selectedDate;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _focusedMonth = DateTime(now.year, now.month, 1);
    _selectedDate = DateTime(now.year, now.month, now.day);
  }

  @override
  Widget build(BuildContext context) {
    final draftsAsync = ref.watch(draftListProvider);

    return Scaffold(
      backgroundColor: backgroundDark,
      appBar: AppBar(
        backgroundColor: backgroundDark,
        elevation: 0,
        title: const Text('カレンダー'),
      ),
      body: SafeArea(
        child: draftsAsync.when(
          data: (drafts) => _buildContent(drafts),
          loading: () => const Center(child: CircularProgressIndicator(color: primary)),
          error: (_, __) => _buildErrorState(),
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
            onPressed: () => ref.read(draftListProvider.notifier).refresh(),
            child: const Text('再読み込み'),
          ),
        ],
      ),
    );
  }

  Widget _buildContent(List<Draft> drafts) {
    final byDate = _groupByDate(drafts);
    final selectedDrafts = byDate[_dateKey(_selectedDate)] ?? <Draft>[];

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildMonthHeader(),
          const SizedBox(height: 8),
          _buildWeekdayRow(),
          const SizedBox(height: 6),
          _buildMonthGrid(byDate),
          const SizedBox(height: 12),
          Text(
            _formatDateLabel(_selectedDate),
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: subduedText),
          ),
          const SizedBox(height: 8),
          Expanded(child: _buildDraftList(selectedDrafts)),
        ],
      ),
    );
  }

  Widget _buildMonthHeader() {
    final label = '${_focusedMonth.year}年${_focusedMonth.month}月';
    return Row(
      children: [
        IconButton(
          onPressed: () => _changeMonth(-1),
          icon: const Icon(Icons.chevron_left, color: Colors.white70),
        ),
        Expanded(
          child: Center(
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
        ),
        IconButton(
          onPressed: () => _changeMonth(1),
          icon: const Icon(Icons.chevron_right, color: Colors.white70),
        ),
      ],
    );
  }

  Widget _buildWeekdayRow() {
    const labels = ['日', '月', '火', '水', '木', '金', '土'];
    return Row(
      children: [
        for (final label in labels)
          Expanded(
            child: Center(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  color: label == '日' ? Colors.redAccent : mutedText,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildMonthGrid(Map<int, List<Draft>> byDate) {
    final cells = _buildMonthCells(_focusedMonth);
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 7,
        mainAxisSpacing: 6,
        crossAxisSpacing: 6,
        childAspectRatio: 1.1,
      ),
      itemCount: cells.length,
      itemBuilder: (context, index) {
        final date = cells[index];
        if (date == null) {
          return const SizedBox.shrink();
        }
        final key = _dateKey(date);
        final hasDrafts = (byDate[key] ?? []).isNotEmpty;
        final isSelected = _isSameDay(date, _selectedDate);
        final isToday = _isSameDay(date, DateTime.now());

        return GestureDetector(
          onTap: () => setState(() => _selectedDate = date),
          child: Container(
            decoration: BoxDecoration(
              color: isSelected ? primary : surfaceDarkElevated,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isSelected ? Colors.transparent : const Color(0xFF232C3B),
              ),
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                Text(
                  '${date.day}',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: isSelected
                        ? Colors.black
                        : isToday
                            ? primary
                            : Colors.white,
                  ),
                ),
                if (hasDrafts)
                  Positioned(
                    bottom: 6,
                    child: Container(
                      width: 6,
                      height: 6,
                      decoration: BoxDecoration(
                        color: isSelected ? Colors.black : primary,
                        shape: BoxShape.circle,
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

  Widget _buildDraftList(List<Draft> drafts) {
    if (drafts.isEmpty) {
      return Center(
        child: Text(
          'この日の告知はありません。',
          style: TextStyle(color: mutedText),
        ),
      );
    }

    return ListView.separated(
      itemCount: drafts.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final draft = drafts[index];
        final time = _formatTimeLabel(draft.publishAt);
        final statusLabel = _statusLabel(draft.status);
        final statusColor = _statusColor(draft.status);
        final subtitle = _subtitleFromDraft(draft);

        return InkWell(
          onTap: () => _openDetail(draft),
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: surfaceDark,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFF1F2735)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        _titleFromDraft(draft),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      time,
                      style: const TextStyle(fontSize: 11, color: subduedText),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  subtitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 12, color: mutedText),
                ),
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    statusLabel,
                    style: TextStyle(fontSize: 11, color: statusColor, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _openDetail(Draft draft) async {
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => PostPreparerationScreen(draftId: draft.id)),
    );
    if (!mounted) return;
    await ref.read(draftListProvider.notifier).refresh();
  }

  List<DateTime?> _buildMonthCells(DateTime month) {
    final firstDay = DateTime(month.year, month.month, 1);
    final daysInMonth = DateTime(month.year, month.month + 1, 0).day;
    final offset = firstDay.weekday % 7;
    final totalCells = ((offset + daysInMonth + 6) ~/ 7) * 7;
    final cells = <DateTime?>[];

    for (var i = 0; i < totalCells; i++) {
      final dayNumber = i - offset + 1;
      if (dayNumber < 1 || dayNumber > daysInMonth) {
        cells.add(null);
      } else {
        cells.add(DateTime(month.year, month.month, dayNumber));
      }
    }
    return cells;
  }

  Map<int, List<Draft>> _groupByDate(List<Draft> drafts) {
    final map = <int, List<Draft>>{};
    for (final draft in drafts) {
      final date = DateTime.fromMillisecondsSinceEpoch(draft.publishAt);
      final key = _dateKey(date);
      map.putIfAbsent(key, () => <Draft>[]).add(draft);
    }
    return map;
  }

  int _dateKey(DateTime date) {
    return date.year * 10000 + date.month * 100 + date.day;
  }

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  void _changeMonth(int delta) {
    setState(() {
      _focusedMonth = DateTime(_focusedMonth.year, _focusedMonth.month + delta, 1);
      _selectedDate = DateTime(_focusedMonth.year, _focusedMonth.month, 1);
    });
  }

  String _formatDateLabel(DateTime date) {
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');
    return '$month/$day';
  }

  String _formatTimeLabel(int millis) {
    final date = DateTime.fromMillisecondsSinceEpoch(millis);
    final hour = date.hour.toString().padLeft(2, '0');
    final minute = date.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
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

  String _statusLabel(String status) {
    switch (status) {
      case 'scheduled':
        return '予約済み';
      case 'draft':
        return '下書き';
      case 'posted':
        return '投稿済み';
      case 'failed':
        return '投稿失敗';
      default:
        return '未設定';
    }
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'scheduled':
        return primary;
      case 'draft':
        return mutedText;
      case 'posted':
        return const Color(0xFF6F7A8D);
      case 'failed':
        return Colors.redAccent;
      default:
        return mutedText;
    }
  }
}
