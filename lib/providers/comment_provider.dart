import 'package:flutter/material.dart';

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
          .select('*, profiles(username)')
          .eq('post_id', postId)
          .order('created_at', ascending: true);
      comments = data.map<Comment>((m) => Comment.fromMap(m)).toList();
    } catch (e) {
      error = e.toString();
    }
    loading = false;
    notifyListeners();
  }

  Future<void> add(String content) async {
    await supabase.from('comments').insert({
      'post_id': postId,
      'user_id': supabase.auth.currentUser!.id,
      'content': content,
    });
    await fetch();
  }

  Future<void> remove(Comment c) async {
    await supabase.from('comments').delete().eq('id', c.id);
    comments.remove(c);
    notifyListeners();
  }
}
