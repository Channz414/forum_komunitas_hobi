import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/friendship.dart';
import '../../providers/friend_provider.dart';
import '../../providers/profile_provider.dart';
import '../../widgets/app_card.dart';
import '../../widgets/app_chip.dart';
import '../../widgets/friend_button.dart';
import '../../widgets/user_avatar.dart';
import '../profile/user_profile_screen.dart';

enum _Tab { friends, incoming, outgoing }

class FriendsScreen extends StatefulWidget {
  const FriendsScreen({super.key});
  @override
  State<FriendsScreen> createState() => _FriendsScreenState();
}

class _FriendsScreenState extends State<FriendsScreen> {
  _Tab _tab = _Tab.friends;
  final _search = TextEditingController();
  Timer? _debounce;
  List<UserLite> _results = [];
  bool _searching = false;
  String _query = '';

  @override
  void dispose() {
    _debounce?.cancel();
    _search.dispose();
    super.dispose();
  }

  // pencarian ditunda 400 ms setelah user berhenti mengetik,
  // supaya tidak mengirim request di setiap huruf
  void _onChanged(String v) {
    _debounce?.cancel();
    final q = v.trim();
    setState(() {
      _query = q;
      if (q.isEmpty) {
        _results = [];
        _searching = false;
      }
    });
    if (q.isEmpty) return;
    _debounce = Timer(const Duration(milliseconds: 400), () async {
      if (!mounted) return;
      setState(() => _searching = true);
      try {
        final r = await context.read<FriendProvider>().searchUsers(q);
        if (!mounted || _query != q) return; // abaikan hasil yang sudah usang
        setState(() {
          _results = r;
          _searching = false;
        });
      } catch (_) {
        if (mounted) setState(() => _searching = false);
      }
    });
  }

  Widget _row(
    BuildContext context, {
    required String id,
    required String username,
    String? avatar,
  }) {
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => UserProfileScreen(userId: id, username: username),
        ),
      ),
      child: AppCard(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            UserAvatar(name: username, imageUrl: avatar, radius: 22),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                username,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
            const SizedBox(width: 8),
            FriendButton(userId: id, username: username, compact: true),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final fp = context.watch<FriendProvider>();
    final profile = context.watch<ProfileProvider>();
    final name = profile.username.isEmpty ? 'U' : profile.username;

    final List<Widget> rows;
    final String emptyText;
    if (_query.isNotEmpty) {
      rows = [
        for (final u in _results)
          _row(context, id: u.id, username: u.username, avatar: u.avatarUrl),
      ];
      emptyText = 'Pengguna tidak ditemukan';
    } else {
      final list = switch (_tab) {
        _Tab.friends => fp.friends,
        _Tab.incoming => fp.incoming,
        _Tab.outgoing => fp.outgoing,
      };
      rows = [
        for (final f in list)
          _row(
            context,
            id: f.otherId,
            username: f.otherUsername,
            avatar: f.otherAvatar,
          ),
      ];
      emptyText = switch (_tab) {
        _Tab.friends =>
          'Belum punya teman.\nCari pengguna lewat kolom pencarian di atas.',
        _Tab.incoming => 'Tidak ada permintaan pertemanan masuk',
        _Tab.outgoing => 'Tidak ada permintaan yang sedang menunggu',
      };
    }

    return SafeArea(
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
            child: Row(
              children: [
                const Expanded(
                  child: Text(
                    'Teman',
                    style: TextStyle(fontSize: 28, fontWeight: FontWeight.w800),
                  ),
                ),
                UserAvatar(name: name, imageUrl: profile.avatarUrl),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
            child: TextField(
              controller: _search,
              onChanged: _onChanged,
              decoration: InputDecoration(
                hintText: 'Cari pengguna',
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
          if (_query.isEmpty)
            SizedBox(
              height: 48,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                children: [
                  AppChip(
                    label: 'Teman (${fp.friends.length})',
                    selected: _tab == _Tab.friends,
                    onTap: () => setState(() => _tab = _Tab.friends),
                  ),
                  AppChip(
                    label: 'Permintaan (${fp.incoming.length})',
                    selected: _tab == _Tab.incoming,
                    onTap: () => setState(() => _tab = _Tab.incoming),
                  ),
                  AppChip(
                    label: 'Terkirim (${fp.outgoing.length})',
                    selected: _tab == _Tab.outgoing,
                    onTap: () => setState(() => _tab = _Tab.outgoing),
                  ),
                ],
              ),
            ),
          Expanded(
            child: RefreshIndicator(
              onRefresh: fp.fetch,
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                children: [
                  if (_searching ||
                      (_query.isEmpty && fp.loading && fp.all.isEmpty))
                    const Padding(
                      padding: EdgeInsets.all(40),
                      child: Center(child: CircularProgressIndicator()),
                    )
                  else if (_query.isEmpty && fp.error != null)
                    Padding(
                      padding: const EdgeInsets.all(24),
                      child: Text('Gagal memuat: ${fp.error}'),
                    )
                  else if (rows.isEmpty)
                    Padding(
                      padding: const EdgeInsets.all(40),
                      child: Center(
                        child: Text(emptyText, textAlign: TextAlign.center),
                      ),
                    )
                  else
                    ...rows,
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
