-- Task 3 Rolling 3-Month Revenue to smooth shirt-term volatility

WITH clean_data AS -- CTE: Prepare data for further manipulations
      (SELECT
        DATE_FORMAT(date, '%Y-%m-01') as transaction_month,      -- changes date to year-month-01 for subsequent grouping by month 
        CAST(REPLACE(amount, '$', '') AS DECIMAL(10,2)) AS amount_cleaned -- removes dollar sign and formats to decimal for subsequent calc
      FROM transactions_data
      )
SELECT  -- MAIN Query: calculates monthly revenue and a 3-month revenue using a window function for code-brevitry
    transaction_month,
    SUM(amount_cleaned) as monthly_revenue, -- monthly revenue
    SUM(SUM(amount_cleaned)) OVER (
        ORDER BY transaction_month 
        ROWS BETWEEN 2 PRECEDING AND CURRENT ROW
        ) as rolling_3mnth_revenue  -- final calculation of rolling revenue 
FROM clean_data
GROUP BY transaction_month
ORDER BY transaction_month;
