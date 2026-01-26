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
~10+ million transaction records

## Description
This dataset contains financial transaction records including:
- Transaction timestamps
- Transaction amounts
- User identifiers
- Card identifiers
- Merchant categories
- Fraud labels

The dataset simulates real-world financial transaction behavior and fraud patterns.

## Key Tables (Logical Model)

### users_data
- user_id
- age
- country
- signup_date

### transactions_data
- transaction_id
- user_id
- card_id
- transaction_date
- amount
- merchant_category
- is_fraud

### cards_data
- card_id
- card_type
- issue_date

## Purpose in This Project
The dataset is used to:
- Analyze transaction behavior over time
- Identify revenue and fraud concentration
- Explore customer transaction frequency
- Study fraud risk patterns

## How to Reproduce
1. Download the dataset from Kaggle
2. Load CSV files into MySQL
3. Run SQL scripts from the `/sql` directory

