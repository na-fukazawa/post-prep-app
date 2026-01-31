import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/draft_providers.dart';
import '../services/caption_builder.dart';
import '../services/draft_store.dart';

class PostPrepScreen extends ConsumerStatefulWidget {
  final Draft? draft;
  final String? initialRaw;

  const PostPrepScreen({Key? key, this.draft, this.initialRaw}) : super(key: key);

  @override
  ConsumerState<PostPrepScreen> createState() => _PostPrepScreenState();
}

class _PostPrepScreenState extends ConsumerState<PostPrepScreen> {
  static const Color primary = Color(0xFF00FFCC);
  static const Color backgroundDark = Color(0xFF0E121A);
  static const Color surfaceDark = Color(0xFF161B26);
  static const Color inputDark = Color(0xFF1F2735);
  static const Color mutedText = Color(0xFF9AA3B2);

  final _formKey = GlobalKey<FormState>();
  late TextEditingController _rawController;
  late TextEditingController _titleController;
  late TextEditingController _bodyController;
  DateTime? _publishAt;
  bool _targetX = true;
  bool _targetInstagram = true;
  bool _isGenerating = false;
  String? _publishAtError;
  String? _targetsError;

  @override
  void initState() {
    super.initState();
    final draft = widget.draft;
    final initialRaw = draft?.rawText ?? widget.initialRaw ?? '';
    _rawController = TextEditingController(text: initialRaw);
    _bodyController = TextEditingController(text: draft?.generated ?? '');
    _titleController = TextEditingController(
      text: draft?.title.isNotEmpty == true ? draft?.title : _extractTitle(initialRaw, draft?.generated ?? ''),
    );
    _publishAt = draft != null ? DateTime.fromMillisecondsSinceEpoch(draft.publishAt) : null;
    if (draft?.targets.isNotEmpty == true) {
      final normalized = draft!.targets.map((target) => target.toLowerCase()).toList();
      _targetX = normalized.contains('x') || normalized.contains('twitter');
      _targetInstagram = normalized.contains('instagram');
    }
  }

  @override
  void dispose() {
    _rawController.dispose();
    _titleController.dispose();
    _bodyController.dispose();
    super.dispose();
  }

  Future<void> _generateFromRaw() async {
    setState(() => _isGenerating = true);
    final raw = _rawController.text.trim();
    final out = CaptionBuilder.buildCaption(raw);
    setState(() {
      _bodyController.text = out;
      if (_titleController.text.trim().isEmpty) {
        _titleController.text = _extractTitle(raw, out);
      }
      _isGenerating = false;
    });
  }

  Future<void> _save(String status) async {
    if (!_validateRequired()) return;
    final now = DateTime.now();
    final draft = Draft(
      id: widget.draft?.id ?? now.millisecondsSinceEpoch.toString(),
      rawText: _rawController.text.trim(),
      generated: _bodyController.text.trim(),
      status: status,
      createdAt: widget.draft?.createdAt ?? now.millisecondsSinceEpoch,
      title: _titleController.text.trim(),
      publishAt: _publishAt!.millisecondsSinceEpoch,
      targets: _selectedTargets(),
    );
    await ref.read(draftListProvider.notifier).save(draft);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(status == 'scheduled' ? '公開予約しました' : '下書きを保存しました')),
    );
    Navigator.of(context).pop();
  }

  bool _validateRequired() {
    final formValid = _formKey.currentState?.validate() ?? true;
    var valid = formValid;

    if (_publishAt == null) {
      _publishAtError = '公開日時を選択してください。';
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

    return Scaffold(
      backgroundColor: backgroundDark,
      appBar: AppBar(
        backgroundColor: backgroundDark,
        elevation: 0,
        title: Text(isEditing ? '告知編集' : '新規作成'),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
          children: [
            _sectionTitle('スマート入力'),
            _card(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '主催者から届いた情報を貼り付けると本文案を生成します。',
                    style: TextStyle(fontSize: 12, color: mutedText, height: 1.4),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: _rawController,
                    maxLines: 4,
                    style: const TextStyle(color: Colors.white),
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
                        backgroundColor: primary,
                        foregroundColor: Colors.black,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),
            _sectionTitle('告知タイトル'),
            TextFormField(
              controller: _titleController,
              style: const TextStyle(color: Colors.white),
              decoration: _inputDecoration('ライブ名やイベント名'),
              validator: (value) => (value ?? '').trim().isEmpty ? 'タイトルは必須です。' : null,
            ),
            const SizedBox(height: 18),
            _sectionTitle('投稿本文'),
            TextFormField(
              controller: _bodyController,
              maxLines: 6,
              style: const TextStyle(color: Colors.white),
              decoration: _inputDecoration('投稿用キャプション'),
              validator: (value) => (value ?? '').trim().isEmpty ? '本文は必須です。' : null,
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
                        selected: _targetX,
                        onSelected: (value) => setState(() => _targetX = value),
                        label: const Text('X'),
                        selectedColor: primary,
                        checkmarkColor: Colors.black,
                        labelStyle: TextStyle(color: _targetX ? Colors.black : Colors.white),
                        backgroundColor: inputDark,
                      ),
                      FilterChip(
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
    );
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
        border: Border.all(color: const Color(0xFF1F2735)),
      ),
      child: child,
    );
  }

  InputDecoration _inputDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(color: mutedText),
      filled: true,
      fillColor: inputDark,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
    );
  }
}
