-- Task 1 Monthly revenue

WITH clean_data AS -- CTE: Prepare data for further manipulations
      (SELECT
       DATE_FORMAT(date, '%Y-%m-01') as transaction_month,      -- changes date to year-month-01 for subsequent grouping by month 
       CAST(REPLACE(amount, '$', '') AS DECIMAL(10,2)) AS amount_cleaned -- removes dollar sign and formats to decimal for subsequent calc
      FROM transactions_data
      )
SELECT  -- Main Query: calculates revenue per month
  transaction_month,
  SUM(amount_cleaned) as monthly_revenue -- final revenue per month calculation
FROM clean_data
GROUP BY transaction_month
ORDER BY transaction_month;