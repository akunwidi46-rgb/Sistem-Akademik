import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:printing/printing.dart';
import '../../utils/pdf_helper.dart';

/// KrsSayaPage (Mahasiswa)
/// Menampilkan daftar KRS yang sudah diajukan mahasiswa beserta statusnya.
/// KRS berstatus Pending bisa dibatalkan. Ada tombol cetak/export PDF KRS.
///
/// Endpoint PHP:
/// - tampil_krs.php (filter by mahasiswa_id)
/// - hapus_krs.php
/// - tampil_jadwal.php, tampil_matkul.php, tampil_dosen.php (untuk detail)
class KrsSayaPage extends StatefulWidget {
  final String mahasiswaId;
  final String nama;
  final String nim;
  final String jurusan;

  const KrsSayaPage({
    super.key,
    required this.mahasiswaId,
    required this.nama,
    required this.nim,
    required this.jurusan,
  });

  @override
  State<KrsSayaPage> createState() => _KrsSayaPageState();
}

class _KrsSayaPageState extends State<KrsSayaPage> {
  final String baseUrl = 'http://192.168.43.167/flutter_api/';

  List _krsList = [];
  List _jadwalList = [];
  List _matkulList = [];
  List _dosenList = [];
  bool _isLoading = true;
  bool _isExporting = false;

  @override
  void initState() {
    super.initState();
    _getData();
  }

  Map? _jadwalOf(dynamic jadwalId) =>
      _jadwalList.firstWhere((e) => e['id'].toString() == jadwalId.toString(), orElse: () => null);

  Map? _matkulOfJadwal(Map jadwal) =>
      _matkulList.firstWhere((e) => e['id'].toString() == jadwal['mata_kuliah_id'].toString(), orElse: () => null);

  String _namaDosen(dynamic id) {
    final d = _dosenList.firstWhere((e) => e['id'].toString() == id.toString(), orElse: () => null);
    return d == null ? '-' : '${d['nama']}';
  }

  String _namaMatkul(dynamic jadwalId) {
    final j = _jadwalOf(jadwalId);
    if (j == null) return 'Jadwal #$jadwalId';
    final mk = _matkulOfJadwal(j);
    return mk == null ? '-' : '${mk['nama_mk']} (${j['kelas'] ?? '-'})';
  }

  Future<void> _getData() async {
    setState(() => _isLoading = true);
    try {
      final results = await Future.wait([
        http.post(
          Uri.parse('${baseUrl}tampil_krs.php'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({'mahasiswa_id': widget.mahasiswaId}),
        ),
        http.get(Uri.parse('${baseUrl}tampil_jadwal.php')),
        http.get(Uri.parse('${baseUrl}tampil_matkul.php')),
        http.get(Uri.parse('${baseUrl}tampil_dosen.php')),
      ]);
      if (!mounted) return;
      setState(() {
        _krsList = jsonDecode(results[0].body);
        _jadwalList = jsonDecode(results[1].body);
        _matkulList = jsonDecode(results[2].body);
        _dosenList = jsonDecode(results[3].body);
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

  Future<void> _batalkan(Map krs) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Batalkan KRS'),
        content: Text('Batalkan pengajuan ${_namaMatkul(krs['jadwal_id'])}?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Tidak')),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Batalkan'),
          ),
        ],
      ),
    );
    if (confirm != true) return;

    try {
      final response = await http.post(
        Uri.parse('${baseUrl}hapus_krs.php'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'id': krs['id'].toString()}),
      );
      final data = jsonDecode(response.body);
      if (!mounted) return;

      if (data['success'] == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('KRS berhasil dibatalkan'), backgroundColor: Colors.green),
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
    }
  }

  Future<void> _cetak() async {
    setState(() => _isExporting = true);
    try {
      final items = _krsList.map<KrsItem>((k) {
        final j = _jadwalOf(k['jadwal_id']);
        final mk = j == null ? null : _matkulOfJadwal(j);
        return KrsItem(
          kodeMk: mk?['kode_mk']?.toString() ?? '-',
          namaMk: mk?['nama_mk']?.toString() ?? '-',
          sks: int.tryParse(mk?['sks']?.toString() ?? '') ?? 0,
          kelas: j?['kelas']?.toString() ?? '-',
          namaDosen: j == null ? '-' : _namaDosen(j['dosen_id']),
          status: (k['status'] ?? 'Pending').toString(),
        );
      }).toList();

      final doc = await PdfHelper.buildKrs(
        nama: widget.nama,
        nim: widget.nim,
        jurusan: widget.jurusan,
        items: items,
      );
      await Printing.layoutPdf(onLayout: (format) => doc.save());
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal membuat PDF: $e'), backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) setState(() => _isExporting = false);
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
    return Scaffold(
      appBar: AppBar(
        title: const Text('KRS Saya'),
        foregroundColor: Colors.white,
        actions: [
          IconButton(tooltip: 'Refresh', onPressed: _getData, icon: const Icon(Icons.refresh)),
          IconButton(
            tooltip: 'Cetak KRS',
            onPressed: (_isExporting || _krsList.isEmpty) ? null : _cetak,
            icon: const Icon(Icons.picture_as_pdf_outlined),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _krsList.isEmpty
              ? const Center(child: Text('Kamu belum mengambil mata kuliah apa pun'))
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _krsList.length,
                  itemBuilder: (context, index) {
                    final k = _krsList[index];
                    final status = (k['status'] ?? 'Pending').toString();
                    return Card(
                      elevation: 3,
                      margin: const EdgeInsets.only(bottom: 12),
                      child: ListTile(
                        title: Text(_namaMatkul(k['jadwal_id'])),
                        subtitle: Text('Diajukan: ${k['tanggal'] ?? '-'}'),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
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
                            if (status == 'Pending')
                              IconButton(
                                tooltip: 'Batalkan',
                                icon: const Icon(Icons.delete_outline, color: Colors.red),
                                onPressed: () => _batalkan(k),
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
