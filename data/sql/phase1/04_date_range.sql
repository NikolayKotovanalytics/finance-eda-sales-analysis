-- TASK 4 Assess time range of the dataset

SELECT 
    MIN(date) as  first_date, -- 2010-01-01 00:01:00
    MAX(date) as final_date -- 2019-10-31 23:59:00
FROM transactions_data t;


 -- Conclusion: Dataset covers total 10 years from start of 2010 till end of 2019.
