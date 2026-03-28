USE arel_global_marketplace;

SELECT
  o.order_code,
  SUM(oi.quantity * oi.unit_price_customer) AS calc_total,
  o.total_amount
FROM ORDERS o
JOIN ORDER_ITEMS oi ON oi.order_code = o.order_code
GROUP BY o.order_code
ORDER BY o.order_code;



-- Her bir kategoride toplam kaç adet ürün satıldı ve ne kadar ciro (USD bazında) elde edildi?
SELECT 
c.category_name,
SUM(oi.quantity) as TOPLAM_SATİS,
SUM(oi.quantity * oi.unit_price) AS TOPLAM_FİYAT 
FROM CATEGORIES c
JOIN PRODUCTS p ON c.category_name = p.category_name
JOIN PRODUCT_VARIANTS pv ON pv.product_sku = p.product_sku
JOIN ORDER_ITEMS oi ON oi.stock_control_unit = pv.stock_control_unit
GROUP BY c.category_name
ORDER BY TOPLAM_FİYAT DESC;


-- Türkiye'de yaşayan ve toplam harcaması 1000 TRY'nin üzerinde olan kullanıcıları, harcama miktarına göre sırala.
SELECT 
	u.full_name as isim,
    u.email as mail,
    SUM(oi.quantity * oi.unit_price_customer) AS TOPLAM_HARCAMA
FROM USERS u
JOIN ORDERS o ON u.email = o.user_email
JOIN ORDER_ITEMS oi ON o.order_code = oi.order_code
WHERE u.country_name = 'Türkiye'
GROUP BY mail,isim
HAVING TOPLAM_HARCAMA > 1000
ORDER BY TOPLAM_HARCAMA DESC;



-- Hangi kargo firması ortalama kaç günde teslimat yapıyor? (Hızlıdan yavaşa sırala)
SELECT 
	c.carrier_name as taşiyici_adi,
    COUNT(shipment_id) AS teslimat_sayisi,
    AVG(DATEDIFF(delivered_at,shipped_at)) AS ortalama_teslimat_süresi,
    c.delivery_speed_category
FROM CARRIERS c
JOIN SHIPMENTS s ON c.carrier_name = s.carrier_name
WHERE s.delivered_at IS NOT NULL
GROUP BY c.carrier_name,c.delivery_speed_category
ORDER BY ortalama_teslimat_süresi ASC;



-- hiç satılmamış veya stoğu 10'un altına düşmüş ürün varyantlarını; marka, satıcı, fiyat ve satış miktarıyla birlikte listeleyen bir stok uyarı raporu hazırlar.
SELECT
	pv.stock_control_unit as varyantAdi,
    b.brand_name,
    pv.price,
    v.vendor_name,
    p.total_sold as toplam_satiş_miktari,
    pv.stock_number as güncel_stok
FROM PRODUCT_VARIANTS pv
JOIN PRODUCTS p ON p.product_sku = pv.product_sku
JOIN BRANDS b ON p.brand_name = b.brand_name
JOIN VENDORS v ON p.vendor_name = v.vendor_name
WHERE p.total_sold = 0 OR pv.stock_number <= 10
ORDER BY pv.price DESC;



-- En az 2 yorum almış markaların, ortalama puanlarını ve toplam yorum sayılarını listele.
SELECT 
	b.brand_name AS marka_adi,
	AVG(rv.rating) AS ortalama_reyting,
    COUNT(rv.review_id) AS yorum_sayisi
FROM REVIEWS rv
JOIN PRODUCTS p ON rv.product_sku = p.product_sku
JOIN BRANDS b ON p.brand_name = b.brand_name
GROUP BY marka_adi
HAVING COUNT(rv.review_id) > 2
ORDER BY ortalama_reyting DESC;
    
    
-- Sistemdeki her bir kullanıcının kaç farklı farklı kategoriden ürün satın aldığını bulabilir misin? En çok kategori çeşitliliği olan kullanıcıyı en üstte görmek istiyorum.
SELECT
	u.full_name as ad,
    u.email as mail,
    COUNT(DISTINCT c.category_name) AS kategori_sayisi,
    SUM(oi.quantity*unit_price_customer) as TOPLAM_FİYAT
    FROM ORDER_ITEMS oi
