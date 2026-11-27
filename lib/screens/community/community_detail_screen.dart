import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../models/event.dart';
import '../../providers/community_detail_provider.dart';
import '../../providers/community_provider.dart';
import '../../providers/event_provider.dart';
import '../../providers/post_provider.dart';
import '../../widgets/app_chip.dart';
import '../../widgets/community_card.dart' show formatNumber;
import '../../widgets/confirm_dialog.dart';
import '../../widgets/event_card.dart';
import '../../widgets/post_card.dart';
import '../../widgets/post_composer.dart';
import '../../widgets/profile_link.dart';
import 'edit_community_screen.dart';
import 'members_screen.dart';

const _reportReasons = [
  'Spam',
  'Ujaran kebencian atau pelecehan',
  'Konten tidak pantas',
  'Informasi palsu (hoax)',
  'Lainnya',
];

enum _Action { members, edit, delete, report, leave }

class CommunityDetailScreen extends StatelessWidget {
  final String communityId;
  final String? name; // judul sementara selagi loading
  const CommunityDetailScreen({
    super.key,
    required this.communityId,
    this.name,
  });

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => CommunityDetailProvider(communityId)..fetch(),
      child: _CommunityDetailView(fallbackName: name),
    );
  }
}

class _CommunityDetailView extends StatelessWidget {
  final String? fallbackName;
  const _CommunityDetailView({this.fallbackName});

