import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';
import '../services/caption_builder.dart';
import '../services/draft_store.dart';

class PostPrepScreen extends StatefulWidget {
  final String? initialRaw;

  const PostPrepScreen({Key? key, this.initialRaw}) : super(key: key);

  @override
  State<PostPrepScreen> createState() => _PostPrepScreenState();
}

class _PostPrepScreenState extends State<PostPrepScreen> {
  late TextEditingController _controller;
  String _generated = '';
  bool _isGenerating = false;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialRaw ?? '');
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _generate() {
    setState(() => _isGenerating = true);
    final raw = _controller.text.trim();
    final out = CaptionBuilder.buildCaption(raw);
    setState(() {
      _generated = out;
      _isGenerating = false;
    });
  }

  Future<void> _copy() async {
    await Clipboard.setData(ClipboardData(text: _generated));
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('コピーしました')));
  }

  Future<void> _share() async {
    if (_generated.isEmpty) return;
    await Share.share(_generated);
  }

  Future<void> _saveDraft({String status = 'draft'}) async {
    final raw = _controller.text.trim();
    final generated = _generated.isNotEmpty ? _generated : CaptionBuilder.buildCaption(raw);
    final id = DateTime.now().millisecondsSinceEpoch.toString();
    final draft = Draft(id: id, rawText: raw, generated: generated, status: status, createdAt: DateTime.now().millisecondsSinceEpoch);
    await DraftStore().saveDraft(draft);
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('下書きを保存しました')));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Post Prep')),
      body: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: TextField(
                controller: _controller,
                maxLines: null,
                expands: true,
                decoration: const InputDecoration(
                  hintText: 'ここに主催者から受け取ったイベント情報をそのまま貼り付けてください',
                  border: OutlineInputBorder(),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: _isGenerating ? null : _generate,
                    child: Text(_isGenerating ? '生成中...' : 'キャプションを生成'),
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: () => _saveDraft(status: 'draft'),
                  child: const Text('下書きを保存'),
                ),
              ],
            ),
            const SizedBox(height: 12),
            const Text('生成されたキャプション', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade300),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: SingleChildScrollView(child: SelectableText(_generated.isEmpty ? 'まだ生成されていません' : _generated)),
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _generated.isEmpty ? null : _copy,
                    icon: const Icon(Icons.copy),
                    label: const Text('コピー'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _generated.isEmpty ? null : _share,
                    icon: const Icon(Icons.share),
                    label: const Text('共有'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
