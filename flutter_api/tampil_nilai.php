<?php
header("Access-Control-Allow-Origin: *");
header("Access-Control-Allow-Headers: *");
header("Access-Control-Allow-Methods: GET, POST, OPTIONS");
header("Content-Type: application/json; charset=UTF-8");

error_reporting(0);
include "koneksi.php";

if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    exit;
}

$raw = json_decode(file_get_contents('php://input'), true);
$mahasiswaId = '';
if (is_array($raw) && isset($raw['mahasiswa_id'])) {
    $mahasiswaId = trim($raw['mahasiswa_id']);
} else {
    $mahasiswaId = isset($_POST['mahasiswa_id']) ? trim($_POST['mahasiswa_id']) : '';
}

$filter = '';
if ($mahasiswaId !== '') {
    $mahasiswaId = mysqli_real_escape_string($koneksi, $mahasiswaId);
    $filter = " WHERE mahasiswa_id='$mahasiswaId' ";
}

$query = mysqli_query($koneksi, "SELECT * FROM nilai {$filter} ORDER BY id DESC");
$result = [];

if ($query) {
    while ($row = mysqli_fetch_assoc($query)) {
        $result[] = $row;
    }
}

echo json_encode($result);
?>
