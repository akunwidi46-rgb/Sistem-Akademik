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
$status = input('status');
$tanggal = input('tanggal');

if ($id === '' || $mahasiswa_id === '' || $jadwal_id === '' || $status === '' || $tanggal === '') {
    echo json_encode([
        'success' => false,
        'message' => 'id, mahasiswa_id, jadwal_id, status, dan tanggal wajib diisi'
    ]);
    exit;
}

$id = mysqli_real_escape_string($koneksi, $id);
$mahasiswa_id = mysqli_real_escape_string($koneksi, $mahasiswa_id);
$jadwal_id = mysqli_real_escape_string($koneksi, $jadwal_id);
$status = mysqli_real_escape_string($koneksi, $status);
$tanggal = mysqli_real_escape_string($koneksi, $tanggal);

$query = mysqli_query(
    $koneksi,
    "UPDATE krs SET mahasiswa_id='$mahasiswa_id', jadwal_id='$jadwal_id', status='$status', tanggal='$tanggal' WHERE id='$id'"
);

if ($query) {
    echo json_encode([
        'success' => true,
        'message' => 'KRS berhasil diubah'
    ]);
} else {
    echo json_encode([
        'success' => false,
        'message' => 'Gagal mengubah: ' . mysqli_error($koneksi)
    ]);
}
?>
