<?php
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Headers: Content-Type');
header('Access-Control-Allow-Methods: POST, OPTIONS');
header('Content-Type: application/json; charset=UTF-8');

if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    exit;
}

function sendResponse(bool $success, string $message, array $extra = []): void {
    $response = array_merge([
        'success' => $success,
        'message' => $message,
    ], $extra);
    echo json_encode($response);
    exit;
}

$dbHost = 'localhost';
$dbUser = 'root';
$dbPass = '';
$dbName = 'db_mahasiswa'; // FIX: sebelumnya 'flutter_api' (database salah/tidak ada)
                          // sehingga registrasi mahasiswa & dosen selalu gagal
                          // dan datanya tidak pernah tersimpan di database yang benar.

$conn = new mysqli($dbHost, $dbUser, $dbPass, $dbName);
if ($conn->connect_error) {
    sendResponse(false, 'Koneksi database gagal: ' . $conn->connect_error);
}

$nama = trim($_POST['nama'] ?? '');
$username = trim($_POST['username'] ?? '');
$password = trim($_POST['password'] ?? '');
$role = strtolower(trim($_POST['role'] ?? ''));

if ($nama === '' || $username === '' || $password === '' || $role === '') {
    sendResponse(false, 'Semua field wajib diisi');
}

if (!in_array($role, ['mahasiswa', 'dosen', 'admin'], true)) {
    sendResponse(false, 'Role tidak valid');
}

// FIX: tabel `users` primary key-nya bernama `id`, bukan `user_id` (bug ini yang
// bikin "Tambah Akun" masih gagal walau koneksi DB sudah dibetulkan).
$checkSql = "SELECT id FROM users WHERE username = ? LIMIT 1";
$stmt = $conn->prepare($checkSql);
if (!$stmt) {
    sendResponse(false, 'Query gagal disiapkan: ' . $conn->error);
}
$stmt->bind_param('s', $username);
$stmt->execute();
$stmt->store_result();
if ($stmt->num_rows > 0) {
    sendResponse(false, 'Username sudah terdaftar');
}
$stmt->close();

$insertSql = "INSERT INTO users (nama, username, password, role) VALUES (?, ?, ?, ?)";
$stmt = $conn->prepare($insertSql);
if (!$stmt) {
    sendResponse(false, 'Query gagal disiapkan: ' . $conn->error);
}
$stmt->bind_param('ssss', $nama, $username, $password, $role);

if ($stmt->execute()) {
    $newUserId = $conn->insert_id;
    sendResponse(true, 'Registrasi berhasil', ['user_id' => $newUserId]);
} else {
    sendResponse(false, 'Gagal registrasi: ' . $stmt->error);
}