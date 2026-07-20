/*
-- ============================================================================
SQL EDA Phase 2: Time-Based Revenue Analysis 
Purpose: Analyze how revenue and refunds change over time, including trend, seasonality, volatility, and customer activity patterns

-- Contents:
-- Task 1. Monthly revenue
-- Task 2. Month-over-Month (MoM) Revenue Change
-- Task 3. Rolling 3-Month Revenue to smooth short-term volatility
-- Task 4. Yearly revenue and refunds
-- Task 5. Seasonality Analysis (Monthly Pattern)
-- Task 6. Transaction Volume vs Revenue
-- Task 7. Refund Trend Over Time
-- Task 8. Revenue Volatility by Year
-- Task 9. Revenue per Active Client and per bank card
-- Task 10. Recency, Frequency, Monetary (RFM) analysis for Revenue with account to refunds
-- ============================================================================
*/

-- select the dataset to work with:
USE financial_transactions_dataset;
-- Note. The CTAS clean_transactions which was created in Phase 1 of EDA is used here to avoid code repetition in this Phase.


-- ============================================================================
-- Task 1 Monthly revenue
-- Goal: Calculate total monthly revenue over all dataset period
-- ============================================================================

SELECT  
  YEAR(transaction_month) AS 'Year',
  MONTHNAME(transaction_month) AS 'Month',
  SUM(amount_cleaned) as monthly_net_revenue
FROM clean_transactions
GROUP BY transaction_month 
ORDER BY transaction_month;

-- Insight: This output helps identify long-term trends, seasonality,
-- and months with unusually high or low net revenue.


-- ============================================================================
-- Task 2 Month-over-Month (MoM) Revenue Change
-- Goal: Make monthly revenue change trend easier to interpret
-- ============================================================================

-- CTE: calculates monthly revenue and uses LAG function to create a column for MoM calculations
WITH mom AS (
SELECT  
transaction_month,
SUM(amount_cleaned) as monthly_net_revenue,
LAG(SUM(amount_cleaned)) OVER (
    ORDER BY transaction_month      -- ensures correct order of months for LAG function to work properly
    ) as previous_month_net_revenue -- returns the value of a previous month revenue for each month
FROM clean_transactions
GROUP BY transaction_month)

-- Main Query: calculates MoM and MoM change percentage
SELECT  
    YEAR(transaction_month) AS 'Year',
    MONTHNAME(transaction_month) AS 'Month',
    monthly_net_revenue,
    monthly_net_revenue - previous_month_net_revenue as mom_net_revenue_change, -- MoM change
    ROUND(
          100 * 
          (monthly_net_revenue - previous_month_net_revenue)
          / previous_month_net_revenue,
          2  
    ) as mom_change_pct -- MoM change in percentage compared to previous month
FROM mom
ORDER BY transaction_month;

-- Insight: Shows month-over-month changes in net revenue in both absolute
-- and percentage terms, which helps highlight acceleration, slowdown,
-- and unusual month-level shifts.


-- ============================================================================
-- Task 3 Rolling 3-Month Revenue to smooth short-term volatility
-- Goal: Get a look at a coarsier revenue time trend using 3-month revenue as a step
-- ============================================================================

 -- Query: calculates monthly revenue and a 3-month revenue using a window function for code-brevitry
SELECT 
    YEAR(transaction_month) AS 'Year',
    MONTHNAME(transaction_month) AS 'Month',
    SUM(amount_cleaned) as monthly_net_revenue,
    SUM(SUM(amount_cleaned)) OVER (
        ORDER BY transaction_month 
        ROWS BETWEEN 2 PRECEDING AND CURRENT ROW
        ) as rolling_3_month_net_revenue  -- calculation of rolling revenue 
FROM clean_transactions
GROUP BY transaction_month
ORDER BY transaction_month;

-- Insight: The rolling 3-month view smooths short-term fluctuations and
-- makes the broader net revenue trend easier to interpret.


-- ============================================================================
-- Task 4 Yearly revenue and refunds
-- Goal: Get a look at a coarsier revenue time trend using 1 year revenue as a step.
-- ============================================================================

