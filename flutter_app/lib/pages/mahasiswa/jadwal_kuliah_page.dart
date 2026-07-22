import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

/// JadwalKuliahPage (Mahasiswa)
/// Menampilkan seluruh jadwal kuliah yang tersedia dan memungkinkan mahasiswa
/// mengajukan KRS (mengambil mata kuliah) untuk jadwal tersebut.
///
/// Endpoint PHP:
/// - tampil_jadwal.php, tampil_matkul.php, tampil_dosen.php (data referensi)
/// - tampil_krs.php (mengecek KRS yang sudah diambil mahasiswa ini)
/// - simpan_krs.php (mengajukan KRS baru)
class JadwalKuliahPage extends StatefulWidget {
  final String mahasiswaId;
  const JadwalKuliahPage({super.key, required this.mahasiswaId});

  @override
  State<JadwalKuliahPage> createState() => _JadwalKuliahPageState();
}

class _JadwalKuliahPageState extends State<JadwalKuliahPage> {
  final String baseUrl = 'http://192.168.43.167/flutter_api/';

  List _jadwalList = [];
  List _matkulList = [];
  List _dosenList = [];
  List _krsSaya = [];
  bool _isLoading = true;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _getData();
  }

  Map? _matkulOf(dynamic jadwal) {
    return _matkulList.firstWhere(
      (e) => e['id'].toString() == jadwal['mata_kuliah_id'].toString(),
      orElse: () => null,
    );
  }

  String _namaDosen(dynamic id) {
    final d = _dosenList.firstWhere((e) => e['id'].toString() == id.toString(), orElse: () => null);
    return d == null ? '-' : '${d['nama']}';
  }

  String? _statusKrsFor(dynamic jadwalId) {
    final k = _krsSaya.firstWhere(
      (e) => e['jadwal_id'].toString() == jadwalId.toString(),
      orElse: () => null,
    );
    return k == null ? null : (k['status']?.toString());
  }

  Future<void> _getData() async {
    setState(() => _isLoading = true);
    try {
      final results = await Future.wait([
        http.get(Uri.parse('${baseUrl}tampil_jadwal.php')),
        http.get(Uri.parse('${baseUrl}tampil_matkul.php')),
        http.get(Uri.parse('${baseUrl}tampil_dosen.php')),
        http.post(
          Uri.parse('${baseUrl}tampil_krs.php'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({'mahasiswa_id': widget.mahasiswaId}),
        ),
      ]);
      if (!mounted) return;
      setState(() {
        _jadwalList = jsonDecode(results[0].body);
        _matkulList = jsonDecode(results[1].body);
        _dosenList = jsonDecode(results[2].body);
        _krsSaya = jsonDecode(results[3].body);
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

  Future<void> _ambilKrs(Map jadwal) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Ambil Mata Kuliah'),
        content: Text('Ajukan KRS untuk ${_matkulOf(jadwal)?['nama_mk'] ?? '-'}?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Batal')),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Ajukan'),
          ),
        ],
      ),
    );
    if (confirm != true) return;

    setState(() => _isSubmitting = true);
    try {
      final now = DateTime.now();
      final tanggal =
          '${now.year.toString().padLeft(4, '0')}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')} '
          '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}:${now.second.toString().padLeft(2, '0')}';

      final response = await http.post(
        Uri.parse('${baseUrl}simpan_krs.php'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'mahasiswa_id': widget.mahasiswaId,
          'jadwal_id': jadwal['id'].toString(),
          'status': 'Pending',
          'tanggal': tanggal,
        }),
      );
      final data = jsonDecode(response.body);
      if (!mounted) return;

      if (data['success'] == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('KRS berhasil diajukan, menunggu persetujuan'), backgroundColor: Colors.green),
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
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  Color _statusColor(String? status) {
    switch (status) {
      case 'Disetujui':
        return Colors.green;
      case 'Ditolak':
        return Colors.red;
      case 'Pending':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Jadwal Kuliah'),
        foregroundColor: Colors.white,
        actions: [
          IconButton(tooltip: 'Refresh', onPressed: _getData, icon: const Icon(Icons.refresh)),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _jadwalList.isEmpty
              ? const Center(child: Text('Belum ada jadwal kuliah'))
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _jadwalList.length,
                  itemBuilder: (context, index) {
                    final j = _jadwalList[index];
                    final mk = _matkulOf(j);
                    final status = _statusKrsFor(j['id']);

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
                                    mk == null ? 'Mata kuliah #${j['mata_kuliah_id']}' : mk['nama_mk'],
                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                                  ),
                                ),
                                if (status != null)
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: _statusColor(status).withOpacity(0.15),
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: Text(
                                      status,
                                      style: TextStyle(color: _statusColor(status), fontWeight: FontWeight.bold, fontSize: 12),
                                    ),
                                  ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text('Dosen: ${_namaDosen(j['dosen_id'])}'),
                            Text('${j['hari'] ?? '-'}, ${j['jam_mulai'] ?? '-'} - ${j['jam_selesai'] ?? '-'}'),
                            Text('Ruangan ${j['ruangan'] ?? '-'} • Kelas ${j['kelas'] ?? '-'} • ${j['tahun_ajaran'] ?? '-'}'),
                            if (mk != null) Text('SKS: ${mk['sks'] ?? '-'}'),
                            const SizedBox(height: 12),
                            if (status == null)
                              SizedBox(
                                width: double.infinity,
                                child: ElevatedButton(
                                  onPressed: _isSubmitting ? null : () => _ambilKrs(j),
                                  child: const Text('Ambil Mata Kuliah'),
                                ),
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
