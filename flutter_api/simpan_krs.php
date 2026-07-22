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
$status = input('status');
$tanggal = input('tanggal');

if ($mahasiswa_id === '' || $jadwal_id === '' || $status === '' || $tanggal === '') {
    echo json_encode([
        'success' => false,
        'message' => 'mahasiswa_id, jadwal_id, status, dan tanggal wajib diisi'
    ]);
    exit;
}

$mahasiswa_id = mysqli_real_escape_string($koneksi, $mahasiswa_id);
$jadwal_id = mysqli_real_escape_string($koneksi, $jadwal_id);
$status = mysqli_real_escape_string($koneksi, $status);
$tanggal = mysqli_real_escape_string($koneksi, $tanggal);

// Cegah duplikasi KRS untuk mahasiswa & jadwal yang sama
$cek = mysqli_query($koneksi, "SELECT id FROM krs WHERE mahasiswa_id='$mahasiswa_id' AND jadwal_id='$jadwal_id' LIMIT 1");
if ($cek && mysqli_num_rows($cek) > 0) {
    echo json_encode([
        'success' => false,
        'message' => 'KRS untuk jadwal ini sudah ada'
    ]);
    exit;
}

$query = mysqli_query(
    $koneksi,
    "INSERT INTO krs (mahasiswa_id, jadwal_id, status, tanggal) VALUES ('$mahasiswa_id', '$jadwal_id', '$status', '$tanggal')"
);

if ($query) {
    echo json_encode([
        'success' => true,
        'message' => 'KRS berhasil dibuat'
    ]);
} else {
    echo json_encode([
        'success' => false,
        'message' => 'Gagal menyimpan: ' . mysqli_error($koneksi)
    ]);
}
?>
