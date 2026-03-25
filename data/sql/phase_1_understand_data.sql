-- SQL EDA Phase 1: Understand the data
---------------------------------------------------------------------------

-- select the dataset to work with:
USE financial_transactions_dataset;


-- TASK 1 Overview data --

DESCRIBE cards_data;
-- Contains info about clients and detailed info the payment cards which they use

DESCRIBE users_data;
-- Contains detailed info about clients, their age, address, and their income, debt
-- Note. One customer may have several credit cards

DESCRIBE transactions_data;
-- Contains detailed info about purchases the clients did with their cards.

-- Conclusion: Dataset comprises detailed data about clients, their personal data, their addresses, 
-- their finansial accounts and credit cards (with details), transactions performed with these cards,
-- and additional information that could help reveal fraudulent activity.


-- TASK 2 Find Missing Data

SELECT
    SUM(id IS NULL) AS id_nulls,                                          -- 0
    SUM(client_id IS NULL) AS client_id_nulls,                            -- 0
    SUM(card_brand IS NULL) AS card_brand_nulls,                          -- 0
    SUM(card_type IS NULL) AS card_type_nulls,                            -- 0
    SUM(card_number IS NULL) AS card_number_nulls,                        -- 0
    SUM(expires IS NULL) AS expires_nulls,                                -- 0
    SUM(cvv IS NULL) AS cvv_nulls,                                        -- 0
    SUM(has_chip IS NULL) AS has_chip_nulls,                              -- 0
    SUM(num_cards_issued IS NULL) AS num_cards_issued_nulls,              -- 0
    SUM(credit_limit IS NULL) AS credit_limit_nulls,                      -- 0
    SUM(acct_open_date IS NULL) AS acct_open_date_nulls,                  -- 0
    SUM(year_pin_last_changed IS NULL) AS year_pin_last_changed_nulls,    -- 0
    SUM(card_on_dark_web IS NULL) AS card_on_dark_web_nulls               -- 0
FROM cards_data;

SELECT
    SUM(id IS NULL) AS id_nulls,                               -- 0
    SUM(current_age IS NULL) AS current_age_nulls,             -- 0
    SUM(retirement_age IS NULL) AS retirement_age_nulls,       -- 0
    SUM(birth_year IS NULL) AS birth_year_nulls,               -- 0
    SUM(birth_month IS NULL) AS birth_month_nulls,             -- 0
    SUM(gender IS NULL) AS gender_nulls,                       -- 0
    SUM(address IS NULL) AS address_nulls,                     -- 0
    SUM(latitude IS NULL) AS latitude_nulls,                   -- 0
    SUM(longitude IS NULL) AS longitude_nulls,                 -- 0
    SUM(per_capita_income IS NULL) AS per_capita_income_nulls, -- 0
    SUM(yearly_income IS NULL) AS yearly_income_nulls,         -- 0
    SUM(total_debt IS NULL) AS total_debt_nulls,               -- 0
    SUM(credit_score IS NULL) AS credit_score_nulls,           -- 0
    SUM(num_credit_cards IS NULL) AS num_credit_cards_nulls    -- 0
FROM users_data u;

SELECT
    SUM(id IS NULL) AS id_nulls,                             -- 0
    SUM(date IS NULL) AS date_nulls,                         -- 0
    SUM(client_id IS NULL) AS client_id_nulls,               -- 0
    SUM(card_id IS NULL) AS card_id_nulls,                   -- 0
    SUM(amount IS NULL) AS amount_nulls,                     -- 0
    SUM(use_chip IS NULL) AS use_chip_nulls,                 -- 0
    SUM(merchant_id IS NULL) AS merchant_id_nulls,           -- 0
    SUM(merchant_city IS NULL) AS merchant_city_nulls,       -- 0
    SUM(merchant_state IS NULL) AS merchant_state_nulls,     -- 0
    SUM(zip IS NULL) AS zip_nulls,                           -- 0
    SUM(mcc IS NULL) AS mcc_nulls,                           -- 0
    SUM(errors IS NULL) AS errors_nulls                      -- 0
FROM transactions_data;


-- Conclusion: No NULL values were detected in the dataset; 
-- However, further exploration should be done to identify any possible placeholders or inconsistency in data.


-- TASK 3 Count of Customers and Cards in the dataset

-- Check the total number of cards, unique cards, and unique clients in the dataset
SELECT 
    COUNT(*) AS total_cards,   -- 6146
    COUNT(DISTINCT id) AS unique_cards, -- 6146
    COUNT (DISTINCT client_id) AS unique_clients -- 2000
