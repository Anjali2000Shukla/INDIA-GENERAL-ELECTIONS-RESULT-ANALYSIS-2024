-- Monday Coffee -- Data Analysis 

select * from city;
select * from customers;
select * from products;
select * from sales;


-- Reports & Data Analysis


-- Q.1 Coffee Consumers Count
-- How many people in each city are estimated to consume coffee, given that 25% of the population does?
select city_name,
(population * 0.25)/100000,
city_rank
from city
order by 2 desc;


-- -- Q.2
-- Total Revenue from Coffee Sales
-- What is the total revenue generated from coffee sales across all cities in the last quarter of 2023?

SELECT SUM(total) AS Total_Revenue
FROM sales
WHERE EXTRACT(YEAR FROM sale_date) = 2023
  AND EXTRACT(QUARTER FROM sale_date) = 4;
  
select city_name,
sum(s.total) as Total_Revenue
from sales as s
join customers as c
on s.customer_id = c.customer_id
join city as ci
on ci.city_id = c.city_id
where 
EXTRACT(YEAR FROM sale_date) = 2023
AND EXTRACT(QUARTER FROM sale_date) = 4
group by ci.city_name;

-- Q.3
-- Sales Count for Each Product
-- How many units of each coffee product have been sold?

select p.product_name,
count(s.sale_id) as total_orders
from products as p
left join sales as s
on p.product_id = s.product_id
group by p.product_name
order by total_orders desc;

-- Q.4
-- Average Sales Amount per City
-- What is the average sales amount per customer in each city?

-- city abd total sale
-- no cx in each these city
 
 SELECT ci.city_name,
       SUM(s.total) AS Total_Sales,
       COUNT(DISTINCT c.customer_id) AS Num_Customers,
       round(SUM(s.total) / COUNT(DISTINCT c.customer_id),2) AS Avg_Sales_Per_Customer
FROM sales s
JOIN customers c 
  ON s.customer_id = c.customer_id
JOIN city ci 
  ON ci.city_id = c.city_id
GROUP BY ci.city_name
order by Avg_Sales_Per_Customer desc;

 -- -- Q.5
-- City Population and Coffee Consumers (25%)
-- Provide a list of cities along with their populations and estimated coffee consumers.
-- return city_name, total current cx, estimated coffee consumers (25%)

with city_table as
(
   select city_name,
   round((population * 0.25)/100000,2) as coffee_consumers
   from city
),
customers_table as
(
   select ci.city_name,
   count(distinct c.customer_id) as total_current_cx
   from sales as s
   join customers as c
   on s.customer_id = c.customer_id
   join city as ci
   on ci.city_id = c.city_id
   group by ci.city_name
   )
select
city_table.city_name,
customers_table.total_current_cx,
city_table.coffee_consumers
from city_table
join customers_table
on city_table.city_name = customers_table.city_name
order by city_table.coffee_consumers desc;


-- -- Q6
-- Top Selling Products by City
-- What are the top 3 selling products in each city based on sales volume?

select * from -- table
(
select ci.city_name,
p.product_name,
count(s.sale_id) as total_order,
dense_rank() over(partition by ci.city_name order by count(s.sale_id) desc) as Ranking
from products as p 
join sales as s
on p.product_id = s.product_id
join customers as c
on c.customer_id = s.customer_id
join city as ci
on ci.city_id = c.city_id
group by ci.city_name,
p.product_name
) as t1
where ranking <= 3;

-- Q.7
-- Customer Segmentation by City
-- How many unique customers are there in each city who have purchased coffee products?

select * from products;

select ci.city_name,
COUNT(DISTINCT c.customer_id) AS Num_Customers
from city as ci
join customers as c
on ci.city_id = c.city_id
join sales as s
on s.customer_id = c.customer_id
where s.product_id in (1,2,3,4,5,6,7,8,9,10,11,12,13,14)
group by ci.city_name
order by Num_Customers desc;
 
 
 -- -- Q.8
