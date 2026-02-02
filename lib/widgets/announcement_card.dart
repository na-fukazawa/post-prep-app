import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/draft_providers.dart';
import '../services/draft_store.dart';
import '../screens/post_prepareration.dart';

class AnnouncementCard extends ConsumerWidget {
  const AnnouncementCard({
    super.key,
    required this.draft,
  });

  final Draft draft;

  static const Color primary = Color(0xFF00FFCC);
  static const Color surfaceDark = Color(0xFF161B26);
  static const Color surfaceDarkElevated = Color(0xFF1B2230);
  static const Color chipBorder = Color(0xFF2A3240);
  static const Color mutedText = Color(0xFF9AA3B2);
  static const Color subduedText = Color(0xFF7C8595);
  static const double deleteActionWidth = 92;
  static const String instagramIconAsset = 'assets/icons/instagram.jpg';
  static const String xIconAsset = 'assets/icons/x.jpg';

  static const List<String> previewImages = [
    'https://lh3.googleusercontent.com/aida-public/AB6AXuA1-L2pzadFAl73MEesP1ktDxNsaeVSg79ZDB82JN8bKuxQsRPBH_pdpZrmblPii1CQcIUs131V4-qCVCVQOrYm1QKqGlKdfBdRjjMC1cfbeQp41--t0ygT2XzVTS8mMXb7iF721S1JVtD_nylEF1B6OZkfcXUdaCZ1lWhW5cOLBlcrtYe4b4aGXhjnXNLG6TRDYCajAnkts7zN05rGF55hEuISADKRZVHwckKF4H2Uldwl2TeCXz7dNL95heNoq0dmFYPFZwXSuFPc',
    'https://lh3.googleusercontent.com/aida-public/AB6AXuDzh9YKMlrsA0RKU6EFe4jj-sxLQCOvnV-vq5sjpbP5XK1NEzvb8gPYs1OsEvvmmFGQY68DWUPKDHXF8mPsatSiLkUrRy1jRmdMoN2gElPUg2dSNP4MMlemea4AjBSj9lHX1nCqsbTIPLBHqth7QUsTsxOOo2HOYJeEF1uiRfEApqh3_Nz8GShw1O75AiW6lniMJZQhz6nsfjYPmk78WdoCohFFYoHAufZIFepp71eSQsFEU-mwXmsYbqcnWa1nhc4PlVP_rgQ2cGCX',
    'https://lh3.googleusercontent.com/aida-public/AB6AXuBxXiBK-BrGdvUoD_GZrj8MYhOyN0AtHW4UXWpbWvMLv0mowtXUN4iUCo9y8pQQC-zWPoHBPgTVt-gAUk2RdP8mkx423v9cSRvGrl8XR85OE8ofV5XBCcuSmxcjlFiyu4ewbMs-EZ11COSAGnNIq0QCB__t7nz__9l9kdnmmdrnfdUs-96s5S_3AHQ5XWV6YWZIEcWNgMKO2l36Dh5G-q8nEkQhhSrvxYxZWWQnbaVwyOdJ4LhkyljjoTENIczndPcnYiZ0TeOnVpn4',
    'https://lh3.googleusercontent.com/aida-public/AB6AXuA5eIpaRB6EVvGKbIgEEYMseCzGHUYtQ6FHbyxwXag82A8wwj54JaeFYaM3xTrtliWkp2lpty6TFIvFzzeS-LI6vJYDUggJCQnyxqPEFdOb-KhuS751adRnkl9PRnJiMqaXMwDeYSU1t2W4ixUpMudDOQ8d82udY_SW7uEObRtpGQnnMINOb0b68p-Fzq1oBQ0Yufg8UzjZcm7vC9bwhy6fIMvD-fddWAwt0oRddq6H977OxubNZZ9KVYEeyNMm2xkaxRaSD60Uj_Q4',
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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

    final borderColor = isFailed ? const Color(0xFF7D2B2B) : chipBorder;

    final card = Container(
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
                          const Icon(
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
                                  const Icon(Icons.schedule, size: 14, color: subduedText),
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
    );

    return _SwipeRevealCard(
      key: ValueKey('draft-${draft.id}'),
      borderRadius: BorderRadius.circular(22),
      actionWidth: deleteActionWidth,
      backgroundBuilder: (close) => _buildDeleteBackground(
        width: deleteActionWidth,
        onTap: () async {
          final ok = await _confirmDelete(context);
          if (!ok) {
            close();
            return;
          }
          await _deleteDraft(context, ref);
        },
      ),
      onTap: () => _openDetail(context, ref),
      child: card,
    );
  }

  Widget _buildDeleteBackground({required VoidCallback onTap, required double width}) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(22),
      child: Container(
        alignment: Alignment.centerRight,
        color: const Color(0xFF7D2B2B),
        child: Align(
          alignment: Alignment.centerRight,
          child: SizedBox(
            width: width,
            height: double.infinity,
            child: InkWell(
              onTap: onTap,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: const [
                  _DeleteIcon(),
                  SizedBox(width: 10),
                  Text(
                    '削除',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<bool> _confirmDelete(BuildContext context) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: surfaceDark,
          title: const Text('告知を削除しますか？', style: TextStyle(color: Colors.white)),
          content: Text(
            'この操作は元に戻せません。',
            style: TextStyle(color: mutedText),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text('キャンセル', style: TextStyle(color: mutedText)),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('削除', style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );
    return result ?? false;
  }

  Future<void> _deleteDraft(BuildContext context, WidgetRef ref) async {
    await ref.read(draftListProvider.notifier).delete(draft.id);
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('告知を削除しました')),
    );
  }

  Future<void> _openDetail(BuildContext context, WidgetRef ref) async {
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => PostPreparerationScreen(draftId: draft.id)),
    );
    if (!context.mounted) return;
    await ref.read(draftListProvider.notifier).refresh();
  }

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

  Widget _buildThumbnail({
    required bool isFailed,
    required String imageUrl,
    required List<String> platforms,
  }) {
    final image = _buildThumbnailImage(imageUrl);

    final imageWidget = isFailed
        ? ColorFiltered(
            colorFilter: const ColorFilter.mode(Colors.grey, BlendMode.saturation),
            child: image,
          )
        : image;

    return SizedBox(
      width: 88,
      height: 88,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: Stack(
          clipBehavior: Clip.hardEdge,
          children: [
            Positioned.fill(child: imageWidget),
            if (platforms.isNotEmpty)
              Positioned(
                bottom: 4,
                right: 4,
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
                bottom: 4,
                left: 4,
                child: _errorBadge(),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildThumbnailImage(String imageUrl) {
    final fallback = Container(
      width: 88,
      height: 88,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        color: surfaceDarkElevated,
      ),
      child: Icon(Icons.image, color: mutedText),
    );
    if (_isRemoteImage(imageUrl)) {
      return Image.network(
        imageUrl,
        width: 88,
        height: 88,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => fallback,
      );
    }
    return Image.file(
      File(imageUrl),
      width: 88,
      height: 88,
      fit: BoxFit.cover,
      errorBuilder: (_, __, ___) => fallback,
    );
  }

  Widget _platformBadge(String assetPath) {
    return ClipOval(
      child: Image.asset(
        assetPath,
        width: 22,
        height: 22,
        fit: BoxFit.cover,
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

  String _imageUrlForDraft(Draft draft) {
    if (draft.imageUrls.isNotEmpty) {
      return draft.imageUrls.first;
    }
    final index = draft.id.hashCode.abs() % previewImages.length;
    return previewImages[index];
  }

  bool _isRemoteImage(String value) {
    final uri = Uri.tryParse(value);
    if (uri == null) return false;
    return uri.scheme == 'http' || uri.scheme == 'https';
  }

  List<String> _platformsForDraft(Draft draft) {
    if (draft.targets.isNotEmpty) {
      return draft.targets.map((target) {
        if (target.toLowerCase() == 'instagram') return instagramIconAsset;
        return xIconAsset;
      }).toList();
    }
    final index = draft.id.hashCode.abs() % 3;
    if (index == 0) return [xIconAsset];
    if (index == 1) return [instagramIconAsset];
    return [xIconAsset, instagramIconAsset];
  }
}

class _SwipeRevealCard extends StatefulWidget {
  const _SwipeRevealCard({
    super.key,
    required this.child,
    required this.backgroundBuilder,
    required this.onTap,
    required this.borderRadius,
    required this.actionWidth,
  });

  final Widget child;
  final Widget Function(VoidCallback close) backgroundBuilder;
  final VoidCallback onTap;
  final BorderRadius borderRadius;
  final double actionWidth;

  @override
  State<_SwipeRevealCard> createState() => _SwipeRevealCardState();
}

class _SwipeRevealCardState extends State<_SwipeRevealCard> {
  double _offset = 0;
  bool _dragging = false;

  void _setOffset(double value) {
    final clamped = value.clamp(-widget.actionWidth, 0.0);
    if (clamped == _offset) return;
    setState(() => _offset = clamped);
  }

  void _handleDragStart(DragStartDetails details) {
    setState(() => _dragging = true);
  }

  void _handleDragUpdate(DragUpdateDetails details) {
    final delta = details.primaryDelta;
    if (delta == null) return;
    _setOffset(_offset + delta);
  }

  void _handleDragEnd(DragEndDetails details) {
    setState(() => _dragging = false);
    final shouldOpen = _offset.abs() >= widget.actionWidth * 0.5;
    _setOffset(shouldOpen ? -widget.actionWidth : 0);
  }

  void _handleDragCancel() {
    setState(() => _dragging = false);
    final shouldOpen = _offset.abs() >= widget.actionWidth * 0.5;
    _setOffset(shouldOpen ? -widget.actionWidth : 0);
  }

  void _handleTap() {
    if (_offset != 0) {
      _setOffset(0);
      return;
    }
    widget.onTap();
  }

  @override
  Widget build(BuildContext context) {
    final duration = _dragging ? Duration.zero : const Duration(milliseconds: 180);
    void close() => _setOffset(0);
    return ClipRRect(
      borderRadius: widget.borderRadius,
      child: Stack(
        children: [
          Positioned.fill(child: widget.backgroundBuilder(close)),
          GestureDetector(
            onHorizontalDragStart: _handleDragStart,
            onHorizontalDragUpdate: _handleDragUpdate,
            onHorizontalDragEnd: _handleDragEnd,
            onHorizontalDragCancel: _handleDragCancel,
            behavior: HitTestBehavior.translucent,
            child: AnimatedContainer(
              duration: duration,
              curve: Curves.easeOut,
              transform: Matrix4.translationValues(_offset, 0, 0),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: _handleTap,
                  borderRadius: widget.borderRadius,
                  child: widget.child,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DeleteIcon extends StatelessWidget {
  const _DeleteIcon();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 34,
      height: 34,
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.16),
        borderRadius: BorderRadius.circular(17),
      ),
      child: const Center(
        child: Icon(Icons.delete_outline, size: 18, color: Colors.white),
      ),
    );
  }
}
