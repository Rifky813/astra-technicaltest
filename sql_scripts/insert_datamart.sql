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
