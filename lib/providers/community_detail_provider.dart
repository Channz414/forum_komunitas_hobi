import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../core/config.dart';
import '../models/community.dart';
import '../models/post.dart';

class CommunityDetailProvider extends ChangeNotifier {
  final String communityId;
  CommunityDetailProvider(this.communityId);

  Community? info;
  List<Post> posts = [];
  bool loading = false;
  bool gone = false; // komunitas sudah dihapus
  String? error;

  Future<void> fetch() async {
    loading = true;
    error = null;
    notifyListeners();
    try {
      final row = await supabase
          .from('communities_info')
          .select()
          .eq('id', communityId)
          .maybeSingle();
      if (row == null) {
        gone = true;
        info = null;
        posts = [];
      } else {
        gone = false;
        info = Community.fromMap(row);
        if (info!.joined) {
          final data = await supabase
              .from('posts_feed')
              .select()
              .eq('community_id', communityId)
              .order('created_at', ascending: false)
              .limit(50);
          posts = data.map<Post>((m) => Post.fromMap(m)).toList();
        } else {
          posts = []; // postingan hanya terlihat oleh anggota
        }
      }
    } catch (e) {
      error = e.toString();
    }
    loading = false;
    notifyListeners();
  }

  Future<void> toggleJoin() async {
    final c = info;
    if (c == null || (c.isOwner && c.joined)) return;
    final uid = supabase.auth.currentUser!.id;
    if (c.joined) {
      await supabase.from('community_members').delete().match({
        'community_id': communityId,
        'user_id': uid,
      });
    } else {
      await supabase.from('community_members').insert({
        'community_id': communityId,
        'user_id': uid,
      });
    }
    await fetch();
  }

  Future<void> update({
    required String name,
    String? description,
    XFile? image,
  }) async {
    String? url;
    if (image != null) {
      final ext = image.name.split('.').last;
      final path =
          'communities/$communityId/${DateTime.now().millisecondsSinceEpoch}.$ext';
      await supabase.storage
          .from('post-images')
          .uploadBinary(
            path,
            await image.readAsBytes(),
            fileOptions: FileOptions(contentType: image.mimeType),
          );
      url = supabase.storage.from('post-images').getPublicUrl(path);
    }
    // .select('id') + cek kosong: RLS yang menolak tidak melempar error
    final res = await supabase
        .from('communities')
        .update({
          'name': name,
          'description': (description == null || description.isEmpty)
              ? null
              : description,
          if (url != null) 'image_url': url,
        })
        .eq('id', communityId)
        .select('id');
    if (res.isEmpty) throw 'Hanya pemilik yang boleh mengedit komunitas';
    await fetch();
  }

  Future<void> delete() async {
    final res = await supabase
        .from('communities')
        .delete()
        .eq('id', communityId)
        .select('id');
    if (res.isEmpty) throw 'Hanya pemilik yang boleh menghapus komunitas';
  }
}
