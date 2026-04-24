/*
-- ============================================================================
SQL EDA Phase 4: Payment Risk and Anomaly Analysiss 
Purpose: Identify suspicious patterns, data integrity issues, and unusual card or customer behavior that may require further investigation

-- Contents:
-- Task 1. Cards on Dark Web
-- Task 2. Duplicate Card Numbers in the Cards Table
-- Task 3. Cards Without Clients and Clients Without Transactions
-- Task 4. Cards Without Transactions
-- Task 5. Transactions After Card Expiration Date
-- Task 6. Dormant Client Reactivation Spike
-- Task 7. Card Sharing Detection
-- ============================================================================
*/

-- select the dataset to work with:
USE financial_transactions_dataset;
-- Note. The CTAS clean_transactions which was created in Phase 1 of EDA is used here to avoid code repetition in this Phase.

-- ============================================================================
-- Task 1 Cards on Dark Web 
-- Goal: Check if any card is present on Dark Web 

-- Note. Info about if clients card is present on Dark Web is available in the dataset 
-- in the column card_on_dark_web, which is a boolean value (True/False)
-- ============================================================================

SELECT
    card_on_dark_web,
    COUNT(*) AS cards_count
FROM cards_data
GROUP BY card_on_dark_web;

-- Insight: This check shows whether any cards are explicitly flagged as
-- appearing on the dark web in the dataset. A zero count reduces one type
-- of known exposure risk, but does not rule out other fraud scenarios.


-- ============================================================================
-- Task 2 Duplicate Card Numbers in the Cards Table 
-- Goal: Check if there are any duplicate card numbers in cards table
-- ============================================================================

-- Query: calculates how many duplicated card numbers are in the cards table(cards_data)
SELECT 
    COUNT(*) AS duplicated_card_numbers
FROM (
    SELECT -- subquery listing all duplicated cards numbers
        card_number 
    FROM cards_data
    GROUP BY card_number
    HAVING COUNT(*) > 1 -- filter cards that have more than 1 occurrence in the dataset
) sub; 

-- Insight: This check validates whether any card numbers are duplicated in
-- the cards table, which could indicate data quality issues or suspicious records.


-- ============================================================================
-- Task 3 Cards without clients and Clients without transactions
-- Goal: Check if there are any cards without clients in the dataset and if there are any clients without transactions in the dataset
-- ============================================================================

-- CTE 1: finds cards without clients, i.e. cards that do not have a registered client in the users_data table in the dataset
WITH cards_without_clients AS (
SELECT 
    COUNT(*) AS total_cards_without_active_clients
FROM cards_data c
LEFT JOIN users_data u ON c.client_id = u.id
WHERE u.id IS NULL),

-- CTE 2: finds inactive clients, i.e clients without transactions in the dataset
-- Note. Main purpose of this CTE is to list all ids of the non-active users
inactive_clients AS (
SELECT
    u.id AS inactive_client_id
FROM users_data u
LEFT JOIN transactions_data t ON u.id = t.client_id
WHERE t.client_id IS NULL)

-- Main Query: Counts inactive clients and shows a number of cards without registered clients
SELECT 
    COUNT(*) AS total_inactive_clients,
    (SELECT 
        total_cards_without_active_clients 
    FROM cards_without_clients) AS total_cards_without_active_clients -- subquery to show a result from CTE 1
FROM inactive_clients;

-- Insight: This check separates two integrity cases:
-- 1. cards that are not linked to any registered client, and
-- 2. registered clients who have no recorded transactions.
-- The second group may represent inactive customers or incomplete activity records.


-- ============================================================================
-- Task 4 Cards without transactions 
-- Goal: Check if there are any cards without transactions in the dataset
-- ============================================================================

-- Query 1: finds the number of cards without transactions in the dataset
SELECT 
    COUNT(*)
FROM cards_data c
LEFT JOIN transactions_data t ON c.id = t.card_id
WHERE t.card_id IS NULL;


-- Query 2: lists all clients and their card ids and numbers which have no recorded transactions in the dataset
SELECT
    c.client_id,
    c.id AS na_card_id,
    c.card_number AS na_card_number
FROM cards_data c
LEFT JOIN transactions_data t ON c.id = t.card_id
WHERE t.card_id IS NULL  
ORDER BY 
    c.client_id,
    c.id,
    c.card_number;


-- Insight: Identifies cards with no recorded usage in the transaction table.
-- These cards may belong to inactive clients, unused accounts, or records
-- that deserve further operational or fraud-related review.


-- ============================================================================
-- Task 5 Transactions after card expiration date 
-- Goal: Check if any transaction was performed after expiration of a bank card. Show client and card ids for these transactions 
-- ============================================================================

-- CTE: lists card id, card's number, its owner's client id and card's expiration month in a correct format
WITH cards_expiration_data AS (
SELECT
    id,
    card_number,
    client_id,
    STR_TO_DATE(CONCAT('01/', expires), '%d/%m/%Y') AS card_expiration_month -- Converts text data from column into DATE Y-m-d format
-- Note. DAY information is missing and requires to be added, otherwise the function returns NULL.
FROM cards_data),

-- CTE: lists card id, its owners's client id and the first day when the card is deactivated (1st day of the month next after expiration date)
cards_expired AS (
SELECT
    id,
    card_number,
    client_id,
    DATE_ADD(card_expiration_month, INTERVAL 1 MONTH) AS card_deactivation_date 
    -- Note. 1 month is added to the expiration time to find the 1st day when the bank card is inactive
FROM cards_expiration_data)

