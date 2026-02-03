-- Task 7 Refund Trend Over Time

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
        COUNT(*) AS transactions_per_month,   -- counts total number of transactions per month
        COUNT(
              CASE
                 WHEN amount_cleaned < 0 THEN 1 
                 ELSE 0
              END) AS refund_transactions, -- counts number of refund transactions per month
        SUM(
          CASE 
              WHEN amount_cleaned > 0 THEN amount_cleaned
              ELSE 0
          END) AS monthly_income, -- counts total monthly income
        SUM(
          CASE 
              WHEN amount_cleaned < 0 THEN amount_cleaned * -1
              ELSE 0
          END
        )  AS monthly_refunds   -- counts total monthly refunds and converts them to a positive value
      FROM clean_data
      GROUP BY transaction_month
      )
SELECT -- Main Query: final calculation of refund and income percentage ratio per month
  transaction_month,
  monthly_refunds,
  ROUND (
        100 * monthly_refunds / (monthly_income + monthly_refunds), -- note: monthly refunds were converted to positive value during previous step
        2
        ) AS refund_ratio_pct,  -- final calculation of refund value ratio percentage of total income
  ROUND (
        100 * refund_transactions / transactions_per_month,
        2
        ) AS refund_transactions_ratio_pct -- final calculation of refund transactions ratio percentage of total transactions
FROM monthly
ORDER BY transaction_month;
