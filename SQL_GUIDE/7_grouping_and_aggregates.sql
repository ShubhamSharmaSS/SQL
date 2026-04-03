-------##### CHAPTER - 7 GROUPING AND AGGREGATES ------
--Databases must store data at the lowest level of granularity needed for any particular operation.

--GROUPING CONCEPTS...
--the group by clause, which is used to group rows together using common values of one or more columns.

SELECT CALENDAR_ID,SUM(VALUE_LC), COUNT(*) 
FROM dwh_market_sales.fct_sales_national_mth 
GROUP BY CALENDAR_ID ORDER BY 1 DESC;

--Filtering on grouped data needs to be done in the having clause, which can only be used for queries including a group by clause.

SELECT CALENDAR_ID,SUM(VALUE_LC), COUNT(*) 
FROM dwh_market_sales.fct_sales_national_mth 
GROUP BY CALENDAR_ID 
HAVING SUM(VALUE_LC) >= 50000000 OR COUNT(*) >= 2000000 -- WHEN USING GROUP BY USE having FOR FILTERING PURPOSES.
ORDER BY 1 DESC;

--AGGREGATE FUNCTIONS
--Aggregate functions perform a specific operation across all rows within a group, such as counting the number of rows, summing numeric fields, or calculating averages.

SELECT COUNT(*), MIN(VALUE_LC), MAX(VALUE_LC), AVG(VALUE_LC) FROM dwh_market_sales.fct_sales_national_mth;

--EXTENDING ABOVE QUERY TO SEE ABOVE VALUE FOR EACH CALENDAR YEAR
SELECT DATE_PART(YEAR, INSERTED_TS) AS YEAR,
COUNT(*), MIN(VALUE_LC), MAX(VALUE_LC), AVG(VALUE_LC)
FROM dwh_market_sales.fct_sales_national_mth 
GROUP BY DATE_PART(YEAR, INSERTED_TS) 
HAVING DATE_PART(YEAR, INSERTED_TS) > 2000;

--it is fine to use aggregate functions without a group by clause as long as you are applying the functions across every row in the result set. Otherwise, you will need a group by clause that includes all columns other than the aggregate functions from your select clause.

--COUNT(): Counting the number of rows belonging to each group is a very common operation.
SELECT COUNT(FS.*) AS TOTAL_RECORD,
COUNT(DISTINCT(SP.PRODUCT)) AS PRODUCTS,
COUNT(DISTINCT(DATE_PART(YEAR,FS.INSERTED_TS))) AS YEAR
FROM dwh_market_sales.fct_sales_national_mth FS
JOIN DWH_MARKET_SALES.DIM_SOURCE_PRODUCT SP
ON FS.SOURCE_PRODUCT_ID = SP.SOURCE_PRODUCT_ID;

--Another useful variation of the count() function is count_if(), which will count the number of rows for which a given condition evaluates as true. Unfortunately, there aren’t similar variations of the sum(), min(), and max() functions that allow for rows to be included or excluded.

SELECT 
COUNT_IF(2025 = DATE_PART(YEAR,FS.INSERTED_TS)) AS NUM_2025,
COUNT_IF(2026 = DATE_PART(YEAR,FS.INSERTED_TS)) AS NUM_2026
FROM dwh_market_sales.fct_sales_national_mth FS;


--MIN(),MAX(),AVG() AND SUM() FUNCTION
--you are grouping data that includes numeric columns.find the largest or smallest value within the group, compute the average value for the group, or sum the values across all rows in the group. The max(), min(), avg(),and sum() aggregate functions are used for these purposes, and max() and min() are also often used with date columns.

select date_part(year, INSERTED_TS) as year,
min(value_lc), max(value_lc),avg(value_lc),sum(value_lc)
FROM dwh_market_sales.fct_sales_national_mth FS
group by date_part(year,inserted_ts) 
order by 1;

--LISTAGG() FUNCTION: the listagg() function to be extremely valuable. Listagg() generates a delimited list of values as a single column.

SELECT COUNTRY, LISTAGG(MOLECULE_LIST,',') WITHIN GROUP (ORDER BY MOLECULE_LIST) AS MASTER_MOLECULE_LIST FROM
DWH_MARKET_SALES.DIM_SOURCE_PRODUCT
GROUP BY COUNTRY ORDER BY COUNTRY;

--GENERATING GROUPS: the group by clause is the mechanism for grouping rows of data.
--MULTICOLOUMN GROUPING:  you can group on as many columns.

SELECT COUNT(FS.*) AS TOTAL_RECORD,
COUNT(DISTINCT(SP.PRODUCT)) AS PRODUCTS,
COUNT(DISTINCT(DATE_PART(YEAR,FS.INSERTED_TS))) AS YEAR
FROM dwh_market_sales.fct_sales_national_mth FS
JOIN DWH_MARKET_SALES.DIM_SOURCE_PRODUCT SP
ON FS.SOURCE_PRODUCT_ID = SP.SOURCE_PRODUCT_ID
GROUP BY (DATE_PART(YEAR,FS.INSERTED_TS)),SP.PRODUCT  -- GROUPING USING 2 COLOUMNS
ORDER BY 3 DESC ,1 DESC;

