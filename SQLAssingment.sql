-->A1.DATA UNDERSTANDING

-->1.Listed all the tables 
-->No of rows in each table 
----------------------------------------------------------------------
select count(*) as total_rows_customers from customers;
select COUNT(*) as total_rows_order_items from order_items;
select COUNT(*) as total_rows_order_payments from order_payments;
select COUNT(*) as total_rows_orders from orders;
select COUNT(*) as total_rows_products from products;


--> No of colums
------------------------------------------------------------------------
select table_schema,table_name,COUNT(*) as column_count
from INFORMATION_SCHEMA.COLUMNS
group by table_name,table_schema
order by table_name,table_schema;

--> 5 Sample rows 
--------------------------------------------------------------------------
select top 5 * from customers;
select top 5 * from order_items;
select top 5 * from order_payments;
select top 5 * from orders;
select top 5 * from products;
--> 2. Identying key relations BW tables

/*
--> How orders Joins to customers
	
	with the help of customer_id in both tables
	==> syntax:- join customers as cu on cu.customer_id = o.customer_id

--> How orders Joins to order_items

	with the help of order_id in both tables
	==> syntax:- join orders as o on oi.order_id = o.order_id

--> How order_items joins to products
	
	with the help of product_id in both tables
	==> syntax:- join products as p on oi.product_id = p.product_id

--> How orders joins to order_payments
	
	with the help of order_id in both tables
	==> syntax:- join order_payments as op on o.order_id = op.order_id
	
 */
--> A2. Building an analysis redy table
---------------------------------------------------------------------------------------
select 
	oi.order_id,
	o.order_purchase_timestamp,
	CONVERT(DATE,o.order_purchase_timestamp) as order_purchase_date,
	cu.customer_id,
	cu.customer_state,
	p.product_id,
	coalesce(p.product_category_name,'unknown') as product_category_name, 
	oi.price,
	oi.freight_value,
	op.payment_type,
	op.payment_value,
	o.order_status
	INTO orders_enriched
	from order_items as oi
join orders as o on oi.order_id = o.order_id
join customers as cu on cu.customer_id = o.customer_id
join products as p on oi.product_id = p.product_id
join order_payments as op on o.order_id = op.order_id

where o.order_status not in ('canceled', 'unavailable');

--> A3. Basic KPIs
--> 1.Overall KPIs
--> Total no of orders
-------------------------------------------------------------------------------
select COUNT(distinct order_id) from orders_enriched;

--> Total revenue
---------------------------------------------------------------------------------
select SUM(payment_value) as total_revenue from orders_enriched;

--> Average order value
------------------------------------------------------------------------------------
SELECT SUM(payment_value)/COUNT(DISTINCT order_id) AS AOV FROM orders_enriched;

--> Date range
------------------------------------------------------------------------------------
SELECT 
	MIN(order_purchase_date) AS DATE_RANGE_MIN,
	MAX(order_purchase_date) AS DATE_RANGE_MAX
FROM orders_enriched;

-->2.Yearly summary
-->Create a table with one row per year showing:
--------------------------------------------------------------------------------------
SELECT 
	YEAR(order_purchase_date) AS YYYY,
	COUNT(DISTINCT order_id) as TOTAL_ORDERS,
	SUM(payment_value) AS TOTAL_REVENUE,
	SUM(payment_value)/
	COUNT(DISTINCT order_id) as TOTAL_AVG_ORDERS
	INTO YEAR_SUMMARY
FROM orders_enriched
GROUP BY YEAR(order_purchase_date);


-->A4. SALES TREND OVER A TIME
--> To created monthly sales table
----------------------------------------------------------------------------------------
SELECT
    FORMAT(order_purchase_date, 'yyyy-MM') AS YEAR_MONTH,
    COUNT(DISTINCT order_id) AS TOTAL_ORDERS,
    SUM(payment_value) AS TOTAL_REVENUE,
    SUM(payment_value) / COUNT(DISTINCT order_id) AS AOV
    INTO monthly_sales
FROM orders_enriched
GROUP BY FORMAT(order_purchase_date, 'yyyy-MM')
ORDER BY year_month;

--> A5. PRODUCT CATEGORY PERFORMANCE
--> To create category_performane table
-------------------------------------------------------------------------------------------
select 
	product_category_name,
	COUNT(distinct order_id) AS total_orders,
	COUNT(*) as total_items,
	SUM(payment_value) as total_revenue,
	AVG(price) as avg_price
	into category_performane
from orders_enriched
group by product_category_name;

-->Sorting by total_revenue and keeping the top 10 rows
----------------------------------------------------------------------------------------------
select 
	top 10
	product_category_name,
	COUNT(distinct order_id) AS total_orders,
	COUNT(*) as total_items,
	SUM(payment_value) as total_revenue,
	AVG(price) as avg_price
from orders_enriched
group by product_category_name
order by SUM(payment_value) desc;

--> A6. Creating table state_performane
--------------------------------------------------------------------------------------

select 
	customer_state,
	COUNT(distinct customer_id) as unique_customers,
	COUNT(distinct order_id) AS total_orders,
	SUM(payment_value) as total_revenue,
	SUM(payment_value)/
	COUNT(DISTINCT order_id) as avg_order_value
	into state_performance
from orders_enriched
group by customer_state
order by SUM(payment_value) desc;

-->A7. Delivery performance
-->Creating colums
-----------------------------------------------------------------------------------------

select 
	Datediff(day,convert(date,order_purchase_timestamp),
	convert(date,order_delivered_customer_date)) as delevery_time_days,
	datediff(day,CONVERT(date,order_purchase_timestamp),
	CONVERT(date,order_estimated_delivery_date)) as estimated_delivery_days
from orders;

-->creating table delivery summary by state
--------------------------------------------------------------------------------------------

select 
	cu.customer_state,
	Datediff(day,convert(date,o.order_purchase_timestamp),
	convert(date,o.order_delivered_customer_date)) as delevery_time_days,
	datediff(day,CONVERT(date,o.order_purchase_timestamp),
	CONVERT(date,o.order_estimated_delivery_date)) as estimated_delivery_days
	into delivery_summary_by_state
from orders as o 
join customers as cu on o.customer_id = cu.customer_id;

-->A8. Output of Part A
------------------------------------------------------------------------------------------------
select * from orders_enriched;
select* from monthly_sales;
select * from category_performane;
select * from state_performance;
select * from delivery_summary_by_state;






