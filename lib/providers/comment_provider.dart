import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../core/config.dart';
import '../models/comment.dart';

class CommentProvider extends ChangeNotifier {
  final String postId;
  CommentProvider(this.postId);

  List<Comment> comments = [];
  bool loading = false;
  String? error;

  Future<void> fetch() async {
    loading = true;
    error = null;
    notifyListeners();
    try {
      final data = await supabase
          .from('comments')
          .select('*, profiles(username, avatar_url)')
          .eq('post_id', postId)
          .order('created_at', ascending: true);
      comments = data.map<Comment>((m) => Comment.fromMap(m)).toList();
    } catch (e) {
      error = e.toString();
    }
    loading = false;
    notifyListeners();
  }

  String _mime(String ext) {
    switch (ext) {
      case 'png':
        return 'image/png';
      case 'gif':
        return 'image/gif';
      case 'webp':
        return 'image/webp';
      default:
        return 'image/jpeg';
    }
  }

  Future<void> add(String content, {XFile? image}) async {
    final uid = supabase.auth.currentUser!.id;
    String? url;
    if (image != null) {
      final ext = image.name.contains('.')
          ? image.name.split('.').last.toLowerCase()
          : 'jpg';
      final path =
          '$uid/comments/${DateTime.now().millisecondsSinceEpoch}.$ext';
      await supabase.storage
          .from('post-images')
          .uploadBinary(
            path,
            await image.readAsBytes(),
            fileOptions: FileOptions(contentType: _mime(ext)),
          );
      url = supabase.storage.from('post-images').getPublicUrl(path);
    }
    await supabase.from('comments').insert({
      'post_id': postId,
      'user_id': uid,
      'content': content, // boleh kosong kalau komentarnya hanya gambar
      'image_url': url,
    });
    await fetch();
  }

  Future<void> remove(Comment c) async {
    await supabase.from('comments').delete().eq('id', c.id);
    comments.remove(c);
    notifyListeners();
  }
}
