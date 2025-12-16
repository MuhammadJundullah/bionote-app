import 'dart:async';
import 'package:flutter/material.dart';
import 'package:biodata_app/pages/login_page.dart';

class SplashScreen extends StatefulWidget {
  @override
  _SplashScreenState createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    // Timer untuk menavigasi ke LoginPage setelah 3 detik
    Timer(Duration(seconds: 3), () {
      // Menggunakan pushReplacement agar pengguna tidak bisa kembali ke splash screen
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => const LoginPage()),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Mengatur warna latar belakang ke warna biru dari gambar
      // Anda bisa menyesuaikan kode warna ini jika perlu
      backgroundColor: Color(0xFF0077B6), 
      body: Center(
        child: Text(
          'BioNote.',
          style: TextStyle(
            fontSize: 40.0, // Ukuran teks yang cukup besar
            fontWeight: FontWeight.bold, // Teks tebal
            color: Colors.white, // Warna teks putih
            letterSpacing: 1.2, // Sedikit jarak antar huruf untuk estetika
          ),
        ),
      ),
    );
  }
}
