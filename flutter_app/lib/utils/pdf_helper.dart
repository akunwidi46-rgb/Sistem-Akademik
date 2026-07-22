import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

/// PdfHelper
/// Kumpulan fungsi untuk membangun dokumen PDF KHS (Kartu Hasil Studi)
/// dan KRS (Kartu Rencana Studi) mahasiswa, dipakai oleh KhsPage dan
/// KrsSayaPage lewat package:printing untuk cetak/simpan/bagikan.
class PdfHelper {
  PdfHelper._();

  static const _bulanIndonesia = [
    'Januari', 'Februari', 'Maret', 'April', 'Mei', 'Juni',
    'Juli', 'Agustus', 'September', 'Oktober', 'November', 'Desember',
  ];

  /// Format tanggal manual ("11 Juli 2026") tanpa bergantung pada
  /// inisialisasi locale package:intl, supaya tidak ada risiko error
  /// runtime kalau locale belum di-inisialisasi di main().
  static String _formatTanggalIndonesia(DateTime date) {
    return '${date.day} ${_bulanIndonesia[date.month - 1]} ${date.year}';
  }

  static final _headerColor = PdfColor.fromInt(0xFF4F46E5);
  static final _borderColor = PdfColor.fromInt(0xFFE5E7EB);
  static final _mutedColor = PdfColor.fromInt(0xFF6B7280);

