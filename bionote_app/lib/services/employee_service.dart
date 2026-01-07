import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';

import '../config/api.dart';

class EmployeeService {
  const EmployeeService();

  Future<List<Map<String, dynamic>>> fetchEmployees({String? userId}) async {
    final uri = Uri.parse('${ApiConfig.baseUrl}/employees');
    final headers = _headers(userId: userId);
    final response = await http.get(uri, headers: headers);

    if (response.statusCode == 200) {
      final List<dynamic> body = jsonDecode(response.body) as List<dynamic>;
      final data = body.cast<Map<String, dynamic>>();
      if (userId == null) return data;
      // Fallback filter jika backend belum menerapkan filter per user.
      return data.where((e) {
        final createdBy = e['createdById']?.toString();
        final owner = e['userId']?.toString();
        return createdBy == userId || owner == userId;
      }).toList();
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
    final headers = _headers(userId: userId ?? createdById);
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
      headers: headers,
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
    final headers = _headers(userId: createdById ?? userId);
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

  Future<Map<String, dynamic>> uploadEmployeePhoto({
    required String id,
    required List<int> bytes,
    required String filename,
    String? mimeType,
    required String userId,
  }) async {
    final uri = Uri.parse('${ApiConfig.baseUrl}/employees/$id/photo');
    final request = http.MultipartRequest('POST', uri);
    request.headers.addAll(_multipartHeaders(userId: userId));
    final mediaType = _resolveMediaType(filename, mimeType);
    request.files.add(
      http.MultipartFile.fromBytes(
        'foto',
        bytes,
        filename: filename,
        contentType: mediaType,
      ),
    );

    final streamed = await request.send();
    final response = await http.Response.fromStream(streamed);
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
    String? userId,
  }) async {
    final uri = Uri.parse('${ApiConfig.baseUrl}/employees/$employeeId/pendidikan');
    final response = await http.post(
      uri,
      headers: _headers(userId: userId),
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
    String? userId,
  }) async {
    final uri = Uri.parse('${ApiConfig.baseUrl}/employees/$employeeId/pekerjaan');
    final response = await http.post(
      uri,
      headers: _headers(userId: userId),
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
    String? userId,
  }) async {
    final uri = Uri.parse('${ApiConfig.baseUrl}/employees/$employeeId/keluarga');
    final response = await http.post(
      uri,
      headers: _headers(userId: userId),
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
    String? userId,
  }) async {
    final uri = Uri.parse('${ApiConfig.baseUrl}/employees/$employeeId/pendidikan/$id');
    final response = await http.delete(uri, headers: _headers(userId: userId));
    if (response.statusCode != 204) throw _mapError(response);
  }

  Future<void> deleteJob({
    required String employeeId,
    required String id,
    String? userId,
  }) async {
    final uri = Uri.parse('${ApiConfig.baseUrl}/employees/$employeeId/pekerjaan/$id');
    final response = await http.delete(uri, headers: _headers(userId: userId));
    if (response.statusCode != 204) throw _mapError(response);
  }

  Future<void> deleteFamily({
    required String employeeId,
    required String id,
    String? userId,
  }) async {
    final uri = Uri.parse('${ApiConfig.baseUrl}/employees/$employeeId/keluarga/$id');
    final response = await http.delete(uri, headers: _headers(userId: userId));
    if (response.statusCode != 204) throw _mapError(response);
  }

  Future<void> deleteEmployee({required String id, String? userId}) async {
    final uri = Uri.parse('${ApiConfig.baseUrl}/employees/$id');
    final response = await http.delete(uri, headers: _headers(userId: userId));
    if (response.statusCode != 204) throw _mapError(response);
  }

  Map<String, String> _headers({String? userId}) {
    return {
      'Content-Type': 'application/json',
      if (userId != null) 'x-user-id': userId,
    };
  }

  Map<String, String> _multipartHeaders({String? userId}) {
    return {
      if (userId != null) 'x-user-id': userId,
    };
  }

  MediaType _resolveMediaType(String filename, String? mimeType) {
    if (mimeType != null && mimeType.contains('/')) {
      final parts = mimeType.split('/');
      if (parts.length == 2) {
        return MediaType(parts[0], parts[1]);
      }
    }
    final lower = filename.toLowerCase();
    if (lower.endsWith('.png')) return MediaType('image', 'png');
    if (lower.endsWith('.gif')) return MediaType('image', 'gif');
    if (lower.endsWith('.webp')) return MediaType('image', 'webp');
    return MediaType('image', 'jpeg');
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
