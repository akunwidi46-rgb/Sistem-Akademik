<?php
// 1. HEADER CORS WAJIB UNTUK FLUTTER WEB / CHROME
header("Access-Control-Allow-Origin: *");
header("Access-Control-Allow-Headers: Origin, X-Requested-With, Content-Type, Accept, Authorization");
header("Access-Control-Allow-Methods: GET, POST, OPTIONS, DELETE");
header("Content-Type: application/json; charset=UTF-8");

// Jika Chrome mengirimkan preflight request (OPTIONS), langsung jawab OK tanpa mengeksekusi query
if ($_SERVER['REQUEST_METHOD'] == 'OPTIONS') {
    http_response_code(200);
    exit();
}

// Matikan laporan error teks agar tidak merusak format JSON Flutter
error_reporting(0);
ini_set('display_errors', 0);

include "koneksi.php";

// 2. AMBIL ID MAHASISWA DARI BERBAGAI JALUR REQUEST CHROME
$id = isset($_POST['id']) ? $_POST['id'] : '';

if (empty($id)) {
    // Jika $_POST kosong, coba ambil dari JSON Raw Payload (bawaan Flutter Web)
    $dataMentah = json_decode(file_get_contents('php://input'), true);
    if (isset($dataMentah['id'])) {
        $id = $dataMentah['id'];
    }
}

// 3. JIKA ID TETAP KOSONG
if (empty($id)) {
    echo json_encode([
        "success" => false,
        "message" => "ID kosong atau tidak terkirim dari Flutter"
    ]);
    exit();
}

// 4. EKSEKUSI QUERY HAPUS DATA
$query = mysqli_query($koneksi, "DELETE FROM mahasiswa WHERE id='$id'");

if ($query) {
    echo json_encode([
        "success" => true,
        "message" => "Data berhasil dihapus"
    ]);
} else {
    echo json_encode([
        "success" => false,
        "message" => "Gagal menghapus di database: " . mysqli_error($koneksi)
    ]);
}
?>