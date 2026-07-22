import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

/// NilaiSayaPage (Mahasiswa)
/// Menampilkan nilai mahasiswa yang bersangkutan (read-only).
///
/// Endpoint PHP:
/// - tampil_nilai.php (filter by mahasiswa_id)
/// - tampil_jadwal.php, tampil_matkul.php (untuk menampilkan nama mata kuliah)
class NilaiSayaPage extends StatefulWidget {
  final String mahasiswaId;
  const NilaiSayaPage({super.key, required this.mahasiswaId});

  @override
  State<NilaiSayaPage> createState() => _NilaiSayaPageState();
}

class _NilaiSayaPageState extends State<NilaiSayaPage> {
  final String baseUrl = 'http://192.168.43.167/flutter_api/';

  List _nilaiList = [];
  List _jadwalList = [];
  List _matkulList = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _getData();
  }

  Map? _matkulOfJadwal(dynamic jadwalId) {
    final j = _jadwalList.firstWhere((e) => e['id'].toString() == jadwalId.toString(), orElse: () => null);
    if (j == null) return null;
    return _matkulList.firstWhere(
      (e) => e['id'].toString() == j['mata_kuliah_id'].toString(),
      orElse: () => null,
    );
  }

  Future<void> _getData() async {
    setState(() => _isLoading = true);
    try {
      final results = await Future.wait([
        http.post(
          Uri.parse('${baseUrl}tampil_nilai.php'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({'mahasiswa_id': widget.mahasiswaId}),
        ),
        http.get(Uri.parse('${baseUrl}tampil_jadwal.php')),
        http.get(Uri.parse('${baseUrl}tampil_matkul.php')),
      ]);
      if (!mounted) return;
      setState(() {
        _nilaiList = jsonDecode(results[0].body);
        _jadwalList = jsonDecode(results[1].body);
        _matkulList = jsonDecode(results[2].body);
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

  Color _hurufColor(String huruf) {
    switch (huruf) {
      case 'A':
        return Colors.green;
      case 'B':
        return Colors.lightGreen;
      case 'C':
        return Colors.orange;
      default:
        return Colors.red;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Nilai Saya'),
        foregroundColor: Colors.white,
        actions: [
          IconButton(tooltip: 'Refresh', onPressed: _getData, icon: const Icon(Icons.refresh)),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _nilaiList.isEmpty
              ? const Center(child: Text('Belum ada nilai yang diinput dosen'))
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _nilaiList.length,
                  itemBuilder: (context, index) {
                    final n = _nilaiList[index];
                    final mk = _matkulOfJadwal(n['jadwal_id']);
                    final huruf = (n['nilai_huruf'] ?? '-').toString();
                    return Card(
                      elevation: 3,
                      margin: const EdgeInsets.only(bottom: 12),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Text(
                                    mk == null ? 'Mata kuliah #${n['jadwal_id']}' : mk['nama_mk'],
                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                                  ),
                                ),
                                CircleAvatar(
                                  backgroundColor: _hurufColor(huruf).withOpacity(0.15),
                                  child: Text(huruf, style: TextStyle(color: _hurufColor(huruf), fontWeight: FontWeight.bold)),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text('Tugas: ${n['tugas'] ?? '-'}'),
                                Text('UTS: ${n['uts'] ?? '-'}'),
                                Text('UAS: ${n['uas'] ?? '-'}'),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Nilai Akhir: ${n['nilai_akhir'] ?? '-'}',
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}
