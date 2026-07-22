import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:printing/printing.dart';
import '../../theme/app_theme.dart';
import '../../utils/pdf_helper.dart';

/// KhsPage (Mahasiswa)
/// Menampilkan Kartu Hasil Studi (KHS): nilai dikelompokkan per semester,
/// lengkap dengan IPS (per semester) dan IPK (kumulatif semua semester).
/// Ada tombol cetak/export PDF untuk KHS per semester maupun transkrip
/// lengkap (semua semester sekaligus).
///
/// Endpoint PHP:
/// - tampil_nilai.php (filter by mahasiswa_id)
/// - tampil_jadwal.php, tampil_matkul.php (untuk semester, tahun ajaran, SKS)
class KhsPage extends StatefulWidget {
  final String mahasiswaId;
  final String nama;
  final String nim;
  final String jurusan;

  const KhsPage({
    super.key,
    required this.mahasiswaId,
    required this.nama,
    required this.nim,
    required this.jurusan,
  });

  @override
  State<KhsPage> createState() => _KhsPageState();
}

class _KhsPageState extends State<KhsPage> {
  final String baseUrl = 'http://192.168.43.167/flutter_api/';

  List _nilaiList = [];
  List _jadwalList = [];
  List _matkulList = [];
  bool _isLoading = true;
  bool _isExporting = false;

