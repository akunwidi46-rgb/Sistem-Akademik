import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class TambahDosenPage extends StatefulWidget {
  const TambahDosenPage({super.key});

  @override
  State<TambahDosenPage> createState() => _TambahDosenPageState();
}

class _TambahDosenPageState extends State<TambahDosenPage> {
  final _formKey = GlobalKey<FormState>();
  static const String baseUrl = 'http://192.168.43.167/flutter_api/';

final TextEditingController _nidnController = TextEditingController();
final TextEditingController _namaController = TextEditingController();
final TextEditingController _kontakController = TextEditingController();
final TextEditingController _passwordController = TextEditingController();
  bool _isLoading = false;

  Future<void> _tambahDosen() async {
    if (!_formKey.currentState!.validate()) return;

    final nidn = _nidnController.text.trim();
    final nama = _namaController.text.trim();
    final kontak = _kontakController.text.trim();

    if (nidn.isEmpty || nama.isEmpty || kontak.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Semua field wajib diisi'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final response = await http.post(
        Uri.parse('${baseUrl}register.php'),
        body: {
          'nama': nama,
          'username': nidn,
          'password': nidn,
          'role': 'dosen',
        },
      );

      final responseBody = response.body.trim();
      if (!responseBody.startsWith('{')) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Server mengirim respons bukan JSON'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      final data = jsonDecode(responseBody);
      if (!mounted) return;

      if (data['success'] == true) {
        final userId = data['user_id']?.toString() ?? '';
        if (userId.isEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Server tidak mengirim user_id, cek register.php'),
              backgroundColor: Colors.red,
            ),
          );
          return;
        }

        final profileResponse = await http.post(
          Uri.parse('${baseUrl}simpan_dosen.php'),
          body: {
            'user_id': userId,
            'username': nidn,
            'nidn': nidn,
            'nama': nama,
            'kontak': kontak,
            'role': 'dosen',
          },
        );

        final profileData = jsonDecode(profileResponse.body.trim());
        if (!mounted) return;

        if (profileData['success'] == true) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Akun dosen berhasil dibuat'),
              backgroundColor: Colors.green,
            ),
          );
          _nidnController.clear();
          _namaController.clear();
          _kontakController.clear();
          _passwordController.clear();
          Navigator.pop(context);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(profileData['message'] ?? 'Akun dibuat, tetapi profil gagal disimpan'),
              backgroundColor: Colors.orange,
            ),
          );
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(data['message'] ?? 'Gagal membuat akun dosen'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error jaringan: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  void dispose() {
    _nidnController.dispose();
    _namaController.dispose();
    _kontakController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Tambah Data Dosen'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Card(
                elevation: 3,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Container(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Form Pendaftaran Dosen Baru',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.indigo,
                        ),
                      ),
                      const SizedBox(height: 20),
                      TextFormField(
                        controller: _nidnController,
                        decoration: InputDecoration(
                          labelText: 'NIDN',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          prefixIcon: const Icon(Icons.numbers),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'NIDN tidak boleh kosong';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _namaController,
                        decoration: InputDecoration(
                          labelText: 'Nama Lengkap',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          prefixIcon: const Icon(Icons.person),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Nama tidak boleh kosong';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _kontakController,
                        decoration: InputDecoration(
                          labelText: 'Kontak (No. HP / Email)',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          prefixIcon: const Icon(Icons.phone),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Kontak tidak boleh kosong';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _passwordController,
                        decoration: InputDecoration(
                          labelText: 'Password',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          prefixIcon: const Icon(Icons.lock),
                        ),
                        obscureText: true,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Password tidak boleh kosong';
                          }
                          if (value.length < 6) {
                            return 'Password minimal 6 karakter';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 24),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () => Navigator.pop(context),
                              child: const Text('Batal'),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.indigo,
                              ),
                              onPressed: _isLoading ? null : _tambahDosen,
                              child: _isLoading
                                  ? const SizedBox(
                                      height: 20,
                                      width: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                      ),
                                    )
                                  : const Text('Simpan'),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