-- Query: calculates yearly revenue and refunds
SELECT  
    YEAR(transaction_date) as dataset_year, -- shortens data to year
    SUM(amount_cleaned) as yearly_net_revenue,  -- revenue calculation,
    SUM(CASE WHEN amount_cleaned >= 0 THEN amount_cleaned ELSE 0 END) as yearly_gross_revenue, -- revenue without refunds
    SUM(CASE WHEN amount_cleaned < 0 THEN amount_cleaned ELSE 0 END) * -1 as refunds_per_year  -- only refunds calculation
FROM clean_transactions
GROUP BY dataset_year                     -- groups by year for final calculation
ORDER BY dataset_year;

-- Insight: This view compares yearly gross revenue, net revenue, and refunds,
-- making it easier to evaluate long-term performance without monthly fluctuations.


-- ============================================================================
-- Task 5 Seasonality Analysis (Monthly Pattern)
-- Goal: Get a look at a seasonal pattern of sales
-- ============================================================================

-- CTE: Pre-calculate monthly revenue needed for correct monthly seasonality (monthly average) calculation
WITH monthly_rev AS (    
SELECT  
    transaction_month,
    SUM(amount_cleaned) as monthly_net_revenue
FROM clean_transactions
GROUP BY transaction_month)

-- Main Query: final calculation of avg per month from 2010 till 2019 and rank of months by their average revenue
SELECT    
    MONTHNAME(transaction_month) as 'Month',           -- returns name of month needed for seasonality analysis
    AVG(monthly_net_revenue) as avg_month_net_revenue, -- returns average revenue per month across all years in the dataset
    RANK() OVER (
        ORDER BY AVG(monthly_net_revenue) DESC
        ) as month_net_revenue_rank                    -- ranking months starting with largest average monthly revenue
FROM monthly_rev
GROUP BY MONTHNAME(transaction_month)
ORDER BY month_net_revenue_rank;

-- Insight: This highlights recurring seasonal patterns by comparing the
-- average monthly net revenue across years and ranking months from strongest
-- to weakest average performance.


-- ============================================================================
-- Task 6 Transaction Volume vs Revenue
-- Goal: Reveal total monetary worth of all successful sales transactions
-- ============================================================================

-- CTE: Pre-calculate number of transactions and total revenue per month
WITH mon_rev AS (
SELECT 
    transaction_month,
    COUNT(*) AS transactions_per_month,
    SUM(amount_cleaned) AS monthly_gross_revenue         
FROM clean_transactions
WHERE amount_cleaned > 0 -- ignore refunds as we want to see the relationship between transaction volume and revenue
GROUP BY transaction_month)

-- Main Query: calculation of average transaction value per month
SELECT 
    YEAR(transaction_month) AS 'Year',
    MONTHNAME(transaction_month) AS 'Month',
    transactions_per_month, 
    monthly_gross_revenue, 
    ROUND(monthly_gross_revenue / transactions_per_month , 2) AS avg_transaction_value -- final calculation of average revenue per transaction per month
FROM mon_rev
ORDER BY transaction_month;

-- Insight: Comparing transaction count, total monthly gross revenue, and average
-- transaction value helps show whether revenue changes are driven more by
-- transaction volume or by order value.


-- ============================================================================
-- TASK 7 Refund Trend Over Time
-- Goal: Understand monthly refund trends.
-- ============================================================================

-- CTE: Prepare data for further manipulations
WITH monthly_calc AS (
SELECT 
    transaction_month,
    COUNT(*) AS transactions_per_month,   -- counts total number of transactions per month
    COUNT(
        CASE
            WHEN amount_cleaned < 0 THEN 1 
        END -- ELSE is automatically 'NULL', but if set it to '0' or any non-'NULL' value, it will be counted by the 'COUNT' function
    ) AS refund_transactions, -- counts number of refund transactions per month
    SUM(
        CASE 
            WHEN amount_cleaned >= 0 THEN amount_cleaned 
            ELSE 0
        END
    ) AS monthly_gross_revenue, -- counts total monthly income
    SUM(
        CASE 
            WHEN amount_cleaned < 0 THEN amount_cleaned * -1
            ELSE 0
        END
    )  AS monthly_refunds   -- counts total monthly refunds and converts them to a positive value
FROM clean_transactions
GROUP BY transaction_month),

