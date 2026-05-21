-- =============================================
-- PROJECT: BikeStores Retail Analytics
-- AUTHOR: Obinna Mark Neboh
-- DATE: May 2026
-- TOOL: SQL Server Management Studio (SSMS)
-- DESCRIPTION: Data audit and cleaning queries
-- =============================================

-- =====================
--DATA CLEANING
-- =====================

--row count on each table to confirm the data is in

SELECT 'orders' as Tbl, count (*) as rows from orders
union all select 'customers', count (*) as rows from customers
union all select 'products' , count (*) as rows from products
union all select 'brands' , count (*) as rows from brands
union all select 'categories', count (*) as rows from categories
union all select 'stocks' , count (*) as rows from stocks
union all select 'staffs' , count(*) as rows from staffs
union all select 'order_items', count (*) as rows from order_items
union all select 'stores', count (*) as rows from stores


--check for duplicates inall the 9 tables
--1. check number of occurence
--RESULT: NO DUPLICATE FOUND in order

Select *,
Row_Number() over( 
partition by order_id, Customer_id, order_status, order_date, required_date, shipped_date, staff_id, store_id
order by order_id)
as row_number
from orders;

with duplicate_cte as
(
Select *,
Row_Number() over( 
partition by order_id, Customer_id, order_status, order_date, required_date, shipped_date, staff_id, store_id
order by order_id)
as row_number
from orders
)
select *
from duplicate_cte
where row_number > 1;


--2. Fixing datatypes

--checing column data type
select table_name, column_name, data_type
from information_schema.columns
where column_name='order_id'
and table_name in ('orders','order_items');

--
alter table orders
drop constraint pk_orders;

alter table orders
alter column order_id int not null;

alter table orders
add constraint pk_orders primary Key(order_id);


--3. check for null values
select * from orders;
select * from orders
where shipped_date is Null;


--counting the number of rows with null values
select 'orders' as orders,
count (*) as Count
from orders
where shipped_date is Null;

--4. How many rows in each table contain NULL values, and in which columns?

Select * 
from orders
Where order_id is null
or Customer_id is null
or order_status is null 
or order_date is null
or required_date is null
or shipped_date is null
or staff_id is null
or store_id is null;

--5. Are there any orders with a shipped_date earlier than order_date? How many?
SELECT *
FROm orders
Where shipped_date < order_date;

--6. Which customers have never placed any order? Are they ghost records?
select *
from customers
left join orders on customers.customer_id=orders.customer_id
where orders.customer_id is null;


--7.Show me all products that exist in the products table but have never appeared in a single order."
select *
from products
left join order_items on products.product_id=order_items.Product_id
where order_items.Product_id is null;

--8. Are there products in order_items that do not exist in the products table (orphaned references)?
select *
from order_items
left join products on order_items.product_id=products.product_id
where products.product_id is null;

--9.Which staff members are marked inactive (active = 0) but still appear as the assigned staff on orders?
select * from staffs;

select * 
from orders
left join staffs on orders.staff_id=staffs.staff_id
where staffs.active=0;

--10. Are there products in order_items where the recorded list_price differs from the current products.list_price by more than 20%?

Select * from products;
select * from order_items;

select * 
from order_items 
left join products on order_items.product_id=products.product_id
where order_items.list_price>=products.list_price+((products.list_price*20)/100)
or order_items.list_price<=products.list_price-((products.list_price*20)/100);