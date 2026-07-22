<?php
header("Access-Control-Allow-Origin: *");
header("Access-Control-Allow-Headers: *");
header("Access-Control-Allow-Methods: GET, POST, OPTIONS");
header("Content-Type: application/json");

error_reporting(0); // Mencegah text error PHP merusak struktur JSON

include 'koneksi.php';

$query = mysqli_query($koneksi, "SELECT * FROM mahasiswa ORDER BY id DESC");
$result = array();

if ($query) {
    while ($row = mysqli_fetch_assoc($query)) {
        $result[] = $row;
    }
}

echo json_encode($result);
?>
