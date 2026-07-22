import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

/// JadwalMengajarPage (Dosen)
/// Menampilkan jadwal mengajar milik dosen yang sedang login (read-only).
///
/// Endpoint PHP:
/// - tampil_jadwal.php (difilter di sisi klien berdasarkan dosen_id)
/// - tampil_matkul.php (untuk menampilkan nama mata kuliah)
class JadwalMengajarPage extends StatefulWidget {
  final String dosenId;
  const JadwalMengajarPage({super.key, required this.dosenId});

  @override
  State<JadwalMengajarPage> createState() => _JadwalMengajarPageState();
}

class _JadwalMengajarPageState extends State<JadwalMengajarPage> {
  final String baseUrl = 'http://192.168.43.167/flutter_api/';

  List _jadwalList = [];
  List _matkulList = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _getData();
  }

  List get _jadwalSaya =>
      _jadwalList.where((j) => j['dosen_id'].toString() == widget.dosenId).toList();

  Map? _matkulOf(dynamic jadwal) {
    return _matkulList.firstWhere(
      (e) => e['id'].toString() == jadwal['mata_kuliah_id'].toString(),
      orElse: () => null,
    );
  }

  Future<void> _getData() async {
    setState(() => _isLoading = true);
    try {
      final results = await Future.wait([
        http.get(Uri.parse('${baseUrl}tampil_jadwal.php')),
        http.get(Uri.parse('${baseUrl}tampil_matkul.php')),
      ]);
      if (!mounted) return;
      setState(() {
        _jadwalList = jsonDecode(results[0].body);
        _matkulList = jsonDecode(results[1].body);
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

  @override
  Widget build(BuildContext context) {
    final data = _jadwalSaya;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Jadwal Mengajar'),
        foregroundColor: Colors.white,
        actions: [
          IconButton(tooltip: 'Refresh', onPressed: _getData, icon: const Icon(Icons.refresh)),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : data.isEmpty
              ? const Center(child: Text('Belum ada jadwal mengajar'))
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: data.length,
                  itemBuilder: (context, index) {
                    final j = data[index];
                    final mk = _matkulOf(j);
                    return Card(
                      elevation: 3,
                      margin: const EdgeInsets.only(bottom: 12),
                      child: ListTile(
                        title: Text(mk == null ? 'Mata kuliah #${j['mata_kuliah_id']}' : mk['nama_mk']),
                        subtitle: Text(
                          '${j['hari'] ?? '-'}, ${j['jam_mulai'] ?? '-'} - ${j['jam_selesai'] ?? '-'}\n'
                          'Ruangan ${j['ruangan'] ?? '-'} • Kelas ${j['kelas'] ?? '-'} • ${j['tahun_ajaran'] ?? '-'}',
                        ),
                        isThreeLine: true,
                      ),
                    );
                  },
                ),
    );
  }
}
