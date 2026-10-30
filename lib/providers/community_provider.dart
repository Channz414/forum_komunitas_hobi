import 'package:flutter/material.dart';

import '../core/config.dart';
import '../models/community.dart';

class CommunityProvider extends ChangeNotifier {
  List<Community> joined = [];

  Future<void> fetchJoined() async {
    final uid = supabase.auth.currentUser!.id;
    final data = await supabase
        .from('community_members')
        .select('communities(id, name, description)')
        .eq('user_id', uid);
    joined = data
        .map<Community>((m) => Community.fromMap(m['communities']))
        .toList();
    notifyListeners();
  }
}
