-- =============================================
-- PROJECT: BikeStores Retail Analytics
-- AUTHOR: Obinna Mark Neboh
-- DATE: May 2026
-- TOOL: SQL Server Management Studio (SSMS)
-- DESCRIPTION: Data audit and cleaning queries
-- =============================================

-- =====================
-- CHAPTER : KEY PERFORMANCE INDEX
-- =====================

--Total Revenue
Select Sum(order_items.list_price*(1-order_items.discount)*order_items.quantity) as Revenue
from order_items;

--Total orders
Select * from Orders;
Select Count(distinct order_id) as ORder_count
from orders;

--Total customers
 Select Count(distinct Customer_id) as Customer_count
from Customers;

--%of repeat customers
select 
(Select count(*) as repeat_buyers
from(
select distinct Customers.customer_id, Concat(customers.First_name,' ',Customers.last_name) as Customer_name,
count(orders.order_id) as repeat_orders
from orders
inner join customers on orders.customer_id=customers.customer_id
group by Customers.customer_id, Concat(customers.First_name,' ',Customers.last_name)
having count(orders.order_id) >= 2 
--order by repeat_orders desc
) as sub) * 100.0
/ Count(distinct Customer_id)as Pecentage_of_repeat_customers
from
customers;


-- =====================
-- CHAPTER : SALES PERFORMANCE
-- =====================
--1. What is the total revenue per year (2016, 2017, 2018)?
Select Year(orders.order_date) AS YEARs, Sum(order_items.list_price*(1-order_items.discount)*order_items.quantity) as Revenue
from orders
inner join order_items On orders.order_id=order_items.Order_id
group by Year(orders.order_date)
order by YEARs Asc;

--2. Which store generated the highest total revenue across all years?
--orders, products and stores

Select top 1 Stores.store_name,
Sum(order_items.list_price*(1-order_items.discount)*order_items.quantity) as Revenue
from orders
inner join order_items on orders.order_id= order_items.order_id
inner join stores on orders.store_id=stores.store_id
group by Stores.store_name
order by Revenue desc;



--3. What are the top 5 best-selling products by revenue?

Select top 5 Products.Product_name,
Sum(order_items.list_price*(1-order_items.discount)*order_items.quantity) as Revenue
from order_items
inner join products on order_items.product_id=products.Product_id
Group by Products.Product_name
order by Revenue desc;


--4. Which product category drives the most revenue? Which is the least profitable?
select * from categories;

with highest_cte as
(
Select Top 1 Categories.category_NAME ,
Sum(order_items.list_price*(1-order_items.discount)*order_items.quantity) as Revenue
from order_items
inner join products on order_items.product_id=products.Product_id
inner join categories on products.category_id=categories.Category_id
Group by  Categories.category_NAME
order by Revenue desc
),
lowest_cte as
(
Select Top 1 Categories.category_NAME,
Sum(order_items.list_price*(1-order_items.discount)*order_items.quantity) as Revenue
from order_items
inner join products on order_items.product_id=products.Product_id
inner join categories on products.category_id=categories.Category_id
group by Categories.category_NAME
order by Revenue asc
)
Select *, 'highest_Revenue' as Category_rank
From Highest_cte

union all
Select *, 'lowest_Revenue' as Category_rank from lowest_cte a;



--5. Which month consistently generates the highest sales across all years?
select * from Orders;
select * from order_items;


Select Top 1 datename(Month, Orders.Order_date)  as Best_Month,
sum(order_items.list_price*(1-order_items.discount)*Order_items.quantity) as revenue
from order_items
inner join orders on Order_items.order_id=orders.Order_id
group by datename(Month, Orders.Order_date)
order by revenue desc;


--6. What percentage of orders were completed vs rejected vs still pending?

select 
Case order_status
when 1 then 'Pending'
when 2 then 'Processing'
when 3 then 'Rejected'
when 4 then 'Completed'
end as status_label, Orders.Order_status,
Count(order_Status)*100/(select Count(*) from Orders) As percentage
from orders
Group By Orders.Order_status
order by percentage desc;

