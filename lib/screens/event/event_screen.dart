import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/config.dart';
import '../../providers/event_provider.dart';
import '../../widgets/app_chip.dart';
import '../../widgets/event_card.dart';
import '../../widgets/user_avatar.dart';
import 'create_event_screen.dart';

class EventScreen extends StatelessWidget {
  const EventScreen({super.key});

  static const _filters = {
    EventFilter.all: 'Semua',
    EventFilter.upcoming: 'Mendatang',
    EventFilter.joined: 'Diikuti',
    EventFilter.past: 'Selesai',
  };

  @override
  Widget build(BuildContext context) {
    final ep = context.watch<EventProvider>();
    final events = ep.visible;
    final name =
        (supabase.auth.currentUser?.userMetadata?['username'] as String?) ??
        'U';

    return SafeArea(
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
            child: Row(
              children: [
                const Expanded(
                  child: Text(
                    'Kalender Event',
                    style: TextStyle(fontSize: 28, fontWeight: FontWeight.w800),
                  ),
                ),
                IconButton(
                  tooltip: 'Buat event',
                  icon: const Icon(Icons.add_circle_outline, size: 30),
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const CreateEventScreen(),
                    ),
                  ),
                ),
                UserAvatar(name: name),
              ],
            ),
          ),
          SizedBox(
            height: 48,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              children: [
                for (final f in _filters.entries)
                  AppChip(
                    label: f.value,
                    selected: ep.filter == f.key,
                    onTap: () => ep.setFilter(f.key),
                  ),
              ],
            ),
          ),
          Expanded(
            child: RefreshIndicator(
              onRefresh: ep.fetch,
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                children: [
                  if (ep.loading && ep.events.isEmpty)
                    const Padding(
                      padding: EdgeInsets.all(40),
                      child: Center(child: CircularProgressIndicator()),
                    )
                  else if (ep.error != null)
                    Padding(
                      padding: const EdgeInsets.all(24),
                      child: Text('Gagal memuat: ${ep.error}'),
                    )
                  else if (events.isEmpty)
                    const Padding(
                      padding: EdgeInsets.all(40),
                      child: Center(child: Text('Belum ada event')),
                    )
                  else
                    for (final e in events)
                      EventCard(event: e, onToggle: () => ep.toggleAttend(e)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
