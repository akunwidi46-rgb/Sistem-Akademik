import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'login_page.dart';
import 'admin_page.dart';
import 'mahasiswa/jadwal_kuliah_page.dart';
import 'mahasiswa/krs_saya_page.dart';
import 'mahasiswa/nilai_saya_page.dart';
import 'mahasiswa/khs_page.dart';
import 'dosen/jadwal_mengajar_page.dart';
import 'dosen/mahasiswa_kelas_page.dart';
import 'dosen/input_nilai_page.dart';
import 'dosen/persetujuan_krs_dosen_page.dart';
import '../theme/app_theme.dart';

class HomePage extends StatefulWidget {
  final String userRole;
  final String userId;
  final String username;

  const HomePage({
    super.key,
    this.userRole = 'mahasiswa',
    this.userId = '',
    this.username = '',
  });

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  static const String baseUrl = 'http://192.168.43.167/flutter_api/';

  bool _isLoadingProfil = true;
  bool _isChangingPassword = false;
  Map<String, dynamic> _dataProfil = {};
  final TextEditingController _nimController = TextEditingController();
  final TextEditingController _namaController = TextEditingController();
  final TextEditingController _jurusanController = TextEditingController();
  final TextEditingController _alamatController = TextEditingController();

  bool get _hasProfil => _dataProfil.isNotEmpty;

  /// id (primary key) di tabel mahasiswa/dosen -- dipakai untuk fitur KRS,
  /// Nilai, dan Jadwal yang mereferensikan mahasiswa_id/dosen_id (bukan user_id).
  String? get _profileId => _dataProfil['id']?.toString();

