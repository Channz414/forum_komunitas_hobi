import 'package:flutter/material.dart';

import '../core/config.dart';
import '../models/friendship.dart';

class FriendProvider extends ChangeNotifier {
  List<Friendship> all = []; // semua relasi yang melibatkan saya
  bool loading = false;
  String? error;

  List<Friendship> get friends => all.where((f) => f.isAccepted).toList();
  // permintaan masuk (orang lain yang mengajak saya)
  List<Friendship> get incoming =>
      all.where((f) => !f.isAccepted && !f.iAmRequester).toList();
  // permintaan keluar (saya yang mengajak)
  List<Friendship> get outgoing =>
      all.where((f) => !f.isAccepted && f.iAmRequester).toList();

  // relasi saya dengan user tertentu (null = belum ada relasi)
  Friendship? relationWith(String userId) {
    for (final f in all) {
      if (f.otherId == userId) return f;
    }
    return null;
  }

  Future<void> fetch() async {
    final uid = supabase.auth.currentUser?.id;
    if (uid == null) return;
    loading = true;
    error = null;
    notifyListeners();
    try {
      // dua kolom sama-sama mengarah ke profiles, jadi nama foreign key
      // dipakai sebagai petunjuk (hint) supaya Supabase tahu mana yang dimaksud
      final data = await supabase
          .from('friendships')
          .select(
            'id, status, requester_id, addressee_id, '
            'requester:profiles!friendships_requester_id_fkey(username, avatar_url), '
            'addressee:profiles!friendships_addressee_id_fkey(username, avatar_url)',
          )
          .or('requester_id.eq.$uid,addressee_id.eq.$uid')
          .order('created_at', ascending: false);
      all = data.map<Friendship>((m) => Friendship.fromMap(m, uid)).toList();
    } catch (e) {
      error = e.toString();
    }
    loading = false;
    notifyListeners();
  }

  Future<List<UserLite>> searchUsers(String q) async {
    final uid = supabase.auth.currentUser!.id;
    final data = await supabase
        .from('profiles')
        .select('id, username, avatar_url')
        .ilike('username', '%$q%')
        .neq('id', uid)
        .limit(20);
    return data.map<UserLite>((m) => UserLite.fromMap(m)).toList();
  }

  Future<void> sendRequest(String userId) async {
    final uid = supabase.auth.currentUser!.id;
    await supabase.from('friendships').insert({
      'requester_id': uid,
      'addressee_id': userId,
    });
    await fetch();
  }

  Future<void> accept(Friendship f) async {
    // .select('id') + cek kosong: RLS yang menolak tidak melempar error
    final res = await supabase
        .from('friendships')
        .update({'status': 'accepted'})
        .eq('id', f.id)
        .select('id');
    if (res.isEmpty) throw 'Permintaan ini tidak bisa diterima';
    await fetch();
  }

  // dipakai untuk batalkan permintaan, tolak permintaan, dan hapus teman
  Future<void> remove(Friendship f) async {
    final res = await supabase
        .from('friendships')
        .delete()
        .eq('id', f.id)
        .select('id');
    if (res.isEmpty) throw 'Tidak bisa menghapus relasi ini';
    all.removeWhere((x) => x.id == f.id);
    notifyListeners();
  }
}
