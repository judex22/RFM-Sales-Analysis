-- Display Imported Dataset
select * from rfm_sales_analysis.sales_data_sample;

-- Checking Unique Values
select distinct STATUS from rfm_sales_analysis.sales_data_sample;
select distinct YEAR_ID from rfm_sales_analysis.sales_data_sample;
select distinct PRODUCTLINE from rfm_sales_analysis.sales_data_sample;
select distinct COUNTRY from rfm_sales_analysis.sales_data_sample;
select distinct DEALSIZE from rfm_sales_analysis.sales_data_sample;
select distinct TERRITORY from rfm_sales_analysis.sales_data_sample;




-- 1) Finding Total Revenue earned by each ProductLine in Descending Order
select PRODUCTLINE, round(sum(SALES),2) as Revenue from rfm_sales_analysis.sales_data_sample
group by PRODUCTLINE
order by sum(SALES) desc;



-- 2) Finding Total Revenue earned for each Year  in Descending Order
select YEAR_ID, round(sum(SALES),2) as Revenue from rfm_sales_analysis.sales_data_sample
group by YEAR_ID
order by sum(SALES) desc;




-- 3) Checking Which Months Operations performed for Each Year

select distinct MONTH_ID from rfm_sales_analysis.sales_data_sample
where YEAR_ID = 2003
order by MONTH_ID;

select distinct MONTH_ID from rfm_sales_analysis.sales_data_sample
where YEAR_ID = 2004
order by MONTH_ID;

select distinct MONTH_ID from rfm_sales_analysis.sales_data_sample
where YEAR_ID = 2005
order by MONTH_ID;


-- 4) Checking Which Type of DealsSize operation made the most Revenue

select DEALSIZE, round(sum(SALES),2) as Revenue from rfm_sales_analysis.sales_data_sample
group by DEALSIZE
order by 2 desc;




-- 5) What was the best Month for Sales in a Specific Year?
--    How much was earned that Month?

select MONTH_ID, round(sum(sales),2) as Revenue, count(ORDERNUMBER) as Frequency 
from rfm_sales_analysis.sales_data_sample
where YEAR_ID= 2004                            -- Change Year for Specific Year Analysis
group by MONTH_ID
order by 2 desc;
-- November month was the best month for sales in 2004

-- 6) Most Popular Product Line sold during the best Month for Sales in a Specific Year?

select MONTH_ID,PRODUCTLINE, round(sum(sales),2) as Revenue, count(ORDERNUMBER) as Frequency 
from rfm_sales_analysis.sales_data_sample
where YEAR_ID= 2004 and MONTH_ID= 11                           -- Add Specific Year and Best Month_ID
group by MONTH_ID, PRODUCTLINE
order by 3 desc;
-- In November 2004, Classic Cars was the most popular Product Line with most orders placed.

-- 7) Who is the Best Customer using RFM Analysis

with rfm_cte as 
(
	select CUSTOMERNAME, round(sum(SALES),2) as MoneytaryValue, 
	round(avg(SALES),2) as Avg_MoneytaryValue, count(ORDERNUMBER) as Frequency, 
	max(ORDERDATE) as last_order_date,
	(select max(ORDERDATE) from rfm_sales_analysis.sales_data_sample) as max_order_date,
	DATEDIFF( (select STR_TO_DATE(max(ORDERDATE), '%m/%d/%Y') from rfm_sales_analysis.sales_data_sample), STR_TO_DATE(max(ORDERDATE), '%m/%d/%Y')) as Recency -- Recency_days= Max_Date- Last-Date
    from rfm_sales_analysis.sales_data_sample
	group by CUSTOMERNAME
) ,  rfm_upd AS (
    SELECT
        *,
        NTILE(4) OVER (ORDER BY Recency) AS rfm_recency,
        NTILE(4) OVER (ORDER BY Frequency) AS rfm_frequency,
        NTILE(4) OVER (ORDER BY Avg_MoneytaryValue) AS rfm_monetary
    FROM rfm_cte
),  rfm_upd2 AS
 (
    SELECT *,
      rfm_recency+ rfm_frequency+rfm_monetary as rfm_total,
      concat(cast(rfm_recency as char),cast(rfm_frequency as char),cast(rfm_monetary as char)) as rfm_string
    FROM rfm_upd
 )
select CUSTOMERNAME, rfm_recency, rfm_frequency, rfm_monetary, rfm_string,
	 case
		when rfm_string in (111, 112, 121,122, 123, 211, 212, 114, 141) then 'Lost'
        when rfm_string in (133,134,143,244,334,343,344,144) then 'Slipping Away'  -- Big Spenders who havent purchased recently
        when rfm_string in (311,411,331) then 'New'
        when rfm_string in (222,223,233,322) then 'Potential Churners'
        when rfm_string in (433,434,443,444) then 'Best'
        when rfm_string in (323,333,321,422,332,432) then 'Active' -- Customers who often buys & recntly,at low price
        else "Others"
	end as rfm_class
 from rfm_upd2;

-- 8) What Products are most often sold together?

select distinct ORDERNUMBER, 
( select group_concat(PRODUCTCODE) 
	from rfm_sales_analysis.sales_data_sample p
	where ORDERNUMBER IN ( select ORDERNUMBER from 
							  (select ORDERNUMBER, COUNT(*) as cnt 	
								 from rfm_sales_analysis.sales_data_sample
								 where STATUS= 'Shipped'
								 group by ORDERNUMBER
							   ) m
						  where cnt=2         -- Retrieve rows with only two products sold together
						  )
    and p.ORDERNUMBER=s.ORDERNUMBER
) ProductCode
from rfm_sales_analysis.sales_data_sample s
order by 2 desc