--GROUPING USING  EXPRESSION: use multiple expressions to generate groupings.
SELECT COUNT(FS.*) AS TOTAL_RECORD,
COUNT(DISTINCT(SP.PRODUCT)) AS PRODUCTS,
COUNT(DISTINCT(DATE_PART(YEAR,FS.INSERTED_TS))) AS YEAR
FROM dwh_market_sales.fct_sales_national_mth FS
JOIN DWH_MARKET_SALES.DIM_SOURCE_PRODUCT SP
ON FS.SOURCE_PRODUCT_ID = SP.SOURCE_PRODUCT_ID
GROUP BY (DATE_PART(YEAR,FS.INSERTED_TS)), -- EXPRESSION 1
DATEDIFF(MONTH,(DATE_PART(MONTH,FS.INSERTED_TS)),LEAD(DATE_PART(MONTH,FS.INSERTED_TS))) -- EXPRESSION 2
ORDER BY 3 DESC ,1 DESC;

--GROUP BY ALL: Snowflake added the group by all option, which is a nice shortcut when grouping data using expressions. the all keyword represents everything in the select statement that is not an aggregate function (e.g., sum() and count()), so if your query is grouping on complex expressions such as function calls or case expressions, using group by all will save you a lot of typing.

SELECT COUNT(FS.*) AS TOTAL_RECORD,
COUNT(DISTINCT(SP.PRODUCT)) AS PRODUCTS,
COUNT(DISTINCT(DATE_PART(YEAR,FS.INSERTED_TS))) AS YEAR
FROM dwh_market_sales.fct_sales_national_mth FS
JOIN DWH_MARKET_SALES.DIM_SOURCE_PRODUCT SP
ON FS.SOURCE_PRODUCT_ID = SP.SOURCE_PRODUCT_ID
GROUP BY ALL  -- GROUPING USING ALL COLOUMNS
ORDER BY 3 DESC ,1 DESC;

--GENERATING ROLLUPS: to know the total counts for each country across DIFFERENT segments. This can be accomplished using the rollup option of the group by clause.

SELECT SP.COUNTRY, SP.MOLECULE_LIST, 
DATE_PART(YEAR,FS.INSERTED_TS) AS YEAR, SUM(VALUE_LC)
FROM dwh_market_sales.fct_sales_national_mth FS
JOIN DWH_MARKET_SALES.DIM_SOURCE_PRODUCT SP
ON FS.SOURCE_PRODUCT_ID = SP.SOURCE_PRODUCT_ID
WHERE COUNTRY_ID BETWEEN 20 AND 25
GROUP BY ROLLUP(DATE_PART(YEAR,FS.INSERTED_TS),SP.COUNTRY,SP.MOLECULE_LIST,VALUE_LC)  -- GROUPING USING 3 COLOUMNS, 1 EXPRESSION AND ROLLINGUPS.
ORDER BY SP.COUNTRY, VALUE_LC DESC;

--If you need subtotals created for both columns, you can use the cube option instead of rollup
SELECT SP.COUNTRY, SP.MOLECULE_LIST, SUM(VALUE_LC)
FROM dwh_market_sales.fct_sales_national_mth FS
JOIN DWH_MARKET_SALES.DIM_SOURCE_PRODUCT SP
ON FS.SOURCE_PRODUCT_ID = SP.SOURCE_PRODUCT_ID
WHERE COUNTRY_ID BETWEEN 20 AND 25
GROUP BY CUBE(SP.MOLECULE_LIST,SP.COUNTRY,VALUE_LC)  --  CUBE GROUPING USING 3 COLOUMNS, 1 EXPRESSION AND ROLLINGUPS, FIRST GROUPING WILL BE DONE BY MOLECULE_LIST THEN COUNTRY THEN VALUE_LC
ORDER BY SP.COUNTRY, VALUE_LC DESC;


--FILTER GROUPING DATA: All grouping operations are done after the where clause has been evaluated, so it isnot possible to include filter conditions in your where clause that contain aggregate functions. Instead, there is a special having clause specifically for this purpose.
SELECT SP.COUNTRY, SP.MOLECULE_LIST, SUM(VALUE_LC)
FROM dwh_market_sales.fct_sales_national_mth FS
JOIN DWH_MARKET_SALES.DIM_SOURCE_PRODUCT SP
ON FS.SOURCE_PRODUCT_ID = SP.SOURCE_PRODUCT_ID
WHERE COUNTRY_ID BETWEEN 20 AND 25
GROUP BY CUBE(SP.MOLECULE_LIST,SP.COUNTRY,VALUE_LC)  --  CUBE GROUPING USING 3 COLOUMNS, 1 EXPRESSION AND ROLLINGUPS, FIRST GROUPING WILL BE DONE BY MOLECULE_LIST THEN COUNTRY THEN VALUE_LC
HAVING SUM(VALUE_LC) >= 1000000 -- SIMPLE FILTER, APPLIED AFTER GROUPING
ORDER BY SP.COUNTRY, VALUE_LC DESC;

--GROUPPING USING SNOW SITE: 
SELECT SP.COUNTRY, SP.MOLECULE_LIST, SUM(VALUE_LC),:DATEBUCKET(INSERTED_TS)
FROM dwh_market_sales.fct_sales_national_mth FS
JOIN DWH_MARKET_SALES.DIM_SOURCE_PRODUCT SP
ON FS.SOURCE_PRODUCT_ID = SP.SOURCE_PRODUCT_ID
WHERE COUNTRY_ID BETWEEN 20 AND 25
GROUP BY CUBE(SP.MOLECULE_LIST,SP.COUNTRY,VALUE_LC,:DATEBUCKET(INSERTED_TS))  --  CUBE GROUPING USING 3 COLOUMNS, 1 EXPRESSION AND ROLLINGUPS, FIRST GROUPING WILL BE DONE BY MOLECULE_LIST THEN COUNTRY THEN VALUE_LC
HAVING SUM(VALUE_LC) >= 1000000 -- SIMPLE FILTER, APPLIED AFTER GROUPING
ORDER BY SP.COUNTRY, VALUE_LC DESC;