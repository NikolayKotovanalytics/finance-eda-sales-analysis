-- Task 8 Dormant client reactivation spike

WITH clean_data AS -- CTE: Prepare data for further manipulations
( 
    SELECT
        client_id,
        DATE(date) AS transaction_date, -- Removes time for date calculations
        LAG(DATE(date)) OVER (
            PARTITION BY client_id 
            ORDER BY DATE(date)
        ) AS previous_date, -- Get a previous transaction date for each customer to calculate dormancy
        CAST(REPLACE(amount, '$', '') AS DECIMAL(10,2)) AS amount_cleaned -- Clean amount for calculations and convert to DECIMAL
    FROM transactions_data
),
client_total_revenue AS  -- CTE: calculates total revenue per customer
(
    SELECT
        client_id,
        SUM(CASE WHEN amount_cleaned > 0 THEN amount_cleaned ELSE 0 END) AS total_revenue -- Sum revenue per client without refunds
    FROM clean_data
    GROUP BY client_id
),
reactivation AS -- CTE: Calculate reactivation revenue
(
    SELECT
        client_id,
        SUM(amount_cleaned) AS reactivation_revenue -- Sum revenue for transactions that are considered reactivations (after dormancy)
    FROM clean_data
    WHERE amount_cleaned > 0 AND DATEDIFF(transaction_date, previous_date) > 60 -- Filter revenue for reactivated customers
    GROUP BY client_id
)
SELECT -- Main query: finds customers with reactivation revenue spike 
    client_id,
    reactivation_revenue
FROM reactivation
WHERE reactivation_revenue > (SELECT AVG(total_revenue) FROM client_total_revenue) -- Filters revenues greater than overall avg total revenue per client
ORDER BY reactivation_revenue DESC;
