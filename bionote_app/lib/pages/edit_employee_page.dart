import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../services/auth_service.dart';
import '../services/employee_service.dart';
import '../utils/image_url.dart';

class EditEmployeePage extends StatefulWidget {
  final Map<String, dynamic> employee;

  const EditEmployeePage({super.key, required this.employee});

  @override
  State<EditEmployeePage> createState() => _EditEmployeePageState();
}

class _EditEmployeePageState extends State<EditEmployeePage> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _namaController;
  late final TextEditingController _nikController;
  late final TextEditingController _tempatLahirController;
  late final TextEditingController _tanggalLahirController;
  late final TextEditingController _alamatController;
  String _jenisKelamin = 'L';
  String? _userId;
  String? _currentPhotoPath;
  Uint8List? _pickedPhotoBytes;
  String? _pickedPhotoName;
  String? _pickedPhotoMimeType;

  final _authService = const AuthService();
  final _employeeService = const EmployeeService();
  bool _loading = false;
  final List<_EducationEntry> _educations = [];
  final List<_JobEntry> _jobs = [];
  final List<_FamilyEntry> _families = [];

  @override
  void initState() {
    super.initState();
    final emp = widget.employee;
    _namaController = TextEditingController(text: emp['namaLengkap'] ?? '');
    _nikController = TextEditingController(text: emp['nik'] ?? '');
    _tempatLahirController = TextEditingController(text: emp['tempatLahir'] ?? '');
    _tanggalLahirController = TextEditingController(
      text: (emp['tanggalLahir'] != null)
          ? _formatDateInput(DateTime.parse(emp['tanggalLahir']))
          : '',
    );
    _alamatController = TextEditingController(text: emp['alamat'] ?? '');
    _currentPhotoPath = emp['foto']?.toString();
    _jenisKelamin = (emp['jenisKelamin'] ?? 'L').toString();
    final pendidikan = (emp['pendidikan'] as List<dynamic>? ?? []).cast<Map<String, dynamic>>();
    for (final p in pendidikan) {
      _educations.add(
        _EducationEntry(
          id: p['id'] as String?,
          jenjang: p['jenjang']?.toString() ?? '',
          namaSekolah: p['namaSekolah']?.toString() ?? '',
          tahunMasuk: p['tahunMasuk']?.toString() ?? '',
          tahunLulus: p['tahunLulus']?.toString(),
        ),
      );
    }
    final jobs = (emp['pekerjaan'] as List<dynamic>? ?? []).cast<Map<String, dynamic>>();
    for (final p in jobs) {
      _jobs.add(
        _JobEntry(
          id: p['id'] as String?,
          namaPerusahaan: p['namaPerusahaan']?.toString() ?? '',
          jabatan: p['jabatan']?.toString() ?? '',
          tahunMasuk: p['tahunMasuk']?.toString() ?? '',
          tahunKeluar: p['tahunKeluar']?.toString(),
        ),
      );
    }
    final fams = (emp['keluarga'] as List<dynamic>? ?? []).cast<Map<String, dynamic>>();
    for (final p in fams) {
      _families.add(
        _FamilyEntry(
          id: p['id'] as String?,
          hubungan: p['hubungan']?.toString() ?? '',
          nama: p['nama']?.toString() ?? '',
          tanggalLahir: p['tanggalLahir'] != null ? DateTime.tryParse(p['tanggalLahir']) : null,
        ),
      );
    }
  }

  @override
  void dispose() {
    _namaController.dispose();
    _nikController.dispose();
    _tempatLahirController.dispose();
    _tanggalLahirController.dispose();
    _alamatController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final initial = _tanggalLahirController.text.isNotEmpty
        ? DateTime.tryParse(_tanggalLahirController.text) ?? DateTime.now()
        : DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      _tanggalLahirController.text = _formatDateInput(picked);
    }
  }

  String _formatDateInput(DateTime date) {
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    final year = date.year.toString();
    return '$year-$month-$day';
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final uid = await _ensureUserId();
    if (uid == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('User tidak ditemukan, silakan login ulang')),
      );
      return;
    }
    setState(() => _loading = true);
    try {
      await _employeeService.updateEmployee(
        id: widget.employee['id'] as String,
        nik: _nikController.text.trim(),
        namaLengkap: _namaController.text.trim(),
        tempatLahir: _tempatLahirController.text.trim(),
        tanggalLahir: DateTime.parse(_tanggalLahirController.text.trim()),
        jenisKelamin: _jenisKelamin,
        alamat: _alamatController.text.trim(),
        createdById: uid,
      );
      if (_pickedPhotoBytes != null && _pickedPhotoName != null) {
        await _employeeService.uploadEmployeePhoto(
          id: widget.employee['id'] as String,
          bytes: _pickedPhotoBytes!,
          filename: _pickedPhotoName!,
          mimeType: _pickedPhotoMimeType,
          userId: uid,
        );
      }
      // Update additional relations (additions only)
      for (final edu in _educations.where((e) => e.id == null)) {
        await _employeeService.addEducation(
          employeeId: widget.employee['id'] as String,
          jenjang: edu.jenjang,
          namaSekolah: edu.namaSekolah,
          tahunMasuk: edu.tahunMasuk,
          tahunLulus: edu.tahunLulus?.isNotEmpty == true ? edu.tahunLulus : null,
          userId: uid,
        );
      }
      for (final job in _jobs.where((e) => e.id == null)) {
        await _employeeService.addJob(
          employeeId: widget.employee['id'] as String,
          namaPerusahaan: job.namaPerusahaan,
          jabatan: job.jabatan,
          tahunMasuk: job.tahunMasuk,
          tahunKeluar: job.tahunKeluar?.isNotEmpty == true ? job.tahunKeluar : null,
          userId: uid,
        );
      }
      for (final fam in _families.where((e) => e.id == null)) {
        await _employeeService.addFamily(
          employeeId: widget.employee['id'] as String,
          hubungan: fam.hubungan,
          nama: fam.nama,
          tanggalLahir: fam.tanggalLahir,
          userId: uid,
        );
      }
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Data anggota berhasil diperbarui')),
      );
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<String?> _ensureUserId() async {
    if (_userId != null) return _userId;
    final user = await _authService.currentUser();
    final uid = user?['id']?.toString();
    if (uid != null) _userId = uid;
    return uid;
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

  void _clearPhoto() {
    setState(() {
      _pickedPhotoBytes = null;
      _pickedPhotoName = null;
      _pickedPhotoMimeType = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.black87),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Edit Anggota',
          style: TextStyle(
            color: Colors.black87,
            fontWeight: FontWeight.w700,
          ),
        ),
        centerTitle: false,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Divider(color: Colors.blueGrey.shade200),
              const SizedBox(height: 12),
              const Text(
                'Data Pribadi',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF243141),
                ),
              ),
              const SizedBox(height: 12),
              _label('Nama lengkap'),
              _textField(
                controller: _namaController,
                hint: 'Nama lengkap',
                validator: (v) => v == null || v.trim().isEmpty ? 'Nama wajib diisi' : null,
              ),
              const SizedBox(height: 12),
              _label('NIK'),
              _textField(
                controller: _nikController,
                hint: 'NIK',
                keyboardType: TextInputType.number,
                validator: (v) => v == null || v.trim().isEmpty ? 'NIK wajib diisi' : null,
              ),
              const SizedBox(height: 12),
              _label('Tempat lahir'),
              _textField(
                controller: _tempatLahirController,
                hint: 'Tempat lahir',
                validator: (v) => v == null || v.trim().isEmpty ? 'Tempat lahir wajib diisi' : null,
              ),
              const SizedBox(height: 12),
              _label('Tanggal lahir'),
              _textField(
                controller: _tanggalLahirController,
                hint: 'YYYY-MM-DD',
                readOnly: true,
                onTap: _pickDate,
                suffix: IconButton(
                  icon: const Icon(Icons.calendar_today_outlined, color: Colors.grey),
                  onPressed: _pickDate,
                ),
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return 'Tanggal lahir wajib diisi';
                  try {
                    DateTime.parse(v.trim());
                    return null;
                  } catch (_) {
                    return 'Format tanggal YYYY-MM-DD';
                  }
                },
              ),
              const SizedBox(height: 12),
              _label('Jenis kelamin'),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: _fieldDecoration(),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _jenisKelamin,
                    items: const [
                      DropdownMenuItem(value: 'L', child: Text('Laki-laki')),
                      DropdownMenuItem(value: 'P', child: Text('Perempuan')),
                    ],
                    onChanged: (val) {
                      if (val != null) setState(() => _jenisKelamin = val);
                    },
                  ),
                ),
              ),
              const SizedBox(height: 12),
              _label('Alamat'),
              _textField(
                controller: _alamatController,
                hint: 'Alamat lengkap',
                maxLines: 2,
                validator: (v) => v == null || v.trim().isEmpty ? 'Alamat wajib diisi' : null,
              ),
              const SizedBox(height: 12),
              _label('Foto anggota'),
              _photoPicker(),
              const SizedBox(height: 20),
              _sectionHeader('Pendidikan'),
              _listSection(
                children: _educations
                    .asMap()
                    .entries
                    .map(
                      (e) => _pill(
                        title: '${e.value.jenjang} - ${e.value.namaSekolah}',
                        subtitle:
                            'Masuk ${e.value.tahunMasuk}${e.value.tahunLulus != null && e.value.tahunLulus!.isNotEmpty ? ', Lulus ${e.value.tahunLulus}' : ''}',
                        onDelete: () => _deleteEducation(e.key, e.value),
                      ),
                    )
                    .toList(),
                onAdd: _showAddEducation,
                emptyText: 'Belum ada riwayat pendidikan',
              ),
              const SizedBox(height: 16),
              _sectionHeader('Pekerjaan'),
              _listSection(
                children: _jobs
                    .asMap()
                    .entries
                    .map(
                      (e) => _pill(
                        title: e.value.namaPerusahaan,
                        subtitle:
                            '${e.value.jabatan} | ${e.value.tahunMasuk}${e.value.tahunKeluar != null && e.value.tahunKeluar!.isNotEmpty ? ' - ${e.value.tahunKeluar}' : ''}',
                        onDelete: () => _deleteJob(e.key, e.value),
                      ),
                    )
                    .toList(),
                onAdd: _showAddJob,
                emptyText: 'Belum ada riwayat pekerjaan',
              ),
              const SizedBox(height: 16),
              _sectionHeader('Keluarga'),
              _listSection(
                children: _families
                    .asMap()
                    .entries
                    .map(
                      (e) => _pill(
                        title: '${e.value.hubungan} - ${e.value.nama}',
                        subtitle: e.value.tanggalLahir != null
                            ? _formatDateDisplay(e.value.tanggalLahir!)
                            : 'Tanggal lahir tidak diisi',
                        onDelete: () => _deleteFamily(e.key, e.value),
                      ),
                    )
                    .toList(),
                onAdd: _showAddFamily,
                emptyText: 'Belum ada data keluarga',
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _loading ? null : _submit,
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
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                ),
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
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

  Widget _photoPicker() {
    final hasPhoto = _pickedPhotoBytes != null;
    final resolvedUrl = resolveImageUrl(_currentPhotoPath);
    return Row(
      children: [
        Container(
          height: 96,
          width: 96,
          decoration: BoxDecoration(
            color: Colors.blueGrey.shade50,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: Colors.blueGrey.shade200),
          ),
          child: hasPhoto
              ? ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: Image.memory(
                    _pickedPhotoBytes!,
                    fit: BoxFit.cover,
                    width: 96,
                    height: 96,
                  ),
                )
              : (resolvedUrl != null
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: Image.network(
                        resolvedUrl,
                        fit: BoxFit.cover,
                        width: 96,
                        height: 96,
                        errorBuilder: (_, __, ___) => const Icon(
                          Icons.broken_image,
                          size: 40,
                          color: Colors.grey,
                        ),
                      ),
                    )
                  : const Icon(Icons.person, size: 48, color: Colors.blueGrey)),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              OutlinedButton.icon(
                onPressed: _loading ? null : _pickPhoto,
                icon: const Icon(Icons.photo_library_outlined),
                label: const Text('Ganti foto'),
              ),
              if (hasPhoto)
                TextButton.icon(
                  onPressed: _loading ? null : _clearPhoto,
                  icon: const Icon(Icons.close, color: Colors.red),
                  label: const Text('Hapus', style: TextStyle(color: Colors.red)),
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _textField({
    required TextEditingController controller,
    required String hint,
    bool readOnly = false,
    int maxLines = 1,
    TextInputType? keyboardType,
    FormFieldValidator<String>? validator,
    VoidCallback? onTap,
    Widget? suffix,
  }) {
    return TextFormField(
      controller: controller,
      readOnly: readOnly,
      maxLines: maxLines,
      keyboardType: keyboardType,
      validator: validator,
      onTap: onTap,
      decoration: InputDecoration(
        hintText: hint,
        suffixIcon: suffix,
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: Colors.blueGrey.shade200),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: Colors.blue.shade700, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      ),
    );
  }

  BoxDecoration _fieldDecoration() {
    return BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(10),
      border: Border.all(color: Colors.blueGrey.shade200),
    );
  }

  Widget _sectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w700,
          color: Color(0xFF243141),
        ),
      ),
    );
  }

  Widget _listSection({
    required List<Widget> children,
    required VoidCallback onAdd,
    required String emptyText,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (children.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: Text(
              emptyText,
              style: const TextStyle(color: Colors.grey),
            ),
          )
        else
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: children,
          ),
        const SizedBox(height: 8),
        OutlinedButton.icon(
          onPressed: onAdd,
          icon: const Icon(Icons.add),
          label: const Text('Tambah'),
        ),
      ],
    );
  }

  Widget _pill({required String title, String? subtitle, required VoidCallback onDelete}) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.blueGrey.shade200),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                if (subtitle != null && subtitle.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Text(
                      subtitle,
                      style: const TextStyle(color: Colors.grey),
                    ),
                  ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
            onPressed: onDelete,
          ),
        ],
      ),
    );
  }

  Future<void> _showAddEducation() async {
    final jenjangCtrl = TextEditingController();
    final sekolahCtrl = TextEditingController();
    final masukCtrl = TextEditingController();
    final lulusCtrl = TextEditingController();
    final formKey = GlobalKey<FormState>();

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Tambah Pendidikan'),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: jenjangCtrl,
                decoration: const InputDecoration(labelText: 'Jenjang (SD/SMP/SMA/D1-D4/S1/S2/S3)'),
                validator: (v) => v == null || v.trim().isEmpty ? 'Jenjang wajib diisi' : null,
              ),
              TextFormField(
                controller: sekolahCtrl,
                decoration: const InputDecoration(labelText: 'Nama sekolah'),
                validator: (v) => v == null || v.trim().isEmpty ? 'Nama sekolah wajib diisi' : null,
              ),
              TextFormField(
                controller: masukCtrl,
                decoration: const InputDecoration(labelText: 'Tahun masuk (4 digit)'),
                keyboardType: TextInputType.number,
                validator: (v) => v == null || v.trim().isEmpty ? 'Tahun masuk wajib diisi' : null,
              ),
              TextFormField(
                controller: lulusCtrl,
                decoration: const InputDecoration(labelText: 'Tahun lulus (opsional)'),
                keyboardType: TextInputType.number,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Batal')),
          ElevatedButton(
            onPressed: () async {
              if (!formKey.currentState!.validate()) return;
              final uid = await _ensureUserId();
              if (uid == null) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('User tidak ditemukan, silakan login ulang')),
                  );
                }
                return;
              }
              try {
                final created = await _employeeService.addEducation(
                  employeeId: widget.employee['id'] as String,
                  jenjang: jenjangCtrl.text.trim(),
                  namaSekolah: sekolahCtrl.text.trim(),
                  tahunMasuk: masukCtrl.text.trim(),
                  tahunLulus: lulusCtrl.text.trim().isEmpty ? null : lulusCtrl.text.trim(),
                  userId: uid,
                );
                setState(() {
                  _educations.add(
                    _EducationEntry(
                      id: (created as Map<String, dynamic>)['id']?.toString(),
                      jenjang: created['jenjang']?.toString() ?? jenjangCtrl.text.trim(),
                      namaSekolah: created['namaSekolah']?.toString() ?? sekolahCtrl.text.trim(),
                      tahunMasuk: created['tahunMasuk']?.toString() ?? masukCtrl.text.trim(),
                      tahunLulus: created['tahunLulus']?.toString(),
                    ),
                  );
                });
                Navigator.pop(context);
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
                );
              }
            },
            child: const Text('Simpan'),
          ),
        ],
      ),
    );
  }

  Future<void> _showAddJob() async {
    final perusahaanCtrl = TextEditingController();
    final jabatanCtrl = TextEditingController();
    final masukCtrl = TextEditingController();
    final keluarCtrl = TextEditingController();
    final formKey = GlobalKey<FormState>();

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Tambah Pekerjaan'),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: perusahaanCtrl,
                decoration: const InputDecoration(labelText: 'Nama perusahaan'),
                validator: (v) => v == null || v.trim().isEmpty ? 'Nama perusahaan wajib diisi' : null,
              ),
              TextFormField(
                controller: jabatanCtrl,
                decoration: const InputDecoration(labelText: 'Jabatan'),
                validator: (v) => v == null || v.trim().isEmpty ? 'Jabatan wajib diisi' : null,
              ),
              TextFormField(
                controller: masukCtrl,
                decoration: const InputDecoration(labelText: 'Tahun masuk (4 digit)'),
                keyboardType: TextInputType.number,
                validator: (v) => v == null || v.trim().isEmpty ? 'Tahun masuk wajib diisi' : null,
              ),
              TextFormField(
                controller: keluarCtrl,
                decoration: const InputDecoration(labelText: 'Tahun keluar (opsional)'),
                keyboardType: TextInputType.number,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Batal')),
          ElevatedButton(
            onPressed: () async {
              if (!formKey.currentState!.validate()) return;
              final uid = await _ensureUserId();
              if (uid == null) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('User tidak ditemukan, silakan login ulang')),
                  );
                }
                return;
              }
              try {
                final created = await _employeeService.addJob(
                  employeeId: widget.employee['id'] as String,
                  namaPerusahaan: perusahaanCtrl.text.trim(),
                  jabatan: jabatanCtrl.text.trim(),
                  tahunMasuk: masukCtrl.text.trim(),
                  tahunKeluar: keluarCtrl.text.trim().isEmpty ? null : keluarCtrl.text.trim(),
                  userId: uid,
                );
                setState(() {
                  _jobs.add(
                    _JobEntry(
                      id: (created as Map<String, dynamic>)['id']?.toString(),
                      namaPerusahaan: created['namaPerusahaan']?.toString() ?? perusahaanCtrl.text.trim(),
                      jabatan: created['jabatan']?.toString() ?? jabatanCtrl.text.trim(),
                      tahunMasuk: created['tahunMasuk']?.toString() ?? masukCtrl.text.trim(),
                      tahunKeluar: created['tahunKeluar']?.toString(),
                    ),
                  );
                });
                Navigator.pop(context);
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
                );
              }
            },
            child: const Text('Simpan'),
          ),
        ],
      ),
    );
  }

  Future<void> _showAddFamily() async {
    final hubunganCtrl = TextEditingController();
    final namaCtrl = TextEditingController();
    final tanggalCtrl = TextEditingController();
    final formKey = GlobalKey<FormState>();

    Future<void> pickDate() async {
      final now = DateTime.now();
      final picked = await showDatePicker(
        context: context,
        initialDate: now,
        firstDate: DateTime(1900),
        lastDate: now,
      );
      if (picked != null) {
        tanggalCtrl.text = _formatDateInput(picked);
      }
    }

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Tambah Keluarga'),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: hubunganCtrl,
                decoration: const InputDecoration(labelText: 'Hubungan (Ayah/Ibu/Pasangan/Anak/Saudara)'),
                validator: (v) => v == null || v.trim().isEmpty ? 'Hubungan wajib diisi' : null,
              ),
              TextFormField(
                controller: namaCtrl,
                decoration: const InputDecoration(labelText: 'Nama'),
                validator: (v) => v == null || v.trim().isEmpty ? 'Nama wajib diisi' : null,
              ),
              TextFormField(
                controller: tanggalCtrl,
                decoration: InputDecoration(
                  labelText: 'Tanggal lahir (opsional)',
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.calendar_today_outlined),
                    onPressed: pickDate,
                  ),
                ),
                readOnly: true,
                onTap: pickDate,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Batal')),
          ElevatedButton(
            onPressed: () async {
              if (!formKey.currentState!.validate()) return;
              final uid = await _ensureUserId();
              if (uid == null) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('User tidak ditemukan, silakan login ulang')),
                  );
                }
                return;
              }
              DateTime? tanggal;
              if (tanggalCtrl.text.trim().isNotEmpty) {
                try {
                  tanggal = DateTime.parse(tanggalCtrl.text.trim());
                } catch (_) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Format tanggal keluarga tidak valid')),
                  );
                  return;
                }
              }
              try {
                final created = await _employeeService.addFamily(
                  employeeId: widget.employee['id'] as String,
                  hubungan: hubunganCtrl.text.trim(),
                  nama: namaCtrl.text.trim(),
                  tanggalLahir: tanggal,
                  userId: uid,
                );
                setState(() {
                  _families.add(
                    _FamilyEntry(
                      id: (created as Map<String, dynamic>)['id']?.toString(),
                      hubungan: created['hubungan']?.toString() ?? hubunganCtrl.text.trim(),
                      nama: created['nama']?.toString() ?? namaCtrl.text.trim(),
                      tanggalLahir: created['tanggalLahir'] != null
                          ? DateTime.tryParse(created['tanggalLahir'])
                          : tanggal,
                    ),
                  );
                });
                Navigator.pop(context);
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
                );
              }
            },
            child: const Text('Simpan'),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteEducation(int index, _EducationEntry entry) async {
    final uid = await _ensureUserId();
    if (uid == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('User tidak ditemukan, silakan login ulang')),
      );
      return;
    }
    if (entry.id != null) {
      try {
        await _employeeService.deleteEducation(
          employeeId: widget.employee['id'] as String,
          id: entry.id!,
          userId: uid,
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
        );
        return;
      }
    }
    setState(() => _educations.removeAt(index));
  }

  Future<void> _deleteJob(int index, _JobEntry entry) async {
    final uid = await _ensureUserId();
    if (uid == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('User tidak ditemukan, silakan login ulang')),
      );
      return;
    }
    if (entry.id != null) {
      try {
        await _employeeService.deleteJob(
          employeeId: widget.employee['id'] as String,
          id: entry.id!,
          userId: uid,
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
        );
        return;
      }
    }
    setState(() => _jobs.removeAt(index));
  }

  Future<void> _deleteFamily(int index, _FamilyEntry entry) async {
    final uid = await _ensureUserId();
    if (uid == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('User tidak ditemukan, silakan login ulang')),
      );
      return;
    }
    if (entry.id != null) {
      try {
        await _employeeService.deleteFamily(
          employeeId: widget.employee['id'] as String,
          id: entry.id!,
          userId: uid,
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
        );
        return;
      }
    }
    setState(() => _families.removeAt(index));
  }

  String _formatDateDisplay(DateTime date) {
    const months = [
      'Januari',
      'Februari',
      'Maret',
      'April',
      'Mei',
      'Juni',
      'Juli',
      'Agustus',
      'September',
      'Oktober',
      'November',
      'Desember',
    ];
    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }
}

class _EducationEntry {
  final String? id;
  final String jenjang;
  final String namaSekolah;
  final String tahunMasuk;
  final String? tahunLulus;

  _EducationEntry({
    this.id,
    required this.jenjang,
    required this.namaSekolah,
    required this.tahunMasuk,
    this.tahunLulus,
  });
}

class _JobEntry {
  final String? id;
  final String namaPerusahaan;
  final String jabatan;
  final String tahunMasuk;
  final String? tahunKeluar;

  _JobEntry({
    this.id,
    required this.namaPerusahaan,
    required this.jabatan,
    required this.tahunMasuk,
    this.tahunKeluar,
  });
}

class _FamilyEntry {
  final String? id;
  final String hubungan;
  final String nama;
  final DateTime? tanggalLahir;

  _FamilyEntry({
    this.id,
    required this.hubungan,
    required this.nama,
    this.tanggalLahir,
  });
}
