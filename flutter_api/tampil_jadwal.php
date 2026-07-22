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

$query = mysqli_query($koneksi, "SELECT * FROM jadwal ORDER BY id DESC");
$result = [];

if ($query) {
    while ($row = mysqli_fetch_assoc($query)) {
        $result[] = $row;
    }
}

echo json_encode($result);
?>
