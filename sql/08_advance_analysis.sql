USE ecommerce_sales_analysis;

-- 1. TOP PRODUCT + CATEGORY CONTRIBUTION
WITH product_sales AS (
    SELECT
        product,category,SUM(total_price) AS revenue
    FROM sales
    GROUP BY product, category
),
ranked_products AS (
    SELECT
        product,category,revenue,
        ROW_NUMBER() OVER (ORDER BY revenue DESC) AS product_rank
    FROM product_sales
)
SELECT
    product_rank,product,category,ROUND(revenue, 2) AS revenue,
    ROUND(revenue /(SELECT SUM(total_price) FROM sales) * 100,2) AS revenue_contribution_pct
FROM ranked_products
WHERE product_rank <= 10
ORDER BY product_rank;

-- 2. TOP 3 PRODUCTS WITHIN EACH CATEGORY
WITH product_sales AS (
    SELECT
        category,product,SUM(quantity) AS quantity_sold,SUM(total_price) AS revenue
    FROM sales
    GROUP BY category, product
),
ranked_products AS (
    SELECT
        category,product,quantity_sold,
        revenue,
        ROW_NUMBER() OVER (PARTITION BY category ORDER BY revenue DESC) AS product_rank
    FROM product_sales
)
SELECT
    category,product_rank,product,quantity_sold,ROUND(revenue, 2) AS revenue
FROM ranked_products
WHERE product_rank <= 3
ORDER BY category, product_rank;

-- 3. REVENUE CONCENTRATION — TOP 5 PRODUCTS
WITH product_sales AS (
    SELECT
        product,SUM(total_price) AS revenue
    FROM sales
    GROUP BY product
),
ranked_products AS (
    SELECT
        product,revenue,
        ROW_NUMBER() OVER (ORDER BY revenue DESC) AS product_rank
    FROM product_sales
)
SELECT
    ROUND(SUM(revenue), 2) AS top_5_revenue,
    ROUND(SUM(revenue) /(SELECT SUM(total_price) FROM sales) * 100,2) AS top_5_contribution_pct
FROM ranked_products
WHERE product_rank <= 5;

-- 4. PRODUCT REVENUE CONCENTRATION — PARETO ANALYSIS
WITH product_sales AS (
    SELECT
        product,SUM(total_price) AS revenue
    FROM sales
    GROUP BY product
),
ranked_products AS (
    SELECT
        product,revenue,
        ROW_NUMBER() OVER (ORDER BY revenue DESC) AS product_rank
    FROM product_sales
),
cumulative_sales AS (
    SELECT
        product,product_rank,revenue,
        SUM(revenue) OVER (ORDER BY product_rank) AS cumulative_revenue
    FROM ranked_products
)
SELECT
    product_rank,product,
    ROUND(revenue, 2) AS revenue,
    ROUND(cumulative_revenue, 2) AS cumulative_revenue,
    ROUND(cumulative_revenue /(SELECT SUM(total_price) FROM sales) * 100,2) AS cumulative_revenue_pct
FROM cumulative_sales
ORDER BY product_rank;

-- 5. HIGH-VOLUME / LOW-REVENUE PRODUCTS
WITH product_metrics AS (
    SELECT
        product,category,SUM(quantity) AS quantity_sold,SUM(total_price) AS revenue
    FROM sales
    GROUP BY product, category
),
benchmarks AS (
    SELECT
        AVG(quantity_sold) AS avg_quantity,AVG(revenue) AS avg_revenue
    FROM product_metrics
)
SELECT
    p.product,p.category,p.quantity_sold,
    ROUND(p.revenue, 2) AS revenue,
    CASE
        WHEN p.quantity_sold >= b.avg_quantity AND p.revenue < b.avg_revenue
        THEN 'High Volume - Low Revenue'
        WHEN p.quantity_sold < b.avg_quantity AND p.revenue >= b.avg_revenue
        THEN 'Low Volume - High Revenue'
        WHEN p.quantity_sold >= b.avg_quantity AND p.revenue >= b.avg_revenue
        THEN 'High Volume - High Revenue'
        ELSE 'Low Volume - Low Revenue'
    END AS product_segment
FROM product_metrics p
CROSS JOIN benchmarks b
ORDER BY p.revenue DESC;

-- 6. CITY + CATEGORY REVENUE MATRIX
SELECT
    city,
    ROUND(SUM(
        CASE
            WHEN category = 'Electronics' THEN total_price ELSE 0 END), 2) AS electronics_revenue,
    ROUND(SUM(
        CASE
            WHEN category = 'Home Appliances' THEN total_price ELSE 0 END), 2) AS home_appliances_revenue,
    ROUND(SUM(
        CASE
			WHEN category = 'Accessories' THEN total_price ELSE 0 END), 2) AS accessories_revenue,
    ROUND(SUM(
        CASE
			WHEN category = 'Fashion' THEN total_price ELSE 0 END), 2) AS fashion_revenue,

    ROUND(SUM(
        CASE WHEN category = 'Books' THEN total_price ELSE 0 END), 2) AS books_revenue

FROM sales
GROUP BY city
ORDER BY
    (
        electronics_revenue +home_appliances_revenue +accessories_revenue +fashion_revenue +books_revenue
    ) DESC;

