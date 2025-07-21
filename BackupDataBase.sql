-- โครงสร้างฐานข้อมูลสำหรับ `car_booking_app`

CREATE DATABASE IF NOT EXISTS `car_booking_app`;

USE `car_booking_app`;

-- ตาราง `users`
CREATE TABLE IF NOT EXISTS `users` (
  `id` INT NOT NULL AUTO_INCREMENT PRIMARY KEY,
  `name` VARCHAR(100) NOT NULL,
  `email` VARCHAR(100) NOT NULL UNIQUE,
  `password` VARCHAR(255) NOT NULL,
  `phone` VARCHAR(20) NOT NULL,
  `role` ENUM('customer', 'vendor', 'driver') NOT NULL DEFAULT 'customer',
  `created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);

-- ตาราง `vendors`
CREATE TABLE IF NOT EXISTS `vendors` (
  `id` INT NOT NULL AUTO_INCREMENT PRIMARY KEY,
  `name` VARCHAR(100) NOT NULL,
  `contact` VARCHAR(100) NOT NULL,
  `address` TEXT,
  `user_id` INT NOT NULL,
  FOREIGN KEY (`user_id`) REFERENCES `users`(`id`)
);

-- ตาราง `cars`
CREATE TABLE IF NOT EXISTS `cars` (
  `id` INT NOT NULL AUTO_INCREMENT PRIMARY KEY,
  `vendor_id` INT NOT NULL,
  `name` VARCHAR(100) NOT NULL,
  `license_plate` VARCHAR(20) NOT NULL,
  `is_available` TINYINT(1) NOT NULL DEFAULT 1,
  `price_per_day` DECIMAL(10,2) NOT NULL DEFAULT 0.00,
  `location_lat` DECIMAL(10,7),
  `location_lng` DECIMAL(10,7),
  `image_url` TEXT,
  `transmission` ENUM('automatic', 'manual') NOT NULL,
  FOREIGN KEY (`vendor_id`) REFERENCES `vendors`(`id`)
);

-- ตาราง `bookings`
CREATE TABLE IF NOT EXISTS `bookings` (
  `id` INT NOT NULL AUTO_INCREMENT PRIMARY KEY,
  `user_id` INT NOT NULL,
  `car_id` INT NOT NULL,
  `status` ENUM('pending', 'confirmed', 'cancelled') NOT NULL DEFAULT 'pending',
  `booking_date` DATE NOT NULL,
  `created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (`user_id`) REFERENCES `users`(`id`),
  FOREIGN KEY (`car_id`) REFERENCES `cars`(`id`)
);

-- ตาราง `payments`
CREATE TABLE IF NOT EXISTS `payments` (
  `id` INT NOT NULL AUTO_INCREMENT PRIMARY KEY,
  `booking_id` INT NOT NULL,
  `transaction_id` VARCHAR(255) NOT NULL,
  `payment_method` ENUM('promptpay', 'qr', 'credit_card') NOT NULL,
  `amount` DECIMAL(10,2) NOT NULL,
  `payment_status` ENUM('pending', 'paid', 'failed') NOT NULL DEFAULT 'pending',
  `created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (`booking_id`) REFERENCES `bookings`(`id`)
);

-- ตาราง `receipts`
CREATE TABLE IF NOT EXISTS `receipts` (
  `id` INT NOT NULL AUTO_INCREMENT PRIMARY KEY,
  `booking_id` INT NOT NULL,
  `transaction_id` VARCHAR(255) NOT NULL,
  `total_amount` DECIMAL(10,2) NOT NULL,
  `payment_status` ENUM('paid') NOT NULL DEFAULT 'paid',
  `created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (`booking_id`) REFERENCES `bookings`(`id`)
);

-- ตาราง `notifications`
CREATE TABLE IF NOT EXISTS `notifications` (
  `id` INT NOT NULL AUTO_INCREMENT PRIMARY KEY,
  `user_id` INT NOT NULL,
  `title` VARCHAR(255) NOT NULL,
  `message` TEXT NOT NULL,
  `is_read` TINYINT(1) NOT NULL DEFAULT 0,
  `created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (`user_id`) REFERENCES `users`(`id`)
);

-- ตาราง `drivers`
CREATE TABLE IF NOT EXISTS `drivers` (
  `id` INT NOT NULL AUTO_INCREMENT PRIMARY KEY,
  `user_id` INT NOT NULL,
  `service_radius_km` INT NOT NULL DEFAULT 10,
  `is_available` TINYINT(1) NOT NULL DEFAULT 1,
  FOREIGN KEY (`user_id`) REFERENCES `users`(`id`)
);

-- ตาราง `driver_assignments`
CREATE TABLE IF NOT EXISTS `driver_assignments` (
  `id` INT NOT NULL AUTO_INCREMENT PRIMARY KEY,
  `booking_id` INT NOT NULL,
  `driver_id` INT NOT NULL,
  `is_accepted` TINYINT(1) NOT NULL DEFAULT 0,
  `responded_at` DATETIME,
  FOREIGN KEY (`booking_id`) REFERENCES `bookings`(`id`),
  FOREIGN KEY (`driver_id`) REFERENCES `drivers`(`id`)
);

-- ตัวอย่างข้อมูล `users`
INSERT INTO `users` (`name`, `email`, `password`, `phone`, `role`) VALUES
('Nana', 'nana@example.com', 'hashedpassword', '0891234567', 'customer'),
('Vendor A', 'vendor@example.com', 'hashedpassword', '0891112233', 'vendor'),
('Driver A', 'driver@example.com', 'hashedpassword', '0894455667', 'driver');

-- ตัวอย่างข้อมูล `vendors`
INSERT INTO `vendors` (`name`, `contact`, `address`, `user_id`) VALUES
('ร้านรถบางนา', '0812345678', 'บางนา กรุงเทพ', 2);

-- ตัวอย่างข้อมูล `cars`
INSERT INTO `cars` (`vendor_id`, `name`, `license_plate`, `is_available`, `price_per_day`, `transmission`) VALUES
(1, 'Toyota Camry', 'กข1234', 1, 1500.00, 'automatic');

-- ตัวอย่างข้อมูล `bookings`
INSERT INTO `bookings` (`user_id`, `car_id`, `status`, `booking_date`) VALUES
(1, 1, 'pending', '2025-07-23');

-- ตัวอย่างข้อมูล `payments`
INSERT INTO `payments` (`booking_id`, `transaction_id`, `payment_method`, `amount`, `payment_status`) VALUES
(1, 'TXN-12345', 'credit_card', 1500.00, 'pending');

-- ตัวอย่างข้อมูล `receipts`
INSERT INTO `receipts` (`booking_id`, `transaction_id`, `total_amount`, `payment_status`) VALUES
(1, 'TXN-12345', 1500.00, 'paid');

-- ตัวอย่างข้อมูล `notifications`
INSERT INTO `notifications` (`user_id`, `title`, `message`, `is_read`) VALUES
(1, 'การจองสำเร็จ', 'การจองของคุณสำเร็จแล้ว', 0);
