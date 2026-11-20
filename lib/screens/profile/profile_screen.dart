import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/config.dart';
import '../../providers/post_provider.dart';
import '../../providers/profile_provider.dart';
import '../../widgets/post_card.dart';
import '../../widgets/user_avatar.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});
  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  void _snack(String m) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(m)));

  Future<void> _editName(ProfileProvider pp) async {
    final c = TextEditingController(text: pp.username);
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Ubah username'),
        content: TextField(
          controller: c,
          decoration: const InputDecoration(labelText: 'Username'),
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
    final name = c.text.trim();
    if (ok != true || name.isEmpty || name == pp.username) return;
    try {
      await pp.updateUsername(name);
    } on PostgrestException catch (e) {
      // 23505 = unique violation (username sudah dipakai orang lain)
      if (mounted) {
        _snack(
          e.code == '23505'
              ? 'Username sudah dipakai'
              : 'Gagal menyimpan: ${e.message}',
        );
      }
    } catch (e) {
      if (mounted) _snack('Gagal menyimpan: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final pp = context.watch<ProfileProvider>();
    context.watch<PostProvider>(); // supaya like di kartu langsung ter-update
    final shownName = pp.username.isEmpty ? 'U' : pp.username;

    return SafeArea(
      child: RefreshIndicator(
        onRefresh: pp.fetch,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(16, 24, 16, 24),
          children: [
            Center(child: UserAvatar(name: shownName, radius: 44)),
            const SizedBox(height: 12),
            Center(
              child: Text(
                pp.username,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            Center(child: Text(pp.email)),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                OutlinedButton.icon(
                  onPressed: () => _editName(pp),
                  icon: const Icon(Icons.edit_outlined, size: 18),
                  label: const Text('Edit profil'),
                ),
                const SizedBox(width: 12),
                OutlinedButton.icon(
                  onPressed: () => supabase.auth.signOut(),
                  icon: const Icon(Icons.logout, size: 18),
                  label: const Text('Keluar'),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Text(
              'Postingan saya (${pp.posts.length})',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 12),
            if (pp.loading && pp.posts.isEmpty)
              const Padding(
                padding: EdgeInsets.all(24),
                child: Center(child: CircularProgressIndicator()),
              )
            else if (pp.error != null)
              Text('Gagal memuat: ${pp.error}')
            else if (pp.posts.isEmpty)
              const Padding(
                padding: EdgeInsets.all(24),
                child: Center(child: Text('Belum ada postingan')),
              )
            else
              for (final p in pp.posts) PostCard(post: p),
          ],
        ),
      ),
    );
  }
}
