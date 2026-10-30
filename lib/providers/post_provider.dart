import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../core/config.dart';
import '../models/post.dart';

class PostProvider extends ChangeNotifier {
  List<Post> posts = [];
  bool loading = false;
  String? error;
  String? communityFilter; // null = Semua
  String search = '';

  Future<void> fetch() async {
    loading = true;
    error = null;
    notifyListeners();
    try {
      var q = supabase.from('posts_feed').select();
      if (communityFilter != null) q = q.eq('community_id', communityFilter!);
      if (search.isNotEmpty) q = q.ilike('content', '%$search%');
      final data = await q.order('created_at', ascending: false).limit(50);
      posts = data.map<Post>((m) => Post.fromMap(m)).toList();
    } catch (e) {
      error = e.toString();
    }
    loading = false;
    notifyListeners();
  }

  void setFilter(String? id) {
    communityFilter = id;
    fetch();
  }

  void setSearch(String text) {
    search = text.trim();
    fetch();
  }

  // optimistic update: UI langsung berubah, rollback kalau request gagal
  Future<void> toggleLike(Post p) async {
    final uid = supabase.auth.currentUser!.id;
    final wasLiked = p.likedByMe;
    p.likedByMe = !wasLiked;
    p.likeCount += wasLiked ? -1 : 1;
    notifyListeners();
    try {
      if (wasLiked) {
        await supabase.from('likes').delete().match({
          'post_id': p.id,
          'user_id': uid,
        });
      } else {
        await supabase.from('likes').insert({'post_id': p.id, 'user_id': uid});
      }
    } catch (_) {
      p.likedByMe = wasLiked;
      p.likeCount += wasLiked ? 1 : -1;
      notifyListeners();
    }
  }

  Future<void> createPost({
    required String communityId,
    required String content,
    XFile? image,
  }) async {
    final uid = supabase.auth.currentUser!.id;
    String? url;
    if (image != null) {
      final ext = image.name.split('.').last;
      final path = '$uid/${DateTime.now().millisecondsSinceEpoch}.$ext';
      await supabase.storage
          .from('post-images')
          .uploadBinary(
            path,
            await image.readAsBytes(),
            fileOptions: FileOptions(contentType: image.mimeType),
          );
      url = supabase.storage.from('post-images').getPublicUrl(path);
    }
    await supabase.from('posts').insert({
      'user_id': uid,
      'community_id': communityId,
      'content': content,
      'image_url': url,
    });
    await fetch();
  }
}
