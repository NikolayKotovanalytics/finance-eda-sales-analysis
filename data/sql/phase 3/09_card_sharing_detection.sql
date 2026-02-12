-- Task 9 Card Sharing Detection

WITH suspicious_cards AS -- CTE: find cards with several users
(
    SELECT card_number
    FROM cards_data
    GROUP BY card_number
    HAVING COUNT(DISTINCT client_id) > 1 -- filters cards with more than 1 unique user
)

SELECT DISTINCT -- Main query: find card-client pairs for cards with more than 1 unnique user
    c.card_number,
    c.client_id
FROM cards_data c
JOIN suspicious_cards s -- Join with original table to find respective card-client pairs
    ON c.card_number = s.card_number
ORDER BY c.card_number;