-- CTE Query: final calculation of refund and income percentage ratio per month
refund_income_ratio AS (
SELECT 
    transaction_month,
    refund_transactions AS refund_transactions_per_month,
    monthly_refunds,
    ROUND (
        100 * monthly_refunds / monthly_gross_revenue, -- Note: monthly_refunds were converted to positive value during previous step
        2
        ) AS refund_ratio_pct,                         -- final calculation of refund value ratio percentage of total income
    ROUND (
        100 * refund_transactions / transactions_per_month,
        2
        ) AS refund_transactions_ratio_pct             -- final calculation of refund transactions ratio percentage of total transactions
FROM monthly_calc)

-- Main Query: date formatting for better readability of results
SELECT
    DATE_FORMAT(transaction_month, '%Y %M') AS transaction_year_month,
    refund_transactions_per_month,
    monthly_refunds,
    refund_ratio_pct,
    refund_transactions_ratio_pct
FROM refund_income_ratio
ORDER BY transaction_month;

-- Insight: This output tracks monthly refund volume and refund rates
-- relative to revenue and transaction count, helping identify unusual
-- refund spikes or changing return behavior over time.


-- ============================================================================
-- Task 8 Revenue Volatility by Year
-- Goal: Analyze revenue volatility by year.
-- ============================================================================

-- CTE: Prepare data for further manipulations
WITH monthly_rev AS (
SELECT
    YEAR(transaction_month) AS transaction_year,       -- return only year
    MONTH(transaction_month),                          -- return only month
    SUM(amount_cleaned) AS monthly_net_revenue
FROM clean_transactions
GROUP BY YEAR(transaction_month), MONTH(transaction_month))  

-- Main Query: final calculation of monthly revenue volatility per year
SELECT       
    transaction_year AS 'Year',
    ROUND(AVG(monthly_net_revenue), 2) AS avg_monthly_net_revenue,      -- calculates AVG monthly revenue per year
    ROUND(STDDEV_POP(monthly_net_revenue), 2) AS net_revenue_volatility, -- returns revenue volatility 
    -- I divide revenue volatility by average monthly revenue to get volatility coefficient
    -- for better comparability across years with different revenue levels
    ROUND(100 * STDDEV_POP(monthly_net_revenue) / AVG(monthly_net_revenue), 2) AS net_revenue_volatility_coefficient 
FROM monthly_rev
GROUP BY transaction_year
ORDER BY transaction_year;

-- Insight: Revenue volatility measures how much monthly net revenue varies
-- within each year. A higher volatility coefficient suggests less stable
-- monthly performance and potentially higher planning risk.


-- ============================================================================
-- Task 9 Revenue per active Client and per bank card
-- Goal: Find total net revenue per client and per bank card
-- ============================================================================

-- CTE Query: calculation of revenue per number of unique active customers each month
WITH monthly_revenue AS (
SELECT 
    transaction_month,
    ROUND(
            SUM(
                CASE 
                    WHEN amount_cleaned > 0 THEN amount_cleaned 
                    ELSE 0 
                END)            -- ignore refunds to avoid distorting per-customer value
            / COUNT(DISTINCT client_id), 2
    ) AS revenue_per_customer,  -- final count of net revenue value per active customer
    ROUND(
            SUM(
                CASE 
                    WHEN amount_cleaned > 0 THEN amount_cleaned 
                    ELSE 0 
                END)            -- ignore refunds to avoid distorting per-customer value
            / COUNT(DISTINCT card_id), 2
    ) AS revenue_per_card       -- final count of net revenue value per each bank card
FROM clean_transactions
GROUP BY transaction_month
ORDER BY transaction_month)

-- Main Query: date formatting for better readability of results
SELECT
    YEAR(transaction_month) AS 'Year',
    MONTHNAME(transaction_month) AS 'Month',
    revenue_per_customer,
    revenue_per_card
FROM monthly_revenue
ORDER BY transaction_month;


-- Insight: These metrics estimate average monthly gross revenue generated per
-- active client and per bank card, helping evaluate client's activity
-- and monetization efficiency over time.


-- ============================================================================
-- Task 10 Recency, Frequency, Monetary (RFM) analysis for Revenue with account to refunds
-- Goal: Understand customer behavior for marketing strategies.
-- ============================================================================

-- CTE: specify a specific (snapshot) date, which is here a final transaction day + 1 day, to use in recency calculations
WITH snapshot_date AS (
SELECT 
    DATE_ADD(MAX(transaction_date), INTERVAL 1 DAY) AS ds_snapshot_date            
FROM clean_transactions),

