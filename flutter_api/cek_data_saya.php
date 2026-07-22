<?php
header("Access-Control-Allow-Origin: *");
header("Content-Type: application/json");

include "koneksi.php";

$user_id = $_GET['user_id'];

$query = mysqli_query(
    $koneksi,
    "SELECT * FROM mahasiswa WHERE user_id='$user_id' LIMIT 1"
);

if(mysqli_num_rows($query) > 0){

    $data = mysqli_fetch_assoc($query);

    echo json_encode([
        "success" => true,
        "data" => $data
    ]);

}else{

    echo json_encode([
        "success" => false
    ]);

}
?>