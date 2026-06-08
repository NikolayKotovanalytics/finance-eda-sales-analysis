# Dataset Description

## Dataset Name
Transactions Fraud Dataset

## Source
Kaggle – Computing Victor  
https://www.kaggle.com/datasets/computingvictor/transactions-fraud-datasets

## License
Dataset provided by Kaggle under its respective usage license.  
The raw data is not included in this repository.

## Files Used
- `transactions_data.csv`
- `users_data.csv`
- `cards_data.csv`

## Size
~13+ million transaction records

## Description
This dataset contains financial transaction records including:
- Transaction timestamps
- Transaction amounts
- Transaction types
- User identifiers
- User demographic information 
- User account-related details
- Card identifiers
- Card limits
- Card types
- Card activation dates
- Merchant categories


The dataset simulates real-world financial transaction behavior and fraud patterns.

## Table Schema

### users_data
- id
- current_age
- retirement_age
- birth_year
- birth_month
- gender
- address
- latitude
- longitude
- per_capita_income
- yearly_income
- total_debt
- credit_score
_num_credit_cards

### transactions_data
- id
- date
- client_id
- card_id
- amount
- use_chip
- merchant_id
- merchant_city
- merchant_state
- zip
- mcc
- errors

### cards_data
- id
- client_id
- card_brand
- card_type
- card_numbr
- expires
- cvv
- has_chip
- num_cards_issued
- credit_limit
- acct_open_date
- year_pin_last_changed
- card_on_dark_web

## Purpose in This Project
The dataset is used to:
- Analyze transaction behavior over time
- Identify revenue and fraud concentration
- Explore customer transaction frequency
- Study fraud risk patterns