-- CTE: find client's last order date, total transactions number, total spent and total refunds number and volume, and last refund date 
last_order_date AS (
SELECT
    client_id,

-- revenue part
    COUNT(CASE WHEN amount_cleaned > 0 THEN 1 END) AS frequency_revenue,
    SUM(CASE WHEN amount_cleaned > 0 THEN amount_cleaned ELSE 0 END) AS monetary_client_revenue,
    MAX(CASE WHEN amount_cleaned > 0 THEN transaction_date END) AS last_order_date,

-- refund part
    COUNT(CASE WHEN amount_cleaned < 0 THEN 1 END) AS frequency_refund,
    SUM(CASE WHEN amount_cleaned < 0 THEN -1 * amount_cleaned ELSE 0 END) AS monetary_client_refund,
    MAX(CASE WHEN amount_cleaned < 0 THEN transaction_date END) AS last_refund_date

FROM clean_transactions
GROUP BY client_id),

-- CTE: RFM table for revenue and refunds for all clients
rfm_table AS (
SELECT
    lod.client_id,
    lod.last_order_date,
    DATEDIFF(sd.ds_snapshot_date, lod.last_order_date) AS recency_revenue_days,

-- revenue part
    lod.frequency_revenue,
    lod.monetary_client_revenue,

-- refund part
    DATEDIFF(sd.ds_snapshot_date, lod.last_refund_date) AS recency_refund_days,
    ROUND(100 * lod.frequency_refund / NULLIF((lod.frequency_revenue + lod.frequency_refund), 0), 2) AS refund_transaction_ratio_pct,
    ROUND(100 * lod.monetary_client_refund / NULLIF((lod.monetary_client_revenue + lod.monetary_client_refund), 0), 2) AS refund_ratio_pct,
    lod.monetary_client_refund
FROM last_order_date lod
CROSS JOIN snapshot_date sd), -- CROSS JOIN combines all rows in both tables without conditions, and we have only one date in sd  

-- CTE: create for clients 5 buckets/performance scores for each r,f,m parameters 
clients_scored AS (
SELECT 
    client_id,

-- revenue part
    monetary_client_revenue,
    NTILE(5) OVER (ORDER BY recency_revenue_days DESC)  AS r_revenue_score,   -- Recency, DESC so lower values get higher score
    NTILE(5) OVER (ORDER BY frequency_revenue ASC) AS f_revenue_score,        -- Frequency, ASC so lower values get lower score
    NTILE(5) OVER (ORDER BY monetary_client_revenue ASC) AS m_revenue_score,  -- Monetary, ASC so lower values get lower score

-- refund part
    monetary_client_refund,
    refund_ratio_pct,
    refund_transaction_ratio_pct
FROM rfm_table),

-- CTE: assign parameters for a segment basing on combination of their rfm perfomance scores and refund behaviors
segmented AS (
SELECT 
    client_id,

-- revenue part
    monetary_client_revenue,

    -- create a combined segment code for revenue part to simplify revenue assignemnt logic and make it more transparent
    CONCAT(r_revenue_score, f_revenue_score, m_revenue_score) AS segment_revenue_code,

    -- assign revenue segment based on the combination of r,f,m scores with the following logic:
    CASE
    -- Set conditions to find most valuable clients based on highest rfm scores
        WHEN 
            r_revenue_score >= 4 AND
            f_revenue_score >= 4 AND
            m_revenue_score >= 4
        THEN "Champions"  -- Most valuable customers

        WHEN
            r_revenue_score < 4 AND
            f_revenue_score >= 4 AND
            m_revenue_score < 4
        THEN "Loyal customers" 

        WHEN
            r_revenue_score < 4 AND
            f_revenue_score < 4 AND
            m_revenue_score >= 4
        THEN "Big spenders" 
        
    -- Set conditions to find other specific client groups based on rfm parameters
        WHEN
            r_revenue_score <= 2 AND
            f_revenue_score >= 3         
        THEN "At Risk" 
        
        WHEN
            r_revenue_score >= 4 AND
            f_revenue_score <= 2 
        THEN "New customers"
        
        WHEN
            r_revenue_score = 1 AND 
            f_revenue_score = 1 
        THEN "Inactive" 
        ELSE "Other"
    END AS revenue_segment,

-- refund part
    monetary_client_refund,

    -- assign refund segment based on the combination of refund monetary values with the following logic:
    CASE
        WHEN 
            refund_ratio_pct = 0
        THEN "No refunds" 

        WHEN 
            0 < refund_ratio_pct <= 5
        THEN "Normal behavior" 
        
        WHEN 
            5 < refund_ratio_pct <= 15
        THEN "Moderate refunds"
        
        WHEN 
            15 < refund_ratio_pct <= 30
        THEN "High refund"  
        
        WHEN 
            refund_ratio_pct > 30
        THEN "Potential Abuse" 
        
    END AS refund_segment,

    -- assign refund segment based on the combination of refund frequency with the following logic:
    CASE
        WHEN 
            refund_transaction_ratio_pct = 0
        THEN "No refunds" 

        WHEN 
            0 < refund_transaction_ratio_pct <= 5
        THEN "Normal behavior" 
        
        WHEN 
            5 < refund_transaction_ratio_pct <= 15
        THEN "Moderate refunds"
        
        WHEN 
            15 < refund_transaction_ratio_pct <= 30
        THEN "High refund"  
        
        WHEN 
            refund_transaction_ratio_pct > 30
        THEN "Potential Abuse" 
        
    END AS refund_transactions_segment
FROM clients_scored),

