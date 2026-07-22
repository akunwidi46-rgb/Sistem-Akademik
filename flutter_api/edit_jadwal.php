<?php
header("Access-Control-Allow-Origin: *");
header("Access-Control-Allow-Headers: Content-Type");
header("Access-Control-Allow-Methods: POST, OPTIONS");
header("Content-Type: application/json; charset=UTF-8");

if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    exit;
}

error_reporting(0);
include "koneksi.php";

$raw = json_decode(file_get_contents('php://input'), true);

function input($key) {
    global $raw;
    if (isset($raw[$key])) return trim($raw[$key]);
    if (isset($_POST[$key])) return trim($_POST[$key]);
    return '';
}

$id = input('id');
$mata_kuliah_id = input('mata_kuliah_id');
$dosen_id = input('dosen_id');
$hari = input('hari');
$jam_mulai = input('jam_mulai');
$jam_selesai = input('jam_selesai');
$ruangan = input('ruangan');
$kelas = input('kelas');
$semester = input('semester');
$tahun_ajaran = input('tahun_ajaran');

if ($id === '' || $mata_kuliah_id === '' || $dosen_id === '' || $hari === '' || $jam_mulai === '' || $jam_selesai === '' || $ruangan === '' || $kelas === '' || $semester === '' || $tahun_ajaran === '') {
    echo json_encode([
        'success' => false,
        'message' => 'ID dan semua field wajib diisi'
    ]);
    exit;
}

$id = mysqli_real_escape_string($koneksi, $id);
$mata_kuliah_id = mysqli_real_escape_string($koneksi, $mata_kuliah_id);
$dosen_id = mysqli_real_escape_string($koneksi, $dosen_id);
$hari = mysqli_real_escape_string($koneksi, $hari);
$jam_mulai = mysqli_real_escape_string($koneksi, $jam_mulai);
$jam_selesai = mysqli_real_escape_string($koneksi, $jam_selesai);
$ruangan = mysqli_real_escape_string($koneksi, $ruangan);
$kelas = mysqli_real_escape_string($koneksi, $kelas);
$semester = mysqli_real_escape_string($koneksi, $semester);
$tahun_ajaran = mysqli_real_escape_string($koneksi, $tahun_ajaran);

$query = mysqli_query(
    $koneksi,
    "UPDATE jadwal SET 
        mata_kuliah_id='$mata_kuliah_id',
        dosen_id='$dosen_id',
        hari='$hari',
        jam_mulai='$jam_mulai',
        jam_selesai='$jam_selesai',
        ruangan='$ruangan',
        kelas='$kelas',
        semester='$semester',
        tahun_ajaran='$tahun_ajaran'
     WHERE id='$id'"
);

if ($query) {
    echo json_encode([
        'success' => true,
        'message' => 'Data jadwal berhasil diubah'
    ]);
} else {
    echo json_encode([
        'success' => false,
        'message' => 'Gagal mengubah: ' . mysqli_error($koneksi)
    ]);
}
?>
