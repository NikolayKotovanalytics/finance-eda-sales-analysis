# Finance EDA Sales Analysis

## Project Summary
This project analyzes large-scale finance and sales transaction data to identify revenue trends, customer behavior patterns, refund activity, and potential payment anomalies.

The analysis combines:
- MySQL for data cleaning, transformation, and business analysis
- Python (pandas, matplotlib, seaborn) for EDA and visualizations
- Power BI for dashboarding and stakeholder reporting

## Business Questions
- How does revenue change over time?
- Are there seasonal or monthly patterns in sales?
- Which customers contribute most of the revenue?
- How do refunds relate to active customer trends?
- Are there suspicious transactions, such as payments after card expiration?

## Key Findings
- Revenue shows clear time-based variation and seasonal patterns
- A small group of customers contributes a disproportionately high share of revenue
- Refund spikes appear in specific periods and deserve operational review
- Transactions after card expiration suggest possible control or data-quality issues

## Tools Used
MySQL, Python, pandas, matplotlib, seaborn, SQLAlchemy, Power BI

## Project Deliverables
- SQL analysis scripts
- Python visualization scripts and exported charts
- Dashboard screenshots / Power BI reporting

## Repository Structure
```text
finance-eda-sales-analysis/
├── README.md
├── requirements.txt
├── .gitignore
├── data/
│   ├── sql/
│   ├── src/
│   ├── images/
│   └── dashboards/
```

### Folder Details
- `data/sql/` - SQL scripts used for transformations and analysis
- `data/src/` - Python scripts for database extraction and plotting
- `data/images/` - Exported charts used in the README and reporting
- `data/dashboards/` - Power BI dashboard screenshots or files

## How to Run This Project

### 1. Clone the repository

```bash
git clone https://github.com/NikolayKotovanalytics/finance-eda-sales-analysis.git
cd finance-eda-sales-analysis
```

### 2. Create and activate a virtual environment

**Windows**
```bash
python -m venv venv
```
```bash
venv\Scripts\activate
```

### 3. Install project dependencies
```bash
pip install -r requirements.txt
```

### 4. Download the dataset

This project uses the public Transactions Fraud Dataset from Kaggle.

Download it from Kaggle at:

https://www.kaggle.com/datasets/computingvictor/transactions-fraud-datasets

Raw data is not included in this repository due to size and licensing constraints.

### 5. Create the MySQL database and import the dataset tables
```sql
CREATE DATABASE financial_transactions_dataset;
```
Then import the dataset tables into that database.

### 6. Configure database credentials

Create a `.env` file in the project root:
```env
DB_HOST=localhost
DB_PORT=3306
DB_NAME=financial_transactions_dataset
DB_USER=your_username
DB_PASSWORD=your_password
```

### 7. Run scripts and review outputs

- SQL analysis scripts: `data/sql/`

Recommended order:
1. `phase_1_understand_data.sql`
2. `phase_2_time_based_analysis.sql`
3. `phase_3_customer_behavior_and_revenue_structure.sql`
4. `phase_4_fraud_and_anomaly_analysis.sql`
 
- Python scripts: `data/src/`

After the database is set up, run the Python scripts in data/src/ to generate charts:
```bash
python data/src/phase2_monthly_revenue.py
python data/src/phase2_refunds_active_customers.py
```
- Visualizations: `data/images/` 


## Dataset Overview
The project uses a large transaction-level dataset containing approximately 13 million transaction records and supports time-based, customer-level, and payment-related analysis.

Main entities analyzed include:
- Transactions
- Customers
- Revenue amounts
- Refund events
- Card/payment attributes
- Time dimensions

See `/data/dataset_description.md` for full schema and details.

## Acknowledgements / AI Assistance
AI tools - ChatGPT (OpenAI) was used for code review, debugging, and documentation refinement. All analysis design, interpretation of results, and final implementation decisions were performed by the author.

## Business Value

This analysis demonstrates how transaction data can be used to:

