import 'package:flutter/material.dart';

import '../services/auth_service.dart';
import '../services/employee_service.dart';
import '../utils/image_url.dart';
import 'add_employee_page.dart';
import 'employee_detail_page.dart';
import 'settings_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final _employeeService = const EmployeeService();
  final _authService = const AuthService();
  final _searchController = TextEditingController();
  List<Map<String, dynamic>> _employees = [];
  bool _loading = true;
  String? _error;
  String? _userId;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final user = await _authService.currentUser();
      final uid = user?['id']?.toString();
      if (uid == null) {
        setState(() => _error = 'User tidak ditemukan, silakan login ulang');
        return;
      }
      final data = await _employeeService.fetchEmployees(userId: uid);
      setState(() {
        _userId = uid;
        _employees = data;
      });
    } catch (e) {
      setState(() => _error = e.toString().replaceFirst('Exception: ', ''));
    } finally {
      setState(() => _loading = false);
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  PageRouteBuilder<T> _noAnimationRoute<T>(Widget page) {
    return PageRouteBuilder<T>(
      pageBuilder: (_, __, ___) => page,
      transitionDuration: Duration.zero,
      reverseTransitionDuration: Duration.zero,
    );
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _employees.where((emp) {
      final q = _searchController.text.toLowerCase();
      final nama = (emp['namaLengkap'] ?? '').toString().toLowerCase();
      final nik = (emp['nik'] ?? '').toString().toLowerCase();
      final belongsToUser = _userId == null ||
          emp['createdById']?.toString() == _userId ||
          emp['userId']?.toString() == _userId;
      return belongsToUser && (nama.contains(q) || nik.contains(q));
    }).toList();

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(56),
        child: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          title: const Text(
            'BioNote',
            style: TextStyle(
              color: Colors.black87,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 8),
              Text(
                'Daftar Anggota',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                  color: Colors.blueGrey.shade900,
                ),
              ),
              const SizedBox(height: 16),
              _buildSearch(),
              const SizedBox(height: 12),
              Expanded(
                child: _loading
                    ? const Center(child: CircularProgressIndicator())
                    : _error != null
                        ? _ErrorState(message: _error!, onRetry: _load)
                        : _EmployeeGrid(
                            employees: filtered,
                            onRefresh: _load,
                          ),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: 1,
        type: BottomNavigationBarType.fixed,
        onTap: (idx) async {
          if (idx == 0) {
            final created = await Navigator.push<bool>(
              context,
              _noAnimationRoute(const AddEmployeePage()),
            );
            if (created == true) {
              _load();
            }
          } else if (idx == 2) {
            _openSettings();
          } else if (idx == 3) {
            _confirmLogout();
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

  Widget _buildSearch() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: Colors.blueGrey.shade100),
        boxShadow: [
          BoxShadow(
            color: Colors.blueGrey.withOpacity(0.08),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: TextField(
        controller: _searchController,
        onChanged: (_) => setState(() {}),
        decoration: InputDecoration(
          hintText: 'Search',
          contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
          border: InputBorder.none,
          suffixIcon: Icon(Icons.search, color: Colors.blueGrey.shade400),
        ),
      ),
    );
  }

  void _openSettings() {
    Navigator.pushReplacement(
      context,
      _noAnimationRoute(const SettingsPage()),
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

class _EmployeeGrid extends StatelessWidget {
  final List<Map<String, dynamic>> employees;
  final VoidCallback onRefresh;

  const _EmployeeGrid({required this.employees, required this.onRefresh});

  @override
  Widget build(BuildContext context) {
    if (employees.isEmpty) {
      return const Center(child: Text('Belum ada anggota'));
    }

    return GridView.builder(
      padding: const EdgeInsets.only(top: 4),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
        childAspectRatio: 1,
      ),
      itemCount: employees.length,
      itemBuilder: (context, index) {
        final emp = employees[index];
        final nama = emp['namaLengkap'] ?? 'Tanpa nama';
        final foto = emp['foto'] as String?;
        return GestureDetector(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => EmployeeDetailPage(employee: emp),
              ),
            ).then((value) {
              if (value == true) {
                onRefresh();
              }
            });
          },
          child: _EmployeeCard(name: nama.toString(), photoUrl: foto),
        );
      },
    );
  }
}

class _EmployeeCard extends StatelessWidget {
  final String name;
  final String? photoUrl;

  const _EmployeeCard({required this.name, this.photoUrl});

  @override
  Widget build(BuildContext context) {
    final resolvedPhotoUrl = resolveImageUrl(photoUrl);
    return ClipRRect(
      borderRadius: BorderRadius.circular(10),
      child: Stack(
        children: [
          Container(
            decoration: BoxDecoration(
              color: Colors.blueGrey.shade200,
              image: resolvedPhotoUrl != null
                  ? DecorationImage(
                      image: NetworkImage(resolvedPhotoUrl),
                      fit: BoxFit.cover,
                    )
                  : null,
            ),
          ),
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.bottomCenter,
                end: Alignment.topCenter,
                colors: [
                  Colors.black.withOpacity(0.6),
                  Colors.black.withOpacity(0.0),
                ],
              ),
            ),
          ),
          Positioned(
            left: 8,
            right: 8,
            bottom: 8,
            child: Text(
              name,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w700,
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _ErrorState({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(message, textAlign: TextAlign.center),
          const SizedBox(height: 12),
          ElevatedButton(
            onPressed: onRetry,
            child: const Text('Coba lagi'),
          ),
        ],
      ),
    );
  }
}
