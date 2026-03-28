USE arel_global_marketplace;


DELIMITER $$
CREATE TRIGGER trg_review_verifiedPurchase
BEFORE INSERT ON REVIEWS
FOR EACH ROW
BEGIN
  IF NOT EXISTS (
    SELECT 1
    FROM ORDERS o
	JOIN ORDER_ITEMS oi ON oi.order_code = o.order_code
    JOIN PRODUCT_VARIANTS pv ON pv.stock_control_unit = oi.stock_control_unit
    WHERE o.user_email = NEW.user_email
      AND pv.product_sku = NEW.product_sku
  ) THEN
    SIGNAL SQLSTATE '45000'
      SET MESSAGE_TEXT = 'Bu ürünü satin alan kullanici değil!';
  END IF;
END$$
DELIMITER;


DELIMITER $$
CREATE TRIGGER trg_users_age_check
BEFORE INSERT ON USERS
FOR EACH ROW
BEGIN
  IF NEW.age < 18 THEN
    SIGNAL SQLSTATE '45000'
      SET MESSAGE_TEXT = '18 yaşindan küçük eklenemez !';
  END IF;
END$$
DELIMITER ;


DELIMITER $$
CREATE TRIGGER trg_users_age_check_forUpdate
BEFORE UPDATE ON USERS
FOR EACH ROW
BEGIN
  IF NEW.age < 18 THEN
    SIGNAL SQLSTATE '45000'
      SET MESSAGE_TEXT = 'kişinin yaşi 18 yaşindan küçük bir yaş olarak güncellenemez !';
  END IF;
END$$
DELIMITER ;


DELIMITER $$
CREATE TRIGGER trg_users_tel_no
BEFORE INSERT ON USERS
FOR EACH ROW
BEGIN
  IF NEW.tel_no IS NOT NULL THEN
    IF JSON_VALID(NEW.tel_no) = 0 THEN
      SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Telefon numarasi JSON formatinde olmalidir';
    END IF;

    IF EXISTS(
      SELECT 1
      FROM JSON_TABLE(NEW.tel_no, '$[*]' COLUMNS(num VARCHAR(20) PATH '$')) AS t
      WHERE t.num REGEXP '^[0-9]+$' = 0
    ) THEN
      SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Telefon numarasi numerik karakter olmalidir!';
    END IF;

    IF EXISTS(
      SELECT 1
      FROM JSON_TABLE(NEW.tel_no, '$[*]' COLUMNS(num VARCHAR(20) PATH '$')) AS t
      WHERE LENGTH(t.num) > 15
    ) THEN
      SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Telefon numarasi 15 karakterden fazla olamaz!!';
    END IF;
  END IF;
END$$
DELIMITER ;

DELIMITER $$
CREATE TRIGGER trg_productVariants_stockNumber_Control
BEFORE INSERT ON ORDER_ITEMS
FOR EACH ROW
BEGIN
  DECLARE mevcut_stok INT;

  SELECT stock_number INTO mevcut_stok
  FROM PRODUCT_VARIANTS
  WHERE stock_control_unit = NEW.stock_control_unit;

  IF mevcut_stok IS NULL THEN
    SIGNAL SQLSTATE '45000'
      SET MESSAGE_TEXT = 'Variant bulunamadı!';
  END IF;

  IF mevcut_stok < NEW.quantity THEN
    SIGNAL SQLSTATE '45000'
      SET MESSAGE_TEXT = 'Stok yetersiz. Bu kadar ürün yok!';
  ELSE
    UPDATE PRODUCT_VARIANTS
    SET stock_number = stock_number - NEW.quantity
    WHERE stock_control_unit = NEW.stock_control_unit;
  END IF;
END$$
DELIMITER ;



DELIMITER $$
CREATE TRIGGER trg_update_order_total_after_insert
AFTER INSERT ON ORDER_ITEMS
FOR EACH ROW
BEGIN
  UPDATE ORDERS
  SET total_amount = (
    SELECT IFNULL(SUM(quantity * unit_price_customer), 0)
    FROM ORDER_ITEMS
    WHERE order_code = NEW.order_code
  )
  WHERE order_code = NEW.order_code;
