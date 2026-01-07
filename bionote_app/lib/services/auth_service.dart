import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../config/api.dart';

class AuthService {
  const AuthService();

  Future<Map<String, dynamic>> register({
    required String name,
    required String email,
    required String password,
    String role = 'user',
  }) async {
    final uri = Uri.parse('${ApiConfig.baseUrl}${ApiConfig.registerPath}');
    final response = await http.post(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'name': name,
        'email': email,
        'password': password,
        'role': role,
      }),
    );

    if (response.statusCode == 201) {
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      // Simpan info dasar user (tanpa token)
      await _persistUser(data);
      return data;
    }

    throw _mapError(response);
  }

  Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    final uri = Uri.parse('${ApiConfig.baseUrl}${ApiConfig.loginPath}');
    final response = await http.post(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'email': email, 'password': password}),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      await _persistUser(data);
      return data;
    }

    throw _mapError(response);
  }

  Future<Map<String, dynamic>> uploadUserPhoto({
    required String userId,
    required List<int> bytes,
    required String filename,
    String? mimeType,
  }) async {
    final uri = Uri.parse('${ApiConfig.baseUrl}/users/$userId/photo');
    final request = http.MultipartRequest('POST', uri);
    request.headers['x-user-id'] = userId;
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
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      await _persistUser(data);
      return data;
    }

    throw _mapError(response);
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('user');
  }

  Future<Map<String, dynamic>?> currentUser() async {
    final prefs = await SharedPreferences.getInstance();
    final stored = prefs.getString('user');
    if (stored == null) return null;
    return jsonDecode(stored) as Map<String, dynamic>;
  }

  Future<void> _persistUser(Map<String, dynamic> data) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('user', jsonEncode(data));
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
}
