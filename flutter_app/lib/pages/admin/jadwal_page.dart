import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

/// JadwalPage
/// CRUD Jadwal Kuliah untuk Admin.
///
/// Endpoint PHP:
/// - tampil_jadwal.php, simpan_jadwal.php, edit_jadwal.php, hapus_jadwal.php
/// - tampil_matkul.php (untuk dropdown mata kuliah)
/// - tampil_dosen.php (untuk dropdown dosen)
class JadwalPage extends StatefulWidget {
  const JadwalPage({super.key});

  @override
  State<JadwalPage> createState() => _JadwalPageState();
}

class _JadwalPageState extends State<JadwalPage> {
  final String baseUrl = 'http://192.168.43.167/flutter_api/';
  static const hariOptions = ['Senin', 'Selasa', 'Rabu', 'Kamis', "Jum'at", 'Sabtu'];

  List _list = [];
  List _matkulList = [];
  List _dosenList = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _getData();
  }

  String _namaMatkul(dynamic id) {
    final mk = _matkulList.firstWhere(
      (e) => e['id'].toString() == id.toString(),
      orElse: () => null,
    );
    return mk == null ? '-' : '${mk['kode_mk']} - ${mk['nama_mk']}';
  }

  String _namaDosen(dynamic id) {
    final d = _dosenList.firstWhere(
      (e) => e['id'].toString() == id.toString(),
      orElse: () => null,
    );
    return d == null ? '-' : '${d['nama']}';
  }

  Future<void> _getData() async {
    setState(() => _isLoading = true);
    try {
      final results = await Future.wait([
        http.get(Uri.parse('${baseUrl}tampil_jadwal.php')),
        http.get(Uri.parse('${baseUrl}tampil_matkul.php')),
        http.get(Uri.parse('${baseUrl}tampil_dosen.php')),
      ]);
      if (!mounted) return;
      setState(() {
        _list = jsonDecode(results[0].body);
        _matkulList = jsonDecode(results[1].body);
        _dosenList = jsonDecode(results[2].body);
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
        Uri.parse('${baseUrl}hapus_jadwal.php'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'id': id}),
      );
      final data = jsonDecode(response.body);
      if (!mounted) return;

      if (data['success'] == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Jadwal berhasil dihapus'), backgroundColor: Colors.green),
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

  Future<void> _confirmDelete(Map jadwal) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hapus Jadwal'),
        content: Text('Hapus jadwal ${_namaMatkul(jadwal['mata_kuliah_id'])} (${jadwal['hari']})?'),
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
    if (confirm == true) _deleteData(jadwal['id'].toString());
  }

  Future<TimeOfDay?> _pickTime(String initial) async {
    TimeOfDay initTime = TimeOfDay.now();
    if (initial.isNotEmpty) {
      final parts = initial.split(':');
      if (parts.length >= 2) {
        initTime = TimeOfDay(hour: int.tryParse(parts[0]) ?? 0, minute: int.tryParse(parts[1]) ?? 0);
      }
    }
    return showTimePicker(context: context, initialTime: initTime);
  }

  String _formatTime(TimeOfDay t) =>
      '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}:00';

  Future<void> _showForm({Map? existing}) async {
    if (_matkulList.isEmpty || _dosenList.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Data Mata Kuliah / Dosen masih kosong. Tambahkan dulu sebelum membuat jadwal.'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    final formKey = GlobalKey<FormState>();
    String? matkulId = existing?['mata_kuliah_id']?.toString();
    String? dosenId = existing?['dosen_id']?.toString();
    String? hari = existing?['hari']?.toString();
    final jamMulaiController = TextEditingController(text: existing?['jam_mulai']?.toString() ?? '');
    final jamSelesaiController = TextEditingController(text: existing?['jam_selesai']?.toString() ?? '');
    final ruanganController = TextEditingController(text: existing?['ruangan']?.toString() ?? '');
    final kelasController = TextEditingController(text: existing?['kelas']?.toString() ?? '');
    final semesterController = TextEditingController(text: existing?['semester']?.toString() ?? '');
    final tahunAjaranController = TextEditingController(text: existing?['tahun_ajaran']?.toString() ?? '');

    // Pastikan value dropdown valid (ada di list), kalau tidak biarkan null.
    if (!_matkulList.any((e) => e['id'].toString() == matkulId)) matkulId = null;
    if (!_dosenList.any((e) => e['id'].toString() == dosenId)) dosenId = null;
    if (!hariOptions.contains(hari)) hari = null;

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(existing == null ? 'Tambah Jadwal' : 'Edit Jadwal'),
          content: SizedBox(
            width: 460,
            child: Form(
              key: formKey,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    DropdownButtonFormField<String>(
                      value: matkulId,
                      decoration: const InputDecoration(labelText: 'Mata Kuliah'),
                      items: _matkulList
                          .map<DropdownMenuItem<String>>((mk) => DropdownMenuItem(
                                value: mk['id'].toString(),
                                child: Text('${mk['kode_mk']} - ${mk['nama_mk']}', overflow: TextOverflow.ellipsis),
                              ))
                          .toList(),
                      onChanged: (v) => setDialogState(() => matkulId = v),
                      validator: (v) => v == null ? 'Pilih mata kuliah' : null,
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      value: dosenId,
                      decoration: const InputDecoration(labelText: 'Dosen Pengajar'),
                      items: _dosenList
                          .map<DropdownMenuItem<String>>((d) => DropdownMenuItem(
                                value: d['id'].toString(),
                                child: Text('${d['nama']}', overflow: TextOverflow.ellipsis),
                              ))
                          .toList(),
                      onChanged: (v) => setDialogState(() => dosenId = v),
                      validator: (v) => v == null ? 'Pilih dosen' : null,
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      value: hari,
                      decoration: const InputDecoration(labelText: 'Hari'),
                      items: hariOptions
                          .map((h) => DropdownMenuItem(value: h, child: Text(h)))
                          .toList(),
                      onChanged: (v) => setDialogState(() => hari = v),
                      validator: (v) => v == null ? 'Pilih hari' : null,
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: jamMulaiController,
                            readOnly: true,
                            decoration: const InputDecoration(labelText: 'Jam Mulai'),
                            onTap: () async {
                              final t = await _pickTime(jamMulaiController.text);
                              if (t != null) setDialogState(() => jamMulaiController.text = _formatTime(t));
                            },
                            validator: (v) => (v == null || v.isEmpty) ? 'Wajib diisi' : null,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextFormField(
                            controller: jamSelesaiController,
                            readOnly: true,
                            decoration: const InputDecoration(labelText: 'Jam Selesai'),
                            onTap: () async {
                              final t = await _pickTime(jamSelesaiController.text);
                              if (t != null) setDialogState(() => jamSelesaiController.text = _formatTime(t));
                            },
                            validator: (v) => (v == null || v.isEmpty) ? 'Wajib diisi' : null,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: ruanganController,
                      decoration: const InputDecoration(labelText: 'Ruangan'),
                      validator: (v) => (v == null || v.trim().isEmpty) ? 'Ruangan wajib diisi' : null,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: kelasController,
                      decoration: const InputDecoration(labelText: 'Kelas'),
                      validator: (v) => (v == null || v.trim().isEmpty) ? 'Kelas wajib diisi' : null,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: semesterController,
                      decoration: const InputDecoration(labelText: 'Semester'),
                      keyboardType: TextInputType.number,
                      validator: (v) => (v == null || v.trim().isEmpty) ? 'Semester wajib diisi' : null,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: tahunAjaranController,
                      decoration: const InputDecoration(labelText: 'Tahun Ajaran (contoh: 2025/2026)'),
                      validator: (v) => (v == null || v.trim().isEmpty) ? 'Tahun ajaran wajib diisi' : null,
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
        ),
      ),
    );

    if (result != true) return;

    final body = {
      'mata_kuliah_id': matkulId ?? '',
      'dosen_id': dosenId ?? '',
      'hari': hari ?? '',
      'jam_mulai': jamMulaiController.text.trim(),
      'jam_selesai': jamSelesaiController.text.trim(),
      'ruangan': ruanganController.text.trim(),
      'kelas': kelasController.text.trim(),
      'semester': semesterController.text.trim(),
      'tahun_ajaran': tahunAjaranController.text.trim(),
    };

    setState(() => _isLoading = true);
    try {
      final url = existing == null ? 'simpan_jadwal.php' : 'edit_jadwal.php';
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
            content: Text(existing == null ? 'Jadwal berhasil ditambahkan' : 'Jadwal berhasil diubah'),
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
                    headingRowColor: WidgetStateProperty.all(Colors.red.shade50),
                    columnSpacing: 24,
                    columns: const [
                      DataColumn(label: Text('No')),
                      DataColumn(label: Text('Mata Kuliah')),
                      DataColumn(label: Text('Dosen')),
                      DataColumn(label: Text('Hari')),
                      DataColumn(label: Text('Jam')),
                      DataColumn(label: Text('Ruangan')),
                      DataColumn(label: Text('Kelas')),
                      DataColumn(label: Text('Aksi')),
                    ],
                    rows: List.generate(_list.length, (index) {
                      final j = _list[index];
                      return DataRow(cells: [
                        DataCell(Text('${index + 1}')),
                        DataCell(Text(_namaMatkul(j['mata_kuliah_id']))),
                        DataCell(Text(_namaDosen(j['dosen_id']))),
                        DataCell(Text('${j['hari'] ?? '-'}')),
                        DataCell(Text('${j['jam_mulai'] ?? '-'} - ${j['jam_selesai'] ?? '-'}')),
                        DataCell(Text('${j['ruangan'] ?? '-'}')),
                        DataCell(Text('${j['kelas'] ?? '-'}')),
                        DataCell(Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              tooltip: 'Edit',
                              icon: const Icon(Icons.edit, color: Colors.orange),
                              onPressed: () => _showForm(existing: j),
                            ),
                            IconButton(
                              tooltip: 'Hapus',
                              icon: const Icon(Icons.delete, color: Colors.red),
                              onPressed: () => _confirmDelete(j),
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
        title: const Text('Jadwal'),
        foregroundColor: Colors.white,
        actions: [
          IconButton(tooltip: 'Refresh', onPressed: _getData, icon: const Icon(Icons.refresh)),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _list.isEmpty
              ? const Center(child: Text('Belum ada data jadwal'))
              : _buildTable(),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showForm(),
        child: const Icon(Icons.add),
      ),
    );
  }
}
