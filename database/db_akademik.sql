-- phpMyAdmin SQL Dump
-- version 5.2.1
-- https://www.phpmyadmin.net/
--
-- Host: 127.0.0.1
-- Generation Time: Jul 22, 2026 at 06:04 AM
-- Server version: 10.4.32-MariaDB
-- PHP Version: 8.0.30

SET SQL_MODE = "NO_AUTO_VALUE_ON_ZERO";
START TRANSACTION;
SET time_zone = "+00:00";


/*!40101 SET @OLD_CHARACTER_SET_CLIENT=@@CHARACTER_SET_CLIENT */;
/*!40101 SET @OLD_CHARACTER_SET_RESULTS=@@CHARACTER_SET_RESULTS */;
/*!40101 SET @OLD_COLLATION_CONNECTION=@@COLLATION_CONNECTION */;
/*!40101 SET NAMES utf8mb4 */;

--
-- Database: `db_akademik`
--

-- --------------------------------------------------------

--
-- Table structure for table `dosen`
--

CREATE TABLE `dosen` (
  `id` int(11) NOT NULL,
  `user_id` int(11) DEFAULT NULL,
  `nidn` varchar(20) DEFAULT NULL,
  `nama` varchar(100) DEFAULT NULL,
  `kontak` varchar(20) DEFAULT NULL,
  `gelar` varchar(30) DEFAULT NULL,
  `alamat` text DEFAULT NULL,
  `no_hp` varchar(20) DEFAULT NULL,
  `email` varchar(100) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Dumping data for table `dosen`
--

INSERT INTO `dosen` (`id`, `user_id`, `nidn`, `nama`, `kontak`, `gelar`, `alamat`, `no_hp`, `email`) VALUES
(1, 3, '01234567', 'Dr. Hermawan susilo', '08123456789', NULL, NULL, NULL, NULL),
(2, 23, '0011223344', 'Ahmad Fauzi, S.Kom., M.Kom', '081234567001', NULL, NULL, NULL, NULL),
(3, 24, '0022334455', 'Siti Rahmawati, S.T., M.T', '081234567002', NULL, NULL, NULL, NULL),
(4, 27, '0011223366', 'budi susanto M.kom', '082233446789', NULL, NULL, NULL, NULL);

-- --------------------------------------------------------

--
-- Table structure for table `jadwal`
--

CREATE TABLE `jadwal` (
  `id` int(11) NOT NULL,
  `mata_kuliah_id` int(11) NOT NULL,
  `dosen_id` int(11) NOT NULL,
  `hari` varchar(20) DEFAULT NULL,
  `jam_mulai` time DEFAULT NULL,
  `jam_selesai` time DEFAULT NULL,
  `ruangan` varchar(30) DEFAULT NULL,
  `kelas` varchar(20) DEFAULT NULL,
  `semester` int(11) DEFAULT NULL,
  `tahun_ajaran` varchar(20) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Dumping data for table `jadwal`
--

INSERT INTO `jadwal` (`id`, `mata_kuliah_id`, `dosen_id`, `hari`, `jam_mulai`, `jam_selesai`, `ruangan`, `kelas`, `semester`, `tahun_ajaran`) VALUES
(2, 2, 2, 'Senin', '08:00:00', '09:40:00', 'R101', 'RPL-1A', 1, '2025/2026'),
(3, 3, 3, 'Selasa', '10:00:00', '00:30:00', 'Lab1', 'RPL-1A', 1, '2025/2026'),
(4, 4, 2, 'Rabu', '13:00:00', '15:30:00', 'Lab2', 'SI-2B', 2, '2025/2026'),
(5, 6, 4, 'Jum\'at', '17:30:00', '19:15:00', '402', 'RPL-3A', 3, '2025/2026');

-- --------------------------------------------------------

--
-- Table structure for table `krs`
--

CREATE TABLE `krs` (
  `id` int(11) NOT NULL,
  `mahasiswa_id` int(11) NOT NULL,
  `jadwal_id` int(11) NOT NULL,
  `status` enum('Pending','Disetujui','Ditolak') DEFAULT 'Pending',
  `tanggal` timestamp NOT NULL DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Dumping data for table `krs`
--

INSERT INTO `krs` (`id`, `mahasiswa_id`, `jadwal_id`, `status`, `tanggal`) VALUES
(1, 9, 2, 'Disetujui', '2026-07-08 06:29:10'),
(2, 9, 3, 'Disetujui', '2026-07-08 06:29:20'),
(3, 12, 5, 'Disetujui', '2026-07-16 08:15:51');

-- --------------------------------------------------------

--
-- Table structure for table `mahasiswa`
--

CREATE TABLE `mahasiswa` (
  `id` int(11) NOT NULL,
  `nim` varchar(20) DEFAULT NULL,
  `nama` varchar(100) DEFAULT NULL,
  `jurusan` varchar(100) DEFAULT NULL,
  `alamat` text DEFAULT NULL,
  `user_id` int(11) DEFAULT NULL,
  `semester` int(11) DEFAULT NULL,
  `angkatan` year(4) DEFAULT NULL,
  `jenis_kelamin` varchar(20) DEFAULT NULL,
  `no_hp` varchar(20) DEFAULT NULL,
  `email` varchar(100) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Dumping data for table `mahasiswa`
--

INSERT INTO `mahasiswa` (`id`, `nim`, `nama`, `jurusan`, `alamat`, `user_id`, `semester`, `angkatan`, `jenis_kelamin`, `no_hp`, `email`) VALUES
(3, '2315000026', 'widi wulandari', 'RPL', 'belawan', 8, NULL, NULL, NULL, NULL, NULL),
(5, '2315000010', 'budi', 'sistem informasi', 'marelan', 11, NULL, NULL, NULL, NULL, NULL),
(8, '2134567', 'retno', 'hukum', 'martubung', 1, NULL, NULL, NULL, NULL, NULL),
(9, '2315000101', 'Rina Amelia', 'RPL', 'Jl. Merdeka No.10, Medan', 25, NULL, NULL, NULL, NULL, NULL),
(10, '2315000102', 'Dedi Kurniawan', 'Sistem Informasi', 'Jl. Sudirman No.5, Medan', 26, NULL, NULL, NULL, NULL, NULL),
(12, '2315000040', 'widi wulandari', 'RPL', 'Belawan', 29, NULL, NULL, NULL, NULL, NULL);

-- --------------------------------------------------------

--
-- Table structure for table `mata_kuliah`
--

CREATE TABLE `mata_kuliah` (
  `id` int(11) NOT NULL,
  `kode_mk` varchar(20) NOT NULL,
  `nama_mk` varchar(100) NOT NULL,
  `sks` int(11) NOT NULL,
  `semester` int(11) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Dumping data for table `mata_kuliah`
--

INSERT INTO `mata_kuliah` (`id`, `kode_mk`, `nama_mk`, `sks`, `semester`) VALUES
(2, 'MTK101', 'Matematika Dasar', 3, 1),
(3, 'ALG201', 'Algoritma dan Pemrograman', 4, 1),
(4, 'BDT301', 'Basis Data', 3, 2),
(5, 'JAR302', 'Jaringan Komputer', 2, 2),
(6, 'PBO303', 'Pemrograman Berorientasi Objek', 3, 3);

-- --------------------------------------------------------

--
-- Table structure for table `nilai`
--

CREATE TABLE `nilai` (
  `id` int(11) NOT NULL,
  `mahasiswa_id` int(11) NOT NULL,
  `jadwal_id` int(11) NOT NULL,
  `tugas` double DEFAULT 0,
  `uts` double DEFAULT 0,
  `uas` double DEFAULT 0,
  `nilai_akhir` double DEFAULT 0,
  `nilai_huruf` varchar(2) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Dumping data for table `nilai`
--

INSERT INTO `nilai` (`id`, `mahasiswa_id`, `jadwal_id`, `tugas`, `uts`, `uas`, `nilai_akhir`, `nilai_huruf`) VALUES
(2, 9, 2, 80, 85, 80, 81.75, 'B'),
(3, 12, 5, 80, 85, 90, 86.25, 'A');

-- --------------------------------------------------------

--
-- Table structure for table `users`
--

CREATE TABLE `users` (
  `id` int(11) NOT NULL,
  `nama` varchar(100) DEFAULT NULL,
  `username` varchar(50) DEFAULT NULL,
  `password` varchar(100) DEFAULT NULL,
  `role` varchar(20) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Dumping data for table `users`
--

INSERT INTO `users` (`id`, `nama`, `username`, `password`, `role`) VALUES
(1, NULL, 'admin', 'admin123', 'admin'),
(2, NULL, 'mahasiswa', 'mhs123', 'mahasiswa'),
(3, NULL, 'dosen', 'dosen123', 'dosen'),
(4, 'widi wulandari', 'widi wlndari', 'widi123', 'user'),
(5, 'tes', 'tes_codex', '123', 'user'),
(6, 'widi wulandari', 'widiwlndari', '123456', 'user'),
(8, 'widi wulandari', '@widi', 'widi123', 'mahasiswa'),
(9, 'quen', 'queen', '123456', 'mahasiswa'),
(10, 'widi wulandari', '@widi', 'widi123', 'mahasiswa'),
(11, 'budi', '@budi', 'budi123', 'mahasiswa'),
(12, 'susi', '@susi', 'sus123', 'mahasiswa'),
(13, 'wiidi wulandari', '2215000026', '2215000026', 'mahasiswa'),
(14, 'budi', '1234567', '1234567', 'dosen'),
(15, 'budi', '1234567', '1234567', 'dosen'),
(16, 'budi', '1234567', '1234567', 'dosen'),
(17, 'retno', '2134567', 'retno123', 'mahasiswa'),
(18, 'budi susanto', '123456', '123456', 'dosen'),
(19, 'budi susanto', '123456', '123456', 'dosen'),
(20, 'budi susanto', '123456', '123456', 'dosen'),
(21, 'budi susanto', '123456', '123456', 'dosen'),
(22, 'budi susanto', '123456', '123456', 'dosen'),
(23, 'Ahmad Fauzi, S.Kom., M.Kom', '0011223344', '0011223344', 'dosen'),
(24, 'Siti Rahmawati, S.T., M.T', '0022334455', '0022334455', 'dosen'),
(25, 'Rina Amelia', '2315000101', '2315000101', 'mahasiswa'),
(26, 'Dedi Kurniawan', '2315000102', '2315000102', 'mahasiswa'),
(27, 'budi susanto M.kom', '0011223366', '0011223366', 'dosen'),
(28, 'widi wulandari', '2315000026', '2315000026', 'mahasiswa'),
(29, 'widi wulandari', '2315000040', '2315000040', 'mahasiswa');

--
-- Indexes for dumped tables
--

--
-- Indexes for table `dosen`
--
ALTER TABLE `dosen`
  ADD PRIMARY KEY (`id`);

--
-- Indexes for table `jadwal`
--
ALTER TABLE `jadwal`
  ADD PRIMARY KEY (`id`),
  ADD KEY `mata_kuliah_id` (`mata_kuliah_id`),
  ADD KEY `dosen_id` (`dosen_id`);

--
-- Indexes for table `krs`
--
ALTER TABLE `krs`
  ADD PRIMARY KEY (`id`),
  ADD KEY `mahasiswa_id` (`mahasiswa_id`),
  ADD KEY `jadwal_id` (`jadwal_id`);

--
-- Indexes for table `mahasiswa`
--
ALTER TABLE `mahasiswa`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `unique_nim` (`nim`),
  ADD UNIQUE KEY `unique_user_id` (`user_id`);

--
-- Indexes for table `mata_kuliah`
--
ALTER TABLE `mata_kuliah`
  ADD PRIMARY KEY (`id`);

--
-- Indexes for table `nilai`
--
ALTER TABLE `nilai`
  ADD PRIMARY KEY (`id`),
  ADD KEY `mahasiswa_id` (`mahasiswa_id`),
  ADD KEY `jadwal_id` (`jadwal_id`);

--
-- Indexes for table `users`
--
ALTER TABLE `users`
  ADD PRIMARY KEY (`id`);

--
-- AUTO_INCREMENT for dumped tables
--

--
-- AUTO_INCREMENT for table `dosen`
--
ALTER TABLE `dosen`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=5;

--
-- AUTO_INCREMENT for table `jadwal`
--
ALTER TABLE `jadwal`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=6;

--
-- AUTO_INCREMENT for table `krs`
--
ALTER TABLE `krs`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=4;

--
-- AUTO_INCREMENT for table `mahasiswa`
--
ALTER TABLE `mahasiswa`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=13;

--
-- AUTO_INCREMENT for table `mata_kuliah`
--
ALTER TABLE `mata_kuliah`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=7;

--
-- AUTO_INCREMENT for table `nilai`
--
ALTER TABLE `nilai`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=4;

--
-- AUTO_INCREMENT for table `users`
--
ALTER TABLE `users`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=30;

--
-- Constraints for dumped tables
--

--
-- Constraints for table `jadwal`
--
ALTER TABLE `jadwal`
  ADD CONSTRAINT `jadwal_ibfk_1` FOREIGN KEY (`mata_kuliah_id`) REFERENCES `mata_kuliah` (`id`) ON DELETE CASCADE,
  ADD CONSTRAINT `jadwal_ibfk_2` FOREIGN KEY (`dosen_id`) REFERENCES `dosen` (`id`) ON DELETE CASCADE;

--
-- Constraints for table `krs`
--
ALTER TABLE `krs`
  ADD CONSTRAINT `krs_ibfk_1` FOREIGN KEY (`mahasiswa_id`) REFERENCES `mahasiswa` (`id`) ON DELETE CASCADE,
  ADD CONSTRAINT `krs_ibfk_2` FOREIGN KEY (`jadwal_id`) REFERENCES `jadwal` (`id`) ON DELETE CASCADE;

--
-- Constraints for table `nilai`
--
ALTER TABLE `nilai`
  ADD CONSTRAINT `nilai_ibfk_1` FOREIGN KEY (`mahasiswa_id`) REFERENCES `mahasiswa` (`id`) ON DELETE CASCADE,
  ADD CONSTRAINT `nilai_ibfk_2` FOREIGN KEY (`jadwal_id`) REFERENCES `jadwal` (`id`) ON DELETE CASCADE;
COMMIT;

/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
