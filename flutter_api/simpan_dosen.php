<?php
header("Access-Control-Allow-Origin: *");
header("Access-Control-Allow-Headers: Content-Type");
header("Access-Control-Allow-Methods: POST, OPTIONS");
header("Content-Type: application/json; charset=UTF-8");

error_reporting(0);
include "koneksi.php";

if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    exit;
}

$raw = json_decode(file_get_contents('php://input'), true);

function input($key) {
    global $raw;
    if (isset($raw[$key])) {
        return trim($raw[$key]);
    }
    if (isset($_POST[$key])) {
        return trim($_POST[$key]);
    }
    return '';
}

$user_id = input('user_id');
$role = strtolower(input('role'));
$username = input('username');
$nidn = input('nidn');
$nama = input('nama');
$kontak = input('kontak');

// Pola konsisten dengan simpan_mahasiswa.php:
// Jika client mengirim username sebagai NIDN, gunakan itu sebagai nidn.
if ($role === 'dosen') {
    if ($nidn === '' && $username !== '') {
        $nidn = $username;
    }
} 

$errors = [];

if ($user_id === '') {
    $errors[] = 'User ID wajib diisi';
}
if ($role !== 'dosen') {
    $errors[] = 'Role tidak valid';
}
if ($nidn === '') {
    $errors[] = 'NIDN wajib diisi untuk dosen';
}
if ($nama === '') {
    $errors[] = 'Nama wajib diisi';
}
if ($kontak === '') {
    $errors[] = 'Kontak wajib diisi untuk dosen';
}

if (!empty($errors)) {
    echo json_encode([
        'success' => false,
        'message' => implode('; ', $errors),
    ]);
    exit;
}

$user_id = mysqli_real_escape_string($koneksi, $user_id);
$role = mysqli_real_escape_string($koneksi, $role);
$username = mysqli_real_escape_string($koneksi, $username);
$nidn = mysqli_real_escape_string($koneksi, $nidn);
$nama = mysqli_real_escape_string($koneksi, $nama);
$kontak = mysqli_real_escape_string($koneksi, $kontak);

// Upsert dosen berdasarkan user_id
$cekProfil = mysqli_query($koneksi, "SELECT id FROM dosen WHERE user_id='$user_id' LIMIT 1");

if ($cekProfil && mysqli_num_rows($cekProfil) > 0) {
    $query = mysqli_query(
        $koneksi,
        "UPDATE dosen
         SET nidn='$nidn', nama='$nama', kontak='$kontak'
         WHERE user_id='$user_id'"
    );
} else {
    $query = mysqli_query(
        $koneksi,
        "INSERT INTO dosen (user_id, nidn, nama, kontak)
         VALUES ('$user_id', '$nidn', '$nama', '$kontak')"
    );
}

if ($query) {
    echo json_encode([
        'success' => true,
        'message' => 'Data dosen berhasil disimpan',
    ]);
} else {
    echo json_encode([
        'success' => false,
        'message' => 'Gagal menyimpan: ' . mysqli_error($koneksi)
    ]);
}
?>
