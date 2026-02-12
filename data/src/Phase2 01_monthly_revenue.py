import pandas as pd                    
from sqlalchemy import create_engine
import matplotlib.pyplot as plt
import seaborn as sns


# Connect to SQL, use MySQL code and Retrieve Results in Pandas DataFrame
engine = create_engine(
    "mysql+pymysql://root:admin@localhost:3306/financial_transactions_dataset" )

# SQL Query to calculate monthly revenue
query = """
WITH clean_data AS -- CTE: Prepare data for further manipulations
      (SELECT
       DATE_FORMAT(date, '%%Y-%%m-01') as transaction_month,      -- changes date to year-month-01 for subsequent grouping by month 
       CAST(REPLACE(amount, '$', '') AS DECIMAL(10,2)) AS amount_cleaned -- removes dollar sign and formats to decimal for subsequent calc
      FROM transactions_data
      )
SELECT  -- Main Query: calculates revenue per month
  transaction_month,
  SUM(amount_cleaned) as monthly_revenue -- final revenue per month calculation
FROM clean_data
GROUP BY transaction_month
ORDER BY transaction_month;
"""
# Note: Always add % to "%X" from MySQL, because it conflicts with Python reading

df = pd.read_sql(query, engine) # Result


# Data manipulation for plotting data
df["transaction_month"] = pd.to_datetime(df["transaction_month"]) # Convert Date Column 
#MySQL → Pandas sometimes loads dates as text.

df["year"] = df["transaction_month"].dt.year # Extract year for grouping and plotting. Note: always after to_datetime conversion!
df = df.sort_values("transaction_month") # Sorting by date, to ensure correct order in the plot


# Used Pandas GROUP BY to calculate average monthly revenue per year, which will be used for the line plot of average monthly revenue per year. Then merged it back to the original df to have both monthly_revenue and avg_monthly_revenue in the same df for plotting.
yearly_avg_df = (                   
    df.groupby("year", as_index=False)["monthly_revenue"]
    .mean() # AVG
    .rename(columns={"monthly_revenue": "avg_monthly_revenue"})
)
df = df.merge(yearly_avg_df, on="year", how="left") # Merge with original df to get avg_monthly_revenue column


# Plotting the data with Matplotlib and Seaborn
plt.figure(figsize=(10,6))

sns.lineplot(
    data=df,
    x="transaction_month",
    y="monthly_revenue",
    label = "Monthly Revenue"
)   # Set data and axes for line plot
sns.lineplot(
    data=df,
    x="transaction_month",
    y="avg_monthly_revenue",
    label="Average Monthly Revenue per year"
)
# Adding labels and title to the plot
plt.title("Monthly Revenue Trend")
plt.xlabel("Months")
plt.ylabel("Revenue, mln $USD")
plt.xticks(rotation=45)

plt.tight_layout()
plt.show()

# Saving the plot as .png image
#plt.savefig("C:/.../monthly_revenue_trend.png") Note: an example of saving the plot as .png image