END$$
DELIMITER ;




DELIMITER $$
CREATE TRIGGER trg_order_orderItems_noUpdate
BEFORE UPDATE ON ORDER_ITEMS
FOR EACH ROW
BEGIN
  IF OLD.unit_price != NEW.unit_price THEN
    SIGNAL SQLSTATE '45000'
      SET MESSAGE_TEXT = 'ORDER_ITEMS unitprice üzerinde değişiklik yapamazsin!';
  END IF;
END$$
DELIMITER ;


DELIMITER $$
CREATE TRIGGER trg_update_total_sold_after_insert
AFTER INSERT ON ORDER_ITEMS
FOR EACH ROW
BEGIN
  UPDATE PRODUCTS p
  JOIN PRODUCT_VARIANTS pv
    ON pv.product_sku = p.product_sku
  SET p.total_sold = (
    SELECT COALESCE(SUM(oi.quantity), 0)
    FROM ORDER_ITEMS oi
    JOIN PRODUCT_VARIANTS pv2 ON pv2.stock_control_unit = oi.stock_control_unit
    WHERE pv2.product_sku = p.product_sku
  )
  WHERE pv.stock_control_unit = NEW.stock_control_unit;
END$$
DELIMITER ;




DELIMITER $$
CREATE TRIGGER trg_shipment_orders_orderCode
BEFORE UPDATE ON SHIPMENTS
FOR EACH ROW
BEGIN
  IF NEW.order_code != OLD.order_code THEN
    SIGNAL SQLSTATE '45000'
      SET MESSAGE_TEXT = 'SHIPMENTS tablosundaki order_code değiştiremezsin!';
  END IF;
END$$
DELIMITER ;


DELIMITER $$
CREATE TRIGGER trg_shipment_date_validation_insert
BEFORE INSERT ON SHIPMENTS
FOR EACH ROW
BEGIN
  DECLARE order_time TIMESTAMP;

  IF NEW.delivered_at IS NOT NULL AND NEW.shipped_at IS NOT NULL AND NEW.shipped_at > NEW.delivered_at THEN
    SIGNAL SQLSTATE '45000'
      SET MESSAGE_TEXT = 'bir kargonun yola çikma tarihi teslim edilme tarihinden sonra olamaz!';
  END IF;

  SELECT created_at INTO order_time
  FROM ORDERS
  WHERE order_code = NEW.order_code;

  IF NEW.shipped_at IS NOT NULL AND order_time > NEW.shipped_at THEN
    SIGNAL SQLSTATE '45000'
      SET MESSAGE_TEXT = 'Sipariş oluşturulmadan önce kargoya verilemez!';
  END IF;
END$$
DELIMITER ;




DELIMITER $$
CREATE TRIGGER trg_shipment_date_validation_update
BEFORE UPDATE ON SHIPMENTS
FOR EACH ROW
BEGIN
  DECLARE order_time TIMESTAMP;

  IF NEW.delivered_at IS NOT NULL AND NEW.shipped_at IS NOT NULL AND NEW.shipped_at > NEW.delivered_at THEN
    SIGNAL SQLSTATE '45000'
      SET MESSAGE_TEXT = 'bir kargonun yola çikma tarihi teslim edilme tarihinden sonra olamaz!';
  END IF;

  SELECT created_at INTO order_time
  FROM ORDERS
  WHERE order_code = NEW.order_code;

  IF NEW.shipped_at IS NOT NULL AND order_time > NEW.shipped_at THEN
    SIGNAL SQLSTATE '45000'
      SET MESSAGE_TEXT = 'Sipariş oluşturulmadan önce kargoya verilemez!';
  END IF;
END$$
DELIMITER ;



DELIMITER $$
CREATE TRIGGER trg_payments_refund_limit
BEFORE INSERT ON PAYMENTS
FOR EACH ROW
FOLLOWS trg_payments_positive_amount
BEGIN
  IF (NEW.refund_amount > NEW.amount)
     OR (NEW.refund_amount < NEW.amount AND NEW.refund_amount != 0) THEN
    SIGNAL SQLSTATE '45000'
      SET MESSAGE_TEXT = 'iade tutari ödeme tutarina eşit olmalidir!';
  END IF;
