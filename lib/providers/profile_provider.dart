import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/config.dart';
import '../../models/post.dart';

class ProfileProvider extends ChangeNotifier {
  String username = '';
  List<Post> posts = [];
  bool loading = false;
  String? error;

  String get email => supabase.auth.currentUser?.email ?? '';

  Future<void> fetch() async {
    final user = supabase.auth.currentUser;
    if (user == null) return;
    loading = true;
    error = null;
    notifyListeners();
    try {
      final profile = await supabase
          .from('profiles')
          .select('username')
          .eq('id', user.id)
          .maybeSingle();
      username =
          (profile?['username'] as String?) ??
          (user.userMetadata?['username'] as String?) ??
          '';
      final data = await supabase
          .from('posts_feed')
          .select()
          .eq('user_id', user.id)
          .order('created_at', ascending: false);
      posts = data.map<Post>((m) => Post.fromMap(m)).toList();
    } catch (e) {
      error = e.toString();
    }
    loading = false;
    notifyListeners();
  }

  Future<void> updateUsername(String name) async {
    final uid = supabase.auth.currentUser!.id;
    await supabase.from('profiles').update({'username': name}).eq('id', uid);
    // samakan dengan metadata auth supaya avatar di Home ikut berubah
    await supabase.auth.updateUser(UserAttributes(data: {'username': name}));
    username = name;
    notifyListeners();
  }
}
