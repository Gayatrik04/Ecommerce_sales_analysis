CREATE DATABASE IF NOT EXISTS ecommerce_sales_analysis;

USE ecommerce_sales_analysis;

CREATE TABLE sales (
    order_id VARCHAR(50),
    product VARCHAR(100),
    category VARCHAR(50),
    quantity INT,
    price DECIMAL(12,2),
    city VARCHAR(50),
    date DATE,
    total_price DECIMAL(14,2),
    year INT,
    month_number INT,
    month VARCHAR(7)
);

SELECT COUNT(*) AS total_rows FROM sales;

SELECT * FROM sales LIMIT 10;

DESCRIBE sales;