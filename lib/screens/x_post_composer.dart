import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/draft_providers.dart';
import '../providers/x_auth_providers.dart';
import '../services/draft_store.dart';
import '../services/x_api_service.dart';

class XPostComposerScreen extends ConsumerStatefulWidget {
  const XPostComposerScreen({
    Key? key,
    required this.draft,
    required this.initialText,
  }) : super(key: key);

  final Draft draft;
  final String initialText;

  @override
  ConsumerState<XPostComposerScreen> createState() => _XPostComposerScreenState();
}

class _XPostComposerScreenState extends ConsumerState<XPostComposerScreen> {
  static const Color primary = Color(0xFF00FFCC);
  static const Color backgroundDark = Color(0xFF0E121A);
  static const Color surfaceDark = Color(0xFF161B26);
  static const Color inputDark = Color(0xFF1F2735);
  static const Color mutedText = Color(0xFF9AA3B2);

  late TextEditingController _textController;
  late TextEditingController _tagController;
  late Draft _draft;

  final List<XUser> _taggedUsers = [];
  bool _isPosting = false;
  bool _isSearching = false;
  String? _tagError;

  @override
  void initState() {
    super.initState();
    _draft = widget.draft;
    _textController = TextEditingController(text: widget.initialText);
    _tagController = TextEditingController();
    _hydrateTaggedUsers();
  }

  @override
  void dispose() {
    _textController.dispose();
    _tagController.dispose();
    super.dispose();
  }