-- CTE: group refund behavior segments into one segment for simplicity
segmented_refunds AS (
SELECT
    client_id,
    -- revenue part
    monetary_client_revenue,
    segment_revenue_code, 
    revenue_segment,

    -- Assign revenue segment rank for correct grouping in the final query
    CASE 
        WHEN revenue_segment = "Champions" THEN 1
        WHEN revenue_segment = "Loyal customers" THEN 2
        WHEN revenue_segment = "Big spenders" THEN 3
        WHEN revenue_segment = "At Risk" THEN 4
        WHEN revenue_segment = "New customers" THEN 5
        WHEN revenue_segment = "Inactive" THEN 6
        ELSE 7
    END AS revenue_segment_rank,

    -- refund part
    monetary_client_refund,

    -- combine frequency and monetary refund segments to simplify risk-assessment logic
    CASE
        WHEN 
            refund_transactions_segment = "No refunds" AND refund_segment = "No refunds"
        THEN "No refunds" 

        WHEN 
            refund_transactions_segment = "Normal behavior" AND refund_segment = "Normal behavior"
        THEN "Normal behavior" 
        
        WHEN 
            refund_transactions_segment = "High refund" AND refund_segment = "Normal behavior" 
        THEN "Potential Abuse"
        
        WHEN 
                refund_transactions_segment = "High refund" AND refund_segment = "High refund" 
        THEN "High-risk customer"  
        
        WHEN 
            refund_transactions_segment = "Normal behavior" AND refund_segment = "High refund" 
        THEN "Occasional large refunds" 

        ELSE "Other"
    END AS refunds_segment 
FROM segmented)

-- Main Query: final grouping of clients based on their revenue and refund segments with details about each segment combination
SELECT 
   revenue_segment,
   refunds_segment,
   COUNT(*) AS clients_in_segment,
   SUM(monetary_client_revenue) AS total_revenue_in_segment,
   SUM(monetary_client_refund) AS total_refund_in_segment
FROM segmented_refunds
GROUP BY revenue_segment, refunds_segment
ORDER BY revenue_segment_rank;

-- Insight: This segmentation combines customer value (RFM) with refund
-- behavior to identify high-value customers, at-risk groups, and clients
-- whose refund patterns may require closer review.


-- ============================================================================
-- Summary
-- ============================================================================
-- Phase 2 focuses on understanding how revenue changes over time and what may drive these changes.
-- Key insights:
-- - Revenue showed clear time-based variation, with both monthly fluctuations and broader year-level trends.
-- - Rolling 3-month revenue helped smooth short-term noise and made the overall trend easier to interpret.
-- - Seasonal analysis revealed that some calendar months consistently outperformed others on average.
-- - Refund levels remained trackable over time and could be compared against both revenue and transaction counts.
-- - Revenue changes were influenced by both transaction volume and average transaction value.
-- - Volatility analysis showed that revenue stability differed across years.
-- - Revenue per active client and per active card provided additional visibility into customer-level monetization.
-- - RFM-style segmentation highlighted high-value, loyal, new, and at-risk customer groups, while refund behavior added a useful risk lens.