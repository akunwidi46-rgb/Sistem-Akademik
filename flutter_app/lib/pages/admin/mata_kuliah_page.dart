import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

/// MataKuliahPage
/// CRUD Mata Kuliah untuk Admin.
///
/// Endpoint PHP:
/// - tampil_matkul.php
/// - simpan_matkul.php
/// - edit_matkul.php
/// - hapus_matkul.php
class MataKuliahPage extends StatefulWidget {
  const MataKuliahPage({super.key});

  @override
  State<MataKuliahPage> createState() => _MataKuliahPageState();
}

class _MataKuliahPageState extends State<MataKuliahPage> {
  final String baseUrl = 'http://192.168.43.167/flutter_api/';

  List _list = [];
  List _filteredList = [];
  bool _isLoading = true;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _getData();
    _searchController.addListener(_filterData);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _filterData() {
    final q = _searchController.text.trim().toLowerCase();
    setState(() {
      _filteredList = _list.where((mk) {
        final kode = (mk['kode_mk'] ?? '').toString().toLowerCase();
        final nama = (mk['nama_mk'] ?? '').toString().toLowerCase();
        return q.isEmpty || kode.contains(q) || nama.contains(q);
      }).toList();
    });
  }

  Future<void> _getData() async {
    setState(() => _isLoading = true);
    try {
      final response = await http.get(Uri.parse('${baseUrl}tampil_matkul.php'));
      if (!mounted) return;
      if (response.statusCode == 200) {
        setState(() {
          _list = jsonDecode(response.body);
          _filteredList = _list;
          _isLoading = false;
        });
      } else {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal mengambil data: ${response.statusCode}')),
        );
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal mengambil data: $e')),
      );
    }
  }

  Future<void> _deleteData(String id) async {
    try {
      final response = await http.post(
        Uri.parse('${baseUrl}hapus_matkul.php'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'id': id}),
      );
      final data = jsonDecode(response.body);
      if (!mounted) return;

      if (data['success'] == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Data berhasil dihapus'), backgroundColor: Colors.green),
        );
        _getData();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal menghapus: ${data['message']}'), backgroundColor: Colors.red),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal menghapus: $e'), backgroundColor: Colors.red),
      );
    }
  }

  Future<void> _confirmDelete(Map mk) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hapus Data'),
        content: Text('Hapus mata kuliah ${mk['nama_mk']} (${mk['kode_mk']})?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Batal')),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );
    if (confirm == true) _deleteData(mk['id'].toString());
  }

  Future<void> _showForm({Map? existing}) async {
    final formKey = GlobalKey<FormState>();
    final kodeController = TextEditingController(text: existing?['kode_mk']?.toString() ?? '');
    final namaController = TextEditingController(text: existing?['nama_mk']?.toString() ?? '');
    final sksController = TextEditingController(text: existing?['sks']?.toString() ?? '');
    final semesterController = TextEditingController(text: existing?['semester']?.toString() ?? '');

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(existing == null ? 'Tambah Mata Kuliah' : 'Edit Mata Kuliah'),
        content: SizedBox(
          width: 420,
          child: Form(
            key: formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    controller: kodeController,
                    decoration: const InputDecoration(labelText: 'Kode MK'),
                    validator: (v) => (v == null || v.trim().isEmpty) ? 'Kode MK wajib diisi' : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: namaController,
                    decoration: const InputDecoration(labelText: 'Nama Mata Kuliah'),
                    validator: (v) => (v == null || v.trim().isEmpty) ? 'Nama wajib diisi' : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: sksController,
                    decoration: const InputDecoration(labelText: 'SKS'),
                    keyboardType: TextInputType.number,
                    validator: (v) => (v == null || v.trim().isEmpty) ? 'SKS wajib diisi' : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: semesterController,
                    decoration: const InputDecoration(labelText: 'Semester'),
                    keyboardType: TextInputType.number,
                    validator: (v) => (v == null || v.trim().isEmpty) ? 'Semester wajib diisi' : null,
                  ),
                ],
              ),
            ),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Batal')),
          ElevatedButton(
            onPressed: () {
              if (!(formKey.currentState?.validate() ?? false)) return;
              Navigator.pop(context, true);
            },
            child: const Text('Simpan'),
          ),
        ],
      ),
    );

    if (result != true) return;

    final body = {
      'kode_mk': kodeController.text.trim(),
      'nama_mk': namaController.text.trim(),
      'sks': sksController.text.trim(),
      'semester': semesterController.text.trim(),
    };

    setState(() => _isLoading = true);
    try {
      final url = existing == null ? 'simpan_matkul.php' : 'edit_matkul.php';
      if (existing != null) body['id'] = existing['id'].toString();

      final response = await http.post(
        Uri.parse('$baseUrl$url'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(body),
      );
      final data = jsonDecode(response.body);
      if (!mounted) return;

      if (data['success'] == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(existing == null ? 'Mata kuliah berhasil ditambahkan' : 'Mata kuliah berhasil diubah'),
            backgroundColor: Colors.green,
          ),
        );
        await _getData();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal: ${data['message']}'), backgroundColor: Colors.red),
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
                    headingRowColor: WidgetStateProperty.all(Colors.orange.shade50),
                    columnSpacing: 28,
                    columns: const [
                      DataColumn(label: Text('No')),
                      DataColumn(label: Text('Kode MK')),
                      DataColumn(label: Text('Nama Mata Kuliah')),
                      DataColumn(label: Text('SKS')),
                      DataColumn(label: Text('Semester')),
                      DataColumn(label: Text('Aksi')),
                    ],
                    rows: List.generate(_filteredList.length, (index) {
                      final mk = _filteredList[index];
                      return DataRow(cells: [
                        DataCell(Text('${index + 1}')),
                        DataCell(Text('${mk['kode_mk'] ?? '-'}')),
                        DataCell(Text('${mk['nama_mk'] ?? '-'}')),
                        DataCell(Text('${mk['sks'] ?? '-'}')),
                        DataCell(Text('${mk['semester'] ?? '-'}')),
                        DataCell(Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              tooltip: 'Edit',
                              icon: const Icon(Icons.edit, color: Colors.orange),
                              onPressed: () => _showForm(existing: mk),
                            ),
                            IconButton(
                              tooltip: 'Hapus',
                              icon: const Icon(Icons.delete, color: Colors.red),
                              onPressed: () => _confirmDelete(mk),
                            ),
                          ],
                        )),
                      ]);
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
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mata Kuliah'),
        foregroundColor: Colors.white,
        actions: [
          IconButton(tooltip: 'Refresh', onPressed: _getData, icon: const Icon(Icons.refresh)),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Cari kode atau nama mata kuliah...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
            ),
          ),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _filteredList.isEmpty
                    ? const Center(child: Text('Belum ada data mata kuliah'))
                    : _buildTable(),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showForm(),
        child: const Icon(Icons.add),
      ),
    );
  }
}
