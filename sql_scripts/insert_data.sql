-- insert to staging

INSERT INTO customers_raw (id, name, dob, created_at) 
VALUES 
	('1', 'Antonio', '1998-08-04', '2025-03-01 14:24:40.012'),
    ('2', 'Brandon', '2001-04-21', '2025-03-02 08:12:54.003'),
    ('3', 'Charlie', '1980/11/15', '2025-03-02 11:20:02.391'),
    ('4', 'Dominikus', '14/01/1995', '2025-03-03 09:50:41.852'),
    ('5', 'Erik', '1900-01-01', '2025-03-03 17:22:03.198'),
    ('6', 'PT Black Bird', NULL, '2025-03-04 12:52:16.122');
    
INSERT INTO sales_raw (vin, customer_id, model, invoice_date, price, created_at) 
VALUES 
	('JIS8135SAD', '1', 'RAIZA', '2025-03-01', '350.000.000', '2025-03-01 14:24:40.012'),
    ('MAS8160POE', '3', 'RANGGO', '2025-05-19', '430.000.000', '2025-05-19 14:29:21.003'),
    ('JLK1368KDE', '4', 'INNAVO', '2025-05-22', '600.000.000', '2025-05-22 16:10:28.12'),
    ('JLK1869KDF', '6', 'VELOS', '2025-08-02', '390.000.000', '2025-08-02 14:04:31.021'),
    ('JLK1962KOP', '6', 'VELOS', '2025-08-02', '390.000.000', '2025-08-02 15:21:04.201');
    
INSERT INTO after_sales_raw (service_ticket, vin, customer_id, model, service_date, service_type, created_at) 
VALUES 
    ('T124-kgu1', 'MAS8160POE', '3', 'RANGGO', '2025-07-11', 'BP', '2025-07-11 09:24:40.012'),
    ('T560-jga1', 'JLK1368KDE', '4', 'INNAVO', '2025-08-04', 'PM', '2025-08-04 10:12:54.003'),
    ('T521-oai8', 'POI1059IIK', '5', 'RAIZA', '2026-09-10', 'GR', '2026-09-10 12:45:02.391');
    

-- insert to data warehouse

INSERT INTO fact_sales (vin, customer_sk, model, invoice_date, price, transaction_date)
SELECT 
    s.vin, 
    dc.customer_sk, -- ambil SK, bukan ID asli
    s.model,
    s.invoice_date, 
    REPLACE(s.price, '.', '') AS price,
    s.created_at AS transaction_date
FROM staging.sales_raw s
JOIN datawarehouse.dim_customer dc ON s.customer_id = dc.src_customer_id;

INSERT INTO dim_customer (src_customer_id, name, dob, address, city, province, registration_date, address_updated_at)
SELECT
	cr.id,
    cr.name,
    CASE 
        -- Cleaning format 14/01/1995
        WHEN cr.dob LIKE '%/%/%' AND LENGTH(SUBSTRING_INDEX(cr.dob, '/', 1)) <= 2 
            THEN DATE_FORMAT(STR_TO_DATE(cr.dob, '%d/%m/%Y'), '%Y-%m-%d')
        -- Cleaning format 1980/11/15
        WHEN cr.dob LIKE '%/%/%' AND LENGTH(SUBSTRING_INDEX(cr.dob, '/', 1)) = 4 
            THEN DATE_FORMAT(STR_TO_DATE(cr.dob, '%Y/%m/%d'), '%Y-%m-%d')
        -- Format 1998-08-04 (Sudah sesuai)
        WHEN cr.dob LIKE '%-%-%' 
            THEN DATE_FORMAT(STR_TO_DATE(cr.dob, '%Y-%m-%d'), '%Y-%m-%d')
        ELSE NULL 
    END AS dob,
    LOWER(REGEXP_REPLACE(REPLACE(ca.address, 'Jalan', 'Jl'), '[^a-zA-Z0-9 ]', '')) AS address,
    UPPER(ca.city) AS city,
    UPPER(ca.province) AS province,
    cr.created_at AS registration_date,
    ca.created_at AS address_updated_at
FROM staging.customers_raw cr
LEFT JOIN staging.customer_addresses ca ON cr.id = ca.customer_id;

INSERT INTO fact_after_sales (service_ticket, vin, customer_sk, model, service_date, service_type, transaction_date)
SELECT
	af.service_ticket,
    af.vin,
    dc.customer_sk,
    af.model,
    af.service_date,
    af.service_type,
    af.created_at AS transaction_date
FROM staging.after_sales_raw af
JOIN datawarehouse.dim_customer dc ON af.customer_id = dc.src_customer_id;


-- insert to data mart

INSERT INTO datamart.mart_sales_monthly (periode, class, model, total)
SELECT
	DATE_FORMAT(invoice_date, '%Y-%m-%d') AS periode,
    CASE
		WHEN price BETWEEN 100000000 AND 250000000 THEN 'LOW'
        WHEN price BETWEEN 250000000 AND 400000000 THEN 'MEDIUM'
        WHEN price > 400000000 THEN 'HIGH'
        ELSE 'UNDEFINED'
	END AS class,
    model,
    SUM(price) AS total
FROM datawarehouse.fact_sales
GROUP BY 1, 2, 3
ON DUPLICATE KEY UPDATE 
    total = VALUES(total);

INSERT INTO datamart.mart_customer_priority (periode, vin, customer_name, address, count_service, priority)
WITH latest_profile AS (
    -- Mencari profil terbaru untuk setiap customer_id asli
    SELECT 
        src_customer_id, 
        name, 
        address,
        ROW_NUMBER() OVER(PARTITION BY src_customer_id ORDER BY customer_sk DESC) as rn
    FROM datawarehouse.dim_customer
),
service_aggregation AS (
    -- Menghitung total servis per orang fisik (bukan per SK)
    SELECT
        fa.service_date AS periode,
        fa.vin,
        dc.src_customer_id,
        COUNT(fa.service_ticket) AS total_svc
    FROM datawarehouse.fact_after_sales fa
    JOIN datawarehouse.dim_customer dc ON fa.customer_sk = dc.customer_sk
    GROUP BY 1, 2, 3
)
SELECT 
    s.periode,
    s.vin,
    p.name,
    p.address,
    s.total_svc,
    CASE 
        WHEN s.total_svc > 10 THEN 'HIGH'
        WHEN s.total_svc BETWEEN 5 AND 10 THEN 'MED'
        ELSE 'LOW' 
    END AS priority
FROM service_aggregation s
JOIN latest_profile p ON s.src_customer_id = p.src_customer_id
WHERE p.rn = 1 -- Hanya ambil baris profil yang paling baru
ON DUPLICATE KEY UPDATE 
    count_service = VALUES(count_service),
    priority = VALUES(priority),
    address = VALUES(address);