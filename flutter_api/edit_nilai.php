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

$id = input('id');
$mahasiswa_id = input('mahasiswa_id');
$jadwal_id = input('jadwal_id');
$tugas = input('tugas');
$uts = input('uts');
$uas = input('uas');
$nilai_akhir = input('nilai_akhir');
$nilai_huruf = input('nilai_huruf');

if ($id === '' || $mahasiswa_id === '' || $jadwal_id === '' || $tugas === '' || $uts === '' || $uas === '' || $nilai_akhir === '' || $nilai_huruf === '') {
    echo json_encode([
        'success' => false,
        'message' => 'id dan semua field wajib diisi'
    ]);
    exit;
}

$id = mysqli_real_escape_string($koneksi, $id);
$mahasiswa_id = mysqli_real_escape_string($koneksi, $mahasiswa_id);
$jadwal_id = mysqli_real_escape_string($koneksi, $jadwal_id);
$tugas = mysqli_real_escape_string($koneksi, $tugas);
$uts = mysqli_real_escape_string($koneksi, $uts);
$uas = mysqli_real_escape_string($koneksi, $uas);
$nilai_akhir = mysqli_real_escape_string($koneksi, $nilai_akhir);
$nilai_huruf = mysqli_real_escape_string($koneksi, $nilai_huruf);

$query = mysqli_query(
    $koneksi,
    "UPDATE nilai SET 
        mahasiswa_id='$mahasiswa_id',
        jadwal_id='$jadwal_id',
        tugas='$tugas',
        uts='$uts',
        uas='$uas',
        nilai_akhir='$nilai_akhir',
        nilai_huruf='$nilai_huruf'
     WHERE id='$id'"
);

if ($query) {
    echo json_encode([
        'success' => true,
        'message' => 'Nilai berhasil diubah'
    ]);
} else {
    echo json_encode([
        'success' => false,
        'message' => 'Gagal mengubah: ' . mysqli_error($koneksi)
    ]);
}
?>
