<?php
header("Access-Control-Allow-Origin: *");
header("Content-Type: application/json");

include "koneksi.php";

$data = array();

$query = mysqli_query($koneksi,
"SELECT * FROM mahasiswa ORDER BY id DESC");

while($row = mysqli_fetch_assoc($query)){
    $data[] = $row;
}

echo json_encode([
    "success" => true,
    "data" => $data
]);
?>