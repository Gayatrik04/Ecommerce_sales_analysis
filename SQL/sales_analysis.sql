create database ecommerce_sales_analysis;

use ecommerce_sales_analysis; 

create table sales(
Order_id varchar(50),
Product varchar(100),
Category varchar(50),
Quantity int,
Price decimal,
City varchar(20),
Date date,
Total_price decimal,
Month varchar(12)
);

-- 1. What is the total revenue generated?
select sum(Total_price)as total_revenue from sales;

-- 2. How many orders were placed?
select count(Order_id)as total_orders from sales;

-- 3. What is the total quantity of products sold?
select sum(Quantity) as total_quantity from sales;

-- 4. What is the average order value?
select avg(Total_price)as avg_order_value from sales;

-- 5. Which product categories generated the highest revenue?
select Category,sum(Total_price)as revenue from sales group by Category order by revenue desc;

-- 6. Which are the Top 5 revenue-generating products?
select product,category,sum(Total_price)as Revenue_generated 
from sales 
group by product,category 
order by Revenue_generated desc 
limit 5;

-- 7. Which cities generated the highest revenue?
select city,sum(Total_price)as revenue from sales group by city order by revenue desc;

-- 8. Which month generated the highest revenue?
select Month,sum(Total_price)as revenue from sales group by Month order by revenue desc limit 1;

-- 9. Which category sold the highest quantity?
select category,sum(Quantity)as Total_quantity_sold from sales group by category order by Total_quantity_sold desc limit 1;

-- 10. Which products have the highest average selling price?
select product,avg(price)as avg_selling_price from sales group by product order by avg_selling_price desc ;

-- 11. What percentage of total revenue does each category contribute?
select category,sum(Total_price)as Total_revenue_category, 
round((sum(Total_price)/(select sum(Total_price) from sales))*100,2) as percenatge_contribution
from sales 
group by category 
order by percenatge_contribution desc;

-- 12. Rank products based on total revenue.
select product,sum(Total_price),Rank() over (order by sum(total_price) desc) as rnk
from sales group by product;

-- 13. Which city has the highest average order value?
select city,avg(Total_price)as avg_order_value from sales group by city order by avg_order_value desc;

-- 14. Find the cumulative monthly revenue.
with monthly_revenue as(
select month,sum(Total_price)as total_revenue 
from sales 
group by month)
select month,total_revenue,
sum(total_revenue) over(order by month asc) as cumulative_monthly_revenue 
from monthly_revenue;

-- 15. Which products generated revenue above the average product revenue?
select product,sum(Total_price)as revenue from sales group by product having revenue >(select avg(Total_price) from sales);

-- Find the second highest revenue-generating category.
select category,sum(Total_price)as total_revenue from sales group by category order by total_revenue desc limit 1 offset 1;

-- Find the top-selling product in each category.
with category_product_sales as (
select category,product,sum(Total_price)as total_revenue,
rank()over(partition by category order by sum(Total_price) desc) as rnk 
from sales 
group by category,product 
order by total_revenue desc
)
select * from category_product_sales where rnk=1;

-- Calculate month-over-month revenue growth.
with curr_month as(
select month,sum(Total_price) as curr_month_revenue 
from sales 
group by month
),
prev_month as(
select month,curr_month_revenue,
lag(curr_month_revenue,1)over(order by month asc)as prev_month_revenue 
from curr_month
)
select month,curr_month_revenue,prev_month_revenue,
round(((curr_month_revenue-prev_month_revenue)/prev_month_revenue)*100,2)as mom_growth 
from prev_month 
order by mom_growth asc;

-- Find products that were sold in every month from January to June.
SELECT Product
FROM sales
WHERE date >= '2026-01-01' 
  AND date < '2026-07-01'
GROUP BY Product
HAVING COUNT(DISTINCT Month) = 6;


-- Classify products into High, Medium, and Low revenue using CASE.
with revenue_pro as(select product,sum(Total_price)as revenue from sales group by product)
select product,revenue,case 
when revenue >= 800000 then 'High'
when  revenue < 800000 and revenue >= 300000 then 'Medium'
else 'Low'
end as  Classify_products
from revenue_pro;

-- Find the top 3 products in each category using ROW_NUMBER() or DENSE_RANK().
with category_product_sales as (
select category,product,sum(Total_price)as total_revenue,
dense_rank()over(partition by category order by sum(Total_price) desc) as rnk 
from sales 
group by category,product 
order by total_revenue desc
)
select * from category_product_sales where rnk <= 3;

-- Identify cities contributing more than 10% of total revenue.
with contribution as (
select city,sum(Total_price)as Total_revenue, 
round((sum(Total_price)/(select sum(Total_price) from sales))*100,2) as percentage_contribution
from sales 
group by city
order by percentage_contribution desc)
select * from contribution where percentage_contribution > 10;
