import 'package:flutter/material.dart';

import '../core/config.dart';
import '../models/community.dart';

class CommunityProvider extends ChangeNotifier {
  List<Community> all = [];
  bool loading = false;

  // dipakai Home (chip) dan Buat Postingan (dropdown)
  List<Community> get joined => all.where((c) => c.joined).toList();

  Future<void> fetch() async {
    loading = true;
    notifyListeners();
    try {
      final data = await supabase
          .from('communities_info')
          .select()
          .order('member_count', ascending: false);
      all = data.map<Community>((m) => Community.fromMap(m)).toList();
    } catch (_) {}
    loading = false;
    notifyListeners();
  }

  // optimistic update, sama kayak toggleLike
  Future<void> toggleJoin(Community c) async {
    final uid = supabase.auth.currentUser!.id;
    final was = c.joined;
    c.joined = !was;
    c.memberCount += was ? -1 : 1;
    notifyListeners();
    try {
      if (was) {
        await supabase.from('community_members').delete().match({
          'community_id': c.id,
          'user_id': uid,
        });
      } else {
        await supabase.from('community_members').insert({
          'community_id': c.id,
          'user_id': uid,
        });
      }
    } catch (_) {
      c.joined = was;
      c.memberCount += was ? 1 : -1;
      notifyListeners();
    }
  }

  Future<void> create(String name, String description) async {
    final uid = supabase.auth.currentUser!.id;
    final row = await supabase
        .from('communities')
        .insert({
          'name': name,
          'description': description.isEmpty ? null : description,
          'created_by': uid,
        })
        .select('id')
        .single();
    // pembuat otomatis jadi anggota
    await supabase.from('community_members').insert({
      'community_id': row['id'],
      'user_id': uid,
    });
    await fetch();
  }
}
