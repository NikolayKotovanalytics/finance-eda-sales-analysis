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
Phase 2 - Refunds and Active Customers Over Time

Purpose:
Visualize monthly refund amounts alongside active customer counts
to explore whether refund activity changes together with customer activity.

Outputs:
- Line chart saved to data/images/monthly_refunds_active_customers.png
"""



# Part 1. SQL Queries to calculate monthly refunds and active customer counts for SQLAlchemy connection and subsequent plotting with Matplotlib and Seaborn
#---------------------------------------------------------------------------------------------------------
# SQL Query to claculate monthly refunds and refund ratio percentage, as well as count of active customers per month

refunds_query = """
-- CTE: Prepare data for further calculcation of refunds and active customers
WITH monthly AS (
SELECT 
      transaction_month,
      COUNT(*) AS transactions_per_month,   -- counts total number of transactions per month
      COUNT(
            CASE
                  WHEN amount_cleaned < 0 THEN 1 
                  ELSE NULL
            END
      ) AS refund_transactions, -- counts number of refund transactions per month

      SUM(
            CASE 
                  WHEN amount_cleaned >= 0 THEN amount_cleaned
                  ELSE 0
            END
      ) AS monthly_gross_revenue, -- counts total monthly gross revenue
      
      SUM(
            CASE 
                  WHEN amount_cleaned < 0 THEN amount_cleaned * -1
                  ELSE 0
            END
      )  AS monthly_refunds   -- counts total monthly refunds and converts them to a positive value
FROM clean_transactions
GROUP BY transaction_month)

-- Main Query: final calculation of refund and income percentage ratio per month
SELECT 
  transaction_month,
  monthly_refunds,
  ROUND (
        100 * monthly_refunds / NULLIF((monthly_gross_revenue), 0), -- note: monthly refunds were converted to positive value during previous step
        2
      ) AS refund_ratio_pct,  -- final calculation of refund value ratio percentage of total income
  ROUND (
        100 * refund_transactions / NULLIF(transactions_per_month, 0),
        2
      ) AS refund_transactions_ratio_pct -- final calculation of refund transactions ratio percentage of total transactions
FROM monthly
ORDER BY transaction_month;
"""

# SQL Query to calculate count of active customers per month
active_customers_query = """
-- Query: calculation of unique active customers in each month
SELECT 
      transaction_month,
      COUNT(DISTINCT client_id) as active_customers -- count of unique customers
FROM clean_transactions
GROUP BY transaction_month
ORDER BY transaction_month;
"""


#---------------------------------------------------------------------------------------------------------
# Part 2. Connect Pandas with SQLAlchemy queries 
#---------------------------------------------------------------------------------------------------------

# connect refunds query
df_refunds = pd.read_sql(refunds_query, engine) 
df_refunds["transaction_month"] = pd.to_datetime(df_refunds["transaction_month"]) # Convert to Date Format, as MySQL → Pandas sometimes loads dates as text
df_refunds = df_refunds.sort_values("transaction_month") # Sorting by date, to ensure correct order in the plot

# connect active customers query
df_ac = pd.read_sql(active_customers_query, engine) 
df_ac["transaction_month"] = pd.to_datetime(df_ac["transaction_month"]) # Convert to Date Format, as MySQL → Pandas sometimes loads dates as text
df_ac = df_ac.sort_values("transaction_month") # Sorting by date, to ensure correct order in the plot

# Merge pandas dataframe to have refunds and active customers in the same dataframe for plotting 
df_plot = df_refunds.merge(df_ac, on="transaction_month", how="left") 

# Improve readability of the plot by dividing by 1000 because refunds are in hundreds thousands of USD
df_plot["monthly_refunds_thousands"] = df_plot["monthly_refunds"] / 1000


#---------------------------------------------------------------------------------------------------------
# Part 3. Plotting the data with Matplotlib and Seaborn
#---------------------------------------------------------------------------------------------------------
sns.set_theme(style="whitegrid")

# Plotting the data with dual Y-axes
fig, ax1 = plt.subplots(figsize=(11, 6))

# First Y-axis: Monthly Refunds 
sns.lineplot(
    data=df_plot,
    x="transaction_month",
    y="monthly_refunds_thousands",
    ax=ax1,
    color="tab:blue",
    label="Monthly Refunds"
)

ax1.set_xlabel("Year-Month")
ax1.set_ylabel("Monthly Refund Amount ($ Thousands)")
ax1.tick_params(axis="y")


# Second Y-axis: Active Customers 
ax2 = ax1.twinx()

sns.lineplot(
    data=df_plot,
    x="transaction_month",
    y="active_customers",
    ax=ax2,
    color="tab:orange",
    label="Active Customers",
)

ax2.set_ylabel("Active Customers")
ax2.tick_params(axis="y")


#  Title & formatting 
plt.title("Monthly Refunds vs Active Customers")
plt.xticks(rotation=45)

# Remove automatic legends created by seaborn
if ax1.get_legend() is not None:
    ax1.get_legend().remove()

if ax2.get_legend() is not None:
    ax2.get_legend().remove()

# Create one combined legend
lines_1, labels_1 = ax1.get_legend_handles_labels()
lines_2, labels_2 = ax2.get_legend_handles_labels()

ax1.legend(
    lines_1 + lines_2,
    labels_1 + labels_2,
    loc="lower right"
)

plt.tight_layout()

#Save the plot to the output folder
output_path = IMAGE_DIR / "monthly_refunds_vs_active_customers.png"
plt.savefig(output_path, dpi=300, bbox_inches="tight")

print(f"Plot saved to: {output_path}")

plt.show()
