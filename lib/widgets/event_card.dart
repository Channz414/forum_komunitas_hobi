import 'package:flutter/material.dart';

import '../core/format.dart';
import '../core/theme.dart';
import '../models/event.dart';
import 'app_card.dart';

class EventCard extends StatelessWidget {
  final Event event;
  final VoidCallback onToggle;
  const EventCard({super.key, required this.event, required this.onToggle});

  @override
  Widget build(BuildContext context) {
    final d = event.startsAt;
    final label = event.isPast
        ? 'Selesai'
        : event.joinedByMe
        ? '✓ Terdaftar'
        : '+ Ikut';

    return AppCard(
      margin: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.chip,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppColors.chipBorder),
            ),
            child: Text(
              event.communityName,
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 56,
                padding: const EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(
                  color: AppColors.bg,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.chipBorder),
                ),
                child: Column(
                  children: [
                    Text(
                      bulanPendek(d).toUpperCase(),
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      '${d.day}',
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      event.title,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    if (event.description != null &&
                        event.description!.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text(event.description!),
                      ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              const Icon(Icons.schedule, size: 18),
              const SizedBox(width: 8),
              Expanded(
                child: Text('${formatTanggal(d)} · ${formatJam(d)} WIB'),
              ),
            ],
          ),
          if (event.location != null && event.location!.isNotEmpty) ...[
            const SizedBox(height: 6),
            Row(
              children: [
                const Icon(Icons.place_outlined, size: 18),
                const SizedBox(width: 8),
                Expanded(child: Text(event.location!)),
              ],
            ),
          ],
          const SizedBox(height: 12),
          Row(
            children: [
              const Icon(Icons.people_outline, size: 18),
              const SizedBox(width: 6),
              Text(
                '${event.attendeeCount} peserta',
                style: const TextStyle(fontSize: 12),
              ),
              const Spacer(),
              OutlinedButton(
                onPressed: event.isPast ? null : onToggle,
                style: OutlinedButton.styleFrom(
                  backgroundColor: event.joinedByMe
                      ? AppColors.chip
                      : const Color(0xFFB8D4F8),
                  foregroundColor: Colors.black,
                  side: const BorderSide(color: AppColors.ink, width: 1.5),
                ),
                child: Text(
                  label,
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
