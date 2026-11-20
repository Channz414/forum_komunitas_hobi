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

  Widget _item(IconData icon, int index) => IconButton(
    icon: Icon(
      icon,
      size: 30,
      color: _tab == index ? AppColors.accent : AppColors.ink,
    ),
    onPressed: () => _go(index),
  );

  Widget _bell() {
    final unread = context.watch<NotificationProvider>().unreadCount;
    return Stack(
      clipBehavior: Clip.none,
      children: [
        _item(Icons.notifications_none, 3),
        if (unread > 0)
          Positioned(
            right: 4,
            top: 4,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
              decoration: BoxDecoration(
                color: Colors.red,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                unread > 99 ? '99+' : '$unread',
                style: const TextStyle(color: Colors.white, fontSize: 10),
              ),
            ),
          ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
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
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          color: AppColors.bg,
          boxShadow: [BoxShadow(color: AppColors.shadow, blurRadius: 8)],
        ),
        child: SafeArea(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _item(Icons.home_outlined, 0),
              _item(Icons.groups_outlined, 1),
              IconButton(
                icon: const Icon(
                  Icons.add_circle_outline,
                  size: 34,
                  color: AppColors.ink,
                ),
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const CreatePostScreen()),
                ),
              ),
              _item(Icons.calendar_today_outlined, 2),
              _bell(),
              _item(Icons.account_circle_outlined, 4),
            ],
          ),
        ),
      ),
    );
  }
}
