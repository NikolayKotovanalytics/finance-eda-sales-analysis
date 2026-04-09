import pandas as pd
import matplotlib.pyplot as plt
import seaborn as sns

from db import get_db_engine

engine = get_db_engine()

# SQL Query to claculate monthly refunds and refund ratio percentage, as well as count of active customers per month
query_refunds = """
WITH clean_data AS -- CTE: Prepare data for further manipulations
      (SELECT
       DATE_FORMAT(date, '%%Y-%%m-01') as transaction_month,      -- changes date to year-month-01 for subsequent grouping by month 
       CAST(REPLACE(amount, '$', '') AS DECIMAL(10,2)) AS amount_cleaned -- removes dollar sign and formats to decimal for subsequent calc
      FROM transactions_data
      ),
monthly AS -- CTE: Prepare data for further manipulations
      (
      SELECT 
        transaction_month,
        COUNT(*) AS transactions_per_month,   -- counts total number of transactions per month
        COUNT(
              CASE
                 WHEN amount_cleaned < 0 THEN 1 
                 ELSE 0
              END) AS refund_transactions, -- counts number of refund transactions per month
        SUM(
          CASE 
              WHEN amount_cleaned > 0 THEN amount_cleaned
              ELSE 0
          END) AS monthly_income, -- counts total monthly income
        SUM(
          CASE 
              WHEN amount_cleaned < 0 THEN amount_cleaned * -1
              ELSE 0
          END
        )  AS monthly_refunds   -- counts total monthly refunds and converts them to a positive value
      FROM clean_data
      GROUP BY transaction_month
      )
SELECT -- Main Query: final calculation of refund and income percentage ratio per month
  transaction_month,
  monthly_refunds,
  ROUND (
        100 * monthly_refunds / (monthly_income + monthly_refunds), -- note: monthly refunds were converted to positive value during previous step
        2
        ) AS refund_ratio_pct,  -- final calculation of refund value ratio percentage of total income
  ROUND (
        100 * refund_transactions / transactions_per_month,
        2
        ) AS refund_transactions_ratio_pct -- final calculation of refund transactions ratio percentage of total transactions
FROM monthly
ORDER BY transaction_month;
"""

df_refunds = pd.read_sql(query_refunds, engine) # Result
df_refunds["transaction_month"] = pd.to_datetime(df_refunds["transaction_month"]) # Convert to Date Format 
#MySQL → Pandas sometimes loads dates as text.

df_refunds = df_refunds.sort_values("transaction_month") # Sorting by date, to ensure correct order in the plot

# SQL Query to calculate count of active customers per month
query_active_customers = """
WITH clean_data AS -- CTE: Prepare data for further manipulations
      (SELECT
            client_id,
            DATE_FORMAT(date, '%%Y-%%m-01') as transaction_month      -- changes date to year-month-01 for subsequent grouping by month 
       FROM transactions_data
      )
SELECT -- Main Query: calculation of unique active customers in each month
      transaction_month,
      COUNT(DISTINCT client_id) as active_customers -- final count of unique customers
FROM clean_data
GROUP BY transaction_month
ORDER BY transaction_month;
"""

df_ac = pd.read_sql(query_active_customers, engine) # Result
df_ac["transaction_month"] = pd.to_datetime(df_ac["transaction_month"]) # Convert to Date Format 
#MySQL → Pandas sometimes loads dates as text.

df_plot = df_refunds.merge(df_ac, on="transaction_month", how="left") # Merge pandas dataframe to have refunds and active customers in the same dataframe for plotting 


#Plotting the data with dual Y-axes

fig, ax1 = plt.subplots(figsize=(10, 6))

# First Y-axis: Monthly Refunds 
sns.lineplot(
    data=df_plot,
    x="transaction_month",
    y="monthly_refunds",
    ax=ax1,
    color="tab:blue",
    label="Monthly Refunds",
    legend=False
)

ax1.set_xlabel("Month")
ax1.set_ylabel("Monthly Refunds, $USD")
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
    legend=False
)

ax2.set_ylabel("Active Customers")
ax2.tick_params(axis="y")
legend=False

#  Title & formatting 
plt.title("Monthly Refunds vs Active Customers")
plt.xticks(rotation=45)

# Legend (combine both axes) 
lines_1, labels_1 = ax1.get_legend_handles_labels()
lines_2, labels_2 = ax2.get_legend_handles_labels()
ax1.legend(lines_1 + lines_2, labels_1 + labels_2, loc="lower right")

plt.tight_layout()
plt.show()

# Save result as .png figure
# fig.savefig("C:/.../monthly_refunds_ac_trend.png") example of saving the plot as .png image
