/*
===================================================
CUSTOMER REPORT
===================================================
Purpose: 
This report will consolidate key customer metrics and behaviours
*/
create view gold.report_customers as
with base_query as (
-- base query: retrieves core columns from tables
select 
fs.order_number,
fs.product_key,
fs.sales_amount,
fs.order_date,
fs.quantity,
dc.customer_key,
dc.customer_number,
concat(dc.first_name, ' ',dc.last_name) as customer_name,
datediff(year, dc.birth_date, getdate()) as age
from gold.fact_sales fs
left join gold.dim_customers dc
on fs.customer_key = dc.customer_key
where order_date is not null)

, customer_aggregation as (
-- customer aggregations: summarizes key metrics at the customer level
select 
customer_key,
customer_number,
customer_name,
age,
count(distinct order_number) as total_orders,
sum(sales_amount) as total_sales,
sum(quantity) as total_quantity_sold,
count(distinct product_key) as total_products,
max(order_date) as last_order_date,
datediff(month,min(order_date), max(order_date)) as order_range
from base_query
group by 
customer_key,
customer_number,
customer_name,
age)

select 
customer_key,
customer_number,
customer_name,
age,
case when age < 20 then 'under 20'
	 when age between 20 and 29 then '20-29'
	 when age between 30 and 39 then '30-39'
	 when age between 40 and 49 then '40-49'
	 when age between 50 and 59 then '50-59'
	 when age between 60 and 69 then '60-69'
	 when age between 70 and 79 then '70-79'
	 when age between 80 and 89 then '80-89'
	 when age between 90 and 99 then '90-99'
	 else '100+'
end as age_bracket,
case when total_sales > 5000 and order_range >= 12 then 'VIP'
	 when total_sales <= 5000 and order_range >= 12 then 'Regular'
	 else 'New'
end customer_category,
datediff(month, last_order_date, getdate()) as recency,
total_orders,
total_sales,
total_quantity_sold,
total_products,
last_order_date,
order_range,
-- compute average order value (AVO)
case when total_orders = 0 then 0
	 else total_sales/total_orders 
	 end as avg_order_value,
-- compute average monthly spend
case when order_range = 0 then total_sales
	 else total_sales/order_range 
end as avg_monthly_spend
from customer_aggregation;
