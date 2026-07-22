<?php
header("Access-Control-Allow-Origin: *");
header("Access-Control-Allow-Headers: *");
header("Access-Control-Allow-Methods: POST, OPTIONS");
header("Content-Type: application/json");

include 'koneksi.php';

$dataMentah = json_decode(file_get_contents('php://input'), true);

$id = isset($dataMentah['id']) ? $dataMentah['id'] : (isset($_POST['id']) ? $_POST['id'] : '');
$nim = isset($dataMentah['nim']) ? $dataMentah['nim'] : (isset($_POST['nim']) ? $_POST['nim'] : '');
$nama = isset($dataMentah['nama']) ? $dataMentah['nama'] : (isset($_POST['nama']) ? $_POST['nama'] : '');
$jurusan = isset($dataMentah['jurusan']) ? $dataMentah['jurusan'] : (isset($_POST['jurusan']) ? $_POST['jurusan'] : '');
$alamat = isset($dataMentah['alamat']) ? $dataMentah['alamat'] : (isset($_POST['alamat']) ? $_POST['alamat'] : '');


$id = mysqli_real_escape_string($koneksi, $id);
$nim = mysqli_real_escape_string($koneksi, $nim);
$nama = mysqli_real_escape_string($koneksi, $nama);
$jurusan = mysqli_real_escape_string($koneksi, $jurusan);
$alamat = mysqli_real_escape_string($koneksi, $alamat);

// Validasi
// - Miminim: id, nim, nama
// - jurusan harus diterima (agar update kolom jurusan tidak diam-diam kosong)
if (empty($id) || empty($nim) || empty($nama) || !isset($jurusan) || $jurusan === null) {
    echo json_encode([
        "success" => false,
        "message" => "ID, NIM, Nama, dan jurusan harus dikirim"
    ]);
    exit;
}

// Normalisasi agar UPDATE konsisten
$jurusan = $jurusan ?? '';
$alamat = $alamat ?? '';
// Jika backend/Flutter mengirim alamat kosong, biarkan update alamat menjadi string kosong sesuai kontrak yang ada.


$cekNim = mysqli_query($koneksi, "SELECT id FROM mahasiswa WHERE nim='$nim' AND id != '$id' LIMIT 1");

if ($cekNim && mysqli_num_rows($cekNim) > 0) {
    echo json_encode([
        "success" => false,
        "message" => "NIM sudah terdaftar untuk mahasiswa lain"
    ]);
    exit;
}

// Query SQL untuk mengubah data mahasiswa berdasarkan ID
// UPDATE jurusan dengan field yang diharapkan DB
$sql = "UPDATE mahasiswa SET nim='$nim', nama='$nama', jurusan='$jurusan', alamat='$alamat' WHERE id='$id'";

$query = mysqli_query($koneksi, $sql);

if ($query) {
    // Jika nilai tidak berubah, affected_rows bisa 0.
    $affected = mysqli_affected_rows($koneksi);
    if ($affected >= 0) {
        echo json_encode([
            "success" => true,
            "message" => $affected === 0 ? "Data tersimpan (tidak ada perubahan)" : "Data berhasil diubah"
        ]);
    } else {
        echo json_encode([
            "success" => false,
            "message" => "Query berhasil tapi affected_rows tidak valid"
        ]);
    }
} else {
    echo json_encode([
        "success" => false,
        "message" => "Gagal mengubah data: " . mysqli_error($koneksi)
    ]);
}
?>
