import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/community_detail_provider.dart';
import '../../providers/community_provider.dart';
import '../../providers/post_provider.dart';
import '../../widgets/community_card.dart' show formatNumber;
import '../../widgets/post_card.dart';
import '../../widgets/profile_link.dart';
import 'edit_community_screen.dart';

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
    try {
      await p.toggleJoin();
      cp.fetch();
      pp.fetch(); // feed Home bergantung pada komunitas yang diikuti
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text('Gagal: $e')));
    }
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
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Hapus komunitas?'),
        content: const Text(
          'Semua postingan dan event di komunitas ini ikut terhapus permanen.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Batal'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );
    if (ok != true) return;
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

  @override
  Widget build(BuildContext context) {
    final p = context.watch<CommunityDetailProvider>();
    context.watch<PostProvider>(); // supaya like di kartu ikut ter-update
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
        if (c.isOwner)
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFFFF4DA),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Text('Anda adalah pemilik komunitas ini'),
          )
        else
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: () => _toggle(context),
              child: Text(c.joined ? 'Keluar' : 'Gabung'),
            ),
          ),
        const SizedBox(height: 24),
        const Text(
          'Postingan',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 12),
        if (!c.joined)
          const Padding(
            padding: EdgeInsets.all(24),
            child: Center(
              child: Text('Gabung komunitas ini untuk melihat postingannya'),
            ),
          )
        else if (p.posts.isEmpty)
          const Padding(
            padding: EdgeInsets.all(24),
            child: Center(child: Text('Belum ada postingan')),
          )
        else
          for (final post in p.posts)
            PostCard(post: post, onChanged: p.fetch, linkCommunity: false),
      ]);
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(c?.name ?? fallbackName ?? 'Komunitas'),
        actions: [
          if (c?.isOwner == true)
            PopupMenuButton<String>(
              onSelected: (v) =>
                  v == 'edit' ? _edit(context) : _delete(context),
              itemBuilder: (_) => const [
                PopupMenuItem(value: 'edit', child: Text('Edit komunitas')),
                PopupMenuItem(value: 'delete', child: Text('Hapus komunitas')),
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
