import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../core/config.dart';
import '../models/community.dart';
import '../models/community_member.dart';
import '../models/event.dart';
import '../models/post.dart';

enum CommunityTab { posts, events }

class CommunityDetailProvider extends ChangeNotifier {
  final String communityId;
  CommunityDetailProvider(this.communityId);

  Community? info;
  List<Post> posts = [];
  List<Event> events = [];
  CommunityTab tab = CommunityTab.posts;
  bool loading = false;
  bool gone = false; // komunitas sudah dihapus
  String? error;

  // event mendatang (terdekat dulu), lalu event yang sudah lewat (terbaru dulu)
  List<Event> get sortedEvents {
    final upcoming = events.where((e) => !e.isPast).toList()
      ..sort((a, b) => a.startsAt.compareTo(b.startsAt));
    final past = events.where((e) => e.isPast).toList()
      ..sort((a, b) => b.startsAt.compareTo(a.startsAt));
    return [...upcoming, ...past];
  }

  void setTab(CommunityTab t) {
    tab = t;
    notifyListeners();
  }

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
        events = [];
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
        // event komunitas terlihat oleh semua orang
        final ev = await supabase
            .from('events_feed')
            .select()
            .eq('community_id', communityId);
        events = ev.map<Event>((m) => Event.fromMap(m)).toList();
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

  // pemilik di urutan pertama, sisanya urut abjad
  Future<List<CommunityMember>> fetchMembers() async {
    final data = await supabase
        .from('community_members')
        .select('user_id, profiles(username, avatar_url)')
        .eq('community_id', communityId);
    final ownerId = info?.ownerId;
    final list = data
        .map<CommunityMember>(
          (m) => CommunityMember(
            userId: m['user_id'],
            username: m['profiles']['username'],
            avatarUrl: m['profiles']['avatar_url'],
            isOwner: m['user_id'] == ownerId,
          ),
        )
        .toList();
    list.sort((a, b) {
      if (a.isOwner != b.isOwner) return a.isOwner ? -1 : 1;
      return a.username.toLowerCase().compareTo(b.username.toLowerCase());
    });
    return list;
  }

  Future<void> report(String reason) async {
    await supabase.from('community_reports').insert({
      'reporter_id': supabase.auth.currentUser!.id,
      'community_id': communityId,
      'reason': reason,
    });
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
