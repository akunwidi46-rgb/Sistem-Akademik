<?php
header("Access-Control-Allow-Origin: *");
header("Access-Control-Allow-Headers: Content-Type");
header("Access-Control-Allow-Methods: POST, OPTIONS");
header("Content-Type: application/json; charset=UTF-8");

if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    exit;
}

error_reporting(0);
include "koneksi.php";

$raw = json_decode(file_get_contents('php://input'), true);

function input($key) {
    global $raw;
    if (isset($raw[$key])) return trim($raw[$key]);
    if (isset($_POST[$key])) return trim($_POST[$key]);
    return '';
}

$mata_kuliah_id = input('mata_kuliah_id');
$dosen_id = input('dosen_id');
$hari = input('hari');
$jam_mulai = input('jam_mulai');
$jam_selesai = input('jam_selesai');
$ruangan = input('ruangan');
$kelas = input('kelas');
$semester = input('semester');
$tahun_ajaran = input('tahun_ajaran'); // FIX: sebelumnya tanpa '$' -> fatal syntax error PHP


// Validasi
$errors = [];
if ($mata_kuliah_id === '') $errors[] = 'mata_kuliah_id wajib diisi';
if ($dosen_id === '') $errors[] = 'dosen_id wajib diisi';
if ($hari === '') $errors[] = 'hari wajib diisi';
if ($jam_mulai === '') $errors[] = 'jam_mulai wajib diisi';
if ($jam_selesai === '') $errors[] = 'jam_selesai wajib diisi';
if ($ruangan === '') $errors[] = 'ruangan wajib diisi';
if ($kelas === '') $errors[] = 'kelas wajib diisi';
if ($semester === '') $errors[] = 'semester wajib diisi';
if ($tahun_ajaran === '') $errors[] = 'tahun_ajaran wajib diisi';

if (!empty($errors)) {
    echo json_encode([
        'success' => false,
        'message' => implode('; ', $errors),
    ]);
    exit;
}

$mata_kuliah_id = mysqli_real_escape_string($koneksi, $mata_kuliah_id);
$dosen_id = mysqli_real_escape_string($koneksi, $dosen_id);
$hari = mysqli_real_escape_string($koneksi, $hari);
$jam_mulai = mysqli_real_escape_string($koneksi, $jam_mulai);
$jam_selesai = mysqli_real_escape_string($koneksi, $jam_selesai);
$ruangan = mysqli_real_escape_string($koneksi, $ruangan);
$kelas = mysqli_real_escape_string($koneksi, $kelas);
$semester = mysqli_real_escape_string($koneksi, $semester);
$tahun_ajaran = mysqli_real_escape_string($koneksi, $tahun_ajaran);

// Insert
$query = mysqli_query(
    $koneksi,
    "INSERT INTO jadwal (mata_kuliah_id, dosen_id, hari, jam_mulai, jam_selesai, ruangan, kelas, semester, tahun_ajaran)
     VALUES ('$mata_kuliah_id', '$dosen_id', '$hari', '$jam_mulai', '$jam_selesai', '$ruangan', '$kelas', '$semester', '$tahun_ajaran')"
);

if ($query) {
    echo json_encode([
        'success' => true,
        'message' => 'Data jadwal berhasil disimpan'
    ]);
} else {
    echo json_encode([
        'success' => false,
        'message' => 'Gagal menyimpan: ' . mysqli_error($koneksi)
    ]);
}
?>
