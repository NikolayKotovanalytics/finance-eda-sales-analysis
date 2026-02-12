-- Task 1 – Top Clients by Revenue
WITH clean_data AS -- CTE: Prepare data for further manipulations
        (Select 
            client_id,
            CAST(REPLACE(amount, '$', '') AS DECIMAL(10,2)) AS amount_cleaned -- removes dollar sign and formats to decimal for subsequent calc
            FROM transactions_data            
        ),

ranking AS  -- CTE: Ranking clients based on their revenue
    (SELECT 
        client_id,
        SUM(amount_cleaned) as client_total_revenue,
        ROW_NUMBER() OVER (ORDER BY SUM(amount_cleaned) DESC) as revenue_rank
    FROM clean_data
    GROUP BY client_id
    )
    
SELECT       -- Main Query: filtering data to reveal TOP 20 clients based on the revenue 
    client_id AS TOP_20_clients,
    client_total_revenue,
    revenue_rank
FROM ranking
WHERE revenue_rank < 21 -- Filter TOP 20  clients based on the revenue
ORDER BY revenue_rank;
