-- Task 5 Seasonality Analysis (Monthly Pattern)

WITH clean_data AS -- CTE: Prepare data for further manipulations
      (SELECT
       DATE_FORMAT(date, '%Y-%m-01') as transaction_month,      -- changes date to year-month-01 for subsequent grouping by month 
       CAST(REPLACE(amount, '$', '') AS DECIMAL(10,2)) AS amount_cleaned -- removes dollar sign and formats to decimal for subsequent calc
      FROM transactions_data      
      ),
monthly AS     -- CTE: Rank every month of every year by revenue
      (SELECT  
          transaction_month,
          SUM(amount_cleaned) as monthly_revenue
      FROM clean_data
      GROUP BY transaction_month
      )
SELECT    -- Main Query: final calculation of avg per month from 2010 till 2019 and rank of months by avg revenue
    MONTHNAME(transaction_month) as month,
    AVG(monthly_revenue) as avg_month_revenue, -- final calculation
    RANK() OVER (ORDER BY AVG(monthly_revenue) DESC) as month_revenue_rank -- ranking starting with largest revenue value
FROM monthly
GROUP BY month
ORDER BY month_revenue_rank;
