import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import 'tambah_dosen_page.dart';

/// ListDosenPage
/// Menampilkan seluruh data dosen dengan fitur search, refresh, tambah, edit, dan hapus.
///
/// Endpoint PHP:
/// - tampil_dosen.php
/// - simpan_dosen.php
/// - edit_dosen.php
/// - hapus_dosen.php
class ListDosenPage extends StatefulWidget {
  const ListDosenPage({super.key});

  @override
  State<ListDosenPage> createState() => _ListDosenPageState();
}

class _ListDosenPageState extends State<ListDosenPage> {
  final String baseUrl = 'http://192.168.43.167/flutter_api/';

  final TextEditingController _searchNidnController = TextEditingController();
  final TextEditingController _searchNamaController = TextEditingController();

  List _listDosen = [];
  List _filteredList = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _getData();

    _searchNidnController.addListener(() {
      _filterData();
    });
    _searchNamaController.addListener(() {
      _filterData();
    });
  }

  void _filterData() {
    final nidnQuery = _searchNidnController.text.trim().toLowerCase();
    final namaQuery = _searchNamaController.text.trim().toLowerCase();

    setState(() {
      _filteredList = _listDosen.where((dosen) {
        final nidn = (dosen['nidn'] ?? dosen['nidn'] ?? '').toString().toLowerCase();
        final nama = (dosen['nama'] ?? '').toString().toLowerCase();

        final matchNidn = nidnQuery.isEmpty || nidn.contains(nidnQuery);
        final matchNama = namaQuery.isEmpty || nama.contains(namaQuery);

        return matchNidn && matchNama;
      }).toList();
    });
  }

  Future<void> _getData() async {
    try {
      final response = await http.get(Uri.parse('${baseUrl}tampil_dosen.php'));
      if (response.statusCode == 200) {
        if (!mounted) return;
        setState(() {
          _listDosen = jsonDecode(response.body);
          _filteredList = _listDosen;
          _isLoading = false;
        });
      } else {
        if (!mounted) return;
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal mengambil data dosen: ${response.statusCode}')),
        );
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal mengambil data dosen: $e')),
      );
    }
  }

  Future<void> _deleteData(String id) async {
    try {
      final response = await http.post(
        Uri.parse('${baseUrl}hapus_dosen.php'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({'id': id}),
      );

      final data = jsonDecode(response.body);
      if (!mounted) return;

      if (data['success'] == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Data dosen berhasil dihapus'),
            backgroundColor: Colors.green,
          ),
        );
        _getData();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal menghapus: ${data['message']}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Gagal menghapus: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _confirmDelete(Map dosen) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hapus Data'),
        content: Text('Hapus data ${dosen['nama']} dengan NIDN ${dosen['nidn']}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      _deleteData(dosen['id'].toString());
    }
  }

  // Edit (inline via dialog) - mengikuti pola mahasiswa.
  Future<void> _confirmEdit(Map dosen) async {
    final _formKey = GlobalKey<FormState>();
    final nidnController = TextEditingController(text: dosen['nidn']?.toString() ?? '');
    final namaController = TextEditingController(text: dosen['nama']?.toString() ?? '');
    final kontakController = TextEditingController(text: dosen['kontak']?.toString() ?? '');

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Data Dosen'),
        content: SizedBox(
          width: 420,
          child: Form(
            key: _formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    controller: nidnController,
                    decoration: const InputDecoration(labelText: 'NIDN'),
                    validator: (v) => (v == null || v.trim().isEmpty) ? 'NIDN tidak boleh kosong' : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: namaController,
                    decoration: const InputDecoration(labelText: 'Nama'),
                    validator: (v) => (v == null || v.trim().isEmpty) ? 'Nama tidak boleh kosong' : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: kontakController,
                    decoration: const InputDecoration(labelText: 'Kontak'),
                    validator: (v) => (v == null || v.trim().isEmpty) ? 'Kontak tidak boleh kosong' : null,
                  ),
                ],
              ),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (!(_formKey.currentState?.validate() ?? false)) return;
              Navigator.pop(context, true);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.indigo),
            child: const Text('Simpan'),
          ),
        ],
      ),
    );

    if (result != true) return;

    setState(() => _isLoading = true);
    try {
      final response = await http.post(
        Uri.parse('${baseUrl}edit_dosen.php'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'id': dosen['id'].toString(),
          'nidn': nidnController.text.trim(),
          'nama': namaController.text.trim(),
          'kontak': kontakController.text.trim(),
        }),
      );

      final data = jsonDecode(response.body);
      if (!mounted) return;

      if (data['success'] == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Data dosen berhasil diubah'), backgroundColor: Colors.green),
        );
        await _getData();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal mengubah data: ${data['message']}'), backgroundColor: Colors.red),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error jaringan: $e'), backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _navigateToTambah() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const TambahDosenPage()),
    );

    if (result == true) {
      _getData();
    }
  }

  Widget _buildTable() {
    return LayoutBuilder(
      builder: (context, constraints) {
        return Scrollbar(
          thumbVisibility: true,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: ConstrainedBox(
              constraints: BoxConstraints(minWidth: constraints.maxWidth - 32),
              child: Card(
                elevation: 3,
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: DataTable(
                    headingRowColor: WidgetStateProperty.all(Colors.indigo.shade50),
                    columnSpacing: 28,
                    columns: const [
                      DataColumn(label: Text('No')),
                      DataColumn(label: Text('NIDN')),
                      DataColumn(label: Text('Nama')),
                      DataColumn(label: Text('Kontak')),
                      DataColumn(label: Text('Aksi')),
                    ],
                    rows: List.generate(_filteredList.length, (index) {
                      final dosen = _filteredList[index];
                      return DataRow(
                        cells: [
                          DataCell(Text('${index + 1}')),
                          DataCell(Text('${dosen['nidn'] ?? '-'}')),
                          DataCell(Text('${dosen['nama'] ?? '-'}')),
                          DataCell(
                            ConstrainedBox(
                              constraints: const BoxConstraints(maxWidth: 260),
                              child: Text(
                                '${dosen['kontak'] ?? '-'}',
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ),
                          DataCell(
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  tooltip: 'Edit',
                                  icon: const Icon(Icons.edit, color: Colors.orange),
                                  onPressed: () => _confirmEdit(dosen),
                                ),
                                IconButton(
                                  tooltip: 'Hapus',
                                  icon: const Icon(Icons.delete, color: Colors.red),
                                  onPressed: () => _confirmDelete(dosen),
                                ),
                              ],
                            ),
                          ),
                        ],
                      );
                    }),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  void dispose() {
    _searchNidnController.dispose();
    _searchNamaController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Daftar Dosen'),
        actions: [
          IconButton(
            tooltip: 'Refresh',
            onPressed: _getData,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: TextField(
              controller: _searchNidnController,
              decoration: InputDecoration(
                hintText: 'Search NIDN...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: TextField(
              controller: _searchNamaController,
              decoration: InputDecoration(
                hintText: 'Search Nama...',
                prefixIcon: const Icon(Icons.person_search),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
            ),
          ),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _filteredList.isEmpty
                    ? const Center(child: Text('Belum ada data dosen'))
                    : _buildTable(),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _navigateToTambah,
        child: const Icon(Icons.add),
      ),
    );
  }
}

