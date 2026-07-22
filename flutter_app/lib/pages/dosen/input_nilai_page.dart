import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

/// InputNilaiPage (Dosen)
/// Dosen menginput/mengubah nilai hanya untuk mahasiswa yang KRS-nya sudah
/// disetujui di kelas/jadwal miliknya sendiri.
///
/// Endpoint PHP:
/// - tampil_jadwal.php, tampil_matkul.php, tampil_mahasiswa.php, tampil_krs.php
/// - tampil_nilai.php, simpan_nilai.php, edit_nilai.php, hapus_nilai.php
class InputNilaiPage extends StatefulWidget {
  final String dosenId;
  const InputNilaiPage({super.key, required this.dosenId});

  @override
  State<InputNilaiPage> createState() => _InputNilaiPageState();
}

class _InputNilaiPageState extends State<InputNilaiPage> {
  final String baseUrl = 'http://192.168.43.167/flutter_api/';

  List _jadwalList = [];
  List _matkulList = [];
  List _mahasiswaList = [];
  List _krsList = [];
  List _nilaiList = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _getData();
  }

  static double _toDouble(dynamic v) => double.tryParse(v?.toString() ?? '') ?? 0;

  static String _hurufFrom(double akhir) {
    if (akhir >= 85) return 'A';
    if (akhir >= 75) return 'B';
    if (akhir >= 65) return 'C';
    if (akhir >= 50) return 'D';
    return 'E';
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
    return m == null ? '-' : '${m['nama']} (${m['nim']})';
  }

  /// Mahasiswa dengan KRS Disetujui pada jadwal-jadwal milik dosen ini,
  /// dan belum punya nilai untuk jadwal itu (kecuali sedang mengedit).
  List<Map> _mahasiswaBisaDinilai(String jadwalId, {dynamic excludeNilaiId}) {
    final sudahDinilai = _nilaiList
        .where((n) => n['jadwal_id'].toString() == jadwalId && n['id'].toString() != excludeNilaiId?.toString())
        .map((n) => n['mahasiswa_id'].toString())
        .toSet();

    return _krsList
        .where((k) =>
            k['jadwal_id'].toString() == jadwalId &&
            (k['status'] ?? '') == 'Disetujui' &&
            !sudahDinilai.contains(k['mahasiswa_id'].toString()))
        .map<Map>((k) => _mahasiswaList.firstWhere(
              (m) => m['id'].toString() == k['mahasiswa_id'].toString(),
              orElse: () => {},
            ))
        .where((m) => m.isNotEmpty)
        .toList();
  }

  Future<void> _getData() async {
    setState(() => _isLoading = true);
    try {
      final results = await Future.wait([
        http.get(Uri.parse('${baseUrl}tampil_jadwal.php')),
        http.get(Uri.parse('${baseUrl}tampil_matkul.php')),
        http.get(Uri.parse('${baseUrl}tampil_mahasiswa.php')),
        http.get(Uri.parse('${baseUrl}tampil_krs.php')),
        http.get(Uri.parse('${baseUrl}tampil_nilai.php')),
      ]);
      if (!mounted) return;
      setState(() {
        _jadwalList = jsonDecode(results[0].body);
        _matkulList = jsonDecode(results[1].body);
        _mahasiswaList = jsonDecode(results[2].body);
        _krsList = jsonDecode(results[3].body);
        _nilaiList = jsonDecode(results[4].body);
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

  List get _nilaiSaya {
    final jadwalIds = _jadwalSaya.map((j) => j['id'].toString()).toSet();
    return _nilaiList.where((n) => jadwalIds.contains(n['jadwal_id'].toString())).toList();
  }

  Future<void> _confirmDelete(Map nilai) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hapus Nilai'),
        content: Text('Hapus nilai ${_namaMahasiswa(nilai['mahasiswa_id'])}?'),
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
    if (confirm != true) return;

    try {
      final response = await http.post(
        Uri.parse('${baseUrl}hapus_nilai.php'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'id': nilai['id'].toString()}),
      );
      final data = jsonDecode(response.body);
      if (!mounted) return;
      if (data['success'] == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Nilai berhasil dihapus'), backgroundColor: Colors.green),
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

  Future<void> _showForm({Map? existing}) async {
    if (_jadwalSaya.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Kamu belum punya jadwal mengajar'), backgroundColor: Colors.orange),
      );
      return;
    }

    final formKey = GlobalKey<FormState>();
    String? jadwalId = existing?['jadwal_id']?.toString();
    String? mahasiswaId = existing?['mahasiswa_id']?.toString();
    final tugasController = TextEditingController(text: existing?['tugas']?.toString() ?? '');
    final utsController = TextEditingController(text: existing?['uts']?.toString() ?? '');
    final uasController = TextEditingController(text: existing?['uas']?.toString() ?? '');

    if (!_jadwalSaya.any((e) => e['id'].toString() == jadwalId)) {
      jadwalId = _jadwalSaya.first['id'].toString();
    }

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          final options = _mahasiswaBisaDinilai(jadwalId!, excludeNilaiId: existing?['id']);
          if (!options.any((m) => m['id'].toString() == mahasiswaId)) {
            mahasiswaId = options.isNotEmpty ? options.first['id'].toString() : null;
          }

          final tugas = _toDouble(tugasController.text);
          final uts = _toDouble(utsController.text);
          final uas = _toDouble(uasController.text);
          final akhir = (tugas * 0.2) + (uts * 0.35) + (uas * 0.45);
          final huruf = _hurufFrom(akhir);

          return AlertDialog(
            title: Text(existing == null ? 'Input Nilai' : 'Edit Nilai'),
            content: SizedBox(
              width: 440,
              child: Form(
                key: formKey,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      DropdownButtonFormField<String>(
                        value: jadwalId,
                        decoration: const InputDecoration(labelText: 'Kelas / Mata Kuliah'),
                        items: _jadwalSaya
                            .map<DropdownMenuItem<String>>((j) => DropdownMenuItem(
                                  value: j['id'].toString(),
                                  child: Text(_namaMatkul(j['id']), overflow: TextOverflow.ellipsis),
                                ))
                            .toList(),
                        onChanged: existing != null
                            ? null // saat edit, kelas & mahasiswa dikunci
                            : (v) => setDialogState(() {
                                  jadwalId = v;
                                  mahasiswaId = null;
                                }),
                        validator: (v) => v == null ? 'Pilih kelas' : null,
                      ),
                      const SizedBox(height: 12),
                      DropdownButtonFormField<String>(
                        value: mahasiswaId,
                        decoration: const InputDecoration(labelText: 'Mahasiswa'),
                        items: existing != null
                            ? [
                                DropdownMenuItem(
                                  value: mahasiswaId,
                                  child: Text(_namaMahasiswa(mahasiswaId), overflow: TextOverflow.ellipsis),
                                ),
                              ]
                            : options
                                .map<DropdownMenuItem<String>>((m) => DropdownMenuItem(
                                      value: m['id'].toString(),
                                      child: Text('${m['nama']} (${m['nim']})', overflow: TextOverflow.ellipsis),
                                    ))
                                .toList(),
                        onChanged: existing != null ? null : (v) => setDialogState(() => mahasiswaId = v),
                        validator: (v) => v == null ? 'Pilih mahasiswa' : null,
                      ),
                      if (existing == null && options.isEmpty)
                        const Padding(
                          padding: EdgeInsets.only(top: 4),
                          child: Text(
                            'Semua mahasiswa di kelas ini sudah dinilai, atau belum ada KRS yang disetujui.',
                            style: TextStyle(fontSize: 12, color: Colors.red),
                          ),
                        ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: tugasController,
                        decoration: const InputDecoration(labelText: 'Nilai Tugas (0-100)'),
                        keyboardType: TextInputType.number,
                        onChanged: (_) => setDialogState(() {}),
                        validator: (v) => (v == null || v.trim().isEmpty) ? 'Wajib diisi' : null,
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: utsController,
                        decoration: const InputDecoration(labelText: 'Nilai UTS (0-100)'),
                        keyboardType: TextInputType.number,
                        onChanged: (_) => setDialogState(() {}),
                        validator: (v) => (v == null || v.trim().isEmpty) ? 'Wajib diisi' : null,
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: uasController,
                        decoration: const InputDecoration(labelText: 'Nilai UAS (0-100)'),
                        keyboardType: TextInputType.number,
                        onChanged: (_) => setDialogState(() {}),
                        validator: (v) => (v == null || v.trim().isEmpty) ? 'Wajib diisi' : null,
                      ),
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(color: Colors.teal.shade50, borderRadius: BorderRadius.circular(8)),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('Nilai Akhir: ${akhir.toStringAsFixed(2)}'),
                            Text('Huruf: $huruf', style: const TextStyle(fontWeight: FontWeight.bold)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Batal')),
              ElevatedButton(
                onPressed: mahasiswaId == null
                    ? null
                    : () {
                        if (!(formKey.currentState?.validate() ?? false)) return;
                        Navigator.pop(context, true);
                      },
                child: const Text('Simpan'),
              ),
            ],
          );
        },
      ),
    );

    if (result != true || mahasiswaId == null || jadwalId == null) return;

    final tugas = _toDouble(tugasController.text);
    final uts = _toDouble(utsController.text);
    final uas = _toDouble(uasController.text);
    final akhir = (tugas * 0.2) + (uts * 0.35) + (uas * 0.45);
    final huruf = _hurufFrom(akhir);

    final body = {
      'mahasiswa_id': mahasiswaId,
      'jadwal_id': jadwalId,
      'tugas': tugasController.text.trim(),
      'uts': utsController.text.trim(),
      'uas': uasController.text.trim(),
      'nilai_akhir': akhir.toStringAsFixed(2),
      'nilai_huruf': huruf,
    };

    setState(() => _isLoading = true);
    try {
      final url = existing == null ? 'simpan_nilai.php' : 'edit_nilai.php';
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
            content: Text(existing == null ? 'Nilai berhasil disimpan' : 'Nilai berhasil diubah'),
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

  @override
  Widget build(BuildContext context) {
    final data = _nilaiSaya;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Input Nilai'),
        foregroundColor: Colors.white,
        actions: [
          IconButton(tooltip: 'Refresh', onPressed: _getData, icon: const Icon(Icons.refresh)),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : data.isEmpty
              ? const Center(child: Text('Belum ada nilai yang diinput'))
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: data.length,
                  itemBuilder: (context, index) {
                    final n = data[index];
                    return Card(
                      elevation: 2,
                      margin: const EdgeInsets.only(bottom: 10),
                      child: ListTile(
                        title: Text(_namaMahasiswa(n['mahasiswa_id'])),
                        subtitle: Text(
                          '${_namaMatkul(n['jadwal_id'])}\nTugas ${n['tugas']} • UTS ${n['uts']} • UAS ${n['uas']} • Akhir ${n['nilai_akhir']} (${n['nilai_huruf']})',
                        ),
                        isThreeLine: true,
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              tooltip: 'Edit',
                              icon: const Icon(Icons.edit, color: Colors.orange),
                              onPressed: () => _showForm(existing: n),
                            ),
                            IconButton(
                              tooltip: 'Hapus',
                              icon: const Icon(Icons.delete, color: Colors.red),
                              onPressed: () => _confirmDelete(n),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showForm(),
        child: const Icon(Icons.add),
      ),
    );
  }
}