  @override
  void initState() {
    super.initState();
    _getData();
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

  Map? _jadwalOf(dynamic jadwalId) =>
      _jadwalList.firstWhere((e) => e['id'].toString() == jadwalId.toString(), orElse: () => null);

  Map? _matkulOf(dynamic mataKuliahId) =>
      _matkulList.firstWhere((e) => e['id'].toString() == mataKuliahId.toString(), orElse: () => null);

  /// Mengelompokkan nilai per (semester, tahun_ajaran) berdasarkan data jadwal
  /// tempat mata kuliah itu diambil, lalu diurutkan dari semester terbaru.
  List<KhsSemesterGroup> get _semesterGroups {
    final Map<String, List<KhsItem>> grouped = {};
    final Map<String, int> semesterOf = {};
    final Map<String, String> tahunOf = {};

    for (final n in _nilaiList) {
      final jadwal = _jadwalOf(n['jadwal_id']);
      if (jadwal == null) continue;
      final matkul = _matkulOf(jadwal['mata_kuliah_id']);
      if (matkul == null) continue;

      final semester = jadwal['semester'];
      final tahunAjaran = (jadwal['tahun_ajaran'] ?? '-').toString();
      final key = '$semester|$tahunAjaran';

      grouped.putIfAbsent(key, () => []);
      semesterOf[key] = int.tryParse(semester.toString()) ?? 0;
      tahunOf[key] = tahunAjaran;

      grouped[key]!.add(KhsItem(
        kodeMk: matkul['kode_mk']?.toString() ?? '-',
        namaMk: matkul['nama_mk']?.toString() ?? '-',
        sks: int.tryParse(matkul['sks']?.toString() ?? '') ?? 0,
        nilaiHuruf: (n['nilai_huruf'] ?? '-').toString(),
      ));
    }

    final groups = grouped.entries
        .map((e) => KhsSemesterGroup(semester: semesterOf[e.key]!, tahunAjaran: tahunOf[e.key]!, items: e.value))
        .toList();

    groups.sort((a, b) {
      final t = b.tahunAjaran.compareTo(a.tahunAjaran);
      if (t != 0) return t;
      return b.semester.compareTo(a.semester);
    });

    return groups;
  }

  ({double sks, double mutu, double ips}) _hitung(List<KhsItem> items) {
    double sks = 0;
    double mutu = 0;
    for (final item in items) {
      sks += item.sks;
      mutu += PdfHelper.bobotHuruf(item.nilaiHuruf) * item.sks;
    }
    return (sks: sks, mutu: mutu, ips: sks == 0 ? 0 : mutu / sks);
  }

  ({double sks, double mutu, double ipk}) get _kumulatif {
    double sks = 0;
    double mutu = 0;
    for (final g in _semesterGroups) {
      final h = _hitung(g.items);
      sks += h.sks;
      mutu += h.mutu;
    }
    return (sks: sks, mutu: mutu, ipk: sks == 0 ? 0 : mutu / sks);
  }

  Future<void> _cetak({KhsSemesterGroup? hanyaSemesterIni}) async {
    setState(() => _isExporting = true);
    try {
      final groups = hanyaSemesterIni != null ? [hanyaSemesterIni] : _semesterGroups;
      final doc = await PdfHelper.buildKhs(
        nama: widget.nama,
        nim: widget.nim,
        jurusan: widget.jurusan,
        semesterGroups: groups,
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
    final groups = _semesterGroups;
    final kumulatif = _kumulatif;

    return Scaffold(
      appBar: AppBar(
        title: const Text('KHS Saya'),
        actions: [
          IconButton(tooltip: 'Refresh', onPressed: _getData, icon: const Icon(Icons.refresh)),
          IconButton(
            tooltip: 'Cetak Transkrip Lengkap',
            onPressed: (_isExporting || groups.isEmpty) ? null : () => _cetak(),
            icon: const Icon(Icons.picture_as_pdf_outlined),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : groups.isEmpty
              ? const Center(child: Text('Belum ada nilai yang bisa ditampilkan sebagai KHS'))
              : ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(colors: [AppTheme.primary, AppTheme.primaryDark]),
                        borderRadius: BorderRadius.circular(18),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('IPK Kumulatif', style: TextStyle(color: Colors.white70, fontSize: 12.5)),
                              const SizedBox(height: 4),
                              Text(kumulatif.ipk.toStringAsFixed(2),
                                  style: const TextStyle(color: Colors.white, fontSize: 26, fontWeight: FontWeight.bold)),
                            ],
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              const Text('Total SKS Lulus', style: TextStyle(color: Colors.white70, fontSize: 12.5)),
                              const SizedBox(height: 4),
                              Text(kumulatif.sks.toStringAsFixed(0),
                                  style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    ...groups.map((g) {
                      final h = _hitung(g.items);
                      return Container(
                        margin: const EdgeInsets.only(bottom: 14),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: AppTheme.cardBorder),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Padding(
                              padding: const EdgeInsets.fromLTRB(16, 14, 8, 8),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                    child: Text(
                                      'Semester ${g.semester} • T.A. ${g.tahunAjaran}',
                                      style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14.5),
                                    ),
                                  ),
                                  IconButton(
                                    tooltip: 'Cetak KHS semester ini',
                                    icon: const Icon(Icons.print_outlined, color: AppTheme.primary),
                                    onPressed: _isExporting ? null : () => _cetak(hanyaSemesterIni: g),
                                  ),
                                ],
                              ),
                            ),
                            const Divider(height: 1),
                            ...g.items.map((item) => Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                                  child: Row(
                                    children: [
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(item.namaMk, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13.5)),
                                            Text('${item.kodeMk} • ${item.sks} SKS',
                                                style: const TextStyle(fontSize: 11.5, color: Color(0xFF9CA3AF))),
                                          ],
                                        ),
                                      ),
                                      CircleAvatar(
                                        radius: 16,
                                        backgroundColor: _hurufColor(item.nilaiHuruf).withOpacity(0.15),
                                        child: Text(item.nilaiHuruf,
                                            style: TextStyle(color: _hurufColor(item.nilaiHuruf), fontWeight: FontWeight.bold, fontSize: 12.5)),
                                      ),
                                    ],
                                  ),
                                )),
                            const Divider(height: 1),
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text('Total ${h.sks.toStringAsFixed(0)} SKS', style: const TextStyle(fontSize: 12, color: Color(0xFF6B7280))),
                                  Text('IPS: ${h.ips.toStringAsFixed(2)}',
                                      style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.primary, fontSize: 13)),
                                ],
                              ),
                            ),
                          ],
                        ),
                      );
                    }),
                  ],
                ),
    );
  }
}
