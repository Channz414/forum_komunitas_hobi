import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:timeago/timeago.dart' as timeago;

import '../../core/config.dart';
import '../../core/theme.dart';
import '../../models/app_notification.dart';
import '../../models/post.dart';
import '../../providers/notification_provider.dart';
import '../../widgets/app_chip.dart';
import '../post/post_detail_screen.dart';

class NotificationScreen extends StatefulWidget {
  const NotificationScreen({super.key});
  @override
  State<NotificationScreen> createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen> {
  void _snack(String m) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(m)));

  Future<void> _open(AppNotification n) async {
    context.read<NotificationProvider>().markRead(n);
    if (n.postId == null) return;
    try {
      final row = await supabase
          .from('posts_feed')
          .select()
          .eq('id', n.postId!)
          .maybeSingle();
      if (!mounted) return;
      if (row == null) {
        _snack('Postingan tidak ditemukan');
        return;
      }
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => PostDetailScreen(post: Post.fromMap(row)),
        ),
      );
    } catch (_) {
      if (mounted) _snack('Gagal membuka postingan');
    }
  }

  IconData _icon(String type) {
    switch (type) {
      case 'like':
        return Icons.favorite;
      case 'comment':
        return Icons.chat_bubble;
      default:
        return Icons.event;
    }
  }

  @override
  Widget build(BuildContext context) {
    final np = context.watch<NotificationProvider>();
    final items = np.visible;

    return SafeArea(
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 8, 8),
            child: Row(
              children: [
                const Expanded(
                  child: Text(
                    'Notifikasi',
                    style: TextStyle(fontSize: 28, fontWeight: FontWeight.w800),
                  ),
                ),
                TextButton(
                  onPressed: np.unreadCount == 0 ? null : np.markAllRead,
                  child: const Text('Tandai semua dibaca'),
                ),
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
                  selected: !np.unreadOnly,
                  onTap: () => np.setUnreadOnly(false),
                ),
                AppChip(
                  label: 'Belum dibaca',
                  selected: np.unreadOnly,
                  onTap: () => np.setUnreadOnly(true),
                ),
              ],
            ),
          ),
          Expanded(
            child: RefreshIndicator(
              onRefresh: np.fetch,
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                children: [
                  if (np.loading && np.items.isEmpty)
                    const Padding(
                      padding: EdgeInsets.all(40),
                      child: Center(child: CircularProgressIndicator()),
                    )
                  else if (np.error != null)
                    Padding(
                      padding: const EdgeInsets.all(24),
                      child: Text('Gagal memuat: ${np.error}'),
                    )
                  else if (items.isEmpty)
                    const Padding(
                      padding: EdgeInsets.all(40),
                      child: Center(child: Text('Belum ada notifikasi')),
                    )
                  else
                    for (final n in items)
                      Container(
                        margin: const EdgeInsets.only(bottom: 10),
                        decoration: BoxDecoration(
                          color: n.isRead
                              ? Colors.white
                              : const Color(0xFFFFF4DA),
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: const [
                            BoxShadow(color: AppColors.shadow, blurRadius: 6),
                          ],
                        ),
                        child: ListTile(
                          onTap: () => _open(n),
                          leading: CircleAvatar(
                            backgroundColor: AppColors.teal,
                            child: Icon(
                              _icon(n.type),
                              color: AppColors.tealText,
                              size: 20,
                            ),
                          ),
                          title: Text(
                            n.message,
                            style: TextStyle(
                              fontWeight: n.isRead
                                  ? FontWeight.w400
                                  : FontWeight.w700,
                            ),
                          ),
                          subtitle: Text(
                            timeago.format(n.createdAt, locale: 'id'),
                            style: const TextStyle(fontSize: 12),
                          ),
                        ),
                      ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