-- Main Query: Lists clients ids, their bank cards number,their cards deactivation date,
-- and the transactions performed with these cards after their deactivation dates
SELECT
    ct.client_id,
    ct.card_id,
    ce.card_number,
    ct.transaction_date,
    ce.card_deactivation_date
FROM clean_transactions ct
LEFT JOIN cards_expired ce ON ct.card_id = ce.id
WHERE ct.transaction_date >= ce.card_deactivation_date
GROUP BY ct.client_id, ct.card_id, ce.card_number, ct.transaction_date, ce.card_deactivation_date
ORDER BY ct.client_id, ct.card_id, ce.card_number, ct.transaction_date;

-- Insight: Transactions recorded on or after a card's deactivation date are
-- anomalous and may indicate invalid card usage, data quality issues, or
-- potential fraud. These cases should be reviewed individually.


-- ============================================================================
-- Task 6 Dormant client reactivation spike
-- Goal: Find clients with a suspicious spike in transactions after client's inactivity periods and calculate reactivation revenue ratio
-- ============================================================================

-- CTE: Prepare data to calculate dormancy for individual clients
WITH date_lag AS (
SELECT
    client_id,
    transaction_date, 
    LAG(transaction_date) OVER (
        PARTITION BY client_id 
        ORDER BY transaction_date
    ) AS previous_date, -- Get a previous transaction date for each customer to calculate dormancy
    amount_cleaned AS gross_revenue
FROM clean_transactions
WHERE amount_cleaned > 0), -- Exclude refunds

-- CTE: calculates total gross revenue per client
client_total_revenue AS (  
SELECT
    client_id,
    SUM(amount_cleaned) AS client_gross_revenue 
FROM clean_transactions
WHERE amount_cleaned > 0 -- Exclude refunds
GROUP BY client_id),

-- CTE: Calculates Dormancy revenue, i.e. revenue for clients reactivated with purchases after a set number of days - 60 days
reactivation AS (
SELECT
    client_id,
    SUM(gross_revenue) AS reactivation_gross_revenue -- Sum revenue for transactions that are considered reactivations (after dormancy)
FROM date_lag
WHERE 
    previous_date IS NOT NULL 
    AND DATEDIFF(transaction_date, previous_date) > 60 -- Filter revenue for clients reactivated after set amount of days
GROUP BY client_id),

-- CTE: calculation of reactivantion revenue ratio per client
reactivation_share AS (
SELECT
    r.client_id,
    r.reactivation_gross_revenue,
    c.client_gross_revenue, -- total gross client revenue 
    ROUND(100 * r.reactivation_gross_revenue / NULLIF(c.client_gross_revenue, 0), 2) 
        AS reactivation_share_pct -- calculate reactivantion revenue ratio per client for further filtering of the spike
FROM reactivation r
JOIN client_total_revenue c ON r.client_id = c.client_id)

-- Main Query: filtering by setting Dormant client reactivation spike threshold
SELECT *
FROM reactivation_share
WHERE 
    reactivation_share_pct >= 1   -- spike threshold 
    AND reactivation_gross_revenue > 0  -- remove 0
ORDER BY reactivation_gross_revenue DESC;

-- Insight: Flags clients whose revenue includes purchases made after long
-- inactive periods. This is a behavioral anomaly indicator rather than a proof
-- of fraud and can be used to identify cases for closer review.

-- Note: The reactivation-share threshold is set to 1% because the dataset spans
-- roughly nine years and client-level revenue totals are large. In this dataset,
-- only one client exceeded that threshold.


-- ============================================================================
-- Task 7 Card Sharing Detection
-- Goal: Find bank cards registered/used by several clients
-- ============================================================================

-- CTE: find cards with several users in cards_data table
WITH suspicious_cards AS (
SELECT 
    card_number
FROM cards_data
GROUP BY card_number
HAVING COUNT(DISTINCT client_id) > 1), -- filters cards with more than 1 unique user

-- CTE: find cards with several users in transactions_data table
suspicious_cards_2 AS (
SELECT 
    card_id
FROM clean_transactions
GROUP BY card_id
HAVING COUNT(DISTINCT client_id) > 1)

-- Main Query: find card-client pairs for cards with more than 1 unique user
SELECT DISTINCT 
    c.card_number,
    c.id AS card_id,
    c.client_id
FROM cards_data c
JOIN suspicious_cards s 
    ON c.card_number = s.card_number -- Join with original table to find respective card-client pairs
JOIN suspicious_cards_2 s2
    ON c.id = s2.card_id
ORDER BY c.card_number;

-- Insight: Cards registered to or used by multiple clients may indicate
-- shared credentials, account misuse, data inconsistencies, or potentially
-- fraudulent behavior and should be investigated further.


-- ============================================================================
-- Summary
-- ============================================================================
-- Phase 4 focuses on fraud-related checks, anomaly detection, and data integrity
-- validation. The section covers:
-- - Known exposure indicators such as cards flagged on the dark web
-- - Data integrity checks for duplicate or orphan records
-- - Invalid transaction timing, such as usage after card expiration
-- - Unusual customer reactivation behavior after dormancy
-- - Card-sharing patterns that may require fraud review