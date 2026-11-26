import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/theme.dart';
import '../providers/community_provider.dart';
import '../providers/event_provider.dart';
import '../providers/notification_provider.dart';
import '../providers/post_provider.dart';
import '../providers/profile_provider.dart';
import 'community/community_screen.dart';
import 'event/event_screen.dart';
import 'home/home_screen.dart';
import 'notification/notification_screen.dart';
import 'post/create_post_screen.dart';
import 'profile/profile_screen.dart';

class MainShell extends StatefulWidget {
  const MainShell({super.key});
  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _tab = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<CommunityProvider>().fetch();
      context.read<PostProvider>().fetch();
      context.read<EventProvider>().fetch();
      context.read<NotificationProvider>().fetch();
      context.read<ProfileProvider>().fetch();
    });
  }

  void _go(int i) {
    setState(() => _tab = i);
    // data tab yang dibuka di-refresh biar selalu terbaru
    if (i == 2) context.read<EventProvider>().fetch();
    if (i == 3) context.read<NotificationProvider>().fetch();
    if (i == 4) context.read<ProfileProvider>().fetch();
  }

  @override
  Widget build(BuildContext context) {
    final unread = context.watch<NotificationProvider>().unreadCount;

    return Scaffold(
      body: IndexedStack(
        index: _tab,
        children: const [
          HomeScreen(),
          CommunityScreen(),
          EventScreen(),
          NotificationScreen(),
          ProfileScreen(),
        ],
      ),
      bottomNavigationBar: Material(
        color: AppColors.bg,
        elevation: 8,
        shadowColor: AppColors.shadow,
        child: SafeArea(
          child: SizedBox(
            height: 68,
            child: Row(
              children: [
                _NavItem(
                  icon: Icons.home_outlined,
                  activeIcon: Icons.home,
                  label: 'Beranda',
                  selected: _tab == 0,
                  onTap: () => _go(0),
                ),
                _NavItem(
                  icon: Icons.groups_outlined,
                  activeIcon: Icons.groups,
                  label: 'Komunitas',
                  selected: _tab == 1,
                  onTap: () => _go(1),
                ),
                // bukan tab: membuka layar buat postingan
                _NavItem(
                  icon: Icons.add_circle_outline,
                  activeIcon: Icons.add_circle,
                  label: 'Buat',
                  selected: false,
                  iconSize: 32,
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const CreatePostScreen()),
                  ),
                ),
                _NavItem(
                  icon: Icons.calendar_today_outlined,
                  activeIcon: Icons.calendar_month,
                  label: 'Event',
                  selected: _tab == 2,
                  onTap: () => _go(2),
                ),
                _NavItem(
                  icon: Icons.notifications_none,
                  activeIcon: Icons.notifications,
                  label: 'Notifikasi',
                  selected: _tab == 3,
                  badge: unread,
                  onTap: () => _go(3),
                ),
                _NavItem(
                  icon: Icons.account_circle_outlined,
                  activeIcon: Icons.account_circle,
                  label: 'Profil',
                  selected: _tab == 4,
                  onTap: () => _go(4),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon, activeIcon;
  final String label;
  final bool selected;
  final VoidCallback onTap;
  final int badge;
  final double iconSize;

  const _NavItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
    required this.selected,
    required this.onTap,
    this.badge = 0,
    this.iconSize = 26,
  });

  @override
  Widget build(BuildContext context) {
    final color = selected ? AppColors.accent : AppColors.ink;

    return Expanded(
      child: InkWell(
        onTap: onTap,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                Icon(
                  selected ? activeIcon : icon,
                  size: iconSize,
                  color: color,
                ),
                if (badge > 0)
                  Positioned(
                    right: -8,
                    top: -4,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 5,
                        vertical: 1,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.red,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        badge > 99 ? '99+' : '$badge',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 11,
                fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
