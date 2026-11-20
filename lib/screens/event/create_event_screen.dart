import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/format.dart';
import '../../providers/community_provider.dart';
import '../../providers/event_provider.dart';
import '../../widgets/app_card.dart';

class CreateEventScreen extends StatefulWidget {
  const CreateEventScreen({super.key});
  @override
  State<CreateEventScreen> createState() => _CreateEventScreenState();
}

class _CreateEventScreenState extends State<CreateEventScreen> {
  final _title = TextEditingController();
  final _desc = TextEditingController();
  final _location = TextEditingController();
  String? _communityId;
  DateTime? _startsAt;
  bool _saving = false;

  @override
  void dispose() {
    _title.dispose();
    _desc.dispose();
    _location.dispose();
    super.dispose();
  }

  void _snack(String m) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(m)));

  Future<void> _pickDateTime() async {
    final now = DateTime.now();
    final date = await showDatePicker(
      context: context,
      initialDate: now.add(const Duration(days: 1)),
      firstDate: now,
      lastDate: now.add(const Duration(days: 365)),
    );
    if (date == null || !mounted) return;
    final time = await showTimePicker(
      context: context,
      initialTime: const TimeOfDay(hour: 15, minute: 0),
    );
    if (time == null) return;
    setState(
      () => _startsAt = DateTime(
        date.year,
        date.month,
        date.day,
        time.hour,
        time.minute,
      ),
    );
  }

  Future<void> _submit() async {
    if (_communityId == null ||
        _title.text.trim().isEmpty ||
        _startsAt == null) {
      _snack('Komunitas, judul, dan waktu wajib diisi');
      return;
    }
    setState(() => _saving = true);
    try {
      await context.read<EventProvider>().create(
        communityId: _communityId!,
        title: _title.text.trim(),
        description: _desc.text.trim(),
        location: _location.text.trim(),
        startsAt: _startsAt!,
      );
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        setState(() => _saving = false);
        _snack('Gagal membuat event: $e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final communities = context.watch<CommunityProvider>().joined;
    return Scaffold(
      appBar: AppBar(title: const Text('Buat Event')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          AppCard(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                isExpanded: true,
                value: _communityId,
                hint: const Text('Pilih komunitas'),
                items: [
                  for (final c in communities)
                    DropdownMenuItem(value: c.id, child: Text(c.name)),
                ],
                onChanged: (v) => setState(() => _communityId = v),
              ),
            ),
          ),
          const SizedBox(height: 16),
          AppCard(
            child: Column(
              children: [
                TextField(
                  controller: _title,
                  decoration: const InputDecoration(labelText: 'Judul event'),
                ),
                TextField(
                  controller: _desc,
                  maxLines: 3,
                  decoration: const InputDecoration(labelText: 'Deskripsi'),
                ),
                TextField(
                  controller: _location,
                  decoration: const InputDecoration(labelText: 'Lokasi'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          AppCard(
            child: InkWell(
              onTap: _pickDateTime,
              child: Row(
                children: [
                  const Icon(Icons.calendar_today_outlined),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      _startsAt == null
                          ? 'Pilih tanggal dan jam'
                          : '${formatTanggal(_startsAt!)} · ${formatJam(_startsAt!)} WIB',
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          Align(
            alignment: Alignment.centerRight,
            child: FilledButton(
              onPressed: _saving ? null : _submit,
              child: _saving
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Buat Event'),
            ),
          ),
        ],
      ),
    );
  }
}
