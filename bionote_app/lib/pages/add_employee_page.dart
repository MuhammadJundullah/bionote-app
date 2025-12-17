import 'package:flutter/material.dart';

import '../services/auth_service.dart';
import '../services/employee_service.dart';
import 'home_page.dart';
import 'settings_page.dart';

class AddEmployeePage extends StatefulWidget {
  const AddEmployeePage({super.key});

  @override
  State<AddEmployeePage> createState() => _AddEmployeePageState();
}

class _AddEmployeePageState extends State<AddEmployeePage> {
  final _formKey = GlobalKey<FormState>();
  final _namaController = TextEditingController();
  final _nikController = TextEditingController();
  final _tempatLahirController = TextEditingController();
  final _tanggalLahirController = TextEditingController();
  final _alamatController = TextEditingController();
  final _fotoController = TextEditingController();
  String _jenisKelamin = 'L';

  final _employeeService = const EmployeeService();
  final _authService = const AuthService();

  bool _loading = false;
  final List<_EducationEntry> _educations = [];
  final List<_JobEntry> _jobs = [];
  final List<_FamilyEntry> _families = [];

  @override
  void dispose() {
    _namaController.dispose();
    _nikController.dispose();
    _tempatLahirController.dispose();
    _tanggalLahirController.dispose();
    _alamatController.dispose();
    _fotoController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: now,
      firstDate: DateTime(1900),
      lastDate: now,
    );
    if (picked != null) {
      _tanggalLahirController.text = _formatDate(picked);
    }
  }

  String _formatDate(DateTime date) {
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    final year = date.year.toString();
    return '$year-$month-$day';
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final currentUser = await _authService.currentUser();
    if (currentUser == null || currentUser['id'] == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('User tidak ditemukan, silakan login ulang')),
      );
      return;
    }

    setState(() => _loading = true);
    try {
      final tanggal = DateTime.parse(_tanggalLahirController.text.trim());
      final employee = await _employeeService.createEmployee(
        nik: _nikController.text.trim(),
        namaLengkap: _namaController.text.trim(),
        tempatLahir: _tempatLahirController.text.trim(),
        tanggalLahir: tanggal,
        jenisKelamin: _jenisKelamin,
        alamat: _alamatController.text.trim(),
        foto: _fotoController.text.trim().isEmpty ? null : _fotoController.text.trim(),
        createdById: currentUser['id'] as String,
      );

      final employeeId = employee['id'] as String;
      for (final edu in _educations) {
        await _employeeService.addEducation(
          employeeId: employeeId,
          jenjang: edu.jenjang,
          namaSekolah: edu.namaSekolah,
          tahunMasuk: edu.tahunMasuk,
          tahunLulus: edu.tahunLulus?.isNotEmpty == true ? edu.tahunLulus : null,
        );
      }
      for (final job in _jobs) {
        await _employeeService.addJob(
          employeeId: employeeId,
          namaPerusahaan: job.namaPerusahaan,
          jabatan: job.jabatan,
          tahunMasuk: job.tahunMasuk,
          tahunKeluar: job.tahunKeluar?.isNotEmpty == true ? job.tahunKeluar : null,
        );
      }
      for (final fam in _families) {
        await _employeeService.addFamily(
          employeeId: employeeId,
          hubungan: fam.hubungan,
          nama: fam.nama,
          tanggalLahir: fam.tanggalLahir,
        );
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Anggota berhasil ditambahkan')),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(0),
        child: Container(color: Colors.white),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Tambah Anggota',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                    color: Colors.blueGrey.shade900,
                  ),
                ),
                const SizedBox(height: 4),
                Divider(color: Colors.blueGrey.shade200),
                const SizedBox(height: 12),
                const Text(
                  'Data Pribadi',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: Colors.blueGrey,
                  ),
                ),
                const SizedBox(height: 12),
                _label('Nama lengkap'),
                _textField(
                  controller: _namaController,
                  hint: 'Budi Santoso',
                  validator: (v) => v == null || v.trim().isEmpty ? 'Nama wajib diisi' : null,
                ),
                const SizedBox(height: 12),
                _label('NIK'),
                _textField(
                  controller: _nikController,
                  hint: '3271038596738564',
                  keyboardType: TextInputType.number,
                  validator: (v) => v == null || v.trim().isEmpty ? 'NIK wajib diisi' : null,
                ),
                const SizedBox(height: 12),
                _label('Tempat lahir'),
                _textField(
                  controller: _tempatLahirController,
                  hint: 'Tangerang',
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
                _label('Foto (URL)'),
                _textField(
                  controller: _fotoController,
                  hint: 'https://example.com/foto.jpg',
                ),
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
                          onDelete: () => setState(() => _educations.removeAt(e.key)),
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
                          onDelete: () => setState(() => _jobs.removeAt(e.key)),
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
                              ? _formatDate(e.value.tanggalLahir!)
                              : 'Tanggal lahir tidak diisi',
                          onDelete: () => setState(() => _families.removeAt(e.key)),
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
      ),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        currentIndex: 0,
        onTap: (idx) async {
          if (idx == 1) {
            Navigator.of(context).pushAndRemoveUntil(
              _noAnimationRoute(const HomePage()),
              (route) => false,
            );
          } else if (idx == 2) {
            Navigator.pushReplacement(
              context,
              _noAnimationRoute(const SettingsPage()),
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
            onPressed: () {
              if (!formKey.currentState!.validate()) return;
              setState(() {
                _educations.add(
                  _EducationEntry(
                    jenjang: jenjangCtrl.text.trim(),
                    namaSekolah: sekolahCtrl.text.trim(),
                    tahunMasuk: masukCtrl.text.trim(),
                    tahunLulus: lulusCtrl.text.trim().isEmpty ? null : lulusCtrl.text.trim(),
                  ),
                );
              });
              Navigator.pop(context);
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
            onPressed: () {
              if (!formKey.currentState!.validate()) return;
              setState(() {
                _jobs.add(
                  _JobEntry(
                    namaPerusahaan: perusahaanCtrl.text.trim(),
                    jabatan: jabatanCtrl.text.trim(),
                    tahunMasuk: masukCtrl.text.trim(),
                    tahunKeluar: keluarCtrl.text.trim().isEmpty ? null : keluarCtrl.text.trim(),
                  ),
                );
              });
              Navigator.pop(context);
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
        tanggalCtrl.text = _formatDate(picked);
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
            onPressed: () {
              if (!formKey.currentState!.validate()) return;
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
              setState(() {
                _families.add(
                  _FamilyEntry(
                    hubungan: hubunganCtrl.text.trim(),
                    nama: namaCtrl.text.trim(),
                    tanggalLahir: tanggal,
                  ),
                );
              });
              Navigator.pop(context);
            },
            child: const Text('Simpan'),
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
      await _authService.logout();
      if (!mounted) return;
      Navigator.of(context).pushNamedAndRemoveUntil('/login', (route) => false);
    }
  }
}

class _EducationEntry {
  final String jenjang;
  final String namaSekolah;
  final String tahunMasuk;
  final String? tahunLulus;

  _EducationEntry({
    required this.jenjang,
    required this.namaSekolah,
    required this.tahunMasuk,
    this.tahunLulus,
  });
}

class _JobEntry {
  final String namaPerusahaan;
  final String jabatan;
  final String tahunMasuk;
  final String? tahunKeluar;

  _JobEntry({
    required this.namaPerusahaan,
    required this.jabatan,
    required this.tahunMasuk,
    this.tahunKeluar,
  });
}

class _FamilyEntry {
  final String hubungan;
  final String nama;
  final DateTime? tanggalLahir;

  _FamilyEntry({
    required this.hubungan,
    required this.nama,
    this.tanggalLahir,
  });
}
