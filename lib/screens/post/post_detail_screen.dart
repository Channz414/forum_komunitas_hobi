import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:timeago/timeago.dart' as timeago;

import '../../core/config.dart';
import '../../models/comment.dart';
import '../../models/post.dart';
import '../../providers/comment_provider.dart';
import '../../providers/post_provider.dart';
import '../../widgets/app_card.dart';
import '../../widgets/confirm_dialog.dart';
import '../../widgets/emoji_panel.dart';
import '../../widgets/image_viewer.dart';
import '../../widgets/post_card.dart';
import '../../widgets/profile_link.dart';
import '../../widgets/user_avatar.dart';

class PostDetailScreen extends StatelessWidget {
  final Post post;
  const PostDetailScreen({super.key, required this.post});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => CommentProvider(post.id)..fetch(),
      child: _PostDetailView(post: post),
    );
  }
}

class _PostDetailView extends StatefulWidget {
  final Post post;
  const _PostDetailView({required this.post});
  @override
  State<_PostDetailView> createState() => _PostDetailViewState();
}

class _PostDetailViewState extends State<_PostDetailView> {
  // tidak dikompres supaya GIF tetap beranimasi, jadi ukurannya dibatasi
  static const _maxBytes = 8 * 1024 * 1024;

  final _text = TextEditingController();
  final _focus = FocusNode();
  XFile? _image;
  Uint8List? _bytes;
  bool _sending = false;
  bool _showEmoji = false;

  @override
  void dispose() {
    _text.dispose();
    _focus.dispose();
    super.dispose();
  }

