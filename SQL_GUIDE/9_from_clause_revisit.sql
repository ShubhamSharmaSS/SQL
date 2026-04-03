-------##### CHAPTER - 9 FROM CLAUSE REVISITED ------
--Hieriarchical Queries
--Some data is hierarchical in nature, such as a family tree, where each data point has a relationship with other data points above and/or below. 

WITH EMPLOYEE (EMPID, EMP_NAME, MGR_EMPID) AS (
    SELECT 1001, 'Bob Smith',     NULL -- higest in position
    UNION ALL SELECT 1002, 'Susan Jackson', 1001
    UNION ALL SELECT 1003, 'Greg Carpenter', 1001
    UNION ALL SELECT 1004, 'Robert Butler', 1002
    UNION ALL SELECT 1005, 'Kim Josephs',   1003
    UNION ALL SELECT 1006, 'John Tyler',    1004 -- lowest in position
)

--if the company was very large with a deep and complex management structure. A more general approach is needed, and for these purposes Snowflake provides the connect by clause to traverse hierarchical relationships.
select emp_name,empid from employee 
start with emp_name = 'John Tyler' and EMPID = 1006
connect by prior mgr_empid = empid; -- going up in hirerchiy.. lower to higher.. --pay attention to connection of coloumn
--The start by clause describes which row to start from, and the connect by clause describes how to traverse from one row to the next. The prior keyword is used to denote the current level.The nice thing about this approach is that it can handle any number of levels in the hierarchy, so the query stays the same no matter how many management levels there are.
WITH EMPLOYEE (EMPID, EMP_NAME, MGR_EMPID) AS (
    SELECT 1001, 'Bob Smith',     NULL -- higest in position
    UNION ALL SELECT 1002, 'Susan Jackson', 1001
    UNION ALL SELECT 1003, 'Greg Carpenter', 1001
    UNION ALL SELECT 1004, 'Robert Butler', 1002
    UNION ALL SELECT 1005, 'Kim Josephs',   1003
    UNION ALL SELECT 1006, 'John Tyler',    1004 -- lowest in position
)
select emp_name,empid from employee 
start with emp_name = 'Bob Smith' and EMPID = 1001
connect by prior  empid = mgr_empid ; -- going down in hirerchiy.. higher to lower --pay attention to connection of coloumn

--If you want to see these relationships, you can use the built in function sys_connect_by_path() to see a description of the entire hierarchy up to that point:
WITH EMPLOYEE (EMPID, EMP_NAME, MGR_EMPID) AS (
    SELECT 1001, 'Bob Smith',     NULL -- higest in position
    UNION ALL SELECT 1002, 'Susan Jackson', 1001
    UNION ALL SELECT 1003, 'Greg Carpenter', 1001
    UNION ALL SELECT 1004, 'Robert Butler', 1002
    UNION ALL SELECT 1005, 'Kim Josephs',   1003
    UNION ALL SELECT 1006, 'John Tyler',    1004 -- lowest in position
)
select emp_name,
sys_connect_by_path(emp_name, ' -> ') management_path
       from employee
         start with emp_name = 'Bob Smith'
         connect by prior empid = mgr_empid;

--TIME TRAVEL: Snowflake’s Time Travel feature allows you to execute queries that will see your data as it was at a certain time in the past. To do so, you can use the at keyword to specify either a specific time or an offset from the current time, and Snowflake will retrieve the data as it was at that point in time.

delete from STG_EG.STG_EG_SALES_NATIONAL_MTH -- DELETING A RECORD
where channel = 'RETAIL' AND
ATC4 = 'A01A0 STOMATOLOGICALS' AND
CORPORATION = 'ADCO*' AND
MANUFACTURER = 'ADCO' AND
PRODUCT = 'HEXITOL' AND
MOLECULE = 'CHLORHEXIDINE' AND
PACK = 'MOUTH WASH 100ML' AND
LAUNCH_DATE = '1990/04';

SELECT * FROM STG_EG.STG_EG_SALES_NATIONAL_MTH AT(OFFSET => -3600); --  -3600 = 1 HOUR BACK

--One of the uses of this feature would be to identify which rows were inserted over a particular time span. This next query uses the minus operator to compare the current state of the table with the state one hour ago.
SELECT * FROM STG_EG.STG_EG_SALES_NATIONAL_MTH AT(OFFSET => -3600) -- CONTAINS MORE ROW 1 HR BACK
MINUS
SELECT * FROM STG_EG.STG_EG_SALES_NATIONAL_MTH ;--CONTAINS LESS ROW AS WE HAVE DELETED ONE ROW FROM STG_EG.STG_EG_SALES_NATIONAL_MTH -- IT IWLL GIVE YOU THE CHANGES BETWEEN SAME TABLE AT DIFFERENT TIME.--
--default for Time Travel is one day in the past, but if you are using Snowflake’s Enterprise edition you can run queries that see the state of the data up to 90 days in the past.


--PIVOT QUERIES: Pivoting is a common operation in data analysis, where rows of data need to be pivoted into columns.


