import pandas as pd
import os
import glob
from io import StringIO

with open('/home/lanpirot/data/builder/archive3/modellist_synthed.csv', 'r') as f:
    csv_lines = f.readlines()

    # Join and load into pandas
    csv_str = ''.join(csv_lines)
    df = pd.read_csv(StringIO(csv_str), delimiter='\t')

df = df[df["model_url"].notna() & (df["model_url"] != "broken_model")]
df["needs_to_be_compilable"] = df["model_url"].apply(lambda x: int(x.split('archive3/')[1].split('/')[0]))

# Extract 'mode' (the part after the 0/1 and before the model name)
df["mode"] = df["model_url"].apply(lambda x: x.split('archive3/')[1].split('/')[1])

# Define the desired order for modes
mode_order = ["RANDOM", "AST_MODEL", "WIDTH", "DEPTH", "GIANT"]

# Convert 'mode' to a categorical type with the specified order
df["mode"] = pd.Categorical(df["mode"], categories=mode_order, ordered=True)

# Calculate the average of 'compilable' and 'runnable' for each combination of 'needs_to_be_compilable' and 'mode'
average_df = df.groupby(["needs_to_be_compilable", "mode"])[["compilable", "runnable"]].mean().reset_index()

# Sort the DataFrame by 'mode' using the categorical order
average_df = average_df.sort_values(by="mode")


# Display the result
print(average_df)


compilable_rows = df[df["compilable"] == 1]

# Sort by 'num_els' in descending order and select the top 10
top_10_rows = compilable_rows.nlargest(10, "num_els")

# Display the result
print(top_10_rows)
pass