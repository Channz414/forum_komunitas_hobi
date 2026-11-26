import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../../core/theme.dart';
import '../../providers/community_detail_provider.dart';
import '../../providers/community_provider.dart';
import '../../providers/post_provider.dart';
import '../../widgets/app_card.dart';

class EditCommunityScreen extends StatefulWidget {
  const EditCommunityScreen({super.key});
  @override
  State<EditCommunityScreen> createState() => _EditCommunityScreenState();
}

class _EditCommunityScreenState extends State<EditCommunityScreen> {
  late final TextEditingController _name;
  late final TextEditingController _desc;
  String? _imageUrl;
  XFile? _image;
  Uint8List? _bytes;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final c = context.read<CommunityDetailProvider>().info!;
    _name = TextEditingController(text: c.name);
    _desc = TextEditingController(text: c.description ?? '');
    _imageUrl = c.imageUrl;
  }

  @override
  void dispose() {
    _name.dispose();
    _desc.dispose();
    super.dispose();
  }

  void _snack(String m) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(m)));

  Future<void> _pick() async {
    final x = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      imageQuality: 80,
      maxWidth: 1200,
    );
    if (x == null) return;
    final b = await x.readAsBytes();
    setState(() {
      _image = x;
      _bytes = b;
    });
  }

  Future<void> _save() async {
    final name = _name.text.trim();
    if (name.isEmpty) {
      _snack('Nama komunitas wajib diisi');
      return;
    }
    final p = context.read<CommunityDetailProvider>();
    final cp = context.read<CommunityProvider>();
    final pp = context.read<PostProvider>();
    setState(() => _saving = true);
    try {
      await p.update(name: name, description: _desc.text.trim(), image: _image);
      cp.fetch();
      pp.fetch(); // nama komunitas di kartu postingan ikut berubah
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        setState(() => _saving = false);
        _snack('Gagal menyimpan: $e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Edit Komunitas')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          GestureDetector(
            onTap: _pick,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Container(
                height: 160,
                color: const Color(0xFFB8D4F8),
                child: _bytes != null
                    ? Image.memory(
                        _bytes!,
                        fit: BoxFit.cover,
                        width: double.infinity,
                      )
                    : (_imageUrl != null && _imageUrl!.isNotEmpty
                          ? Image.network(
                              _imageUrl!,
                              fit: BoxFit.cover,
                              width: double.infinity,
                            )
                          : const Center(
                              child: Text('Ketuk untuk pilih gambar komunitas'),
                            )),
              ),
            ),
          ),
          const SizedBox(height: 16),
          AppCard(
            child: Column(
              children: [
                TextField(
                  controller: _name,
                  decoration: const InputDecoration(
                    labelText: 'Nama komunitas',
                  ),
                ),
                TextField(
                  controller: _desc,
                  maxLines: 3,
                  decoration: const InputDecoration(labelText: 'Deskripsi'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          Align(
            alignment: Alignment.centerRight,
            child: FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.chip,
                foregroundColor: Colors.black,
                side: const BorderSide(color: AppColors.chipBorder),
              ),
              onPressed: _saving ? null : _save,
              child: _saving
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text(
                      'Simpan',
                      style: TextStyle(fontWeight: FontWeight.w700),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}