--7. Calculate month-over-month revenue growth rate for each store.
with Monthy_revenue as
(
Select Store_name, datename(Month, Orders.Order_date)  as Months, 
datepart(Month, Orders.Order_date) as Month_num,
Sum(order_items.list_price*(1-order_items.discount)*order_items.quantity) as Revenue
from order_items
inner join orders on Order_items.order_id=orders.Order_id
inner join stores on orders.store_id=stores.store_id
group by store_name, datepart(Month, Orders.Order_date), datename(Month, Orders.Order_date),
datepart(Month, Orders.Order_date)
)
select store_Name, Months, Month_num,
(Revenue-lag(Revenue) over (partition by store_name order by datepart(Month, Month_num)))
/
lag(Revenue) over (partition by store_name order by datepart(Month, Month_num)) *100 as MoM
from Monthy_revenue
;

-- =====================
--CHAPTER: STAFF PERFORMANCE
-- =====================

--1. Who are the top 3 staff members by total revenue generated?

SELECT top 3 Staffs.Staff_id, Concat(staffs.First_name,' ',Staffs.last_name) as Staff_Name,
Sum(order_items.list_price*(1-order_items.discount)*order_items.quantity) as Revenue
from order_items
inner join orders on order_items.order_id=orders.order_id
inner join staffs on orders.staff_id= staffs.staff_id
Group by staffs.staff_id,Concat(staffs.First_name,' ',Staffs.last_name)
order by Revenue desc;


--2. Which staff member handles the most orders? Is it the same as the one generating most revenue?

with Most_revenue as
(
Select top 1 Staffs.Staff_id, Concat(staffs.First_name,' ',Staffs.last_name) as Staff_Name,
Sum(order_items.list_price*(1-order_items.discount)*order_items.quantity) as Value_Num
from order_items
inner join orders on order_items.order_id=orders.order_id
inner join staffs on orders.staff_id= staffs.staff_id
Group by staffs.staff_id,Concat(staffs.First_name,' ',Staffs.last_name)
order by Value_Num desc
),
Most_orders as
(
Select top 1 Staffs.Staff_id, Concat(staffs.First_name,' ',Staffs.last_name) as Staff_Name,
count(order_items.order_id) as Value_Num
from order_items
inner join orders on order_items.order_id=orders.order_id
inner join staffs on orders.staff_id= staffs.staff_id
Group by staffs.staff_id,Concat(staffs.First_name,' ',Staffs.last_name)
order by Value_Num desc
)
Select * ,'Most Revenue' as Ranks
from Most_Revenue
union all
Select *, 'Most Orders' as ranks
from most_orders;


--3. Rank all staff by total sales using a window function.
SELECT Staffs.Staff_id, Concat(staffs.First_name,' ',Staffs.last_name) as Staff_Name,
Sum(order_items.list_price*(1-order_items.discount)*order_items.quantity) as Revenue,
Row_Number() over(order by Sum(order_items.list_price*(1-order_items.discount)*order_items.quantity) desc) As Staff_rank
from order_items
inner join orders on order_items.order_id=orders.order_id
inner join staffs on orders.staff_id= staffs.staff_id
Group by staffs.staff_id,Concat(staffs.First_name,' ',Staffs.last_name);
--order by Revenue desc;


--4. Which staff has the highest number of repeat customers?

with repeat_customer as
(
select customer_id
from orders
group by customer_id
having count(customer_id) >=2
)
Select top 1 staffs.Staff_id, Concat(staffs.First_name,' ',Staffs.last_name) as Staff_Name,
count(*)  as total_repeat_customer
from orders
inner join staffs on orders.staff_id=staffs.staff_id
where customer_id in (Select customer_id from repeat_customer)
group by staffs.Staff_id, Concat(staffs.First_name,' ',Staffs.last_name);


--5. Compare each staff member's revenue against the store average for their store.

with Staff_revenue as
(
Select Staffs.Staff_id, Concat(staffs.First_name,' ',Staffs.last_name) as Staff_Name,orders.store_id,
Sum(order_items.list_price*(1-order_items.discount)*order_items.quantity) as Revenue
from order_items
inner join orders on order_items.order_id=orders.order_id
inner join staffs on orders.staff_id=staffs.staff_id
group by  Staffs.Staff_id, Concat(staffs.First_name,' ',Staffs.last_name),orders.store_id
),
store_avg as
(
Select store_id,
avg(Revenue) As store_average
from Staff_revenue
group by store_id
)
Select *
from staff_revenue
left join store_avg on staff_revenue.Store_id=store_avg.store_id;


