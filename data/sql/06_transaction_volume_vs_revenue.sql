-- Task 6 Transaction Volume vs Revenue

WITH clean_data AS -- CTE: Prepare data for further manipulations
      (SELECT
       DATE_FORMAT(date, '%Y-%m-01') as transaction_month,      -- changes date to year-month-01 for subsequent grouping by month 
       CAST(REPLACE(amount, '$', '') AS DECIMAL(10,2)) AS amount_cleaned -- removes dollar sign and formats to decimal for subsequent calc
      FROM transactions_data
      ),
monthly AS -- CTE: Prepare data for further manipulations
      (
      SELECT 
        transaction_month,
         COUNT(*) AS transactions_per_month,
         SUM(amount_cleaned) AS monthly_revenue         
      FROM clean_data
      GROUP BY transaction_month
      )
SELECT -- Main Query: final calculation of avg transaction value per month
  transaction_month,
  transactions_per_month, 
  monthly_revenue, 
  ROUND(monthly_revenue / transactions_per_month , 2) AS avg_transaction_value -- final calculation
FROM monthly
ORDER BY transaction_month;