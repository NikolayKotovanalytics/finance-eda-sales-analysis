-- Task 6 Revenue vs Frequency Matrix

WITH clean_data AS  -- CTE: Prepare data for further manipulations
( 
    SELECT
        client_id,
        DATE(date) AS transaction_date,  -- Removes day and time component for monthly calculations
        CAST(REPLACE(amount, '$', '') AS DECIMAL(10,2)) AS amount_cleaned -- Removes dollar sign and converts value to DECIMAL for calculations
    FROM transactions_data 
    WHERE amount NOT LIKE '-%' -- Exclude refunds   
),

customer_lifetime AS -- CTE: Customer lifetime window + total purchases
( 
    SELECT
        client_id,
        COUNT(*) AS total_purchases, -- Calculates total purchases for next step - frequency calculations
        MIN(transaction_date) AS first_month,
        MAX(transaction_date) AS last_month,
        SUM(amount_cleaned) AS total_revenue -- Calculates total revenue for next step 
    FROM clean_data
    GROUP BY client_id
),

lifetime_frequency AS --CTE: Converts lifetime window into an active period of each customer
( 
    SELECT
        client_id,
        total_purchases,
        TIMESTAMPDIFF(MONTH, first_month, last_month) + 1 AS lifetime_months, -- Active period of a customer, Calculate number of months between the first and last purchases which is a time while a client was active. Add 1 because it starts counting months with "0".
        total_revenue
    FROM customer_lifetime
),

client_labels AS  -- CTE: label clients by frequency and revenue groups for the next step of grouping them in the matrix 
(
    SELECT 
        client_id,
        CASE        -- Labelling based on frequency
            WHEN total_purchases / lifetime_months > AVG(total_purchases / lifetime_months) OVER () THEN 'High frequency' 
            ELSE 'Low frequency'
        END AS client_purchase_frequency,
        CASE        -- Labelling based on revenue
            WHEN total_revenue > AVG(total_revenue) OVER () THEN 'High revenue'
            ELSE 'Low revenue'
        END AS client_revenue
    FROM lifetime_frequency
)

SELECT -- Main Query: Final Revenue vs Frequency Matrix
    client_purchase_frequency,
    client_revenue,
    COUNT(*) AS clients_number, -- calculate number of clients in each group
    ROUND(100 * COUNT(*) / SUM(COUNT(*)) OVER (), 2) AS share_pct -- calculates share percentage of the group;
FROM client_labels
GROUP BY client_purchase_frequency, client_revenue;