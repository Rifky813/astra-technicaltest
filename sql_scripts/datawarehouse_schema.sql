-- data warehouse schema

CREATE DATABASE IF NOT EXISTS datawarehouse;
USE datawarehouse;

CREATE TABLE dim_customer (
	customer_sk INT AUTO_INCREMENT PRIMARY KEY,
	src_customer_id INT NOT NULL,
    name VARCHAR(100) NOT NULL,
    dob DATE,
    address VARCHAR(255),
    city VARCHAR(50),
    province VARCHAR(50),
	registration_date TIMESTAMP(3),
    address_updated_at TIMESTAMP(3),
    dw_inserted_at TIMESTAMP(3) DEFAULT CURRENT_TIMESTAMP(3),
    
    INDEX (src_customer_id)
);	

CREATE TABLE fact_sales (
	sales_sk INT AUTO_INCREMENT PRIMARY KEY,
    vin VARCHAR(17),
    customer_sk INT NOT NULL,
    model VARCHAR(30) NOT NULL,
    invoice_date DATE NOT NULL,
    price BIGINT NOT NULL,
    transaction_date TIMESTAMP(3),
    dw_inserted_at TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
    FOREIGN KEY (customer_sk) REFERENCES dim_customer(customer_sk)
);

CREATE TABLE fact_after_sales (
	after_sales_sk INT AUTO_INCREMENT PRIMARY KEY,
    service_ticket VARCHAR(9),
    vin VARCHAR(17),
    customer_sk INT NOT NULL,
    model VARCHAR(30) NOT NULL,
    service_date DATE NOT NULL,
    service_type CHAR(2) NOT NULL,
    transaction_date TIMESTAMP(3),
    dw_inserted_at TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
    FOREIGN KEY (customer_sk) REFERENCES dim_customer(customer_sk)
);