import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/config.dart';
import '../../core/format.dart';
import '../../core/theme.dart';
import '../../providers/post_provider.dart';
import '../../providers/user_profile_provider.dart';
import '../../widgets/friend_button.dart';
import '../../widgets/post_card.dart';
import '../../widgets/user_avatar.dart';
import '../friend/friend_list_screen.dart';

class UserProfileScreen extends StatelessWidget {
  final String userId;
  final String? username; // buat judul sementara selagi loading
  const UserProfileScreen({super.key, required this.userId, this.username});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => UserProfileProvider(userId)..fetch(),
      child: _UserProfileView(userId: userId, fallbackName: username),
    );
  }
}

class _UserProfileView extends StatelessWidget {
  final String userId;
  final String? fallbackName;
  const _UserProfileView({required this.userId, this.fallbackName});

  @override
  Widget build(BuildContext context) {
    final up = context.watch<UserProfileProvider>();
    context.watch<PostProvider>(); // supaya like di kartu ikut ter-update
    final title = up.username.isNotEmpty
        ? up.username
        : (fallbackName ?? 'Profil');
    final isMe = userId == supabase.auth.currentUser?.id;

    final countText = Text(
      '${up.friendCount} Teman',
      style: const TextStyle(fontWeight: FontWeight.w700),
    );

    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: RefreshIndicator(
        onRefresh: up.fetch,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(16, 24, 16, 24),
          children: [
            if (up.loading && up.username.isEmpty)
              const Padding(
                padding: EdgeInsets.all(40),
                child: Center(child: CircularProgressIndicator()),
              )
            else if (up.error != null && up.username.isEmpty)
              Padding(
                padding: const EdgeInsets.all(24),
                child: Text('Gagal memuat: ${up.error}'),
              )
            else ...[
              Center(
                child: UserAvatar(
                  name: up.username,
                  imageUrl: up.avatarUrl,
                  radius: 44,
                ),
              ),
              const SizedBox(height: 12),
              Center(
                child: Text(
                  up.username,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              if (up.bio != null && up.bio!.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Center(
                    child: Text(up.bio!, textAlign: TextAlign.center),
                  ),
                ),
              // jumlah teman: profil sendiri bisa diketuk buat lihat daftar,
              // profil orang lain hanya angka
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: Center(
                  child: isMe
                      ? InkWell(
                          borderRadius: BorderRadius.circular(8),
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const FriendListScreen(),
                            ),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                countText,
                                const SizedBox(width: 4),
                                const Icon(Icons.chevron_right, size: 18),
                              ],
                            ),
                          ),
                        )
                      : countText,
                ),
              ),
              if (up.joinedAt != null)
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Center(
                    child: Text(
                      'Bergabung ${bulanPendek(up.joinedAt!)} ${up.joinedAt!.year}',
                      style: const TextStyle(fontSize: 12),
                    ),
                  ),
                ),
              // tombol pertemanan, tidak muncul di profil sendiri
              if (!isMe)
                Padding(
                  padding: const EdgeInsets.only(top: 16),
                  child: Center(
                    child: FriendButton(userId: userId, username: up.username),
                  ),
                ),
              if (up.communities.isNotEmpty) ...[
                const SizedBox(height: 16),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  alignment: WrapAlignment.center,
                  children: [
                    for (final c in up.communities)
                      Chip(
                        label: Text(c),
                        backgroundColor: AppColors.chip,
                        side: const BorderSide(color: AppColors.chipBorder),
                        visualDensity: VisualDensity.compact,
                      ),
                  ],
                ),
              ],
              const SizedBox(height: 24),
              Text(
                'Postingan (${up.posts.length})',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 12),
              if (up.posts.isEmpty)
                const Padding(
                  padding: EdgeInsets.all(24),
                  child: Center(child: Text('Belum ada postingan')),
                )
              else
                for (final p in up.posts)
                  PostCard(post: p, onChanged: up.fetch),
            ],
          ],
        ),
      ),
    );
  }
}
