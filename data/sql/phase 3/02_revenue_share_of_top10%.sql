-- Task 2 – Revenue Share of Top 10% Clients
WITH clean_data AS  -- CTE: Prepare data for further manipulations
    (SELECT 
        client_id,
        CAST(REPLACE(amount, '$', '') AS DECIMAL(10,2)) AS amount_cleaned -- removes dollar sign and formats to decimal for subsequent calc
        FROM transactions_data
    ),

client_revenue AS -- CTE: Calculating clients total revenue
    (SELECT 
        client_id,
        SUM(amount_cleaned) AS client_total_revenue        
    FROM clean_data
    GROUP BY client_id
    ),

ranked_clients AS -- CTE: Ranking clients based on revenue
    (SELECT 
        client_id,
        client_total_revenue,
        SUM(client_total_revenue) OVER () AS total_revenue,
        CUME_DIST() OVER (ORDER BY client_total_revenue DESC) AS dist_rank -- ranking 
    FROM client_revenue
    WHERE client_total_revenue > 0 -- Exclude clients with negative or zero revenue like refunds because otherwise they appear in the end of sorted data and thus impact percentage calculations. For TOP10% we can ignore negative values.
    )

SELECT      -- Main Query: filtering data and calculating cumulative revenue share of TOP 10% clients based on revenue
    SUM(client_total_revenue) AS top10_revenue, -- Total revenue of TOP 10% clients
    MAX(total_revenue) AS total_revenue,   
    ROUND(100 * SUM(client_total_revenue) / MAX(total_revenue), 2) AS top10_revenue_share_pct   -- Calculating the total percantage share of TOP10% clients
FROM ranked_clients
WHERE dist_rank <= 0.10; -- Filters top 10% customers by revenue 
-- Result: Revenue Share of Top 10% Customers is 23.86% of total revenue
