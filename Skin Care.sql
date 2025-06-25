/** Creating the Skin Care table **/
create table skin_care (
row_id int primary key, order_id varchar, order_date date, customer_id varchar, segment varchar,
city varchar, state varchar, country varchar, country_latitude double precision, country_longitude double precision,
region varchar, market varchar, subcategory varchar, category varchar, product varchar, quantity int, sales int, discount decimal,
profit numeric
)
/** Importing the Skin Care table **/
copy skin_care 
from 'C:\Program Files\PostgreSQL\Skin_Care Target.csv'
delimiter ','
csv header

/** Creating a date table for time based analysis **/
create table date_table (
date_id serial primary key, date_value date, year int, quarter int, month_number int, month varchar,
weekday int, weekday_name varchar
)

/** Inserting values into the date table **/
insert into date_table (date_value, year, quarter, month_number, month, weekday, weekday_name)
select
gs:: date as date_value,
extract (year from gs):: int as year,
extract (quarter from gs):: int as quarter,
extract (month from gs):: int as month_number,
to_char (gs, 'month') as month,
extract (week from gs):: int as weekday,
to_char (gs, 'Day') as weekday_name
from generate_series('2022-01-01'::date, '2022-12-31'::date, '1 day'::interval) as gs;

/** KPIs **/
/** Revenue, Total Profit, Total Orders, Total quantity bought**/
select sum(sales) as Revenue,
sum(profit) as Total_profit,
count(row_id) as Total_orders,
sum (quantity) as Total_qnty
from skin_care

/** Average Profit Margin **/
select
cast(sum(profit)/sum(sales) * 100 as decimal(10,2)) as avg_profit_margin,
from skin_care

/** Average Order Quantity **/
select cast(avg(order_qnty) as decimal(10,2)) as avg_order_qnty
from (
	select order_id,
	sum(quantity) as order_qnty
	from skin_care
	group by order_id
) as result

/** Average Sales per Order **/
select cast(avg(total_sales) as decimal(10,2)) as avg_sales_per_order	
from (
	select order_id,
	sum(sales) as total_sales
	from skin_care
	group by order_id
) as result

/** Q&A **/
/**  Top 10 Products by Revenue **/
select product,
sum(sales) as Revenue
from skin_care
group by product
order by revenue desc
limit 10

/** Top 5 Products by Revenue per category **/
with ranked_products as (
	select category, subcategory, product,
		sum(sales) as Revenue,
		row_number() over(
		partition by category
		order by sum(sales) desc
	) as rank
	from skin_care
	group by category, subcategory, product
)
select category, subcategory, product, Revenue
from ranked_products
where rank <= 5
order by category, subcategory, Revenue desc

/** Average Profit Margin for each Product Subcategory **/
select subcategory,
sum(sales) as revenue,
sum(profit) as total_profit,
cast(sum(profit)/sum(sales) * 100 as decimal(10,2)) as avg_profit_margin
from skin_care
group by subcategory
order by avg_profit_margin desc

/** Which Country & City Contributed the Most to Total Sales **/
/** City **/
select city, 
sum(sales) as revenue,
sum(profit) as total_profit,
rank() over(order by sum(sales) desc) as sales_rank,
rank() over(order by sum(profit) desc) as profit_rank
from skin_care
group by city
order by profit_rank

/** Country **/
select country,
sum(sales) as revenue,
sum(profit) as total_profit,
rank() over (order by sum(sales) desc) as revenue_rank,
rank() over (order by sum(profit) desc) as profit_rank
from skin_care
group by country
order by profit_rank 

/** Customer Segment generating the most profit **/
select segment,
sum(profit) as total_profit
from skin_care
group by segment
order by sum(profit)desc

/** Sales Trend over Time (Weekday) **/
select
b.weekday_name, sum(a.sales) as revenue, sum(a.profit) as total_profit
from skin_care as a
join date_table as b
on a.order_date = b.date_value
group by b.weekday_name
order by revenue desc

/** Region with the Highest Average Order Quantity **/
select region, 
cast(avg(quantity) as decimal(10,2)) as avg_order_quantity
from skin_care
group by region
order by avg(quantity) desc
limit 5

/** Product Categories Selling the Most Units over Time **/
select a.category, sum(a.quantity) as total_units_sold, b.year, b.month
from skin_care as a
join date_table as b
on a.order_date = b.date_value
group by a.category, b.year, b.month
order by sum(a.quantity)

/** Top Selling Products per Month **/
with ranked_sales as(
	select a.category, sum(a.quantity) as units_sold, a.subcategory, b.month,
	row_number() over(
		partition by a.category, a.subcategory, b.month
		order by sum(a.quantity) desc
	) as rank
	from skin_care as a
	join date_table as b
	on a.order_date = b.date_value
	group by a.category, b.month, a.subcategory
)
select category, month, subcategory, units_sold 
from ranked_sales
where rank = 1
order by month

/** Average Sales Per Order across Different Countries **/
select country, round(avg(sales),2) as avg_sales
from skin_care
group by country
order by avg(sales) desc
limit 5

/** What Cities Recorded the Highest Number of Transactions **/
Select city, count(distinct order_id)as num_of_trans
from skin_care
group by city
order by count(row_id) desc
limit 10

/** Which market makes the most profit **/
select market, sum(profit) as total_profit
from skin_care
group by market
order by total_profit desc



