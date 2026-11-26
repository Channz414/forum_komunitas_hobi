import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../core/config.dart';
import '../models/post.dart';
import '../providers/post_provider.dart';

enum _PostAction { edit, delete, report }

const _reportReasons = [
  'Spam',
  'Ujaran kebencian atau pelecehan',
  'Konten tidak pantas',
  'Informasi palsu (hoax)',
  'Lainnya',
];

class PostMenu extends StatelessWidget {
  final Post post;
  final bool popOnDelete; // true kalau dipakai di layar detail
  final VoidCallback?
  onChanged; // refresh list di layar lain setelah edit/hapus
  const PostMenu({
    super.key,
    required this.post,
    this.popOnDelete = false,
    this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final uid = supabase.auth.currentUser?.id;
    final isMine = post.userId == uid;
    final isModerator = !isMine && uid != null && post.communityOwnerId == uid;

    return PopupMenuButton<_PostAction>(
      icon: const Icon(Icons.more_horiz),
      tooltip: 'Opsi',
      onSelected: (a) {
        switch (a) {
          case _PostAction.edit:
            _edit(context);
          case _PostAction.delete:
            _delete(context);
          case _PostAction.report:
            _report(context);
        }
      },
      itemBuilder: (_) => [
        if (isMine)
          const PopupMenuItem(value: _PostAction.edit, child: Text('Edit')),
        if (isMine || isModerator)
          PopupMenuItem(
            value: _PostAction.delete,
            child: Text(isMine ? 'Hapus' : 'Hapus (moderator)'),
          ),
        if (!isMine)
          const PopupMenuItem(
            value: _PostAction.report,
            child: Text('Laporkan'),
          ),
      ],
    );
  }

  Future<void> _edit(BuildContext context) async {
    final messenger = ScaffoldMessenger.of(context);
    final provider = context.read<PostProvider>();
    final c = TextEditingController(text: post.content);
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Edit postingan'),
        content: TextField(
          controller: c,
          autofocus: true,
          minLines: 3,
          maxLines: 6,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Batal'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Simpan'),
          ),
        ],
      ),
    );
    final text = c.text.trim();
    if (ok != true || text.isEmpty || text == post.content) return;
    try {
      await provider.updatePost(post, text);
      onChanged?.call();
      messenger.showSnackBar(
        const SnackBar(content: Text('Postingan diperbarui')),
      );
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text('Gagal mengedit: $e')));
    }
  }

  Future<void> _delete(BuildContext context) async {
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    final provider = context.read<PostProvider>();
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Hapus postingan?'),
        content: const Text(
          'Postingan beserta komentarnya akan dihapus permanen.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Batal'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    try {
      await provider.deletePost(post);
      onChanged?.call();
      if (popOnDelete) navigator.pop();
      messenger.showSnackBar(
        const SnackBar(content: Text('Postingan dihapus')),
      );
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text('Gagal menghapus: $e')));
    }
  }

  Future<void> _report(BuildContext context) async {
    final messenger = ScaffoldMessenger.of(context);
    final provider = context.read<PostProvider>();
    final reason = await showModalBottomSheet<String>(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Padding(
              padding: EdgeInsets.all(16),
              child: Text(
                'Alasan melaporkan postingan',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
              ),
            ),
            for (final r in _reportReasons)
              ListTile(title: Text(r), onTap: () => Navigator.pop(ctx, r)),
          ],
        ),
      ),
    );
    if (reason == null) return;
    try {
      await provider.reportPost(post, reason);
      messenger.showSnackBar(
        const SnackBar(content: Text('Laporan terkirim, terima kasih')),
      );
    } on PostgrestException catch (e) {
      // 23505 = unique violation (udah pernah lapor)
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            e.code == '23505'
                ? 'Anda sudah melaporkan postingan ini'
                : 'Gagal melapor: ${e.message}',
          ),
        ),
      );
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text('Gagal melapor: $e')));
    }
  }
}
