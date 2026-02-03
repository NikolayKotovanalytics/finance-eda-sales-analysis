-- TASK 10 Revenue per Active Customer

WITH clean_data AS -- CTE: Prepare data for further manipulations
      (SELECT
            client_id,
            DATE_FORMAT(date, '%Y-%m-01') as transaction_month,      -- changes date to year-month-01 for subsequent grouping by month 
            CAST(REPLACE(amount, '$', '') AS DECIMAL(10,2)) AS amount_cleaned -- removes dollar sign and formats to decimal for subsequent calc
       FROM transactions_data
      )
SELECT -- Main Query: calculation of revenue per unique active customers each month
      transaction_month as Date,
      ROUND(
            SUM(CASE WHEN amount_cleaned > 0 THEN amount_cleaned ELSE 0 END) -- ignore refunds to avoid distorting per-customer value
             / COUNT(DISTINCT client_id), 2) as revenue_per_customer -- final count of a gross revenue value per active customer
FROM clean_data
GROUP BY transaction_month
ORDER BY transaction_month;