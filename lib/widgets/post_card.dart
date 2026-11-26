import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:timeago/timeago.dart' as timeago;

import '../core/theme.dart';
import '../models/post.dart';
import '../providers/post_provider.dart';
import '../screens/community/community_detail_screen.dart';
import '../screens/post/post_detail_screen.dart';
import 'post_menu.dart';
import 'profile_link.dart';
import 'user_avatar.dart';

class PostCard extends StatelessWidget {
  final Post post;
  final bool tappable; // false kalau dipakai di layar detail post
  final bool linkCommunity; // false kalau sudah di layar komunitasnya
  final VoidCallback? onChanged; // dipanggil setelah edit/hapus
  const PostCard({
    super.key,
    required this.post,
    this.tappable = true,
    this.linkCommunity = true,
    this.onChanged,
  });

  // layar gambar penuh, bisa di-zoom dan digeser
  void _showImage(BuildContext context, String url) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => Scaffold(
          backgroundColor: Colors.black,
          appBar: AppBar(
            backgroundColor: Colors.black,
            foregroundColor: Colors.white,
          ),
          body: Center(
            child: InteractiveViewer(maxScale: 5, child: Image.network(url)),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    const bold = TextStyle(fontWeight: FontWeight.w700);
    final edited = post.editedAt != null ? ' · diedit' : '';

    final card = Container(
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: const [
          BoxShadow(
            color: AppColors.shadow,
            blurRadius: 10,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Row(
                  children: [
                    ProfileLink(
                      userId: post.userId,
                      username: post.username,
                      child: UserAvatar(
                        name: post.username,
                        imageUrl: post.avatarUrl,
                        radius: 26,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          ProfileLink(
                            userId: post.userId,
                            username: post.username,
                            child: Text(
                              post.username,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                          Wrap(
                            children: [
                              GestureDetector(
                                onTap: linkCommunity
                                    ? () => Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (_) => CommunityDetailScreen(
                                            communityId: post.communityId,
                                            name: post.communityName,
                                          ),
                                        ),
                                      )
                                    : null,
                                child: Text(
                                  post.communityName,
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    decoration: linkCommunity
                                        ? TextDecoration.underline
                                        : null,
                                  ),
                                ),
                              ),
                              Text(
                                ' · ${timeago.format(post.createdAt, locale: 'id')}$edited',
                                style: const TextStyle(fontSize: 12),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              PostMenu(
                post: post,
                popOnDelete: !tappable,
                onChanged: onChanged,
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(post.content),
          if (post.imageUrl != null) ...[
            const SizedBox(height: 12),
            GestureDetector(
              onTap: () => _showImage(context, post.imageUrl!),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                // tinggi mengikuti rasio asli gambar, maksimal 420
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxHeight: 420),
                  child: Image.network(
                    post.imageUrl!,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    loadingBuilder: (context, child, progress) =>
                        progress == null
                        ? child
                        : const SizedBox(
                            height: 200,
                            child: Center(child: CircularProgressIndicator()),
                          ),
                    errorBuilder: (_, __, ___) => const SizedBox(
                      height: 200,
                      child: Center(child: Icon(Icons.broken_image)),
                    ),
                  ),
                ),
              ),
            ),
          ],
          const SizedBox(height: 12),
          Row(
            children: [
              InkWell(
                onTap: () => context.read<PostProvider>().toggleLike(post),
                child: Row(
                  children: [
                    Icon(
                      post.likedByMe ? Icons.favorite : Icons.favorite_border,
                      color: post.likedByMe ? Colors.red : AppColors.ink,
                    ),
                    const SizedBox(width: 6),
                    Text('${post.likeCount}', style: bold),
                  ],
                ),
              ),
              const SizedBox(width: 20),
              Row(
                children: [
                  const Icon(Icons.chat_bubble_outline, color: AppColors.ink),
                  const SizedBox(width: 6),
                  Text('${post.commentCount}', style: bold),
                ],
              ),
            ],
          ),
        ],
      ),
    );

    if (!tappable) return card;

    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => PostDetailScreen(post: post)),
      ),
      child: card,
    );
  }
}
