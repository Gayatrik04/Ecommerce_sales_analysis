USE ecommerce_sales_analysis;

-- 1. OVERALL SALES KPIs

SELECT
    COUNT(DISTINCT order_id) AS total_orders,
    SUM(quantity) AS total_quantity,
    SUM(total_price) AS total_revenue,
    ROUND(SUM(total_price) / COUNT(DISTINCT order_id), 2) AS average_order_value,
    ROUND(SUM(total_price) / SUM(quantity), 2) AS average_selling_price
FROM sales;

-- 2. TOTAL REVENUE
SELECT
    ROUND(SUM(total_price), 2) AS total_revenue
FROM sales;

-- 3. TOTAL ORDERS
SELECT
    COUNT(DISTINCT order_id) AS total_orders
FROM sales;

-- 4. TOTAL QUANTITY SOLD
SELECT
    SUM(quantity) AS total_quantity_sold
FROM sales;

-- 5. REVENUE PER CITY
SELECT
    city,ROUND(SUM(total_price), 2) AS revenue
FROM sales
GROUP BY city
ORDER BY revenue DESC;

-- 6. ORDERS AND REVENUE BY CITY
SELECT
    city,
    COUNT(DISTINCT order_id) AS total_orders,
    SUM(quantity) AS total_quantity,
    ROUND(SUM(total_price), 2) AS revenue,
    ROUND(SUM(total_price) / COUNT(DISTINCT order_id),2) AS average_order_value
FROM sales
GROUP BY city
ORDER BY revenue DESC;

-- 7. REVENUE BY CATEGORY
SELECT
    category,ROUND(SUM(total_price), 2) AS revenue
FROM sales
GROUP BY category
ORDER BY revenue DESC;

-- 8. CATEGORY REVENUE CONTRIBUTION %
SELECT
    category,ROUND(SUM(total_price), 2) AS revenue,
    ROUND(SUM(total_price) /(SELECT SUM(total_price) FROM sales) * 100,2) AS revenue_contribution_pct
FROM sales
GROUP BY category
ORDER BY revenue DESC;

-- 9. MONTHLY SALES KPIs
SELECT
    year,month_number,month,
    COUNT(DISTINCT order_id) AS total_orders,
    SUM(quantity) AS total_quantity,
    ROUND(SUM(total_price), 2) AS revenue,
    ROUND(SUM(total_price) / COUNT(DISTINCT order_id),2) AS average_order_value
FROM sales
GROUP BY year, month_number, month
ORDER BY year, month_number;

-- 10. HIGHEST REVENUE MONTH
SELECT
    year,month_number,month,ROUND(SUM(total_price), 2) AS revenue
FROM sales
GROUP BY year, month_number, month
ORDER BY revenue DESC
LIMIT 1;


-- 11. LOWEST REVENUE MONTH
SELECT
    year,month_number,month,ROUND(SUM(total_price), 2) AS revenue
FROM sales
GROUP BY year, month_number, month
ORDER BY revenue ASC
LIMIT 1;



