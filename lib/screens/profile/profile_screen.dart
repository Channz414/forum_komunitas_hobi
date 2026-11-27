import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/config.dart';
import '../../providers/friend_provider.dart';
import '../../providers/post_provider.dart';
import '../../providers/profile_provider.dart';
import '../../widgets/post_card.dart';
import '../../widgets/user_avatar.dart';
import '../friend/friend_list_screen.dart';
import 'edit_profile_screen.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final pp = context.watch<ProfileProvider>();
    final friendCount = context.watch<FriendProvider>().friends.length;
    context.watch<PostProvider>(); // supaya like di kartu langsung ter-update
    final shownName = pp.username.isEmpty ? 'U' : pp.username;

    return SafeArea(
      child: RefreshIndicator(
        onRefresh: pp.fetch,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(16, 24, 16, 24),
          children: [
            Center(
              child: UserAvatar(
                name: shownName,
                imageUrl: pp.avatarUrl,
                radius: 44,
              ),
            ),
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
            if (pp.bio != null && pp.bio!.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Center(
                  child: Text(pp.bio!, textAlign: TextAlign.center),
                ),
              ),
            // ketuk jumlah teman -> daftar teman (hanya terlihat oleh sendiri)
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: Center(
                child: InkWell(
                  borderRadius: BorderRadius.circular(8),
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const FriendListScreen()),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          '$friendCount Teman',
                          style: const TextStyle(fontWeight: FontWeight.w700),
                        ),
                        const SizedBox(width: 4),
                        const Icon(Icons.chevron_right, size: 18),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                OutlinedButton.icon(
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const EditProfileScreen(),
                    ),
                  ),
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
              for (final p in pp.posts) PostCard(post: p, onChanged: pp.fetch),
          ],
        ),
      ),
    );
  }
}
