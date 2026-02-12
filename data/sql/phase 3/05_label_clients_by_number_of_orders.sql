-- TASK 5 Label clients by their total number of orders

WITH clean_data AS  -- CTE: Calculate total number of orders per customer excluding refunds
( 
    SELECT 
        client_id,
        COUNT(*) AS client_total_orders  -- calculates total orders per customer     
        FROM transactions_data
        WHERE amount NOT LIKE '-%'  -- Exclude refunds
        GROUP BY client_id
), 

labelling AS -- CTE: Label clients by total number of their orders
(
    SELECT 
        CASE
            WHEN client_total_orders > 9999 THEN 'Lots of orders' 
            WHEN client_total_orders > 999 THEN 'Thousands of orders'
            WHEN client_total_orders > 99 THEN 'Hundreds of items'
            ELSE 'Few orders' -- Note: 0 Customers with such low count are present in the used dataset
        END AS clients_category,
        COUNT(*) AS clients_number -- counts number of customers in each group
    FROM  clean_data
    WHERE client_total_orders > 0 -- excludes customers with 0 purchases
    GROUP BY clients_category
)

SELECT  -- Main Query: Shows labelled groups and number of clients in these groups and their respective share
    clients_category,
    clients_number,
    ROUND(100 * clients_number / SUM(clients_number) OVER (), 2) AS share_pct -- calculates share percentage of the group
FROM labelling;
