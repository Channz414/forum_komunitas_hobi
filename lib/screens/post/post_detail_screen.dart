import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:timeago/timeago.dart' as timeago;

import '../../core/config.dart';
import '../../models/comment.dart';
import '../../models/post.dart';
import '../../providers/comment_provider.dart';
import '../../providers/post_provider.dart';
import '../../widgets/app_card.dart';
import '../../widgets/post_card.dart';
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
  final _text = TextEditingController();
  bool _sending = false;

  @override
  void dispose() {
    _text.dispose();
    super.dispose();
  }

  void _snack(String m) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(m)));

  Future<void> _send() async {
    final content = _text.text.trim();
    if (content.isEmpty || _sending) return;
    setState(() => _sending = true);
    try {
      await context.read<CommentProvider>().add(content);
      if (!mounted) return;
      context.read<PostProvider>().bumpCommentCount(widget.post, 1);
      _text.clear();
    } catch (e) {
      if (mounted) _snack('Gagal mengirim komentar: $e');
    }
    if (mounted) setState(() => _sending = false);
  }

  Future<void> _delete(Comment c) async {
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
              padding: const EdgeInsets.fromLTRB(16, 8, 8, 8),
              decoration: const BoxDecoration(
                color: Colors.white,
                boxShadow: [BoxShadow(color: Color(0x26000000), blurRadius: 6)],
              ),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _text,
                      minLines: 1,
                      maxLines: 4,
                      textInputAction: TextInputAction.send,
                      onSubmitted: (_) => _send(),
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
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.send),
                  ),
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
    return AppCard(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          UserAvatar(name: comment.username, radius: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  comment.username,
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                Text(
                  timeago.format(comment.createdAt, locale: 'id'),
                  style: const TextStyle(fontSize: 11),
                ),
                const SizedBox(height: 4),
                Text(comment.content),
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
