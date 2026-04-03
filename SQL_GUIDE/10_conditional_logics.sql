-------##### CHAPTER - 10 CONDITIONAL LOGIC------
--In certain situations, SQL statement to behave differently depending on the values of certain columns or expressions, which is known as conditional logic. The mechanism used for conditional logic in SQL statements is the case expression, which can be utilized in insert, update, and delete statements, as well as in every clause of a select statement.
--CONDITIONAL LOGIC: the SQL language uses case expressions for conditional logic. The case expression works like a cascading if-then else statement, evaluating a series of conditions in sequence.
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
            WHEN VALUE_LC BETWEEN 650000 AND 700000 THEN 3 --CONDITION 1
            WHEN VALUE_LC BETWEEN 700001 AND 730000 THEN 2 --CONDITION 2
            WHEN VALUE_LC BETWEEN 730001 AND 9999999 THEN 1 --CONDITION 3
            ELSE 00 -- DEFAULT CONDITION IF NON OF THE ABOVE CONDITION PASSES.
        END AS TIER_CLASS,
        *
    FROM dwh_market_sales.fct_sales_national_mth
)

SELECT *
FROM XYZ
JOIN dollar_ranges
    ON XYZ.TIER_CLASS = dollar_ranges.range_num ORDER BY TIER_CLASS DESC;
    
--Case expressions can have multiple conditions (each starting with the when keyword),and the conditions are evaluated in order from top to bottom. Evaluation ends as soon as one condition evaluates as true.

--TYPES OF CASE EXPRESSION:
-- SEARCHED CASE EXPRESSION:
--Searched case expressions can have multiple when clauses and an optional else clause to be returned if none of the when clauses evaluate as true. Case expressions can return any type of expression, including numbers, strings, dates, and even subqueries, 
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
            WHEN VALUE_LC BETWEEN 650000 AND 700000 THEN 3 --CONDITION 1
            WHEN VALUE_LC BETWEEN 700001 AND 730000 THEN 2 --CONDITION 2
            WHEN VALUE_LC BETWEEN 730001 AND 9999999 THEN 1 --CONDITION 3
            WHEN VALUE_LC = 1 THEN (SELECT '001')  --QUERY INSIDE CASE CONDITION
            ELSE 00 -- DEFAULT CONDITION IF NON OF THE ABOVE CONDITION PASSES.
        END AS TIER_CLASS,
        *
    FROM dwh_market_sales.fct_sales_national_mth
)

SELECT *
FROM XYZ
JOIN dollar_ranges
    ON XYZ.TIER_CLASS = dollar_ranges.range_num ORDER BY TIER_CLASS DESC;

--SIMPLE CASE EXPRESSION: The simple case expression is quite similar to the searched case expression but is a bit less flexible (and thus used less frequently)
--For this type of statement, an expression is evaluated and compared to a set of values. If a match is found, the corresponding expression is returned, and if no match is found, the expression in the optional else clause is returned.
SELECT CASE SRC_CHANNEL 
WHEN  'RETAIL' THEN 'FOR SALE' 
WHEN 'NON RETAIL' THEN 'HOSPITAL CONSUMPTION' END AS STATUS
FROM DF_CHC_MARKET_DEV.PSA_EG.PSA_EG_SALES_NATIONAL_MTH_TRANSP SAMPLE(200 ROWS);

--CHECKING FOR EXISTENCE
--if a certain relationship exists, without regard for the number of occurrences.
SELECT COUNTRY_ID,CALENDAR_ID, CASE WHEN EXISTS(SELECT MAX(VALUE_LC),COUNTRY_ID FROM dwh_market_sales.fct_sales_national_mth GROUP BY 2) THEN 'MAJOR PLAYER' ELSE 'REGULAR PLAYER' END AS TREND
FROM dwh_market_sales.fct_sales_national_mth F GROUP BY ALL;

--CONDITIONAL UPDATES: TO POPULATE A COLOUMN USING OTHER COLOUMN.
UPDATE DF_CHC_MARKET_DEV.STG_EG.STG_EG_SALES_NATIONAL_MTH 
SET LC_60 = CASE WHEN EXISTS 
(SELECT 1 FROM  DF_CHC_MARKET_DEV.STG_EG.STG_EG_SALES_NATIONAL_MTH WHERE LC_60 = NULL OR LC_60 = '0') THEN 0 END;

--CONDITIONAL DELETEION: 
DELETE FROM DF_CHC_MARKET_DEV.STG_EG.STG_EG_SALES_NATIONAL_MTH where 
1 = CASE WHEN NOT EXISTS 
(SELECT 1 FROM  DF_CHC_MARKET_DEV.STG_EG.STG_EG_SALES_NATIONAL_MTH WHERE LC_60 = NULL OR LC_60 = '0') THEN 1 END;

--you can retrieve all the things back to original using time travel:
insert into DF_CHC_MARKET_DEV.STG_EG.STG_EG_SALES_NATIONAL_MTH 
select * from DF_CHC_MARKET_DEV.STG_EG.STG_EG_SALES_NATIONAL_MTH at(offset => -3600);

--FUNCTIONS FOR CONDITIONAL LOGIC
--IFF() FUNCTION: a simple if-then-else expression having a single condition,
SELECT COUNTRY_ID,CALENDAR_ID, IFF( EXISTS(SELECT MAX(VALUE_LC),COUNTRY_ID FROM dwh_market_sales.fct_sales_national_mth GROUP BY 2),'MAJOR PLAYER', 'REGULAR PLAYER') AS TREND_IFF,
CASE WHEN EXISTS(SELECT MAX(VALUE_LC),COUNTRY_ID FROM dwh_market_sales.fct_sales_national_mth GROUP BY 2) THEN 'MAJOR PLAYER' ELSE 'REGULAR PLAYER' END AS TREND_CASE
FROM dwh_market_sales.fct_sales_national_mth F GROUP BY ALL;
--Keep in mind that the iff() function cannot be used if multiple conditions need to be evaluated.

--IFNULL() AND NUL() FUNCTIONS: especially when writing reports, where you want to substitute a value such as 'unknown' or 'N/A' when a column is null. For these situations, you can use either the ifnull() or nvl() functions.
SELECT NVL(LC_60,'N/A') AS LC_60_NVL,
IFNULL(LC_60,'UNKNOWN') AS LC_60_IFNULL
FROM DF_CHC_MARKET_DEV.STG_EG.STG_EG_SALES_NATIONAL_MTH;
--These functions are also useful for cases where the value for a column can come from one of two different places.
--to choose between more than two columns to find a nonnull value, you can use the coalesce() function, which allows for an unlimited number of expressions to be evaluated.

--DECODE() FUNCTION: The decode() function works just like a simple case expression; a single expression is compared to a set of one or more values, and when a match is found the corresponding value is returned..
SELECT SRC_CHANNEL,CASE SRC_CHANNEL 
WHEN  'RETAIL' THEN 'FOR SALE' 
WHEN 'NON RETAIL' THEN 'HOSPITAL CONSUMPTION' END AS STATUS,
DECODE(SRC_CHANNEL, 'RETAIL','FOR SALE','NON RETAIL', 'HOSPITAL CONSUMPTION') AS DECODE_STATUS
FROM DF_CHC_MARKET_DEV.PSA_EG.PSA_EG_SALES_NATIONAL_MTH_TRANSP SAMPLE(200 ROWS);
--people prefer using decode() because it is less wordy,use case, because it is easier to understand and is portable between different database servers.