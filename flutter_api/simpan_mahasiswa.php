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
$identifier = input('nim');
$nama = input('nama');
$jurusan = input('jurusan');
$alamat = input('alamat');
$nidn = input('nidn');
$kontak = input('kontak');

if ($role === 'dosen') {
    $nidn = $identifier !== '' ? $identifier : $nidn;
    $nim = '';
} else {
    $nim = $identifier;
    $nidn = $nidn ?: '';
}

$errors = [];

if ($user_id === '') {
    $errors[] = 'User ID wajib diisi';
}
if ($role !== 'mahasiswa' && $role !== 'dosen') {
    $errors[] = 'Role tidak valid';
}
if ($role === 'dosen' && $nidn === '') {
    $errors[] = 'NIDN wajib diisi untuk dosen';
}
if ($role === 'mahasiswa' && $nim === '') {
    $errors[] = 'NIM wajib diisi untuk mahasiswa';
}
if ($nama === '') {
    $errors[] = 'Nama wajib diisi';
}
if ($role === 'mahasiswa') {
    if ($jurusan === '') {
        $errors[] = 'Jurusan wajib diisi untuk mahasiswa';
    }
    if ($alamat === '') {
        $errors[] = 'Alamat wajib diisi untuk mahasiswa';
    }
}
if ($role === 'dosen' && $kontak === '') {
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
$nim = mysqli_real_escape_string($koneksi, $nim);
$nama = mysqli_real_escape_string($koneksi, $nama);
$jurusan = mysqli_real_escape_string($koneksi, $jurusan);
$alamat = mysqli_real_escape_string($koneksi, $alamat);
$nidn = mysqli_real_escape_string($koneksi, $nidn);
$kontak = mysqli_real_escape_string($koneksi, $kontak);

if ($role === 'mahasiswa') {
    $cekProfil = mysqli_query($koneksi, "SELECT id FROM mahasiswa WHERE user_id='$user_id' LIMIT 1");
    if ($cekProfil && mysqli_num_rows($cekProfil) > 0) {
        $query = mysqli_query(
            $koneksi,
            "UPDATE mahasiswa
             SET nim='$nim', nama='$nama', jurusan='$jurusan', alamat='$alamat'
             WHERE user_id='$user_id'"
        );
    } else {
        $query = mysqli_query(
            $koneksi,
            "INSERT INTO mahasiswa (user_id, nim, nama, jurusan, alamat)
             VALUES ('$user_id', '$nim', '$nama', '$jurusan', '$alamat')"
        );
    }
} else {
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
}

if ($query) {
    echo json_encode([
        'success' => true,
        'message' => 'Data berhasil disimpan'
    ]);
} else {
    echo json_encode([
        'success' => false,
        'message' => 'Gagal menyimpan: ' . mysqli_error($koneksi)
    ]);
}