JOIN ORDERS o ON o.order_code = oi.order_code
JOIN USERS u ON u.email = o.user_email
JOIN PRODUCT_VARIANTS pv ON oi.stock_control_unit = pv.stock_control_unit
JOIN PRODUCTS p ON pv.product_sku = p.product_sku
JOIN CATEGORIES c ON p.category_name = c.category_name
GROUP BY ad,mail
ORDER BY COUNT(c.category_name) DESC;


-- Kendi ülkesi dışındaki (international) müşterilere en çok satış yapan (toplam adet bazında) ilk 3 satıcıyı (vendor) getir.
SELECT
	v.vendor_name,
    v.country_name,
    COUNT(o.shipping_country_name) AS YURT_DİŞİNA_GÖNDERDİĞİ_SİPARİŞ_SAYİSİ
FROM ORDERS o
JOIN ORDER_ITEMS oi ON o.order_code = oi.order_code
JOIN PRODUCT_VARIANTS pv ON oi.stock_control_unit = pv.stock_control_unit
JOIN PRODUCTS p ON pv.product_sku = p.product_sku
JOIN VENDORS v ON p.vendor_name = v.vendor_name
WHERE  v.country_name != o.shipping_country_name
GROUP BY v.vendor_name,v.country_name
ORDER BY COUNT(o.shipping_country_name) DESC LIMIT 3;


-- Bu sorgu, ortalaması 3.0’ın altında kalan sorunlu kategorileri ve bu kategorilerdeki düşük puanlı yorum sayılarını listeleyen bir müşteri memnuniyet analizidir
SELECT 
	c.category_name,
    AVG(rv.rating) AS ortalama_reyting,
    SUM(CASE WHEN rv.rating < 3 THEN 1 ELSE 0 END) AS düşük_puan_sayisi
FROM REVİEWS rv 
JOIN PRODUCTS p ON rv.product_sku = p.product_sku
JOIN CATEGORIES c ON p.category_name = c.category_name
GROUP BY c.category_name
HAVING AVG(rv.rating) < 3
ORDER BY ortalama_reyting ASC;


-- Bu sorgu, her bir satıcının ulaştığı tekil (benzersiz) müşteri sayısını hesaplayarak, en geniş müşteri portföyüne sahip satıcıları belirleyen bir pazar payı analizidir.
SELECT
	v.vendor_name,
    COUNT(DISTINCT u.email) AS KAC_FARKLİ_MUSTERİ
FROM ORDERS o
JOIN USERS u ON o.user_email = u.email
JOIN ORDER_ITEMS oi ON o.order_code = oi.order_code
JOIN PRODUCT_VARIANTS pv ON oi.stock_control_unit = pv.stock_control_unit
JOIN PRODUCTS p ON pv.product_sku = p.product_sku
JOIN VENDORS v ON p.vendor_name = v.vendor_name
GROUP BY v.vendor_name
ORDER BY KAC_FARKLİ_MUSTERİ DESC;



-- Bu sorgu, hiç satılmayan (ölü stok) ürünlere sahip markaları bularak, deposunda 100 adetten fazla atıl ürün tutan markaları depo maliyeti riski açısından listeler.
SELECT
	b.brand_name,
    p.total_sold,
    SUM(pv.stock_number) AS KALAN_STOK_ADEDİ
FROM PRODUCT_VARIANTS pv 
JOIN PRODUCTS p ON pv.product_sku = p.product_sku
JOIN BRANDS b ON p.brand_name = b.brand_name
WHERE p.total_sold = 0
GROUP BY b.brand_name
HAVING SUM(pv.stock_number) > 100
ORDER BY SUM(pv.stock_number) DESC;


-- Bu sorgu, lojistik performansı ile müşteri memnuniyeti arasındaki bağı inceleyerek, teslimatı 5 günden uzun süren yavaş kargo firmalarının ürün reytinglerini ne kadar etkilediğini analiz eder.
SELECT
	c.carrier_name,
    AVG(DATEDIFF(s.delivered_at,s.shipped_at)) AS ORTALAMA_TESLİMAT_SÜRESİ,
    AVG(rv.rating) AS ORTALAMA_REYTİNG
FROM REVIEWS rv 
JOIN PRODUCTS p ON rv.product_sku = p.product_sku
JOIN PRODUCT_VARIANTS pv ON pv.product_sku = p.product_sku
JOIN ORDER_ITEMS oi ON pv.stock_control_unit = oi.stock_control_unit
JOIN SHIPMENTS s ON oi.order_code = s.order_code
JOIN CARRIERS c ON s.carrier_name = c.carrier_name
GROUP BY c.carrier_name
HAVING AVG(DATEDIFF(s.delivered_at,s.shipped_at)) > 5
ORDER BY AVG(rv.rating) DESC;
	


