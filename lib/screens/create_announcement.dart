import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/draft_providers.dart';
import '../providers/settings_providers.dart';
import '../services/caption_builder.dart';
import '../services/draft_store.dart';
import '../services/settings_store.dart';

class CreateAnnouncementScreen extends ConsumerStatefulWidget {
  final Draft? draft;
  final String? initialRaw;

  const CreateAnnouncementScreen({Key? key, this.draft, this.initialRaw}) : super(key: key);

  @override
  ConsumerState<CreateAnnouncementScreen> createState() => _CreateAnnouncementScreenState();
}

class _CreateAnnouncementScreenState extends ConsumerState<CreateAnnouncementScreen> {
  static const Color primary = Color(0xFF00FFCC);
  static const Color backgroundDark = Color(0xFF0E121A);
  static const Color surfaceDark = Color(0xFF1A1F2D);
  static const Color surfaceDarkAlt = Color(0xFF151925);
  static const Color inputDark = Color(0xFF252B3B);
  static const Color borderDark = Color(0xFF2A3240);
  static const Color mutedText = Color(0xFF9AA3B2);
  static const int xCharacterLimit = 280;
  static const int xUrlLength = 23;
  static const String instagramIconAsset = 'assets/icons/instagram.jpg';
  static const String xIconAsset = 'assets/icons/x.jpg';

  final _formKey = GlobalKey<FormState>();
  late TextEditingController _rawController;
  late TextEditingController _titleController;
  late TextEditingController _captionInstagramController;
  late TextEditingController _captionXController;
  late TextEditingController _hashtagsController;
  late TextEditingController _eventDateController;
  late TextEditingController _venueController;
  late TextEditingController _performersController;
  late TextEditingController _ticketPriceController;
  late TextEditingController _ticketUrlController;
  late TextEditingController _imageUrlsController;
  DateTime? _publishAt;
  bool _targetX = true;
  bool _targetInstagram = true;
  bool _isGenerating = false;
  String? _publishAtError;
  String? _targetsError;
  String? _captionError;
  int _captionTabIndex = 0;
  bool _didApplyDefaults = false;

  @override
  void initState() {
    super.initState();
    final draft = widget.draft;
    final initialRaw = draft?.rawText ?? widget.initialRaw ?? '';
    final generated = draft?.generated ?? '';
    _rawController = TextEditingController(text: initialRaw);
    _titleController = TextEditingController(
      text: draft?.title.isNotEmpty == true ? draft?.title : _extractTitle(initialRaw, generated),
    );
    _captionInstagramController = TextEditingController(
      text: draft?.captionInstagram ?? generated,
    );
    _captionXController = TextEditingController(
      text: draft?.captionX ?? generated,
    );
    _hashtagsController = TextEditingController(text: draft?.hashtags ?? '');
    _eventDateController = TextEditingController(text: draft?.eventDate ?? '');
    _venueController = TextEditingController(text: draft?.venue ?? '');
    _performersController = TextEditingController(text: draft?.performers ?? '');
    _ticketPriceController = TextEditingController(text: draft?.ticketPrice ?? '');
    _ticketUrlController = TextEditingController(text: draft?.ticketUrl ?? '');
    _imageUrlsController = TextEditingController(text: (draft?.imageUrls ?? []).join('\n'));
    _publishAt = draft != null ? DateTime.fromMillisecondsSinceEpoch(draft.publishAt) : null;
    if (draft?.targets.isNotEmpty == true) {
      final normalized = draft!.targets.map((target) => target.toLowerCase()).toList();
      _targetX = normalized.contains('x') || normalized.contains('twitter');
      _targetInstagram = normalized.contains('instagram');
    }
    if (draft != null) {
      _didApplyDefaults = true;
    }
  }

  @override
  void dispose() {
    _rawController.dispose();
    _titleController.dispose();
    _captionInstagramController.dispose();
    _captionXController.dispose();
    _hashtagsController.dispose();
    _eventDateController.dispose();
    _venueController.dispose();
    _performersController.dispose();
    _ticketPriceController.dispose();
    _ticketUrlController.dispose();
    _imageUrlsController.dispose();
    super.dispose();
  }

