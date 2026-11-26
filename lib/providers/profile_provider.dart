import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../core/config.dart';
import '../models/post.dart';

class ProfileProvider extends ChangeNotifier {
  String username = '';
  String? avatarUrl, bio;
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
          .select('username, avatar_url, bio')
          .eq('id', user.id)
          .maybeSingle();
      username =
          (profile?['username'] as String?) ??
          (user.userMetadata?['username'] as String?) ??
          '';
      avatarUrl = profile?['avatar_url'] as String?;
      bio = profile?['bio'] as String?;
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

  Future<void> updateBio(String text) async {
    final uid = supabase.auth.currentUser!.id;
    final value = text.trim().isEmpty ? null : text.trim();
    await supabase.from('profiles').update({'bio': value}).eq('id', uid);
    bio = value;
    notifyListeners();
  }

  Future<void> setAvatar(XFile image) async {
    final uid = supabase.auth.currentUser!.id;
    final ext = image.name.split('.').last;
    // folder pertama harus uid (dicek oleh policy storage)
    final path = '$uid/avatar_${DateTime.now().millisecondsSinceEpoch}.$ext';
    await supabase.storage
        .from('avatars')
        .uploadBinary(
          path,
          await image.readAsBytes(),
          fileOptions: FileOptions(contentType: image.mimeType),
        );
    final url = supabase.storage.from('avatars').getPublicUrl(path);
    await supabase.from('profiles').update({'avatar_url': url}).eq('id', uid);
    avatarUrl = url;
    notifyListeners();
  }

  Future<void> removeAvatar() async {
    final uid = supabase.auth.currentUser!.id;
    await supabase.from('profiles').update({'avatar_url': null}).eq('id', uid);
    avatarUrl = null;
    notifyListeners();
  }
}