  Future<void> _toggle(BuildContext context) async {
    final p = context.read<CommunityDetailProvider>();
    final cp = context.read<CommunityProvider>();
    final pp = context.read<PostProvider>();
    final messenger = ScaffoldMessenger.of(context);
    final c = p.info;
    if (c == null) return;

    // keluar butuh konfirmasi, gabung langsung
    if (c.joined) {
      final ok = await confirmDialog(
        context,
        title: 'Keluar dari ${c.name}?',
        message:
            'Postingan komunitas ini tidak akan muncul lagi di beranda '
            'Anda. Anda bisa bergabung lagi kapan saja.',
        confirmLabel: 'Keluar',
      );
      if (!ok) return;
    }
    try {
      await p.toggleJoin();
      cp.fetch();
      pp.fetch(); // feed Home bergantung pada komunitas yang diikuti
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text('Gagal: $e')));
    }
  }

  // tombol Ikut di kartu event. Event di layar ini salinan sendiri,
  // jadi layar Event utama di-fetch ulang supaya ikut sinkron
  Future<void> _toggleEvent(BuildContext context, Event e) async {
    final ep = context.read<EventProvider>();
    await ep.toggleAttend(e);
    ep.fetch();
  }

  void _members(BuildContext context) {
    final p = context.read<CommunityDetailProvider>();
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ChangeNotifierProvider.value(
          value: p,
          child: const MembersScreen(),
        ),
      ),
    );
  }

  void _edit(BuildContext context) {
    final p = context.read<CommunityDetailProvider>();
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ChangeNotifierProvider.value(
          value: p,
          child: const EditCommunityScreen(),
        ),
      ),
    );
  }

  Future<void> _delete(BuildContext context) async {
    final p = context.read<CommunityDetailProvider>();
    final cp = context.read<CommunityProvider>();
    final pp = context.read<PostProvider>();
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    final ok = await confirmDialog(
      context,
      title: 'Hapus komunitas?',
      message:
          'Semua postingan dan event di komunitas ini ikut terhapus permanen.',
      confirmLabel: 'Hapus',
    );
    if (!ok) return;
    try {
      await p.delete();
      cp.fetch();
      pp.fetch();
      navigator.pop();
      messenger.showSnackBar(
        const SnackBar(content: Text('Komunitas dihapus')),
      );
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text('Gagal menghapus: $e')));
    }
  }

  Future<void> _report(BuildContext context) async {
    final p = context.read<CommunityDetailProvider>();
    final messenger = ScaffoldMessenger.of(context);
    final reason = await showModalBottomSheet<String>(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Padding(
              padding: EdgeInsets.all(16),
              child: Text(
                'Alasan melaporkan komunitas',
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
      await p.report(reason);
      messenger.showSnackBar(
        const SnackBar(content: Text('Laporan terkirim, terima kasih')),
      );
    } on PostgrestException catch (e) {
      // 23505 = unique violation (sudah pernah melapor)
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            e.code == '23505'
                ? 'Anda sudah melaporkan komunitas ini'
                : 'Gagal melapor: ${e.message}',
          ),
        ),
      );
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text('Gagal melapor: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = context.watch<CommunityDetailProvider>();
    context.watch<PostProvider>(); // supaya like di kartu ikut ter-update
    context.watch<EventProvider>(); // supaya tombol Ikut ikut ter-update
    final c = p.info;

    final children = <Widget>[];
    if (c == null) {
      children.add(
        Padding(
          padding: const EdgeInsets.all(40),
          child: Center(
            child: p.loading
                ? const CircularProgressIndicator()
                : Text(
                    p.gone
                        ? 'Komunitas tidak ditemukan'
                        : 'Gagal memuat: ${p.error}',
                  ),
          ),
        ),
      );
    } else {
      children.addAll([
        ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: c.imageUrl != null && c.imageUrl!.isNotEmpty
              ? Image.network(
                  c.imageUrl!,
                  height: 160,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => _bannerPlaceholder(),
                )
              : _bannerPlaceholder(),
        ),
        const SizedBox(height: 16),
        Text(
          c.name,
          style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 4),
        Row(
          children: [
            const Icon(Icons.people_outline, size: 18),
            const SizedBox(width: 6),
            Text('${formatNumber(c.memberCount)} Anggota'),
          ],
        ),
        if (c.description != null && c.description!.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 12),
            child: Text(c.description!),
          ),
        if (c.ownerId != null)
          Padding(
            padding: const EdgeInsets.only(top: 12),
            child: ProfileLink(
              userId: c.ownerId!,
              username: c.ownerUsername,
              child: Text(
                'Dibuat oleh ${c.ownerUsername ?? '-'}',
                style: const TextStyle(
                  fontSize: 12,
                  decoration: TextDecoration.underline,
                ),
              ),
            ),
          ),
        const SizedBox(height: 16),
        // bukan anggota: tombol Gabung (tab apa pun)
        if (!c.joined) ...[
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: () => _toggle(context),
              child: const Text('Gabung'),
            ),
          ),
          const SizedBox(height: 12),
        ],
        // chip tab: Postingan / Event
        Row(
          children: [
            AppChip(
              label: 'Postingan',
              selected: p.tab == CommunityTab.posts,
              onTap: () => p.setTab(CommunityTab.posts),
            ),
            AppChip(
              label: 'Event (${p.events.length})',
              selected: p.tab == CommunityTab.events,
              onTap: () => p.setTab(CommunityTab.events),
            ),
          ],
        ),
        const SizedBox(height: 8),
      ]);

      if (p.tab == CommunityTab.posts) {
        if (c.joined) {
          children.addAll([
            PostComposer(
              communityId: c.id,
              hint: 'Bagikan sesuatu ke ${c.name}...',
              onPosted: p.fetch,
            ),
            const SizedBox(height: 16),
          ]);
        }
        if (!c.joined) {
          children.add(
            const Padding(
              padding: EdgeInsets.all(24),
              child: Center(
                child: Text('Gabung komunitas ini untuk melihat postingannya'),
              ),
            ),
          );
        } else if (p.posts.isEmpty) {
          children.add(
            const Padding(
              padding: EdgeInsets.all(24),
              child: Center(child: Text('Belum ada postingan')),
            ),
          );
        } else {
          for (final post in p.posts) {
            children.add(
              PostCard(post: post, onChanged: p.fetch, linkCommunity: false),
            );
          }
        }
      } else {
        final events = p.sortedEvents;
        if (events.isEmpty) {
          children.add(
            const Padding(
              padding: EdgeInsets.all(24),
              child: Center(child: Text('Belum ada event di komunitas ini')),
            ),
          );
        } else {
          for (final e in events) {
            children.add(
              EventCard(event: e, onToggle: () => _toggleEvent(context, e)),
            );
          }
        }
      }
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(c?.name ?? fallbackName ?? 'Komunitas'),
        actions: [
          if (c != null)
            PopupMenuButton<_Action>(
              tooltip: 'Opsi',
              onSelected: (a) {
                switch (a) {
                  case _Action.members:
                    _members(context);
                  case _Action.edit:
                    _edit(context);
                  case _Action.delete:
                    _delete(context);
                  case _Action.report:
                    _report(context);
                  case _Action.leave:
                    _toggle(context);
                }
              },
              itemBuilder: (_) => [
                const PopupMenuItem(
                  value: _Action.members,
                  child: Text('Lihat anggota'),
                ),
                if (c.isOwner) ...[
                  const PopupMenuItem(
                    value: _Action.edit,
                    child: Text('Edit komunitas'),
                  ),
                  const PopupMenuItem(
                    value: _Action.delete,
                    child: Text(
                      'Hapus komunitas',
                      style: TextStyle(color: Colors.red),
                    ),
                  ),
                ] else ...[
                  const PopupMenuItem(
                    value: _Action.report,
                    child: Text('Laporkan komunitas'),
                  ),
                  if (c.joined)
                    const PopupMenuItem(
                      value: _Action.leave,
                      child: Text(
                        'Keluar dari komunitas',
                        style: TextStyle(color: Colors.red),
                      ),
                    ),
                ],
              ],
            ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: p.fetch,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
          children: children,
        ),
      ),
    );
  }

  Widget _bannerPlaceholder() => Container(
    height: 160,
    width: double.infinity,
    color: const Color(0xFFD9D9D9),
    child: const Icon(Icons.groups, size: 56, color: Colors.white),
  );
}
