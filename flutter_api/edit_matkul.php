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
$kode_mk = input('kode_mk');
$nama_mk = input('nama_mk');
$sks = input('sks');
$semester = input('semester');

if ($id === '' || $kode_mk === '' || $nama_mk === '' || $sks === '' || $semester === '') {
    echo json_encode([
        'success' => false,
        'message' => 'ID dan semua field wajib diisi'
    ]);
    exit;
}

$id = mysqli_real_escape_string($koneksi, $id);
$kode_mk = mysqli_real_escape_string($koneksi, $kode_mk);
$nama_mk = mysqli_real_escape_string($koneksi, $nama_mk);
$sks = mysqli_real_escape_string($koneksi, $sks);
$semester = mysqli_real_escape_string($koneksi, $semester);

$cek = mysqli_query($koneksi, "SELECT id FROM mata_kuliah WHERE kode_mk='$kode_mk' AND id != '$id' LIMIT 1");
if ($cek && mysqli_num_rows($cek) > 0) {
    echo json_encode([
        'success' => false,
        'message' => 'Kode MK sudah dipakai'
    ]);
    exit;
}

$query = mysqli_query(
    $koneksi,
    "UPDATE mata_kuliah SET kode_mk='$kode_mk', nama_mk='$nama_mk', sks='$sks', semester='$semester' WHERE id='$id'"
);

if ($query) {
    echo json_encode([
        'success' => true,
        'message' => 'Data mata kuliah berhasil diubah'
    ]);
} else {
    echo json_encode([
        'success' => false,
        'message' => 'Gagal mengubah: ' . mysqli_error($koneksi)
    ]);
}
?>