WITH EMPLOYEE (EMPID, EMP_NAME, MGR_EMPID) AS (
    SELECT 1001, 'Bob Smith',     NULL
    UNION ALL SELECT 1002, 'Susan Jackson', 1001
    UNION ALL SELECT 1003, 'Greg Carpenter', 1001
    UNION ALL SELECT 1004, 'Robert Butler', 1002
    UNION ALL SELECT 1005, 'Kim Josephs',   1003
    UNION ALL SELECT 1006, 'John Tyler',    1004
)
SELECT *
FROM EMPLOYEE
PIVOT (
    COUNT(EMPID) FOR MGR_EMPID IN (1001, 1002, 1003, 1004)
) AS P;

--Snowflake also provides an unpivot clause that performs the opposite transformation (pivot data from columns into rows).

WITH EMPLOYEE (EMPID, EMP_NAME, MGR_EMPID) AS (
    SELECT 1001, 'Bob Smith',     NULL
    UNION ALL SELECT 1002, 'Susan Jackson', 1001
    UNION ALL SELECT 1003, 'Greg Carpenter', 1001
    UNION ALL SELECT 1004, 'Robert Butler', 1002
    UNION ALL SELECT 1005, 'Kim Josephs',   1003
    UNION ALL SELECT 1006, 'John Tyler',    1004
),
EMP_CAST AS (
    SELECT 
        EMPID,
        EMP_NAME::VARCHAR AS EMP_NAME, --because UNPIVOT requires all columns in the UNPIVOT list to have the SAME data type.
        MGR_EMPID::VARCHAR AS MGR_EMPID --because UNPIVOT requires all columns in the UNPIVOT list to have the SAME data type.
    FROM EMPLOYEE
)
SELECT *
FROM EMP_CAST
UNPIVOT (
    VALUE FOR FIELD_NAME IN (EMP_NAME, MGR_EMPID)
) AS U;

--RANDOM SAMPLING:
--Sometimes it is useful to retrieve a subset of a table for tasks such as testing, and you want the subset to be different every time. For this purpose, Snowflake includes the sample clause to allow you to specify what percent of the rows you would like returned. 

SELECT * FROM  dwh_market_sales.fct_sales_national_mth SAMPLE(0.1); 
-- 0.1 is specified as the probability, meaning that there should be a 0.1% chance that any particular row is included in the result set. If you run this query multiple times, you will get a different set of rows (and potentially a different number of rows) each time.

SELECT * FROM  dwh_market_sales.fct_sales_national_mth SAMPLE(218 ROWS); -- exact number of rows, you can specify a row count you will get a different set of rows (and potentially a different number of rows) each time.

--FULL OUTER JOIN:
-- If you want the result set to include both every order and every customer, you can specify a full outer join instead of a left outer join
select orders.ordernum, orders.custkey, customer.custname
        from
         (values (990, 101), (991, 102),
                 (992, 101), (993, 104))
          as orders (ordernum, custkey)
full outer join
         (values (101, 'BOB'), (102, 'KIM'), (103, 'JIM'))
        as customer (custkey, custname)
        on orders.custkey = customer.custkey;

--However, Jim’s custkey value in the result set is null because orders.custkey is specified in the select clause. This can be fixed by using the nvl() function to return the custkey value from either the orders or customer data sets:
--When you specify full outer joins, you will generally want to use nvl() for any columns that can come from either of the tables.

select orders.ordernum, 
nvl(orders.custkey, customer.custkey) as custkey,
          customer.custname
        from
         (values (990, 101), (991, 102),
                 (992, 101), (993, 104))
          as orders (ordernum, custkey)
        full outer join
         (values (101, 'BOB'), (102, 'KIM'), (103, 'JIM'))
          as customer (custkey, custname)
        on orders.custkey = customer.custkey;

--LATERAL JOIN:
--Snowflake allows a subquery in the from clause to reference another table in the same from clause, which means that the subquery acts like a correlated subquery. This is done by specifying the lateral keyword


SELECT 
    VD.*,
    X.LC_60
FROM PSA_EG.VW_PSA_EG_DIM_PRODUCT_MTH VD
    INNER JOIN LATERAL (
        SELECT F.LC_60
        FROM dwh_market_sales.fct_sales_national_mth F
        WHERE F.SOURCE_PRODUCT_ID = VD.SOURCE_PRODUCT_ID
          AND F.CALENDAR_ID = 202512
        LIMIT 1
    ) X
WHERE VD.COUNTRY = 'EGYPT';

--TABLE LITERALS: 
--Snowflake allows table names to be passed into a query as a string using the table() Function. 
SELECT * FROM TABLE('PSA_EG.VW_PSA_EG_DIM_PRODUCT_MTH');
--things become more interesting when you are writing scripts.
--with a script or stored procedure , the table literals passed into the table() function will be evaluated at runtime, allowing for some very flexible code.
--you can use the table() function to generate a table name from a string literal, and that the string literals can be generated programmatically.