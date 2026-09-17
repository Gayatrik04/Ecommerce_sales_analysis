USE ecommerce_sales_analysis;

-- 1. MONTHLY SALES PERFORMANCE
SELECT
    year,month_number,month,
    COUNT(DISTINCT order_id) AS total_orders,
    SUM(quantity) AS total_quantity,
    ROUND(SUM(total_price), 2) AS revenue,
    ROUND(SUM(total_price) / COUNT(DISTINCT order_id),2) AS average_order_value
FROM sales
GROUP BY year,month_number,month
ORDER BY year,month_number;

-- 2. MONTH-OVER-MONTH REVENUE GROWTH
WITH monthly_sales AS (
    SELECT
        year,month_number,month,SUM(total_price) AS revenue
    FROM sales
    GROUP BY year,month_number,month
),
monthly_growth AS (
    SELECT
        year,month_number,month,revenue,
        LAG(revenue) OVER (ORDER BY year, month_number) AS previous_month_revenue
    FROM monthly_sales
)
SELECT
    year,month_number,month,ROUND(revenue, 2) AS revenue,
    ROUND(previous_month_revenue, 2) AS previous_month_revenue,
    ROUND((revenue - previous_month_revenue) /NULLIF(previous_month_revenue, 0) * 100,2) AS mom_growth_pct
FROM monthly_growth
ORDER BY year, month_number;

-- 3. CUMULATIVE REVENUE
WITH monthly_sales AS (
    SELECT
        year,month_number,month,SUM(total_price) AS revenue
    FROM sales
    GROUP BY year,month_number,month
)
SELECT
    year,month_number,month,
    ROUND(revenue, 2) AS monthly_revenue,
    ROUND(SUM(revenue) OVER (ORDER BY year, month_number),2) AS cumulative_revenue
FROM monthly_sales
ORDER BY year, month_number;

-- 4. MONTHLY REVENUE CONTRIBUTION %
SELECT
    year,month_number,month,ROUND(SUM(total_price), 2) AS revenue,
    ROUND(SUM(total_price) /(SELECT SUM(total_price) FROM sales) * 100,2) AS revenue_contribution_pct
FROM sales
GROUP BY year,month_number,month
ORDER BY year, month_number;

-- 5. HIGHEST REVENUE MONTH
WITH monthly_sales AS (
    SELECT
        year,month_number,month,SUM(total_price) AS revenue
    FROM sales
    GROUP BY year, month_number, month
)
SELECT
    year,month_number,month,ROUND(revenue, 2) AS revenue
FROM monthly_sales
ORDER BY revenue DESC
LIMIT 1;

-- 6. LOWEST REVENUE MONTH
WITH monthly_sales AS (
    SELECT
        year,month_number,month,SUM(total_price) AS revenue
    FROM sales
    GROUP BY year, month_number, month
)
SELECT
    year,month_number,month,ROUND(revenue, 2) AS revenue
FROM monthly_sales
ORDER BY revenue ASC
LIMIT 1;

-- 7. HIGHEST GROWTH MONTH
WITH monthly_sales AS (
    SELECT
        year,month_number,month,SUM(total_price) AS revenue
    FROM sales
    GROUP BY year, month_number, month
),
growth AS (
    SELECT
        year,month_number,month,revenue,
        LAG(revenue) OVER (ORDER BY year, month_number) AS previous_revenue
    FROM monthly_sales
)
SELECT
    year,month_number,month,
    ROUND(revenue, 2) AS revenue,
    ROUND((revenue - previous_revenue) /NULLIF(previous_revenue, 0) * 100,2) AS mom_growth_pct
FROM growth
WHERE previous_revenue IS NOT NULL
ORDER BY mom_growth_pct DESC
LIMIT 1;

-- 8. LOWEST GROWTH MONTH
WITH monthly_sales AS (
    SELECT
        year,month_number,month,SUM(total_price) AS revenue
    FROM sales
    GROUP BY year, month_number, month
),
growth AS (
    SELECT
        year,month_number,month,revenue,
        LAG(revenue) OVER (ORDER BY year, month_number) AS previous_revenue
    FROM monthly_sales
)
SELECT
    year,month_number,month,
    ROUND(revenue, 2) AS revenue,
    ROUND((revenue - previous_revenue) /NULLIF(previous_revenue, 0) * 100,2) AS mom_growth_pct
FROM growth
WHERE previous_revenue IS NOT NULL
ORDER BY mom_growth_pct ASC
LIMIT 1;

-- 9. MONTHLY ORDER VALUE ANALYSIS
SELECT
    year,month_number,month,
    COUNT(DISTINCT order_id) AS total_orders,
    ROUND(SUM(total_price), 2) AS revenue,
    ROUND(SUM(total_price) /COUNT(DISTINCT order_id),2) AS average_order_value
FROM sales
GROUP BY year, month_number, month
ORDER BY year, month_number;

-- 10. MONTHLY REVENUE CHANGE FROM FIRST MONTH
WITH monthly_sales AS (
    SELECT
        year,month_number,month,SUM(total_price) AS revenue
    FROM sales
    GROUP BY year, month_number, month
),
first_month AS (
    SELECT revenue AS first_month_revenue
    FROM monthly_sales
    ORDER BY year, month_number
    LIMIT 1
)
SELECT
    m.year,
    m.month_number,
    m.month,
    ROUND(m.revenue, 2) AS revenue,
    ROUND((m.revenue - f.first_month_revenue) /NULLIF(f.first_month_revenue, 0) * 100,2) AS change_from_first_month_pct
FROM monthly_sales m
CROSS JOIN first_month f
ORDER BY m.year, m.month_number;

-- 11. MONTHLY REVENUE TREND CLASSIFICATION
WITH monthly_sales AS (
    SELECT
        year,month_number,month,SUM(total_price) AS revenue
    FROM sales
    GROUP BY year, month_number, month
),
growth AS (
    SELECT
        year,month_number,month,revenue,
        LAG(revenue) OVER (ORDER BY year, month_number) AS previous_revenue
    FROM monthly_sales
)
SELECT
    year,month_number,month,ROUND(revenue, 2) AS revenue,
    ROUND((revenue - previous_revenue) /NULLIF(previous_revenue, 0) * 100,2) AS mom_growth_pct,
    CASE
        WHEN previous_revenue IS NULL THEN 'Baseline'
        WHEN revenue > previous_revenue THEN 'Growth'
        WHEN revenue < previous_revenue THEN 'Decline'
        ELSE 'Stable'
    END AS trend
FROM growth
ORDER BY year, month_number;

-- 12. FIRST MONTH VS LAST MONTH PERFORMANCE
WITH monthly_sales AS (
    SELECT
        year,month_number,month,SUM(total_price) AS revenue
    FROM sales
    GROUP BY year, month_number, month
),
first_month AS (
    SELECT
        revenue AS first_month_revenue
    FROM monthly_sales
    ORDER BY year, month_number
    LIMIT 1
),
last_month AS (
    SELECT
        revenue AS last_month_revenue
    FROM monthly_sales
    ORDER BY year DESC, month_number DESC
    LIMIT 1
)
SELECT
    ROUND(first_month_revenue, 2) AS first_month_revenue,
    ROUND(last_month_revenue, 2) AS last_month_revenue,
    ROUND((last_month_revenue - first_month_revenue) /NULLIF(first_month_revenue, 0) * 100,2) AS overall_change_pct
FROM first_month
CROSS JOIN last_month;