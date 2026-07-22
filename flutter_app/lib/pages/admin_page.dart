import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import 'list_dosen_page.dart';
import 'list_mahasiswa_page.dart';
import 'login_page.dart';
import 'tambah_dosen_page.dart';
import 'tambah_mahasiswa_page.dart';
import 'placeholder_page.dart';

import 'admin/mata_kuliah_page.dart';
import 'admin/jadwal_page.dart';
import 'admin/persetujuan_krs_page.dart';
import 'admin/nilai_page.dart';
import '../theme/app_theme.dart';




/// Admin Dashboard Page
///
/// Menampilkan dashboard utama untuk admin dengan menu berbasis Card.
/// - Data Mahasiswa
/// - Data Dosen
/// - Mata Kuliah (placeholder)
/// - Jadwal (placeholder)
/// - Persetujuan KRS (placeholder)
/// - Nilai (placeholder)
/// - User (dialog)
///
/// Fitur tambahan:
/// - Ubah password admin (AppBar lock icon)
/// - Logout (AppBar logout icon)
class AdminPage extends StatefulWidget {
  final String userId;
  final String username;

  const AdminPage({
    super.key,
    this.userId = '',
    this.username = '',
  });

  @override
  State<AdminPage> createState() => _AdminPageState();
}

class _AdminPageState extends State<AdminPage> {
  /// Base URL untuk API
  static const String baseUrl = 'http://192.168.43.167/flutter_api/';

  final TextEditingController _passwordBaruController = TextEditingController();
  bool _isChangingPassword = false;

  Future<void> _ubahPasswordAdmin() async {
    final passwordBaru = _passwordBaruController.text.trim();
    if (passwordBaru.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Password baru wajib diisi'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() => _isChangingPassword = true);

    try {
      final response = await http.post(
        Uri.parse('${baseUrl}change_password.php'),
        body: {
          'user_id': widget.userId.isNotEmpty ? widget.userId : '0',
          'password': passwordBaru,
          'username': widget.username,
        },
      );

      final data = jsonDecode(response.body.trim());
      if (!mounted) return;

      if (data['success'] == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Password berhasil diubah'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(data['message'] ?? 'Gagal mengubah password'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Gagal mengubah password: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) setState(() => _isChangingPassword = false);
    }
  }

  void _showPasswordDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Ubah Password Admin'),
        content: TextField(
          controller: _passwordBaruController,
          obscureText: true,
          decoration: const InputDecoration(
            labelText: 'Password Baru',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: _isChangingPassword ? null : _ubahPasswordAdmin,
            child: _isChangingPassword
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Simpan'),
          ),
        ],
      ),
    );
  }

  void _logout() {
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const LoginPage()),
      (route) => false,
    );
  }

  // Kartu menu dashboard sekarang dipakai dari komponen bersama
  // DashboardMenuTile (lib/theme/app_theme.dart) supaya tampilannya
  // konsisten dengan dashboard Dosen & Mahasiswa.

  void _showUserMenu() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Kelola User'),
        content: const Text('Pilih aksi untuk mengelola user'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const TambahMahasiswaPage()),
              );
            },
            child: const Text('Tambah Mahasiswa'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const TambahDosenPage()),
              );
            },
            child: const Text('Tambah Dosen'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Tutup'),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _passwordBaruController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard Admin'),
        actions: [
          IconButton(
            tooltip: 'Ubah Password',
            onPressed: _showPasswordDialog,
            icon: const Icon(Icons.lock_reset),
          ),
          IconButton(
            tooltip: 'Logout',
            onPressed: _logout,
            icon: const Icon(Icons.logout),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            DashboardHeader(
              title: 'Selamat datang, ${widget.username.isNotEmpty ? widget.username : 'Admin'}',
              subtitle: 'Kelola data akademik dari satu tempat',
              icon: Icons.admin_panel_settings_outlined,
            ),
            const SizedBox(height: 20),
            const Text('Menu Utama', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: Color(0xFF1F2937))),
            const SizedBox(height: 12),
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 1.05,
              children: [
                DashboardMenuTile(
                  title: 'Data Mahasiswa',
                  icon: Icons.people_alt_outlined,
                  accentColor: AppTheme.accentMahasiswa,
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ListMahasiswaPage())),
                ),
                DashboardMenuTile(
                  title: 'Data Dosen',
                  icon: Icons.school_outlined,
                  accentColor: AppTheme.accentDosen,
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ListDosenPage())),
                ),
                DashboardMenuTile(
                  title: 'Mata Kuliah',
                  icon: Icons.menu_book_outlined,
                  accentColor: AppTheme.accentMatkul,
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const MataKuliahPage())),
                ),
                DashboardMenuTile(
                  title: 'Jadwal',
                  icon: Icons.schedule_outlined,
                  accentColor: AppTheme.accentJadwal,
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const JadwalPage())),
                ),
                DashboardMenuTile(
                  title: 'Persetujuan KRS',
                  icon: Icons.fact_check_outlined,
                  accentColor: AppTheme.accentKrs,
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const PersetujuanKRSPage())),
                ),
                DashboardMenuTile(
                  title: 'Nilai',
                  icon: Icons.grade_outlined,
                  accentColor: AppTheme.accentNilai,
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const NilaiPage())),
                ),
                DashboardMenuTile(
                  title: 'Kelola User',
                  icon: Icons.person_add_alt_outlined,
                  accentColor: AppTheme.primary,
                  onTap: _showUserMenu,
                ),
                DashboardMenuTile(
                  title: 'Logout',
                  icon: Icons.logout_outlined,
                  accentColor: AppTheme.danger,
                  onTap: _logout,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

