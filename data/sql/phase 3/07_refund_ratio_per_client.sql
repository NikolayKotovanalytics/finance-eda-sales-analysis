-- Task 7 Refund ratio per client

WITH clean_data AS  -- CTE: Prepare data for further manipulations
(
    SELECT 
        client_id,
        CAST(REPLACE(amount, '$', '') AS DECIMAL(10,2)) AS amount_cleaned -- Removes dollar sign and converts value to DECIMAL for calculations
    FROM transactions_data
),

precalculus AS -- CTE:  Calculate total spent and total refunds per client
(
    SELECT 
        client_id,
        SUM(CASE WHEN amount_cleaned > 0 THEN amount_cleaned ELSE 0 END) AS total_spending, -- Calculates total spending
        SUM(CASE WHEN amount_cleaned < 0 THEN amount_cleaned ELSE 0 END) AS total_refund -- Calculates total refunds
    FROM clean_data
    GROUP BY client_id
),

calculus AS -- CTE:  Calculate refunds share per client
(
    SELECT 
        client_id,
        total_spending,
        total_refund,
        100 * -1 * total_refund / total_spending AS refund_ratio -- Note: positive value; calculates refund ratio as percantage of total spending
    FROM precalculus
)

SELECT -- Main Query: filter clients with high refunds prioritize these with high spending
    client_id AS clients_with_refunds_over_33pct, -- Top clients have suspicious amount of refunds
    total_spending,
    total_refund,
    refund_ratio
FROM calculus
WHERE refund_ratio > 33 -- Filters for high refunds
ORDER BY total_spending DESC, refund_ratio DESC -- Prioritizes higher spending and higher refunds;