-- Average Sale vs Rent
-- Find each city and their average sale per customer and avg rent per customer

WITH city_table AS (
   SELECT 
      ci.city_id,
      ci.city_name,
      SUM(s.total) AS total_sale,
      COUNT(DISTINCT c.customer_id) AS unique_customers,
      ROUND(SUM(s.total) / COUNT(DISTINCT c.customer_id), 2) AS avg_sale_per_customer
   FROM city AS ci
   JOIN customers AS c
      ON ci.city_id = c.city_id
   JOIN sales AS s
      ON s.customer_id = c.customer_id
   GROUP BY ci.city_id, ci.city_name
),
city_rent AS (
   SELECT 
      ci.city_id,
      ci.city_name,
      SUM(estimated_rent) AS total_rent,
      ROUND(SUM(estimated_rent) / COUNT(DISTINCT c.customer_id), 2) AS avg_rent_per_customer
   FROM city AS ci
   JOIN customers AS c
      ON ci.city_id = c.city_id
   JOIN sales AS s
      ON s.customer_id = c.customer_id
   GROUP BY ci.city_id, ci.city_name
)
SELECT 
   r.city_name,
   t.avg_sale_per_customer,
   r.avg_rent_per_customer
FROM city_rent r
JOIN city_table t
   ON r.city_id = t.city_id
ORDER BY r.avg_rent_per_customer DESC;


-- Q.9
-- Monthly Sales Growth
-- Sales growth rate: Calculate the percentage growth (or decline) in sales over different time periods (monthly)
-- by each city

with monthly_sales as
(
select 
ci.city_name,
extract(month from sale_date) as month,
extract(year from sale_date) as year,
sum(s.total) as total_sale
FROM city AS ci
   JOIN customers AS c
      ON ci.city_id = c.city_id
   JOIN sales AS s
      ON s.customer_id = c.customer_id
   GROUP BY  ci.city_name, month, year
   order by ci.city_name, month,total_sale ),
 growth_rate as 
 (
 select 
 city_name,
 month,
 year,
 total_sale as cr_month_sales,
 lag( total_sale, 1 ) over(partition by city_name order by month , year ) as last_month_sales
 from monthly_sales
 ) 
select 
city_name,
month,
year,
cr_month_sales,
last_month_sales,
round((cr_month_sales-last_month_sales)/cr_month_sales*100,2) as growth_ratio
from growth_rate
where last_month_sales is not null;


-- Q.10
-- Market Potential Analysis
-- Identify top 3 city based on highest sales, return city name, total sale, total rent, total customers, estimated coffee consumer


WITH city_table AS (
    SELECT 
        ci.city_name,
        SUM(s.total) AS total_revenue,
        COUNT(DISTINCT s.customer_id) AS total_cx,
        ROUND(
            SUM(s.total) / COUNT(DISTINCT s.customer_id),
            2
        ) AS avg_sale_pr_cx
    FROM sales AS s
    JOIN customers AS c
        ON s.customer_id = c.customer_id
    JOIN city AS ci
        ON ci.city_id = c.city_id
    GROUP BY ci.city_name
),
city_rent AS (
    SELECT 
        city_name, 
        estimated_rent,
        ROUND((population * 0.25)/1000000, 3) AS estimated_coffee_consumer_in_millions
    FROM city
)
SELECT 
    cr.city_name,
    ct.total_revenue,
    cr.estimated_rent AS total_rent,
    ct.total_cx,
    cr.estimated_coffee_consumer_in_millions,
    ct.avg_sale_pr_cx,
    ROUND(
        cr.estimated_rent / ct.total_cx,
        2
    ) AS avg_rent_per_cx
FROM city_rent AS cr
JOIN city_table AS ct
    ON cr.city_name = ct.city_name
ORDER BY ct.total_revenue DESC
LIMIT 3;