-- Bu sorgu, hangi ödeme yöntemlerinin (Kredi Kartı, Havale vb.) toplam iade tutarı açısından en yüksek riski taşıdığını gösteren bir finansal kayıp analizidir.
SELECT
	p.method_type,
    SUM(p.refund_amount)
FROM PAYMENTS p GROUP BY p.method_type ORDER BY SUM(p.refund_amount) DESC;


    
-- Sistemdeki satıcıların toplamda kaç farklı ülkeye ürün gönderdiğini hesaplar ve (kendi ülkesi dahil) en az 4 farklı ülkeye ulaşmış olan 'küresel oyuncuları' başarı sırasına göre listeler.    
SELECT
	v.vendor_name,
    v.country_name,
    COUNT(DISTINCT o.shipping_country_name) AS ÜLKE_SAYİSİ
FROM ORDERS o
JOIN ORDER_ITEMS oi ON o.order_code = oi.order_code
JOIN PRODUCT_VARIANTS pv ON oi.stock_control_unit = pv.stock_control_unit
JOIN PRODUCTS p ON pv.product_sku = p.product_sku
JOIN VENDORS v ON p.vendor_name = v.vendor_name
GROUP BY v.vendor_name,v.country_name
HAVING COUNT(DISTINCT o.shipping_country_name) > 3
ORDER BY COUNT(DISTINCT o.shipping_country_name) DESC;


SELECT title, vendor_name 
FROM PRODUCTS 
WHERE title LIKE '%Samsung%';




    
  
  
  -- En yüksek indirim oranına sahip (unit_price vs unit_price_customer) ürünleri ve bu indirimi sağlayan satıcıları listeler.
SELECT 
    p.title, 
    v.vendor_name, 
    ((oi.unit_price - oi.unit_price_customer) / oi.unit_price * 100) AS INDIRIM_ORANI
FROM ORDER_ITEMS oi
JOIN PRODUCT_VARIANTS pv ON oi.stock_control_unit = pv.stock_control_unit
JOIN PRODUCTS p ON pv.product_sku = p.product_sku
JOIN VENDORS v ON p.vendor_name = v.vendor_name
ORDER BY INDIRIM_ORANI DESC;

-- Son 1 ay içerisinde hiç sipariş vermemiş "pasif" müşterileri bularak pazarlama listesi oluşturur.
SELECT u.full_name, u.email, MAX(o.order_date) AS SON_SIPARIS_TARIHI
FROM USERS u
LEFT JOIN ORDERS o ON u.email = o.user_email
GROUP BY u.full_name, u.email
HAVING MAX(o.order_date) < DATE_SUB(CURDATE(), INTERVAL 1 MONTH) OR SON_SIPARIS_TARIHI IS NULL;

-- Hangi ödeme yöntemiyle yapılan satışlarda 'CANCELED' (İptal) durumu daha sık görülüyor?
SELECT o.payment_method, COUNT(*) AS IPTAL_SAYISI
FROM ORDERS o
WHERE o.order_status = 'CANCELED'
GROUP BY o.payment_method
ORDER BY IPTAL_SAYISI DESC;

-- Her bir kategorinin şirket cirosuna katkısını yüzde (%) olarak hesaplayan bir pazar payı raporudur.
SELECT 
    c.category_name, 
    SUM(oi.quantity * oi.unit_price_customer) AS KATEGORI_CIRO,
    (SUM(oi.quantity * oi.unit_price_customer) / (SELECT SUM(quantity * unit_price_customer) FROM ORDER_ITEMS) * 100) AS CIRO_YUZDESI
FROM CATEGORIES c
JOIN PRODUCTS p ON c.category_name = p.category_name
JOIN PRODUCT_VARIANTS pv ON p.product_sku = pv.product_sku
JOIN ORDER_ITEMS oi ON pv.stock_control_unit = oi.stock_control_unit
GROUP BY c.category_name;

-- Sipariş başına ortalama ürün adedi en yüksek olan "toptancı ruhlu" müşterileri listeler.
SELECT u.full_name, AVG(siparis_toplam_adet) AS ORTALAMA_SEPET_HACMI
FROM (
    SELECT user_email, order_code, SUM(quantity) as siparis_toplam_adet
    FROM ORDER_ITEMS oi
    JOIN ORDERS o ON oi.order_code = o.order_code
    GROUP BY order_code, user_email
) AS alt_sorgu
JOIN USERS u ON alt_sorgu.user_email = u.email
GROUP BY u.full_name
ORDER BY ORTALAMA_SEPET_HACMI DESC;

