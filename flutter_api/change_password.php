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

$conn = new mysqli($dbHost, $dbUser, $dbPass, $dbName);
if ($conn->connect_error) {
    sendResponse(false, 'Koneksi database gagal: ' . $conn->connect_error);
}

$role = strtolower(trim($_POST['role'] ?? ''));
$username = trim($_POST['username'] ?? '');
$userId = trim($_POST['user_id'] ?? '');
// FIX: aplikasi Flutter (admin_page.dart & home_page.dart) cuma mengirim
// satu field 'password' (tidak ada 'old_password'), jadi backend harus
// menerima itu sebagai password baru juga. 'new_password'/'old_password'
// tetap didukung untuk kompatibilitas ke depan.
$oldPassword = trim($_POST['old_password'] ?? '');
$newPassword = trim($_POST['new_password'] ?? ($_POST['password'] ?? ''));

if ($role === '') {
    sendResponse(false, 'Role wajib diisi');
}

if ($username === '' && $userId === '') {
    sendResponse(false, 'Username atau User ID wajib diisi');
}

if ($newPassword === '') {
    sendResponse(false, 'Password baru wajib diisi');
}

// FIX: tabel `users` primary key-nya bernama `id`, bukan `user_id`.
$sql = "SELECT id, password FROM users WHERE ";
$sql .= $userId !== '' ? "id = ?" : "username = ?";
$sql .= " AND role = ? LIMIT 1";
$stmt = $conn->prepare($sql);
if (!$stmt) {
    sendResponse(false, 'Query gagal disiapkan: ' . $conn->error);
}

// FIX: query di atas cuma punya 2 placeholder '?', tapi sebelumnya
// bind_param dikasih 3 nilai ('sss', ..., $role, $role) -> error mysqli.
if ($userId !== '') {
    $stmt->bind_param('ss', $userId, $role);
} else {
    $stmt->bind_param('ss', $username, $role);
}

$stmt->execute();
$result = $stmt->get_result();
if ($result->num_rows === 0) {
    sendResponse(false, 'Akun tidak ditemukan');
}

$row = $result->fetch_assoc();
// Verifikasi password lama hanya kalau memang dikirim oleh client.
if ($oldPassword !== '' && $row['password'] !== $oldPassword) {
    sendResponse(false, 'Password lama salah');
}

$updateSql = "UPDATE users SET password = ? WHERE id = ? LIMIT 1";
$updateStmt = $conn->prepare($updateSql);
if (!$updateStmt) {
    sendResponse(false, 'Query update gagal: ' . $conn->error);
}
$updateStmt->bind_param('ss', $newPassword, $row['id']);

if ($updateStmt->execute()) {
    sendResponse(true, 'Password berhasil diubah');
} else {
    sendResponse(false, 'Gagal mengubah password: ' . $updateStmt->error);
}