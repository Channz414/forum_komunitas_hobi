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

  void bumpCommentCount(Post p, int delta) {
    p.commentCount += delta;
    notifyListeners();
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

  Future<void> updatePost(Post p, String content) async {
    final now = DateTime.now();
    final res = await supabase
        .from('posts')
        .update({
          'content': content,
          'edited_at': now.toUtc().toIso8601String(),
        })
        .eq('id', p.id)
        .select('id');
    if (res.isEmpty) throw 'Tidak punya izin untuk mengedit postingan ini';
    p.content = content;
    p.editedAt = now;

    for (final x in posts.where((x) => x.id == p.id)) {
      x.content = content;
      x.editedAt = now;
    }
    notifyListeners();
  }

  Future<void> deletePost(Post p) async {
    final res = await supabase
        .from('posts')
        .delete()
        .eq('id', p.id)
        .select('id');
    if (res.isEmpty) throw 'Tidak punya izin untuk menghapus postingan ini';
    posts.removeWhere((x) => x.id == p.id);
    notifyListeners();
  }

  Future<void> reportPost(Post p, String reason) async {
    await supabase.from('reports').insert({
      'reporter_id': supabase.auth.currentUser!.id,
      'post_id': p.id,
      'reason': reason,
    });
  }
}
