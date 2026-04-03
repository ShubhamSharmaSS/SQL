-------##### CHAPTER - 11 TRANSACTIONS ------
--transactions, which are the mechanism used to group a set of SQL statements together such that either all or none of the statements succeed.

--WHAT IS A TRANSACTION? : A transaction is a series of SQL statements within a single database session, with the goal of having all of the changes either applied or undone as a unit. 

----EXPLICIT AND IMPLICIT TRANSACTION: to start a transaction by issuing the begin transaction statement,after which all following SQL statements will be considered part of the transaction until you issue a commit or rollback statement. This is known as an explicit transaction because you are instructing Snowflake to start a transaction.
BEGIN TRANSACTION;

DELETE FROM DF_CHC_MARKET_DEV.STG_EG.STG_EG_SALES_NATIONAL_MTH where 
1 = CASE WHEN NOT EXISTS 
(SELECT 1 FROM  DF_CHC_MARKET_DEV.STG_EG.STG_EG_SALES_NATIONAL_MTH WHERE LC_60 = NULL OR LC_60 = '0') THEN 1 END;

COMMIT;
--commit statement applied changes to the database; if I had issued a rollback instead, both changes would have been undone.
--If you execute an insert, update, delete, or merge statement without first starting a transaction, then a transaction is automatically started for you by Snowflake. This is known as an implicit transaction because you did not start the transaction yourself.

--To check if autocommit is enabled for your session, you can use the show parameters command:
SHOW PARAMETERS LIKE 'AUTOCOMMIT';
--If your session is not in autocommit mode, and you modify the database without first issuing begin transaction.
--to enable or disable autocommit in your session, you can use the alter session command;
ALTER SESSION SET AUTOCOMMIT = TRUE;

--adopt the following best practices:
-- • Explicitly start transactions using begin transaction.
-- • Resolve all transactions using commit or rollback prior to ending session.
-- • Explicitly end any open transactions prior to issuing DDL commands

--FINDING OPEN TRANSACTIONS: Snowflake supplies the show transactions statement to list any open transactions.

BEGIN TRANSACTION;

DELETE FROM DF_CHC_MARKET_DEV.STG_EG.STG_EG_SALES_NATIONAL_MTH where 
1 = CASE WHEN NOT EXISTS 
(SELECT 1 FROM  DF_CHC_MARKET_DEV.STG_EG.STG_EG_SALES_NATIONAL_MTH WHERE LC_60 = NULL OR LC_60 = '0') THEN 1 END;

SHOW TRANSACTIONS; -- IT WILL SHOW YOU ID,USER,SESSION,NAME,START TIMESTAMP, STATE (RUNNING/ABORTED) AND SCOPE.

--ISOLATION LEVELS: The concept of an isolation level is pertinent to a discussion of transactions because isolation deals with when changes are visible to other sessions.
--Some database servers provide multiple options, including a dirty read option, which allows one session to see uncommitted changes from other sessions. Snowflake, however, only allows a statement to see committed changes, so Snowflake is said to have an isolation level of read committed. This extends throughout the execution of the statement, so even if a query takes an hour to complete, the server must guarantee that no changes made after the statement began executing will be visible to the query.
--SQL statements will see uncommitted changes made within the same transaction, but only committed changes made by other transactions. Also, multiple statements in the same transaction may see different views of the data as other transactions commit their changes.

--LOCKING: 
-- All database servers use locks to prevent multiple sessions from modifying the same data. If one user updates a row in a table, a lock is held until the transaction ends, which protects against another transaction modifying the same row. However, there are different levels, or granularities, of locking:
-- • Table locks, where an entire table is locked when any row is modified
-- • Page locks, where a subset of a table’s rows are locked (rows in the same physical
-- page or block)
-- • Row locks, where only the modified rows are locked.

--Snowflake’s locking scheme is a bit harder to nail down but lies somewhere between table-level and page-level locking. Snowflake automatically breaks tables into pieces, called micropartitions, which hold between 50MB and 500MB of uncompressed data.If multiple transactions attempt to modify or delete data in the same micropartition,one session will be blocked and must wait until the other session’s transaction completes.

--LOCK WAIT TIME:
--When a session is blocked waiting for a lock to be released, it will wait for a configurable amount of time and then fail if the lock has not been released. The maximum number of seconds can be set using the lock_timeout parameter, which can be set at the session level:

ALTER SESSION SET LOCK_TIMEOUT = 600; --IT WILL KEEP LOCK WAIT TIME TO 10 MINS

--This statement sets the maximum lock wait to 10 minutes. While it is possible to set this value to 0, it is not recommended since it will cause an error to be thrown every time a lock is encountered. The default timeout is 12 hours.

--DEADLOCKS:
--A deadlock is a scenario where session A is waiting for a lock held by session B, and session B is waiting for a lock held by session A.
--this is generally a rare occurrence, it does happen, and database servers need to have a strategy to resolve dead locks. 
--Snowflake identifies a deadlock, it chooses the session having the most recent statement to be the victim, allowing the other transaction to progress.
--setting the lock_timeout parameter to a lower value might help resolve these situations faster. If you encounter a deadlock situation and identify a transaction that you would like to abort, you can use the system function system$abort_transaction() to do so. 

--TRANSACTION AND STORE PROCEDURES: 
--A stored procedure is a compiled program written using Snowflake’s Scripting language.
-- • A stored procedure cannot end a transaction started outside of the stored procedure.
-- • If a stored procedure starts a transaction, it must also complete it by issuing either a commit or rollback. No transaction started within a stored procedure can be unresolved when the stored procedure completes.
-- • A stored procedure can contain 0, 1, or several transactions, and not all statements within the stored procedure must be within a transaction.