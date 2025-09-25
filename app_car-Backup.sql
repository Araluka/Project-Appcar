-- phpMyAdmin SQL Dump
-- version 5.2.1
-- https://www.phpmyadmin.net/
--
-- Host: 127.0.0.1
-- Generation Time: Sep 25, 2025 at 04:40 AM
-- Server version: 10.4.32-MariaDB
-- PHP Version: 8.2.12

SET SQL_MODE = "NO_AUTO_VALUE_ON_ZERO";
START TRANSACTION;
SET time_zone = "+00:00";


/*!40101 SET @OLD_CHARACTER_SET_CLIENT=@@CHARACTER_SET_CLIENT */;
/*!40101 SET @OLD_CHARACTER_SET_RESULTS=@@CHARACTER_SET_RESULTS */;
/*!40101 SET @OLD_COLLATION_CONNECTION=@@COLLATION_CONNECTION */;
/*!40101 SET NAMES utf8mb4 */;

--
-- Database: `app_car`
--

-- --------------------------------------------------------

--
-- Table structure for table `bookings`
--

CREATE TABLE `bookings` (
  `id` int(11) NOT NULL,
  `user_id` int(11) NOT NULL,
  `car_id` int(11) NOT NULL,
  `vendor_id` int(11) DEFAULT NULL,
  `driver_required` tinyint(1) DEFAULT 0,
  `booking_date` date DEFAULT NULL,
  `start_time` datetime DEFAULT NULL,
  `end_time` datetime DEFAULT NULL,
  `price` decimal(10,2) DEFAULT 0.00,
  `status` enum('pending','confirmed','cancelled','no_driver_found') DEFAULT 'pending',
  `created_at` timestamp NOT NULL DEFAULT current_timestamp(),
  `updated_at` timestamp NULL DEFAULT NULL ON UPDATE current_timestamp(),
  `driver_id` int(11) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Dumping data for table `bookings`
--

INSERT INTO `bookings` (`id`, `user_id`, `car_id`, `vendor_id`, `driver_required`, `booking_date`, `start_time`, `end_time`, `price`, `status`, `created_at`, `updated_at`, `driver_id`) VALUES
(1, 1, 1, 1, 1, '2025-09-28', '2025-09-28 09:00:00', '2025-09-28 18:00:00', 1200.00, 'no_driver_found', '2025-09-24 10:26:02', '2025-09-24 10:50:20', NULL),
(2, 1, 2, 1, 0, '2025-09-29', '2025-09-29 10:00:00', '2025-09-29 18:00:00', 1000.00, 'confirmed', '2025-09-24 10:26:02', NULL, NULL),
(5, 1, 1, 1, 1, '2025-09-26', '2025-09-26 09:00:00', '2025-09-26 18:00:00', 0.00, 'pending', '2025-09-24 10:34:33', NULL, NULL),
(6, 1, 16, 1, 1, '2025-09-26', '2025-09-26 09:00:00', '2025-09-26 18:00:00', 0.00, 'no_driver_found', '2025-09-24 11:34:01', '2025-09-24 11:34:01', NULL),
(7, 1, 16, 1, 1, '2025-09-26', '2025-09-26 09:00:00', '2025-09-26 18:00:00', 0.00, 'no_driver_found', '2025-09-24 11:45:23', '2025-09-24 11:45:23', NULL),
(8, 1, 16, 1, 1, '2025-09-26', '2025-09-26 09:00:00', '2025-09-26 18:00:00', 0.00, 'no_driver_found', '2025-09-24 11:58:33', '2025-09-24 11:58:33', NULL),
(9, 1, 1, 1, 1, '2025-09-25', '2025-09-26 09:00:00', '2025-09-26 18:00:00', 0.00, 'no_driver_found', '2025-09-24 11:59:13', '2025-09-24 11:59:13', NULL),
(10, 1, 1, 1, 1, '2025-09-28', '2025-09-28 09:00:00', '2025-09-28 18:00:00', 0.00, 'no_driver_found', '2025-09-24 11:59:37', '2025-09-24 11:59:37', NULL),
(11, 1, 1, 1, 1, '2025-09-28', '2025-09-28 09:00:00', '2025-09-28 18:00:00', 0.00, 'confirmed', '2025-09-24 12:04:55', '2025-09-24 12:19:08', 1),
(12, 1, 1, 1, 1, '2025-10-28', '2025-10-28 09:00:00', '2025-10-28 18:00:00', 0.00, 'no_driver_found', '2025-09-24 12:21:14', '2025-09-24 12:21:14', NULL),
(13, 1, 1, 1, 1, '2025-10-28', '2025-10-28 09:00:00', '2025-10-28 18:00:00', 0.00, 'no_driver_found', '2025-09-24 12:22:53', '2025-09-24 12:22:53', NULL);

-- --------------------------------------------------------

--
-- Table structure for table `cars`
--

CREATE TABLE `cars` (
  `id` int(11) NOT NULL,
  `vendor_id` int(11) NOT NULL,
  `name` varchar(100) NOT NULL,
  `license_plate` varchar(20) NOT NULL,
  `is_available` tinyint(1) NOT NULL DEFAULT 1,
  `location_lat` decimal(10,7) DEFAULT NULL,
  `location_lng` decimal(10,7) DEFAULT NULL,
  `image_url` text DEFAULT NULL,
  `seats` int(11) DEFAULT NULL,
  `transmission` enum('automatic','manual') DEFAULT NULL,
  `bag_small` int(11) DEFAULT 0,
  `bag_large` int(11) DEFAULT 0,
  `unlimited_mileage` tinyint(1) DEFAULT 1,
  `price_per_day` decimal(10,2) DEFAULT 0.00,
  `free_cancellation` tinyint(1) DEFAULT 1
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Dumping data for table `cars`
--

INSERT INTO `cars` (`id`, `vendor_id`, `name`, `license_plate`, `is_available`, `location_lat`, `location_lng`, `image_url`, `seats`, `transmission`, `bag_small`, `bag_large`, `unlimited_mileage`, `price_per_day`, `free_cancellation`) VALUES
(1, 1, 'Toyota Vios 1.5 (2020)', 'กข-1234', 1, 13.7563000, 100.5018000, NULL, 4, NULL, 0, 0, 1, 1500.00, 1),
(2, 1, 'Honda City', 'กข-5678', 1, 13.7500000, 100.5100000, NULL, 4, 'manual', 1, 2, 1, 1000.00, 1),
(16, 1, 'Toyota Vios', 'กข-1235', 1, 13.7563000, 100.5018000, NULL, 4, 'automatic', 2, 1, 1, 1200.00, 1);

-- --------------------------------------------------------

--
-- Table structure for table `drivers`
--

CREATE TABLE `drivers` (
  `id` int(11) NOT NULL,
  `user_id` int(11) NOT NULL,
  `service_radius_km` int(11) DEFAULT 10,
  `base_lat` decimal(10,7) DEFAULT NULL,
  `base_lng` decimal(10,7) DEFAULT NULL,
  `is_available` tinyint(1) DEFAULT 1
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Dumping data for table `drivers`
--

INSERT INTO `drivers` (`id`, `user_id`, `service_radius_km`, `base_lat`, `base_lng`, `is_available`) VALUES
(1, 3, 20, 13.7563000, 100.5018000, 0);

-- --------------------------------------------------------

--
-- Table structure for table `driver_assignments`
--

CREATE TABLE `driver_assignments` (
  `id` int(11) NOT NULL,
  `booking_id` int(11) NOT NULL,
  `driver_id` int(11) NOT NULL,
  `is_accepted` tinyint(1) DEFAULT 0,
  `responded_at` datetime DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Dumping data for table `driver_assignments`
--

INSERT INTO `driver_assignments` (`id`, `booking_id`, `driver_id`, `is_accepted`, `responded_at`) VALUES
(2, 1, 1, -1, '2025-09-24 17:50:20'),
(3, 11, 1, 1, '2025-09-24 19:19:08');

-- --------------------------------------------------------

--
-- Table structure for table `notifications`
--

CREATE TABLE `notifications` (
  `id` int(11) NOT NULL,
  `user_id` int(11) NOT NULL,
  `title` varchar(255) NOT NULL,
  `message` text NOT NULL,
  `is_read` tinyint(1) DEFAULT 0,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Dumping data for table `notifications`
--

INSERT INTO `notifications` (`id`, `user_id`, `title`, `message`, `is_read`, `created_at`) VALUES
(1, 1, 'การจองสำเร็จ', 'คุณได้จอง Toyota Vios วันที่ 2025-09-28', 0, '2025-09-24 10:27:01'),
(2, 2, 'มีการจองใหม่', 'ลูกค้าได้จองรถ Honda City ของคุณ', 0, '2025-09-24 10:27:01'),
(3, 3, 'ได้รับงานใหม่', 'คุณได้รับงานขับรถให้ลูกค้า Customer One', 0, '2025-09-24 10:27:01'),
(4, 4, 'ระบบ', 'คุณคือผู้ดูแลระบบ สามารถตรวจสอบข้อมูลทั้งหมดได้', 1, '2025-09-24 10:27:01'),
(5, 1, 'การจองสำเร็จ', 'คุณได้จองรถเรียบร้อย วันที่ 2025-09-26', 0, '2025-09-24 10:34:33'),
(6, 2, 'การจองใหม่', 'ลูกค้า 1 จองรถวันที่ 2025-09-26', 0, '2025-09-24 10:34:33'),
(7, 1, 'การจองถูกยกเลิก', 'คุณได้ยกเลิกการจอง 1 วันที่ Sun Sep 28 2025 00:00:00 GMT+0700 (Indochina Time)', 0, '2025-09-24 10:41:38'),
(8, 2, 'แจ้งเตือนระบบ', 'ยินดีต้อนรับสู่ CarApp', 0, '2025-09-24 10:51:19'),
(10, 1, 'การจองสำเร็จ', 'คุณได้จองรถเรียบร้อย วันที่ 2025-09-26', 0, '2025-09-24 11:34:01'),
(11, 2, 'การจองใหม่', 'ลูกค้า 1 จองรถวันที่ 2025-09-26', 0, '2025-09-24 11:34:01'),
(12, 1, 'ยังไม่พบคนขับ', 'ระบบยังไม่พบคนขับในรัศมีสำหรับวันที่ 2025-09-26', 0, '2025-09-24 11:34:01'),
(13, 1, 'การจองสำเร็จ', 'คุณได้จองรถเรียบร้อย วันที่ 2025-09-26', 0, '2025-09-24 11:45:23'),
(14, 2, 'การจองใหม่', 'ลูกค้า 1 จองรถวันที่ 2025-09-26', 0, '2025-09-24 11:45:23'),
(15, 1, 'ยังไม่พบคนขับ', 'ระบบยังไม่พบคนขับในรัศมีสำหรับวันที่ 2025-09-26', 0, '2025-09-24 11:45:23'),
(16, 1, 'การจองสำเร็จ', 'คุณได้จองรถเรียบร้อย วันที่ 2025-09-26', 0, '2025-09-24 11:58:33'),
(17, 2, 'การจองใหม่', 'ลูกค้า 1 จองรถวันที่ 2025-09-26', 0, '2025-09-24 11:58:33'),
(18, 1, 'ยังไม่พบคนขับ', 'ระบบยังไม่พบคนขับในรัศมีสำหรับวันที่ 2025-09-26', 0, '2025-09-24 11:58:33'),
(19, 1, 'การจองสำเร็จ', 'คุณได้จองรถเรียบร้อย วันที่ 2025-09-25', 0, '2025-09-24 11:59:13'),
(20, 2, 'การจองใหม่', 'ลูกค้า 1 จองรถวันที่ 2025-09-25', 0, '2025-09-24 11:59:13'),
(21, 1, 'ยังไม่พบคนขับ', 'ระบบยังไม่พบคนขับในรัศมีสำหรับวันที่ 2025-09-25', 0, '2025-09-24 11:59:13'),
(22, 1, 'การจองสำเร็จ', 'คุณได้จองรถเรียบร้อย วันที่ 2025-09-28', 0, '2025-09-24 11:59:37'),
(23, 2, 'การจองใหม่', 'ลูกค้า 1 จองรถวันที่ 2025-09-28', 0, '2025-09-24 11:59:37'),
(24, 1, 'ยังไม่พบคนขับ', 'ระบบยังไม่พบคนขับในรัศมีสำหรับวันที่ 2025-09-28', 0, '2025-09-24 11:59:37'),
(25, 2, 'การจองใหม่', 'ลูกค้า 1 จองรถวันที่ 2025-09-28', 0, '2025-09-24 12:04:55'),
(26, 3, 'ได้รับงานใหม่', 'คุณได้รับงานจากลูกค้า 1 วันที่ 2025-09-28', 0, '2025-09-24 12:04:55'),
(27, 1, 'ยืนยันคนขับแล้ว', 'การจอง #11 ได้รับการยืนยันคนขับแล้ว', 0, '2025-09-24 12:19:08'),
(28, 2, 'งานถูกยืนยันโดยคนขับ', 'การจอง #11 ถูกยืนยันคนขับแล้ว', 0, '2025-09-24 12:19:08'),
(29, 2, 'การจองใหม่', 'ลูกค้า 1 จองรถวันที่ 2025-10-28', 0, '2025-09-24 12:21:14'),
(30, 1, 'ยังไม่พบคนขับ', 'ระบบยังไม่พบคนขับในรัศมีสำหรับวันที่ 2025-10-28', 0, '2025-09-24 12:21:14'),
(31, 2, 'การจองใหม่', 'ลูกค้า 1 จองรถวันที่ 2025-10-28', 0, '2025-09-24 12:22:53'),
(32, 1, 'ยังไม่พบคนขับ', 'ระบบยังไม่พบคนขับในรัศมีสำหรับวันที่ 2025-10-28', 0, '2025-09-24 12:22:53');

-- --------------------------------------------------------

--
-- Table structure for table `payments`
--

CREATE TABLE `payments` (
  `id` int(11) NOT NULL,
  `booking_id` int(11) NOT NULL,
  `transaction_id` varchar(255) NOT NULL,
  `payment_method` enum('promptpay','qr','credit_card','bank_transfer') NOT NULL,
  `amount` decimal(10,2) NOT NULL,
  `payment_status` enum('pending','paid','failed','refunded') NOT NULL DEFAULT 'pending',
  `created_at` timestamp NOT NULL DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Dumping data for table `payments`
--

INSERT INTO `payments` (`id`, `booking_id`, `transaction_id`, `payment_method`, `amount`, `payment_status`, `created_at`) VALUES
(1, 1, 'TXN1001', 'promptpay', 1200.00, 'paid', '2025-09-24 10:27:01'),
(2, 2, 'TXN1002', 'credit_card', 1000.00, 'pending', '2025-09-24 10:27:01'),
(3, 1, 'TEST-TXN-123456', 'promptpay', 1200.00, 'paid', '2025-09-24 10:35:14'),
(4, 2, 'TEST-TXN-123456', 'promptpay', 1200.00, 'paid', '2025-09-24 10:35:43'),
(5, 2, 'TEST-TXN-123456', 'promptpay', 1200.00, 'paid', '2025-09-24 10:36:43'),
(6, 5, 'TEST-TXN-123456', 'promptpay', 1200.00, 'paid', '2025-09-24 11:30:38');

-- --------------------------------------------------------

--
-- Table structure for table `receipts`
--

CREATE TABLE `receipts` (
  `id` int(11) NOT NULL,
  `booking_id` int(11) NOT NULL,
  `transaction_id` varchar(255) NOT NULL,
  `total_amount` decimal(10,2) NOT NULL,
  `payment_status` enum('paid') NOT NULL DEFAULT 'paid',
  `created_at` timestamp NOT NULL DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Dumping data for table `receipts`
--

INSERT INTO `receipts` (`id`, `booking_id`, `transaction_id`, `total_amount`, `payment_status`, `created_at`) VALUES
(1, 1, 'TXN1001', 1200.00, 'paid', '2025-09-24 10:27:01'),
(2, 5, 'TEST-TXN-123456', 1200.00, 'paid', '2025-09-24 11:30:38');

-- --------------------------------------------------------

--
-- Table structure for table `users`
--

CREATE TABLE `users` (
  `id` int(11) NOT NULL,
  `name` varchar(100) NOT NULL,
  `email` varchar(100) NOT NULL,
  `password` varchar(255) NOT NULL,
  `phone` varchar(20) NOT NULL,
  `role` enum('admin','customer','vendor','driver') NOT NULL DEFAULT 'customer',
  `created_at` timestamp NOT NULL DEFAULT current_timestamp(),
  `updated_at` timestamp NULL DEFAULT NULL ON UPDATE current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Dumping data for table `users`
--

INSERT INTO `users` (`id`, `name`, `email`, `password`, `phone`, `role`, `created_at`, `updated_at`) VALUES
(1, 'Updated Name', 'cust1@example.com', '$2b$10$4LFqpdeZV7bJy89728Mtiur1Whn3mJ0Bug28IjeREple5tYOYjaP6', '0809999799', 'customer', '2025-09-24 09:45:31', '2025-09-24 10:54:01'),
(2, 'Vendor User', 'vendor1@example.com', '$2b$10$0Aj6NWorbrdWlKIjd1Aqw.fYqOJR0rfy9FFM3K.hedTAYsPdWU4R6', '0802222222', 'vendor', '2025-09-24 09:48:11', NULL),
(3, 'Driver User', 'driver1@example.com', '$2b$10$BKOXcgj/iyV7ElDKn5dBIOKqRpyQ2UM3EHIVLc/sW4.judNGl4jt.', '0803333333', 'driver', '2025-09-24 09:48:59', NULL),
(4, 'Super Admin', 'admin@example.com', '$2b$10$SY7PTSGj/heCXZ2XjzgMiOjC0jdTg2Pjc4cMKMkT7UVQAowod1l2K', '0800000000', 'admin', '2025-09-24 09:53:03', NULL);

-- --------------------------------------------------------

--
-- Table structure for table `vendors`
--

CREATE TABLE `vendors` (
  `id` int(11) NOT NULL,
  `name` varchar(100) NOT NULL,
  `contact` varchar(100) NOT NULL,
  `address` text DEFAULT NULL,
  `user_id` int(11) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Dumping data for table `vendors`
--

INSERT INTO `vendors` (`id`, `name`, `contact`, `address`, `user_id`) VALUES
(1, 'ร้านรถเช่า A (อัปเดท)', '0811111121', 'บางนา กรุงเทพฯ', 2);

--
-- Indexes for dumped tables
--

--
-- Indexes for table `bookings`
--
ALTER TABLE `bookings`
  ADD PRIMARY KEY (`id`),
  ADD KEY `user_id` (`user_id`),
  ADD KEY `car_id` (`car_id`),
  ADD KEY `vendor_id` (`vendor_id`),
  ADD KEY `fk_bookings_driver` (`driver_id`);

--
-- Indexes for table `cars`
--
ALTER TABLE `cars`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `license_plate` (`license_plate`),
  ADD KEY `vendor_id` (`vendor_id`);

--
-- Indexes for table `drivers`
--
ALTER TABLE `drivers`
  ADD PRIMARY KEY (`id`),
  ADD KEY `user_id` (`user_id`);

--
-- Indexes for table `driver_assignments`
--
ALTER TABLE `driver_assignments`
  ADD PRIMARY KEY (`id`),
  ADD KEY `booking_id` (`booking_id`),
  ADD KEY `driver_id` (`driver_id`);

--
-- Indexes for table `notifications`
--
ALTER TABLE `notifications`
  ADD PRIMARY KEY (`id`),
  ADD KEY `user_id` (`user_id`);

--
-- Indexes for table `payments`
--
ALTER TABLE `payments`
  ADD PRIMARY KEY (`id`),
  ADD KEY `booking_id` (`booking_id`);

--
-- Indexes for table `receipts`
--
ALTER TABLE `receipts`
  ADD PRIMARY KEY (`id`),
  ADD KEY `booking_id` (`booking_id`);

--
-- Indexes for table `users`
--
ALTER TABLE `users`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `email` (`email`);

--
-- Indexes for table `vendors`
--
ALTER TABLE `vendors`
  ADD PRIMARY KEY (`id`),
  ADD KEY `user_id` (`user_id`);

--
-- AUTO_INCREMENT for dumped tables
--

--
-- AUTO_INCREMENT for table `bookings`
--
ALTER TABLE `bookings`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=14;

--
-- AUTO_INCREMENT for table `cars`
--
ALTER TABLE `cars`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=17;

--
-- AUTO_INCREMENT for table `drivers`
--
ALTER TABLE `drivers`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=4;

--
-- AUTO_INCREMENT for table `driver_assignments`
--
ALTER TABLE `driver_assignments`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=4;

--
-- AUTO_INCREMENT for table `notifications`
--
ALTER TABLE `notifications`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=33;

--
-- AUTO_INCREMENT for table `payments`
--
ALTER TABLE `payments`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=7;

--
-- AUTO_INCREMENT for table `receipts`
--
ALTER TABLE `receipts`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=3;

--
-- AUTO_INCREMENT for table `users`
--
ALTER TABLE `users`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=8;

--
-- AUTO_INCREMENT for table `vendors`
--
ALTER TABLE `vendors`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=12;

--
-- Constraints for dumped tables
--

--
-- Constraints for table `bookings`
--
ALTER TABLE `bookings`
  ADD CONSTRAINT `bookings_driver_fk` FOREIGN KEY (`driver_id`) REFERENCES `drivers` (`id`) ON DELETE SET NULL,
  ADD CONSTRAINT `bookings_ibfk_1` FOREIGN KEY (`user_id`) REFERENCES `users` (`id`),
  ADD CONSTRAINT `bookings_ibfk_2` FOREIGN KEY (`car_id`) REFERENCES `cars` (`id`),
  ADD CONSTRAINT `bookings_ibfk_3` FOREIGN KEY (`vendor_id`) REFERENCES `vendors` (`id`) ON DELETE SET NULL,
  ADD CONSTRAINT `fk_bookings_driver` FOREIGN KEY (`driver_id`) REFERENCES `drivers` (`id`) ON DELETE SET NULL;

--
-- Constraints for table `cars`
--
ALTER TABLE `cars`
  ADD CONSTRAINT `cars_ibfk_1` FOREIGN KEY (`vendor_id`) REFERENCES `vendors` (`id`);

--
-- Constraints for table `drivers`
--
ALTER TABLE `drivers`
  ADD CONSTRAINT `drivers_ibfk_1` FOREIGN KEY (`user_id`) REFERENCES `users` (`id`);

--
-- Constraints for table `driver_assignments`
--
ALTER TABLE `driver_assignments`
  ADD CONSTRAINT `driver_assignments_ibfk_1` FOREIGN KEY (`booking_id`) REFERENCES `bookings` (`id`),
  ADD CONSTRAINT `driver_assignments_ibfk_2` FOREIGN KEY (`driver_id`) REFERENCES `drivers` (`id`);

--
-- Constraints for table `notifications`
--
ALTER TABLE `notifications`
  ADD CONSTRAINT `notifications_ibfk_1` FOREIGN KEY (`user_id`) REFERENCES `users` (`id`);

--
-- Constraints for table `payments`
--
ALTER TABLE `payments`
  ADD CONSTRAINT `payments_ibfk_1` FOREIGN KEY (`booking_id`) REFERENCES `bookings` (`id`);

--
-- Constraints for table `receipts`
--
ALTER TABLE `receipts`
  ADD CONSTRAINT `receipts_ibfk_1` FOREIGN KEY (`booking_id`) REFERENCES `bookings` (`id`);

--
-- Constraints for table `vendors`
--
ALTER TABLE `vendors`
  ADD CONSTRAINT `vendors_ibfk_1` FOREIGN KEY (`user_id`) REFERENCES `users` (`id`);
COMMIT;

/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
