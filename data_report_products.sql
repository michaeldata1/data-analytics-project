/*
=============================
PRODUCT REPORT
=============================
Purpose: 
This report will consolidate key product metrics to be used for business intelligence
*/

create view gold.report_product as 
with base_query as (
select
fs.order_number,
fs.order_date,
fs.customer_key,
fs.sales_amount,
fs.quantity,
dp.product_key,
dp.product_name,
dp.category,
dp.subcategory,
dp.product_cost
from gold.fact_sales fs
left join gold.dim_products dp
on fs.product_key = dp.product_key
where order_date is not null)
,product_aggregations as (
select 
product_key,
product_name,
category,
subcategory,
product_cost,
datediff(month, min(order_date), max(order_date)) as product_lifespan,
max(order_date) as last_sale_date,
count(distinct order_number) as total_orders,
count(distinct customer_key) as total_customers,
sum(sales_amount) as total_sales,
sum(quantity) as total_quantity_sold,
round(avg(cast(sales_amount as float)/nullif(quantity, 0)),1) as avg_selling_price
from base_query
group by product_key,
product_name,
category,
subcategory,
product_cost)
select 
product_key,
product_name,
category,
subcategory,
product_cost,
last_sale_date,
datediff(month, last_sale_date, getdate()) as recency_in_months,
case when total_sales > 5000 then 'high performing'
	 when total_sales between 1000 and 5000 then 'mid-range'
	 else 'low performing'
end as product_performance,
product_lifespan,
total_orders,
total_sales,
total_quantity_sold,
total_customers,
avg_selling_price,
case when total_orders = 0 then 0
	 else total_sales / total_orders
end as avg_order_revenue,
case when product_lifespan = 0 then total_sales
	 else total_sales / product_lifespan
end as avg_monthly_revenue
from product_aggregations;

