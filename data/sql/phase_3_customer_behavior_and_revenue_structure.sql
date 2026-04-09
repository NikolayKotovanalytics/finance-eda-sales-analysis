-- SQL EDA Phase 3: Customer Behavior & Revenue Structure
-- Note. The CTAS clean_transactions which was created in Phase 1 of EDA is used here to avoid code repetition in this Phase.
---------------------------------------------------------------------------

-- select the dataset to work with:
USE financial_transactions_dataset;

-- Task 1 – Top 20 Clients by Revenue

WITH ranking AS  -- CTE: Ranking clients based on their revenue
    (SELECT 
        client_id,
        SUM(CASE WHEN amount_cleaned > 0 THEN amount_cleaned ELSE 0 END) as client_total_revenue,  -- gross revenue focused
        ROW_NUMBER() OVER (ORDER BY SUM(amount_cleaned) DESC) as revenue_rank  -- ROW_Number function to rank clients without double or missing ranks 
    FROM clean_transactions
    GROUP BY client_id
    )

-- Main Query: filtering data to reveal TOP 20 clients based on the revenue 
SELECT       
    client_id AS TOP_20_clients,
    client_total_revenue,
    revenue_rank
FROM ranking
WHERE revenue_rank < 21 -- Filter TOP 20 clients based on the revenue
ORDER BY revenue_rank;


-- Task 2 – Revenue Share of Top 10% Customers

WITH revenue AS -- CTE: Calculating clients total revenue
    (SELECT 
        client_id,
        SUM(amount_cleaned) as client_revenue -- for this analysis client's net revenue is more relevant and thus only it is calulated
    FROM clean_transactions
    GROUP BY client_id
    ),

ranked_clients AS -- CTE: Ranking clients based on revenue
    (SELECT 
        client_id,
        client_revenue,        
        SUM(client_revenue) OVER () AS total_revenue,        
        CUME_DIST() OVER (ORDER BY client_revenue DESC) AS dist_rank -- ranking using Cume_Dist as it returns percentage of partition values less than or equal to the value in the current row
    FROM revenue
    )

-- Main Query: filtering data and calculating cumulative revenue share of TOP 10% clients based on revenue
SELECT      
    MAX(total_revenue) AS total_revenue, 
    SUM(client_revenue) AS top10_revenue, -- Total revenue of TOP 10% clients
    ROUND(100 * SUM(client_revenue) / MAX(total_revenue), 2) AS top10_revenue_share_pct   -- Calculating the total percantage share of TOP10% clients
FROM ranked_clients
WHERE dist_rank <= 0.10; -- Filters top 10% customers by revenue 

-- Result: Revenue Share of Top 10% Customers is 23.86% of total revenue


-- Task 3 – Customer Purchase Frequency Segmentation 

WITH customer_lifetime AS -- CTE: preliminary calcuations per client
    (SELECT
        client_id,
        SUM(CASE WHEN amount_cleaned > 0 THEN amount_cleaned ELSE 0 END) AS monetary_client_revenue,
        SUM(CASE WHEN amount_cleaned < 0 THEN -1 * amount_cleaned ELSE 0 END) AS monetary_client_refund,
        COUNT(CASE WHEN amount_cleaned > 0 THEN 1 END) AS total_purchases, -- Calculate total purchases without returns for next step - frequency calculations
        MIN(transaction_month) AS first_month,
        MAX(transaction_month) AS last_month
    FROM clean_transactions
    GROUP BY client_id
    ),

lifetime_frequency AS -- CTE: Convert lifetime window into an active period of each customer
    (SELECT
        client_id,
        monetary_client_revenue,
        monetary_client_refund,
        100 * monetary_client_refund / NULLIF(monetary_client_revenue, 0) AS refund_ratio_pct,
        total_purchases,
        (
            TIMESTAMPDIFF(                      -- Calculates number of months between the first and last purchases which is a time while a client was active. Add 1 because it starts counting months with "0".
                MONTH,
                STR_TO_DATE(first_month, '%Y-%m-%d'), -- Converts to DATE format DATE_FORMAT, because TIMESTAMPDIFF requires it. Note, in the first CTE DATE_FORMAT() returns string value and MIN/MAX() work with strings
                STR_TO_DATE(last_month, '%Y-%m-%d')
            ) + 1
        ) AS lifetime_months, -- Active period of a customer
        total_purchases / (TIMESTAMPDIFF(MONTH, STR_TO_DATE(first_month, '%Y-%m-%d'), STR_TO_DATE(last_month, '%Y-%m-%d')) + 1) AS purchase_frequency, -- Calculate purchase frequency as total purchases divided by active months
        PERCENT_RANK() OVER (
            ORDER BY 
                total_purchases /
                (TIMESTAMPDIFF(MONTH, STR_TO_DATE(first_month, '%Y-%m-%d'), STR_TO_DATE(last_month, '%Y-%m-%d')) + 1) 
            ASC
        ) AS frequency_group_rank
    FROM customer_lifetime
    ) -- Note: purchase_frequency range appears to be ca. 357 - 5 purchases per month

