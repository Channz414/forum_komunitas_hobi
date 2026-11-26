import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/config.dart';
import '../../core/theme.dart';
import '../../models/community_member.dart';
import '../../providers/community_detail_provider.dart';
import '../../widgets/app_card.dart';
import '../../widgets/user_avatar.dart';
import '../profile/user_profile_screen.dart';

class MembersScreen extends StatefulWidget {
  const MembersScreen({super.key});
  @override
  State<MembersScreen> createState() => _MembersScreenState();
}

class _MembersScreenState extends State<MembersScreen> {
  late Future<List<CommunityMember>> _future;

  @override
  void initState() {
    super.initState();
    _future = context.read<CommunityDetailProvider>().fetchMembers();
  }

  Future<void> _reload() async {
    final f = context.read<CommunityDetailProvider>().fetchMembers();
    setState(() => _future = f);
    try {
      await f;
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final myId = supabase.auth.currentUser?.id;

    return Scaffold(
      appBar: AppBar(title: const Text('Anggota')),
      body: FutureBuilder<List<CommunityMember>>(
        future: _future,
        builder: (context, snap) {
          if (snap.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snap.hasError) {
            return Center(child: Text('Gagal memuat: ${snap.error}'));
          }
          final members = snap.data ?? [];
          return RefreshIndicator(
            onRefresh: _reload,
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
              children: [
                Padding(
                  padding: const EdgeInsets.only(left: 4, bottom: 12),
                  child: Text(
                    '${members.length} anggota',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                for (final m in members)
                  AppCard(
                    margin: const EdgeInsets.only(bottom: 10),
                    padding: EdgeInsets.zero,
                    child: ListTile(
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => UserProfileScreen(
                            userId: m.userId,
                            username: m.username,
                          ),
                        ),
                      ),
                      leading: UserAvatar(
                        name: m.username,
                        imageUrl: m.avatarUrl,
                        radius: 22,
                      ),
                      title: Text(
                        m.userId == myId ? '${m.username} (Anda)' : m.username,
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                      trailing: m.isOwner
                          ? Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.teal,
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: const Text(
                                'Pemilik',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.tealText,
                                ),
                              ),
                            )
                          : null,
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }
}
