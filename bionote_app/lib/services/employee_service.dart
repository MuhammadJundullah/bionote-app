import 'dart:convert';

import 'package:http/http.dart' as http;

import '../config/api.dart';

class EmployeeService {
  const EmployeeService();

  Future<List<Map<String, dynamic>>> fetchEmployees() async {
    final uri = Uri.parse('${ApiConfig.baseUrl}/employees');
    final response = await http.get(uri);

    if (response.statusCode == 200) {
      final List<dynamic> body = jsonDecode(response.body) as List<dynamic>;
      return body.cast<Map<String, dynamic>>();
    }

    throw Exception('Gagal mengambil data anggota');
  }

  Future<Map<String, dynamic>> createEmployee({
    required String nik,
    required String namaLengkap,
    required String tempatLahir,
    required DateTime tanggalLahir,
    required String jenisKelamin,
    required String alamat,
    String? foto,
    required String createdById,
    String? userId,
  }) async {
    final uri = Uri.parse('${ApiConfig.baseUrl}/employees');
    final body = {
      'nik': nik,
      'namaLengkap': namaLengkap,
      'tempatLahir': tempatLahir,
      'tanggalLahir': tanggalLahir.toIso8601String(),
      'jenisKelamin': jenisKelamin,
      'alamat': alamat,
      'foto': foto,
      'createdById': createdById,
      'userId': userId,
    }..removeWhere((key, value) => value == null);

    final response = await http.post(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(body),
    );

    if (response.statusCode == 201) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    }

    throw _mapError(response);
  }

  Future<Map<String, dynamic>> updateEmployee({
    required String id,
    String? nik,
    String? namaLengkap,
    String? tempatLahir,
    DateTime? tanggalLahir,
    String? jenisKelamin,
    String? alamat,
    String? foto,
    String? userId,
    String? createdById,
  }) async {
    final uri = Uri.parse('${ApiConfig.baseUrl}/employees/$id');
    final body = {
      'nik': nik,
      'namaLengkap': namaLengkap,
      'tempatLahir': tempatLahir,
      'tanggalLahir': tanggalLahir?.toIso8601String(),
      'jenisKelamin': jenisKelamin,
      'alamat': alamat,
      'foto': foto,
      'userId': userId,
      'createdById': createdById,
    }..removeWhere((key, value) => value == null);

    final response = await http.put(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(body),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    }

    throw _mapError(response);
  }

  Future<Map<String, dynamic>> addEducation({
    required String employeeId,
    required String jenjang,
    required String namaSekolah,
    required String tahunMasuk,
    String? tahunLulus,
  }) async {
    final uri = Uri.parse('${ApiConfig.baseUrl}/employees/$employeeId/pendidikan');
    final response = await http.post(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'jenjang': jenjang,
        'namaSekolah': namaSekolah,
        'tahunMasuk': tahunMasuk,
        'tahunLulus': tahunLulus,
      }..removeWhere((key, value) => value == null)),
    );
    if (response.statusCode != 201) throw _mapError(response);
    return jsonDecode(response.body) as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> addJob({
    required String employeeId,
    required String namaPerusahaan,
    required String jabatan,
    required String tahunMasuk,
    String? tahunKeluar,
  }) async {
    final uri = Uri.parse('${ApiConfig.baseUrl}/employees/$employeeId/pekerjaan');
    final response = await http.post(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'namaPerusahaan': namaPerusahaan,
        'jabatan': jabatan,
        'tahunMasuk': tahunMasuk,
        'tahunKeluar': tahunKeluar,
      }..removeWhere((key, value) => value == null)),
    );
    if (response.statusCode != 201) throw _mapError(response);
    return jsonDecode(response.body) as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> addFamily({
    required String employeeId,
    required String hubungan,
    required String nama,
    DateTime? tanggalLahir,
  }) async {
    final uri = Uri.parse('${ApiConfig.baseUrl}/employees/$employeeId/keluarga');
    final response = await http.post(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'hubungan': hubungan,
        'nama': nama,
        'tanggalLahir': tanggalLahir?.toIso8601String(),
      }..removeWhere((key, value) => value == null)),
    );
    if (response.statusCode != 201) throw _mapError(response);
    return jsonDecode(response.body) as Map<String, dynamic>;
  }

  Future<void> deleteEducation({
    required String employeeId,
    required String id,
  }) async {
    final uri = Uri.parse('${ApiConfig.baseUrl}/employees/$employeeId/pendidikan/$id');
    final response = await http.delete(uri);
    if (response.statusCode != 204) throw _mapError(response);
  }

  Future<void> deleteJob({
    required String employeeId,
    required String id,
  }) async {
    final uri = Uri.parse('${ApiConfig.baseUrl}/employees/$employeeId/pekerjaan/$id');
    final response = await http.delete(uri);
    if (response.statusCode != 204) throw _mapError(response);
  }

  Future<void> deleteFamily({
    required String employeeId,
    required String id,
  }) async {
    final uri = Uri.parse('${ApiConfig.baseUrl}/employees/$employeeId/keluarga/$id');
    final response = await http.delete(uri);
    if (response.statusCode != 204) throw _mapError(response);
  }

  Exception _mapError(http.Response response) {
    try {
      final body = jsonDecode(response.body) as Map<String, dynamic>;
      final message = body['message'] ?? 'Gagal memproses permintaan';
      return Exception(message);
    } catch (_) {
      return Exception('Gagal memproses permintaan (${response.statusCode})');
    }
  }
}
