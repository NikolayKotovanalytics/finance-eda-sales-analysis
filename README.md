# Finance EDA – Revenue & Customer Analysis

## Objective
This project explores financial transaction behavior and fraud patterns to assess revenue stability, customer concentration risk, and transaction trends over time.

## Tools Used
- MySQL (CTEs, Window Functions, Date Functions)
- SQL for EDA
- GitHub for version control

## Key Questions
- How does revenue evolve over time?
- Which customers contribute the most?
- Is revenue concentrated or diversified?
- Are purchase frequencies increasing or decreasing?

## Key Insights

## Dataset
This project uses a large public Kaggle dataset related to financial transactions and fraud detection.

Due to size and licensing constraints, the raw dataset is not included in this repository.

You can download the dataset here:
https://www.kaggle.com/datasets/computingvictor/transactions-fraud-datasets

See `/data/dataset_description.md` for full schema and details.
===============================================================================================================================================================================

## Phase 1 – Data Understanding

## Objective
Investigate the structure of the dataset, Check for missing data, find active customers, time range, total revenue, total refunds in a large financial transactions dataset.

**Dataset:** Kaggle – Transactions Fraud Dataset  
**Period:** 2010–2019  
**Entities:** Customers, Cards, Transactions  

### Key Findings
- 2000 registered customers
- 1219 active customers with transactions
- No NULL values detected
- Total transaction value: ~$571M
- Gross income and Refunds calculated

===============================================================================================================================================================================

##  Phase 2 – Time-Based Revenue Analysis (EDA)

## Objective
Analyze revenue dynamics over time to identify trends, seasonality, volatility, customer activity patterns, and refund behavior in a large financial transactions dataset.

**Dataset:** Kaggle – Transactions Fraud Dataset  
**Period:** 2010–2019  
**Entities:** Transactions  

Key Analyses Performed

1. Monthly Revenue Trends
Aggregated transaction amounts by month to observe long-term revenue evolution from 2010 to 2019.

2. Month-over-Month (MoM) Revenue Change
Calculated absolute and percentage MoM revenue changes using window functions to identify growth acceleration and slowdowns.

3. Rolling 3-Month Revenue
Applied rolling window aggregation to smooth short-term volatility and highlight underlying revenue trends.

4. Yearly Revenue Growth
Summarized total revenue by year to assess long-term business growth.

5. Seasonality Analysis
Computed average monthly revenue across years and ranked months to detect recurring seasonal patterns.

6. Transaction Volume vs Revenue
Compared transaction counts with total revenue to derive average transaction value per month.

7. Refund Trends Over Time
Analyzed refund volumes and refund transaction ratios to assess operational risk and customer behavior.

8. Revenue Volatility by Year
Calculated standard deviation of monthly revenue per year to measure financial stability and risk exposure.

9. Active Customers Over Time
Tracked the number of unique active customers per month to understand customer engagement trends.

10. Revenue per Active Customer
Measured average gross revenue per active customer per month to evaluate monetization efficiency.

### Key Insights

- Revenue exhibits strong long-term growth with noticeable seasonal effects.
- Certain years show increased revenue volatility, indicating higher financial risk.
- Active customer counts fluctuate independently from revenue, highlighting changes in spending behavior.
- Refund ratios remain relatively stable but spike during specific periods, warranting further investigation.

===============================================================================================================================================================================