END$$
DELIMITER ;





DELIMITER $$
CREATE TRIGGER trg_payments_refund_limit_update
BEFORE UPDATE ON PAYMENTS
FOR EACH ROW
BEGIN
  IF (NEW.refund_amount > NEW.amount)
     OR (NEW.refund_amount < NEW.amount AND NEW.refund_amount != 0) THEN
    SIGNAL SQLSTATE '45000'
      SET MESSAGE_TEXT = 'iade tutari ödeme tutarina eşit olmalidir!';
  END IF;
END$$
DELIMITER ;


DELIMITER $$
CREATE TRIGGER trg_payments_auto_amount_currency
BEFORE INSERT ON PAYMENTS
FOR EACH ROW
BEGIN
  DECLARE cc VARCHAR(10);


  SET NEW.amount = (
    SELECT total_amount
    FROM ORDERS
    WHERE order_code = NEW.order_code
  );

  SELECT customer_currency
    INTO cc
  FROM ORDER_ITEMS
  WHERE order_code = NEW.order_code
  LIMIT 1;

  IF cc IS NULL THEN
    SIGNAL SQLSTATE '45000'
      SET MESSAGE_TEXT = 'Payment için order_items bulunamadi!';
  END IF;

  SET NEW.currency = cc;
END$$
DELIMITER ;

drop trigger trg_payments_auto_amount_currency



DELIMITER $$
CREATE TRIGGER trg_categories_parentName_check
BEFORE INSERT ON CATEGORIES
FOR EACH ROW
BEGIN
  IF NEW.parent_category_name IS NOT NULL
     AND NEW.parent_category_name = NEW.category_name THEN
    SIGNAL SQLSTATE '45000'
      SET MESSAGE_TEXT = 'Bir categorynin parent''ı kendi adı olamaz!';
  END IF;
END$$
DELIMITER ;

DELIMITER $$
CREATE TRIGGER trg_categories_parentName_check_update
BEFORE UPDATE ON CATEGORIES
FOR EACH ROW
BEGIN
  IF NEW.parent_category_name IS NOT NULL
     AND NEW.parent_category_name = NEW.category_name THEN
    SIGNAL SQLSTATE '45000'
      SET MESSAGE_TEXT = 'Hata: Bir kategori kendi kendisinin üst kategorisi olamaz!';
  END IF;
END$$
DELIMITER ;

DELIMITER $$
CREATE TRIGGER trg_orderItems_tax_rate_check
BEFORE INSERT ON ORDER_ITEMS
FOR EACH ROW
BEGIN
  IF NEW.tax_rate < 0 OR NEW.tax_rate > 50 THEN
    SIGNAL SQLSTATE '45000'
      SET MESSAGE_TEXT = 'Vergi oranı 0 ile 50 arasında olmalıdır!';
  END IF;
END$$
DELIMITER ;

DELIMITER $$
CREATE TRIGGER trg_orders_address_validation
BEFORE INSERT ON ORDERS
FOR EACH ROW
BEGIN
  IF NEW.shipping_city IS NULL OR NEW.shipping_city = ''
     OR NEW.shipping_address_line IS NULL OR NEW.shipping_address_line = '' THEN
    SIGNAL SQLSTATE '45000'
      SET MESSAGE_TEXT = 'Sipariş adres bilgileri eksik olamaz!';
  END IF;
END$$
DELIMITER ;

DELIMITER $$
CREATE TRIGGER trg_payments_positive_amount
BEFORE INSERT ON PAYMENTS
FOR EACH ROW
FOLLOWS trg_payments_auto_amount_currency
BEGIN
  IF NEW.amount <= 0 THEN
    SIGNAL SQLSTATE '45000'
      SET MESSAGE_TEXT = 'Ödeme tutarı 0 veya negatif olamaz!';
  END IF;

  IF NEW.refund_amount < 0 THEN
    SIGNAL SQLSTATE '45000'
      SET MESSAGE_TEXT = 'İade tutarı negatif olamaz!';
  END IF;
END$$
DELIMITER ;


