import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/config.dart';
import '../../core/theme.dart';
import '../../providers/community_provider.dart';
import '../../providers/post_provider.dart';
import '../../widgets/app_chip.dart';
import '../../widgets/post_card.dart';
import '../../widgets/user_avatar.dart';
import '../post/create_post_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final posts = context.watch<PostProvider>();
    final communities = context.watch<CommunityProvider>().joined;
    final name =
        (supabase.auth.currentUser?.userMetadata?['username'] as String?) ??
        'U';

    return SafeArea(
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
            child: Row(
              children: [
                const Text(
                  'Forum Komunitas Hobi',
                  style: TextStyle(fontSize: 32, fontWeight: FontWeight.w800),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: TextField(
                    onSubmitted: posts.setSearch,
                    decoration: InputDecoration(
                      hintText: 'Cari apa hari ini',
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
                const SizedBox(width: 16),
                UserAvatar(name: name),
              ],
            ),
          ),
          SizedBox(
            height: 48,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              children: [
                AppChip(
                  label: 'Semua',
                  selected: posts.communityFilter == null,
                  onTap: () => posts.setFilter(null),
                ),
                for (final c in communities)
                  AppChip(
                    label: c.name,
                    selected: posts.communityFilter == c.id,
                    onTap: () => posts.setFilter(c.id),
                  ),
              ],
            ),
          ),
          Expanded(
            child: RefreshIndicator(
              onRefresh: posts.fetch,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                children: [
                  _Composer(name: name),
                  const SizedBox(height: 16),
                  if (posts.loading && posts.posts.isEmpty)
                    const Padding(
                      padding: EdgeInsets.all(40),
                      child: Center(child: CircularProgressIndicator()),
                    )
                  else if (posts.error != null)
                    Padding(
                      padding: const EdgeInsets.all(24),
                      child: Text('Gagal memuat: ${posts.error}'),
                    )
                  else if (posts.posts.isEmpty)
                    const Padding(
                      padding: EdgeInsets.all(40),
                      child: Center(child: Text('Belum ada postingan')),
                    )
                  else
                    for (final p in posts.posts) PostCard(post: p),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Composer extends StatelessWidget {
  final String name;
  const _Composer({required this.name});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const CreatePostScreen()),
      ),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: const [
            BoxShadow(
              color: AppColors.shadow,
              blurRadius: 6,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            UserAvatar(name: name, radius: 18),
            const SizedBox(width: 12),
            const Expanded(child: Text('Apa kabar hari ini?')),
            const Icon(Icons.add_circle_outline),
          ],
        ),
      ),
    );
  }
}
