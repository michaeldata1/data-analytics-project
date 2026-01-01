/*
 =================================
 Exploratory Data Analysis
 =================================
This script explores key objects in the database and 
calculates core business metrics to understand the 
scale, health, and structure of the sales dataset.

Included analytics:
• Schema discovery (tables, columns, dimensions)
• Data coverage checks (date ranges & customer ages)
• Key business measures (sales, orders, products, customers)
• Breakdown of results by country, gender, and category
• Top and bottom performers using ranking analysis

Used to establish foundational insights before building 
advanced analytical models and dashboards.
==========================================================
*/


-- DATABASE EXPLORATION

-- exploring objects in the database
select * from INFORMATION_SCHEMA.tables;


-- exploring columns in the database
select * from INFORMATION_SCHEMA.columns
where table_name = 'fact_sales';


-- exploring all the countries he customers come from
select distinct country from gold.dim_customers;


-- exploring all the categories of products
select distinct category, subcategory, product_name from gold.dim_products
order by 1,2,3;


-- finding the date of the first and last order
-- finding how many years of sales there are in the table
select min(order_date) first_order_date, 
max(order_date) last_order_date,
datediff(month,min(order_date) ,max(order_date) ) months_of_sales_data
from gold.fact_sales;


-- finding the youngest and the oldest customer
select min(birth_date) oldest_customer_birthdate,
datediff(year,min(birth_date), getdate() ) oldest_customer_age,
max(birth_date) youngest_customer_birthdate,
datediff(year,max(birth_date), getdate() ) youngest_cusomer_age
from gold.dim_customers;


-- MEASURES EXPLORATION

-- finding the total sales
select sum(sales_amount) as total_sales 
from gold.fact_sales;


-- finding how many items were sold
select sum(quantity) as total_items_sold
from gold.fact_sales;


-- finding averge selling price
select avg(price) as average_prie 
from gold.fact_sales;


-- finding the total number of orders
select count(distinct order_number)as total_orders
from gold.fact_sales;


-- finding total number of products
select count(distinct product_key) as total_products
from gold.dim_products;


-- finding the total number of customers
select count(customer_key) as total_customers 
from gold.dim_customers;


-- finding the total number of customers that has placed an order
select count(distinct customer_key) as total_customers 
from gold.fact_sales
where quantity >= 1;

-- generate a report that shows all key metrics of the business
select 'Total Sales' as measure_name, sum(sales_amount) as measure_value
from gold.fact_sales
union all 
select 'Total Quantity' as measure_name, sum(quantity) as total_items_sold
from gold.fact_sales
union all 
select 'Average Price', avg(price) as average_prie 
from gold.fact_sales
union all
select 'Total Number of Orders', count(distinct order_number)as total_orders
from gold.fact_sales
union all
select 'Total number of products', count(distinct product_key) as total_products
from gold.dim_products
union all
select 'Total number of customers', count(distinct customer_key) as total_customers 
from gold.dim_customers;


-- MAGNITUDE ANALYSIS
-- ∑(measure) by dimension

-- total sales by country
select country, sum(quantity) as total_quantity_sold
from gold.fact_sales as fs
left join gold.dim_customers as dc
on fs.customer_key = dc.customer_key
group by country
order by total_quantity_sold desc;

-- total customers by country
select country, count(customer_key) as total_customers
from gold.dim_customers
group by country
order by total_customers desc;

-- total customers by gender
select gender, count(customer_key) as total_customers
from gold.dim_customers 
group by gender
order by total_customers desc;

-- total products by category
select category, count(product_key) as total_products 
from gold.dim_products
group by category
order by total_products desc;

-- average cost of each ctegory
select category, avg(product_cost) as average_cost
from gold.dim_products
group by category
order by average_cost desc;

-- total revenue by category
select dp.category, sum(fs.sales_amount) as total_revenue
from gold.dim_products dp 
right join gold.fact_sales fs
on dp.product_key = fs.product_key
group by dp.category 
order by total_revenue desc;

-- what is the total revenue generated per customer
select dc.customer_key,
dc.first_name,
dc.last_name,
sum(fs.sales_amount) as total_revenue 
from gold.fact_sales fs
left join gold.dim_customers dc
on dc.customer_key = fs.customer_key 
group by 
dc.customer_key,
dc.first_name,
dc.last_name
order by total_revenue desc;


-- RANKIG ANALYSIS
-- rank(dimesion) by ∑(measure)

-- 5 highest performing products by revenue
select top 5 dp.product_name, sum(fs.sales_amount) as total_revenue
from gold.dim_products dp 
right join gold.fact_sales fs
on dp.product_key = fs.product_key
group by dp.product_name 
order by total_revenue desc;


-- same as above but with window functions
select * 
from (
	select dp.product_name, 
	sum(fs.sales_amount) as total_revenue,
	row_number() over (order by sum(fs.sales_amount) desc) as rank_products
	from gold.dim_products dp 
	right join gold.fact_sales fs
	on dp.product_key = fs.product_key
	group by dp.product_name) t
where rank_products <= 5;


-- 5 lowest performing products by revenue
select top 5 dp.product_name, sum(fs.sales_amount) as total_revenue
from gold.dim_products dp 
right join gold.fact_sales fs
on dp.product_key = fs.product_key
group by dp.product_name 
order by total_revenue asc;

-- 10 customers who have generated the highest revenue 
select top 10 dc.customer_key,
dc.first_name,
dc.last_name,
sum(fs.sales_amount) as total_revenue 
from gold.fact_sales fs
left join gold.dim_customers dc
on dc.customer_key = fs.customer_key 
group by 
dc.customer_key,
dc.first_name,
dc.last_name
order by total_revenue desc;

-- 3 customers with fewest sales
select top 3 dc.customer_key,
dc.first_name,
dc.last_name,
count(distinct fs.order_number) as total_orders
from gold.fact_sales fs
left join gold.dim_customers dc
on dc.customer_key = fs.customer_key 
group by 
dc.customer_key,
dc.first_name,
dc.last_name
order by total_orders asc;
