import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class EditMahasiswaPage extends StatefulWidget {
  final Map mahasiswa;

  const EditMahasiswaPage({
    super.key,
    required this.mahasiswa,
  });

  @override
  State<EditMahasiswaPage> createState() => _EditMahasiswaPageState();
}

class _EditMahasiswaPageState extends State<EditMahasiswaPage> {
  final _formKey = GlobalKey<FormState>();
  static const String baseUrl = 'http://192.168.43.167/flutter_api/';

  late TextEditingController _nimController;
  late TextEditingController _namaController;
  late TextEditingController _jurusanController;
  late TextEditingController _alamatController;

  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _nimController = TextEditingController(text: widget.mahasiswa['nim'] ?? '');
    _namaController = TextEditingController(text: widget.mahasiswa['nama'] ?? '');
    _jurusanController = TextEditingController(text: widget.mahasiswa['jurusan'] ?? '');
    _alamatController = TextEditingController(text: widget.mahasiswa['alamat'] ?? '');
  }

  Future<void> _editMahasiswa() async {
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
      final response = await http.post(
        Uri.parse('${baseUrl}edit_mahasiswa.php'),
        body: {
          'id': widget.mahasiswa['id'].toString(),
          'nim': nim,
          'nama': nama,
          'jurusan': jurusan,
          'alamat': alamat,
        },
      );

      final data = jsonDecode(response.body.trim());
      if (!mounted) return;

      if (data['success'] == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Data mahasiswa berhasil diubah'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context, true);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(data['message'] ?? 'Gagal mengubah data mahasiswa'),
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
        title: const Text('Edit Data Mahasiswa'),
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
                        'Form Edit Data Mahasiswa',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.indigo,
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
                              onPressed: _isLoading ? null : _editMahasiswa,
                              child: _isLoading
                                  ? const SizedBox(
                                      height: 20,
                                      width: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                      ),
                                    )
                                  : const Text('Simpan Perubahan'),
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
