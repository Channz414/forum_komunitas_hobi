import 'package:flutter/material.dart';

import '../core/config.dart';
import '../models/event.dart';

enum EventFilter { all, upcoming, joined, past }

class EventProvider extends ChangeNotifier {
  List<Event> events = [];
  bool loading = false;
  String? error;
  EventFilter filter = EventFilter.all;

  // event mendatang diurutkan dari yang terdekat, event lewat dari yang terbaru
  List<Event> get visible {
    final upcoming = events.where((e) => !e.isPast).toList()
      ..sort((a, b) => a.startsAt.compareTo(b.startsAt));
    final past = events.where((e) => e.isPast).toList()
      ..sort((a, b) => b.startsAt.compareTo(a.startsAt));
    switch (filter) {
      case EventFilter.all:
        return [...upcoming, ...past];
      case EventFilter.upcoming:
        return upcoming;
      case EventFilter.joined:
        return [...upcoming, ...past].where((e) => e.joinedByMe).toList();
      case EventFilter.past:
        return past;
    }
  }

  void setFilter(EventFilter f) {
    filter = f;
    notifyListeners();
  }

  Future<void> fetch() async {
    loading = true;
    error = null;
    notifyListeners();
    try {
      final data = await supabase
          .from('events_info')
          .select()
          .order('starts_at', ascending: true);
      events = data.map<Event>((m) => Event.fromMap(m)).toList();
    } catch (e) {
      error = e.toString();
    }
    loading = false;
    notifyListeners();
  }

  // optimistic update, rollback kalau gagal (pola sama dengan toggleLike)
  Future<void> toggleAttend(Event e) async {
    if (e.isPast) return;
    final uid = supabase.auth.currentUser!.id;
    final was = e.joinedByMe;
    e.joinedByMe = !was;
    e.attendeeCount += was ? -1 : 1;
    notifyListeners();
    try {
      if (was) {
        await supabase.from('event_attendees').delete().match({
          'event_id': e.id,
          'user_id': uid,
        });
      } else {
        await supabase.from('event_attendees').insert({
          'event_id': e.id,
          'user_id': uid,
        });
      }
    } catch (_) {
      e.joinedByMe = was;
      e.attendeeCount += was ? 1 : -1;
      notifyListeners();
    }
  }

  Future<void> create({
    required String communityId,
    required String title,
    String? description,
    String? location,
    required DateTime startsAt,
  }) async {
    final uid = supabase.auth.currentUser!.id;
    final row = await supabase
        .from('events')
        .insert({
          'community_id': communityId,
          'created_by': uid,
          'title': title,
          'description': (description == null || description.isEmpty)
              ? null
              : description,
          'location': (location == null || location.isEmpty) ? null : location,
          'starts_at': startsAt.toUtc().toIso8601String(),
        })
        .select('id')
        .single();
    // pembuat otomatis ikut, sama seperti pembuat komunitas otomatis jadi anggota
    await supabase.from('event_attendees').insert({
      'event_id': row['id'],
      'user_id': uid,
    });
    await fetch();
  }
}