  static pw.Widget _kopSurat(String judul) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.center,
      children: [
        pw.Text(
          'SIAKAD - SISTEM INFORMASI AKADEMIK',
          style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold, color: _headerColor),
        ),
        pw.SizedBox(height: 2),
        pw.Text(judul, style: pw.TextStyle(fontSize: 12, color: _mutedColor)),
        pw.SizedBox(height: 10),
        pw.Divider(color: _headerColor, thickness: 1.4),
        pw.SizedBox(height: 10),
      ],
    );
  }

  static pw.Widget _infoRow(String label, String value) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 3),
      child: pw.Row(
        children: [
          pw.SizedBox(width: 110, child: pw.Text(label, style: pw.TextStyle(fontSize: 10, color: _mutedColor))),
          pw.Text(':  ', style: const pw.TextStyle(fontSize: 10)),
          pw.Text(value, style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold)),
        ],
      ),
    );
  }

  static pw.TableRow _headerRow(List<String> labels) {
    return pw.TableRow(
      decoration: pw.BoxDecoration(color: PdfColor.fromInt(0xFFF3F4F6)),
      children: labels
          .map((l) => pw.Padding(
                padding: const pw.EdgeInsets.symmetric(vertical: 6, horizontal: 4),
                child: pw.Text(l, style: pw.TextStyle(fontSize: 9.5, fontWeight: pw.FontWeight.bold)),
              ))
          .toList(),
    );
  }

  static pw.Widget _cell(String text, {pw.TextAlign align = pw.TextAlign.left}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 5, horizontal: 4),
      child: pw.Text(text, style: const pw.TextStyle(fontSize: 9.5), textAlign: align),
    );
  }

  static double bobotHuruf(String huruf) {
    switch (huruf) {
      case 'A':
        return 4;
      case 'B':
        return 3;
      case 'C':
        return 2;
      case 'D':
        return 1;
      default:
        return 0;
    }
  }

  /// Membuat dokumen PDF KHS untuk satu kelompok semester (satu tahun ajaran
  /// + semester tertentu), lengkap dengan IPS. [semesterGroups] berisi
  /// beberapa kelompok kalau ingin dicetak sekaligus (transkrip lengkap),
  /// atau cukup satu kelompok untuk KHS per semester.
  static Future<pw.Document> buildKhs({
    required String nama,
    required String nim,
    required String jurusan,
    required List<KhsSemesterGroup> semesterGroups,
  }) async {
    final doc = pw.Document();
    final tanggalCetak = _formatTanggalIndonesia(DateTime.now());

    double totalSksKumulatif = 0;
    double totalMutuKumulatif = 0;

    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (context) {
          final widgets = <pw.Widget>[
            _kopSurat(semesterGroups.length > 1 ? 'TRANSKRIP NILAI' : 'KARTU HASIL STUDI (KHS)'),
            _infoRow('Nama', nama),
            _infoRow('NIM', nim),
            _infoRow('Jurusan', jurusan),
            pw.SizedBox(height: 12),
          ];

          for (final group in semesterGroups) {
            double totalSks = 0;
            double totalMutu = 0;

            widgets.add(
              pw.Container(
                margin: const pw.EdgeInsets.only(bottom: 6, top: 6),
                padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                color: PdfColor.fromInt(0xFFEEF2FF),
                child: pw.Text(
                  'Semester ${group.semester} - T.A. ${group.tahunAjaran}',
                  style: pw.TextStyle(fontSize: 10.5, fontWeight: pw.FontWeight.bold, color: _headerColor),
                ),
              ),
            );

            final rows = <pw.TableRow>[
              _headerRow(['No', 'Kode MK', 'Mata Kuliah', 'SKS', 'Nilai', 'Bobot', 'Mutu']),
            ];

            for (var i = 0; i < group.items.length; i++) {
              final item = group.items[i];
              final bobot = bobotHuruf(item.nilaiHuruf);
              final mutu = bobot * item.sks;
              totalSks += item.sks;
              totalMutu += mutu;

              rows.add(pw.TableRow(children: [
                _cell('${i + 1}', align: pw.TextAlign.center),
                _cell(item.kodeMk),
                _cell(item.namaMk),
                _cell('${item.sks}', align: pw.TextAlign.center),
                _cell(item.nilaiHuruf, align: pw.TextAlign.center),
                _cell(bobot.toStringAsFixed(1), align: pw.TextAlign.center),
                _cell(mutu.toStringAsFixed(1), align: pw.TextAlign.center),
              ]));
            }

            widgets.add(
              pw.Table(
                border: pw.TableBorder.all(color: _borderColor, width: 0.6),
                columnWidths: const {
                  0: pw.FlexColumnWidth(0.6),
                  1: pw.FlexColumnWidth(1.3),
                  2: pw.FlexColumnWidth(3.2),
                  3: pw.FlexColumnWidth(0.8),
                  4: pw.FlexColumnWidth(0.9),
                  5: pw.FlexColumnWidth(0.9),
                  6: pw.FlexColumnWidth(0.9),
                },
                children: rows,
              ),
            );

            final ips = totalSks == 0 ? 0 : totalMutu / totalSks;
            totalSksKumulatif += totalSks;
            totalMutuKumulatif += totalMutu;

            widgets.add(
              pw.Padding(
                padding: const pw.EdgeInsets.only(top: 6, bottom: 4),
                child: pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.end,
                  children: [
                    pw.Text('Total SKS: ${totalSks.toStringAsFixed(0)}   ',
                        style: const pw.TextStyle(fontSize: 9.5)),
                    pw.Text('IPS: ${ips.toStringAsFixed(2)}',
                        style: pw.TextStyle(fontSize: 10.5, fontWeight: pw.FontWeight.bold, color: _headerColor)),
                  ],
                ),
              ),
            );
          }

          if (semesterGroups.length > 1) {
            final ipk = totalSksKumulatif == 0 ? 0 : totalMutuKumulatif / totalSksKumulatif;
            widgets.add(pw.Divider(color: _borderColor));
            widgets.add(
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.end,
                children: [
                  pw.Text('Total SKS Kumulatif: ${totalSksKumulatif.toStringAsFixed(0)}   ',
                      style: const pw.TextStyle(fontSize: 10)),
                  pw.Text('IPK: ${ipk.toStringAsFixed(2)}',
                      style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold, color: _headerColor)),
                ],
              ),
            );
          }

          widgets.add(pw.SizedBox(height: 24));
          widgets.add(
            pw.Align(
              alignment: pw.Alignment.centerRight,
              child: pw.Text('Dicetak pada: $tanggalCetak', style: pw.TextStyle(fontSize: 9, color: _mutedColor)),
            ),
          );

          return widgets;
        },
      ),
    );

    return doc;
  }

  /// Membuat dokumen PDF KRS (daftar mata kuliah yang diambil mahasiswa
  /// beserta status persetujuannya).
  static Future<pw.Document> buildKrs({
    required String nama,
    required String nim,
    required String jurusan,
    required List<KrsItem> items,
  }) async {
    final doc = pw.Document();
    final tanggalCetak = _formatTanggalIndonesia(DateTime.now());

    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (context) {
          final rows = <pw.TableRow>[
            _headerRow(['No', 'Kode MK', 'Mata Kuliah', 'SKS', 'Kelas', 'Dosen', 'Status']),
          ];

          double totalSks = 0;
          for (var i = 0; i < items.length; i++) {
            final item = items[i];
            totalSks += item.sks;
            rows.add(pw.TableRow(children: [
              _cell('${i + 1}', align: pw.TextAlign.center),
              _cell(item.kodeMk),
              _cell(item.namaMk),
              _cell('${item.sks}', align: pw.TextAlign.center),
              _cell(item.kelas),
              _cell(item.namaDosen),
              _cell(item.status, align: pw.TextAlign.center),
            ]));
          }

          return [
            _kopSurat('KARTU RENCANA STUDI (KRS)'),
            _infoRow('Nama', nama),
            _infoRow('NIM', nim),
            _infoRow('Jurusan', jurusan),
            pw.SizedBox(height: 12),
            pw.Table(
              border: pw.TableBorder.all(color: _borderColor, width: 0.6),
              columnWidths: const {
                0: pw.FlexColumnWidth(0.5),
                1: pw.FlexColumnWidth(1.2),
                2: pw.FlexColumnWidth(2.6),
                3: pw.FlexColumnWidth(0.7),
                4: pw.FlexColumnWidth(1),
                5: pw.FlexColumnWidth(1.8),
                6: pw.FlexColumnWidth(1.2),
              },
              children: rows,
            ),
            pw.Padding(
              padding: const pw.EdgeInsets.only(top: 8),
              child: pw.Align(
                alignment: pw.Alignment.centerRight,
                child: pw.Text('Total SKS diambil: ${totalSks.toStringAsFixed(0)}',
                    style: pw.TextStyle(fontSize: 10.5, fontWeight: pw.FontWeight.bold, color: _headerColor)),
              ),
            ),
            pw.SizedBox(height: 24),
            pw.Align(
              alignment: pw.Alignment.centerRight,
              child: pw.Text('Dicetak pada: $tanggalCetak', style: pw.TextStyle(fontSize: 9, color: _mutedColor)),
            ),
          ];
        },
      ),
    );

    return doc;
  }
}

/// Satu baris mata kuliah dalam kelompok semester KHS.
class KhsItem {
  final String kodeMk;
  final String namaMk;
  final int sks;
  final String nilaiHuruf;

  KhsItem({required this.kodeMk, required this.namaMk, required this.sks, required this.nilaiHuruf});
}

/// Kelompok nilai per semester (dipakai untuk hitung IPS per semester,
/// dan gabungan semua kelompok untuk transkrip/IPK).
class KhsSemesterGroup {
  final int semester;
  final String tahunAjaran;
  final List<KhsItem> items;

  KhsSemesterGroup({required this.semester, required this.tahunAjaran, required this.items});
}

/// Satu baris mata kuliah dalam KRS.
class KrsItem {
  final String kodeMk;
  final String namaMk;
  final int sks;
  final String kelas;
  final String namaDosen;
  final String status;

  KrsItem({
    required this.kodeMk,
    required this.namaMk,
    required this.sks,
    required this.kelas,
    required this.namaDosen,
    required this.status,
  });
}