  void _hydrateTaggedUsers() {
    final usernames = _draft.xTaggedUsernames;
    final ids = _draft.xTaggedUserIds;
    if (usernames.isEmpty || ids.isEmpty) return;
    final limit = usernames.length < ids.length ? usernames.length : ids.length;
    for (var i = 0; i < limit; i++) {
      _taggedUsers.add(XUser(id: ids[i], username: usernames[i], name: usernames[i]));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundDark,
      appBar: AppBar(
        backgroundColor: backgroundDark,
        title: const Text('Xに投稿'),
        actions: [
          if (_isPosting)
            const Padding(
              padding: EdgeInsets.only(right: 16),
              child: SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(strokeWidth: 2, color: primary),
              ),
            ),
        ],
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
          children: [
            _buildPreview(),
            const SizedBox(height: 16),
            _buildTextEditor(),
            const SizedBox(height: 16),
            _buildTagSection(),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _isPosting ? null : _postToX,
                icon: const Icon(Icons.send),
                label: const Text('Xに投稿する'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: primary,
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPreview() {
    final images = _draft.imageUrls;
    if (images.isEmpty) {
      return Container(
        height: 160,
        decoration: BoxDecoration(
          color: surfaceDark,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.white10),
        ),
        alignment: Alignment.center,
        child: const Text('画像がありません', style: TextStyle(color: mutedText)),
      );
    }
    return SizedBox(
      height: 160,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: images.length,
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (context, index) {
          final url = images[index];
          final widget = _isRemote(url)
              ? Image.network(url, fit: BoxFit.cover)
              : Image.file(File(url), fit: BoxFit.cover);
          return ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: AspectRatio(
              aspectRatio: 4 / 5,
              child: ColoredBox(color: surfaceDark, child: widget),
            ),
          );
        },
      ),
    );
  }

  Widget _buildTextEditor() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: surfaceDark,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white10),
      ),
      child: TextField(
        controller: _textController,
        maxLines: 6,
        style: const TextStyle(color: Colors.white),
        decoration: const InputDecoration(
          border: InputBorder.none,
          hintText: '本文を入力',
          hintStyle: TextStyle(color: mutedText),
        ),
      ),
    );
  }

  Widget _buildTagSection() {
    final tagCount = _taggedUsers.length;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: surfaceDark,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text('ユーザーをタグ付け', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              const SizedBox(width: 8),
              Text('($tagCount/10)', style: const TextStyle(color: mutedText, fontSize: 12)),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            '例: @Xbox_Japan のように入力して追加します。',
            style: const TextStyle(color: mutedText, fontSize: 11),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _tagController,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: inputDark,
                    hintText: '@username',
                    hintStyle: const TextStyle(color: mutedText),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                  ),
                  onSubmitted: (_) => _addTag(),
                ),
              ),
              const SizedBox(width: 8),
              SizedBox(
                height: 44,
                child: ElevatedButton(
                  onPressed: _isSearching ? null : _addTag,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primary,
                    foregroundColor: Colors.black,
                  ),
                  child: _isSearching
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black),
                        )
                      : const Text('追加'),
                ),
              ),
            ],
          ),
          if (_tagError != null) ...[
            const SizedBox(height: 8),
            Text(_tagError!, style: const TextStyle(color: Colors.redAccent, fontSize: 12)),
          ],
          if (_taggedUsers.isNotEmpty) ...[
            const SizedBox(height: 10),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                for (final user in _taggedUsers)
                  Chip(
                    label: Text('@${user.username}'),
                    backgroundColor: inputDark,
                    deleteIcon: const Icon(Icons.close, size: 18),
                    onDeleted: () => _removeTag(user),
                    labelStyle: const TextStyle(color: Colors.white),
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _addTag() async {
    final input = _tagController.text.trim();
    if (input.isEmpty) return;
    if (_taggedUsers.length >= 10) {
      setState(() => _tagError = 'タグ付けは最大10件までです。');
      return;
    }
    final username = input.replaceAll('@', '').trim();
    if (username.isEmpty) return;
    if (_taggedUsers.any((u) => u.username.toLowerCase() == username.toLowerCase())) {
      setState(() => _tagError = 'すでに追加されています。');
      return;
    }
    setState(() {
      _isSearching = true;
      _tagError = null;
    });
    try {
      final api = ref.read(xApiServiceProvider);
      final user = await api.lookupUserByUsername(username);
      _taggedUsers.add(user);
      _tagController.clear();
      await _saveTags();
    } catch (error) {
      setState(() => _tagError = error.toString());
    } finally {
      if (mounted) {
        setState(() => _isSearching = false);
      }
    }
  }

  Future<void> _removeTag(XUser user) async {
    setState(() {
      _taggedUsers.removeWhere((u) => u.id == user.id);
      _tagError = null;
    });
    await _saveTags();
  }

  Future<void> _saveTags() async {
    final updated = _copyDraftWithTags(
      _draft,
      _taggedUsers.map((u) => u.id).toList(),
      _taggedUsers.map((u) => u.username).toList(),
    );
    _draft = updated;
    await ref.read(draftListProvider.notifier).save(updated);
  }

  Future<void> _postToX() async {
    if (_isPosting) return;
    final text = _textController.text.trim();
    setState(() => _isPosting = true);
    try {
      final api = ref.read(xApiServiceProvider);
      await api.createPost(
        text: text,
        imageUrls: _draft.imageUrls,
        taggedUserIds: _taggedUsers.map((u) => u.id).toList(),
      );
      await ref.read(draftListProvider.notifier).markPosted(_draft);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Xに投稿しました')));
      Navigator.of(context).pop();
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error.toString())));
    } finally {
      if (mounted) {
        setState(() => _isPosting = false);
      }
    }
  }

  Draft _copyDraftWithTags(Draft draft, List<String> ids, List<String> usernames) {
    return Draft(
      id: draft.id,
      rawText: draft.rawText,
      generated: draft.generated,
      status: draft.status,
      createdAt: draft.createdAt,
      title: draft.title,
      publishAt: draft.publishAt,
      targets: draft.targets,
      captionX: draft.captionX,
      captionInstagram: draft.captionInstagram,
      hashtags: draft.hashtags,
      eventDate: draft.eventDate,
      venue: draft.venue,
      performers: draft.performers,
      ticketPrice: draft.ticketPrice,
      ticketUrl: draft.ticketUrl,
      imageUrls: draft.imageUrls,
      xTaggedUserIds: ids,
      xTaggedUsernames: usernames,
    );
  }

  bool _isRemote(String value) {
    final uri = Uri.tryParse(value);
    if (uri == null) return false;
    return uri.scheme == 'http' || uri.scheme == 'https';
  }
}
