-- SQL porfolio project.
-- download credit card transactions dataset from below link :
-- https://www.kaggle.com/datasets/thedevastator/analyzing-credit-card-spending-habits-in-india
-- import the dataset in sql server with table name : credit_card_transcations
-- change the column names to lower case before importing data to sql server.Also replace space within column names with underscore.
-- (alternatively you can use the dataset present in zip file)
-- while importing make sure to change the data types of columns. by defualt it shows everything as varchar.

-- write 4-6 queries to explore the dataset and put your findings 

-- solve below questions

-- 1- write a query to print top 5 cities with highest spends and their percentage contribution of total credit card spends 

SELECT 
    City,
    SUM(Amount) AS Total_Spend,
	SUM(Amount)*100.0 / (SELECT SUM(Amount) FROM credit_card_transcations) AS Percentage_Contribution
FROM 
    credit_card_transcations
GROUP BY 
    City
ORDER BY 
    Total_Spend DESC
LIMIT 5;

-- 2- write a query to print highest spend month for each year and amount spent in that month for each card type

WITH cte1 AS(
	SELECT card_type, YEAR(transaction_date) year_trans,
	MONTH(transaction_date) month_trans, SUM(amount) AS total_spend
	FROM credit_card_transcations
	GROUP BY card_type, YEAR(transaction_date), MONTH(transaction_date)
), cte2 AS(
	SELECT *, DENSE_RANK() OVER(PARTITION BY card_type ORDER BY total_spend DESC) AS rn
	FROM cte1
)
SELECT *
FROM cte2
WHERE rn =1;

-- 3- write a query to print the transaction details(all columns from the table) for each card type when
	-- it reaches a cumulative of 1000000 total spends(We should have 4 rows in the o/p one for each card type)3
    
WITH cte1 AS(
SELECT *, 
SUM(amount) OVER(PARTITION BY card_type ORDER BY transaction_id, transaction_date) AS total_spend 
FROM credit_card_transcations
),
cte2 AS(
SELECT*,
DENSE_RANK() OVER (PARTITION BY card_type ORDER BY total_spend) AS rn 
FROM cte1 WHERE total_spend>=1000000
)
SELECT * 
FROM cte2
WHERE rn=1;

-- 4- write a query to find city which had lowest percentage spend for gold card type


WITH cte as(
	SELECT city, card_type, SUM(amount) as amount,
    SUM(CASE 
        WHEN card_type='Gold' THEN amount 
        END) as gold_amount
	FROM credit_card_transcations
	GROUP BY city, card_type
)
SELECT city, SUM(gold_amount)*1.0/SUM(amount) as gold_ratio
FROM cte
GROUP BY city
HAVING COUNT(gold_amount) > 0 AND SUM(gold_amount)>0
ORDER BY gold_ratio;

-----------------------
WITH cte AS (
    SELECT 
        city, 
        SUM(amount) AS total_amount,
        SUM(CASE WHEN card_type = 'Gold' THEN amount ELSE 0 END) AS gold_amount
    FROM credit_card_transcations
    GROUP BY city
)
SELECT 
    city, 
    gold_amount * 100.0 / total_amount AS gold_percentage
FROM cte
WHERE gold_amount > 0
ORDER BY gold_percentage
LIMIT 1;


-- 5- write a query to print 3 columns:  city, highest_expense_type , lowest_expense_type (example format : Delhi , bills, Fuel)

WITH cte1 as (
	SELECT city, exp_type, SUM(amount) as total_amount 
    FROM credit_card_transcations
	GROUP BY city, exp_type
), cte2 as (
	SELECT *,
    DENSE_RANK() OVER(PARTITION BY city ORDER BY total_amount DESC) rn_desc,
    DENSE_RANK() OVER(PARTITION BY city ORDER BY total_amount ASC) rn_asc
	FROM cte1
)
SELECT city, 
MAX(CASE WHEN rn_asc=1 THEN exp_type END) as lowest_exp_type, 
MAX(CASE WHEN rn_desc=1 THEN exp_type END) as highest_exp_type
FROM cte2
GROUP BY city;

-- 6- write a query to find percentage contribution of spends by females for each expense type

SELECT exp_type,
SUM(CASE WHEN gender='F' THEN amount ELSE 0 END)*100/SUM(amount) as percentage_female_contribution
FROM credit_card_transcations
GROUP BY exp_type;

-- 7- which card and expense type combination saw highest month over month growth in Jan-2014

WITH cte1 AS (
    SELECT card_type, exp_type, YEAR(transaction_date) AS year, MONTH(transaction_date) AS month, 
	SUM(amount) AS total_spend
    FROM credit_card_transcations
    GROUP BY card_type, exp_type, YEAR(transaction_date), MONTH(transaction_date)
),
cte2 AS (
    SELECT card_type, exp_type, year, month, total_spend, 
    LAG(total_spend) OVER (PARTITION BY card_type, exp_type ORDER BY year, month) AS prev_spend
    FROM cte1
)
SELECT card_type, exp_type, total_spend, prev_spend, total_spend - prev_spend AS growth
FROM cte2
WHERE year = 2014 AND month = 1 AND prev_spend IS NOT NULL
ORDER BY growth DESC
LIMIT 1;
-- 8- during weekends which city has highest total spend to total no of transcations ratio 

SELECT city , SUM(amount)*100/COUNT(1) as transcations_ratio
FROM credit_card_transcations
WHERE DAYNAME(transaction_date) in ('Saturday','Sunday')
GROUP BY city
ORDER BY transcations_ratio DESC
LIMIT 1;

-- 9- which city took least number of days to reach its 500th transaction after the first transaction in that city

WITH cte as(
	SELECT *,
    ROW_NUMBER() OVER(PARTITION BY city ORDER BY transaction_date, transaction_id) as rn
	FROM credit_card_transcations
)
SELECT city, TIMESTAMPDIFF(DAY, MIN(transaction_date), MAX(transaction_date)) as datediff1
FROM cte
WHERE rn=1 or rn=500
GROUP BY city
HAVING COUNT(1)=2
ORDER BY datediff1
LIMIT 1; 
-- once you are done with this create a github repo to put that link in your resume. Some example github links:
-- https://github.com/ptyadana/SQL-Data-Analysis-and-Visualization-Projects/tree/master/Advanced%20SQL%20for%20Application%20Development
-- https://github.com/AlexTheAnalyst/PortfolioProjects/blob/main/COVID%20Portfolio%20Project%20-%20Data%20Exploration.sql