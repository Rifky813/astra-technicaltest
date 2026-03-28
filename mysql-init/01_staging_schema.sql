-- staging schema

CREATE DATABASE IF NOT EXISTS staging;
USE staging;

CREATE TABLE IF NOT EXISTS customers_raw(
	id VARCHAR(255),
    name VARCHAR(255),
    dob VARCHAR(50),
    created_at VARCHAR(50)
);

CREATE TABLE IF NOT EXISTS sales_raw(
	vin VARCHAR(50),
    customer_id VARCHAR(255),
    model VARCHAR(255),
    invoice_date VARCHAR(50),
    price VARCHAR(255),
    created_at VARCHAR(50)
);

CREATE TABLE IF NOT EXISTS after_sales_raw(
	service_ticket VARCHAR(50),
    vin VARCHAR(50),
    customer_id VARCHAR(255),
    model VARCHAR(255),
    service_date VARCHAR(50),
    service_type VARCHAR(50),
    created_at VARCHAR(50)
);

CREATE TABLE IF NOT EXISTS customer_addresses(
	id VARCHAR(255),
    customer_id VARCHAR(255),
    address VARCHAR(255),
    city VARCHAR(255),
    province VARCHAR(255),
    created_at VARCHAR(50)
);