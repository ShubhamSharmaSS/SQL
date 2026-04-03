-------##### CHAPTER - 8 SUBQUERIES ------
--Subqueries are a powerful tool that can be used in select, update, insert, delete,and merge statements.
--SUBQUERIES DEFINED: A subquery is a query that is contained within another SQL statement. Subqueries are always surrounded by parentheses and generally run prior to the containing statement.
--SUBQUERY TYPES: There are two types of subqueries, and the difference lies in whether the subquery can be executed separately from the containing query.
--UNCORELATED SUBQUERIES: an uncorrelated subquery; it may be executed separately and does not reference anything from the containing query. Most subqueries that you encounter will be of this type unless you are writing update or delete statements which include subqueries. Along with being uncorrelated, the example table is known as a scalar subquery, meaning that it returns a single row having a single column. Scalar subqueries can appear on either side of a condition using the oper ators =, <>, <, >, <=, and >=.
SELECT MAX(INSERTED_TS),COUNTRY FROM DWH_MARKET_SALES.DIM_SOURCE_PRODUCT SP
WHERE SP.COUNTRY = 
(SELECT COUNTRY FROM DWH_MARKET_SALES.DIM_COUNTRY DC WHERE DC.COUNTRY_ID = 20)
GROUP BY CUBE(COUNTRY,INSERTED_TS)
9 ORDER BY 1 DESC;

--Subqueries may be as complex as you need them to be, and they may be used in any of the available query clauses (select,from, where, group by, having, and order by).If you use a subquery in an equality condition, but the subquery returns more than one row, you will receive an error.
SELECT MAX(INSERTED_TS) FROM DWH_MARKET_SALES.DIM_SOURCE_PRODUCT SP
WHERE SP.COUNTRY = 
(SELECT COUNTRY FROM DWH_MARKET_SALES.DIM_COUNTRY DC WHERE DC.COUNTRY_ID > 20); --o/p: Single-row subquery returns more than one row.

--MULTIPLE-ROW,SINGLE-COLOUMN SUBQUERIES: can’t equate a single value to a set of values, you can determine if a single value can be found within a set of values. To do so, you can use the in operator:
SELECT MAX(INSERTED_TS) FROM DWH_MARKET_SALES.DIM_SOURCE_PRODUCT SP
WHERE SP.COUNTRY in 
(SELECT COUNTRY FROM DWH_MARKET_SALES.DIM_COUNTRY DC WHERE DC.COUNTRY_ID > 20);

--use not in to return rows where a value is not found within the set returned by the subquery:
SELECT MAX(INSERTED_TS) FROM DWH_MARKET_SALES.DIM_SOURCE_PRODUCT SP
WHERE SP.COUNTRY NOT IN 
(SELECT COUNTRY FROM DWH_MARKET_SALES.DIM_COUNTRY DC WHERE DC.COUNTRY_ID <> 20);

--Along with checking if a value can be found, or not found, in a set of values, it is also possible to perform comparisons on each value in a set. Using the all operator:
SELECT INSERTED_TS,COUNTRY,COUNT(*) FROM DWH_MARKET_SALES.DIM_SOURCE_PRODUCT SP
WHERE 2025 = DATE_PART(YEAR,INSERTED_TS) GROUP BY ALL
HAVING COUNT(*) > ALL  -- THIS WILL COMPARE ALL THE VALUES AND RETURN MAX AND COMPARE ON THAT.
(SELECT COUNT(*) FROM DWH_MARKET_SALES.DIM_COUNTRY DC WHERE DC.COUNTRY_ID <> 20);

--Along with all, you can also use the any operator, which also compares a value to a set of values, but only needs to find a single instance where the comparison holds true.
SELECT INSERTED_TS,COUNTRY,COUNT(*) FROM DWH_MARKET_SALES.DIM_SOURCE_PRODUCT SP
WHERE 2025 = DATE_PART(YEAR,INSERTED_TS) GROUP BY ALL
HAVING COUNT(*) > ANY  -- THIS WILL COMPARE ALL THE VALUES AND RETURN ANY VALUE THAT HOLDS TRUE AND COMPARE ON THAT.
(SELECT COUNT(*) FROM DWH_MARKET_SALES.DIM_COUNTRY DC WHERE DC.COUNTRY_ID <> 20);

