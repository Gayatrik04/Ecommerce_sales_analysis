USE ecommerce_sales_analysis;

-- 1. CITY PERFORMANCE OVERVIEW
SELECT
    city,
    COUNT(DISTINCT order_id) AS total_orders,
    SUM(quantity) AS total_quantity,
    ROUND(SUM(total_price), 2) AS revenue,
    ROUND(SUM(total_price) / COUNT(DISTINCT order_id),2) AS average_order_value
FROM sales
GROUP BY city
ORDER BY revenue DESC;

-- 2. CITY REVENUE CONTRIBUTION %
SELECT
    city,
    ROUND(SUM(total_price), 2) AS revenue,
    ROUND(SUM(total_price) /(SELECT SUM(total_price) FROM sales) * 100,2) AS revenue_contribution_pct
FROM sales
GROUP BY city
ORDER BY revenue DESC;

-- 3. CITY RANKING BY REVENUE
SELECT
    city,
    ROUND(SUM(total_price), 2) AS revenue,
    RANK() OVER (ORDER BY SUM(total_price) DESC) AS revenue_rank
FROM sales
GROUP BY city
ORDER BY revenue_rank;

-- 4. CITY RANKING BY ORDERS
SELECT
    city,
    COUNT(DISTINCT order_id) AS total_orders,
    RANK() OVER (ORDER BY COUNT(DISTINCT order_id) DESC) AS order_rank
FROM sales
GROUP BY city
ORDER BY order_rank;

-- 5. CITY RANKING BY AOV
SELECT
    city,
    COUNT(DISTINCT order_id) AS total_orders,
    ROUND(SUM(total_price) /COUNT(DISTINCT order_id),2) AS average_order_value,
    RANK() OVER (ORDER BY SUM(total_price) /COUNT(DISTINCT order_id) DESC) AS aov_rank
FROM sales
GROUP BY city
ORDER BY aov_rank;

-- 6. HIGHEST AND LOWEST REVENUE CITY
WITH city_revenue AS (
    SELECT
        city,SUM(total_price) AS revenue
    FROM sales
    GROUP BY city
),
ranked_cities AS (
    SELECT
        city,revenue,
        RANK() OVER (ORDER BY revenue DESC) AS highest_rank,
        RANK() OVER (ORDER BY revenue ASC) AS lowest_rank
    FROM city_revenue
)
SELECT
    city,ROUND(revenue, 2) AS revenue,
    CASE
        WHEN highest_rank = 1 THEN 'Highest Revenue'
        WHEN lowest_rank = 1 THEN 'Lowest Revenue'
    END AS performance
FROM ranked_cities
WHERE highest_rank = 1 OR lowest_rank = 1;

-- 7. CITIES CONTRIBUTING MORE THAN 10% OF REVENUE
SELECT
    city,
    ROUND(SUM(total_price), 2) AS revenue,
    ROUND(SUM(total_price) /(SELECT SUM(total_price) FROM sales) * 100,2) AS revenue_contribution_pct
FROM sales
GROUP BY city
HAVING
    SUM(total_price) /(SELECT SUM(total_price) FROM sales) * 100 > 10
ORDER BY revenue DESC;

-- 8. HIGH ORDERS BUT LOW AOV CITIES
WITH city_metrics AS (
    SELECT
        city,COUNT(DISTINCT order_id) AS total_orders,
        SUM(total_price) AS revenue,
        SUM(total_price) /COUNT(DISTINCT order_id) AS average_order_value
    FROM sales
    GROUP BY city
)
SELECT
    city,total_orders,
    ROUND(revenue, 2) AS revenue,
    ROUND(average_order_value, 2) AS average_order_value
FROM city_metrics
WHERE total_orders > (
	SELECT AVG(total_orders) FROM city_metrics
)
AND average_order_value < (
    SELECT AVG(average_order_value) FROM city_metrics
)
ORDER BY total_orders DESC;

-- 9. CITY + CATEGORY PERFORMANCE
SELECT
    city,category,COUNT(DISTINCT order_id) AS total_orders,
    SUM(quantity) AS quantity_sold,
    ROUND(SUM(total_price), 2) AS revenue
FROM sales
GROUP BY city, category
ORDER BY city, revenue DESC;

-- 10. TOP PRODUCT IN EACH CITY
WITH city_product_sales AS (
    SELECT
        city,product,category,SUM(total_price) AS revenue
    FROM sales
    GROUP BY city, product, category
),
ranked_products AS (
    SELECT
        city,product,category,revenue,
        ROW_NUMBER() OVER (PARTITION BY city ORDER BY revenue DESC) AS product_rank
    FROM city_product_sales
)
SELECT
    city,product,category,ROUND(revenue, 2) AS revenue
FROM ranked_products
WHERE product_rank = 1
ORDER BY revenue DESC;

-- 11. CITY MONTHLY REVENUE
SELECT
    city,year,month_number,month,ROUND(SUM(total_price), 2) AS revenue
FROM sales
GROUP BY city,year,month_number,month
ORDER BY city,year,month_number;

-- 12. CITY MONTH-OVER-MONTH GROWTH
WITH monthly_city_sales AS (
    SELECT city,year,month_number,month,SUM(total_price) AS revenue
    FROM sales
    GROUP BY city,year,month_number,month
),
city_growth AS (
    SELECT
        city,year,month_number,month,revenue,
        LAG(revenue) OVER (PARTITION BY city ORDER BY year, month_number) AS previous_month_revenue
    FROM monthly_city_sales
)
SELECT
    city,year,month_number,month,
    ROUND(revenue, 2) AS revenue,
    ROUND(previous_month_revenue, 2) AS previous_month_revenue,
    ROUND((revenue - previous_month_revenue) /NULLIF(previous_month_revenue, 0) * 100,2) AS mom_growth_pct
FROM city_growth
ORDER BY city, year, month_number;

-- 13. CITY REVENUE VS TOTAL REVENUE
SELECT
    city,
    ROUND(SUM(total_price), 2) AS revenue,
    ROUND(SUM(total_price) /(SELECT SUM(total_price) FROM sales) * 100,2) AS contribution_pct,
    CASE
        WHEN SUM(total_price) /(SELECT SUM(total_price) FROM sales) * 100 >= 10 THEN 'Major Market'
        WHEN SUM(total_price) /(SELECT SUM(total_price) FROM sales) * 100 >= 5 THEN 'Growth Market'
        ELSE 'Smaller Market'
    END AS market_segment
FROM sales
GROUP BY city
ORDER BY revenue DESC;