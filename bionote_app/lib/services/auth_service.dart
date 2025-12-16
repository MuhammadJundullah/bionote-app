import 'dart:convert';

import 'package:http/http.dart' as http;
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
}
