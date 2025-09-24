-- phpMyAdmin SQL Dump
-- Updated for car_booking_app (ปรับปรุงล่าสุด 24 Sep 2025)

CREATE DATABASE IF NOT EXISTS `car_booking_app`;
USE `car_booking_app`;

SET SQL_MODE = "NO_AUTO_VALUE_ON_ZERO";
START TRANSACTION;
SET time_zone = "+00:00";

-- =======================================
-- Table: users
-- =======================================
CREATE TABLE IF NOT EXISTS `users` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `name` varchar(100) NOT NULL,
  `email` varchar(100) NOT NULL UNIQUE,
  `password` varchar(255) NOT NULL,
  `phone` varchar(20) NOT NULL,
  `role` enum('admin','customer','vendor','driver') NOT NULL DEFAULT 'customer',
  `created_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` timestamp NULL DEFAULT NULL ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- =======================================
-- Table: vendors
-- =======================================
CREATE TABLE IF NOT EXISTS `vendors` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `name` varchar(100) NOT NULL,
  `contact` varchar(100) NOT NULL,
  `address` text,
  `user_id` int(11) NOT NULL,
  PRIMARY KEY (`id`),
  KEY `user_id` (`user_id`),
  CONSTRAINT `vendors_ibfk_1` FOREIGN KEY (`user_id`) REFERENCES `users`(`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- =======================================
-- Table: cars
-- =======================================
CREATE TABLE IF NOT EXISTS `cars` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `vendor_id` int(11) NOT NULL,
  `name` varchar(100) NOT NULL,
  `license_plate` varchar(20) NOT NULL UNIQUE,
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
  `free_cancellation` tinyint(1) DEFAULT 1,
  PRIMARY KEY (`id`),
  KEY `vendor_id` (`vendor_id`),
  CONSTRAINT `cars_ibfk_1` FOREIGN KEY (`vendor_id`) REFERENCES `vendors`(`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- =======================================
-- Table: bookings
-- =======================================
CREATE TABLE IF NOT EXISTS `bookings` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `user_id` int(11) NOT NULL,
  `car_id` int(11) NOT NULL,
  `vendor_id` int(11) DEFAULT NULL,
  `driver_required` tinyint(1) DEFAULT 0,
  `booking_date` date DEFAULT NULL,
  `start_time` datetime DEFAULT NULL,
  `end_time` datetime DEFAULT NULL,
  `price` decimal(10,2) DEFAULT 0.00,
  `status` enum('pending','confirmed','cancelled','no_driver_found') DEFAULT 'pending',
  `created_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` timestamp NULL DEFAULT NULL ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  KEY `user_id` (`user_id`),
  KEY `car_id` (`car_id`),
  KEY `vendor_id` (`vendor_id`),
  CONSTRAINT `bookings_ibfk_1` FOREIGN KEY (`user_id`) REFERENCES `users`(`id`),
  CONSTRAINT `bookings_ibfk_2` FOREIGN KEY (`car_id`) REFERENCES `cars`(`id`),
  CONSTRAINT `bookings_ibfk_3` FOREIGN KEY (`vendor_id`) REFERENCES `vendors`(`id`) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- =======================================
-- Table: drivers
-- =======================================
CREATE TABLE IF NOT EXISTS `drivers` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `user_id` int(11) NOT NULL,
  `service_radius_km` int(11) DEFAULT 10,
  `base_lat` decimal(10,7) DEFAULT NULL,
  `base_lng` decimal(10,7) DEFAULT NULL,
  `is_available` tinyint(1) DEFAULT 1,
  PRIMARY KEY (`id`),
  KEY `user_id` (`user_id`),
  CONSTRAINT `drivers_ibfk_1` FOREIGN KEY (`user_id`) REFERENCES `users`(`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- =======================================
-- Table: driver_assignments
-- =======================================
CREATE TABLE IF NOT EXISTS `driver_assignments` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `booking_id` int(11) NOT NULL,
  `driver_id` int(11) NOT NULL,
  `is_accepted` tinyint(1) DEFAULT 0,
  `responded_at` datetime DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `booking_id` (`booking_id`),
  KEY `driver_id` (`driver_id`),
  CONSTRAINT `driver_assignments_ibfk_1` FOREIGN KEY (`booking_id`) REFERENCES `bookings`(`id`),
  CONSTRAINT `driver_assignments_ibfk_2` FOREIGN KEY (`driver_id`) REFERENCES `drivers`(`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- =======================================
-- Table: payments
-- =======================================
CREATE TABLE IF NOT EXISTS `payments` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `booking_id` int(11) NOT NULL,
  `transaction_id` varchar(255) NOT NULL,
  `payment_method` enum('promptpay','qr','credit_card','bank_transfer') NOT NULL,
  `amount` decimal(10,2) NOT NULL,
  `payment_status` enum('pending','paid','failed','refunded') NOT NULL DEFAULT 'pending',
  `created_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  KEY `booking_id` (`booking_id`),
  CONSTRAINT `payments_ibfk_1` FOREIGN KEY (`booking_id`) REFERENCES `bookings`(`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- =======================================
-- Table: receipts
-- =======================================
CREATE TABLE IF NOT EXISTS `receipts` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `booking_id` int(11) NOT NULL,
  `transaction_id` varchar(255) NOT NULL,
  `total_amount` decimal(10,2) NOT NULL,
  `payment_status` enum('paid') NOT NULL DEFAULT 'paid',
  `created_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  KEY `booking_id` (`booking_id`),
  CONSTRAINT `receipts_ibfk_1` FOREIGN KEY (`booking_id`) REFERENCES `bookings`(`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- =======================================
-- Table: notifications
-- =======================================
CREATE TABLE IF NOT EXISTS `notifications` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `user_id` int(11) NOT NULL,
  `title` varchar(255) NOT NULL,
  `message` text NOT NULL,
  `is_read` tinyint(1) DEFAULT 0,
  `created_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  KEY `user_id` (`user_id`),
  CONSTRAINT `notifications_ibfk_1` FOREIGN KEY (`user_id`) REFERENCES `users`(`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

COMMIT;
