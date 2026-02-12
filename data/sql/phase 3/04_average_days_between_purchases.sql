-- Task 4 – Average Days Between Purchases 

WITH clean_data AS  -- CTE: Prepare data for further manipulations
( 
    SELECT DISTINCT -- this applied to date excludes multiple purchases on the same day
        client_id,
        DATE(date) AS transaction_day  -- Removes time component for day calculations        
        FROM transactions_data
        WHERE amount NOT LIKE '-%'  -- Exclude refunds
),

lagging AS -- CTE: lags a date coloumn for calculation of days between purchases
(
    SELECT 
        client_id,
        transaction_day,
        LAG(transaction_day) OVER (PARTITION BY client_id ORDER BY transaction_day) AS previous_buy
    FROM clean_data 
)

SELECT -- Main query: calculates average day between purchases for each client
    client_id,
    AVG(DATEDIFF(transaction_day, previous_buy)) AS avg_days_between_purchases   -- Calculate average amount of days between purchases
FROM lagging
GROUP BY client_id
ORDER BY client_id;