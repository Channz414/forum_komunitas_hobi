import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/config.dart';
import '../../core/theme.dart';
import '../../providers/post_provider.dart';
import '../../providers/profile_provider.dart';
import '../../widgets/app_card.dart';
import '../../widgets/user_avatar.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});
  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  late final TextEditingController _username;
  late final TextEditingController _bio;
  bool _saving = false;
  bool _uploading = false;

  @override
  void initState() {
    super.initState();
    final pp = context.read<ProfileProvider>();
    _username = TextEditingController(text: pp.username);
    _bio = TextEditingController(text: pp.bio ?? '');
  }

  @override
  void dispose() {
    _username.dispose();
    _bio.dispose();
    super.dispose();
  }

  void _snack(String m) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(m)));

  // ---------- foto ----------
  Future<void> _photoMenu() async {
    final pp = context.read<ProfileProvider>();
    final choice = await showModalBottomSheet<String>(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: const Text('Pilih dari galeri'),
              onTap: () => Navigator.pop(ctx, 'pick'),
            ),
            if (pp.avatarUrl != null)
              ListTile(
                leading: const Icon(Icons.delete_outline),
                title: const Text('Hapus foto'),
                onTap: () => Navigator.pop(ctx, 'remove'),
              ),
          ],
        ),
      ),
    );
    if (choice == 'pick') await _pickPhoto();
    if (choice == 'remove') await _removePhoto();
  }

  Future<void> _pickPhoto() async {
    final pp = context.read<ProfileProvider>();
    final posts = context.read<PostProvider>();
    final x = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      imageQuality: 80,
      maxWidth: 800,
    );
    if (x == null) return;
    setState(() => _uploading = true);
    try {
      await pp.setAvatar(x);
      posts.fetch(); // supaya avatar di feed ikut berubah
    } catch (e) {
      if (mounted) _snack('Gagal mengganti foto: $e');
    }
    if (mounted) setState(() => _uploading = false);
  }

  Future<void> _removePhoto() async {
    final pp = context.read<ProfileProvider>();
    final posts = context.read<PostProvider>();
    try {
      await pp.removeAvatar();
      posts.fetch();
    } catch (e) {
      if (mounted) _snack('Gagal menghapus foto: $e');
    }
  }

  // ---------- username + bio ----------
  Future<void> _saveProfile() async {
    final pp = context.read<ProfileProvider>();
    final posts = context.read<PostProvider>();
    final name = _username.text.trim();
    if (!RegExp(r'^[a-zA-Z0-9_.]{3,20}$').hasMatch(name)) {
      _snack('Username 3-20 karakter: huruf, angka, titik, atau underscore');
      return;
    }
    setState(() => _saving = true);
    try {
      if (name != pp.username) await pp.updateUsername(name);
      if (_bio.text.trim() != (pp.bio ?? '')) await pp.updateBio(_bio.text);
      posts.fetch();
      if (mounted) _snack('Profil disimpan');
    } on PostgrestException catch (e) {
      // 23505 = unique violation (username sudah dipakai)
      if (mounted) {
        _snack(
          e.code == '23505'
              ? 'Username sudah dipakai'
              : 'Gagal menyimpan: ${e.message}',
        );
      }
    } catch (e) {
      if (mounted) _snack('Gagal menyimpan: $e');
    }
    if (mounted) setState(() => _saving = false);
  }

  // ---------- email ----------
  Future<void> _changeEmail() async {
    final c = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Ganti email'),
        content: TextField(
          controller: c,
          keyboardType: TextInputType.emailAddress,
          decoration: const InputDecoration(labelText: 'Email baru'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Batal'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Simpan'),
          ),
        ],
      ),
    );
    final email = c.text.trim();
    if (ok != true || !mounted) return;
    if (!email.contains('@')) {
      _snack('Format email tidak valid');
      return;
    }
    try {
      await supabase.auth.updateUser(UserAttributes(email: email));
      if (mounted) {
        _snack(
          'Permintaan ganti email dikirim. '
          'Jika diminta, cek inbox untuk konfirmasi.',
        );
      }
    } on AuthException catch (e) {
      if (mounted) _snack(e.message);
    } catch (e) {
      if (mounted) _snack('Gagal mengganti email: $e');
    }
  }

  // ---------- password ----------
  Future<void> _changePassword() async {
    final cur = TextEditingController();
    final next = TextEditingController();
    final confirm = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Ganti password'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: cur,
              obscureText: true,
              decoration: const InputDecoration(labelText: 'Password lama'),
            ),
            TextField(
              controller: next,
              obscureText: true,
              decoration: const InputDecoration(labelText: 'Password baru'),
            ),
            TextField(
              controller: confirm,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: 'Ulangi password baru',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Batal'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Simpan'),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    if (next.text.length < 6) {
      _snack('Password baru minimal 6 karakter');
      return;
    }
    if (next.text != confirm.text) {
      _snack('Konfirmasi password tidak sama');
      return;
    }
    try {
      final email = supabase.auth.currentUser?.email;
      if (email == null) throw 'Email tidak ditemukan';
      // verifikasi password lama dengan login ulang
      await supabase.auth.signInWithPassword(email: email, password: cur.text);
      await supabase.auth.updateUser(UserAttributes(password: next.text));
      if (mounted) _snack('Password berhasil diganti');
    } on AuthException catch (e) {
      if (mounted) {
        _snack(
          e.message.contains('Invalid login')
              ? 'Password lama salah'
              : e.message,
        );
      }
    } catch (e) {
      if (mounted) _snack('Gagal mengganti password: $e');
    }
  }

  // ---------- hapus akun ----------
  Future<void> _deleteAccount() async {
    final nav = Navigator.of(context);
    final c = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setS) => AlertDialog(
          title: const Text('Hapus akun?'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Semua postingan, komentar, dan event buatan Anda akan '
                'dihapus permanen dan tidak bisa dikembalikan. '
                'Ketik HAPUS untuk konfirmasi.',
              ),
              const SizedBox(height: 12),
              TextField(
                controller: c,
                onChanged: (_) => setS(() {}),
                decoration: const InputDecoration(hintText: 'HAPUS'),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Batal'),
            ),
            FilledButton(
              style: FilledButton.styleFrom(backgroundColor: Colors.red),
              onPressed: c.text == 'HAPUS'
                  ? () => Navigator.pop(ctx, true)
                  : null,
              child: const Text('Hapus akun'),
            ),
          ],
        ),
      ),
    );
    if (ok != true) return;
    try {
      await supabase.rpc('delete_my_account');
      try {
        await supabase.auth.signOut(scope: SignOutScope.local);
      } catch (_) {}
      // tutup semua layar yang numpuk, sisakan halaman login
      nav.popUntil((r) => r.isFirst);
    } catch (e) {
      if (mounted) _snack('Gagal menghapus akun: $e');
    }
  }

  Widget _section(String t) => Padding(
    padding: const EdgeInsets.fromLTRB(4, 24, 4, 8),
    child: Text(
      t,
      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
    ),
  );

  @override
  Widget build(BuildContext context) {
    final pp = context.watch<ProfileProvider>();
    final email = supabase.auth.currentUser?.email ?? '';

    return Scaffold(
      appBar: AppBar(title: const Text('Edit Profil')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Center(
            child: GestureDetector(
              onTap: _uploading ? null : _photoMenu,
              child: Stack(
                children: [
                  UserAvatar(
                    name: pp.username.isEmpty ? 'U' : pp.username,
                    imageUrl: pp.avatarUrl,
                    radius: 52,
                  ),
                  Positioned(
                    right: 0,
                    bottom: 0,
                    child: CircleAvatar(
                      radius: 16,
                      backgroundColor: AppColors.accent,
                      child: _uploading
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Icon(
                              Icons.camera_alt,
                              size: 16,
                              color: Colors.white,
                            ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          Center(
            child: TextButton(
              onPressed: _uploading ? null : _photoMenu,
              child: const Text('Ganti foto profil'),
            ),
          ),
          _section('Profil'),
          AppCard(
            child: Column(
              children: [
                TextField(
                  controller: _username,
                  decoration: const InputDecoration(labelText: 'Username'),
                ),
                TextField(
                  controller: _bio,
                  maxLines: 3,
                  maxLength: 150,
                  decoration: const InputDecoration(labelText: 'Bio'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Align(
            alignment: Alignment.centerRight,
            child: FilledButton(
              onPressed: _saving ? null : _saveProfile,
              child: _saving
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Simpan'),
            ),
          ),
          _section('Akun'),
          AppCard(
            padding: EdgeInsets.zero,
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.email_outlined),
                  title: const Text('Email'),
                  subtitle: Text(email),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: _changeEmail,
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.lock_outline),
                  title: const Text('Ganti password'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: _changePassword,
                ),
              ],
            ),
          ),
          _section('Zona berbahaya'),
          AppCard(
            padding: EdgeInsets.zero,
            child: ListTile(
              leading: const Icon(Icons.delete_forever, color: Colors.red),
              title: const Text(
                'Hapus akun',
                style: TextStyle(color: Colors.red),
              ),
              onTap: _deleteAccount,
            ),
          ),
        ],
      ),
    );
  }
}
