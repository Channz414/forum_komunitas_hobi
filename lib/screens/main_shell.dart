import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/config.dart';
import '../core/theme.dart';
import '../providers/community_provider.dart';
import '../providers/post_provider.dart';
import 'home/home_screen.dart';
import 'post/create_post_screen.dart';

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
      context.read<CommunityProvider>().fetchJoined();
      context.read<PostProvider>().fetch();
    });
  }

  Widget _item(IconData icon, int index) => IconButton(
    icon: Icon(
      icon,
      size: 30,
      color: _tab == index ? AppColors.accent : AppColors.ink,
    ),
    onPressed: () => setState(() => _tab = index),
  );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _tab,
        children: [
          const HomeScreen(),
          const _Todo('Komunitas'),
          const _Todo('Kalender Event'),
          const _Todo('Notifikasi'),
          Center(
            child: TextButton(
              onPressed: () => supabase.auth.signOut(),
              child: const Text('profil'),
            ),
          ),
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
              _item(Icons.notifications_none, 3),
              _item(Icons.account_circle_outlined, 4),
            ],
          ),
        ),
      ),
    );
  }
}

class _Todo extends StatelessWidget {
  final String title;
  const _Todo(this.title);
  @override
  Widget build(BuildContext context) => Center(child: Text('$title'));
}