  void _snack(String m) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(m)));

  Future<void> _pickImage() async {
    final x = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (x == null) return;
    if (await x.length() > _maxBytes) {
      _snack('Ukuran file maksimal 8 MB');
      return;
    }
    final b = await x.readAsBytes();
    if (!mounted) return;
    setState(() {
      _image = x;
      _bytes = b;
    });
  }

  void _removeImage() => setState(() {
    _image = null;
    _bytes = null;
  });

  void _toggleEmoji() {
    if (_showEmoji) {
      setState(() => _showEmoji = false);
      _focus.requestFocus(); // balik ke keyboard biasa
    } else {
      FocusScope.of(context).unfocus(); // sembunyikan keyboard
      setState(() => _showEmoji = true);
    }
  }

  // sisipkan emoji di posisi kursor
  void _insertEmoji(String e) {
    final sel = _text.selection;
    final start = sel.isValid ? sel.start : _text.text.length;
    final end = sel.isValid ? sel.end : _text.text.length;
    _text.value = TextEditingValue(
      text: _text.text.replaceRange(start, end, e),
      selection: TextSelection.collapsed(offset: start + e.length),
    );
  }

  Future<void> _send() async {
    final content = _text.text.trim();
    if ((content.isEmpty && _image == null) || _sending) return;
    setState(() => _sending = true);
    try {
      await context.read<CommentProvider>().add(content, image: _image);
      if (!mounted) return;
      context.read<PostProvider>().bumpCommentCount(widget.post, 1);
      _text.clear();
      setState(() {
        _image = null;
        _bytes = null;
        _showEmoji = false;
      });
    } catch (e) {
      if (mounted) _snack('Gagal mengirim komentar: $e');
    }
    if (mounted) setState(() => _sending = false);
  }

  Future<void> _delete(Comment c) async {
    final ok = await confirmDialog(
      context,
      title: 'Hapus komentar?',
      message: 'Komentar ini akan dihapus permanen.',
      confirmLabel: 'Hapus',
    );
    if (!ok || !mounted) return;
    try {
      await context.read<CommentProvider>().remove(c);
      if (!mounted) return;
      context.read<PostProvider>().bumpCommentCount(widget.post, -1);
    } catch (e) {
      if (mounted) _snack('Gagal menghapus komentar: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    context.watch<PostProvider>(); // supaya like di kartu langsung ter-update
    final cp = context.watch<CommentProvider>();
    final uid = supabase.auth.currentUser?.id;

    return Scaffold(
      appBar: AppBar(title: const Text('Postingan')),
      body: Column(
        children: [
          Expanded(
            child: RefreshIndicator(
              onRefresh: cp.fetch,
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                children: [
                  PostCard(post: widget.post, tappable: false),
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12, left: 4),
                    child: Text(
                      'Komentar (${cp.comments.length})',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  if (cp.loading && cp.comments.isEmpty)
                    const Padding(
                      padding: EdgeInsets.all(24),
                      child: Center(child: CircularProgressIndicator()),
                    )
                  else if (cp.error != null)
                    Text('Gagal memuat komentar: ${cp.error}')
                  else if (cp.comments.isEmpty)
                    const Padding(
                      padding: EdgeInsets.all(24),
                      child: Center(child: Text('Belum ada komentar')),
                    )
                  else
                    for (final c in cp.comments)
                      _CommentTile(
                        comment: c,
                        isMine: c.userId == uid,
                        onDelete: () => _delete(c),
                      ),
                ],
              ),
            ),
          ),
          SafeArea(
            top: false,
            child: Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                boxShadow: [BoxShadow(color: Color(0x26000000), blurRadius: 6)],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // pratinjau gambar/GIF yang akan dikirim
                  if (_bytes != null)
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: Stack(
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: Image.memory(
                                _bytes!,
                                width: 96,
                                height: 96,
                                fit: BoxFit.cover,
                              ),
                            ),
                            Positioned(
                              right: 4,
                              top: 4,
                              child: GestureDetector(
                                onTap: _removeImage,
                                child: const CircleAvatar(
                                  radius: 12,
                                  backgroundColor: Colors.black87,
                                  child: Icon(
                                    Icons.close,
                                    size: 14,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  Padding(
                    padding: const EdgeInsets.all(4),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        IconButton(
                          tooltip: 'Emoji',
                          onPressed: _toggleEmoji,
                          icon: Icon(
                            _showEmoji
                                ? Icons.keyboard_outlined
                                : Icons.emoji_emotions_outlined,
                          ),
                        ),
                        IconButton(
                          tooltip: 'Foto atau GIF',
                          onPressed: _sending ? null : _pickImage,
                          icon: const Icon(Icons.image_outlined),
                        ),
                        Expanded(
                          child: TextField(
                            controller: _text,
                            focusNode: _focus,
                            minLines: 1,
                            maxLines: 4,
                            onTap: () {
                              if (_showEmoji) {
                                setState(() => _showEmoji = false);
                              }
                            },
                            decoration: const InputDecoration(
                              hintText: 'Tulis komentar...',
                              border: InputBorder.none,
                            ),
                          ),
                        ),
                        IconButton(
                          onPressed: _sending ? null : _send,
                          icon: _sending
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Icon(Icons.send),
                        ),
                      ],
                    ),
                  ),
                  if (_showEmoji) EmojiPanel(onPick: _insertEmoji),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CommentTile extends StatelessWidget {
  final Comment comment;
  final bool isMine;
  final VoidCallback onDelete;
  const _CommentTile({
    required this.comment,
    required this.isMine,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final img = comment.imageUrl;
    return AppCard(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ProfileLink(
            userId: comment.userId,
            username: comment.username,
            child: UserAvatar(
              name: comment.username,
              imageUrl: comment.avatarUrl,
              radius: 18,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ProfileLink(
                  userId: comment.userId,
                  username: comment.username,
                  child: Text(
                    comment.username,
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                ),
                Text(
                  timeago.format(comment.createdAt, locale: 'id'),
                  style: const TextStyle(fontSize: 11),
                ),
                if (comment.content.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(comment.content),
                ],
                if (img != null && img.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  GestureDetector(
                    onTap: () => showImageViewer(context, img),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(
                          maxWidth: 260,
                          maxHeight: 260,
                        ),
                        child: Image.network(
                          img,
                          width: double.infinity,
                          fit: BoxFit.cover,
                          loadingBuilder: (context, child, progress) =>
                              progress == null
                              ? child
                              : const SizedBox(
                                  height: 120,
                                  child: Center(
                                    child: CircularProgressIndicator(),
                                  ),
                                ),
                          errorBuilder: (_, __, ___) => const SizedBox(
                            height: 120,
                            child: Center(child: Icon(Icons.broken_image)),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
          if (isMine)
            IconButton(
              visualDensity: VisualDensity.compact,
              tooltip: 'Hapus komentar',
              icon: const Icon(Icons.delete_outline, size: 20),
              onPressed: onDelete,
            ),
        ],
      ),
    );
  }
}
