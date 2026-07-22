<?php
header("Access-Control-Allow-Origin: *");
header("Access-Control-Allow-Headers: *");
header("Access-Control-Allow-Methods: POST, OPTIONS");
header("Content-Type: application/json; charset=UTF-8");

include 'koneksi.php';

$dataMentah = json_decode(file_get_contents('php://input'), true);

$id = isset($dataMentah['id']) ? $dataMentah['id'] : (isset($_POST['id']) ? $_POST['id'] : '');
$nidn = isset($dataMentah['nidn']) ? $dataMentah['nidn'] : (isset($_POST['nidn']) ? $_POST['nidn'] : '');
$nama = isset($dataMentah['nama']) ? $dataMentah['nama'] : (isset($_POST['nama']) ? $_POST['nama'] : '');
$kontak = isset($dataMentah['kontak']) ? $dataMentah['kontak'] : (isset($_POST['kontak']) ? $_POST['kontak'] : '');

$id = mysqli_real_escape_string($koneksi, $id);
$nidn = mysqli_real_escape_string($koneksi, $nidn);
$nama = mysqli_real_escape_string($koneksi, $nama);
$kontak = mysqli_real_escape_string($koneksi, $kontak);

// Validasi minimal
if (empty($id) || empty($nidn) || empty($nama)) {
    echo json_encode([
        "success" => false,
        "message" => "ID, NIDN, dan Nama tidak boleh kosong"
    ]);
    exit;
}

if ($kontak === '') {
    $kontak = '';
}

// Cek duplikasi NIDN untuk dosen lain
$cekNidn = mysqli_query($koneksi, "SELECT id FROM dosen WHERE nidn='$nidn' AND id != '$id' LIMIT 1");

if ($cekNidn && mysqli_num_rows($cekNidn) > 0) {
    echo json_encode([
        "success" => false,
        "message" => "NIDN sudah terdaftar untuk dosen lain"
    ]);
    exit;
}

$sql = "UPDATE dosen SET nidn='$nidn', nama='$nama', kontak='$kontak' WHERE id='$id'";
$query = mysqli_query($koneksi, $sql);

if ($query) {
    echo json_encode([
        "success" => true,
        "message" => "Data dosen berhasil diubah"
    ]);
} else {
    echo json_encode([
        "success" => false,
        "message" => "Gagal mengubah data: " . mysqli_error($koneksi)
    ]);
}
?>