  Future<void> _generateFromRaw() async {
    setState(() => _isGenerating = true);
    final raw = _rawController.text.trim();
    final out = CaptionBuilder.buildCaption(raw);
    setState(() {
      _captionInstagramController.text = out;
      _captionXController.text = out;
      if (_titleController.text.trim().isEmpty) {
        _titleController.text = _extractTitle(raw, out);
      }
      _isGenerating = false;
    });
  }

  Future<void> _save(String status) async {
    if (!_validateRequired(status)) return;
    final now = DateTime.now();
    final captionInstagram = _captionInstagramController.text.trim();
    final captionX = _captionXController.text.trim();
    final generated = captionInstagram.isNotEmpty ? captionInstagram : captionX;
    final draft = Draft(
      id: widget.draft?.id ?? now.millisecondsSinceEpoch.toString(),
      rawText: _rawController.text.trim(),
      generated: generated,
      status: status,
      createdAt: widget.draft?.createdAt ?? now.millisecondsSinceEpoch,
      title: _titleController.text.trim(),
      publishAt: _publishAt?.millisecondsSinceEpoch ?? widget.draft?.publishAt ?? now.millisecondsSinceEpoch,
      targets: _selectedTargets(),
      captionInstagram: captionInstagram,
      captionX: captionX,
      hashtags: _hashtagsController.text.trim(),
      eventDate: _eventDateController.text.trim(),
      venue: _venueController.text.trim(),
      performers: _performersController.text.trim(),
      ticketPrice: _ticketPriceController.text.trim(),
      ticketUrl: _ticketUrlController.text.trim(),
      imageUrls: _parseImageUrls(_imageUrlsController.text),
    );
    await ref.read(draftListProvider.notifier).save(draft);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(status == 'scheduled' ? '公開予約しました' : '下書きを保存しました')),
    );
    Navigator.of(context).pop();
  }

  bool _validateRequired(String status) {
    final formValid = _formKey.currentState?.validate() ?? true;
    var valid = formValid;
    final requireScheduleFields = status == 'scheduled';

    if (requireScheduleFields) {
      if (_publishAt == null) {
        _publishAtError = '公開日時を選択してください。';
        valid = false;
      } else if (_publishAt!.isBefore(DateTime.now())) {
        _publishAtError = '過去の日時は設定できません。';
        valid = false;
      } else {
        _publishAtError = null;
      }

      if (_selectedTargets().isEmpty) {
        _targetsError = '投稿対象を選択してください。';
        valid = false;
      } else {
        _targetsError = null;
      }

      _captionError = null;
      final captionInstagram = _captionInstagramController.text.trim();
      final captionX = _captionXController.text.trim();
      if (_targetInstagram && captionInstagram.isEmpty) {
        _captionError = 'Instagramの本文は必須です。';
        valid = false;
      }
      if (_targetX && captionX.isEmpty) {
        _captionError ??= 'Xの本文は必須です。';
        valid = false;
      }
      final captionXCombined = _composeWithHashtags(captionX);
      if (_targetX && _countXCharacters(captionXCombined) > xCharacterLimit) {
        _captionError = 'Xの文字数は$xCharacterLimit文字以内にしてください。';
        valid = false;
      }
    } else {
      _publishAtError = null;
      _targetsError = null;
      _captionError = null;
    }

    if (!valid) {
      setState(() {});
    }

    return valid;
  }

  List<String> _selectedTargets() {
    final targets = <String>[];
    if (_targetX) targets.add('x');
    if (_targetInstagram) targets.add('instagram');
    return targets;
  }

  String _extractTitle(String raw, String generated) {
    final source = raw.trim().isNotEmpty ? raw : generated;
    final firstLine = source.split(RegExp(r'\r?\n')).first.trim();
    return firstLine.isEmpty ? '無題の告知' : firstLine;
  }

  String _formatDate(DateTime date) {
    final year = date.year.toString();
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');
    return '$year/$month/$day';
  }

  String _formatTime(DateTime date) {
    final hour = date.hour.toString().padLeft(2, '0');
    final minute = date.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final base = _publishAt ?? now;
    final date = await showDatePicker(
      context: context,
      initialDate: base,
      firstDate: DateTime(now.year - 1),
      lastDate: DateTime(now.year + 2),
    );
    if (date == null) return;
    setState(() {
      _publishAt = DateTime(
        date.year,
        date.month,
        date.day,
        base.hour,
        base.minute,
      );
      _publishAtError = null;
    });
  }

  Future<void> _pickTime() async {
    final now = DateTime.now();
    final base = _publishAt ?? now;
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: base.hour, minute: base.minute),
    );
    if (time == null) return;
    setState(() {
      _publishAt = DateTime(
        base.year,
        base.month,
        base.day,
        time.hour,
        time.minute,
      );
      _publishAtError = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.draft != null;
    final settings = ref.watch(settingsProvider).value;
    if (settings != null && widget.draft == null) {
      _applyDefaultsIfNeeded(settings);
    }

    return Scaffold(
      backgroundColor: backgroundDark,
      appBar: AppBar(
        backgroundColor: backgroundDark,
        elevation: 0,
        centerTitle: true,
        foregroundColor: Colors.white,
        systemOverlayStyle: SystemUiOverlayStyle.light,
        title: Text(
          isEditing ? '告知編集' : '新規作成 (スマート抽出)',
          style: const TextStyle(
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
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
            children: [
            _buildSmartInputCard(),
            const SizedBox(height: 18),
            _buildImageUploadCard(),
            const SizedBox(height: 18),
            _sectionTitle('告知タイトル'),
            TextFormField(
              controller: _titleController,
              style: const TextStyle(color: Colors.white),
              keyboardAppearance: Brightness.dark,
              decoration: _inputDecoration('ライブ名やイベント名'),
              validator: (value) => (value ?? '').trim().isEmpty ? 'タイトルは必須です。' : null,
            ),
            const SizedBox(height: 18),
            _sectionTitle('イベント詳細'),
            _card(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextField(
                    controller: _eventDateController,
                    style: const TextStyle(color: Colors.white),
                    keyboardAppearance: Brightness.dark,
                    decoration: _inputDecoration('イベント日時 例: 2024/02/01 19:00'),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: _venueController,
                    style: const TextStyle(color: Colors.white),
                    keyboardAppearance: Brightness.dark,
                    decoration: _inputDecoration('会場'),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: _performersController,
                    style: const TextStyle(color: Colors.white),
                    keyboardAppearance: Brightness.dark,
                    decoration: _inputDecoration('出演者'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),
            _sectionTitle('チケット情報'),
            _card(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextField(
                    controller: _ticketPriceController,
                    style: const TextStyle(color: Colors.white),
                    keyboardAppearance: Brightness.dark,
                    decoration: _inputDecoration('料金 例: 3,000円'),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: _ticketUrlController,
                    style: const TextStyle(color: Colors.white),
                    keyboardAppearance: Brightness.dark,
                    keyboardType: TextInputType.url,
                    decoration: _inputDecoration('チケットURL'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),
            _sectionTitle('投稿本文'),
            _card(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Wrap(
                    spacing: 8,
                    children: [
                      ChoiceChip(
                        avatar: _platformAvatar(instagramIconAsset),
                        label: const Text('Instagram'),
                        selected: _captionTabIndex == 0,
                        onSelected: (_) => setState(() => _captionTabIndex = 0),
                        selectedColor: primary,
                        labelStyle: TextStyle(color: _captionTabIndex == 0 ? Colors.black : Colors.white),
                        backgroundColor: inputDark,
                      ),
                      ChoiceChip(
                        avatar: _platformAvatar(xIconAsset),
                        label: const Text('X'),
                        selected: _captionTabIndex == 1,
                        onSelected: (_) => setState(() => _captionTabIndex = 1),
                        selectedColor: primary,
                        labelStyle: TextStyle(color: _captionTabIndex == 1 ? Colors.black : Colors.white),
                        backgroundColor: inputDark,
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  TextFormField(
                    controller: _captionTabIndex == 0 ? _captionInstagramController : _captionXController,
                    maxLines: 6,
                    style: const TextStyle(color: Colors.white),
                    keyboardAppearance: Brightness.dark,
                    decoration: _inputDecoration('投稿用キャプション'),
                    onChanged: (_) => setState(() {}),
                  ),
                  if (_captionTabIndex == 1) ...[
                    const SizedBox(height: 6),
                    _buildXCount(),
                  ],
                  if (_captionError != null) ...[
                    const SizedBox(height: 8),
                    Text(_captionError!, style: const TextStyle(color: Colors.redAccent, fontSize: 12)),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 18),
            _sectionTitle('ハッシュタグ'),
            _card(
              child: TextField(
                controller: _hashtagsController,
                style: const TextStyle(color: Colors.white),
                keyboardAppearance: Brightness.dark,
                decoration: _inputDecoration('#イベント #ライブ'),
              ),
            ),
            const SizedBox(height: 18),
            _sectionTitle('公開日時'),
            _card(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: _pickDate,
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: Color(0xFF2B3546)),
                            foregroundColor: Colors.white,
                          ),
                          child: Text(_publishAt == null ? '日付を選ぶ' : _formatDate(_publishAt!)),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: OutlinedButton(
                          onPressed: _pickTime,
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: Color(0xFF2B3546)),
                            foregroundColor: Colors.white,
                          ),
                          child: Text(_publishAt == null ? '時間を選ぶ' : _formatTime(_publishAt!)),
                        ),
                      ),
                    ],
                  ),
                  if (_publishAtError != null) ...[
                    const SizedBox(height: 8),
                    Text(_publishAtError!, style: const TextStyle(color: Colors.redAccent, fontSize: 12)),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 18),
            _sectionTitle('投稿対象SNS'),
            _card(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Wrap(
                    spacing: 10,
                    children: [
                      FilterChip(
                        avatar: _platformAvatar(xIconAsset),
                        selected: _targetX,
                        onSelected: (value) => setState(() => _targetX = value),
                        label: const Text('X'),
                        selectedColor: primary,
                        checkmarkColor: Colors.black,
                        labelStyle: TextStyle(color: _targetX ? Colors.black : Colors.white),
                        backgroundColor: inputDark,
                      ),
                      FilterChip(
                        avatar: _platformAvatar(instagramIconAsset),
                        selected: _targetInstagram,
                        onSelected: (value) => setState(() => _targetInstagram = value),
                        label: const Text('Instagram'),
                        selectedColor: primary,
                        checkmarkColor: Colors.black,
                        labelStyle: TextStyle(color: _targetInstagram ? Colors.black : Colors.white),
                        backgroundColor: inputDark,
                      ),
                    ],
                  ),
                  if (_targetsError != null) ...[
                    const SizedBox(height: 8),
                    Text(_targetsError!, style: const TextStyle(color: Colors.redAccent, fontSize: 12)),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => _save('draft'),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Color(0xFF2B3546)),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    child: const Text('下書き保存'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => _save('scheduled'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primary,
                      foregroundColor: Colors.black,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    child: const Text('公開予約'),
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

  void _applyDefaultsIfNeeded(AppSettings settings) {
    if (_didApplyDefaults) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || _didApplyDefaults) return;
      final hashtags = settings.defaultHashtags.trim();
      final template = settings.defaultTemplate.trim();
      if (_hashtagsController.text.trim().isEmpty && hashtags.isNotEmpty) {
        _hashtagsController.text = hashtags;
      }
      if (template.isNotEmpty) {
        if (_captionInstagramController.text.trim().isEmpty) {
          _captionInstagramController.text = template;
        }
        if (_captionXController.text.trim().isEmpty) {
          _captionXController.text = template;
        }
      }
      _didApplyDefaults = true;
    });
  }

  void _openImageUrlSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: surfaceDark,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            final urls = _parseImageUrls(_imageUrlsController.text);
            return Padding(
              padding: EdgeInsets.fromLTRB(
                16,
                16,
                16,
                24 + MediaQuery.of(context).viewInsets.bottom,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 36,
                      height: 4,
                      margin: const EdgeInsets.only(bottom: 12),
                      decoration: BoxDecoration(
                        color: borderDark,
                        borderRadius: BorderRadius.circular(999),
                      ),
                    ),
                  ),
                  const Text(
                    '画像URL（改行区切りで複数入力可）',
                    style: TextStyle(fontSize: 12, color: mutedText),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: _imageUrlsController,
                    maxLines: 4,
                    style: const TextStyle(color: Colors.white),
                    keyboardAppearance: Brightness.dark,
                    decoration: _inputDecoration('https://example.com/image.jpg'),
                    onChanged: (_) {
                      setSheetState(() {});
                      setState(() {});
                    },
                  ),
                  if (urls.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    _buildImagePreview(urls),
                  ],
                  const SizedBox(height: 14),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () => Navigator.of(context).pop(),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primary,
                        foregroundColor: Colors.black,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: const Text('完了'),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildSmartInputCard() {
    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [surfaceDark, surfaceDarkAlt],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: primary.withOpacity(0.3)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x33000000),
            blurRadius: 12,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            left: 0,
            right: 0,
            top: 0,
            child: Container(
              height: 4,
              decoration: BoxDecoration(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                gradient: LinearGradient(
                  colors: [
                    Colors.transparent,
                    primary.withOpacity(0.7),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: primary.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: primary.withOpacity(0.2)),
                      ),
                      child: const Icon(Icons.auto_awesome, color: primary, size: 18),
                    ),
                    const SizedBox(width: 10),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: const [
                        Text(
                          'スマート入力',
                          style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.white),
                        ),
                        SizedBox(height: 2),
                        Text(
                          'Auto-Fill Powered by AI',
                          style: TextStyle(
                            fontSize: 10,
                            color: mutedText,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.6,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                const Text(
                  '主催者から届いたメールや告知文をそのまま貼り付けるだけで、ライブ名や会場などの情報を自動で抽出します。',
                  style: TextStyle(fontSize: 11, color: mutedText, height: 1.4),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _rawController,
                  maxLines: 4,
                  style: const TextStyle(color: Colors.white),
                  keyboardAppearance: Brightness.dark,
                  decoration: _inputDecoration('主催者からの詳細をペースト'),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _isGenerating ? null : _generateFromRaw,
                    icon: const Icon(Icons.auto_awesome),
                    label: Text(_isGenerating ? '生成中...' : '情報を抽出して下書き作成'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: Colors.black,
                      padding: const EdgeInsets.symmetric(vertical: 13),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImageUploadCard() {
    final urls = _parseImageUrls(_imageUrlsController.text);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GestureDetector(
          onTap: _openImageUrlSheet,
          child: _DashedBorder(
            color: borderDark,
            radius: 16,
            strokeWidth: 1.5,
            dashWidth: 6,
            gap: 4,
            child: Container(
              decoration: BoxDecoration(
                color: surfaceDark,
                borderRadius: BorderRadius.circular(16),
              ),
              child: AspectRatio(
                aspectRatio: 4 / 5,
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _UploadIcon(
                        backgroundColor: inputDark,
                        iconColor: primary,
                      ),
                      const SizedBox(height: 10),
                      const Text(
                        'フライヤー画像をアップロード',
                        style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.white70),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        '推奨サイズ 4:5',
                        style: TextStyle(fontSize: 11, color: mutedText),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
        if (urls.isNotEmpty) ...[
          const SizedBox(height: 10),
          _buildImagePreview(urls),
        ],
      ],
    );
  }

  Widget _buildXCount() {
    final count = _countXCharacters(_composeWithHashtags(_captionXController.text));
    final over = count > xCharacterLimit;
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const Text('X文字数', style: TextStyle(fontSize: 11, color: mutedText)),
        Text(
          '$count/$xCharacterLimit',
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.bold,
            color: over ? Colors.redAccent : mutedText,
          ),
        ),
      ],
    );
  }

  Widget _platformAvatar(String assetPath) {
    return ClipOval(
      child: Image.asset(
        assetPath,
        width: 16,
        height: 16,
        fit: BoxFit.cover,
      ),
    );
  }

  Widget _buildImagePreview(List<String> urls) {
    final previews = urls.take(4).toList();
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final url in previews)
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: Image.network(
              url,
              width: 64,
              height: 64,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Container(
                width: 64,
                height: 64,
                color: inputDark,
                child: const Icon(Icons.image, color: mutedText),
              ),
            ),
          ),
      ],
    );
  }

  List<String> _parseImageUrls(String input) {
    return input
        .split(RegExp(r'[\n,]'))
        .map((s) => s.trim())
        .where((s) => s.isNotEmpty)
        .toList();
  }

  String _composeWithHashtags(String base) {
    final tags = _hashtagsController.text.trim();
    final normalized = base.trim();
    if (tags.isEmpty) return normalized;
    if (normalized.isEmpty) return tags;
    return '$normalized\n$tags';
  }

  int _countXCharacters(String text) {
    if (text.isEmpty) return 0;
    final urlRegex = RegExp(r'(https?:\/\/|www\.)\S+', caseSensitive: false);
    var count = 0;
    var last = 0;
    for (final match in urlRegex.allMatches(text)) {
      count += match.start - last;
      count += xUrlLength;
      last = match.end;
    }
    count += text.length - last;
    return count;
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
        border: Border.all(color: borderDark),
      ),
      child: child,
    );
  }

  InputDecoration _inputDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(color: mutedText, fontSize: 12),
      filled: true,
      fillColor: inputDark,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
    );
  }
}

class _UploadIcon extends StatelessWidget {
  const _UploadIcon({
    required this.backgroundColor,
    required this.iconColor,
  });

  final Color backgroundColor;
  final Color iconColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 52,
      height: 52,
      decoration: BoxDecoration(
        color: backgroundColor,
        shape: BoxShape.circle,
      ),
      child: Icon(Icons.add_photo_alternate, color: iconColor),
    );
  }
}

class _DashedBorder extends StatelessWidget {
  const _DashedBorder({
    required this.child,
    required this.color,
    required this.radius,
    required this.strokeWidth,
    required this.dashWidth,
    required this.gap,
  });

  final Widget child;
  final Color color;
  final double radius;
  final double strokeWidth;
  final double dashWidth;
  final double gap;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _DashedBorderPainter(
        color: color,
        radius: radius,
        strokeWidth: strokeWidth,
        dashWidth: dashWidth,
        gap: gap,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(radius),
        child: child,
      ),
    );
  }
}

class _DashedBorderPainter extends CustomPainter {
  const _DashedBorderPainter({
    required this.color,
    required this.radius,
    required this.strokeWidth,
    required this.dashWidth,
    required this.gap,
  });

  final Color color;
  final double radius;
  final double strokeWidth;
  final double dashWidth;
  final double gap;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke;
    final rrect = RRect.fromRectAndRadius(
      Rect.fromLTWH(0, 0, size.width, size.height),
      Radius.circular(radius),
    );
    final path = Path()..addRRect(rrect);
    for (final metric in path.computeMetrics()) {
      var distance = 0.0;
      while (distance < metric.length) {
        final next = math.min(distance + dashWidth, metric.length);
        canvas.drawPath(metric.extractPath(distance, next), paint);
        distance += dashWidth + gap;
      }
    }
  }

  @override
  bool shouldRepaint(covariant _DashedBorderPainter oldDelegate) {
    return oldDelegate.color != color ||
        oldDelegate.radius != radius ||
        oldDelegate.strokeWidth != strokeWidth ||
        oldDelegate.dashWidth != dashWidth ||
        oldDelegate.gap != gap;
  }
}
