<?php
header("Access-Control-Allow-Origin: *");
header("Access-Control-Allow-Headers: *");
header("Access-Control-Allow-Methods: POST, OPTIONS");
header("Content-Type: application/json; charset=UTF-8");

error_reporting(0);
include "koneksi.php";

if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    exit;
}

$input = json_decode(file_get_contents('php://input'), true);

function inputValue($key) {
    global $input;
    if (isset($input[$key])) {
        return trim($input[$key]);
    }
    if (isset($_POST[$key])) {
        return trim($_POST[$key]);
    }
    return '';
}

$user_id = inputValue('user_id');
$role = strtolower(inputValue('role'));
$username = inputValue('username');
$nim = inputValue('nim');

if ($user_id === '' && $username === '' && $nim === '') {
    echo json_encode([
        "success" => false,
        "message" => "User ID, Username, atau NIM/NIDN wajib diisi!"
    ]);
    exit;
}

if ($role === '') {
    echo json_encode([
        "success" => false,
        "message" => "Role wajib diisi!"
    ]);
    exit;
}

$user_id = mysqli_real_escape_string($koneksi, $user_id);
$role = mysqli_real_escape_string($koneksi, $role);
$username = mysqli_real_escape_string($koneksi, $username);
$nim = mysqli_real_escape_string($koneksi, $nim);

if ($role === 'mahasiswa') {
    if ($user_id !== '') {
        $where = "user_id = '$user_id'";
    } elseif ($nim !== '') {
        $where = "nim = '$nim'";
    } else {
        $where = "username = '$username'";
    }

    // FIX: sebelumnya tidak menyertakan kolom `id` (primary key tabel mahasiswa),
    // padahal fitur KRS/Nilai/Jadwal di aplikasi butuh `mahasiswa_id` ini,
    // bukan `user_id`.
    $sql = "SELECT id, user_id, nim, nama, jurusan, alamat FROM mahasiswa WHERE $where LIMIT 1";
} elseif ($role === 'dosen') {
    if ($user_id !== '') {
        $where = "user_id = '$user_id'";
    } elseif ($nim !== '') {
        $where = "nidn = '$nim'";
    } else {
        $where = "username = '$username'";
    }

    // FIX: sama seperti di atas, sertakan `id` (dosen_id) untuk fitur Jadwal
    // Mengajar / Input Nilai / Persetujuan KRS milik dosen.
    $sql = "SELECT id, user_id, nidn, nama, kontak FROM dosen WHERE $where LIMIT 1";
} else {
    echo json_encode([
        "success" => false,
        "message" => "Role tidak valid"
    ]);
    exit;
}

$result = mysqli_query($koneksi, $sql);
if (!$result) {
    echo json_encode([
        "success" => false,
        "message" => "Query gagal: " . mysqli_error($koneksi)
    ]);
    exit;
}

if (mysqli_num_rows($result) === 0) {
    echo json_encode([
        "success" => false,
        "message" => "Data detail profil belum diinput atau tidak ditemukan",
        "data" => null
    ]);
    exit;
}

$dataResult = mysqli_fetch_assoc($result);

echo json_encode([
    "success" => true,
    "message" => "Data profil berhasil ditemukan",
    "data" => $dataResult
]);