-- 7. BEST CATEGORY FOR EACH CITY
WITH city_category_sales AS (
    SELECT
        city,category,SUM(total_price) AS revenue
    FROM sales
    GROUP BY city, category
),
ranked_categories AS (
    SELECT
        city,category,revenue,
        ROW_NUMBER() OVER (PARTITION BY city ORDER BY revenue DESC) AS category_rank
    FROM city_category_sales
)
SELECT
    city,
    category AS top_category,
    ROUND(revenue, 2) AS revenue
FROM ranked_categories
WHERE category_rank = 1
ORDER BY revenue DESC;

-- 8. BEST MONTH FOR EACH CATEGORY
WITH monthly_category_sales AS (
    SELECT
        category,year,month_number,month,SUM(total_price) AS revenue
    FROM sales
    GROUP BY category,year,month_number,month
),
ranked_months AS (
    SELECT
        category,year,month_number,month,revenue,
        ROW_NUMBER() OVER (PARTITION BY category ORDER BY revenue DESC) AS month_rank
    FROM monthly_category_sales
)
SELECT
    category,month,ROUND(revenue, 2) AS revenue
FROM ranked_months
WHERE month_rank = 1
ORDER BY revenue DESC;

-- 9. PRODUCTS WITH DECLINING REVENUE
-- FIRST MONTH VS LAST MONTH
WITH monthly_product_sales AS (
    SELECT
        product,year,month_number,SUM(total_price) AS revenue
    FROM sales
    GROUP BY product, year, month_number
),
first_month AS (
    SELECT
        product,revenue AS first_month_revenue
    FROM (
        SELECT product,revenue,
            ROW_NUMBER() OVER (PARTITION BY product ORDER BY year, month_number) AS rn
        FROM monthly_product_sales
    ) x
    WHERE rn = 1
),
last_month AS (
    SELECT
        product,revenue AS last_month_revenue
    FROM (
        SELECT
            product,revenue,
            ROW_NUMBER() OVER (PARTITION BY product ORDER BY year DESC, month_number DESC) AS rn
        FROM monthly_product_sales
    ) x
    WHERE rn = 1
)
SELECT
    f.product,
    ROUND(f.first_month_revenue, 2) AS first_month_revenue,
    ROUND(l.last_month_revenue, 2) AS last_month_revenue,
    ROUND((l.last_month_revenue - f.first_month_revenue) /NULLIF(f.first_month_revenue, 0) * 100,2) AS revenue_change_pct
FROM first_month f
JOIN last_month l
    ON f.product = l.product
WHERE l.last_month_revenue < f.first_month_revenue
ORDER BY revenue_change_pct ASC;

-- 10. CITY PERFORMANCE SEGMENTATION
WITH city_metrics AS (
    SELECT
        city,COUNT(DISTINCT order_id) AS total_orders,
        SUM(total_price) AS revenue,
        SUM(total_price) / COUNT(DISTINCT order_id) AS aov
    FROM sales
    GROUP BY city
),
benchmarks AS (
    SELECT
        AVG(total_orders) AS avg_orders,
        AVG(revenue) AS avg_revenue,
        AVG(aov) AS avg_aov
    FROM city_metrics
)
SELECT
    c.city,
    c.total_orders,
    ROUND(c.revenue, 2) AS revenue,
    ROUND(c.aov, 2) AS aov,
    CASE
        WHEN c.revenue >= b.avg_revenue AND c.aov >= b.avg_aov
        THEN 'High Value Market'

        WHEN c.total_orders >= b.avg_orders AND c.aov < b.avg_aov
        THEN 'High Volume Opportunity'

        WHEN c.revenue < b.avg_revenue AND c.aov >= b.avg_aov
        THEN 'High AOV - Low Scale'

        ELSE 'Growth Opportunity'
    END AS market_segment
FROM city_metrics c
CROSS JOIN benchmarks b
ORDER BY revenue DESC;

-- 11. MONTHLY CATEGORY MIX
SELECT
    year,month_number,month,category,ROUND(SUM(total_price), 2) AS revenue,
    ROUND(
        SUM(total_price) /SUM(SUM(total_price)) OVER (PARTITION BY year, month_number) * 100,2) AS category_share_pct
FROM sales
GROUP BY year,month_number,month,category
ORDER BY year,month_number,revenue DESC;

-- 12. BUSINESS OPPORTUNITY SUMMARY
WITH product_metrics AS (
    SELECT
        product,category,SUM(quantity) AS quantity_sold,SUM(total_price) AS revenue
    FROM sales
    GROUP BY product, category
),
benchmarks AS (
    SELECT
        AVG(quantity_sold) AS avg_quantity,AVG(revenue) AS avg_revenue
    FROM product_metrics
)
SELECT
    p.product,p.category,p.quantity_sold,ROUND(p.revenue, 2) AS revenue,
    'Potential Bundling / Upselling Opportunity'AS business_opportunity
FROM product_metrics p
CROSS JOIN benchmarks b
WHERE p.quantity_sold >= b.avg_quantity
  AND p.revenue < b.avg_revenue
ORDER BY p.quantity_sold DESC;