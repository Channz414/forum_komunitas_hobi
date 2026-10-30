import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../../core/theme.dart';
import '../../providers/community_provider.dart';
import '../../providers/post_provider.dart';

class CreatePostScreen extends StatefulWidget {
  const CreatePostScreen({super.key});
  @override
  State<CreatePostScreen> createState() => _CreatePostScreenState();
}

class _CreatePostScreenState extends State<CreatePostScreen> {
  final _text = TextEditingController();
  String? _communityId;
  XFile? _image;
  Uint8List? _bytes;
  bool _posting = false;

  void _snack(String m) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(m)));

  Future<void> _pick() async {
    final x = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      imageQuality: 80,
      maxWidth: 1600,
    );
    if (x == null) return;
    final b = await x.readAsBytes();
    setState(() {
      _image = x;
      _bytes = b;
    });
  }

  Future<void> _submit() async {
    if (_communityId == null || _text.text.trim().isEmpty) {
      _snack('Pilih komunitas dan isi teks dulu');
      return;
    }
    setState(() => _posting = true);
    try {
      await context.read<PostProvider>().createPost(
        communityId: _communityId!,
        content: _text.text.trim(),
        image: _image,
      );
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        setState(() => _posting = false);
        _snack('Gagal posting: $e');
      }
    }
  }

  BoxDecoration get _card => BoxDecoration(
    color: Colors.white,
    borderRadius: BorderRadius.circular(16),
    boxShadow: const [BoxShadow(color: AppColors.shadow, blurRadius: 6)],
  );

  @override
  Widget build(BuildContext context) {
    final communities = context.watch<CommunityProvider>().joined;
    return Scaffold(
      appBar: AppBar(title: const Text('Buat Postingan')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            decoration: _card,
            child: Row(
              children: [
                const Text(
                  'Bagikan ke',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      isExpanded: true,
                      value: _communityId,
                      hint: const Text('Pilih komunitas'),
                      items: [
                        for (final c in communities)
                          DropdownMenuItem(
                            value: c.id,
                            child: Text(
                              c.name,
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                      ],
                      onChanged: (v) => setState(() => _communityId = v),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: _card,
            child: TextField(
              controller: _text,
              maxLines: 8,
              decoration: const InputDecoration(
                hintText: 'Tuliskan sesuatu...',
                border: InputBorder.none,
              ),
            ),
          ),
          const SizedBox(height: 16),
          GestureDetector(
            onTap: _pick,
            child: Container(
              height: 220,
              decoration: BoxDecoration(
                color: const Color(0xFFB8D4F8),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.accent),
              ),
              child: _bytes == null
                  ? const Center(child: Text('Ketuk untuk pilih foto'))
                  : ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: Image.memory(
                        _bytes!,
                        fit: BoxFit.cover,
                        width: double.infinity,
                      ),
                    ),
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
              onPressed: _posting ? null : _submit,
              child: _posting
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text(
                      'Posting',
                      style: TextStyle(fontWeight: FontWeight.w700),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}
