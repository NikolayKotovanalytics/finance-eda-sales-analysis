-- Task 2 Month-over-Month (MoM) Revenue Change

WITH clean_data AS -- CTE: Prepare data for further manipulations
      (SELECT
       DATE_FORMAT(date, '%Y-%m-01') as transaction_month,      -- changes date to year-month-01 for subsequent grouping by month 
       CAST(REPLACE(amount, '$', '') AS DECIMAL(10,2)) AS amount_cleaned -- removes dollar sign and formats to decimal for subsequent calc
      FROM transactions_data
      ),
mom AS -- CTE: calculates monthly revenue and uses LAG function to create a column for MoM calculations
      (
        SELECT  
        transaction_month,
        SUM(amount_cleaned) as monthly_revenue,
        LAG(
              SUM(amount_cleaned)) OVER (
                  ORDER BY transaction_month
                  ) as previous_month_revenue
      FROM clean_data
      GROUP BY transaction_month
      )
SELECT  -- MAIN Query: calculates MoM and MoM change percentage
  transaction_month,
  monthly_revenue,
  previous_month_revenue,
  monthly_revenue - previous_month_revenue as mom_revenue_change, -- MoM change
  ROUND(
          100 * 
          (monthly_revenue - previous_month_revenue)
          / previous_month_revenue,
          3  
        ) as mom_change_pct -- MoM change compared to previous month
FROM mom
ORDER BY transaction_month;