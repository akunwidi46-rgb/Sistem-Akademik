import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

/// MahasiswaKelasPage (Dosen)
/// Menampilkan daftar mahasiswa yang KRS-nya sudah disetujui di kelas/jadwal
/// milik dosen yang sedang login.
///
/// Endpoint PHP:
/// - tampil_jadwal.php (jadwal milik dosen ini)
/// - tampil_matkul.php, tampil_mahasiswa.php
/// - tampil_krs.php (status Disetujui untuk jadwal-jadwal tsb)
class MahasiswaKelasPage extends StatefulWidget {
  final String dosenId;
  const MahasiswaKelasPage({super.key, required this.dosenId});

  @override
  State<MahasiswaKelasPage> createState() => _MahasiswaKelasPageState();
}

class _MahasiswaKelasPageState extends State<MahasiswaKelasPage> {
  final String baseUrl = 'http://192.168.43.167/flutter_api/';

  List _jadwalList = [];
  List _matkulList = [];
  List _mahasiswaList = [];
  List _krsList = [];
  bool _isLoading = true;
  String? _selectedJadwalId;

  @override
  void initState() {
    super.initState();
    _getData();
  }

  List get _jadwalSaya =>
      _jadwalList.where((j) => j['dosen_id'].toString() == widget.dosenId).toList();

  String _namaMatkul(dynamic jadwalId) {
    final j = _jadwalList.firstWhere((e) => e['id'].toString() == jadwalId.toString(), orElse: () => null);
    if (j == null) return 'Jadwal #$jadwalId';
    final mk = _matkulList.firstWhere(
      (e) => e['id'].toString() == j['mata_kuliah_id'].toString(),
      orElse: () => null,
    );
    return mk == null ? '-' : '${mk['nama_mk']} (${j['kelas'] ?? '-'})';
  }

  String _namaMahasiswa(dynamic id) {
    final m = _mahasiswaList.firstWhere((e) => e['id'].toString() == id.toString(), orElse: () => null);
    return m == null ? '-' : '${m['nama']}';
  }

  String _nimMahasiswa(dynamic id) {
    final m = _mahasiswaList.firstWhere((e) => e['id'].toString() == id.toString(), orElse: () => null);
    return m == null ? '-' : '${m['nim']}';
  }

  Future<void> _getData() async {
    setState(() => _isLoading = true);
    try {
      final results = await Future.wait([
        http.get(Uri.parse('${baseUrl}tampil_jadwal.php')),
        http.get(Uri.parse('${baseUrl}tampil_matkul.php')),
        http.get(Uri.parse('${baseUrl}tampil_mahasiswa.php')),
        http.get(Uri.parse('${baseUrl}tampil_krs.php')),
      ]);
      if (!mounted) return;
      setState(() {
        _jadwalList = jsonDecode(results[0].body);
        _matkulList = jsonDecode(results[1].body);
        _mahasiswaList = jsonDecode(results[2].body);
        _krsList = jsonDecode(results[3].body);
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal mengambil data: $e')),
      );
    }
  }

  List get _rosterList {
    final jadwalIds = _jadwalSaya.map((j) => j['id'].toString()).toSet();
    return _krsList.where((k) {
      final matchJadwal = jadwalIds.contains(k['jadwal_id'].toString());
      final matchStatus = (k['status'] ?? '') == 'Disetujui';
      final matchFilter = _selectedJadwalId == null || k['jadwal_id'].toString() == _selectedJadwalId;
      return matchJadwal && matchStatus && matchFilter;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final roster = _rosterList;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mahasiswa'),
        foregroundColor: Colors.white,
        actions: [
          IconButton(tooltip: 'Refresh', onPressed: _getData, icon: const Icon(Icons.refresh)),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: DropdownButtonFormField<String>(
                    value: _selectedJadwalId,
                    decoration: const InputDecoration(
                      labelText: 'Filter Kelas / Mata Kuliah',
                      border: OutlineInputBorder(),
                    ),
                    items: [
                      const DropdownMenuItem(value: null, child: Text('Semua Kelas')),
                      ..._jadwalSaya.map(
                        (j) => DropdownMenuItem(value: j['id'].toString(), child: Text(_namaMatkul(j['id']))),
                      ),
                    ],
                    onChanged: (v) => setState(() => _selectedJadwalId = v),
                  ),
                ),
                Expanded(
                  child: roster.isEmpty
                      ? const Center(child: Text('Belum ada mahasiswa yang KRS-nya disetujui di kelas ini'))
                      : ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          itemCount: roster.length,
                          itemBuilder: (context, index) {
                            final k = roster[index];
                            return Card(
                              elevation: 2,
                              margin: const EdgeInsets.only(bottom: 10),
                              child: ListTile(
                                leading: const Icon(Icons.person, color: Colors.indigo),
                                title: Text(_namaMahasiswa(k['mahasiswa_id'])),
                                subtitle: Text('NIM ${_nimMahasiswa(k['mahasiswa_id'])} • ${_namaMatkul(k['jadwal_id'])}'),
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
    );
  }
}
