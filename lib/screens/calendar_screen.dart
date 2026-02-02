import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/draft_providers.dart';
import '../services/draft_store.dart';
import '../widgets/announcement_card.dart';

class CalendarScreen extends ConsumerStatefulWidget {
  const CalendarScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends ConsumerState<CalendarScreen> {
  static const Color primary = Color(0xFF00FFCC);
  static const Color backgroundDark = Color(0xFF0E121A);
  static const Color surfaceDarkElevated = Color(0xFF1B2230);
  static const Color mutedText = Color(0xFF9AA3B2);
  static const Color subduedText = Color(0xFF7C8595);

  late DateTime _focusedMonth;
  late DateTime _selectedDate;
  double _horizontalDragDistance = 0;
  int _monthChangeDirection = 1;

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
        centerTitle: true,
        foregroundColor: Colors.white,
        systemOverlayStyle: SystemUiOverlayStyle.light,
        title: const Text(
          'カレンダー',
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
    final currentKey = ValueKey<int>(_focusedMonth.year * 100 + _focusedMonth.month);
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onHorizontalDragStart: (_) => _horizontalDragDistance = 0,
      onHorizontalDragUpdate: (details) => _horizontalDragDistance += details.delta.dx,
      onHorizontalDragEnd: _handleHorizontalDragEnd,
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 260),
        switchInCurve: Curves.easeOutCubic,
        switchOutCurve: Curves.easeInCubic,
        transitionBuilder: (child, animation) {
          final incoming = child.key == currentKey;
          final direction = _monthChangeDirection == 0 ? 1 : _monthChangeDirection;
          final offset = incoming
              ? Offset(direction.toDouble(), 0)
              : Offset(-direction.toDouble(), 0);
          final position = Tween<Offset>(begin: offset, end: Offset.zero).animate(animation);

          return ClipRect(
            child: SlideTransition(
              position: position,
              child: FadeTransition(opacity: animation, child: child),
            ),
          );
        },
        child: GridView.builder(
          key: currentKey,
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
        ),
      ),
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
        return AnnouncementCard(draft: drafts[index]);
      },
    );
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
      _monthChangeDirection = delta.sign == 0 ? 1 : delta.sign;
      _focusedMonth = DateTime(_focusedMonth.year, _focusedMonth.month + delta, 1);
      _selectedDate = DateTime(_focusedMonth.year, _focusedMonth.month, 1);
    });
  }

  void _handleHorizontalDragEnd(DragEndDetails details) {
    const minDistance = 40.0;
    const minVelocity = 200.0;
    final velocity = details.primaryVelocity ?? 0.0;

    if (_horizontalDragDistance > minDistance || velocity > minVelocity) {
      _changeMonth(-1);
    } else if (_horizontalDragDistance < -minDistance || velocity < -minVelocity) {
      _changeMonth(1);
    }

    _horizontalDragDistance = 0;
  }

  String _formatDateLabel(DateTime date) {
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');
    return '$month/$day';
  }

}
