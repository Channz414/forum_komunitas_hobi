import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/config.dart';
import '../../core/theme.dart';
import '../../models/community.dart';
import '../../providers/community_provider.dart';
import '../../providers/post_provider.dart';
import '../../widgets/community_card.dart';
import '../../widgets/user_avatar.dart';

class CommunityScreen extends StatefulWidget {
  const CommunityScreen({super.key});
  @override
  State<CommunityScreen> createState() => _CommunityScreenState();
}

class _CommunityScreenState extends State<CommunityScreen> {
  String _query = '';

  void _snack(String m) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(m)));

  Future<void> _toggle(Community c) async {
    await context.read<CommunityProvider>().toggleJoin(c);
    if (!mounted) return;
    // feed Home bergantung pada komunitas yang diikuti, jadi refresh
    context.read<PostProvider>().fetch();
  }

  Future<void> _showCreate() async {
    final name = TextEditingController();
    final desc = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Buat Komunitas'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: name,
              decoration: const InputDecoration(labelText: 'Nama komunitas'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: desc,
              maxLines: 2,
              decoration: const InputDecoration(
                labelText: 'Deskripsi (opsional)',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Batal'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Buat'),
          ),
        ],
      ),
    );
    if (ok != true || name.text.trim().isEmpty) return;
    if (!mounted) return;
    try {
      await context.read<CommunityProvider>().create(
        name.text.trim(),
        desc.text.trim(),
      );
    } catch (e) {
      if (mounted) _snack('Gagal membuat komunitas: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final prov = context.watch<CommunityProvider>();
    final q = _query.toLowerCase();
    bool match(Community c) => c.name.toLowerCase().contains(q);
    final joined = prov.all.where((c) => c.joined && match(c)).toList();
    final others = prov.all.where((c) => !c.joined && match(c)).toList();
    final name =
        (supabase.auth.currentUser?.userMetadata?['username'] as String?) ??
        'U';

    return SafeArea(
      child: RefreshIndicator(
        onRefresh: prov.fetch,
        child: ListView(
          padding: const EdgeInsets.only(bottom: 24),
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
              child: Row(
                children: [
                  const Expanded(
                    child: Text(
                      'Komunitas',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  UserAvatar(name: name),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
              child: TextField(
                onChanged: (v) => setState(() => _query = v),
                decoration: InputDecoration(
                  hintText: 'Cari komunitas',
                  prefixIcon: const Icon(Icons.search),
                  filled: true,
                  fillColor: Colors.white,
                  contentPadding: EdgeInsets.zero,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(30),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ),
            InkWell(
              onTap: _showCreate,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 14,
                ),
                decoration: const BoxDecoration(
                  border: Border.symmetric(
                    horizontal: BorderSide(color: AppColors.ink),
                  ),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.add, size: 28),
                    SizedBox(width: 12),
                    Text(
                      'Buat Komunitas Anda Sendiri',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            if (prov.loading && prov.all.isEmpty)
              const Padding(
                padding: EdgeInsets.all(40),
                child: Center(child: CircularProgressIndicator()),
              ),
            _sectionTitle('Komunitas yang Anda Ikuti'),
            if (joined.isEmpty && !prov.loading)
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 20),
                child: Text('Belum ada komunitas yang diikuti'),
              ),
            for (final c in joined)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: CommunityCard(
                  community: c,
                  actionLabel: 'Keluar',
                  onAction: () => _toggle(c),
                ),
              ),
            if (others.isNotEmpty) _sectionTitle('Jelajahi Komunitas'),
            for (final c in others)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: CommunityCard(
                  community: c,
                  actionLabel: 'Gabung',
                  onAction: () => _toggle(c),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _sectionTitle(String t) => Padding(
    padding: const EdgeInsets.fromLTRB(20, 24, 20, 12),
    child: Text(
      t,
      style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
    ),
  );
}
