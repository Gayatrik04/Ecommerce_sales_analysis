USE ecommerce_sales_analysis;

-- 1. CATEGORY PERFORMANCE OVERVIEW
SELECT
    category,
    COUNT(DISTINCT order_id) AS total_orders,
    SUM(quantity) AS total_quantity,
    ROUND(SUM(total_price), 2) AS revenue,
    ROUND(AVG(price), 2) AS average_selling_price,
    ROUND(SUM(total_price) / COUNT(DISTINCT order_id),2) AS average_order_value
FROM sales
GROUP BY category
ORDER BY revenue DESC;

-- 2. CATEGORY REVENUE CONTRIBUTION %
SELECT
    category,
    ROUND(SUM(total_price), 2) AS revenue,
    ROUND(SUM(total_price) /(SELECT SUM(total_price) FROM sales) * 100,2) AS revenue_contribution_pct
FROM sales
GROUP BY category
ORDER BY revenue DESC;

-- 3. CATEGORY QUANTITY CONTRIBUTION %
SELECT
    category,
    SUM(quantity) AS quantity_sold,
    ROUND(SUM(quantity) /(SELECT SUM(quantity) FROM sales) * 100,2) AS quantity_contribution_pct
FROM sales
GROUP BY category
ORDER BY quantity_sold DESC;

-- 4. CATEGORY RANKING BY REVENUE
SELECT
    category,
    ROUND(SUM(total_price), 2) AS revenue,
    RANK() OVER (ORDER BY SUM(total_price) DESC) AS revenue_rank
FROM sales
GROUP BY category
ORDER BY revenue_rank;

-- 5. CATEGORY RANKING BY QUANTITY
SELECT
    category,
    SUM(quantity) AS quantity_sold,
    RANK() OVER (ORDER BY SUM(quantity) DESC) AS quantity_rank
FROM sales
GROUP BY category
ORDER BY quantity_rank;

-- 6. CATEGORY MONTHLY REVENUE
SELECT
    category,year,month_number,month,ROUND(SUM(total_price), 2) AS revenue
FROM sales
GROUP BY category,year,month_number,month
ORDER BY category,year,month_number;

-- 7. CATEGORY MONTH-OVER-MONTH GROWTH
WITH monthly_category_sales AS (
    SELECT
        category,year,month_number,month,SUM(total_price) AS revenue
    FROM sales
    GROUP BY category,year,month_number,month
),
category_growth AS (
    SELECT
        category,year,month_number,month,revenue,
        LAG(revenue) OVER (PARTITION BY categoryORDER BY year, month_number) AS previous_month_revenue
    FROM monthly_category_sales
)
SELECT
    category,year,month_number,month,
    ROUND(revenue, 2) AS revenue,
    ROUND(previous_month_revenue, 2) AS previous_month_revenue,
    ROUND((revenue - previous_month_revenue)/ NULLIF(previous_month_revenue, 0) * 100,2) AS mom_growth_pct
FROM category_growth
ORDER BY category, year, month_number;

-- 8. HIGHEST REVENUE MONTH FOR EACH CATEGORY
WITH monthly_category_sales AS (
    SELECT
        category,year,month_number,month,SUM(total_price) AS revenue
    FROM sales
    GROUP BY
        category,year,month_number,month
),
ranked_months AS (
    SELECT category,year,month_number,month,revenue,
    ROW_NUMBER() OVER (PARTITION BY category ORDER BY revenue DESC) AS revenue_rank
    FROM monthly_category_sales
)
SELECT
    category,year,month_number,month,ROUND(revenue, 2) AS highest_monthly_revenue
FROM ranked_months
WHERE revenue_rank = 1
ORDER BY highest_monthly_revenue DESC;

-- 9. LOWEST REVENUE MONTH FOR EACH CATEGORY
WITH monthly_category_sales AS (
    SELECT
        category,year,month_number,month,SUM(total_price) AS revenue
    FROM sales
    GROUP BY
        category,year,month_number,month
),
ranked_months AS (
    SELECT
        category,year,month_number,month,revenue,
        ROW_NUMBER() OVER (PARTITION BY category ORDER BY revenue ASC) AS revenue_rank
    FROM monthly_category_sales
)
SELECT
    category,year,month_number,month,ROUND(revenue, 2) AS lowest_monthly_revenue
FROM ranked_months
WHERE revenue_rank = 1
ORDER BY lowest_monthly_revenue ASC;

-- 10. TOP PRODUCT WITHIN EACH CATEGORY
WITH product_category_sales AS (
    SELECT
        category,product,
        SUM(quantity) AS quantity_sold,
        SUM(total_price) AS revenue
    FROM sales
    GROUP BY category, product
),
ranked_products AS (
    SELECT
        category,product,quantity_sold,revenue,
        ROW_NUMBER() OVER (PARTITION BY category ORDER BY revenue DESC) AS product_rank
    FROM product_category_sales
)
SELECT
    category,product,quantity_sold,ROUND(revenue, 2) AS revenue
FROM ranked_products
WHERE product_rank = 1
ORDER BY revenue DESC;

-- 11. CATEGORY CONCENTRATION
WITH category_revenue AS (
    SELECT
        category,SUM(total_price) AS revenue
    FROM sales
    GROUP BY category
),
ranked_categories AS (
    SELECT
        category,revenue,ROW_NUMBER() OVER (ORDER BY revenue DESC) AS category_rank
    FROM category_revenue
)
SELECT
    ROUND(SUM(revenue), 2) AS top_2_category_revenue,
    ROUND(SUM(revenue) /(SELECT SUM(total_price) FROM sales) * 100,2) AS top_2_revenue_contribution_pct
FROM ranked_categories
WHERE category_rank <= 2;

-- 12. CATEGORY REVENUE VS QUANTITY
SELECT
    category,
    SUM(quantity) AS quantity_sold,
    ROUND(SUM(total_price), 2) AS revenue,
    ROUND(SUM(total_price) / SUM(quantity),2) AS revenue_per_unit
FROM sales
GROUP BY category
ORDER BY revenue DESC;