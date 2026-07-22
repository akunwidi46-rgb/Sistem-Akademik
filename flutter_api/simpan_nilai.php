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

$mahasiswa_id = input('mahasiswa_id');
$jadwal_id = input('jadwal_id');
$tugas = input('tugas');
$uts = input('uts');
$uas = input('uas');
$nilai_akhir = input('nilai_akhir');
$nilai_huruf = input('nilai_huruf');

if ($mahasiswa_id === '' || $jadwal_id === '' || $tugas === '' || $uts === '' || $uas === '' || $nilai_akhir === '' || $nilai_huruf === '') {
    echo json_encode([
        'success' => false,
        'message' => 'Semua field wajib diisi'
    ]);
    exit;
}

$mahasiswa_id = mysqli_real_escape_string($koneksi, $mahasiswa_id);
$jadwal_id = mysqli_real_escape_string($koneksi, $jadwal_id);
$tugas = mysqli_real_escape_string($koneksi, $tugas);
$uts = mysqli_real_escape_string($koneksi, $uts);
$uas = mysqli_real_escape_string($koneksi, $uas);
$nilai_akhir = mysqli_real_escape_string($koneksi, $nilai_akhir);
$nilai_huruf = mysqli_real_escape_string($koneksi, $nilai_huruf);

$cek = mysqli_query($koneksi, "SELECT id FROM nilai WHERE mahasiswa_id='$mahasiswa_id' AND jadwal_id='$jadwal_id' LIMIT 1");
if ($cek && mysqli_num_rows($cek) > 0) {
    echo json_encode([
        'success' => false,
        'message' => 'Nilai untuk mahasiswa dan jadwal ini sudah ada'
    ]);
    exit;
}

$query = mysqli_query(
    $koneksi,
    "INSERT INTO nilai (mahasiswa_id, jadwal_id, tugas, uts, uas, nilai_akhir, nilai_huruf)
     VALUES ('$mahasiswa_id', '$jadwal_id', '$tugas', '$uts', '$uas', '$nilai_akhir', '$nilai_huruf')"
);

if ($query) {
    echo json_encode([
        'success' => true,
        'message' => 'Nilai berhasil disimpan'
    ]);
} else {
    echo json_encode([
        'success' => false,
        'message' => 'Gagal menyimpan: ' . mysqli_error($koneksi)
    ]);
}
?>
