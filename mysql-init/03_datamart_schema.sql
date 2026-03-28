CREATE DATABASE IF NOT EXISTS datamart;
USE datamart;

CREATE TABLE IF NOT EXISTS mart_sales_monthly (
	periode DATE,
    class ENUM('LOW', 'MEDIUM', 'HIGH'),
    model VARCHAR(50),
    total BIGINT
);

CREATE TABLE IF NOT EXISTS mart_customer_priority (
	periode DATE,
    vin VARCHAR(17),
    customer_name VARCHAR(100),
    address VARCHAR(255),
    count_service SMALLINT,
    priority ENUM('HIGH', 'MED', 'LOW')
);