-- =====================
 -- CHAPTER : Customer Behaviour
 -- =====================

 
 --1.0 Which state has the most customers? Which has the most revenue?

 with most_customers as
 (
 Select top 1 customers.state,
 count(customer_id) as state_count
 from customers
 group by Customers.state
 order by count(customer_id) desc
 ),
 most_revenue as
 (
 Select top 1 customers.state,
 Sum(order_items.list_price*(1-order_items.discount)*order_items.quantity) as Revenue
 from order_items
 inner join orders on order_items.order_id=orders.order_id
 inner join customers on orders.customer_id=customers.customer_id
 group by customers.state
 order by Sum(order_items.list_price*(1-order_items.discount)*order_items.quantity) desc
 )
 select *, 'Most_customers' as Ranks
 from most_customers
 union all
 select *, 'most_revenue' as Ranks
 from most_revenue ;


 --2. Who are the top 10 customers by lifetime spending?
Select top 10 Customers.Customer_id, Concat(customers.First_name,' ',Customers.last_name) as Customer_name,
Sum(order_items.list_price*(1-order_items.discount)*order_items.quantity) lifetime_spending
from order_items
inner join orders on order_items.order_id=orders.order_id
inner join customers on orders.customer_id=customers.customer_id
group by Customers.Customer_id,Concat(customers.First_name,' ',Customers.last_name) 
order by lifetime_spending desc;


--3. What is the average order value per customer?
Select Distinct Customers.customer_id, Concat(customers.First_name,' ',Customers.last_name) as Customer_name,
Sum(order_items.list_price*(1-order_items.discount)*order_items.quantity)/count(Distinct orders.order_id) as Aov_per_customer
from order_items
inner join orders on order_items.order_id=orders.order_id
inner join customers on orders.customer_id=customers.customer_id
group by Customers.customer_id, Concat(customers.First_name,' ',Customers.last_name)
order by Aov_per_customer desc;


--4. How many customers placed more than one order (repeat buyers)?
Select count(*) as repeat_buyers
from(
select distinct Customers.customer_id, Concat(customers.First_name,' ',Customers.last_name) as Customer_name,
count(orders.order_id) as repeat_orders
from orders
inner join customers on orders.customer_id=customers.customer_id
group by Customers.customer_id, Concat(customers.First_name,' ',Customers.last_name)
having count(orders.order_id) >= 2 
--order by repeat_orders desc
) as sub


--5. What is the average number of days between a customer's first and second order?

with row_numbering as
(
Select Distinct Customers.customer_id, Concat(customers.First_name,' ',Customers.last_name) as Customer_name, orders.order_date,
row_number() over(partition by orders.customer_id order by orders.order_date) as customers_date
from orders
inner join customers on orders.customer_id=customers.customer_id

)
Select Avg(diff_days) as avg_date
from (
select *,
datediff(day,lag(order_date) over(partition by customer_id order by order_date), order_date) as diff_days
from row_numbering
where customers_date <=2
) as sub
where customers_date =2;


-- =====================
-- CHAPTER: Inventory & Stock
-- =====================
--1. Which products have zero stock across all stores?

Select products.product_id, Products.product_name, stocks.quantity
from products
inner join stocks on products.product_id=stocks.product_id
inner join stores on stocks.store_id=stores.store_id
where stocks.quantity <1
group by products.product_id, Products.product_name, stocks.quantity
;

--2.Which store has the highest total stock value (quantity × list_price)?
select top 1 stores.store_id, stores.store_name, 
sum(stocks.quantity * products.list_price) as total_stock_value
from products
inner join stocks on products.product_id=stocks.product_id
inner join stores on stocks.store_id=stores.store_id
group by stores.store_id, stores.store_name
order by total_stock_value desc;


--3. Are there products that were sold but never appeared in the stocks table? 
select order_items.product_id, products.product_name, order_items.quantity
from order_items
inner join products on order_items.product_id=products.product_id
left join stocks on stocks.product_id=order_items.product_id
where stocks.product_id is NULL
group by  order_items.product_id, products.product_name, order_items.quantity;
