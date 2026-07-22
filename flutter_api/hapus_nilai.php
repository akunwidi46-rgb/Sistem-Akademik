<?php
header("Access-Control-Allow-Origin: *");
header("Access-Control-Allow-Headers: Content-Type");
header("Access-Control-Allow-Methods: POST, OPTIONS, DELETE");
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
if ($id === '') {
    echo json_encode([
        'success' => false,
        'message' => 'id kosong atau tidak terkirim'
    ]);
    exit;
}

$id = mysqli_real_escape_string($koneksi, $id);

$query = mysqli_query($koneksi, "DELETE FROM nilai WHERE id='$id'");

if ($query) {
    echo json_encode([
        'success' => true,
        'message' => 'Nilai berhasil dihapus'
    ]);
} else {
    echo json_encode([
        'success' => false,
        'message' => 'Gagal menghapus: ' . mysqli_error($koneksi)
    ]);
}
?>
