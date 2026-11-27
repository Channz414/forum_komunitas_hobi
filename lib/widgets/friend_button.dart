import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../providers/friend_provider.dart';
import 'confirm_dialog.dart';

class FriendButton extends StatelessWidget {
  final String userId;
  final String username;
  final bool compact; // label lebih pendek untuk dipakai di dalam daftar
  const FriendButton({
    super.key,
    required this.userId,
    required this.username,
    this.compact = false,
  });

  Future<void> _run(
    BuildContext context,
    Future<void> Function() action,
  ) async {
    final messenger = ScaffoldMessenger.of(context);
    final fp = context.read<FriendProvider>();
    try {
      await action();
    } on PostgrestException catch (e) {
      // 23505 = relasi sudah ada (misalnya dia lebih dulu mengirim permintaan)
      if (e.code == '23505') {
        await fp.fetch();
        messenger.showSnackBar(
          const SnackBar(content: Text('Relasi pertemanan sudah ada')),
        );
      } else {
        messenger.showSnackBar(SnackBar(content: Text('Gagal: ${e.message}')));
      }
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text('Gagal: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final fp = context.watch<FriendProvider>();
    final rel = fp.relationWith(userId);
    final dense = VisualDensity.compact;

    // belum ada relasi
    if (rel == null) {
      return FilledButton(
        style: FilledButton.styleFrom(visualDensity: dense),
        onPressed: () => _run(context, () => fp.sendRequest(userId)),
        child: Text(compact ? 'Tambah' : 'Tambah teman'),
      );
    }

    // sudah berteman
    if (rel.isAccepted) {
      return OutlinedButton.icon(
        style: OutlinedButton.styleFrom(visualDensity: dense),
        icon: const Icon(Icons.check, size: 18),
        label: Text(compact ? 'Teman' : 'Berteman'),
        onPressed: () => _run(context, () async {
          final ok = await confirmDialog(
            context,
            title: 'Hapus teman?',
            message: '$username akan dihapus dari daftar teman Anda.',
            confirmLabel: 'Hapus',
          );
          if (ok) await fp.remove(rel);
        }),
      );
    }

    // saya yang mengajak, belum diterima
    if (rel.iAmRequester) {
      return OutlinedButton(
        style: OutlinedButton.styleFrom(visualDensity: dense),
        onPressed: () => _run(context, () async {
          final ok = await confirmDialog(
            context,
            title: 'Batalkan permintaan?',
            message: 'Permintaan pertemanan ke $username akan dibatalkan.',
            confirmLabel: 'Batalkan',
          );
          if (ok) await fp.remove(rel);
        }),
        child: Text(compact ? 'Terkirim' : 'Permintaan terkirim'),
      );
    }

    // dia yang mengajak: Terima / Tolak
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        FilledButton(
          style: FilledButton.styleFrom(visualDensity: dense),
          onPressed: () => _run(context, () => fp.accept(rel)),
          child: const Text('Terima'),
        ),
        const SizedBox(width: 8),
        OutlinedButton(
          style: OutlinedButton.styleFrom(visualDensity: dense),
          onPressed: () => _run(context, () => fp.remove(rel)),
          child: const Text('Tolak'),
        ),
      ],
    );
  }
}
