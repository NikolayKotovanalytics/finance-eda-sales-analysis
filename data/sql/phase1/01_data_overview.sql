-- TASK 1 Overview data --
DESCRIBE cards_data;
-- Contains info about clients and detailed info the payment cards which they use

SELECT
    card_on_dark_web,
    COUNT(*) AS card_count
FROM cards_data
GROUP BY card_on_dark_web;

-- Note. Info about if clients card is present on Darkweb is avaliable.
-- The data suggests that none of the credit cards is on Darkweb.

DESCRIBE users_data;
-- Contains detailed info about clients, their age, address, and their income, debt
-- Note. One customer may have several credit cards
DESCRIBE transactions_data;
-- Contains detailed info about purchases the clients did with their cards.

-- Conclusion: Dataset comprises detailed data about clients, their personal data, their addresses, 
-- their finansial accounts and credit cards (with details), transactions performed with these cards,
-- and additional information that could help reveal fraudulent activity.
