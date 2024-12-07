CREATE DATABASE BANK;
USE BANK;

CREATE TABLE transactions ( 
step INT, 
type VARCHAR(20), 
amount DECIMAL(15,2), 
nameOrig VARCHAR(20), 
oldbalanceOrg DECIMAL(15,2), 
newbalanceOrig DECIMAL(15,2), 
nameDest VARCHAR(20), 
oldbalanceDest DECIMAL(15,2), 
newbalanceDest DECIMAL(15,2), 
isFraud TINYINT, 
isFlaggedFraud TINYINT );

SELECT * FROM TRANSACTIONS;

-- Problem-1: Use a recursive CTE to identify potential money laundering chains where money is transferred 
--            from one account to another across multiple steps, with all transactions flagged as fraudulent.


WITH RECURSIVE fraud_chain AS (
    SELECT 
        nameOrig AS initial_account, 
        nameDest AS next_account, 
        step, 
        amount
    FROM transactions
    WHERE isFraud = 1 AND type = 'TRANSFER'
    UNION ALL
    SELECT 
        fc.initial_account, 
        t.nameDest, 
        t.step, 
        t.amount
    FROM fraud_chain as fc
    JOIN transactions as t 
    ON fc.next_account = t.nameOrig AND fc.step < t.step
    WHERE t.isFraud = 1 AND t.type = 'TRANSFER'
)
SELECT * FROM fraud_chain;



-- Problen-2: Use a CTE to calculate the rolling sum of fraudulent transactions for each account over the last 5 steps.

WITH rolling_fraud AS (
    SELECT 
        nameOrig, 
        step, 
        SUM(isFraud) OVER (PARTITION BY nameOrig ORDER BY step ROWS BETWEEN 4 PRECEDING AND CURRENT ROW) AS fraud_rolling_sum
    FROM transactions)
SELECT 
    nameOrig, 
    step, 
    fraud_rolling_sum
FROM rolling_fraud
WHERE fraud_rolling_sum > 0;


-- Problem-3: Use multiple CTEs to identify accounts with suspicious activity, 
-- including large transfers, consecutive transactions without balance change, and flagged transactions.

WITH large_transfers AS (
    SELECT 
        nameOrig, 
        step, 
        amount
    FROM transactions
    WHERE type = 'TRANSFER' AND amount > 500000 ), 

no_balance_change AS (
    SELECT 
        nameOrig, 
        step, 
        oldbalanceOrg, 
        newbalanceOrig
    FROM transactions
    WHERE oldbalanceOrg = newbalanceOrig ),

flagged_transactions AS (
    SELECT 
        nameOrig, 
        step, 
        isFlaggedFraud
    FROM transactions
    WHERE isFlaggedFraud = 1 )

SELECT lt.nameOrig FROM large_transfers as lt
JOIN no_balance_change as nbc 
ON lt.nameOrig = nbc.nameOrig AND lt.step = nbc.step
JOIN flagged_transactions as ft 
ON lt.nameOrig = ft.nameOrig AND lt.step = ft.step;


-- Problem-4:  Write me a query that checks if the computed new_updated_Balance is the same as the actual newbalanceDest in the table. 
-- If they are equal, it returns those rows.
WITH cte AS (
    SELECT 
        amount,
        nameOrig,
        oldbalanceDest,
        newbalanceDest,
        (amount + oldbalanceDest) AS new_updated_Balance 
    FROM transactions )
SELECT * FROM cte 
WHERE new_updated_Balance = newbalanceDest;
    
    
-- Problem-5: Write a query to list transactions where oldbalanceDest or newbalanceDest is zero.

SELECT 
    nameOrig, 
    nameDest, 
    oldbalanceDest, 
    newbalanceDest, 
    amount
FROM transactions
WHERE oldbalanceDest = 0 OR newbalanceDest = 0;