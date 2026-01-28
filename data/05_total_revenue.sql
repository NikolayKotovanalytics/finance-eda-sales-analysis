-- TASK 5 Count Total Revenue from all transactions
-- Note. Revenue is in text format and contains negative values (refunds)

WITH clean AS 
    (SELECT         -- CTE. I learned that doing SUM as window function is significantly longer.
        client_id,
        card_id,
        amount,
        CAST(REPLACE(amount, '$', '') AS DECIMAL(10,2)) AS amount_cleaned -- Removes a dollar sign to clean data and converts result to decimal numbers
    FROM transactions_data)
SELECT      
    SUM(amount_cleaned) as total_revenue, -- 571835522.2799922
    SUM(
        CASE 
            WHEN amount_cleaned < 0 THEN amount_cleaned * -1  -- Converts negative value to positive
             ELSE 0
        END
    ) as total_refunds, -- -67519042.34
    SUM(
        CASE 
            WHEN amount_cleaned > 0 THEN amount_cleaned  -- Sums only positive values
             ELSE 0
        END
    ) as total_without_refunds -- 
FROM clean;

-- Conclusion: Total revenue over 10 years is about 571 mln USD. Total gross is 639 mln USD with refunds being -67.5 mln USD.