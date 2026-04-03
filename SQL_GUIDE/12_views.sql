-------##### CHAPTER - 12 VIEWS ------
--WHAT IS VIEW?
--A view is a database object similar to a table, but views can only be queried. Views do not involve any data storage (with the exception of materialized views)
-- One way to think of a view is as a named query, stored in the database for easy use. 

--CREATING VIEWS:
--Views are created using the create view statement, which is essentially a name followed by a query. 
create view DF_CHC_MARKET_DEV.PSA_PE.VW_PSA_PE_DIST_FCT_MTH_TEST
 as 
WITH CTE_DIST_SRC AS 
(
    SELECT 
        DISTINCT MD5(UPPER(TRIM(COUNTRY)) || IFNULL(NULLIF(LTRIM(TRIM(GMID), '0'), ''), 'UNKNOWN')) AS DISTRIBUTION_ID,
        CAST(MD5(UPPER(COUNTRY || PANEL || CHANNEL)) AS VARCHAR(1000)) AS PANEL_ID,
        CHANNEL_TYPE,
        (
            SELECT
                DISTINCT COUNTRY_ID
            FROM
                DWH_MARKET_SALES.DIM_COUNTRY
            WHERE
                UPPER(COUNTRY) = 'PERU'
        ) AS COUNTRY_ID,
        CALENDAR_ID,
        WEIGHTED_SELL_OUT,
        NUMERIC_SELL_OUT,
        CURRENT_TIMESTAMP AS INSERTED_TIMESTAMP
    FROM
        PSA_PE.PSA_PE_DIST_MTH_TRANSP
    WHERE
        LATEST_FLAG = 1
)
SELECT
    DISTINCT DISTRIBUTION_ID,
    PANEL_ID,
    CHANNEL_TYPE_ID,
    COUNTRY_ID,
    CALENDAR_ID AS CALENDAR_ID,
    WEIGHTED_SELL_OUT * 100 WEIGHTED_SELL_OUT,
    NUMERIC_SELL_OUT * 100 NUMERIC_SELL_OUT,
    INSERTED_TIMESTAMP
FROM CTE_DIST_SRC S
LEFT JOIN DWH_MARKET_SALES.DIM_CHANNEL_TYPE CT 
	ON TRIM(UPPER(S.CHANNEL_TYPE)) = TRIM(UPPER(CT.CHANNEL_TYPE_NM))
WHERE S.DISTRIBUTION_ID IN (
        SELECT DISTINCT DISTRIBUTION_ID
        FROM DWH_MARKET_SALES.DIM_SOURCE_PRODUCT
        WHERE COUNTRY ILIKE '%PERU%'
            AND DISTRIBUTION_ID IS NOT NULL
);

--TO QUERY VIEW, YOU CAN USE SAME LIKE QUERYING TABLE.
SELECT * FROM DF_CHC_MARKET_DEV.PSA_PE.VW_PSA_PE_DIST_FCT_MTH;

--DELETE VIEW:
DROP VIEW DF_CHC_MARKET_DEV.PSA_PE.VW_PSA_PE_DIST_FCT_MTH_TEST;

--When defining a view, you have the option of providing your own names for the view columns, rather than having them derived from the underlying tables.
--You can also use views and tables in the same query.
create or replace view DF_CHC_MARKET_DEV.PSA_PE.VW_PSA_PE_DIST_FCT_MTH_TEST(
	DISTRIBUTION_ID, -- PROVIDING DIFFERNT NAME
	PANEL_ID,-- PROVIDING DIFFERNT NAME
	CHANNEL_TYPE_ID,-- PROVIDING DIFFERNT NAME
	COUNTRY_ID,-- PROVIDING DIFFERNT NAME
	CALENDAR_ID,-- PROVIDING DIFFERNT NAME
	WEIGHTED_SELL_OUT,-- PROVIDING DIFFERNT NAME
	NUMERIC_SELL_OUT,-- PROVIDING DIFFERNT NAME
	INSERTED_TS -- PROVIDING DIFFERNT NAME
) as 
WITH CTE_DIST_SRC AS 
(
    SELECT 
        DISTINCT MD5(UPPER(TRIM(COUNTRY)) || IFNULL(NULLIF(LTRIM(TRIM(GMID), '0'), ''), 'UNKNOWN')) AS DISTRIBUTION_ID,
        CAST(MD5(UPPER(COUNTRY || PANEL || CHANNEL)) AS VARCHAR(1000)) AS PANEL_ID,
        CHANNEL_TYPE,
        (
            SELECT
                DISTINCT COUNTRY_ID
            FROM
                DWH_MARKET_SALES.DIM_COUNTRY
            WHERE
                UPPER(COUNTRY) = 'PERU'
        ) AS COUNTRY_ID,
        CALENDAR_ID,
        WEIGHTED_SELL_OUT,
        NUMERIC_SELL_OUT,
        CURRENT_TIMESTAMP AS INSERTED_TS
    FROM
        PSA_PE.PSA_PE_DIST_MTH_TRANSP
    WHERE
        LATEST_FLAG = 1
)
SELECT
    DISTINCT DISTRIBUTION_ID,
    PANEL_ID,
    CHANNEL_TYPE_ID,
    COUNTRY_ID,
    CALENDAR_ID AS CALENDAR_ID,
    WEIGHTED_SELL_OUT * 100 WEIGHTED_SELL_OUT,
    NUMERIC_SELL_OUT * 100 NUMERIC_SELL_OUT,
    INSERTED_TS
