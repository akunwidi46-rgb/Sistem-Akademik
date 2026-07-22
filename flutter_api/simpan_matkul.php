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

$kode_mk = input('kode_mk');
$nama_mk = input('nama_mk');
$sks = input('sks');
$semester = input('semester');

if ($kode_mk === '' || $nama_mk === '' || $sks === '' || $semester === '') {
    echo json_encode([
        'success' => false,
        'message' => 'Semua field wajib diisi'
    ]);
    exit;
}

$kode_mk = mysqli_real_escape_string($koneksi, $kode_mk);
$nama_mk = mysqli_real_escape_string($koneksi, $nama_mk);
$sks = mysqli_real_escape_string($koneksi, $sks);
$semester = mysqli_real_escape_string($koneksi, $semester);

$cek = mysqli_query($koneksi, "SELECT id FROM mata_kuliah WHERE kode_mk='$kode_mk' LIMIT 1");
if ($cek && mysqli_num_rows($cek) > 0) {
    echo json_encode([
        'success' => false,
        'message' => 'Kode MK sudah ada'
    ]);
    exit;
}

$query = mysqli_query(
    $koneksi,
    "INSERT INTO mata_kuliah (kode_mk, nama_mk, sks, semester) VALUES ('$kode_mk', '$nama_mk', '$sks', '$semester')"
);

if ($query) {
    echo json_encode([
        'success' => true,
        'message' => 'Data mata kuliah berhasil disimpan'
    ]);
} else {
    echo json_encode([
        'success' => false,
        'message' => 'Gagal menyimpan: ' . mysqli_error($koneksi)
    ]);
}
?>