DELIMITER $$
CREATE TRIGGER trg_reviews_duplicate_check
BEFORE INSERT ON REVIEWS
FOR EACH ROW
BEGIN
  IF EXISTS (
    SELECT 1 FROM REVIEWS
    WHERE user_email = NEW.user_email
      AND product_sku = NEW.product_sku
  ) THEN
    SIGNAL SQLSTATE '45000'
      SET MESSAGE_TEXT = 'Kullanıcı aynı ürüne birden fazla yorum yapamaz!';
  END IF;
END$$
DELIMITER ;

DELIMITER $$
CREATE TRIGGER trg_productVariants_price_stock_check
BEFORE INSERT ON PRODUCT_VARIANTS
FOR EACH ROW
BEGIN
  IF NEW.price <= 0 THEN
    SIGNAL SQLSTATE '45000'
      SET MESSAGE_TEXT = 'Ürün fiyatı 0 veya negatif olamaz!';
  END IF;

  IF NEW.stock_number < 0 THEN
    SIGNAL SQLSTATE '45000'
      SET MESSAGE_TEXT = 'Stok sayısı negatif olamaz!';
  END IF;
END$$
DELIMITER ;


DELIMITER $$
CREATE TRIGGER trg_users_email_format
BEFORE INSERT ON USERS
FOR EACH ROW
BEGIN
  IF NEW.email NOT REGEXP '^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,}$' THEN
    SIGNAL SQLSTATE '45000'
      SET MESSAGE_TEXT = 'Geçersiz e-posta formatı!';
  END IF;
END$$
DELIMITER ;


DELIMITER $$
CREATE TRIGGER trg_orders_future_date_check
BEFORE INSERT ON ORDERS
FOR EACH ROW
BEGIN
  IF NEW.created_at > NOW() THEN
    SIGNAL SQLSTATE '45000'
      SET MESSAGE_TEXT = 'Gelecekteki tarihle sipariş oluşturulamaz!';
  END IF;
END$$
DELIMITER ;




DELIMITER $$
CREATE TRIGGER trg_orderItems_auto_unit_price
BEFORE INSERT ON ORDER_ITEMS
FOR EACH ROW
BEGIN
  DECLARE variant_price DECIMAL(12,2);
  DECLARE cust_curr VARCHAR(10);
  DECLARE fx DECIMAL(18,6);

  SELECT pv.price
    INTO variant_price
  FROM PRODUCT_VARIANTS pv
  WHERE pv.stock_control_unit = NEW.stock_control_unit;

  IF variant_price IS NULL THEN
    SIGNAL SQLSTATE '45000'
      SET MESSAGE_TEXT = 'Geçersiz varyant!';
  END IF;

  SET NEW.unit_price = variant_price;


  SELECT cc.currency_code
    INTO cust_curr
  FROM ORDERS o
  JOIN USERS u ON u.email = o.user_email
  JOIN COUNTRY_CURRENCY cc ON cc.country_name = u.country_name
  WHERE o.order_code = NEW.order_code;

  IF cust_curr IS NULL THEN
    SIGNAL SQLSTATE '45000'
      SET MESSAGE_TEXT = 'Customer currency mapping bulunamadi!';
  END IF;

  SET NEW.customer_currency = cust_curr;


  SELECT r.rate
    INTO fx
  FROM PRODUCT_VARIANTS pv
  JOIN FX_RATES r
    ON r.from_currency = pv.base_currency
   AND r.to_currency   = cust_curr
  WHERE pv.stock_control_unit = NEW.stock_control_unit;

  IF fx IS NULL THEN
    SIGNAL SQLSTATE '45000'
      SET MESSAGE_TEXT = 'FX rate bulunamadi!';
  END IF;


  SET NEW.unit_price_customer = ROUND(NEW.unit_price * fx, 2);
END$$
DELIMITER ;


