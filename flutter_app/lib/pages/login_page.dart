import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'home_page.dart';
import 'admin_page.dart';
import '../theme/app_theme.dart';
// import '../services/api_client.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  static const String baseUrl = "http://192.168.43.167/flutter_api/";

  final TextEditingController username = TextEditingController();
  final TextEditingController password = TextEditingController();
  
  // ====== Tambahan Variabel Dropdown Role ======
  String selectedRole = 'mahasiswa'; // Default pilihan awal
  final List<String> rolesList = ['admin', 'mahasiswa', 'dosen'];

  bool apiConnected = false;
  bool isLoading = false;
  Timer? timer;

  // ==========================
  // CLEAR FORM
  // ==========================
  void clearLogin() {
    username.clear();
    password.clear();
  }

  // ==========================
  // CEK API
  // ==========================
  Future<bool> checkStatusApi() async {
    try {
      final response = await http.get(Uri.parse("${baseUrl}cek_koneksi.php"));
      if (response.statusCode == 200) {
        var data = jsonDecode(response.body);
        bool status = data["status"] == true;
        if (mounted) {
          setState(() {
            apiConnected = status;
          });
        }
        return status;
      }
      if (mounted) {
        setState(() {
          apiConnected = false;
        });
      }
      return false;
    } catch (e) {
      if (mounted) {
        setState(() {
          apiConnected = false;
        });
      }
      return false;
    }
  }

  // ==========================
  // LOGIN 
  // ==========================
  Future login() async {
    if (username.text.trim().isEmpty || password.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Username dan Password wajib diisi"),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    bool apiAktif = await checkStatusApi();
    if (!mounted) return;

    if (!apiAktif) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Server API Tidak Terhubung"),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      isLoading = true;
    });

    try {
      final loginUsername = username.text.trim();
      final response = await http.post(
        Uri.parse("${baseUrl}login.php"),
        body: {
          "username": loginUsername,
          "password": password.text.trim(),
          "role": selectedRole,
        },
      );

      if (response.statusCode != 200) {
        throw Exception('Server login mengembalikan kode ${response.statusCode}');
      }

      var data = jsonDecode(response.body);
      if (!mounted) return;

      if (data["success"] == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Login Berhasil"),
            backgroundColor: Colors.green,
          ),
        );

        String userRole = data["role"]?.toString().toLowerCase() ?? "mahasiswa";
        String userId = data["user_id"]?.toString().trim() ?? '';
        if (userId.isEmpty) {
          userId = loginUsername;
        }

        clearLogin();

        Future.delayed(const Duration(seconds: 1), () {
          if (mounted) {
            if (userRole == "admin") {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (_) => AdminPage(
                    userId: userId,
                    username: loginUsername,
                  ),
                ),
              );
            } else {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (_) => HomePage(
                    userRole: userRole,
                    userId: userId,
                    username: loginUsername,
                  ),
                ),
              );
            }
          }
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(data["message"] ?? "Username, Password, atau Role Salah"),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: $e"), backgroundColor: Colors.red),
      );
    }

    if (mounted) {
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> _changePassword(String usernameValue, String oldPassword, String newPassword) async {
    if (usernameValue.trim().isEmpty || oldPassword.trim().isEmpty || newPassword.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Username, password lama, dan password baru wajib diisi'), backgroundColor: Colors.orange),
      );
      return;
    }

    setState(() {
      isLoading = true;
    });

    try {
      final response = await http
          .post(
            Uri.parse('${baseUrl}change_password.php'),
            headers: {
              'Content-Type': 'application/x-www-form-urlencoded; charset=UTF-8',
              'Accept': 'application/json',
            },
            body: {
              'username': usernameValue.trim(),
              'password': oldPassword.trim(),
              'old_password': oldPassword.trim(),
              'new_password': newPassword.trim(),
              'role': selectedRole,
            },
          )
          .timeout(const Duration(seconds: 15));

      if (!mounted) return;

      if (response.statusCode != 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal terhubung ke server: ${response.statusCode}'), backgroundColor: Colors.red),
        );
        return;
      }

      final body = response.body.trim();
      if (body.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Respons server kosong'), backgroundColor: Colors.red),
        );
        return;
      }

      final data = jsonDecode(body);
      if (data['success'] == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Password berhasil diubah'), backgroundColor: Colors.green),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(data['message'] ?? 'Gagal mengubah password'), backgroundColor: Colors.red),
        );
      }
    } on TimeoutException {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Permintaan timeout, coba lagi nanti'), backgroundColor: Colors.red),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error ganti password: $e'), backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  void _showChangePasswordDialog() {
    final usernameController = TextEditingController(text: username.text.trim());
    final oldPasswordController = TextEditingController();
    final newPasswordController = TextEditingController();

    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Ganti Password'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: usernameController,
                decoration: const InputDecoration(labelText: 'Username', border: OutlineInputBorder()),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: oldPasswordController,
                obscureText: true,
                decoration: const InputDecoration(labelText: 'Password Lama', border: OutlineInputBorder()),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: newPasswordController,
                obscureText: true,
                decoration: const InputDecoration(labelText: 'Password Baru', border: OutlineInputBorder()),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Batal')),
          ElevatedButton(
            onPressed: () {
              final changeUsername = usernameController.text.trim();
              Navigator.pop(context);
              _changePassword(
                changeUsername,
                oldPasswordController.text,
                newPasswordController.text,
              );
            },
            child: const Text('Simpan'),
          ),
        ],
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    checkStatusApi();
    timer = Timer.periodic(const Duration(seconds: 5), (timer) {
      checkStatusApi();
    });
  }

  @override
  void dispose() {
    timer?.cancel();
    username.dispose();
    password.dispose();
    super.dispose();
  }

  static const _roleMeta = {
    'admin': (label: 'Admin', icon: Icons.admin_panel_settings_outlined),
    'mahasiswa': (label: 'Mahasiswa', icon: Icons.school_outlined),
    'dosen': (label: 'Dosen', icon: Icons.badge_outlined),
  };

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [AppTheme.primary, AppTheme.primaryDark],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 420),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 76,
                      height: 76,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(22),
                      ),
                      child: const Icon(Icons.school_rounded, size: 40, color: Colors.white),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'SIAKAD',
                      style: TextStyle(fontSize: 26, fontWeight: FontWeight.w800, color: Colors.white, letterSpacing: 0.5),
                    ),
                    const Text(
                      'Sistem Informasi Akademik',
                      style: TextStyle(fontSize: 13, color: Colors.white70),
                    ),
                    const SizedBox(height: 28),
                    Container(
                      padding: const EdgeInsets.all(28),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: [
                          BoxShadow(color: Colors.black.withOpacity(0.15), blurRadius: 30, offset: const Offset(0, 12)),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(
                                width: 8,
                                height: 8,
                                margin: const EdgeInsets.only(right: 6),
                                decoration: BoxDecoration(
                                  color: apiConnected ? AppTheme.success : AppTheme.danger,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              Text(
                                apiConnected ? 'Server terhubung' : 'Server tidak terhubung',
                                style: TextStyle(
                                  fontSize: 12.5,
                                  color: apiConnected ? AppTheme.success : AppTheme.danger,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),
                          const Text('Masuk sebagai', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, color: Color(0xFF6B7280))),
                          const SizedBox(height: 8),
                          Row(
                            children: rolesList.map((role) {
                              final meta = _roleMeta[role]!;
                              final selected = selectedRole == role;
                              return Expanded(
                                child: GestureDetector(
                                  onTap: () => setState(() => selectedRole = role),
                                  child: Container(
                                    margin: const EdgeInsets.symmetric(horizontal: 4),
                                    padding: const EdgeInsets.symmetric(vertical: 12),
                                    decoration: BoxDecoration(
                                      color: selected ? AppTheme.primary.withOpacity(0.1) : Colors.transparent,
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(color: selected ? AppTheme.primary : AppTheme.cardBorder),
                                    ),
                                    child: Column(
                                      children: [
                                        Icon(meta.icon, size: 20, color: selected ? AppTheme.primary : const Color(0xFF9CA3AF)),
                                        const SizedBox(height: 4),
                                        Text(
                                          meta.label,
                                          style: TextStyle(
                                            fontSize: 11.5,
                                            fontWeight: FontWeight.w600,
                                            color: selected ? AppTheme.primary : const Color(0xFF9CA3AF),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                          const SizedBox(height: 20),
                          TextField(
                            controller: username,
                            decoration: const InputDecoration(
                              labelText: 'Username',
                              prefixIcon: Icon(Icons.person_outline),
                            ),
                          ),
                          const SizedBox(height: 14),
                          TextField(
                            controller: password,
                            obscureText: true,
                            decoration: const InputDecoration(
                              labelText: 'Password',
                              prefixIcon: Icon(Icons.lock_outline),
                            ),
                          ),
                          const SizedBox(height: 22),
                          SizedBox(
                            width: double.infinity,
                            height: 50,
                            child: ElevatedButton(
                              onPressed: isLoading ? null : login,
                              child: isLoading
                                  ? const SizedBox(
                                      width: 22,
                                      height: 22,
                                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
                                    )
                                  : const Text('MASUK'),
                            ),
                          ),
                          const SizedBox(height: 10),
                          SizedBox(
                            width: double.infinity,
                            height: 46,
                            child: OutlinedButton(
                              onPressed: isLoading ? null : _showChangePasswordDialog,
                              child: const Text('Ganti Password'),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
