// Home screen UI for the Post Prep app.
//
// このファイルはアプリのメイン画面 (ホーム) を定義します。
// - ヘッダー (ユーザー情報)
// - フィルターチップ (All / Scheduled / Drafts / Posted)
// - 投稿のカードリスト (サンプルデータを使用)
// - 下部ナビゲーションと FAB
//
// 各プライベートメソッドはウィジェットの一部を組み立てる責務を持ち、
// UIの再利用性が高くなるように分割されています。
import 'package:flutter/material.dart';
import '../services/draft_store.dart';
import 'post_prep_screen.dart';

// A Home screen visually inspired by the provided Tailwind HTML.
class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<Draft> _drafts = [];
  bool _loading = true;
  String _activeFilter = 'すべて';

  static const Color primary = Color(0xFF00FFCC);

  // _drafts: 保存された下書きのリスト（DraftStore から読み込み）
  // _loading: データ読み込み中にインジケータを表示するためのフラグ
  // _activeFilter: チップで選択されているフィルタ名

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    // DraftStore から下書きを読み込む。読み込み中は _loading を true にして
    // プログレスインジケータを表示する。
    setState(() => _loading = true);
    final drafts = await DraftStore().loadDrafts();
    setState(() {
      _drafts = drafts;
      _loading = false;
    });
  }

  Future<void> _delete(String id) async {
    // 指定した id の下書きを削除し、リストを再読み込みする。
    await DraftStore().deleteDraft(id);
    await _load();
  }

  void _openEditor({String? initialRaw}) async {
    // PostPrepScreen を開き、戻ってきたら下書きリストを再読み込みする。
    await Navigator.of(context).push(MaterialPageRoute(builder: (_) => PostPrepScreen(initialRaw: initialRaw)));
    await _load();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).brightness == Brightness.dark
          ? const Color(0xFF0E121A)
          : const Color(0xFFF0F2F4),
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            _buildFilterChips(),
            Expanded(child: _buildMainList()),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: primary,
        label: const Icon(Icons.add, color: Colors.black),
        onPressed: () => _openEditor(),
      ),
      bottomNavigationBar: _buildBottomNav(),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Stack(
                children: [
                  CircleAvatar(
                    radius: 22,
                    backgroundImage: NetworkImage(
                        'https://lh3.googleusercontent.com/aida-public/AB6AXuDkZnpuu37MCrLMtuR5Sq1ISnQ-gFH3geF6WA4yaFSxqdU6rnU6knowKw7Xc3g19RkxnHnFILbUQVPNDafWzYhE8iB1NhGsxAf04KDtzc136ABWbLf4dhut50PyY_BdaGBO5fpFsvj60IsQnDblbGeEdx5Y4uLmBiLbzVez1GHPfeeJi6Uoh_Iby2sqKaDGkoru751see4zeAa--lQSP8VIrhZUkd71V1K0jyB1y1Iv7EDOu8wpi4JJbnXrVTle3tr24nai66JijSdm'),
                  ),
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(color: primary, shape: BoxShape.circle, border: Border.all(color: Theme.of(context).scaffoldBackgroundColor, width: 2)),
                    ),
                  )
                ],
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Text('こんにちは、サラ', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  SizedBox(height: 2),
                  Text('告知の準備はできましたか？', style: TextStyle(fontSize: 12, color: Colors.grey)),
                ],
              )
            ],
          ),
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            onPressed: () {},
          )
        ],
      ),
    );
  }

  Widget _buildFilterChips() {
    final chips = ['すべて', '予約', '下書き', '投稿済み'];
    return SizedBox(
      height: 56,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        scrollDirection: Axis.horizontal,
        itemCount: chips.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, i) {
          final label = chips[i];
          final active = label == _activeFilter;
          return GestureDetector(
            onTap: () => setState(() => _activeFilter = label),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
              decoration: BoxDecoration(
                color: active ? primary : Colors.transparent,
                borderRadius: BorderRadius.circular(12),
                border: active ? null : Border.all(color: Colors.grey.shade300),
                boxShadow: active ? [BoxShadow(color: primary.withOpacity(0.15), blurRadius: 12)] : null,
              ),
              child: Center(
                child: Text(label, style: TextStyle(color: active ? Colors.black : Colors.grey.shade700, fontWeight: active ? FontWeight.bold : FontWeight.w500)),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildMainList() {
    // Build a scrollable view with sections and a few example cards.
    return _loading
        ? const Center(child: CircularProgressIndicator())
        : CustomScrollView(
            slivers: [
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                sliver: SliverList(
                  delegate: SliverChildListDelegate(
                    [
                      _sectionHeader('今週'),
                      const SizedBox(height: 8),
                      _postCard(
                        title: 'The Velvet Loungeでライブ',
                        subtitle: 'ジャズナイト特別出演。',
                        dateLabel: '明日 20:00',
                        imageUrl: 'https://lh3.googleusercontent.com/aida-public/AB6AXuA1-L2pzadFAl73MEesP1ktDxNsaeVSg79ZDB82JN8bKuxQsRPBH_pdpZrmblPii1CQcIUs131V4-qCVCVQOrYm1QKqGlKdfBdRjjMC1cfbeQp41--t0ygT2XzVTS8mMXb7iF721S1JVtD_nylEF1B6OZkfcXUdaCZ1lWhW5cOLBlcrtYe4b4aGXhjnXNLG6TRDYCajAnkts7zN05rGF55hEuISADKRZVHwckKF4H2Uldwl2TeCXz7dNL95heNoq0dmFYPFZwXSuFPc',
                        primary: primary,
                        onTap: () {},
                      ),
                      const SizedBox(height: 12),
                      _postCard(
                        title: 'ネオン・ナイツ・フェス',
                        subtitle: '早割チケットの告知。',
                        dateLabel: '下書き • 11月2日',
                        imageUrl: 'https://lh3.googleusercontent.com/aida-public/AB6AXuDzh9YKMlrsA0RKU6EFe4jj-sxLQCOvnV-vq5sjpbP5XK1NEzvb8gPYs1OsEvvmmFGQY68DWUPKDHXF8mPsatSiLkUrRy1jRmdMoN2gElPUg2dSNP4MMlemea4AjBSj9lHX1nCqsbTIPLBHqth7QUsTsxOOo2HOYJeEF1uiRfEApqh3_Nz8GShw1O75AiW6lniMJZQhz6nsfjYPmk78WdoCohFFYoHAufZIFepp71eSQsFEU-mwXmsYbqcnWa1nhc4PlVP_rgQ2cGCX',
                        primary: Colors.grey,
                        onTap: () {},
                      ),
                      const SizedBox(height: 20),
                      _sectionHeader('今後の予定'),
                      const SizedBox(height: 8),
                      _postCard(
                        title: 'アコースティック・セッション告知',
                        subtitle: 'ティーザー動画を投稿。',
                        dateLabel: '11月15日 17:00',
                        imageUrl: 'https://lh3.googleusercontent.com/aida-public/AB6AXuBxXiBK-BrGdvUoD_GZrj8MYhOyN0AtHW4UXWpbWvMLv0mowtXUN4iUCo9y8pQQC-zWPoHBPgTVt-gAUk2RdP8mkx423v9cSRvGrl8XR85OE8ofV5XBCcuSmxcjlFiyu4ewbMs-EZ11COSAGnNIq0QCB__t7nz__9l9kdnmmdrnfdUs-96s5S_3AHQ5XWV6YWZIEcWNgMKO2l36Dh5G-q8nEkQhhSrvxYxZWWQnbaVwyOdJ4LhkyljjoTENIczndPcnYiZ0TeOnVpn4',
                        primary: primary,
                        onTap: () {},
                      ),
                      const SizedBox(height: 12),
                      _postCard(
                        title: 'グッズ第2弾',
                        subtitle: '投稿に失敗しました。接続を確認してください。',
                        dateLabel: null,
                        imageUrl: 'https://lh3.googleusercontent.com/aida-public/AB6AXuA5eIpaRB6EVvGKbIgEEYMseCzGHUYtQ6FHbyxwXag82A8wwj54JaeFYaM3xTrtliWkp2lpty6TFIvFzzeS-LI6vJYDUggJCQnyxqPEFdOb-KhuS751adRnkl9PRnJiMqaXMwDeYSU1t2W4ixUpMudDOQ8d82udY_SW7uEObRtpGQnnMINOb0b68p-Fzq1oBQ0Yufg8UzjZcm7vC9bwhy6fIMvD-fddWAwt0oRddq6H977OxubNZZ9KVYEeyNMm2xkaxRaSD60Uj_Q4',
                        primary: Colors.red,
                        error: true,
                        onTap: () {},
                      ),
                      const SizedBox(height: 120),
                    ],
                  ),
                ),
              )
            ],
          );
  }

  Widget _sectionHeader(String text) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(text.toUpperCase(), style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey)),
      ],
    );
  }

  Widget _postCard({required String title, required String subtitle, String? dateLabel, required String imageUrl, required Color primary, bool error = false, VoidCallback? onTap}) {
    return InkWell(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).brightness == Brightness.dark ? const Color(0xFF161B26) : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: error ? Colors.red.withOpacity(0.3) : Colors.grey.shade200),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 8, offset: const Offset(0, 2))],
        ),
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Stack(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.network(imageUrl, width: 88, height: 88, fit: BoxFit.cover),
                ),
                Positioned(
                  bottom: -6,
                  right: -6,
                  child: Row(
                    children: [
                      _platformBadge('X'),
                      const SizedBox(width: 4),
                      _platformBadge('Ig'),
                    ],
                  ),
                )
              ],
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(child: Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold), maxLines: 1, overflow: TextOverflow.ellipsis)),
                      IconButton(icon: const Icon(Icons.more_horiz), onPressed: () {})
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(subtitle, style: TextStyle(fontSize: 13, color: error ? Colors.red.shade300 : Colors.grey.shade600), maxLines: 1, overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      if (dateLabel != null)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(color: primary.withOpacity(0.12), borderRadius: BorderRadius.circular(8)),
                          child: Row(
                            children: [
                              Icon(error ? Icons.priority_high : Icons.calendar_today, size: 14, color: primary),
                              const SizedBox(width: 6),
                              Text(dateLabel, style: TextStyle(fontSize: 12, color: primary)),
                            ],
                          ),
                        ),
                      if (error)
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(backgroundColor: Colors.red.shade700),
                          onPressed: () {},
                          child: const Text('再試行'),
                        ),
                      if (!error) const SizedBox.shrink(),
                    ],
                  )
                ],
              ),
            )
          ],
        ),
      ),
    );
  }

  Widget _platformBadge(String text) {
    return Container(
      width: 28,
      height: 28,
      decoration: BoxDecoration(color: Colors.black, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.white24)),
      child: Center(child: Text(text, style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold))),
    );
  }

  Widget _buildBottomNav() {
    return Container(
      decoration: BoxDecoration(color: Theme.of(context).brightness == Brightness.dark ? const Color(0xFF101217).withOpacity(0.6) : Colors.white.withOpacity(0.9), border: Border(top: BorderSide(color: Colors.white.withOpacity(0.06)))),
      padding: const EdgeInsets.only(bottom: 10, top: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _navItem(Icons.home, 'ホーム', active: true),
          _navItem(Icons.calendar_month, 'カレンダー'),
          _navItem(Icons.bar_chart, '分析'),
          _navItem(Icons.person, 'プロフィール'),
        ],
      ),
    );
  }

  Widget _navItem(IconData icon, String label, {bool active = false}) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: active ? primary : Colors.grey.shade500),
        const SizedBox(height: 4),
        Text(label, style: TextStyle(fontSize: 10, color: active ? primary : Colors.grey.shade500, fontWeight: active ? FontWeight.bold : FontWeight.w500)),
      ],
    );
  }
}
