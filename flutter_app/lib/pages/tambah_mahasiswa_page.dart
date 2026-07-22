import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class TambahMahasiswaPage extends StatefulWidget {
  const TambahMahasiswaPage({super.key});

  @override
  State<TambahMahasiswaPage> createState() => _TambahMahasiswaPageState();
}

class _TambahMahasiswaPageState extends State<TambahMahasiswaPage> {
  final _formKey = GlobalKey<FormState>();
  static const String baseUrl = 'http://192.168.43.167/flutter_api/';

  final TextEditingController _nimController = TextEditingController();
  final TextEditingController _namaController = TextEditingController();
  final TextEditingController _jurusanController = TextEditingController();
  final TextEditingController _alamatController = TextEditingController();

  bool _isLoading = false;

  Future<void> _tambahMahasiswa() async {
    if (!_formKey.currentState!.validate()) return;

    final nim = _nimController.text.trim();
    final nama = _namaController.text.trim();
    final jurusan = _jurusanController.text.trim();
    final alamat = _alamatController.text.trim();

    if (nim.isEmpty || nama.isEmpty || jurusan.isEmpty || alamat.isEmpty) {
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
      // Daftar akun dengan username=NIM dan password=NIM
      final response = await http.post(
        Uri.parse('${baseUrl}register.php'),
        body: {
          'nama': nama,
          'username': nim,
          'password': nim,
          'role': 'mahasiswa',
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

        // Simpan profil mahasiswa
        final profileResponse = await http.post(
          Uri.parse('${baseUrl}simpan_mahasiswa.php'),
          body: {
            'user_id': userId,
            'username': nim,
            'nim': nim,
            'nama': nama,
            'jurusan': jurusan,
            'alamat': alamat,
            'nidn': '',
            'kontak': '',
            'role': 'mahasiswa',
          },
        );

        final profileData = jsonDecode(profileResponse.body.trim());
        if (!mounted) return;

        if (profileData['success'] == true) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Akun mahasiswa berhasil dibuat'),
              backgroundColor: Colors.green,
            ),
          );
          _nimController.clear();
          _namaController.clear();
          _jurusanController.clear();
          _alamatController.clear();
          Navigator.pop(context, true);
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
            content: Text(data['message'] ?? 'Gagal membuat akun mahasiswa'),
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
    _nimController.dispose();
    _namaController.dispose();
    _jurusanController.dispose();
    _alamatController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Tambah Data Mahasiswa'),
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
                        'Form Pendaftaran Mahasiswa Baru',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.indigo,
                        ),
                      ),
                      const SizedBox(height: 10),
                      const Text(
                        'Username dan Password akan otomatis menggunakan NIM',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                      const SizedBox(height: 20),
                      TextFormField(
                        controller: _nimController,
                        decoration: InputDecoration(
                          labelText: 'NIM',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          prefixIcon: const Icon(Icons.numbers),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'NIM tidak boleh kosong';
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
                        controller: _jurusanController,
                        decoration: InputDecoration(
                          labelText: 'Jurusan',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          prefixIcon: const Icon(Icons.school),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Jurusan tidak boleh kosong';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _alamatController,
                        decoration: InputDecoration(
                          labelText: 'Alamat',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          prefixIcon: const Icon(Icons.location_on),
                        ),
                        maxLines: 3,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Alamat tidak boleh kosong';
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
                              onPressed: _isLoading ? null : _tambahMahasiswa,
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
