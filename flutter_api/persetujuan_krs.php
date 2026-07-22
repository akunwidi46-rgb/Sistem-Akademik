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
$status = input('status');

if ($id === '' || $status === '') {
    echo json_encode([
        'success' => false,
        'message' => 'id dan status wajib diisi'
    ]);
    exit;
}

// Validasi status
// FIX: kolom `status` di tabel `krs` adalah ENUM('Pending','Disetujui','Ditolak'),
// sebelumnya di sini ditulis 'Menunggu' sehingga tidak pernah cocok.
$allowed = ['Pending', 'Disetujui', 'Ditolak'];
if (!in_array($status, $allowed, true)) {
    echo json_encode([
        'success' => false,
        'message' => 'Status tidak valid'
    ]);
    exit;
}

$id = mysqli_real_escape_string($koneksi, $id);
$status = mysqli_real_escape_string($koneksi, $status);

$query = mysqli_query($koneksi, "UPDATE krs SET status='$status' WHERE id='$id'");

if ($query) {
    echo json_encode([
        'success' => true,
        'message' => 'Persetujuan KRS berhasil'
    ]);
} else {
    echo json_encode([
        'success' => false,
        'message' => 'Gagal update status: ' . mysqli_error($koneksi)
    ]);
}
?>
