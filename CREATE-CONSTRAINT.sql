CREATE DATABASE arel_global_marketplace
  CHARACTER SET utf8mb4
  COLLATE utf8mb4_unicode_ci;

USE arel_global_marketplace;

CREATE TABLE USERS(
  user_id INT AUTO_INCREMENT PRIMARY KEY,
  full_name VARCHAR(70) NOT NULL,
  email VARCHAR(60) NOT NULL UNIQUE,
  password_hash VARCHAR(100) NOT NULL,
  birth_date DATE NOT NULL,
  gender VARCHAR(20),
  country_name VARCHAR(120) NOT NULL, 
  created_at TIMESTAMP NOT NULL,
  age INT NOT NULL,
  tel_no JSON NOT NULL
);


CREATE TABLE COUNTRY_CURRENCY (
  country_name VARCHAR(120) PRIMARY KEY,
  currency_code VARCHAR(10) NOT NULL
);

CREATE TABLE FX_RATES (
  from_currency VARCHAR(10) NOT NULL,
  to_currency   VARCHAR(10) NOT NULL,
  rate DECIMAL(18,6) NOT NULL,
  updated_at TIMESTAMP NOT NULL
    DEFAULT CURRENT_TIMESTAMP
    ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (from_currency, to_currency)
);



CREATE TABLE VENDORS(
  vendor_id INT AUTO_INCREMENT PRIMARY KEY,
  vendor_name VARCHAR(150) NOT NULL UNIQUE,
  country_name VARCHAR(120) NOT NULL,     
  tax_no VARCHAR(40) NOT NULL,
  registration_date DATE,
  vendor_type VARCHAR(20) NOT NULL
);

CREATE TABLE BRANDS(
  brand_id INT AUTO_INCREMENT PRIMARY KEY,
  brand_name VARCHAR(70) NOT NULL UNIQUE, 
  origin_country VARCHAR(70),
  sustainability_focus BOOLEAN
);


CREATE TABLE CATEGORIES(
  category_id INT AUTO_INCREMENT PRIMARY KEY,
  category_name VARCHAR(120) NOT NULL UNIQUE,   
  parent_category_name VARCHAR(120) NULL,        
  description VARCHAR(150),
  gender_focus VARCHAR(20)
);

CREATE TABLE PRODUCTS(
  product_id INT AUTO_INCREMENT PRIMARY KEY,
  product_sku VARCHAR(40) NOT NULL UNIQUE, 
  vendor_name VARCHAR(150) NOT NULL,       
  category_name VARCHAR(120) NOT NULL,     
  brand_name VARCHAR(50) NULL,           
  title VARCHAR(100) NOT NULL,
  description TEXT,
  eco_friendly BOOLEAN,
  target_age VARCHAR(40),
  created_at TIMESTAMP NOT NULL,
  total_sold INT DEFAULT 0
);

CREATE TABLE PRODUCT_VARIANTS(
  variant_id INT AUTO_INCREMENT PRIMARY KEY,
  product_sku VARCHAR(40) NOT NULL,       
  color VARCHAR(40),
  size VARCHAR(40),
  weight_gram NUMERIC(15,2),
  stock_number INT NOT NULL DEFAULT 0,
  price NUMERIC(12,2) NOT NULL,
  base_currency VARCHAR(10) NOT NULL DEFAULT 'USD',
  stock_control_unit VARCHAR(80) UNIQUE NOT NULL  
);

CREATE TABLE ORDERS(
  order_id INT AUTO_INCREMENT PRIMARY KEY,
  order_code VARCHAR(40) NOT NULL UNIQUE,  
  user_email VARCHAR(60) NOT NULL,         
  shipping_country_name VARCHAR(120) NOT NULL,
  shipping_city VARCHAR(50) NOT NULL,
  shipping_postal_code VARCHAR(20),
  shipping_address_line VARCHAR(250) NOT NULL,
  shipping_address_type VARCHAR(30) NOT NULL,
  total_amount NUMERIC(12,2) NOT NULL DEFAULT 0.00,
  created_at TIMESTAMP NOT NULL
);

CREATE TABLE ORDER_ITEMS(
  order_code VARCHAR(40) NOT NULL,
  stock_control_unit VARCHAR(80) NOT NULL,
  quantity INT NOT NULL DEFAULT 1,
  unit_price NUMERIC(12,2) NOT NULL DEFAULT 0.00,
  customer_currency VARCHAR(10) NOT NULL,
  unit_price_customer NUMERIC(12,2) NOT NULL DEFAULT 0.00,
  tax_rate NUMERIC(5,2),
  PRIMARY KEY(order_code, stock_control_unit)
);

CREATE TABLE PAYMENTS(
  payment_id INT AUTO_INCREMENT PRIMARY KEY,
  order_code VARCHAR(40) NOT NULL UNIQUE,   
  amount NUMERIC(12,2) NOT NULL,
  currency VARCHAR(20) NOT NULL DEFAULT 'USD',
  refund_amount NUMERIC(12,2) DEFAULT 0.00,
  method_type VARCHAR(30) NOT NULL,
  created_at TIMESTAMP NOT NULL
);

