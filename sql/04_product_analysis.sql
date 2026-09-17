USE ecommerce_sales_analysis;

-- PRODUCT PERFORMANCE OVERVIEW
SELECT
    product,category,
    COUNT(DISTINCT order_id) AS total_orders,
    SUM(quantity) AS total_quantity,
    ROUND(SUM(total_price), 2) AS revenue,
    ROUND(AVG(price), 2) AS average_price
FROM sales
GROUP BY product, category
ORDER BY revenue DESC;

-- 2. TOP 10 PRODUCTS BY REVENUE
SELECT
    product,category,ROUND(SUM(total_price), 2) AS revenue
FROM sales
GROUP BY product, category
ORDER BY revenue DESC
LIMIT 10;

-- 3. TOP 10 PRODUCTS BY QUANTITY SOLD
SELECT
    product,category,
    SUM(quantity) AS quantity_sold,ROUND(SUM(total_price), 2) AS revenue
FROM sales
GROUP BY product, category
ORDER BY quantity_sold DESC
LIMIT 10;

-- 4. PRODUCT REVENUE CONTRIBUTION %
SELECT
    product,category,
    ROUND(SUM(total_price), 2) AS revenue,
    ROUND(SUM(total_price) /(SELECT SUM(total_price) FROM sales) * 100,2) AS revenue_contribution_pct
FROM sales
GROUP BY product, category
ORDER BY revenue DESC;

-- 5. TOP 5 PRODUCTS REVENUE CONTRIBUTION
WITH product_revenue AS (
    SELECT
        product,SUM(total_price) AS revenue
    FROM sales
    GROUP BY product
),
ranked_products AS (
    SELECT
        product,revenue,ROW_NUMBER() OVER (ORDER BY revenue DESC) AS product_rank
    FROM product_revenue
)
SELECT
    ROUND(SUM(revenue), 2) AS top_5_revenue,
    ROUND(SUM(revenue) /(SELECT SUM(total_price) FROM sales) * 100,2) AS top_5_revenue_contribution_pct
FROM ranked_products
WHERE product_rank <= 5;

-- 6. HIGHEST REVENUE PRODUCT IN EACH CATEGORY
WITH product_revenue AS (
    SELECT
        category,product,SUM(total_price) AS revenue,SUM(quantity) AS quantity_sold
    FROM sales
    GROUP BY category, product
),
ranked_products AS (
    SELECT
        category,product,revenue,quantity_sold,
        ROW_NUMBER() OVER (PARTITION BY category ORDER BY revenue DESC) AS product_rank
    FROM product_revenue
)
SELECT
    category,product,ROUND(revenue, 2) AS revenue,quantity_sold
FROM ranked_products
WHERE product_rank = 1
ORDER BY revenue DESC;

-- 7. PRODUCTS ABOVE AVERAGE PRODUCT REVENUE
WITH product_revenue AS (
    SELECT
        product,category,SUM(total_price) AS revenue
    FROM sales
    GROUP BY product, category
)
SELECT
    product,category,ROUND(revenue, 2) AS revenue
FROM product_revenue
WHERE revenue > (
    SELECT AVG(revenue) FROM product_revenue
)
ORDER BY revenue DESC;

-- 8. HIGH-VOLUME BUT LOW-REVENUE PRODUCTS
WITH product_metrics AS (
    SELECT
        product,category,SUM(quantity) AS quantity_sold,
        SUM(total_price) AS revenue
    FROM sales
    GROUP BY product, category
)
SELECT
    product,category,quantity_sold,ROUND(revenue, 2) AS revenue
FROM product_metrics
WHERE quantity_sold >= (
    SELECT AVG(quantity_sold) FROM product_metrics
)
AND revenue < (
    SELECT AVG(revenue) FROM product_metrics
)
ORDER BY quantity_sold DESC;

-- 9. PRODUCT MONTHLY REVENUE
SELECT product,year,month_number,month,ROUND(SUM(total_price), 2) AS revenue
FROM sales
GROUP BY product,year,month_number,month
ORDER BY product,year,month_number;

-- 10. PRODUCT MONTH-OVER-MONTH GROWTH
WITH monthly_product_sales AS (
    SELECT
        product,year,month_number,month,SUM(total_price) AS revenue
    FROM sales
    GROUP BY product,year,month_number,month
),
previous_month AS (
    SELECT
        product,year,month_number,month,revenue,
        LAG(revenue) OVER (PARTITION BY product ORDER BY year, month_number) AS previous_month_revenue
    FROM monthly_product_sales
)
SELECT
    product,year,month_number,month,
    ROUND(revenue, 2) AS revenue,
    ROUND(previous_month_revenue, 2) AS previous_month_revenue,
    ROUND((revenue - previous_month_revenue)/ NULLIF(previous_month_revenue, 0) * 100,2) AS mom_growth_pct
FROM previous_month
ORDER BY product, year, month_number;

-- 11. PRODUCT FIRST VS LAST MONTH PERFORMANCE
WITH monthly_product_sales AS (
    SELECT
        product,year,month_number,SUM(total_price) AS revenue
    FROM sales
    GROUP BY product, year, month_number
),
ranked_months AS (
    SELECT
        product,revenue,
        ROW_NUMBER() OVER (PARTITION BY product ORDER BY year, month_number) AS first_rank,
        ROW_NUMBER() OVER (PARTITION BY product ORDER BY year DESC, month_number DESC) AS last_rank
    FROM monthly_product_sales
),
first_month AS (
    SELECT
        product,revenue AS first_month_revenue
    FROM ranked_months
    WHERE first_rank = 1
),
last_month AS (
    SELECT
        product,revenue AS last_month_revenue
    FROM ranked_months
    WHERE last_rank = 1
)
SELECT
    f.product,
    ROUND(f.first_month_revenue, 2) AS first_month_revenue,
    ROUND(l.last_month_revenue, 2) AS last_month_revenue,
    ROUND((l.last_month_revenue - f.first_month_revenue)/ NULLIF(f.first_month_revenue, 0) * 100,2) AS revenue_change_pct
FROM first_month f
JOIN last_month l
    ON f.product = l.product
ORDER BY revenue_change_pct ASC;

-- 12. PRODUCT RANKING BY REVENUE
SELECT
    product,category,
    ROUND(SUM(total_price), 2) AS revenue,
    RANK() OVER (ORDER BY SUM(total_price) DESC) AS revenue_rank
FROM sales
GROUP BY product, category
ORDER BY revenue_rank;



