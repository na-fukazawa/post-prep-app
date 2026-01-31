import 'package:flutter/material.dart';
import 'app_setting.dart';
import 'calendar_screen.dart';
import 'schduleed_annoucements.dart';

class AppShell extends StatefulWidget {
  const AppShell({Key? key}) : super(key: key);

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  static const Color primary = Color(0xFF00FFCC);

  int _index = 0;

  final List<Widget> _screens = const [
    SchduleedAnnoucementsScreen(),
    CalendarScreen(),
    AppSettingScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _index,
        children: _screens,
      ),
      bottomNavigationBar: _buildBottomNav(),
    );
  }

  Widget _buildBottomNav() {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 18),
      decoration: BoxDecoration(
        color: const Color(0xFF111620).withOpacity(0.95),
        border: const Border(top: BorderSide(color: Colors.white10)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.4),
            blurRadius: 24,
            offset: const Offset(0, -8),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _navItem(
            icon: Icons.home,
            label: 'ホーム',
            active: _index == 0,
            onTap: () => _select(0),
          ),
          _navItem(
            icon: Icons.calendar_month,
            label: 'カレンダー',
            active: _index == 1,
            onTap: () => _select(1),
          ),
          _navItem(
            icon: Icons.settings,
            label: '設定',
            active: _index == 2,
            onTap: () => _select(2),
          ),
        ],
      ),
    );
  }

  Widget _navItem({
    required IconData icon,
    required String label,
    required bool active,
    required VoidCallback onTap,
  }) {
    final color = active ? primary : Colors.grey.shade500;
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        width: 72,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                color: color,
                fontWeight: active ? FontWeight.bold : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _select(int index) {
    if (index == _index) return;
    setState(() => _index = index);
  }
}
