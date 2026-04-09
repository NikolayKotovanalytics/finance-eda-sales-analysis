# Finance EDA – Revenue & Customer Analysis

## Objective
This project explores financial transaction behavior and fraud patterns to assess revenue stability, customer concentration risk, and transaction trends over time.

## Key Questions
- How does revenue evolve over time?
- Which customers contribute the most?
- Is revenue concentrated or diversified?
- Are purchase frequencies increasing or decreasing?
- Are there any potential fraud indicators?

## Dataset

This project uses a large public Kaggle dataset related to financial transactions and fraud detection.

Due to size and licensing constraints, the raw dataset is not included in this repository.

Dataset name:
Kaggle – Transactions Fraud Dataset

You can download the dataset here:
https://www.kaggle.com/datasets/computingvictor/transactions-fraud-datasets

See `/data/dataset_description.md` for full schema and details.

## Tools & Technologies

### Database & Querying
- MySQL
- CTEs
- Window Functions
- Time-Series Analysis
- Revenue & Customer Segmentation Queries

### Data Analysis
- Python
- pandas
- SQLAlchemy

### Data Visualization
- Matplotlib
- Seaborn
- Power BI

### Development
- Git
- GitHub

### Acknowledgements / AI Assistance
This project was developed with the assistance of AI tools.

ChatGPT (OpenAI) 5.3 was used for:

- code debugging and optimization suggestions
- reviewing Python and SQL queries
- improving data visualization implementation
- proofreading and refining sections of the project documentation (README)

All analysis design, interpretation of results, and final implementation decisions were performed by the author.
AI assistance was used strictly as a development aid, similar to consulting documentation or technical forums.

## Business Value

This analysis demonstrates how transaction data can be used to:

- Monitor revenue stability and seasonality
- Detect revenue concentration risk
- Identify high-value customer segments
- Detect potential fraud patterns
- Support marketing and retention strategies

===============================================================================================================================================================================
===============================================================================================================================================================================

## Phase 1 – Data Understanding

## Objective
Investigate dataset structure, detect missing data, identify active customers, time coverage, total revenue, refund volumes, and find data that may indicate fraud

**Dataset:** Kaggle – Transactions Fraud Dataset
**Entities:** Transactions, Users, Cards  

### Key insights
- Dataset is composed of 3 tables which contain data about transactions, bank cards and clients
- No missing data found (NULL)
- Dataset comprise 2000 unique clients who made ~13M transactions with unique 6146 bank cards
- Out of 2000 clients listed, 1219 active clients, i.e. with at least one transaction. An Id list of non-active customers is shown
- Out of 6146 bank cards, 2075 cards performed 0 transactions. An Id list of their clients is shown
- Dataset covers a period from 2010/01/01 till 2019/10/31, i.e. 3590 days in total
- Total transaction value: ~$571M which includes gross income $639M and -$67.5M refunds
- Cards data contains information about cards presence on Darkweb. None cards were noted there
- Data was checked for fraud indicators: No card numbers were used twice and 0 cards without a registered client were found

SQL scripts: `/data/sql/phase_1_understand_data.sql`

===============================================================================================================================================================================

##  Phase 2 – Time-Based Revenue Analysis (EDA)

## Objective
Analyze revenue dynamics over time to identify trends, seasonality, volatility, customer activity patterns, and refund behavior in a large financial transactions dataset.

**Dataset:** Kaggle – Transactions Fraud Dataset  
**Entities:** Transactions, Cards  

Key Analyses Performed

1. Monthly Revenue Trends
Aggregated transaction amounts by month to observe long-term revenue evolution from 2010 to 2019.

2. Month-over-Month (MoM) Revenue Change
Calculated absolute and percentage MoM revenue changes using window functions to identify growth acceleration and slowdowns.

3. Rolling 3-Month Revenue
Applied rolling window aggregation to smooth short-term volatility and highlight underlying revenue trends.

4. Yearly Revenue and Refunds
Summarized total revenue and total refund amounts by year to assess long-term business growth and operational risk.

5. Seasonality Analysis
Computed average monthly revenue across years and ranked months to detect recurring seasonal patterns.

6. Transaction Volume vs Revenue
Compared transaction counts with total revenue to derive average transaction value per month.