DELIMITER $$
CREATE TRIGGER trg_productVariants_auto_base_currency
BEFORE INSERT ON PRODUCT_VARIANTS
FOR EACH ROW
BEGIN
  DECLARE v_curr VARCHAR(10);

  SELECT cc.currency_code
    INTO v_curr
  FROM PRODUCTS p
  JOIN VENDORS v ON v.vendor_name = p.vendor_name
  JOIN COUNTRY_CURRENCY cc ON cc.country_name = v.country_name
  WHERE p.product_sku = NEW.product_sku;

  IF v_curr IS NULL THEN
    SIGNAL SQLSTATE '45000'
      SET MESSAGE_TEXT = 'Vendor currency bulunamadi (COUNTRY_CURRENCY/VENDOR/PRODUCTS)!';
  END IF;

  SET NEW.base_currency = v_curr;
END$$
DELIMITER ;



DELIMITER $$
CREATE TRIGGER trg_orders_user_age_policy
BEFORE INSERT ON ORDERS
FOR EACH ROW
BEGIN
  DECLARE user_age INT;

  SELECT age INTO user_age FROM USERS WHERE email = NEW.user_email;

  IF user_age < 18 THEN
    SIGNAL SQLSTATE '45000'
      SET MESSAGE_TEXT = '18 yaş altı kullanıcı sipariş veremez!';
  END IF;
END$$
DELIMITER ;


DELIMITER $$
CREATE TRIGGER trg_orderItems_product_created_check
BEFORE INSERT ON ORDER_ITEMS
FOR EACH ROW
BEGIN
  DECLARE order_time TIMESTAMP;
  DECLARE product_time TIMESTAMP;

  SELECT created_at
  INTO order_time
  FROM ORDERS
  WHERE order_code = NEW.order_code;

  SELECT p.created_at
  INTO product_time
  FROM PRODUCTS p
  JOIN PRODUCT_VARIANTS pv
    ON pv.product_sku = p.product_sku
  WHERE pv.stock_control_unit = NEW.stock_control_unit;

  IF order_time < product_time THEN
    SIGNAL SQLSTATE '45000'
      SET MESSAGE_TEXT = 'Ürün oluşturulmadan önce satılamaz!';
  END IF;
END$$
DELIMITER ;


DELIMITER $$
CREATE TRIGGER trg_orderItems_vendor_registration_check
BEFORE INSERT ON ORDER_ITEMS
FOR EACH ROW
BEGIN
  DECLARE order_time TIMESTAMP;
  DECLARE vendor_reg_date DATE;

  SELECT created_at
  INTO order_time
  FROM ORDERS
  WHERE order_code = NEW.order_code;

  SELECT v.registration_date
  INTO vendor_reg_date
  FROM VENDORS v
  JOIN PRODUCTS p
    ON p.vendor_name = v.vendor_name
  JOIN PRODUCT_VARIANTS pv
    ON pv.product_sku = p.product_sku
  WHERE pv.stock_control_unit = NEW.stock_control_unit;

  IF vendor_reg_date IS NOT NULL
     AND order_time < vendor_reg_date THEN
    SIGNAL SQLSTATE '45000'
      SET MESSAGE_TEXT = 'Satıcı kayıt tarihinden önce ürün satamaz!';
  END IF;
END$$
DELIMITER ;


DELIMITER $$
CREATE TRIGGER trg_reviews_after_delivery
BEFORE INSERT ON REVIEWS
FOR EACH ROW
BEGIN
  DECLARE delivered_time TIMESTAMP;

  SELECT s.delivered_at
  INTO delivered_time
  FROM ORDERS o
  JOIN ORDER_ITEMS oi ON oi.order_code = o.order_code
  JOIN PRODUCT_VARIANTS pv ON pv.stock_control_unit = oi.stock_control_unit
  JOIN SHIPMENTS s ON s.order_code = o.order_code
  WHERE o.user_email = NEW.user_email
    AND pv.product_sku = NEW.product_sku
    AND s.delivered_at IS NOT NULL
  ORDER BY s.delivered_at DESC
  LIMIT 1;

  IF delivered_time IS NULL THEN
    SIGNAL SQLSTATE '45000'
      SET MESSAGE_TEXT = 'Ürün teslim edilmeden yorum yapılamaz!';
  END IF;

  IF NEW.created_at < delivered_time THEN
    SIGNAL SQLSTATE '45000'
      SET MESSAGE_TEXT = 'Yorum tarihi teslim tarihinden önce olamaz!';
  END IF;
END$$
DELIMITER ;

	





