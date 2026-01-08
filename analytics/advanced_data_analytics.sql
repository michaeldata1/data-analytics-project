/*
============================
Advanced Data Analytics
============================
This script analyzes retail sales performance over time 
using aggregated KPI metrics, customer segmentation, 
and product performance reporting.

Key highlights:
• Monthly revenue trends, customer counts, and quantities sold
• Running totals and moving average analytics
• Year-over-year product performance benchmarking
• Category contribution to total company sales
• Product segmentation by cost ranges
• Customer segmentation (VIP, Regular, New)

Designed to support business reporting and dashboards
for revenue growth monitoring and strategic decision-making.
==========================================================
*/


-- CHANGE OVER TIME TRENDS

-- sales performance over time
select year(order_date) as order_year,
month(order_date) as order_month,
sum(sales_amount) as total_sales,
count(distinct customer_key) as total_customers,
sum(quantity) as total_quantity_sold
from gold.fact_sales
where order_date is not null
group by year(order_date), month(order_date) 
order by year(order_date), month(order_date);


-- CUMULATIVE ANALYSIS 

-- sales per month
-- and running total of sales over time
select order_date,
total_sales,
-- window function
sum(total_sales) over (order by order_date) as running_total_sales
from(
select datetrunc(month,order_date) as order_date,
sum(sales_amount) as total_sales
from gold.fact_sales
where order_date is not null
group by datetrunc(month,order_date)) t;

-- same but we partition by order year 
-- so that every year the running total resets 
select order_date,
total_sales,
-- window function
sum(total_sales) over (partition by order_date order by order_date) as running_total_sales
from(
select datetrunc(month,order_date) as order_date,
sum(sales_amount) as total_sales
from gold.fact_sales
where order_date is not null
group by datetrunc(month,order_date)) t;

-- moving average of sales over time
select order_date,
total_sales,
-- window function
avg(total_sales) over (order by order_date) as moving_average_sales
from(
select datetrunc(month,order_date) as order_date,
avg(sales_amount) as total_sales
from gold.fact_sales
where order_date is not null
group by datetrunc(month,order_date)) t;


-- PERFORMANCE ANALYSIS
-- current measure - target measure

/* yearly performance of products by comparing their sales
to both the average sales performance and to last year's sales
*/
with yearly_product_sales as (
select 
year(fs.order_date) order_year,
dp.product_name,
sum(fs.sales_amount) as current_sales
from gold.fact_sales fs
left join gold.dim_products dp
on fs.product_key = dp.product_key
where order_date is not null
group by year(fs.order_date),
dp.product_name)
select
order_year,
product_name,
current_sales,
avg(current_sales) over (partition by product_name) avg_sales,
current_sales - avg(current_sales) over (partition by product_name) as diff_avg,
case when current_sales - avg(current_sales) over (partition by product_name) > 0 then 'above average'
	 when current_sales - avg(current_sales) over (partition by product_name) < 0 then 'below average'
	 else 'Average' 
end as average_change,
-- Y-O-Y analysis
lag(current_sales) over(partition by product_name order by order_year) as last_year_sales,
current_sales - lag(current_sales) over(partition by product_name order by order_year) as diff_previous_year,
case when current_sales - lag(current_sales) over(partition by product_name order by order_year) > 0 then 'above previous year'
	 when current_sales - lag(current_sales) over(partition by product_name order by order_year) < 0 then 'below previous year'
	 else 'no change' 
end as previous_year_change
from yearly_product_sales
order by product_name, order_year;


-- PART TO WHOLE ANALYSIS
-- (measure / total(measure))*100 by dimension

-- which categories contribute the most to the overall sales
select 
category,
sum(sales_amount) total_sales,
sum(sum(sales_amount)) over() overall_sales,
round((cast(sum(sales_amount) as float )/ sum(sum(sales_amount)) over())*100, 2) as percentage_of_sales
from gold.fact_sales fs
left join gold.dim_products dp
on fs.product_key = dp.product_key
group by category;


-- DATA SEGMENTATION
-- measure by measure

/*segment products into cost ranges and
cound how many products fall into each segment
*/
with product_segments as (
select 
product_key,
product_name,
product_cost,
case when product_cost < 100 then 'Below 100'
	 when product_cost between 100 and 500 then '100-500'
	 when product_cost between 500 and 1000 then '500-1000'
	 else 'over 1000' 
end as cost_range
from gold.dim_products)
select cost_range,
count(product_key) as total_products
from product_segments
group by cost_range
order by total_products desc;


/* Group customers into 3 segments based on spending behaviour:
VIP: customers with at least 12 months of history and spending over 5,000
Regular: customers with at least 12 months of history and spending 5,000 or less
New: customers with less than 12 months of history
and find the total number of customers per group
*/
with customer_spending as (
select
dc.customer_key,
sum(fs.sales_amount) as total_spending,
min(order_date) as first_order,
max(order_date) as last_order,
datediff(month,min(order_date), max(order_date)) as order_range
from gold.fact_sales fs
left join gold.dim_customers dc
on fs.customer_key = dc.customer_key
group by dc.customer_key)
select 
customer_category,
count(customer_key) total_customers
from(
select 
customer_key,
case when total_spending > 5000 and order_range >= 12 then 'VIP'
	 when total_spending <= 5000 and order_range >= 12 then 'Regular'
	 else 'New'
end customer_category
from customer_spending) t
group by customer_category
order by total_customers desc
;

