import 'package:flutter/material.dart';

/// AppTheme
/// Sistem desain terpusat supaya seluruh aplikasi (Admin, Dosen, Mahasiswa)
/// punya tampilan yang konsisten: satu warna utama, satu gaya AppBar,
/// satu gaya tombol, satu gaya kartu & input, di semua halaman.
///
/// Warna aksen per-fitur (mis. hijau untuk "disetujui", merah untuk "hapus")
/// tetap dipakai secara lokal di masing-masing halaman untuk indikator status,
/// tapi kerangka/chrome utama aplikasi (AppBar, tombol utama, FAB) semuanya
/// mengikuti tema ini.
class AppTheme {
  AppTheme._();

  // Warna utama aplikasi.
  static const Color primary = Color(0xFF4F46E5); // Indigo elegan
  static const Color primaryDark = Color(0xFF3730A3);
  static const Color surfaceBg = Color(0xFFF5F6FB);
  static const Color cardBorder = Color(0xFFE5E7EB);

  // Warna aksen untuk masing-masing modul (dipakai di ikon menu, badge, dsb).
  static const Color accentMahasiswa = Color(0xFF6D28D9); // ungu
  static const Color accentDosen = Color(0xFF0D9488); // teal
  static const Color accentMatkul = Color(0xFFB45309); // amber gelap
  static const Color accentJadwal = Color(0xFFDC2626); // merah
  static const Color accentKrs = Color(0xFF7C3AED); // ungu terang
  static const Color accentNilai = Color(0xFF0F766E); // teal gelap

  static const Color success = Color(0xFF16A34A);
  static const Color danger = Color(0xFFDC2626);
  static const Color warning = Color(0xFFD97706);

  static ThemeData get light {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: primary,
      brightness: Brightness.light,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: surfaceBg,
      fontFamily: 'Roboto',

      // AppBar konsisten di semua halaman: solid indigo, teks putih, flat.
      appBarTheme: const AppBarTheme(
        backgroundColor: primary,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
          color: Colors.white,
          fontSize: 19,
          fontWeight: FontWeight.w600,
        ),
        iconTheme: IconThemeData(color: Colors.white),
      ),

      cardTheme: CardThemeData(
        elevation: 0,
        color: Colors.white,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: cardBorder),
        ),
      ),

      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          textStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
        ),
      ),

      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: primary,
          side: const BorderSide(color: primary, width: 1.4),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          textStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
        ),
      ),

      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: primary,
          textStyle: const TextStyle(fontWeight: FontWeight.w600),
        ),
      ),

      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: primary,
        foregroundColor: Colors.white,
        elevation: 2,
      ),

      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: const Color(0xFFF9FAFB),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: cardBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: cardBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: primary, width: 1.6),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: danger, width: 1.2),
        ),
        labelStyle: const TextStyle(color: Color(0xFF6B7280)),
      ),

      dataTableTheme: DataTableThemeData(
        headingRowColor: WidgetStateProperty.all(const Color(0xFFF3F4F6)),
        headingTextStyle: const TextStyle(fontWeight: FontWeight.w700, color: Color(0xFF374151)),
        dataRowColor: WidgetStateProperty.all(Colors.white),
        dividerThickness: 0.6,
      ),

      dialogTheme: DialogThemeData(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        backgroundColor: Colors.white,
      ),

      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),

      textTheme: const TextTheme(
        titleLarge: TextStyle(fontWeight: FontWeight.w700, color: Color(0xFF111827)),
        titleMedium: TextStyle(fontWeight: FontWeight.w600, color: Color(0xFF111827)),
        bodyMedium: TextStyle(color: Color(0xFF374151)),
      ),
    );
  }
}

/// Kartu menu dashboard yang konsisten (dipakai di dashboard Admin, Dosen,
/// dan Mahasiswa) supaya ketiganya punya "look & feel" yang sama persis --
/// cuma warna aksen ikon yang membedakan tiap modul.
class DashboardMenuTile extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color accentColor;
  final VoidCallback onTap;
  final String? subtitle;

  const DashboardMenuTile({
    super.key,
    required this.title,
    required this.icon,
    required this.accentColor,
    required this.onTap,
    this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 22, horizontal: 14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: AppTheme.cardBorder),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: accentColor.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(icon, color: accentColor, size: 26),
              ),
              const SizedBox(height: 12),
              Text(
                title,
                textAlign: TextAlign.center,
                style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13.5, color: Color(0xFF1F2937)),
              ),
              if (subtitle != null) ...[
                const SizedBox(height: 2),
                Text(
                  subtitle!,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 11, color: Color(0xFF9CA3AF)),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// Header dashboard yang konsisten: greeting card di atas grid menu.
class DashboardHeader extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;

  const DashboardHeader({super.key, required this.title, required this.subtitle, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppTheme.primary, AppTheme.primaryDark],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.15),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(icon, color: Colors.white, size: 28),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w700)),
                const SizedBox(height: 4),
                Text(subtitle, style: TextStyle(color: Colors.white.withOpacity(0.85), fontSize: 13)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Badge status kecil (Pending/Disetujui/Ditolak, huruf nilai, dsb) yang
/// konsisten bentuknya di seluruh aplikasi.
class StatusBadge extends StatelessWidget {
  final String label;
  final Color color;

  const StatusBadge({super.key, required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: TextStyle(color: color, fontWeight: FontWeight.w700, fontSize: 12),
      ),
    );
  }
}
