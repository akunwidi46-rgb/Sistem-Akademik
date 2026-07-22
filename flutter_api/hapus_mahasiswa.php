<?php
header("Access-Control-Allow-Origin: *");
header("Access-Control-Allow-Headers: Origin, X-Requested-With, Content-Type, Accept, Authorization");
header("Access-Control-Allow-Methods: GET, POST, OPTIONS, DELETE");
header("Content-Type: application/json; charset=UTF-8");

if ($_SERVER['REQUEST_METHOD'] == 'OPTIONS') {
    http_response_code(200);
    exit();
}

error_reporting(0);
ini_set('display_errors', 0);

include "koneksi.php";

$id = isset($_POST['id']) ? $_POST['id'] : '';

if (empty($id)) {
    $dataMentah = json_decode(file_get_contents('php://input'), true);
    if (isset($dataMentah['id'])) {
        $id = $dataMentah['id'];
    }
}

$id = mysqli_real_escape_string($koneksi, $id);

if (empty($id)) {
    echo json_encode([
        "success" => false,
        "message" => "ID kosong atau tidak terkirim dari Flutter"
    ]);
    exit();
}

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
