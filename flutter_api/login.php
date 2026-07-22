<?php
header("Access-Control-Allow-Origin: *");
header("Access-Control-Allow-Headers: *");
header("Access-Control-Allow-Methods: GET, POST, OPTIONS");
header("Content-Type: application/json");

// Mencegah error notice merusak format JSON
error_reporting(0);

include "koneksi.php";

// Trik agar PHP bisa membaca JSON mentah yang dikirim oleh Flutter Web/Chrome
$dataMentah = json_decode(file_get_contents('php://input'), true);

// Jika dikirim via JSON (Flutter baru) pakai $dataMentah, jika form biasa pakai $_POST
$username = isset($dataMentah['username']) ? $dataMentah['username'] : (isset($_POST['username']) ? $_POST['username'] : '');
$password = isset($dataMentah['password']) ? $dataMentah['password'] : (isset($_POST['password']) ? $_POST['password'] : '');
$role = isset($dataMentah['role']) ? $dataMentah['role'] : (isset($_POST['role']) ? $_POST['role'] : '');

// Amankan input dari SQL Injection
$username = mysqli_real_escape_string($koneksi, $username);
$password = mysqli_real_escape_string($koneksi, $password);
$role = mysqli_real_escape_string($koneksi, $role);

if (empty($username) || empty($password) || empty($role)) {
    echo json_encode([
        "success" => false,
        "message" => "Username, Password, dan Role wajib diisi!"
    ]);
    exit();
}

// Query disesuaikan: Harus cocok username, password, DAN role-nya
$query = mysqli_query(
    $koneksi,
    "SELECT * FROM users WHERE username='$username' AND password='$password' AND role='$role'"
);

$cek = mysqli_num_rows($query);

if ($cek > 0) {
    $data = mysqli_fetch_assoc($query);
    echo json_encode([
        "success" => true,
        "message" => "Login Berhasil",
        "username" => $data['username'],
        "role" => $data['role'],
        "user_id" => $data['id']
    ]);
} else {
    echo json_encode([
        "success" => false,
        "message" => "Username, Password, atau Role salah!"
    ]);
}
?>