--MULTICOLOUMN SUBQUERIES: 
--a query that finds the largest LC for each year:
SELECT MAX(INSERTED_TS),COUNTRY FROM DWH_MARKET_SALES.DIM_SOURCE_PRODUCT SP
WHERE SP.COUNTRY = 
(SELECT COUNTRY FROM DWH_MARKET_SALES.DIM_COUNTRY DC WHERE DC.COUNTRY_ID = 20)
GROUP BY CUBE(COUNTRY,INSERTED_TS);

--Correlated Subqueries: A correlated subquery, on the other hand, references one or more columns from the containing statement, which means that both the subquery and containing query must run together. Since the correlated subquery will be executed once for each row of the containing query, the use of correlated subqueries can cause performance issues if the containing query returns a large number of rows.
--FOLLOWING QUERY GIVE LIST OF PRODUCT WHOS VALUE_LC IS >= 10000 FOR EGYPT COUNTRY

SELECT PRODUCT FROM PSA_EG.VW_PSA_EG_DIM_PRODUCT_MTH VD WHERE 
10000 <= (SELECT SUM(VALUE_LC) FROM dwh_market_sales.fct_sales_national_mth F 
WHERE F.SOURCE_PRODUCT_ID = VD.SOURCE_PRODUCT_ID) AND VD.COUNTRY = 'EGYPT';

--EXISTS OPERATOR: 
--Correlated subqueries are often used with the exists operator, which is useful when you want to test for the existence of a particular relationship without regard for the quantity. Snowflake is smart enough to stop execution of the subquery once the first matching row is found.
SELECT PRODUCT FROM PSA_EG.VW_PSA_EG_DIM_PRODUCT_MTH VD WHERE 
EXISTS (SELECT 1 FROM dwh_market_sales.fct_sales_national_mth F 
WHERE COUNTRY_ID = 20 AND VALUE_LC >= 10000) AND VD.COUNTRY = 'EGYPT';

--CORRELATED SUBQUERIES IN UPDATE AND DELETE STATEMENTS
--DELETING THE RECORDS WHOSE VALUE_LC IS LESS THAN 10,  AND INSERTED_TS IS MORE THAN 3 YEARS FROM STG TABLE...
DELETE FROM STG_EG.STG_EG_SALES_NATIONAL_MTH VD WHERE 
NOT EXISTS (SELECT 1 FROM dwh_market_sales.fct_sales_national_mth F 
WHERE COUNTRY_ID = 20 AND INSERTED_TS >= DATEADD(YEAR,-5,CURRENT_DATE) AND VALUE_LC >= 10) ;

--SUBQUERIES AS DATA SOURCES: Since subqueries return result sets, they can be used in place of tables in select statements.
--SUBQUERIES IN THE FROM CLAUSE: Tables and subqueries can both be used in the from clause of a query, and can even be joined to each other. 

SELECT (X.COUNTRY_ID || X.FREQUENCY || X.CALENDAR_ID) AS SHORT ,X.* FROM (
SELECT
    MD5(UPPER(TRIM(COUNTRY)||IFNULL(NULLIF(TRIM(PRODUCT_LOCAL), ''), 'UNKNOWN')|| IFNULL(NULLIF(TRIM(MANUFACTURER), ''), 'UNKNOWN')|| IFNULL(NULLIF(TRIM(PACK_LOCAL), ''), 'UNKNOWN')|| IFNULL(NULLIF(TRIM(OTC4_LOCAL), ''), 'UNKNOWN') )) AS DISTRIBUTION_ID,
    MD5(UPPER(COUNTRY||PANEL||CHANNEL)) AS PANEL_ID,
    (SELECT DISTINCT COUNTRY_ID  FROM DWH_MARKET_SALES.DIM_COUNTRY  WHERE UPPER(COUNTRY)='SWITZERLAND') AS COUNTRY_ID,
    'M' AS FREQUENCY,
    CALENDAR_ID,
    MAX(ROUND(NUM_DISTRIBUTION_SELLOUT,2)) as NUM_DISTRIBUTION_SELLOUT,
    MAX(ROUND(WTD_DISTRIBUTION_SELLOUT,2)) as WTD_DISTRIBUTION_SELLOUT,
	MAX(ROUND(WTD_DISTRIBUTION_STOCK,2)) as WTD_DISTRIBUTION_STOCK,
    CURRENT_TIMESTAMP AS INSERTED_TS
FROM
    PSA_CH.PSA_CH_DIST_MTH_TRANSP
WHERE
    LATEST_FLAG = 1
AND (COALESCE(NUM_DISTRIBUTION_SELLOUT, 0) + COALESCE(WTD_DISTRIBUTION_SELLOUT, 0) + COALESCE(WTD_DISTRIBUTION_STOCK, 0)) !=0
    GROUP BY ALL) X;

