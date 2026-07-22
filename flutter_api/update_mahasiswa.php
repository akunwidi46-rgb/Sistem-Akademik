<?php
header("Access-Control-Allow-Origin: *");
header("Content-Type: application/json");

include "koneksi.php";

$id      = $_POST['id'];
$nim     = $_POST['nim'];
$nama    = $_POST['nama'];
$jurusan = $_POST['jurusan'];
$alamat  = $_POST['alamat'];

$query = mysqli_query(
    $koneksi,
    "UPDATE mahasiswa
     SET
     nim='$nim',
     nama='$nama',
     jurusan='$jurusan',
     alamat='$alamat'
     WHERE id='$id'"
);

if($query){
    echo json_encode([
        "success"=>true
    ]);
}else{
    echo json_encode([
        "success"=>false
    ]);
}
?>