-- Main Query: Grouping clients by frequency of their purchases and calculating average and total refund ratio for each group
SELECT 
    CASE 
        WHEN frequency_group_rank >= 0.95 THEN 'Very High Frequency'  
        WHEN frequency_group_rank >= 0.80 THEN 'High Frequency'      
        WHEN frequency_group_rank >= 0.20 THEN 'Medium Frequency'    
        WHEN frequency_group_rank >= 0.05 THEN 'Low Frequency'       
        ELSE 'Very Low Frequency'                           
    END AS frequency_group_label,
    COUNT(*) AS customer_count, -- counts number of clients in each group,
    ROUND(AVG(purchase_frequency), 2) AS avg_frequency, -- indicates average frequency of purchases in each group
    ROUND(AVG(refund_ratio_pct), 2) AS avg_client_refund_ratio,  -- customer-level behavioral view: indicates average refund ratio per client
    ROUND(
        100 * SUM(monetary_client_refund) / 
        NULLIF(SUM(monetary_client_revenue), 0)
        , 2) AS total_refund_ratio_pct      -- buisness impact view: indicates total refund ratio in each group
FROM lifetime_frequency
GROUP BY frequency_group_label;
-- Result: 5% (61) of very frequent buyers (200+ transactions/month) share similar numbers in behavioral view and buisness impact views. This occurs despite customers 
-- vastly vary in money spent because the high and low spenders are distributed equally in groups. 
-- To get more action-relevant insight, a revenue metric for high and low spenders can be added in the grouping to separate them basing on decision maker needs 


-- Task 4 – Average Days Between Purchases 

WITH clean_data AS  -- CTE: Prepare data for further manipulations
    (SELECT DISTINCT -- DISTINCT applied to date excludes multiple purchases on the same day
            client_id,
            transaction_date      
    FROM clean_transactions
    WHERE amount_cleaned > 0  -- Exclude refunds
    ),

lagging AS -- CTE: lags a date coloumn for calculation of days between purchases
    (SELECT 
        client_id,
        transaction_date,
        LAG(transaction_date) OVER (PARTITION BY client_id ORDER BY transaction_date) AS previous_buy
    FROM clean_data
    )

-- Main Query: calculates average day between purchases for each client
SELECT 
    client_id,
    AVG(DATEDIFF(transaction_date, previous_buy)) AS avg_days_between_purchases   -- Calculate average amount of days between purchases
FROM lagging
GROUP BY client_id
ORDER BY client_id;


-- TASK 5  Customer Segmentation by Total Orders

WITH clean_data AS  -- CTE: Calculate total number of orders per customer excluding refunds
    (SELECT 
        client_id,
        COUNT(*) AS client_total_orders       
    FROM clean_transactions
    WHERE amount_cleaned > 0  -- Exclude refunds
    GROUP BY client_id
    ), 

labelling AS -- CTE: Group clients by total number of their orders
    (SELECT 
        client_id,
        client_total_orders,  
        NTILE(4) OVER (ORDER BY client_total_orders DeSC) AS clients_category
    FROM  clean_data
    WHERE client_total_orders > 0 -- exclude customers with 0 purchases
    )

-- Main Query: Show groups, number of clients in these groups and their respective share
SELECT  
    CASE
        WHEN clients_category = 1 THEN "Champions"
        WHEN clients_category = 2 THEN "High buyers"
        WHEN clients_category = 3 THEN "Medium byuers"
        ELSE "Low buyers"
    END AS client_category,
    COUNT(*) AS clients_number,
    ROUND(AVG(client_total_orders), 2) -- avg number of orders in each category
FROM labelling
GROUP BY clients_category;
-- Result: All clients were categorized in 4 equal size categories based on their total purchases amount


-- Task 6 Revenue vs Frequency Matrix

WITH customer_lifetime AS -- CTE: Customer lifetime window + total purchases
    (SELECT
        client_id,
        COUNT(*) AS total_purchases, -- Calculates total purchases for next step - frequency calculations
        MIN(transaction_month) AS first_month,
        MAX(transaction_month) AS last_month,
        SUM(amount_cleaned) AS total_revenue -- Calculates total revenue for next step 
    FROM clean_transactions
    WHERE amount_cleaned > 0 -- Exclude refunds
    GROUP BY client_id
    ),

lifetime_frequency AS -- CTE: converts lifetime window into client's active period
    (SELECT
        client_id,
        total_purchases,
        TIMESTAMPDIFF(MONTH, first_month, last_month) + 1 AS lifetime_months, -- Active period of a customer, Calculate number of months between the first and last purchases which is a time while a client was active. Add 1 because it starts counting months with "0".
        total_revenue
    FROM customer_lifetime
    ),

client_labels AS  -- CTE: label clients by frequency and revenue groups for the next step of grouping them in the matrix 
    (SELECT 
        client_id,
        CASE        -- Labelling based on frequency
            WHEN total_purchases / NULLIF(lifetime_months, 0) > AVG(total_purchases / lifetime_months) OVER () THEN 'High frequency' 
            ELSE 'Low frequency'
        END AS client_purchase_frequency,
        CASE        -- Labelling based on revenue
            WHEN total_revenue > AVG(total_revenue) OVER () THEN 'High revenue'
            ELSE 'Low revenue'
        END AS client_revenue
    FROM lifetime_frequency
    )

