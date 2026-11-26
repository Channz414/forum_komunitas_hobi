import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/theme.dart';
import '../providers/profile_provider.dart';
import '../screens/post/create_post_screen.dart';
import 'user_avatar.dart';

class PostComposer extends StatelessWidget {
  final String? communityId; // kalau diisi, komunitas langsung terpilih
  final String hint;
  final VoidCallback?
  onPosted; // dipanggil setelah layar buat postingan ditutup

  const PostComposer({
    super.key,
    this.communityId,
    this.hint = 'Apa kabar hari ini?',
    this.onPosted,
  });

  @override
  Widget build(BuildContext context) {
    final profile = context.watch<ProfileProvider>();
    final name = profile.username.isEmpty ? 'U' : profile.username;

    return GestureDetector(
      onTap: () async {
        await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => CreatePostScreen(initialCommunityId: communityId),
          ),
        );
        onPosted?.call();
      },
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
            UserAvatar(name: name, imageUrl: profile.avatarUrl, radius: 18),
            const SizedBox(width: 12),
            Expanded(
              child: Text(hint, maxLines: 1, overflow: TextOverflow.ellipsis),
            ),
            const Icon(Icons.add_circle_outline),
          ],
        ),
      ),
    );
  }
}