7. Refund Trend Over Time
Analyzed refund volumes and refund transaction ratios to assess operational risk and customer behavior.

8. Revenue Volatility by Year
Calculated standard deviation of monthly revenue per year to measure financial stability and risk exposure.

9. Revenue per Active Customer / per Bank Card
Measured average gross revenue per active customer and per card per month to evaluate monetization efficiency.

10. RFM Segmentation with Refund Behavior (Value vs Risk Analysis)
Combined Recency, Frequency, and Monetary (RFM) metrics with refund behavior to classify clients into revenue and refund segments.

- Revenue segments were ranked hierarchically: Champion > Loyal > Big spenders > At Risk > New > Inactive
- Refund behavior was classified by monetary and frequency-based ratios into No refunds, Normal behavior, Occasional large refunds, High-risk customer, Potential Abuse
- Final segmentation allows identifying high-value clients, at-risk customers, and potential refund abuse cases.

11. Data Safety Checks – Card Expiration Validation
Verified whether any transactions occurred after the respective bank card had expired.

- Identified client IDs, card IDs, and transaction dates where the transaction occurred after card expiration.
- Helps detect potential operational errors or fraudulent activity.

### Key Insights

- Revenue exhibits long-term growth with pronounced seasonal variations.
- Certain years show increased revenue volatility, indicating higher financial risk.
- Refund ratios remain relatively stable but spike during specific periods, warranting further investigation.
- Hierarchical RFM segmentation allows prioritizing marketing efforts and detecting potential refund abuse while maintaining a value vs risk perspective.
- Card expiration checks revealed transactions post-expiration, highlighting operational or security issues that require attention.

SQL scripts: `/data/sql/phase_2_time_based_analysis`

## Selected data was plotted as graphs
Visualizations: `/data/images/Phase_2`  
Python plotting scripts: `/data/src`

===============================================================================================================================================================================

## Phase 3 — Customer Behavior & Revenue Structure  (EDA)

## Objective
Analyze customer purchasing behavior, revenue distribution, customer lifecycle patterns, and potential fraud signals in a financial transactions dataset.

**Dataset:** Kaggle – Transactions Fraud Dataset  
**Period:** 2010 – 2019  
**Entities:** Transactions, Cards  

Key Analyses Performed

1. Top 20 Clients by Revenue 
Identified highest revenue-generating customers.

2. Revenue share generated of Top 10% of customers
Measured revenue concentration among top-performing customers.

3. Customer Purchase Frequency Segmentation
Segmented customers into frequency groups using percentile ranking based on lifetime monthly purchase behavior.

Additionally analyzed:
- average purchase frequency per group
- customer-level refund behavior
- business-level refund impact

4. Average Days Between Purchases
Calculated average time between purchases per customer to understand engagement patterns.

5. Customer Segmentation by Total Orders
Grouped customers into quartiles based on total number of purchases.

6. Revenue vs Frequency Matrix
Built a 2 x 2 matrix to segmentation using average-based thresholds:

High Revenue / High Frequency
High Revenue / Low Frequency
Low Revenue / High Frequency
Low Revenue / Low Frequency

Used for identifying:
- high-value customers
- underperforming segments with growth potential

7. Refund ratio per customer
Calculated refund share per customer to detect abnormal return behavior.

8. Dormant Customer Reactivation Spike
Identified customers generating significant revenue after periods of inactivity (>60 days).
Measured reactivation impact as share of total customer revenue to detect:
- successful reactivation
- unusual spending spikes (potential fraud signal)

9.  Card Sharing Detection
Identified cards used by multiple clients as a potential fraud indicator.

### Key Insights

 Revenue is concentrated among a relatively small group of high-value customers.
- Customer behavior varies significantly in purchase frequency and engagement cycles.
- Frequency segmentation combined with revenue highlights actionable customer groups for marketing strategies.
- Refund behavior analysis reveals both normal patterns and potential anomalies.
- Potential fraud indicators were analyzed using:
  1. high refund ratios
  2. abnormal reactivation spikes
  3. shared card usage

SQL scripts: `/data/sql/phase_3_phase_3_customer_behavior_and_revenue_structure.sql`

===============================================================================================================================================================================

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

