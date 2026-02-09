-- ============================================
-- WAREHOUSE WMS - Full Database (MySQL)
-- Database name: warehouse_wms
-- IDs: INTEGER (1, 2, 3...) - chhoti ID
-- Import: MySQL me ye file run karo (pehle database banao ya niche CREATE use karo)
-- ============================================

CREATE DATABASE IF NOT EXISTS `warehouse_wms` DEFAULT CHARACTER SET utf8mb4;
USE `warehouse_wms`;

SET NAMES utf8mb4;
SET FOREIGN_KEY_CHECKS = 0;

-- --------------------------------------------
-- companies
-- --------------------------------------------
DROP TABLE IF EXISTS `companies`;
CREATE TABLE `companies` (
  `id` INT NOT NULL AUTO_INCREMENT PRIMARY KEY,
  `name` VARCHAR(255) NOT NULL,
  `code` VARCHAR(100) NOT NULL,
  `email` VARCHAR(255) DEFAULT NULL,
  `phone` VARCHAR(50) DEFAULT NULL,
  `address` TEXT DEFAULT NULL,
  `status` VARCHAR(20) DEFAULT 'ACTIVE',
  `created_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  UNIQUE KEY `companies_code` (`code`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- --------------------------------------------
-- warehouses
-- --------------------------------------------
DROP TABLE IF EXISTS `warehouses`;
CREATE TABLE `warehouses` (
  `id` INT NOT NULL AUTO_INCREMENT PRIMARY KEY,
  `company_id` INT NOT NULL,
  `name` VARCHAR(255) NOT NULL,
  `code` VARCHAR(100) NOT NULL,
  `warehouse_type` VARCHAR(50) DEFAULT NULL,
  `address` TEXT DEFAULT NULL,
  `phone` VARCHAR(50) DEFAULT NULL,
  `capacity` INT DEFAULT NULL,
  `status` VARCHAR(20) DEFAULT 'ACTIVE',
  `created_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  KEY `warehouses_company_id` (`company_id`),
  CONSTRAINT `warehouses_company_fk` FOREIGN KEY (`company_id`) REFERENCES `companies` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- --------------------------------------------
-- users
-- --------------------------------------------
DROP TABLE IF EXISTS `users`;
CREATE TABLE `users` (
  `id` INT NOT NULL AUTO_INCREMENT PRIMARY KEY,
  `email` VARCHAR(255) NOT NULL,
  `password_hash` VARCHAR(255) NOT NULL,
  `name` VARCHAR(255) NOT NULL,
  `role` VARCHAR(50) NOT NULL,
  `company_id` INT DEFAULT NULL,
  `warehouse_id` INT DEFAULT NULL,
  `status` VARCHAR(20) DEFAULT 'ACTIVE',
  `created_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  UNIQUE KEY `users_email` (`email`),
  KEY `users_company_id` (`company_id`),
  KEY `users_warehouse_id` (`warehouse_id`),
  CONSTRAINT `users_company_fk` FOREIGN KEY (`company_id`) REFERENCES `companies` (`id`) ON DELETE SET NULL,
  CONSTRAINT `users_warehouse_fk` FOREIGN KEY (`warehouse_id`) REFERENCES `warehouses` (`id`) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- --------------------------------------------
-- zones
-- --------------------------------------------
DROP TABLE IF EXISTS `zones`;
CREATE TABLE `zones` (
  `id` INT NOT NULL AUTO_INCREMENT PRIMARY KEY,
  `warehouse_id` INT NOT NULL,
  `name` VARCHAR(255) NOT NULL,
  `code` VARCHAR(100) DEFAULT NULL,
  `zone_type` VARCHAR(50) DEFAULT NULL,
  `created_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  KEY `zones_warehouse_id` (`warehouse_id`),
  CONSTRAINT `zones_warehouse_fk` FOREIGN KEY (`warehouse_id`) REFERENCES `warehouses` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- --------------------------------------------
-- locations
-- --------------------------------------------
DROP TABLE IF EXISTS `locations`;
CREATE TABLE `locations` (
  `id` INT NOT NULL AUTO_INCREMENT PRIMARY KEY,
  `zone_id` INT NOT NULL,
  `name` VARCHAR(255) NOT NULL,
  `code` VARCHAR(100) DEFAULT NULL,
  `aisle` VARCHAR(50) DEFAULT NULL,
  `rack` VARCHAR(50) DEFAULT NULL,
  `shelf` VARCHAR(50) DEFAULT NULL,
  `bin` VARCHAR(50) DEFAULT NULL,
  `location_type` VARCHAR(50) DEFAULT NULL,
  `pick_sequence` INT DEFAULT NULL,
  `max_weight` DECIMAL(10,2) DEFAULT NULL,
  `created_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  KEY `locations_zone_id` (`zone_id`),
  CONSTRAINT `locations_zone_fk` FOREIGN KEY (`zone_id`) REFERENCES `zones` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- --------------------------------------------
-- categories
-- --------------------------------------------
DROP TABLE IF EXISTS `categories`;
CREATE TABLE `categories` (
  `id` INT NOT NULL AUTO_INCREMENT PRIMARY KEY,
  `company_id` INT NOT NULL,
  `name` VARCHAR(255) NOT NULL,
  `code` VARCHAR(100) DEFAULT NULL,
  `created_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  KEY `categories_company_id` (`company_id`),
  CONSTRAINT `categories_company_fk` FOREIGN KEY (`company_id`) REFERENCES `companies` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- --------------------------------------------
-- products
-- --------------------------------------------
DROP TABLE IF EXISTS `products`;
CREATE TABLE `products` (
  `id` INT NOT NULL AUTO_INCREMENT PRIMARY KEY,
  `company_id` INT NOT NULL,
  `category_id` INT DEFAULT NULL,
  `name` VARCHAR(255) NOT NULL,
  `sku` VARCHAR(100) NOT NULL,
  `barcode` VARCHAR(100) DEFAULT NULL,
  `price` DECIMAL(12,2) DEFAULT 0.00,
  `reorder_level` INT DEFAULT 0,
  `status` VARCHAR(20) DEFAULT 'ACTIVE',
  `created_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  KEY `products_company_id` (`company_id`),
  KEY `products_category_id` (`category_id`),
  CONSTRAINT `products_company_fk` FOREIGN KEY (`company_id`) REFERENCES `companies` (`id`) ON DELETE CASCADE,
  CONSTRAINT `products_category_fk` FOREIGN KEY (`category_id`) REFERENCES `categories` (`id`) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- --------------------------------------------
-- product_stocks
-- --------------------------------------------
DROP TABLE IF EXISTS `product_stocks`;
CREATE TABLE `product_stocks` (
  `id` INT NOT NULL AUTO_INCREMENT PRIMARY KEY,
  `product_id` INT NOT NULL,
  `warehouse_id` INT NOT NULL,
  `location_id` INT DEFAULT NULL,
  `quantity` INT DEFAULT 0,
  `reserved` INT DEFAULT 0,
  `created_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  KEY `product_stocks_product_id` (`product_id`),
  KEY `product_stocks_warehouse_id` (`warehouse_id`),
  KEY `product_stocks_location_id` (`location_id`),
  CONSTRAINT `product_stocks_product_fk` FOREIGN KEY (`product_id`) REFERENCES `products` (`id`) ON DELETE CASCADE,
  CONSTRAINT `product_stocks_warehouse_fk` FOREIGN KEY (`warehouse_id`) REFERENCES `warehouses` (`id`) ON DELETE CASCADE,
  CONSTRAINT `product_stocks_location_fk` FOREIGN KEY (`location_id`) REFERENCES `locations` (`id`) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- --------------------------------------------
-- customers
-- --------------------------------------------
DROP TABLE IF EXISTS `customers`;
CREATE TABLE `customers` (
  `id` INT NOT NULL AUTO_INCREMENT PRIMARY KEY,
  `company_id` INT NOT NULL,
  `name` VARCHAR(255) NOT NULL,
  `email` VARCHAR(255) DEFAULT NULL,
  `phone` VARCHAR(50) DEFAULT NULL,
  `address` TEXT DEFAULT NULL,
  `created_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  KEY `customers_company_id` (`company_id`),
  CONSTRAINT `customers_company_fk` FOREIGN KEY (`company_id`) REFERENCES `companies` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- --------------------------------------------
-- suppliers
-- --------------------------------------------
DROP TABLE IF EXISTS `suppliers`;
CREATE TABLE `suppliers` (
  `id` INT NOT NULL AUTO_INCREMENT PRIMARY KEY,
  `company_id` INT NOT NULL,
  `code` VARCHAR(100) NOT NULL,
  `name` VARCHAR(255) NOT NULL,
  `email` VARCHAR(255) DEFAULT NULL,
  `phone` VARCHAR(50) DEFAULT NULL,
  `address` TEXT DEFAULT NULL,
  `created_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  KEY `suppliers_company_id` (`company_id`),
  CONSTRAINT `suppliers_company_fk` FOREIGN KEY (`company_id`) REFERENCES `companies` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- --------------------------------------------
-- purchase_orders
-- --------------------------------------------
DROP TABLE IF EXISTS `purchase_order_items`;
DROP TABLE IF EXISTS `purchase_orders`;
CREATE TABLE `purchase_orders` (
  `id` INT NOT NULL AUTO_INCREMENT PRIMARY KEY,
  `company_id` INT NOT NULL,
  `supplier_id` INT NOT NULL,
  `po_number` VARCHAR(255) NOT NULL,
  `status` VARCHAR(50) DEFAULT 'pending',
  `total_amount` DECIMAL(12,2) DEFAULT 0.00,
  `expected_delivery` DATETIME DEFAULT NULL,
  `notes` TEXT DEFAULT NULL,
  `created_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  KEY `purchase_orders_company_id` (`company_id`),
  KEY `purchase_orders_supplier_id` (`supplier_id`),
  CONSTRAINT `purchase_orders_company_fk` FOREIGN KEY (`company_id`) REFERENCES `companies` (`id`) ON DELETE CASCADE,
  CONSTRAINT `purchase_orders_supplier_fk` FOREIGN KEY (`supplier_id`) REFERENCES `suppliers` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- --------------------------------------------
-- purchase_order_items
-- --------------------------------------------
CREATE TABLE `purchase_order_items` (
  `id` INT NOT NULL AUTO_INCREMENT PRIMARY KEY,
  `purchase_order_id` INT NOT NULL,
  `product_id` INT NOT NULL,
  `product_name` VARCHAR(255) DEFAULT NULL,
  `product_sku` VARCHAR(100) DEFAULT NULL,
  `quantity` INT NOT NULL DEFAULT 0,
  `unit_price` DECIMAL(12,2) DEFAULT 0.00,
  `total_price` DECIMAL(12,2) DEFAULT 0.00,
  `created_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  KEY `purchase_order_items_po_id` (`purchase_order_id`),
  KEY `purchase_order_items_product_id` (`product_id`),
  CONSTRAINT `purchase_order_items_po_fk` FOREIGN KEY (`purchase_order_id`) REFERENCES `purchase_orders` (`id`) ON DELETE CASCADE,
  CONSTRAINT `purchase_order_items_product_fk` FOREIGN KEY (`product_id`) REFERENCES `products` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- --------------------------------------------
-- bundles
-- --------------------------------------------
DROP TABLE IF EXISTS `bundle_items`;
DROP TABLE IF EXISTS `bundles`;
CREATE TABLE `bundles` (
  `id` INT NOT NULL AUTO_INCREMENT PRIMARY KEY,
  `company_id` INT NOT NULL,
  `sku` VARCHAR(100) NOT NULL,
  `name` VARCHAR(255) NOT NULL,
  `cost_price` DECIMAL(12,2) DEFAULT 0.00,
  `selling_price` DECIMAL(12,2) DEFAULT 0.00,
  `status` VARCHAR(20) DEFAULT 'ACTIVE',
  `created_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  KEY `bundles_company_id` (`company_id`),
  CONSTRAINT `bundles_company_fk` FOREIGN KEY (`company_id`) REFERENCES `companies` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE `bundle_items` (
  `id` INT NOT NULL AUTO_INCREMENT PRIMARY KEY,
  `bundle_id` INT NOT NULL,
  `product_id` INT NOT NULL,
  `quantity` INT NOT NULL DEFAULT 1,
  `created_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  KEY `bundle_items_bundle_id` (`bundle_id`),
  KEY `bundle_items_product_id` (`product_id`),
  CONSTRAINT `bundle_items_bundle_fk` FOREIGN KEY (`bundle_id`) REFERENCES `bundles` (`id`) ON DELETE CASCADE,
  CONSTRAINT `bundle_items_product_fk` FOREIGN KEY (`product_id`) REFERENCES `products` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- --------------------------------------------
-- sales_orders
-- --------------------------------------------
DROP TABLE IF EXISTS `sales_orders`;
CREATE TABLE `sales_orders` (
  `id` INT NOT NULL AUTO_INCREMENT PRIMARY KEY,
  `company_id` INT NOT NULL,
  `order_number` VARCHAR(100) NOT NULL,
  `customer_id` INT DEFAULT NULL,
  `status` VARCHAR(30) DEFAULT 'pending',
  `total_amount` DECIMAL(12,2) DEFAULT 0.00,
  `created_by` INT DEFAULT NULL,
  `created_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  KEY `sales_orders_company_id` (`company_id`),
  KEY `sales_orders_customer_id` (`customer_id`),
  KEY `sales_orders_created_by` (`created_by`),
  CONSTRAINT `sales_orders_company_fk` FOREIGN KEY (`company_id`) REFERENCES `companies` (`id`) ON DELETE CASCADE,
  CONSTRAINT `sales_orders_customer_fk` FOREIGN KEY (`customer_id`) REFERENCES `customers` (`id`) ON DELETE SET NULL,
  CONSTRAINT `sales_orders_created_by_fk` FOREIGN KEY (`created_by`) REFERENCES `users` (`id`) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- --------------------------------------------
-- order_items
-- --------------------------------------------
DROP TABLE IF EXISTS `order_items`;
CREATE TABLE `order_items` (
  `id` INT NOT NULL AUTO_INCREMENT PRIMARY KEY,
  `sales_order_id` INT NOT NULL,
  `product_id` INT NOT NULL,
  `quantity` INT NOT NULL,
  `unit_price` DECIMAL(12,2) DEFAULT 0.00,
  `created_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  KEY `order_items_sales_order_id` (`sales_order_id`),
  KEY `order_items_product_id` (`product_id`),
  CONSTRAINT `order_items_sales_order_fk` FOREIGN KEY (`sales_order_id`) REFERENCES `sales_orders` (`id`) ON DELETE CASCADE,
  CONSTRAINT `order_items_product_fk` FOREIGN KEY (`product_id`) REFERENCES `products` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- --------------------------------------------
-- pick_lists
-- --------------------------------------------
DROP TABLE IF EXISTS `pick_lists`;
CREATE TABLE `pick_lists` (
  `id` INT NOT NULL AUTO_INCREMENT PRIMARY KEY,
  `sales_order_id` INT NOT NULL,
  `warehouse_id` INT NOT NULL,
  `assigned_to` INT DEFAULT NULL,
  `status` VARCHAR(20) DEFAULT 'pending',
  `created_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  KEY `pick_lists_sales_order_id` (`sales_order_id`),
  KEY `pick_lists_warehouse_id` (`warehouse_id`),
  KEY `pick_lists_assigned_to` (`assigned_to`),
  CONSTRAINT `pick_lists_sales_order_fk` FOREIGN KEY (`sales_order_id`) REFERENCES `sales_orders` (`id`) ON DELETE CASCADE,
  CONSTRAINT `pick_lists_warehouse_fk` FOREIGN KEY (`warehouse_id`) REFERENCES `warehouses` (`id`) ON DELETE CASCADE,
  CONSTRAINT `pick_lists_assigned_to_fk` FOREIGN KEY (`assigned_to`) REFERENCES `users` (`id`) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- --------------------------------------------
-- pick_list_items
-- --------------------------------------------
DROP TABLE IF EXISTS `pick_list_items`;
CREATE TABLE `pick_list_items` (
  `id` INT NOT NULL AUTO_INCREMENT PRIMARY KEY,
  `pick_list_id` INT NOT NULL,
  `product_id` INT NOT NULL,
  `quantity_required` INT NOT NULL,
  `quantity_picked` INT DEFAULT 0,
  `created_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  KEY `pick_list_items_pick_list_id` (`pick_list_id`),
  KEY `pick_list_items_product_id` (`product_id`),
  CONSTRAINT `pick_list_items_pick_list_fk` FOREIGN KEY (`pick_list_id`) REFERENCES `pick_lists` (`id`) ON DELETE CASCADE,
  CONSTRAINT `pick_list_items_product_fk` FOREIGN KEY (`product_id`) REFERENCES `products` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- --------------------------------------------
-- packing_tasks
-- --------------------------------------------
DROP TABLE IF EXISTS `packing_tasks`;
CREATE TABLE `packing_tasks` (
  `id` INT NOT NULL AUTO_INCREMENT PRIMARY KEY,
  `sales_order_id` INT NOT NULL,
  `pick_list_id` INT DEFAULT NULL,
  `assigned_to` INT DEFAULT NULL,
  `status` VARCHAR(20) DEFAULT 'pending',
  `packed_at` DATETIME DEFAULT NULL,
  `created_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  KEY `packing_tasks_sales_order_id` (`sales_order_id`),
  KEY `packing_tasks_pick_list_id` (`pick_list_id`),
  KEY `packing_tasks_assigned_to` (`assigned_to`),
  CONSTRAINT `packing_tasks_sales_order_fk` FOREIGN KEY (`sales_order_id`) REFERENCES `sales_orders` (`id`) ON DELETE CASCADE,
  CONSTRAINT `packing_tasks_pick_list_fk` FOREIGN KEY (`pick_list_id`) REFERENCES `pick_lists` (`id`) ON DELETE SET NULL,
  CONSTRAINT `packing_tasks_assigned_to_fk` FOREIGN KEY (`assigned_to`) REFERENCES `users` (`id`) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- --------------------------------------------
-- shipments
-- --------------------------------------------
DROP TABLE IF EXISTS `shipments`;
CREATE TABLE `shipments` (
  `id` INT NOT NULL AUTO_INCREMENT PRIMARY KEY,
  `sales_order_id` INT NOT NULL,
  `company_id` INT NOT NULL,
  `packed_by` INT DEFAULT NULL,
  `courier_name` VARCHAR(255) DEFAULT NULL,
  `tracking_number` VARCHAR(100) DEFAULT NULL,
  `weight` DECIMAL(10,2) DEFAULT NULL,
  `dispatch_date` DATE DEFAULT NULL,
  `delivery_status` VARCHAR(50) DEFAULT 'pending',
  `created_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  KEY `shipments_sales_order_id` (`sales_order_id`),
  KEY `shipments_company_id` (`company_id`),
  KEY `shipments_packed_by` (`packed_by`),
  CONSTRAINT `shipments_sales_order_fk` FOREIGN KEY (`sales_order_id`) REFERENCES `sales_orders` (`id`) ON DELETE CASCADE,
  CONSTRAINT `shipments_company_fk` FOREIGN KEY (`company_id`) REFERENCES `companies` (`id`) ON DELETE CASCADE,
  CONSTRAINT `shipments_packed_by_fk` FOREIGN KEY (`packed_by`) REFERENCES `users` (`id`) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

SET FOREIGN_KEY_CHECKS = 1;

-- ============================================
-- Super Admin user (login ke liye)
-- Email: admin@kiaan-wms.com | Password: Admin@123
-- ============================================
INSERT INTO `users` (`email`, `password_hash`, `name`, `role`, `company_id`, `warehouse_id`, `status`, `created_at`, `updated_at`)
VALUES (
  'admin@kiaan-wms.com',
  '$2a$10$zp9P4AQJkoZYTNgaKUisrO7BtUYHOq0HKkY7qqFJVsI/TwB.vUQvC',
  'Super Administrator',
  'super_admin',
  NULL,
  NULL,
  'ACTIVE',
  NOW(),
  NOW()
);
