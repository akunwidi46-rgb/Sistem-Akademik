import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

/// NilaiPage
/// CRUD Nilai Mahasiswa untuk Admin.
/// Nilai akhir & nilai huruf dihitung otomatis dari Tugas (20%), UTS (35%), UAS (45%).
///
/// Endpoint PHP:
/// - tampil_nilai.php, simpan_nilai.php, edit_nilai.php, hapus_nilai.php
/// - tampil_mahasiswa.php (dropdown mahasiswa)
/// - tampil_jadwal.php + tampil_matkul.php (dropdown jadwal/mata kuliah)
class NilaiPage extends StatefulWidget {
  const NilaiPage({super.key});

  @override
  State<NilaiPage> createState() => _NilaiPageState();
}

class _NilaiPageState extends State<NilaiPage> {
  final String baseUrl = 'http://192.168.43.167/flutter_api/';

  List _list = [];
  List _mahasiswaList = [];
  List _jadwalList = [];
  List _matkulList = [];
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

  String _namaMahasiswa(dynamic id) {
    final m = _mahasiswaList.firstWhere((e) => e['id'].toString() == id.toString(), orElse: () => null);
    return m == null ? '-' : '${m['nama']} (${m['nim']})';
  }

  String _namaJadwal(dynamic id) {
    final j = _jadwalList.firstWhere((e) => e['id'].toString() == id.toString(), orElse: () => null);
    if (j == null) return '-';
    final mk = _matkulList.firstWhere(
      (e) => e['id'].toString() == j['mata_kuliah_id'].toString(),
      orElse: () => null,
    );
    return mk == null ? 'Jadwal #$id' : '${mk['nama_mk']} (${j['kelas'] ?? '-'})';
  }

  Future<void> _getData() async {
    setState(() => _isLoading = true);
    try {
      final results = await Future.wait([
        http.get(Uri.parse('${baseUrl}tampil_nilai.php')),
        http.get(Uri.parse('${baseUrl}tampil_mahasiswa.php')),
        http.get(Uri.parse('${baseUrl}tampil_jadwal.php')),
        http.get(Uri.parse('${baseUrl}tampil_matkul.php')),
      ]);
      if (!mounted) return;
      setState(() {
        _list = jsonDecode(results[0].body);
        _mahasiswaList = jsonDecode(results[1].body);
        _jadwalList = jsonDecode(results[2].body);
        _matkulList = jsonDecode(results[3].body);
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

  Future<void> _deleteData(String id) async {
    try {
      final response = await http.post(
        Uri.parse('${baseUrl}hapus_nilai.php'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'id': id}),
      );
      final data = jsonDecode(response.body);
      if (!mounted) return;

      if (data['success'] == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Nilai berhasil dihapus'), backgroundColor: Colors.green),
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
    if (confirm == true) _deleteData(nilai['id'].toString());
  }

  Future<void> _showForm({Map? existing}) async {
    if (_mahasiswaList.isEmpty || _jadwalList.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Data Mahasiswa / Jadwal masih kosong. Tambahkan dulu sebelum input nilai.'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    final formKey = GlobalKey<FormState>();
    String? mahasiswaId = existing?['mahasiswa_id']?.toString();
    String? jadwalId = existing?['jadwal_id']?.toString();
    final tugasController = TextEditingController(text: existing?['tugas']?.toString() ?? '');
    final utsController = TextEditingController(text: existing?['uts']?.toString() ?? '');
    final uasController = TextEditingController(text: existing?['uas']?.toString() ?? '');

    if (!_mahasiswaList.any((e) => e['id'].toString() == mahasiswaId)) mahasiswaId = null;
    if (!_jadwalList.any((e) => e['id'].toString() == jadwalId)) jadwalId = null;

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
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
                        value: mahasiswaId,
                        decoration: const InputDecoration(labelText: 'Mahasiswa'),
                        items: _mahasiswaList
                            .map<DropdownMenuItem<String>>((m) => DropdownMenuItem(
                                  value: m['id'].toString(),
                                  child: Text('${m['nama']} (${m['nim']})', overflow: TextOverflow.ellipsis),
                                ))
                            .toList(),
                        onChanged: (v) => setDialogState(() => mahasiswaId = v),
                        validator: (v) => v == null ? 'Pilih mahasiswa' : null,
                      ),
                      const SizedBox(height: 12),
                      DropdownButtonFormField<String>(
                        value: jadwalId,
                        decoration: const InputDecoration(labelText: 'Mata Kuliah / Jadwal'),
                        items: _jadwalList
                            .map<DropdownMenuItem<String>>((j) => DropdownMenuItem(
                                  value: j['id'].toString(),
                                  child: Text(_namaJadwal(j['id']), overflow: TextOverflow.ellipsis),
                                ))
                            .toList(),
                        onChanged: (v) => setDialogState(() => jadwalId = v),
                        validator: (v) => v == null ? 'Pilih jadwal' : null,
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
                        decoration: BoxDecoration(
                          color: Colors.teal.shade50,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('Nilai Akhir: ${akhir.toStringAsFixed(2)}'),
                            Text('Huruf: $huruf', style: const TextStyle(fontWeight: FontWeight.bold)),
                          ],
                        ),
                      ),
                      const Padding(
                        padding: EdgeInsets.only(top: 6),
                        child: Text(
                          'Nilai akhir = Tugas 20% + UTS 35% + UAS 45%',
                          style: TextStyle(fontSize: 11, color: Colors.grey),
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
                onPressed: () {
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

    if (result != true) return;

    final tugas = _toDouble(tugasController.text);
    final uts = _toDouble(utsController.text);
    final uas = _toDouble(uasController.text);
    final akhir = (tugas * 0.2) + (uts * 0.35) + (uas * 0.45);
    final huruf = _hurufFrom(akhir);

    final body = {
      'mahasiswa_id': mahasiswaId ?? '',
      'jadwal_id': jadwalId ?? '',
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
                    headingRowColor: WidgetStateProperty.all(Colors.teal.shade50),
                    columnSpacing: 24,
                    columns: const [
                      DataColumn(label: Text('No')),
                      DataColumn(label: Text('Mahasiswa')),
                      DataColumn(label: Text('Mata Kuliah')),
                      DataColumn(label: Text('Tugas')),
                      DataColumn(label: Text('UTS')),
                      DataColumn(label: Text('UAS')),
                      DataColumn(label: Text('Akhir')),
                      DataColumn(label: Text('Huruf')),
                      DataColumn(label: Text('Aksi')),
                    ],
                    rows: List.generate(_list.length, (index) {
                      final n = _list[index];
                      return DataRow(cells: [
                        DataCell(Text('${index + 1}')),
                        DataCell(Text(_namaMahasiswa(n['mahasiswa_id']))),
                        DataCell(Text(_namaJadwal(n['jadwal_id']))),
                        DataCell(Text('${n['tugas'] ?? '-'}')),
                        DataCell(Text('${n['uts'] ?? '-'}')),
                        DataCell(Text('${n['uas'] ?? '-'}')),
                        DataCell(Text('${n['nilai_akhir'] ?? '-'}')),
                        DataCell(Text('${n['nilai_huruf'] ?? '-'}')),
                        DataCell(Row(
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
        title: const Text('Nilai'),
        foregroundColor: Colors.white,
        actions: [
          IconButton(tooltip: 'Refresh', onPressed: _getData, icon: const Icon(Icons.refresh)),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _list.isEmpty
              ? const Center(child: Text('Belum ada data nilai'))
              : _buildTable(),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showForm(),
        child: const Icon(Icons.add),
      ),
    );
  }
}