FROM cards_data c;
-- Result: There are 6146 cards in the dataset, all of which have unique numbers, and they belong to 2000 unique clients.

-- Check the total number of clients, and unique clients in the dataset
SELECT 
        COUNT(*) AS total_users,  -- 2000
        COUNT(DISTINCT id) AS unique_users -- 2000   
FROM users_data u; 
-- Result: There are 2000 unique registered clients in the dataset.

-- Check the total number of transactions, and a number of a unique active clients in the dataset
SELECT 
    COUNT(*) AS total_transactions,   -- 13305915
    COUNT(DISTINCT client_id) AS unique_active_clients  -- 1219
FROM transactions_data t;
-- Result: There are 13,305,915 transactions in the dataset performed by 1219 unique active clients.
-- Note: Active clients are those who performed at least one transaction.

-- Find non-active clients, i.e. those who have no transactions in the dataset, and count them
SELECT
    u.id AS client_id,
    COUNT(*) OVER () AS count_of_non_active_clients
FROM users_data u
LEFT JOIN transactions_data t ON u.id = t.client_id
WHERE t.client_id IS NULL;


-- Conclusion: There are 2000 unique registered clients owning 6146 cards in the dataset
-- 1219 of whom are active clients, i.e. performed at least one transaction
-- 781 are non-active clients and list of their ids is provided.


-- TASK 4 Assess time range of the dataset

SELECT 
    MIN(date) as  first_date, -- 2010-01-01 00:01:00
    MAX(date) as final_date, -- 2019-10-31 23:59:00
    DATEDIFF(MAX(date), MIN(date)) AS total_days -- 3590 days
FROM transactions_data t;


-- Conclusion: Dataset covers total 3590 days from January 1st 2010 till October 31st 2019


-- TASK 5 Count Total Revenue from all transactions
-- Note. Revenue is in text format and contains negative values (refunds)

-- Create CTAS table with cleaned amount and date format for further analysis
CREATE TABLE financial_transactions_dataset.clean_transactions AS
    (SELECT         
            client_id,
            card_id,
            CASE 
                WHEN amount LIKE '%$%' THEN CAST(REPLACE(amount, '$', '') AS DECIMAL(10,2)) 
                ELSE CAST(amount AS DECIMAL(10,2)) 
            END AS amount_cleaned, -- Removes a dollar sign to clean data and converts result to decimal numbers
            DATE_FORMAT(date, '%Y-%m-%d') AS transaction_date,
            DATE_FORMAT(date, '%Y-%m-01') AS transaction_month
    FROM transactions_data);

-- Check the content of the new table
SELECT *
FROM financial_transactions_dataset.clean_transactions
LIMIT 5;

-- Count toal revenue, toal refunds, and total revenue without refunds
SELECT      
    SUM(amount_cleaned) as total_revenue, -- 571835522.2799922
    -1 * SUM(
        CASE 
            WHEN amount_cleaned < 0 THEN amount_cleaned   -- Converts negative value to positive
             ELSE 0
        END
    ) as total_refunds, -- -67519042.34
    SUM(
        CASE 
            WHEN amount_cleaned > 0 THEN amount_cleaned  -- Sums only positive values
             ELSE 0
        END
    ) as total_revenue_without_refunds  -- 639354564.62
FROM financial_transactions_dataset.clean_transactions;


-- Conclusion: Total revenue over 10 years is about 571 mln USD. 
-- Total revenue without refunds subtracted is 639 mln USD while refunds being -67.5 mln USD.



-- SQL EDA Phase 1: Fraud related analysis 
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

SELECT COUNT(*) AS cards_without_active_clients
FROM cards_data c
LEFT JOIN users_data u ON c.client_id = u.id
WHERE u.id IS NULL;
-- Result: 0 cards without registered clients in the dataset

-- CTE to find non-active clients, i.e clients without transactions in the dataset
-- Main purpose of this CTE is to list all ids of the non-active users
WITH na_clients AS
    (SELECT
        u.id AS naclient_id
    FROM users_data u
    LEFT JOIN transactions_data t ON u.id = t.client_id
    WHERE t.client_id IS NULL)

-- Main query to count non-active clients
SELECT COUNT(*)
FROM na_clients;
-- Result: 781 non-active clients

-- Conclusion: None cards without a registered client were found.
-- AS for the clients without transactions, there are 781 non-active clients in the users_data table in the dataset


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

