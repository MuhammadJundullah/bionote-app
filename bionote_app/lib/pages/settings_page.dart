import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../services/auth_service.dart';
import '../utils/image_url.dart';
import 'add_employee_page.dart';
import 'home_page.dart';
import 'login_page.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _oldPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _authService = const AuthService();
  bool _obscureOld = true;
  bool _obscureNew = true;
  bool _obscureConfirm = true;
  bool _loading = false;
  bool _photoLoading = false;
  Uint8List? _pickedPhotoBytes;
  String? _pickedPhotoName;
  String? _pickedPhotoMimeType;
  String? _currentPhotoPath;
  String? _userId;

  @override
  void initState() {
    super.initState();
    _loadUser();
  }

  @override
  void dispose() {
    _emailController.dispose();
    _oldPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _loadUser() async {
    final user = await _authService.currentUser();
    if (!mounted || user == null) return;
    setState(() {
      _emailController.text = user['email']?.toString() ?? '';
      _currentPhotoPath = user['foto']?.toString();
      _userId = user['id']?.toString();
    });
  }

  Future<void> _logout() async {
    await _authService.logout();
    if (!mounted) return;
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => const LoginPage()),
      (route) => false,
    );
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    // Placeholder: backend belum punya endpoint ubah password
    setState(() => _loading = true);
    await Future.delayed(const Duration(milliseconds: 600));
    if (!mounted) return;
    setState(() => _loading = false);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Pengaturan disimpan (placeholder, perlu API update password)')),
    );
  }

  Future<void> _pickPhoto() async {
    final picked = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      maxWidth: 1200,
      imageQuality: 85,
    );
    if (picked == null) return;
    final bytes = await picked.readAsBytes();
    setState(() {
      _pickedPhotoBytes = bytes;
      _pickedPhotoName = picked.name;
      _pickedPhotoMimeType = picked.mimeType;
    });
  }

  Future<void> _uploadPhoto() async {
    final userId = _userId;
    if (userId == null || _pickedPhotoBytes == null || _pickedPhotoName == null) {
      return;
    }
    setState(() => _photoLoading = true);
    try {
      final user = await _authService.uploadUserPhoto(
        userId: userId,
        bytes: _pickedPhotoBytes!,
        filename: _pickedPhotoName!,
        mimeType: _pickedPhotoMimeType,
      );
      if (!mounted) return;
      setState(() {
        _currentPhotoPath = user['foto']?.toString();
        _pickedPhotoBytes = null;
        _pickedPhotoName = null;
        _pickedPhotoMimeType = null;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Foto profil diperbarui')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
      );
    } finally {
      if (mounted) setState(() => _photoLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Pengaturan akun',
          style: TextStyle(
            color: Colors.black87,
            fontWeight: FontWeight.w700,
          ),
        ),
        centerTitle: false,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _label('Foto profil'),
              _photoSection(),
              const SizedBox(height: 16),
              _label('Email'),
              _input(
                controller: _emailController,
                hint: 'Enter your email',
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 16),
              _label('Masukkan password lama'),
              _input(
                controller: _oldPasswordController,
                hint: 'Enter your old password',
                obscure: _obscureOld,
                toggle: () => setState(() => _obscureOld = !_obscureOld),
              ),
              const SizedBox(height: 16),
              _label('Password baru'),
              _input(
                controller: _newPasswordController,
                hint: 'Enter your password',
                obscure: _obscureNew,
                toggle: () => setState(() => _obscureNew = !_obscureNew),
              ),
              const SizedBox(height: 16),
              _label('Konfirmasi Password baru'),
              _input(
                controller: _confirmPasswordController,
                hint: 'Enter your password',
                obscure: _obscureConfirm,
                toggle: () => setState(() => _obscureConfirm = !_obscureConfirm),
                validator: (v) {
                  if (v != _newPasswordController.text) {
                    return 'Password tidak sama';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _loading ? null : _save,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue[800],
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      child: _loading
                          ? const SizedBox(
                              height: 18,
                              width: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            )
                          : const Text(
                              'Simpan',
                              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                            ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  OutlinedButton(
                    onPressed: _confirmLogout,
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
                      side: BorderSide(color: Colors.red.shade400),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    child: const Text(
                      'Logout',
                      style: TextStyle(color: Colors.red),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        currentIndex: 2,
        onTap: (idx) async {
          if (idx == 0) {
            Navigator.pushReplacement(
              context,
              _noAnimationRoute(const AddEmployeePage()),
            );
          } else if (idx == 1) {
            Navigator.of(context).pushAndRemoveUntil(
              _noAnimationRoute(const HomePage()),
              (route) => false,
            );
          } else if (idx == 3) {
            await _confirmLogout();
          }
        },
        selectedItemColor: Colors.white,
        unselectedItemColor: Colors.white70,
        backgroundColor: Colors.blue[800],
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.add_box_outlined),
            label: 'Tambah',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.groups),
            label: 'Anggota',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings),
            label: 'Setting',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.logout),
            label: 'Logout',
          ),
        ],
      ),
    );
  }

  PageRouteBuilder<T> _noAnimationRoute<T>(Widget page) {
    return PageRouteBuilder<T>(
      pageBuilder: (_, __, ___) => page,
      transitionDuration: Duration.zero,
      reverseTransitionDuration: Duration.zero,
    );
  }

  Widget _label(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: Color(0xFF243141),
        ),
      ),
    );
  }

  Widget _photoSection() {
    final resolved = resolveImageUrl(_currentPhotoPath);
    final hasPicked = _pickedPhotoBytes != null;
    return Row(
      children: [
        CircleAvatar(
          radius: 32,
          backgroundColor: Colors.blueGrey.shade100,
          backgroundImage: hasPicked
              ? MemoryImage(_pickedPhotoBytes!)
              : (resolved != null ? NetworkImage(resolved) : null) as ImageProvider<Object>?,
          child: (!hasPicked && resolved == null)
              ? const Icon(Icons.person, size: 32, color: Colors.grey)
              : null,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Wrap(
            spacing: 8,
            children: [
              OutlinedButton.icon(
                onPressed: _photoLoading ? null : _pickPhoto,
                icon: const Icon(Icons.photo_library_outlined),
                label: const Text('Pilih foto'),
              ),
              if (hasPicked)
                ElevatedButton.icon(
                  onPressed: _photoLoading ? null : _uploadPhoto,
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.blue[800]),
                  icon: _photoLoading
                      ? const SizedBox(
                          height: 16,
                          width: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : const Icon(Icons.cloud_upload, color: Colors.white),
                  label: const Text('Upload', style: TextStyle(color: Colors.white)),
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _input({
    required TextEditingController controller,
    required String hint,
    TextInputType? keyboardType,
    bool obscure = false,
    VoidCallback? toggle,
    FormFieldValidator<String>? validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      obscureText: obscure,
      validator: validator,
      decoration: InputDecoration(
        hintText: hint,
        suffixIcon: toggle != null
            ? IconButton(
                icon: Icon(obscure ? Icons.visibility_off : Icons.visibility, color: Colors.grey),
                onPressed: toggle,
              )
            : null,
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: Colors.blue.shade700, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      ),
    );
  }

  Future<void> _confirmLogout() async {
    final shouldLogout = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Konfirmasi Logout'),
          content: const Text('Apakah Anda yakin ingin keluar?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Batal'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Logout'),
            ),
          ],
        );
      },
    );

    if (shouldLogout == true) {
      await _logout();
    }
  }
}
