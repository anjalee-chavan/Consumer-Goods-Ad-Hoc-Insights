-- Q1 ) Provide the list of markets in which customer  "Atliq  Exclusive"  operates its 
-- business in the  APAC  region. 

	SELECT DISTINCT market
	FROM dim_customer
	WHERE customer="Atliq Exclusive" AND region="APAC";

 -- Q2) What is the percentage of unique product increase in 2021 vs. 2020? The final output contains these fields, 
-- unique_products_2020 ,unique_products_2021 ,percentage_chg 

     WITH CTE1 AS (
     SELECT COUNT(DISTINCT product_code) AS unique_products_2020
     FROM fact_sales_monthly s
     WHERE fiscal_year = 2020),
     CTE2 AS (
     SELECT COUNT(DISTINCT product_code) AS unique_products_2021
     FROM fact_sales_monthly s
     WHERE fiscal_year = 2021)
     SELECT * ,
            CONCAT(ROUND((CTE2.unique_products_2021-CTE1.unique_products_2020)*100/CTE1.unique_products_2020,2)," %") AS percentage_chg
     FROM CTE1,CTE2;
    
-- Q3) Provide a report with all the unique product counts for each  segment  and 
-- sort them in descending order of product counts. The final output contains 2 fields, 
-- segment , product_count

	SELECT segment,COUNT(DISTINCT product) AS product_count
	FROM dim_product
	GROUP BY segment
	ORDER BY product_count DESC;

 -- Q4) Follow-up: Which segment had the most increase in unique products in 
-- 2021 vs 2020? The final output contains these fields, 
-- segment ,product_count_2020 ,product_count_2021 ,difference

    WITH CTE1 AS (
    SELECT segment,COUNT(DISTINCT p.product_code) AS product_count_2020
    FROM dim_product p
    JOIN fact_sales_monthly s ON p.product_code=s.product_code
    WHERE fiscal_year=2020
    GROUP BY segment),
    
    CTE2 AS (
    SELECT segment,COUNT(DISTINCT p.product_code) AS product_count_2021
    FROM dim_product p
    JOIN fact_sales_monthly s ON p.product_code=s.product_code
    WHERE fiscal_year=2021
    GROUP BY segment)
    
    SELECT CTE1.segment,
           product_count_2020,
           product_count_2021,
           product_count_2021-product_count_2020 AS difference
    FROM CTE1
    JOIN CTE2 ON CTE1.segment=CTE2.segment
    ORDER BY difference DESC;
    
-- Q5) Get the products that have the highest and lowest manufacturing costs. 
-- The final output should contain these fields, 
-- product_code ,product ,manufacturing_cost

     SELECT p.product_code,p.product,m.manufacturing_cost
     FROM dim_product p 
     JOIN fact_manufacturing_cost m ON p.product_code=m.product_code
     WHERE m.manufacturing_cost IN (
     (SELECT MIN(manufacturing_cost) FROM fact_manufacturing_cost),
     (SELECT MAX(manufacturing_cost) FROM fact_manufacturing_cost));
     
-- Q6)  Generate a report which contains the top 5 customers who received an 
-- average high  pre_invoice_discount_pct  for the  fiscal  year 2021  and in the 
-- Indian  market. The final output contains these fields, 
-- customer_code ,customer ,average_discount_percentage 

     SELECT c.customer_code,
            customer,
			CONCAT(ROUND(AVG(pre_invoice_discount_pct)*100,2)," %") AS average_discount_percentage
     FROM dim_customer c
     JOIN fact_pre_invoice_deductions pre ON c.customer_code=pre.customer_code
     WHERE market="India" AND fiscal_year=2021
     GROUP BY c.customer_code,customer
     ORDER BY average_discount_percentage
     LIMIT 5;


-- Q7)  Get the complete report of the Gross sales amount for the customer  “Atliq 
-- Exclusive”  for each month  .  This analysis helps to  get an idea of low and 
-- high-performing months and take strategic decisions. 
-- The final report contains these columns: 
-- Month ,Year ,Gross sales Amount

   SELECT MONTHNAME(s.date) AS Month,s.fiscal_year AS Year,
          CONCAT(ROUND(SUM(s.sold_quantity*g.gross_price)/1000000,2)," M") AS gross_sales_amount
   FROM fact_sales_monthly s
   JOIN dim_customer c ON s.customer_code=c.customer_code
   JOIN fact_gross_price g ON s.product_code=g.product_code
   WHERE customer="Atliq Exclusive"
   GROUP BY MONTHNAME(s.date),s.fiscal_year;
   
-- Q8)  In which quarter of 2020, got the maximum total_sold_quantity? The final 
-- output contains these fields sorted by the total_sold_quantity, 
-- Quarter ,total_sold_quantity

     SELECT 
        CASE 
			WHEN Month(s.date) IN (9,10,11) THEN "Q1"
			WHEN Month(s.date) IN (12,1,2) THEN "Q2"
			WHEN Month(s.date) IN (3,4,5) THEN "Q3"
            ELSE "Q4"
        END AS Quarters,
	 CONCAT(ROUND(SUM(s.sold_quantity)/1000000,2)," M") AS total_sold_quantity
	 FROM fact_sales_monthly s
	 WHERE fiscal_year=2020
	 GROUP BY Quarters
	 ORDER BY total_sold_quantity DESC;
	 
-- Q9) Which channel helped to bring more gross sales in the fiscal year 2021 
-- and the percentage of contribution?  The final output  contains these fields, 
-- channel ,gross_sales_mln ,percentage 

	WITH CTE1 AS (
	SELECT channel,
           CONCAT(ROUND(SUM(s.sold_quantity*p.gross_price)/1000000,2)," M") AS gross_sales_mln
	FROM fact_sales_monthly s
	JOIN dim_customer c ON c.customer_code=s.customer_code
	JOIN fact_gross_price p ON s.product_code=p.product_code
	GROUP BY channel),
    
    CTE2 AS (
	SELECT *,
		   (gross_sales_mln*100)/SUM(gross_sales_mln) OVER() AS percentage
	FROM CTE1)
    
    SELECT channel,
           gross_sales_mln,
		   CONCAT(ROUND(percentage,2)," %") AS percentage
    FROM CTE2;
    
-- Q10)  Get the Top 3 products in each division that have a high 
-- total_sold_quantity in the fiscal_year 2021? The final output contains these fields, 
-- division ,product_code ,product total_sold_quantity ,rank_order
 
	with CTE1 AS(
	SELECT division,p.product_code,SUM(s.sold_quantity) AS total_sold_quantity
	from fact_sales_monthly s
	JOIN dim_product p ON s.product_code=p.product_code
	WHERE fiscal_year=2021
	GROUP BY division,p.product_code),
    
	CTE2 AS(
	SELECT *,
		   DENSE_RANK() OVER(PARTITION BY division ORDER BY total_sold_quantity DESC) AS rank_order
	FROM CTE1)
    
	SELECT * 
	FROM CTE2
	WHERE rank_order <=3;
    
   