--COMMON TABLE EXPRESSION: 
--Along with putting subqueries in the from clause, you also have the option to move your subqueries into a with clause, which must always appear at the top of your query above the select clause

WITH ABC AS (
SELECT
    MD5(UPPER(TRIM(COUNTRY)||IFNULL(NULLIF(TRIM(PRODUCT_LOCAL), ''), 'UNKNOWN')|| IFNULL(NULLIF(TRIM(MANUFACTURER), ''), 'UNKNOWN')|| IFNULL(NULLIF(TRIM(PACK_LOCAL), ''), 'UNKNOWN')|| IFNULL(NULLIF(TRIM(OTC4_LOCAL), ''), 'UNKNOWN') )) AS DISTRIBUTION_ID,
    MD5(UPPER(COUNTRY||PANEL||CHANNEL)) AS PANEL_ID,
    (SELECT DISTINCT COUNTRY_ID  FROM DWH_MARKET_SALES.DIM_COUNTRY  WHERE UPPER(COUNTRY)='SWITZERLAND') AS COUNTRY_ID,
    'M' AS FREQUENCY,
    CALENDAR_ID,
    MAX(ROUND(NUM_DISTRIBUTION_SELLOUT,2)) as NUM_DISTRIBUTION_SELLOUT,
    MAX(ROUND(WTD_DISTRIBUTION_SELLOUT,2)) as WTD_DISTRIBUTION_SELLOUT,
	MAX(ROUND(WTD_DISTRIBUTION_STOCK,2)) as WTD_DISTRIBUTION_STOCK,
    CURRENT_TIMESTAMP AS INSERTED_TS
FROM
    PSA_CH.PSA_CH_DIST_MTH_TRANSP
WHERE
    LATEST_FLAG = 1
AND (COALESCE(NUM_DISTRIBUTION_SELLOUT, 0) + COALESCE(WTD_DISTRIBUTION_SELLOUT, 0) + COALESCE(WTD_DISTRIBUTION_STOCK, 0)) !=0
    GROUP BY ALL),

XYZ AS (
SELECT (X.COUNTRY_ID || X.FREQUENCY || X.CALENDAR_ID) AS SHORT ,X.* FROM (
SELECT
    (SELECT DISTINCT COUNTRY_ID  FROM DWH_MARKET_SALES.DIM_COUNTRY  WHERE UPPER(COUNTRY)='SWITZERLAND') AS COUNTRY_ID,
    'M' AS FREQUENCY,
    CALENDAR_ID
FROM
    PSA_CH.PSA_CH_DIST_MTH_TRANSP
WHERE
    LATEST_FLAG = 1
AND (COALESCE(NUM_DISTRIBUTION_SELLOUT, 0) + COALESCE(WTD_DISTRIBUTION_SELLOUT, 0) + COALESCE(WTD_DISTRIBUTION_STOCK, 0)) !=0
    GROUP BY ALL) X
)
SELECT * FROM ABC JOIN 
XYZ ON XYZ.SHORT = ABC.(COUNTRY_ID || FREQUENCY || CALENDAR_ID);

--Subqueries in a with clause are known as common table expressions, or CTEs.  Having a single CTE can make a query more readable, but if you have multiple CTEs in a with clause you can reference any subqueries defined above in the same with clause.
--use CTEs to fabricate data sets that don’t exist in your database,
WITH dollar_ranges AS (
    SELECT *
    FROM (VALUES
        (3, 'Bottom Tier', 650000, 700000),
        (2, 'Middle Tier', 700001, 730000),
        (1, 'Top Tier', 730001, 9999999)
    ) AS dr(range_num, range_name, low_val, high_val)
),

XYZ AS (
    SELECT
        CASE 
            WHEN VALUE_LC BETWEEN 650000 AND 700000 THEN 3
            WHEN VALUE_LC BETWEEN 700001 AND 730000 THEN 2
            WHEN VALUE_LC BETWEEN 730001 AND 9999999 THEN 1
        END AS TIER_CLASS,
        *
    FROM dwh_market_sales.fct_sales_national_mth
)

SELECT *
FROM XYZ
JOIN dollar_ranges
    ON XYZ.TIER_CLASS = dollar_ranges.range_num ORDER BY TIER_CLASS DESC;