-- Main Query: Final Revenue vs Frequency Matrix
SELECT 
    client_purchase_frequency,
    client_revenue,
    COUNT(*) AS clients_number, -- calculate number of clients in each group
    ROUND(100 * COUNT(*) / SUM(COUNT(*)) OVER (), 2) AS share_pct -- calculates share percentage of the group;
FROM client_labels
GROUP BY client_purchase_frequency, client_revenue;
-- Result: Clients with High frequency of purchases and High revenue are 29.12% of all active client base,
-- while clients with Low frequency and High revenue are 8.86% of all clients and actions can be done to make purchases more frequently 


-- Task 7 Refund ratio per client

WITH precalculus AS -- CTE:  Calculate total spent and total refunds per client
    (SELECT 
        client_id,
        SUM(CASE WHEN amount_cleaned > 0 THEN amount_cleaned ELSE 0 END) AS total_spending, -- Calculates total spending
        SUM(CASE WHEN amount_cleaned < 0 THEN amount_cleaned ELSE 0 END) AS total_refund -- Calculates total refunds
    FROM clean_transactions
    GROUP BY client_id
    ),

calculus AS -- CTE:  Calculate refunds share per client
    (SELECT 
        client_id,
        total_spending,
        total_refund,
        100 * -1 * total_refund / total_spending AS refund_ratio -- Note: positive value; calculates refund ratio as percantage of total spending
    FROM precalculus
    )

-- Main Query: filter clients with high refunds prioritize these with high spending
SELECT 
    client_id AS clients_with_refunds_over_33pct, -- Top clients have suspicious amount of refunds
    total_spending,
    total_refund,
    refund_ratio
FROM calculus
WHERE refund_ratio > 33 -- Filters for high refunds
ORDER BY total_spending DESC, refund_ratio DESC -- Prioritizes higher spending and higher refunds;
-- Result: Finds clients with refund ratio over 33, which could be used as a potential fraud indicator or 
-- investigation action to identify the reason for so many returns requests which can improve sales in future.


-- Task 8 Dormant client reactivation spike

WITH date_lag AS -- CTE: Prepare data for further manipulations
    (SELECT
        client_id,
        transaction_date, 
        LAG(transaction_date) OVER (
            PARTITION BY client_id 
            ORDER BY transaction_date
        ) AS previous_date, -- Get a previous transaction date for each customer to calculate dormancy
        amount_cleaned
    FROM clean_transactions
    ),

client_total_revenue AS  -- CTE: calculates total revenue per client
    (SELECT
        client_id,
        SUM(amount_cleaned) AS client_revenue -- Sum revenue per client without refunds
    FROM clean_transactions
    WHERE amount_cleaned > 0 -- Exclude refunds
    GROUP BY client_id
    ),

reactivation AS -- CTE: Dormancy revenue, calculates revenue for clients reactivated with purchases after a set number of days
    (SELECT
        client_id,
        SUM(amount_cleaned) AS reactivation_revenue -- Sum revenue for transactions that are considered reactivations (after dormancy)
    FROM date_lag
    WHERE amount_cleaned > 0 
        AND previous_date IS NOT NULL 
        AND DATEDIFF(transaction_date, previous_date) > 60 -- Filter revenue for clients reactivated  after set amount of days
    GROUP BY client_id
    ),

reactivation_share AS -- CTE: calculation of reactivantion revenue ratio per client
    (SELECT
        r.client_id,
        r.reactivation_revenue,
        c.client_revenue, -- total gross client revenue 
        ROUND(100 * r.reactivation_revenue / NULLIF(c.client_revenue, 0), 2) 
            AS reactivation_share_pct -- calculate reactivantion revenue ratio per client for further filtering of the spike
    FROM reactivation r
    JOIN client_total_revenue c ON r.client_id = c.client_id
    )

-- Main Query: filtering by setting Dormant client reactivation spike threshold
SELECT *
FROM reactivation_share
WHERE 
    reactivation_share_pct >= 1   -- spike threshold 
    AND reactivation_revenue > 0  -- remove 
ORDER BY reactivation_revenue DESC;
-- Result: The spike threshold is so low because the database spans over ca. 9 years with high transaction total volume per client
-- Only one client was found with above 1% reactivation share pct. THis parameter can be used as a fraud indicator.


-- Task 9 Card Sharing Detection

WITH suspicious_cards AS -- CTE: find cards with several users
    (SELECT card_number
    FROM cards_data
    GROUP BY card_number
    HAVING COUNT(DISTINCT client_id) > 1 -- filters cards with more than 1 unique user
    )

-- Main Query: find card-client pairs for cards with more than 1 unnique user
SELECT DISTINCT 
    c.card_number,
    c.client_id
FROM cards_data c
JOIN suspicious_cards s -- Join with original table to find respective card-client pairs
    ON c.card_number = s.card_number
ORDER BY c.card_number;
-- Result: No pairs are found indicating that each card blongs to a signle user. 
-- This check can be used to detect fraudulent activity.
