-- TASK 3 Count unique Customers/Clients 

SELECT 
    COUNT(id),   -- 6146
    COUNT(DISTINCT id), -- 6146
    COUNT(client_id), -- 6146
    COUNT (DISTINCT client_id) -- 2000
FROM cards_data c;

SELECT 
        COUNT(id),  -- 2000
        COUNT(DISTINCT id) -- 2000   
FROM users_data u; 

SELECT 
    COUNT(client_id),   -- 13305915
    COUNT(DISTINCT client_id)  --1219,
    MIN(date) as  first_date, -- 2010-01-01 00:01:00
    MAX(date) as final_date -- 2019-10-31 23:59:00
FROM transactions_data t;

-- Conclusion: There  2000 unique registered clients in the dataset, 1219 of whom are active clients, i.e. performed at least one transaction.
