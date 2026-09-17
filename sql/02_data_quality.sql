USE ecommerce_sales_analysis;

-- 1. Check total rows
SELECT COUNT(*) AS total_rows FROM sales;

-- 2. Check duplicate rows
SELECT 
    order_id,product,category,quantity,price,city,date,
    COUNT(*) AS duplicate_count
FROM sales
GROUP BY 
    order_id,product,category,quantity,price,city,date
HAVING COUNT(*) > 1;

-- 3. Check duplicate order IDs
SELECT 
    order_id,COUNT(*) AS product_rows
FROM sales
GROUP BY order_id
HAVING COUNT(*) > 1
ORDER BY product_rows DESC;

-- 4. Check missing values
SELECT
    SUM(order_id IS NULL) AS missing_order_id,
    SUM(product IS NULL) AS missing_product,
    SUM(category IS NULL) AS missing_category,
    SUM(quantity IS NULL) AS missing_quantity,
    SUM(price IS NULL) AS missing_price,
    SUM(city IS NULL) AS missing_city,
    SUM(date IS NULL) AS missing_date,
    SUM(total_price IS NULL) AS missing_total_price
FROM sales;

-- 5. Check invalid quantity
SELECT * FROM sales WHERE quantity <= 0;

-- 6. Check invalid price
SELECT * FROM sales WHERE price <= 0;

-- 7. Validate total price
SELECT COUNT(*) AS incorrect_total_price_rows
FROM sales WHERE ABS(total_price - (quantity * price)) > 0.01;

-- 8. Check date range
SELECT
    MIN(date) AS earliest_date,
    MAX(date) AS latest_date
FROM sales;

-- 9. Check categories
SELECT DISTINCT category
FROM sales
ORDER BY category;

-- 10. Check cities
SELECT DISTINCT city
FROM sales
ORDER BY city;

-- 11. Check monthly records
SELECT
    year,month_number,month,COUNT(*) AS rows_count,SUM(total_price) AS revenue
FROM sales
GROUP BY year, month_number, month
ORDER BY year, month_number;


