import 'package:flutter/material.dart';

import '../core/config.dart';
import '../models/app_notification.dart';

class NotificationProvider extends ChangeNotifier {
  List<AppNotification> items = [];
  bool loading = false;
  String? error;
  bool unreadOnly = false;

  int get unreadCount => items.where((n) => !n.isRead).length;

  List<AppNotification> get visible =>
      unreadOnly ? items.where((n) => !n.isRead).toList() : items;

  void setUnreadOnly(bool v) {
    unreadOnly = v;
    notifyListeners();
  }

  Future<void> fetch() async {
    final uid = supabase.auth.currentUser?.id;
    if (uid == null) return;
    loading = true;
    error = null;
    notifyListeners();
    try {
      final data = await supabase
          .from('notifications')
          .select()
          .eq('user_id', uid)
          .order('created_at', ascending: false)
          .limit(100);
      items = data
          .map<AppNotification>((m) => AppNotification.fromMap(m))
          .toList();
    } catch (e) {
      error = e.toString();
    }
    loading = false;
    notifyListeners();
  }

  Future<void> markRead(AppNotification n) async {
    if (n.isRead) return;
    n.isRead = true;
    notifyListeners();
    try {
      await supabase.from('notifications').update({'is_read': true}).eq('id', n.id);
    } catch (_) {
      n.isRead = false;
      notifyListeners();
    }
  }

  Future<void> markAllRead() async {
    final uid = supabase.auth.currentUser!.id;
    final changed = items.where((n) => !n.isRead).toList();
    if (changed.isEmpty) return;
    for (final n in changed) {
      n.isRead = true;
    }
    notifyListeners();
    try {
      await supabase
          .from('notifications')
          .update({'is_read': true})
          .eq('user_id', uid)
          .eq('is_read', false);
    } catch (_) {
      for (final n in changed) {
        n.isRead = false;
      }
      notifyListeners();
    }
  }
}
