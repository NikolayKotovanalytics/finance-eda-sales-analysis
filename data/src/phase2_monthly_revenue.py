import pandas as pd
import matplotlib.pyplot as plt
import seaborn as sns
from pathlib import Path

from db import get_db_engine

# Output folder
IMAGE_DIR = Path("data/images")
IMAGE_DIR.mkdir(parents=True, exist_ok=True)

engine = get_db_engine()


"""
Phase 2 - Monthly Revenue Trend

Purpose:
Visualize monthly net revenue to explore revenue trend variations with time and compare it it's average yearly trend.

Outputs:
- Line chart saved to data/images/monthly_revenue_trend.png

"""

#---------------------------------------------------------------------------------------------------------
# Part 1. SQL Query to calculate monthly net revenue for SQLAlchemy connection and subsequent plotting with Matplotlib and Seaborn
#---------------------------------------------------------------------------------------------------------

# SQL Query to calculate monthly net revenue
monthly_net_revenue_query = """
-- Query: calculates net revenue per month
SELECT  
    transaction_month,
    SUM(amount_cleaned) as monthly_net_revenue
FROM clean_transactions
GROUP BY transaction_month
ORDER BY transaction_month;
"""


#---------------------------------------------------------------------------------------------------------
# Part 2. Connect Pandas with SQLAlchemy queries 
#---------------------------------------------------------------------------------------------------------

# connect refunds query
df = pd.read_sql(monthly_net_revenue_query, engine)
df["transaction_month"] = pd.to_datetime(df["transaction_month"]) # Convert to Date Format, as MySQL → Pandas sometimes loads dates as text
df["year"] = df["transaction_month"].dt.year # Extract year for grouping and plotting
df = df.sort_values("transaction_month") # Sorting by date, to ensure correct order in the plot


# Use Pandas GROUP BY to calculate average monthly net revenue per year, which will be used for the line plot of average monthly revenue per year
yearly_avg_df = (                   
    df.groupby("year", as_index=False)["monthly_net_revenue"]
    .mean() # same function as MySQL "AVG"
    .rename(columns={"monthly_net_revenue": "avg_monthly_net_revenue_within_year"})
)

# Merge with original df to have net revenue and average net revenue in the same dataframe for plotting
df = df.merge(yearly_avg_df, on="year", how="left")

# Improve readability of the plot by dividing by 1 million because net revenue is in millions of USD
df["monthly_net_revenue_millions"] = df["monthly_net_revenue"] / 1000000
df["avg_monthly_net_revenue_within_year_millions"] = (
    df["avg_monthly_net_revenue_within_year"] / 1000000
)



#---------------------------------------------------------------------------------------------------------
# Part 3. Plotting the data with Matplotlib and Seaborn
#---------------------------------------------------------------------------------------------------------

sns.set_theme(style="whitegrid")

# Plotting the data
fig, ax = plt.subplots(figsize=(11, 6))

# Set data and axes for line plot for month 
sns.lineplot(
    data=df,
    x="transaction_month",
    y="monthly_net_revenue_millions",
    ax=ax,
    label = "Monthly Net Revenue"
)   

sns.lineplot(
    data=df,
    x="transaction_month",
    y="avg_monthly_net_revenue_within_year_millions",
    ax=ax,
    label="Average Monthly Net Revenue Within Year"
)

ax.set_title("Monthly Net Revenue Over Time")
ax.set_xlabel("Year-Month")
ax.set_ylabel("Net Revenue ($ Millions)")
ax.tick_params(axis="x", rotation=45)

plt.tight_layout()

#Save the plot to the output folder
output_path = IMAGE_DIR / "monthly_revenue_trend.png"
plt.savefig(output_path, dpi=300, bbox_inches="tight")

print(f"Plot saved to: {output_path}")

plt.show()
