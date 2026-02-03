-- Task 4 Yearly revenue

WITH clean_data AS -- CTE: Prepare data for further manipulations
      (SELECT
       YEAR(date) as rev_year,      -- selects year from date for subsequent grouping by year
       CAST(REPLACE(amount, '$', '') AS DECIMAL(10,2)) AS amount_cleaned -- removes dollar sign and formats to decimal for subsequent calc
      FROM transactions_data
      )
SELECT  -- Main Query: calculates revenue per year
  rev_year as year,
  SUM(amount_cleaned) as revenue_per_year -- final calculation
FROM clean_data
GROUP BY rev_year
ORDER BY rev_year;