-- Kendi ülkesindeki satıcılardan alışveriş yapmayı tercih eden "milliyetçi" müşterileri ve toplam harcamalarını listeler.
SELECT u.full_name, u.country_name, SUM(oi.quantity * oi.unit_price_customer) AS YEREL_HARCAMA
FROM USERS u
JOIN ORDERS o ON u.email = o.user_email
JOIN ORDER_ITEMS oi ON o.order_code = oi.order_code
JOIN PRODUCT_VARIANTS pv ON oi.stock_control_unit = pv.stock_control_unit
JOIN PRODUCTS p ON pv.product_sku = p.product_sku
JOIN VENDORS v ON p.vendor_name = v.vendor_name
WHERE u.country_name = v.country_name
GROUP BY u.full_name, u.country_name;

-- Hiç yorum almamış (REVIEWS tablosunda kaydı olmayan) ama en az 1 kez satılmış ürünleri listeler.
SELECT p.title, v.vendor_name
FROM PRODUCTS p
JOIN VENDORS v ON p.vendor_name = v.vendor_name
LEFT JOIN REVIEWS rv ON p.product_sku = rv.product_sku
WHERE rv.review_id IS NULL AND p.total_sold > 0;

-- Stoktaki toplam ürün değerini (stok adedi * fiyat) marka bazında hesaplayarak depo sigorta değerini çıkarır.
SELECT b.brand_name, SUM(pv.stock_number * pv.price) AS TOPLAM_DEPO_DEGERI
FROM BRANDS b
JOIN PRODUCTS p ON b.brand_name = p.brand_name
JOIN PRODUCT_VARIANTS pv ON p.product_sku = pv.product_sku
GROUP BY b.brand_name
ORDER BY TOPLAM_DEPO_DEGERI DESC;

-- Hangi günlerde (Haftanın günü bazında) daha fazla sipariş oluşturuluyor? (Satış Trend Analizi)
SELECT DAYNAME(order_date) AS GUN, COUNT(*) AS SIPARIS_SAYISI
FROM ORDERS
GROUP BY GUN
ORDER BY SIPARIS_SAYISI DESC;

-- Hem iade almış hem de düşük puan (1-2) almış sorunlu siparişleri ve bu siparişlerin satıcılarını listeler.
SELECT o.order_code, v.vendor_name, py.refund_amount, rv.rating
FROM ORDERS o
JOIN PAYMENTS py ON o.order_code = py.order_code
JOIN REVIEWS rv ON o.user_email = rv.user_email
JOIN ORDER_ITEMS oi ON o.order_code = oi.order_code
JOIN PRODUCT_VARIANTS pv ON oi.stock_control_unit = pv.stock_control_unit
JOIN PRODUCTS p ON pv.product_sku = p.product_sku
JOIN VENDORS v ON p.vendor_name = v.vendor_name
WHERE py.refund_amount > 0 AND rv.rating < 3;

SELECT
	p.order_code as sipariş_no,
    p.method_type,
	p.amount as ödenen_miktar,
    'başarili_ödeme' as ROL
FROM PAYMENTS p
	WHERE p.refund_amount = 0 && p.amount > 0

UNION

SELECT 
	p.order_code as sipariş_no,
    p.method_type as iade_metodu,
    p.refund_amount as iade_edilen_tutar,
    'iade edilen ödeme' as ROL
FROM PAYMENTS p
WHERE p.refund_amount > 0
    


-- Kategorileri al ve 'Kategori' etiketi tak
SELECT 
    category_name AS ETIKET_ADI, 
    'Kategori' AS TURU
FROM CATEGORIES
UNION
-- Markaları al ve 'Marka' etiketi tak, altına yapıştır
SELECT 
    brand_name AS ETIKET_ADI, 
    'Marka' AS TURU
FROM BRANDS

ORDER BY ETIKET_ADI ASC;




-- Müşterilerimizin olduğu ülkelerin kümesi
SELECT country_name FROM USERS
INTERSECT
SELECT country_name FROM VENDORS;





-- 1. Müşterilerin isimlerini ve rollerini al
SELECT 
    full_name AS ISIM_VEYA_UNVAN, 
    country_name AS LOKASYON, 
    'Müşteri' AS SISTEM_ROLU