CREATE TABLE CARRIERS(
  carrier_id INT AUTO_INCREMENT PRIMARY KEY,
  carrier_name VARCHAR(50) NOT NULL UNIQUE, 
  delivery_speed_category VARCHAR(10)
);

CREATE TABLE SHIPMENTS(
  shipment_id INT AUTO_INCREMENT PRIMARY KEY,
  order_code VARCHAR(40) NOT NULL UNIQUE,   
  carrier_name VARCHAR(50) NOT NULL,              
  shipped_at TIMESTAMP NULL,
  delivered_at TIMESTAMP NULL,
  tracking_number VARCHAR(30) NOT NULL UNIQUE
);

CREATE TABLE REVIEWS(
  review_id INT AUTO_INCREMENT PRIMARY KEY,
  product_sku VARCHAR(40) NOT NULL,       
  user_email VARCHAR(60) NOT NULL,         
  rating INT NOT NULL,
  comment TEXT,
  created_at TIMESTAMP NOT NULL,
  CONSTRAINT chk_reviews_rating CHECK (rating BETWEEN 1 AND 5)
);


ALTER TABLE VENDORS
  ADD CONSTRAINT fk_vendors_country_currency
  FOREIGN KEY (country_name)
  REFERENCES COUNTRY_CURRENCY(country_name)
  ON UPDATE CASCADE
  ON DELETE RESTRICT;

ALTER TABLE USERS
  ADD CONSTRAINT fk_users_country_currency
  FOREIGN KEY (country_name)
  REFERENCES COUNTRY_CURRENCY(country_name)
  ON UPDATE CASCADE
  ON DELETE RESTRICT;

ALTER TABLE PRODUCTS
  ADD CONSTRAINT fk_products_vendors_name
  FOREIGN KEY (vendor_name) REFERENCES VENDORS(vendor_name)
  ON UPDATE CASCADE
  ON DELETE CASCADE;

ALTER TABLE PRODUCTS
  ADD CONSTRAINT fk_products_categories_name
  FOREIGN KEY (category_name) REFERENCES CATEGORIES(category_name)
  ON UPDATE CASCADE
  ON DELETE CASCADE;

ALTER TABLE PRODUCTS
  ADD CONSTRAINT fk_products_brands_name
  FOREIGN KEY (brand_name) REFERENCES BRANDS(brand_name)	
  ON UPDATE CASCADE
  ON DELETE SET NULL;
  

ALTER TABLE CATEGORIES
  ADD CONSTRAINT fk_categories_parent_name
  FOREIGN KEY (parent_category_name) REFERENCES CATEGORIES(category_name)
  ON UPDATE CASCADE
  ON DELETE SET NULL;


ALTER TABLE PRODUCT_VARIANTS
  ADD CONSTRAINT fk_variants_products_sku
  FOREIGN KEY (product_sku) REFERENCES PRODUCTS(product_sku)
  ON UPDATE CASCADE
  ON DELETE CASCADE;
  

CREATE UNIQUE INDEX uq_users_email_country
ON USERS (email, country_name);

ALTER TABLE ORDERS
ADD CONSTRAINT fk_orders_user_email_country
FOREIGN KEY (user_email, shipping_country_name)
REFERENCES USERS(email, country_name)
ON UPDATE CASCADE
ON DELETE RESTRICT;


ALTER TABLE ORDER_ITEMS
  ADD CONSTRAINT fk_order_items_orders_code
  FOREIGN KEY (order_code) REFERENCES ORDERS(order_code)
  ON UPDATE CASCADE
  ON DELETE CASCADE;

ALTER TABLE ORDER_ITEMS
  ADD CONSTRAINT fk_order_items_stock_control_unit
  FOREIGN KEY (stock_control_unit) REFERENCES PRODUCT_VARIANTS(stock_control_unit)
  ON UPDATE CASCADE
  ON DELETE RESTRICT;


ALTER TABLE PAYMENTS
  ADD CONSTRAINT fk_payments_orders_code
  FOREIGN KEY (order_code) REFERENCES ORDERS(order_code)
  ON UPDATE CASCADE
  ON DELETE CASCADE;


ALTER TABLE SHIPMENTS
  ADD CONSTRAINT fk_shipments_orders_code
  FOREIGN KEY (order_code) REFERENCES ORDERS(order_code)
  ON UPDATE CASCADE
  ON DELETE CASCADE;

ALTER TABLE SHIPMENTS
  ADD CONSTRAINT fk_shipments_carriers_name
  FOREIGN KEY (carrier_name) REFERENCES CARRIERS(carrier_name)
  ON UPDATE CASCADE
  ON DELETE RESTRICT;
  

ALTER TABLE REVIEWS
  ADD CONSTRAINT fk_reviews_products_sku
  FOREIGN KEY (product_sku) REFERENCES PRODUCTS(product_sku)
  ON UPDATE CASCADE
  ON DELETE CASCADE;

ALTER TABLE REVIEWS
  ADD CONSTRAINT fk_reviews_users_email
  FOREIGN KEY (user_email) REFERENCES USERS(email)
  ON UPDATE CASCADE
  ON DELETE CASCADE;