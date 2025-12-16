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
}
