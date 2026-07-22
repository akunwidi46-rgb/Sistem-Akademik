import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'tambah_mahasiswa_page.dart';
import 'edit_mahasiswa_page.dart';

class ListMahasiswaPage extends StatefulWidget {
  const ListMahasiswaPage({super.key});

  @override
  State<ListMahasiswaPage> createState() => _ListMahasiswaPageState();
}

class _ListMahasiswaPageState extends State<ListMahasiswaPage> {
  final String baseUrl = "http://192.168.43.167/flutter_api/";
  List _listMahasiswa = [];
  List _filteredList = [];
  bool _isLoading = true;
final TextEditingController _searchNimController = TextEditingController();
final TextEditingController _searchNamaController = TextEditingController();



  // Mengambil data dari tampil_mahasiswa.php
  Future<void> _getData() async {
    try {
      final response = await http.get(Uri.parse("${baseUrl}tampil_mahasiswa.php"));
      if (response.statusCode == 200) {
        if (!mounted) return;

        setState(() {
          _listMahasiswa = jsonDecode(response.body);
          _filteredList = _listMahasiswa;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (!mounted) return;

      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Gagal mengambil data: $e")),
      );
    }
  }

  void _filterData() {
    final nimQuery = _searchNimController.text.trim().toLowerCase();
    final namaQuery = _searchNamaController.text.trim().toLowerCase();

    setState(() {
      _filteredList = _listMahasiswa.where((mhs) {
        final nim = (mhs['nim'] ?? '').toString().toLowerCase();
        final nama = (mhs['nama'] ?? '').toString().toLowerCase();

        final matchNim = nimQuery.isEmpty || nim.contains(nimQuery);
        final matchNama = namaQuery.isEmpty || nama.contains(namaQuery);

        return matchNim && matchNama;
      }).toList();
    });
  }


  // Menghapus data melalui hapus_mahasiswa.php
  Future<void> _deleteData(String id) async {
    try {
      final response = await http.post(
        Uri.parse("${baseUrl}hapus_mahasiswa.php"),
        headers: {
          "Content-Type": "application/json",
        },
        body: jsonEncode({"id": id}),
      );

      final data = jsonDecode(response.body);
      if (!mounted) return;

      if (data['success'] == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Data berhasil dihapus"), backgroundColor: Colors.green),
        );
        _getData(); // Refresh data setelah dihapus
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Gagal menghapus: ${data['message']}"), backgroundColor: Colors.red),
        );
      }
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Gagal menghapus: $e"), backgroundColor: Colors.red),
      );
    }
  }

  Future<void> _confirmDelete(Map data) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Hapus Data"),
        content: Text("Hapus data ${data['nama']} dengan NIM ${data['nim']}?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("Batal"),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text("Hapus"),
          ),
        ],
      ),
    );

    if (confirm == true) {
      _deleteData(data['id'].toString());
    }
  }

  // Navigate ke halaman edit
  void _navigateToEdit(Map data) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => EditMahasiswaPage(mahasiswa: data),
      ),
    );

    if (result == true) {
      _getData(); // Refresh data setelah edit
    }
  }

  // Navigate ke halaman tambah
  void _navigateToTambah() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const TambahMahasiswaPage(),
      ),
    );

    if (result == true) {
      _getData(); // Refresh data setelah tambah
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
                      DataColumn(label: Text("No")),
                      DataColumn(label: Text("NIM")),
                      DataColumn(label: Text("Nama")),
                      DataColumn(label: Text("Jurusan")),
                      DataColumn(label: Text("Alamat")),
                      DataColumn(label: Text("Aksi")),
                    ],
                    rows: List.generate(_filteredList.length, (index) {
                      final mhs = _filteredList[index];
                      return DataRow(
                        cells: [
                          DataCell(Text("${index + 1}")),
                          DataCell(Text("${mhs['nim'] ?? '-'}")),
                          DataCell(Text("${mhs['nama'] ?? '-'}")),
                          DataCell(Text("${mhs['jurusan'] ?? '-'}")),
                          DataCell(
                            ConstrainedBox(
                              constraints: const BoxConstraints(maxWidth: 260),
                              child: Text(
                                "${mhs['alamat'] ?? '-'}",
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ),
                          DataCell(
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  tooltip: "Edit",
                                  icon: const Icon(Icons.edit, color: Colors.orange),
                                  onPressed: () => _navigateToEdit(mhs),
                                ),
                                IconButton(
                                  tooltip: "Hapus",
                                  icon: const Icon(Icons.delete, color: Colors.red),
                                  onPressed: () => _confirmDelete(mhs),
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
  void initState() {
    super.initState();
    _getData();
  }

  @override
  void dispose() {
    _searchNimController.dispose();
    _searchNamaController.dispose();
    super.dispose();
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(

        title: const Text("Daftar Mahasiswa"),
        actions: [
          IconButton(
            tooltip: "Refresh",
            onPressed: _getData,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: Column(
        children: [
          // Search Bar
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _searchNimController,
              onChanged: (_) => _filterData(),
              decoration: InputDecoration(

                hintText: 'Cari NIM, Nama, atau Jurusan...',
                prefixIcon: const Icon(Icons.search),
            border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: TextField(
              controller: _searchNamaController,
              onChanged: (_) => _filterData(),
              decoration: InputDecoration(
                hintText: 'Search Nama...',
                prefixIcon: const Icon(Icons.person_search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
            ),
          ),

          // Data Table atau Empty State
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _filteredList.isEmpty
                    ? const Center(
                        child: Text("Belum ada data mahasiswa"),
                      )
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
