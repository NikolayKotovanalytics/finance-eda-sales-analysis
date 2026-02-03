-- Task 9 Active Customers Over Time

WITH clean_data AS -- CTE: Prepare data for further manipulations
      (SELECT
            client_id,
            DATE_FORMAT(date, '%Y-%m-01') as transaction_month      -- changes date to year-month-01 for subsequent grouping by month 
       FROM transactions_data
      )
SELECT -- Main Query: calculation of unique active customers in each month
      transaction_month,
      COUNT(DISTINCT client_id) as active_customers -- final count of unique customers
FROM clean_data
GROUP BY transaction_month
ORDER BY transaction_month;
