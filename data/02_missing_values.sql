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