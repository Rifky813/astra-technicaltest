-- insert to data warehouse

DELIMITER //

CREATE PROCEDURE sp_load_datawarehouse()
BEGIN

INSERT INTO datawarehouse.fact_sales (vin, customer_sk, model, invoice_date, price, transaction_date)
SELECT 
    s.vin, 
    dc.customer_sk, -- ambil SK, bukan ID asli
    s.model,
    s.invoice_date, 
    REPLACE(s.price, '.', '') AS price,
    s.created_at AS transaction_date
FROM staging.sales_raw s
JOIN datawarehouse.dim_customer dc ON s.customer_id = dc.src_customer_id;

INSERT INTO datawarehouse.dim_customer (src_customer_id, name, dob, address, city, province, registration_date, address_updated_at)
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

INSERT INTO datawarehouse.fact_after_sales (service_ticket, vin, customer_sk, model, service_date, service_type, transaction_date)
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

END //

DELIMITER ;