- Monitor revenue stability and seasonality
- Detect revenue concentration risk
- Identify high-value customer segments
- Detect potential fraud patterns
- Support marketing and retention strategies

## Methodology

### Phase 1 — Data Understanding and Preparation
**Goal:** Understand the dataset structure and prepare the data for analysis in MySQL  
**Tasks completed:**
- validated table structure and column definitions
- reviewed key fields and relationships
- checked nulls and general data consistency
- collected overall dataset statistics, including:
  - total clients, cards, and transactions
  - total time period covered by the dataset
  - total revenue, refunds, and net revenue
- cleaned and standardized the data for further analysis

### Phase 2 — Time-Based Analysis
**Goal:** Understand seasonality of revenue and refunds trends from various perspectives and at various time scales    
**Techniques used:**
- aggregations and conditional aggregations
- date transformations and time-based grouping
- window functions for month-over-month and rolling calculations
- trend and seasonality analysis
- refund ratio and volatility analysis
- customer activity metrics, including revenue per active client and card

### Phase 3 — Customer Behavior and Revenue Structure
**Goal:** Understand how revenue is distributed across customers and how customer purchase behavior differs across segments  
**Techniques used:**
- customer ranking and revenue concentration analysis
- contribution analysis for top customers
- purchase frequency and order-volume segmentation
- average time-between-purchase analysis
- revenue-versus-frequency matrix segmentation
- refund ratio analysis at the customer level

### Phase 4 — Fraud / Anomaly Analysis
**Goal:** Identify suspicious patterns, data integrity issues, and unusual card or customer behavior that may require further investigation  
**Focus areas:**
- cards flagged on the dark web
- duplicate card numbers and possible card-sharing patterns
- cards without clients or transactions
- clients without recorded transactions
- transactions after card expiration dates
- unusual client reactivation after long inactivity periods

## Key Insights
```text
|    Analysis Area  |                      Finding                   |                  Business Implication                |
|-------------------|------------------------------------------------|------------------------------------------------------|
|   Revenue Trends  |           Visible seasonality of Revenue       |    Useful for planning, forecasting, and staffing    |
| Customer Revenue  |   Revenue is concentrated among top customers  |  Indicates retention risk if key customers are lost  |
|  Refund Activity  |     Refund spikes occur in specific periods    | Worth investigating for operational or policy issues |
| Payment Anomalies | Some transactions appear after card expiration |    May indicate data-quality or control weaknesses   |
```

## Dashboard & Data Visualization

An interactive Power BI dashboard was developed to present key financial metrics,
revenue trends, and customer behavior insights derived from the EDA.

This dashboard demonstrates how analytical outputs can be translated into
decision-support tools for business stakeholders.

### Key Features

- Revenue and refund trends over time
- Customer activity and transaction patterns
- Financial behavior segmentation
- Comparison across transaction types and payment methods

### Preview

A static preview is available in:
`/data/dashboards/screenshots/ftb_Revenue_and_Returns_dashboard.png`

### File

The full interactive Power BI (.pbix) file can be downloaded here:

https://drive.google.com/file/d/1wL0z1XCwDGNyfbKGTKyleXwxc9j4jrvc/view?usp=drive_link

*To explore the dashboard, download and open it in Power BI Desktop.*

===============================================================================================================================================================================
===============================================================================================================================================================================
## EDA Conclusions

The database was investigated for structure, completeness, and missing values.  
Multiple analytical metrics were applied to analyze revenue trends and customer behavior.  
Refund patterns, customer reactivation spikes, and card usage were analyzed to identify potential fraud indicators.

## Business Recommendations
- Monitor revenue seasonality to improve planning and campaign timing
- Investigate refund spikes by product, region, or operational process
- Build retention strategies for high-value customers
- Review payment validation rules for transactions involving expired cards

## Limitations
- The analysis is based on the available synthetic dataset and may not reflect missing external business context
- Suspicious transaction patterns are indicators, not proof of fraud
- Some findings may require product, region, or channel-level breakdown for deeper interpretation