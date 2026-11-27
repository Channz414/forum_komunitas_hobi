import 'package:flutter/material.dart';

import '../core/config.dart';
import '../models/post.dart';

class UserProfileProvider extends ChangeNotifier {
  final String userId;
  UserProfileProvider(this.userId);

  String username = '';
  String? avatarUrl, bio;
  DateTime? joinedAt;
  int friendCount = 0;
  List<String> communities = [];
  List<Post> posts = [];
  bool loading = false;
  String? error;

  Future<void> fetch() async {
    loading = true;
    error = null;
    notifyListeners();
    try {
      final profile = await supabase
          .from('profiles')
          .select()
          .eq('id', userId)
          .maybeSingle();
      if (profile == null) throw 'Pengguna tidak ditemukan';
      username = profile['username'];
      avatarUrl = profile['avatar_url'];
      bio = profile['bio'];
      joinedAt = DateTime.parse(profile['created_at']).toLocal();

      // hanya angka: daftar teman orang lain tidak bisa dibaca (lihat RLS)
      final count = await supabase.rpc(
        'friend_count',
        params: {'target': userId},
      );
      friendCount = (count as num).toInt();

      final mem = await supabase
          .from('community_members')
          .select('communities(name)')
          .eq('user_id', userId);
      communities = mem
          .map<String>((m) => m['communities']['name'] as String)
          .toList();

      final data = await supabase
          .from('posts_feed')
          .select()
          .eq('user_id', userId)
          .order('created_at', ascending: false);
      posts = data.map<Post>((m) => Post.fromMap(m)).toList();
    } catch (e) {
      error = e.toString();
    }
    loading = false;
    notifyListeners();
  }
}
