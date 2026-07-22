import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

/// PersetujuanKrsDosenPage (Dosen)
/// Sama seperti persetujuan KRS admin, tapi hanya menampilkan pengajuan KRS
/// untuk jadwal/kelas milik dosen yang sedang login.
///
/// Endpoint PHP:
/// - tampil_krs.php, persetujuan_krs.php
/// - tampil_jadwal.php, tampil_matkul.php, tampil_mahasiswa.php
class PersetujuanKrsDosenPage extends StatefulWidget {
  final String dosenId;
  const PersetujuanKrsDosenPage({super.key, required this.dosenId});

  @override
  State<PersetujuanKrsDosenPage> createState() => _PersetujuanKrsDosenPageState();
}

class _PersetujuanKrsDosenPageState extends State<PersetujuanKrsDosenPage> {
  final String baseUrl = 'http://192.168.43.167/flutter_api/';

  List _krsList = [];
  List _jadwalList = [];
  List _matkulList = [];
  List _mahasiswaList = [];
  bool _isLoading = true;
  bool _isUpdating = false;
  String _statusFilter = 'Pending';

  @override
  void initState() {
    super.initState();
    _getData();
  }

  List get _jadwalSaya =>
      _jadwalList.where((j) => j['dosen_id'].toString() == widget.dosenId).toList();

  String _namaMahasiswa(dynamic id) {
    final m = _mahasiswaList.firstWhere((e) => e['id'].toString() == id.toString(), orElse: () => null);
    return m == null ? '-' : '${m['nama']} (${m['nim']})';
  }

  String _namaMatkul(dynamic jadwalId) {
    final j = _jadwalList.firstWhere((e) => e['id'].toString() == jadwalId.toString(), orElse: () => null);
    if (j == null) return 'Jadwal #$jadwalId';
    final mk = _matkulList.firstWhere(
      (e) => e['id'].toString() == j['mata_kuliah_id'].toString(),
      orElse: () => null,
    );
    return mk == null ? '-' : '${mk['nama_mk']} (${j['kelas'] ?? '-'})';
  }

  Future<void> _getData() async {
    setState(() => _isLoading = true);
    try {
      final results = await Future.wait([
        http.get(Uri.parse('${baseUrl}tampil_krs.php')),
        http.get(Uri.parse('${baseUrl}tampil_jadwal.php')),
        http.get(Uri.parse('${baseUrl}tampil_matkul.php')),
        http.get(Uri.parse('${baseUrl}tampil_mahasiswa.php')),
      ]);
      if (!mounted) return;
      setState(() {
        _krsList = jsonDecode(results[0].body);
        _jadwalList = jsonDecode(results[1].body);
        _matkulList = jsonDecode(results[2].body);
        _mahasiswaList = jsonDecode(results[3].body);
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

  List get _filteredList {
    final jadwalIds = _jadwalSaya.map((j) => j['id'].toString()).toSet();
    return _krsList.where((k) {
      final matchJadwal = jadwalIds.contains(k['jadwal_id'].toString());
      final matchStatus = _statusFilter == 'Semua' || (k['status'] ?? '') == _statusFilter;
      return matchJadwal && matchStatus;
    }).toList();
  }

  Future<void> _updateStatus(Map krs, String status) async {
    setState(() => _isUpdating = true);
    try {
      final response = await http.post(
        Uri.parse('${baseUrl}persetujuan_krs.php'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'id': krs['id'].toString(), 'status': status}),
      );
      final data = jsonDecode(response.body);
      if (!mounted) return;

      if (data['success'] == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(status == 'Disetujui' ? 'KRS disetujui' : 'KRS ditolak'),
            backgroundColor: status == 'Disetujui' ? Colors.green : Colors.red,
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
      if (mounted) setState(() => _isUpdating = false);
    }
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'Disetujui':
        return Colors.green;
      case 'Ditolak':
        return Colors.red;
      default:
        return Colors.orange;
    }
  }

  @override
  Widget build(BuildContext context) {
    final data = _filteredList;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Persetujuan KRS'),
        foregroundColor: Colors.white,
        actions: [
          IconButton(tooltip: 'Refresh', onPressed: _getData, icon: const Icon(Icons.refresh)),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            child: Row(
              children: [
                const Text('Filter status: '),
                const SizedBox(width: 8),
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: _statusFilter,
                    decoration: const InputDecoration(
                      isDense: true,
                      contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      border: OutlineInputBorder(),
                    ),
                    items: const ['Semua', 'Pending', 'Disetujui', 'Ditolak']
                        .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                        .toList(),
                    onChanged: (v) => setState(() => _statusFilter = v ?? 'Semua'),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : data.isEmpty
                    ? const Center(child: Text('Tidak ada pengajuan KRS untuk filter ini'))
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: data.length,
                        itemBuilder: (context, index) {
                          final krs = data[index];
                          final status = (krs['status'] ?? 'Pending').toString();
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
                                          _namaMahasiswa(krs['mahasiswa_id']),
                                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                                        ),
                                      ),
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
                                  Text(_namaMatkul(krs['jadwal_id'])),
                                  Text('Tanggal pengajuan: ${krs['tanggal'] ?? '-'}',
                                      style: const TextStyle(color: Colors.grey, fontSize: 12)),
                                  if (status == 'Pending') ...[
                                    const SizedBox(height: 12),
                                    Row(
                                      children: [
                                        Expanded(
                                          child: OutlinedButton.icon(
                                            onPressed: _isUpdating ? null : () => _updateStatus(krs, 'Ditolak'),
                                            icon: const Icon(Icons.close, color: Colors.red),
                                            label: const Text('Tolak', style: TextStyle(color: Colors.red)),
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: ElevatedButton.icon(
                                            onPressed: _isUpdating ? null : () => _updateStatus(krs, 'Disetujui'),
                                            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                                            icon: const Icon(Icons.check),
                                            label: const Text('Setujui'),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ],
                              ),
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
