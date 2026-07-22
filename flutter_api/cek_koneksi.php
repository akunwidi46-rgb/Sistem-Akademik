<?php
header("Access-Control-Allow-Origin: *");
header("Access-Control-Allow-Headers: *");
header("Access-Control-Allow-Methods: GET, POST, OPTIONS");
header("Content-Type: application/json");

include "koneksi.php";

if($koneksi){

    echo json_encode([
        "status" => true,
        "message" => "API Connected"
    ]);

}else{

    echo json_encode([
        "status" => false,
        "message" => "API Disconnected"
    ]);

}

?>