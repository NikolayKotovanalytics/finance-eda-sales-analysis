-- SQL EDA Phase 4: Fraud and Anomaly analysis 
-- Note. The CTAS clean_transactions which was created in Phase 1 of EDA is used here to avoid code repetition in this Phase.
---------------------------------------------------------------------------

-- select the dataset to work with:
USE financial_transactions_dataset;

---------------------------------------------------------------------------

-- TASK 1 Check if any card is present on Darkweb 
-- Note. Info about if clients card is present on Darkweb is avaliable in the dataset in the column card_on_dark_web, which is a boolean value (True/False)

SELECT
    card_on_dark_web,
    COUNT(*) AS cards_count
FROM cards_data
GROUP BY card_on_dark_web;


-- Conclusion: None of the credit cards is on Darkweb


-- TASK 2 Check if there are any duplicate card numbers in the dataset

SELECT
    COUNT(*) AS cards_count
FROM cards_data
GROUP BY card_number
HAVING cards_count > 1; -- filter cards that have more than 1 occurrence in the dataset


-- Conclusion: None, as all card numbers are unique in the dataset.


-- TASK 3 Check if there are any cards without clients in the dataset and if there are any clients without transactions in the dataset

WITH cards_without_clients AS
(
SELECT 
    COUNT(*) AS total_cards_without_active_clients
FROM cards_data c
LEFT JOIN users_data u ON c.client_id = u.id
WHERE u.id IS NULL
),
-- Result: 0 cards without registered clients in the dataset

-- CTE to find non-active clients, i.e clients without transactions in the dataset
-- Main purpose of this CTE is to list all ids of the non-active users
na_clients AS
    (SELECT
        u.id AS naclient_id
    FROM users_data u
    LEFT JOIN transactions_data t ON u.id = t.client_id
    WHERE t.client_id IS NULL)

-- Main query to count non-active clients
SELECT 
    COUNT(*) AS total_na_clients,
    (SELECT total_cards_without_active_clients FROM cards_without_clients) AS total_cards_without_active_clients
FROM na_clients;
-- Result: 781 non-active clients

-- Conclusion: No cards without a registered client were found in the dataset.
-- 781 non-active clients were found in the users_data table in the dataset


-- TASK 4 Check if there are any cards without transactions in the dataset

-- Query to find the number of cards without transactions in the dataset
SELECT 
    COUNT(*)
FROM cards_data c
LEFT JOIN transactions_data t ON c.id = t.card_id
WHERE t.card_id IS NULL;
-- Result: 2075 cards without transactions.

-- Query to list all clients and their card numbers which have no recorded transactions in the dataset
SELECT
    c.client_id,
    c.id AS nacard_id
FROM cards_data c
LEFT JOIN transactions_data t ON c.id = t.card_id
WHERE t.card_id IS NULL
ORDER BY client_id;


-- Conclusion: The query returns numbers of 2075 cards without transactions and ids of their clients
-- This information can be useful for further analysis of non-active clients and their cards, as well as potential fraudulent activity


-- TASK 5 Check if any transaction was performed after expiration of a bank card. Show client and card ids for these transactions 

WITH cards_expiration_data AS
    (SELECT
        id,
        client_id,
        STR_TO_DATE(CONCAT('01/', expires), '%d/%m/%Y') AS card_expiration_month -- Converts text data from column into DATE Y-m-d format
    -- Note. Without adding number for DAY, the function returns NULL as day is needed for full DATE by MySQl
    FROM cards_data),

cards_expired AS
    (SELECT
        id,
        client_id,
        DATE_ADD(card_expiration_month, INTERVAL 1 MONTH) AS card_expired_before -- Added month to find the first day at which the card has expired
    FROM cards_expiration_data)

SELECT
    ct.client_id,
    ct.card_id,
    ct.transaction_date,
    ce.card_expired_before
FROM clean_transactions ct
LEFT JOIN cards_expired ce ON ct.card_id = ce.id
WHERE ct.transaction_date >= ce.card_expired_before
GROUP BY ct.client_id, ct.card_id, ct.transaction_date, ce.card_expired_before
ORDER BY ct.client_id, ct.card_id, ct.transaction_date;

-- Conclusion: Potential fraud alert. transactions done after the respective card expiration has been found.
-- Ids of these cards and their respective owners are provided.

-- Task 6 Dormant client reactivation spike

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


-- Task 7 Card Sharing Detection

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
