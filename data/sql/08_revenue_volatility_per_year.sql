-- Task 8 Revenue Volatility by Year

WITH clean_data AS  -- CTE: Prepare data for further manipulations
      (SELECT
             DATE(date) AS tr_date, -- change to standard date format
             CAST(REPLACE(amount, '$', '') AS DECIMAL(10,2)) AS amount_cleaned
      FROM transactions_data
      ),
monthly AS        -- CTE: Prepare data for further manipulations
      (SELECT
            YEAR(tr_date) AS ds_year,     -- get only 
            MONTH(tr_date) AS ds_month,
            SUM(amount_cleaned) AS monthly_revenue
      FROM clean_data
      GROUP BY YEAR(tr_date), MONTH(tr_date)  -- to get SUM by month
      )
SELECT       -- Main Query: final calculation of monthly revenue volatility per year
    ds_year AS Year,
    ROUND(AVG(monthly_revenue), 2) AS avg_monthly_revenue, -- calculates AVG monthly revenue per year
    ROUND(STDDEV_POP(monthly_revenue), 2) AS revenue_volatitlity -- revenue volatility
FROM monthly
GROUP BY ds_year
ORDER BY ds_year;