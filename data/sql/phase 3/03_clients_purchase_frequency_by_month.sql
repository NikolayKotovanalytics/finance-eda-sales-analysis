-- Task 3 – Client Monthly Purchase Frequency 

WITH clean_data AS  -- CTE: Prepare data for further manipulations
( 
    SELECT
        client_id,
        DATE_FORMAT(date, '%Y-%m-01') AS transaction_month  -- Removes day and time component for monthly calculations
    FROM transactions_data 
    WHERE amount NOT LIKE '-%' -- Exclude refunds   
),

customer_lifetime AS ( -- CTE: Customer lifetime window + total purchases
    SELECT
        client_id,
        COUNT(*) AS total_purchases, -- Calculate total purchases for next step - frequency calculations
        MIN(transaction_month) AS first_month,
        MAX(transaction_month) AS last_month
    FROM clean_data
    GROUP BY client_id
),

lifetime_frequency AS ( -- Convert lifetime window into an active period of each customer
    SELECT
        client_id,
        total_purchases,
        (
            TIMESTAMPDIFF(                      -- Calculate number of months between the first and last purchases which is a time while a client was active. Add 1 because it starts counting months with "0".
                MONTH,
                STR_TO_DATE(first_month, '%Y-%m-%d'), -- Converts to DATE format DATE_FORMAT, because TIMESTAMPDIFF requires it. Note, in the first CTE DATE_FORMAT() returns string value and MIN/MAX() work with strings
                STR_TO_DATE(last_month, '%Y-%m-%d')
            ) + 1
        ) AS lifetime_months -- Active period of a customer
    FROM customer_lifetime
)

SELECT -- Main query: Grouping clients by frequency of their orders
    CASE -- Note: the threshholds are custom because the used dataset is synthetic
        WHEN total_purchases / lifetime_months > 210 THEN 'Very High frequency' -- Group with suspiciously active clients. Worth checking for fraud
        WHEN total_purchases / lifetime_months > 150 THEN 'High frequency' -- Most loyal clients
        WHEN total_purchases / lifetime_months > 90 THEN 'Medium frequency' -- Loyal clients
        WHEN total_purchases / lifetime_months > 30 THEN 'Low frequency' -- Casual clients
        ELSE 'Very Low frequency' -- Rare clients
    END AS client_purchase_frequency,
    COUNT(*) AS customer_count -- counts number of clients in each group
FROM lifetime_frequency
GROUP BY client_purchase_frequency;