FROM CTE_DIST_SRC S
LEFT JOIN DWH_MARKET_SALES.DIM_CHANNEL_TYPE CT 
	ON TRIM(UPPER(S.CHANNEL_TYPE)) = TRIM(UPPER(CT.CHANNEL_TYPE_NM))
WHERE S.DISTRIBUTION_ID IN (
        SELECT DISTINCT DISTRIBUTION_ID
        FROM DWH_MARKET_SALES.DIM_SOURCE_PRODUCT
        WHERE COUNTRY ILIKE '%PERU%'
            AND DISTRIBUTION_ID IS NOT NULL);
--view definition shows the column names specified in the create view statement, rather than the associated column names from the Person table:

DESCRIBE PSA_PE.VW_PSA_PE_DIST_FCT_MTH;

--USING VIEWS: 
--Views can be used in queries anywhere that tables can be used, meaning that you can join views, execute subqueries against views, use them in common table expressions, etc.

SELECT * PSA_PE.VW_PSA_PE_DIST_FCT_MTH AS VW;

--WHY TO USE VIEWS: 
--DATA SECURITY: RESTRICTING COLOUMN ACESS: YOU CAN SIMPLY DEFINE THE COLOUMNS ONLY WANT TO USE.
--RESTRICTING ROW ACCESS: Snowflake provides secure views, which allow you to restrict access to rows based on either the database user name (via the current_user() function) or the database roles assigned to a user (via the current_role() function). The following query shows the results from these two functions in my session:

SELECT CURRENT_USER(), CURRENT_ROLE();

create secure view PSA_PE.MY_SECURE_VIEW_TEST  as
WITH ABC AS (
select case when X.channel_type like 'C%' then 'SHUBHAM.SHARMA2@SANOFI.COM' end as auth_username, X.* FROM
DF_CHC_MARKET_DEV.PSA_PE.PSA_PE_DIST_MTH_TRANSP X)

SELECT * FROM ABC
WHERE auth_username = current_user();

SELECT * FROM PSA_PE.MY_SECURE_VIEW_TEST;

--Using secure views also limits who can see the view definition; only users having the same role as the one with which the view was built will be able to retrieve the view definition from Snowflake.

SELECT GET_DDL('VIEW','PSA_PE.MY_SECURE_VIEW_TEST');

--I can retrieve the view definition because I created the view, but another user without the same role would not be successful. Hiding the view definition makes sense in that if you are creating a mechanism to restrict access to data, you should probably also limit access to the mechanism used to do so

DROP VIEW PSA_PE.MY_SECURE_VIEW_TEST;

--DATA AGGREGATION: 
--Data analysis and reporting are generally done with aggregated data, which, depending on the design of the database, can lead to some very complex queries. Rather than providing the users access to the tables, you can create views to make it seem as if data has been preaggregated.

--MATERIALIZED VIEW: 
 --Snowflake customers using the Enterprise edition have the ability to create material
-- ized views, which are essentially tables built using a view definition and then automat
-- ically refreshed via background processes. Using materialized views will generally
-- reduce computation time for queries but will incur additional storage space/fees and
-- computation fees for the upkeep of the materialized view, so it is important to con
-- sider the number of times the materialized data will be queried versus the amount of
-- data being stored and the frequency with which the data changes.
-- Creating a materialized view is a simple matter of using create materialized view
-- instead of create view. Once created, Snowflake will update the stored data as
-- changes are made to the underlying tables from the view definition.

--HIDING COMPLEXITY:
--Another common use of views is to shield your user community from complex calculations or data relationships.

--CONSIDERATIONS WHEN USING VIEWS:
--when a view is created, Snowflake gathers information about the view (also known as metadata).
--using the state of the database at that point. If you later add, modify, or drop columns in one of the tables used by the view’s query, the view definition will not be automatically changed.
--if you drop a column that is used by a view, the view will be internally marked as invalid, and you will need to modify the view definition and re-create the view before it can be used again.

--want to build a view to be used instead of a table, I generally add the suffix _vw to all of my view names, which allows me to have a table named abc and a view named abc_vw, which generally makes it clear to my user community what is going on.

--when you created the view. Joining two or three views with complex underlying queries can result in poor performance, which results in increased computation costs and unhappy users.

--While database performance is a broad and important topic,however,  one method to look for long-running queries in Snowflake.

select query_id, total_elapsed_time as runtime, 
         substr(query_text,1,40)
       from table(DF_CHC_MARKET_DEV.information_schema.query_history())
       where total_elapsed_time > 5000
       order by start_time;