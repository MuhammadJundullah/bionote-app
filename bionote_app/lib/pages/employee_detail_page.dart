import 'package:flutter/material.dart';

import 'edit_employee_page.dart';

class EmployeeDetailPage extends StatelessWidget {
  final Map<String, dynamic> employee;

  const EmployeeDetailPage({super.key, required this.employee});

  @override
  Widget build(BuildContext context) {
    final pendidikan = (employee['pendidikan'] as List<dynamic>? ?? []).cast<Map<String, dynamic>>();
    final pekerjaan = (employee['pekerjaan'] as List<dynamic>? ?? []).cast<Map<String, dynamic>>();
    final keluarga = (employee['keluarga'] as List<dynamic>? ?? []).cast<Map<String, dynamic>>();

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.black87),
          onPressed: () => Navigator.pop(context),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Details Anggota',
          style: TextStyle(
            color: Colors.black87,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.edit, color: Colors.black87),
            onPressed: () async {
              final updated = await Navigator.push<bool>(
                context,
                MaterialPageRoute(
                  builder: (context) => EditEmployeePage(employee: employee),
                ),
              );
              if (updated == true && Navigator.canPop(context)) {
                Navigator.pop(context, true);
              }
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _divider(),
            const SizedBox(height: 12),
            _sectionTitle('Data Pribadi'),
            _textRow('Nama lengkap', employee['namaLengkap']),
            _textRow('NIK', employee['nik']),
            _textRow(
              'Tempat, Tanggal lahir',
              '${employee['tempatLahir'] ?? '-'}, ${_formatDate(employee['tanggalLahir'])}',
            ),
            _textRow(
              'Jenis kelamin',
              (employee['jenisKelamin'] == 'L') ? 'Laki-laki' : 'Perempuan',
            ),
            _textRow('Alamat', employee['alamat']),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 8),
                const Text(
                  'Foto :',
                  style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
                ),
                const SizedBox(height: 8),
                _photo(employee['foto'] as String?),
              ],
            ),
            const SizedBox(height: 20),
            _sectionTitle('Data Pendidikan'),
            if (pendidikan.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 4),
                child: Text('Belum ada data pendidikan', style: TextStyle(color: Colors.grey)),
              )
            else
              ...pendidikan.map((p) => _bullet(
                    '${p['jenjang']} - ${p['namaSekolah']} (Masuk ${p['tahunMasuk']}${p['tahunLulus'] != null ? ', Lulus ${p['tahunLulus']}' : ''})',
                  )),
            const SizedBox(height: 20),
            _sectionTitle('Data Pekerjaan'),
            if (pekerjaan.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 4),
                child: Text('Belum ada data pekerjaan', style: TextStyle(color: Colors.grey)),
              )
            else
              ...pekerjaan.map((p) => _bullet(
                    '${p['namaPerusahaan']} - ${p['jabatan']} (Masuk ${p['tahunMasuk']}${p['tahunKeluar'] != null ? ', Keluar ${p['tahunKeluar']}' : ''})',
                  )),
            const SizedBox(height: 20),
            _sectionTitle('Data Keluarga'),
            if (keluarga.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 4),
                child: Text('Belum ada data keluarga', style: TextStyle(color: Colors.grey)),
              )
            else
              ...keluarga.map((p) => _bullet(
                    '${p['hubungan']} - ${p['nama']}${p['tanggalLahir'] != null ? ' (${_formatDate(p['tanggalLahir'])})' : ''}',
                  )),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _divider() => Divider(color: Colors.blueGrey.shade200);

  Widget _sectionTitle(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        text,
        style: const TextStyle(
          fontWeight: FontWeight.w700,
          fontSize: 16,
          color: Color(0xFF243141),
        ),
      ),
    );
  }

  Widget _textRow(String label, String? value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: RichText(
        text: TextSpan(
          style: const TextStyle(color: Colors.black87, fontSize: 14),
          children: [
            TextSpan(
              text: '$label : ',
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
            TextSpan(text: value?.toString() ?? '-'),
          ],
        ),
      ),
    );
  }

  Widget _bullet(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('• ', style: TextStyle(fontSize: 16)),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }

  Widget _photo(String? url) {
    if (url == null || url.isEmpty) {
      return Container(
        height: 140,
        width: 140,
        decoration: BoxDecoration(
          color: Colors.grey.shade200,
          borderRadius: BorderRadius.circular(10),
        ),
        child: const Icon(Icons.person, size: 64, color: Colors.grey),
      );
    }
    return ClipRRect(
      borderRadius: BorderRadius.circular(10),
      child: Image.network(
        url,
        height: 140,
        width: 140,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => Container(
          height: 140,
          width: 140,
          color: Colors.grey.shade200,
          child: const Icon(Icons.broken_image, size: 64, color: Colors.grey),
        ),
      ),
    );
  }

  String _formatDate(dynamic value) {
    if (value == null) return '-';
    try {
      final date = DateTime.parse(value.toString());
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
    } catch (_) {
      return value.toString();
    }
  }
}