FROM USERS

UNION
-- 2. Satıcıların isimlerini altına ekle
SELECT 
    vendor_name AS ISIM_VEYA_UNVAN, 
    country_name AS LOKASYON, 
    'Satıcı' AS SISTEM_ROLU
FROM VENDORS
UNION
-- 3. Kargo firmalarını altına ekle (Ülke bilgisi tabloda yoksa 'Global' yazıyoruz)
SELECT 
    carrier_name AS ISIM_VEYA_UNVAN, 
    'Lojistik Merkezi' AS LOKASYON, 
    'Kargo Firması' AS SISTEM_ROLU
FROM CARRIERS
ORDER BY SISTEM_ROLU DESC;



SELECT
	s.carrier_name,
    COUNT(s.delivered_at) AS BAŞARİLİ_TESLİMAT_SAYİSİ
FROM SHIPMENTS s
WHERE s.delivered_at IS NOT NULL
GROUP BY s.carrier_name
HAVING COUNT(s.delivered_at) > 2;



-- Sistemdeki kargo firmalarının isimlerini ve her birinin toplam kaç adet başarılı teslimat (delivered_at değeri boş olmayan) yaptığını listele. Sadece 2'den fazla teslimat yapmış olanları göster.
SELECT 
	u.country_name,
    o.order_code,
    o.created_at
FROM ORDERS o 
JOIN USERS u ON o.user_email = u.email
WHERE u.country_name = 'Türkiye'
ORDER BY o.order_code;



SELECT 
    p.product_name,
    c.category_name,
    pv.price
FROM PRODUCT_VARIANTS pv
JOIN PRODUCTS p ON pv.product_sku = p.product_sku
JOIN CATEGORIES c ON p.category_name = c.category_name
WHERE pv.price > (
    -- BURASI ALT SORGU: Sadece o kategorinin ortalamasını bulur
    SELECT AVG(pv2.price) 
    FROM PRODUCT_VARIANTS pv2
    JOIN PRODUCTS p2 ON pv2.product_sku = p2.product_sku
    WHERE p2.category_name = c.category_name
)
ORDER BY pv.price DESC;
    

SELECT
	u.full_name,
	u.country_name,
    o.order_code
FROM ORDERS o 
JOIN USERS u ON o.user_email = u.email
WHERE u.country_name = "Almanya"
ORDER BY o.order_code;


SELECT
	p.product_sku,
	oi.stock_control_unit
FROM ORDER_ITEMS oi
JOIN PRODUCT_VARIANTS pv ON oi.stock_control_unit = pv.stock_control_unit
JOIN PRODUCTS p ON pv.product_sku = p.product_sku
ORDER BY p.product_sku;


select 
	p.product_sku
from PRODUCTS p 
JOIN PRODUCT_VARIANTS pv ON p.product_sku = pv.product_sku
except
SELECT 
	p.product_sku
FROM PRODUCTS p
JOIN PRODUCT_VARIANTS pv ON p.product_sku = pv.product_sku
JOIN ORDER_ITEMS oi ON pv.stock_control_unit = oi.stock_control_unit
    
    
SELECT 
	s.order_code
FROM SHIPMENTS s
WHERE s.delivered_at IS NOT NULL



SELECT 
	c.carrier_name,
    COUNT(*) as teslim_edilmemiş_sayisi
FROM SHIPMENTS s
JOIN CARRIERS c ON s.carrier_name = c.carrier_name
WHERE s.delivered_at IS NULL
GROUP BY c.carrier_name
HAVING COUNT(*) > 2
ORDER BY c.carrier_name
    
    
    
SELECT 
		c.category_name,
        count(o.order_code) as toplam_sipariş_sayisi,
        v.vendor_name,
        v.country_name as satici_ülkesi,
        o.shipping_country_name as gönderilen_ülke
FROM ORDERS o 
JOIN ORDER_ITEMS oi ON o.order_code = oi.order_code
JOIN PRODUCT_VARIANTS pv ON oi.stock_control_unit = pv.stock_control_unit
JOIN PRODUCTS p ON pv.product_sku = p.product_sku
JOIN CATEGORIES c ON p.category_name = c.category_name
JOIN VENDORS v ON p.vendor_name = v.vendor_name
GROUP BY c.category_name,v.vendor_name, 
    o.shipping_country_name,        v.vendor_name,
        o.shipping_country_name
ORDER BY sum(p.total_sold)  DESC




