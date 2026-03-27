-- stored procedures query

SELECT
	DATE_FORMAT(created_at, '%y-%m') AS periode,
    CASE
		WHEN price BETWEEN 100000000 AND 250000000 THEN 'LOW'
        WHEN price BETWEEN 250000000 AND 400000000 THEN 'MEDIUM'
        WHEN price > 400000000 THEN 'HIGH'
	END AS class,
    model,
    SUM(price) AS total
FROM sales_raw
GROUP BY 1, 2, 3;

SELECT
	YEAR(asr.created_at) AS periode,
    asr.vin,
    cr.customer_name,
    ca.address,
    COUNT(asr.service_ticket) AS count_service,
    CASE
		WHEN count_service > 10 THEN 'HIGH'
        WHEN count_service BETWEEN 5 AND 10 THEN 'MED'
        WHEN count_service < 5 THEN 'HIGH'
	END AS priority
FROM after_sales_raw asr
LEFT JOIN customers_raw cr ON asr.customer_id = cr.id
LEFT JOIN customer_adresses ca ON cr.id = ca.customer_id
GROUP BY 1, 2, 3, 4, 6;