  void _profileIdMissing() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Data profil belum lengkap, hubungi admin untuk melengkapi data akun ini.'),
        backgroundColor: Colors.orange,
      ),
    );
  }

  Future<void> _getProfilData() async {
    // Admin tidak memerlukan profil mahasiswa/dosen.
    if (widget.userRole == 'admin') {
      if (mounted) {
        setState(() => _isLoadingProfil = false);
      }
      return;
    }

    try {
      final roleValue = widget.userRole.trim().toLowerCase();
      final userIdValue = widget.userId.trim();
      final usernameValue = widget.username.trim();

      if (roleValue.isEmpty) {
        throw Exception('Role tidak boleh kosong');
      }
      if (userIdValue.isEmpty && usernameValue.isEmpty) {
        throw Exception('User ID atau Username harus diisi');
      }

      // Request body: gunakan parameter yang benar.
      // Catatan: field `nim` sebelumnya diisi dengan username (salah).
      final body = <String, String>{'role': roleValue};
      if (userIdValue.isNotEmpty) body['user_id'] = userIdValue;
      if (usernameValue.isNotEmpty) body['username'] = usernameValue;

      final response = await http.post(
        Uri.parse('${baseUrl}get_profil.php'),
        headers: {'Content-Type': 'application/json; charset=UTF-8'},
        body: jsonEncode(body),
      );

      if (!mounted) return;

      final responseBody = response.body.trim();
      if (responseBody.isEmpty) {
        throw Exception('Server mengirim respons kosong');
      }

      final data = jsonDecode(responseBody);

      Map<String, dynamic> profileData = {};
      if (data is Map<String, dynamic>) {
        if (data['success'] == true) {
          final rawData = data['data'] ?? data;
          if (rawData is Map<String, dynamic>) {
            profileData = rawData;
          } else if (
            rawData is List &&
            rawData.isNotEmpty &&
            rawData.first is Map<String, dynamic>
          ) {
            profileData = Map<String, dynamic>.from(rawData.first as Map<String, dynamic>);
          }
        } else if (data.containsKey('nim') || data.containsKey('nama') || data.containsKey('jurusan') || data.containsKey('alamat') || data.containsKey('nidn')) {
          // Beberapa backend mengirim langsung field profil tanpa wrapper.
          profileData = data;
        } else if (data.isNotEmpty && data.values.first is Map<String, dynamic>) {
          profileData = Map<String, dynamic>.from(data.values.first as Map<String, dynamic>);
        }
      } else if (data is List && data.isNotEmpty && data.first is Map<String, dynamic>) {
        profileData = Map<String, dynamic>.from(data.first as Map<String, dynamic>);
      }

      setState(() {
        _dataProfil = profileData;
        _isiControllerProfil();
        _isLoadingProfil = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoadingProfil = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal memuat profil: $e')),
      );
    }
  }

  void _isiControllerProfil() {
    _nimController.text = _dataProfil['nim'] ?? widget.username;
    _namaController.text = _dataProfil['nama'] ?? '';
    _jurusanController.text = _dataProfil['jurusan'] ?? '';
    _alamatController.text = _dataProfil['alamat'] ?? '';
  }

  Future<void> _gantiPasswordMahasiswa() async {
    final controller = TextEditingController();
    final passwordBaru = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Ubah Password'),
        content: TextField(
          controller: controller,
          obscureText: true,
          decoration: const InputDecoration(
            labelText: 'Password Baru',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Batal')),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, controller.text.trim()),
            child: const Text('Simpan'),
          ),
        ],
      ),
    );

    if (passwordBaru == null || passwordBaru.isEmpty) return;

    setState(() => _isChangingPassword = true);

    try {
      final response = await http.post(
        Uri.parse('${baseUrl}change_password.php'),
        headers: {'Content-Type': 'application/json; charset=UTF-8'},
        body: jsonEncode({
          'user_id': widget.userId,
          'password': passwordBaru,
        }),
      );

      final data = jsonDecode(response.body);
      if (!mounted) return;

      if (data['success'] == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Password berhasil diubah'), backgroundColor: Colors.green),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(data['message'] ?? 'Gagal mengubah password'), backgroundColor: Colors.red),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal mengubah password: $e'), backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) {
        setState(() => _isChangingPassword = false);
      }
    }
  }

  Widget _profilInfoCard({required IconData icon, required String label, required String value, required Color accent}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.cardBorder),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(color: accent.withOpacity(0.12), borderRadius: BorderRadius.circular(12)),
            child: Icon(icon, color: accent, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: const TextStyle(fontSize: 11.5, color: Color(0xFF9CA3AF), fontWeight: FontWeight.w600)),
                const SizedBox(height: 2),
                Text(value, style: const TextStyle(fontSize: 14.5, color: Color(0xFF1F2937), fontWeight: FontWeight.w600)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMahasiswaProfil() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          Container(
            width: 92,
            height: 92,
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: [AppTheme.accentMahasiswa, AppTheme.primary]),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.person, size: 46, color: Colors.white),
          ),
          const SizedBox(height: 24),
          _profilInfoCard(
            icon: Icons.badge_outlined,
            label: 'NIM',
            value: _dataProfil['nim'] ?? (widget.username.isNotEmpty ? widget.username : 'Belum diatur'),
            accent: AppTheme.accentMahasiswa,
          ),
          _profilInfoCard(
            icon: Icons.person_outline,
            label: 'Nama Lengkap',
            value: _dataProfil['nama'] ?? 'Belum diatur',
            accent: AppTheme.accentMahasiswa,
          ),
          _profilInfoCard(
            icon: Icons.school_outlined,
            label: 'Jurusan',
            value: _dataProfil['jurusan'] ?? 'Belum diatur',
            accent: AppTheme.accentMahasiswa,
          ),
          _profilInfoCard(
            icon: Icons.home_outlined,
            label: 'Alamat',
            value: _dataProfil['alamat'] ?? 'Belum diatur',
            accent: AppTheme.accentMahasiswa,
          ),
        ],
      ),
    );
  }

  Widget _buildProfilDosen() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          Container(
            width: 92,
            height: 92,
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: [AppTheme.accentDosen, AppTheme.primary]),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.person, size: 46, color: Colors.white),
          ),
          const SizedBox(height: 24),
          _profilInfoCard(
            icon: Icons.fingerprint,
            label: 'NIDN',
            value: _dataProfil['nidn'] ?? (widget.username.isNotEmpty ? widget.username : 'Belum diatur'),
            accent: AppTheme.accentDosen,
          ),
          _profilInfoCard(
            icon: Icons.person_outline,
            label: 'Nama Dosen',
            value: _dataProfil['nama'] ?? 'Belum diatur',
            accent: AppTheme.accentDosen,
          ),
          _profilInfoCard(
            icon: Icons.phone_outlined,
            label: 'Kontak',
            value: _dataProfil['kontak'] ?? 'Belum diatur',
            accent: AppTheme.accentDosen,
          ),
        ],
      ),
    );
  }

  // Kartu menu dashboard sekarang dipakai dari komponen bersama
  // DashboardMenuTile (lib/theme/app_theme.dart) supaya tampilannya
  // konsisten dengan dashboard Admin.

  Widget _buildDashboardMahasiswa(VoidCallback logout) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard Mahasiswa'),
        actions: [
          IconButton(onPressed: logout, icon: const Icon(Icons.logout)),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            DashboardHeader(
              title: 'Halo, ${_dataProfil['nama'] ?? widget.username}',
              subtitle: 'Kelola KRS dan pantau nilai kuliahmu',
              icon: Icons.school_outlined,
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
                  title: 'Profil',
                  icon: Icons.badge_outlined,
                  accentColor: AppTheme.accentMahasiswa,
                  onTap: () => showDialog(
                    context: context,
                    builder: (_) => AlertDialog(
                      title: const Text('Profil'),
                      content: SizedBox(width: 520, child: _buildMahasiswaProfil()),
                    ),
                  ),
                ),
                DashboardMenuTile(
                  title: 'KRS Saya',
                  icon: Icons.fact_check_outlined,
                  accentColor: AppTheme.accentKrs,
                  onTap: () {
                    final id = _profileId;
                    if (id == null) return _profileIdMissing();
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => KrsSayaPage(
                          mahasiswaId: id,
                          nama: _dataProfil['nama'] ?? widget.username,
                          nim: _dataProfil['nim'] ?? widget.username,
                          jurusan: _dataProfil['jurusan'] ?? '-',
                        ),
                      ),
                    );
                  },
                ),
                DashboardMenuTile(
                  title: 'KHS',
                  icon: Icons.school_outlined,
                  accentColor: AppTheme.accentNilai,
                  onTap: () {
                    final id = _profileId;
                    if (id == null) return _profileIdMissing();
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => KhsPage(
                          mahasiswaId: id,
                          nama: _dataProfil['nama'] ?? widget.username,
                          nim: _dataProfil['nim'] ?? widget.username,
                          jurusan: _dataProfil['jurusan'] ?? '-',
                        ),
                      ),
                    );
                  },
                ),
                DashboardMenuTile(
                  title: 'Nilai Saya',
                  icon: Icons.grade_outlined,
                  accentColor: AppTheme.accentNilai,
                  onTap: () {
                    final id = _profileId;
                    if (id == null) return _profileIdMissing();
                    Navigator.push(context, MaterialPageRoute(builder: (_) => NilaiSayaPage(mahasiswaId: id)));
                  },
                ),
                DashboardMenuTile(
                  title: 'Jadwal / Mata Kuliah',
                  icon: Icons.schedule_outlined,
                  accentColor: AppTheme.accentJadwal,
                  onTap: () {
                    final id = _profileId;
                    if (id == null) return _profileIdMissing();
                    Navigator.push(context, MaterialPageRoute(builder: (_) => JadwalKuliahPage(mahasiswaId: id)));
                  },
                ),
                DashboardMenuTile(
                  title: 'Logout',
                  icon: Icons.logout_outlined,
                  accentColor: AppTheme.danger,
                  onTap: logout,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDashboardDosen(VoidCallback logout) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard Dosen'),
        actions: [
          IconButton(onPressed: logout, icon: const Icon(Icons.logout)),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            DashboardHeader(
              title: 'Halo, ${_dataProfil['nama'] ?? widget.username}',
              subtitle: 'Kelola kelas, nilai, dan persetujuan KRS',
              icon: Icons.badge_outlined,
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
                  title: 'Profil',
                  icon: Icons.person_outline,
                  accentColor: AppTheme.accentDosen,
                  onTap: () => showDialog(
                    context: context,
                    builder: (_) => AlertDialog(
                      title: const Text('Profil'),
                      content: SizedBox(width: 520, child: _buildProfilDosen()),
                    ),
                  ),
                ),
                DashboardMenuTile(
                  title: 'Mahasiswa',
                  icon: Icons.people_alt_outlined,
                  accentColor: AppTheme.accentMahasiswa,
                  onTap: () {
                    final id = _profileId;
                    if (id == null) return _profileIdMissing();
                    Navigator.push(context, MaterialPageRoute(builder: (_) => MahasiswaKelasPage(dosenId: id)));
                  },
                ),
                DashboardMenuTile(
                  title: 'Input Nilai',
                  icon: Icons.edit_note_outlined,
                  accentColor: AppTheme.accentNilai,
                  onTap: () {
                    final id = _profileId;
                    if (id == null) return _profileIdMissing();
                    Navigator.push(context, MaterialPageRoute(builder: (_) => InputNilaiPage(dosenId: id)));
                  },
                ),
                DashboardMenuTile(
                  title: 'Jadwal Mengajar',
                  icon: Icons.schedule_outlined,
                  accentColor: AppTheme.accentJadwal,
                  onTap: () {
                    final id = _profileId;
                    if (id == null) return _profileIdMissing();
                    Navigator.push(context, MaterialPageRoute(builder: (_) => JadwalMengajarPage(dosenId: id)));
                  },
                ),
                DashboardMenuTile(
                  title: 'Persetujuan KRS',
                  icon: Icons.fact_check_outlined,
                  accentColor: AppTheme.accentKrs,
                  onTap: () {
                    final id = _profileId;
                    if (id == null) return _profileIdMissing();
                    Navigator.push(context, MaterialPageRoute(builder: (_) => PersetujuanKrsDosenPage(dosenId: id)));
                  },
                ),
                DashboardMenuTile(
                  title: 'Logout',
                  icon: Icons.logout_outlined,
                  accentColor: AppTheme.danger,
                  onTap: logout,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }


  @override
  void initState() {
    super.initState();
    _getProfilData();
  }

  void logout() {
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const LoginPage()),
      (route) => false,
    );
  }

  @override
  void dispose() {
    _nimController.dispose();
    _namaController.dispose();
    _jurusanController.dispose();
    _alamatController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.userRole == 'admin') {
      return AdminPage(userId: widget.userId, username: widget.username.isNotEmpty ? widget.username : widget.userRole);
    }

    if (_isLoadingProfil) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (widget.userRole == 'mahasiswa') {
      // FIX: sebelumnya method ini langsung return halaman profil polos
      // (tanpa menu KRS/Nilai/Jadwal), sehingga _buildDashboardMahasiswa()
      // yang berisi menu lengkap tidak pernah terpakai sama sekali.
      return _buildDashboardMahasiswa(logout);
    }

    if (widget.userRole == 'dosen') {
      // FIX: sama seperti mahasiswa di atas -- pakai dashboard lengkap,
      // bukan halaman profil polos.
      return _buildDashboardDosen(logout);
    }

    return const Scaffold(
      body: Center(child: Text('Role Tidak Dikenali')),
    );
  }
}
