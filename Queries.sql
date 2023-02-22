
/*1. Provide the list of markets in which customer "Atliq Exclusive" operates its
business in the APAC region.*/

Select distinct market from dim_customer where customer="Atliq Exclusive" and region="APAC";

/* 2. What is the percentage of unique product increase in 2021 vs. 2020? */

select 
    y1.count as unique_products_2020, y2.count as unique_products_2021, concat(((y2.count - y1.count)/y1.count)*100,'%') as percentage_chg
from 
    (select count(distinct dim_product.product_code) as count  from dim_product inner join fact_sales_monthly on dim_product.product_code = fact_sales_monthly.product_code where fiscal_year = 2020) y1,
    (select count(distinct dim_product.product_code) as count  from dim_product inner join fact_sales_monthly on dim_product.product_code = fact_sales_monthly.product_code where fiscal_year = 2021) y2;

/* 3. Provide a report with all the unique product counts for each segment and
sort them in descending order of product counts. */

select segment, count(distinct product_code) as product_count from dim_product group by segment order by product_count desc; 

/* 4. Follow-up: Which segment had the most increase in unique products in
2021 vs 2020? */

create table segment_2020 select dim_product.segment, count(distinct dim_product.product_code) as unique_product_2020 from dim_product inner join fact_sales_monthly on dim_product.product_code = fact_sales_monthly.product_code where fact_sales_monthly.fiscal_year = 2020 group by dim_product.segment;
create table segment_2021 select dim_product.segment, count(distinct dim_product.product_code) as unique_product_2021 from dim_product inner join fact_sales_monthly on dim_product.product_code = fact_sales_monthly.product_code where fact_sales_monthly.fiscal_year = 2021 group by dim_product.segment;
select 
    segment_2020.segment, segment_2020.unique_product_2020 as product_count_2020, segment_2021.unique_product_2021 as product_count_2021, (segment_2021.unique_product_2021-segment_2020.unique_product_2020) as difference
from
    segment_2020
inner join
    segment_2021
on
    segment_2020.segment = segment_2021.segment
order by
    difference desc;
    
/* 5. Get the products that have the highest and lowest manufacturing costs. */

select
 dim_product.product_code, concat(dim_product.product," ",dim_product.variant) as product, fact_manufacturing_cost.manufacturing_cost
 from
 dim_product
 inner join
 fact_manufacturing_cost on dim_product.product_code = fact_manufacturing_cost.product_code where fact_manufacturing_cost.manufacturing_cost = (select max(manufacturing_cost) from fact_manufacturing_cost) or fact_manufacturing_cost.manufacturing_cost = (select min(manufacturing_cost) from fact_manufacturing_cost) order by manufacturing_cost desc;

/* 6. Generate a report which contains the top 5 customers who received an
average high pre_invoice_discount_pct for the fiscal year 2021 and in the
Indian market. */

select 
    dim_customer.customer_code, dim_customer.customer, avg(fact_pre_invoice_deductions.pre_invoice_discount_pct * 100) as average_discount_percentage
from
    dim_customer inner join fact_pre_invoice_deductions on dim_customer.customer_code = fact_pre_invoice_deductions.customer_code
where
    fiscal_year = 2021 and market = 'India'
group by 
    dim_customer.customer_code
order by
    average_discount_percentage desc limit 5;
    
/* 7. Get the complete report of the Gross sales amount for the customer “Atliq
Exclusive” for each month. This analysis helps to get an idea of low and
high-performing months and take strategic decisions. */

create table sales_customer select dim_customer.customer_code, dim_customer.customer, dim_customer.channel, fact_sales_monthly.date, fact_sales_monthly.sold_quantity, fact_sales_monthly.product_code, fact_sales_monthly.fiscal_year from dim_customer inner join fact_sales_monthly on dim_customer.customer_code = fact_sales_monthly.customer_code;
select 
    month(sales_customer.date) as month, year(sales_customer.date) as year, sum(fact_gross_price.gross_price*sales_customer.sold_quantity) as Gross_sales_Amount 
from
    sales_customer
right join
    fact_gross_price
on
    sales_customer.product_code = fact_gross_price.product_code
where
    sales_customer.customer="Atliq Exclusive"
group by
    sales_customer.date;
    
/* 8. In which quarter of 2020, got the maximum total_sold_quantity? */

select
case
    when month(date) in (9,10,11) then 'Q1'
    when month(date) in (12,1,2) then 'Q2'
    when month(date) in (3,4,5) then 'Q3'
    else 'Q4'
end as Quarter, sum(sold_quantity) as total_sold_quantity
from 
    fact_sales_monthly
where 
    fiscal_year = 2020
group by
    Quarter
order by
    total_sold_quantity desc;
    
/* 9. Which channel helped to bring more gross sales in the fiscal year 2021
and the percentage of contribution? */

create table
    sales_2021_table
select 
    channel, sum(sold_quantity*gross_price)/1000000 as gross_sales_mln
from
    dim_customer
join
    fact_sales_monthly
on
    dim_customer.customer_code = fact_sales_monthly.customer_code
join
    fact_gross_price
on
    fact_sales_monthly.product_code = fact_gross_price.product_code
and
    fact_sales_monthly.fiscal_year = fact_gross_price.fiscal_year
where 
    fact_sales_monthly.fiscal_year = 2021
group by
    channel
order by
    gross_sales_mln desc;
select channel, gross_sales_mln,gross_sales_mln*100/sum(gross_sales_mln) over() as percentage from sales_2021_table;

/* 10. Get the Top 3 products in each division that have a high
total_sold_quantity in the fiscal_year 2021? */

with sales_summary as (
    SELECT 
    division, product_code, concat(product," ",variant) as product, SUM(sold_quantity) AS total_sold_quantity, RANK() OVER (PARTITION BY division ORDER BY SUM(sold_quantity) DESC) as rank_order
    FROM product_table
	WHERE fiscal_year = 2021
    GROUP BY division, product_code, product
)
select division, product_code, product, total_sold_quantity, rank_order
from sales_summary
where rank_order <= 3
order by division, rank_order;





    

