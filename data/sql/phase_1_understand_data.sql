/*
-- ============================================================================
SQL EDA Phase 1: Data Understanding and Preparation
Purpose: understand data in the dataset and prepare it for analysis in MySQL.    

-- Contents:
-- Task 1. Overview data
-- Task 2. Find Missing Data (Checking 'NULL's)
-- Task 3. Count total Clients, Cards, Transactions in the dataset
-- Task 4. Assess time range of the dataset
-- Task 5. Count Total Revenue from all transactions
-- ============================================================================
*/

-- select the dataset to work with:
USE financial_transactions_dataset;

-- ============================================================================
-- Task 1 Overview data 
-- Goal: Understand datsaset structure. Check column names, data types, and key fields in each table.
-- ============================================================================

DESCRIBE cards_data;
-- Contains info about clients and detailed info the payment cards which they use


DESCRIBE users_data;
-- Contains detailed info about clients, their age, address, and their income, debt
-- Note. One customer may have several credit cards


DESCRIBE transactions_data;
-- Contains detailed info about purchases the clients did with their cards.

-- Insight: Dataset comprises detailed data about clients, their personal data, their addresses, 
-- their finansial accounts and credit cards (with details), transactions performed with these cards,
-- and additional information that could help reveal fraudulent activity. 
-- These data is divided into three tables which have common client_id/card_id/id keys.


-- ============================================================================
-- Task 2 Find Missing Data (Checking 'NULL's) 
-- Goal: Find missing data ('NULL's).
-- ============================================================================

-- Query 1 Count total number of 'NULL' values in each colomn in table with cards info
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

-- Query 2 Count total number of 'NULL' values in each colomn in table with clients info
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

-- Query 3 Count total number of 'NULL' values in each colomn in table with transactions info
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

-- Insight: No NULL values were detected in the dataset. Therefor, no explicitly missing data.


-- ============================================================================
-- Task 3 Count total Clients, Cards, Transactions in the dataset
-- Goal: Check total number of clients (active/non-active), cards, transactions.

-- Note. Active clients are those with one or more transactions, while non-active has no transactions mentioned in the dataset 
-- ============================================================================

-- Query 1 Check the total number of cards, unique cards, and unique clients in the dataset
SELECT 
    COUNT(*) AS total_cards, 
    COUNT(DISTINCT id) AS unique_cards, 
    COUNT(DISTINCT client_id) AS unique_clients 
FROM cards_data c; 

-- Query 2 Check the total number of clients, and unique clients in the dataset
SELECT 
        COUNT(*) AS total_clients, 
        COUNT(DISTINCT id) AS unique_clients  
FROM users_data u; 

-- Query 3 Check the total number of transactions, and a number of a unique active clients in the dataset
SELECT 
    COUNT(*) AS total_transactions,   
    COUNT(DISTINCT client_id) AS unique_active_clients  
FROM transactions_data t; 

--  Query 4 Find non-active clients, i.e. those who have no transactions in the dataset, and count them
SELECT
    u.id AS client_id,
    COUNT(*) OVER () AS count_of_non_active_clients
FROM users_data u
LEFT JOIN transactions_data t ON u.id = t.client_id
WHERE t.client_id IS NULL; 

-- Insight: There are 6146 cards in the dataset, all of which have unique numbers, and they belong to 2000 unique clients;
-- 2000 unique registered clients in the dataset;
-- 13+ mln transactions in the dataset performed by 1219 unique active clients who performed at least one transaction;
-- 781 non-active clients and a list of their ids is shown.


-- ============================================================================
-- Task 4 Assess time range of the dataset
-- Goal: Find total time period wich the dataset covers.
-- ============================================================================

SELECT 
    MIN(date) as  first_date,  
    MAX(date) as final_date,
    DATEDIFF(MAX(date), MIN(date)) AS total_days 
FROM transactions_data t; 

-- Insight: Dataset covers 3590 days: from 2010-01-01 00:01:00 till 2019-10-31 23:59:00.


-- ============================================================================
-- Task 5 Count Total Revenue from all transactions 
-- Goal: Find total time period wich covers the dataset.

-- Note. Revenue is in TEXT format and contains negative values (refunds),
-- thus additional task is to transform required data for further analyses in next phases of this EDA
-- ============================================================================

-- Note. Here, I decided to create a CTAS table with cleaned amount and date format that will be reused in further data analysis of this dataset. 
-- This will help to avoid repeating data cleaning steps in each query and make the code more efficient and readable.

CREATE TABLE financial_transactions_dataset.clean_transactions AS (
SELECT         
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
-- ============================================================================

-- Main Task: Count total revenue, total refunds, and total net revenue 

SELECT      
-- total revenue
    SUM(amount_cleaned) as total_net_revenue,

-- total refunds
    -1 * SUM(
            CASE 
                WHEN amount_cleaned < 0 THEN amount_cleaned   -- Converts negative value to positive
                ELSE 0
            END) as total_refunds,

-- total net revenue
    SUM(
        CASE 
            WHEN amount_cleaned > 0 THEN amount_cleaned
            ELSE 0
        END) as total_gross_revenue  

FROM financial_transactions_dataset.clean_transactions;

-- Insight: Total revenue over 10 years is about 571 mln USD. 
-- Total revenue without refunds subtracted is 639 mln USD while refunds being -67.5 mln USD.

-- ============================================================================
-- Summary
-- ============================================================================
-- Phase 1 focuses on:
-- - Validating column structure
-- - Reviewing key fields
-- - Checking nulls and data consistency
-- - Collecting general info in the dataset, i.e.:
--  - Total clients, cards, transactions,
--  - Total time period covered by the dataset,
--  - Total revenue, refunds, net revenue.
-- - Data cleaning and perparing for further analysis

