import pandas as pd
import os
import glob
from io import StringIO

def extract_csv_part(filepath):
    with open(filepath, 'r') as f:
        lines = f.readlines()

    # Extract mode and needs_to_be_compilable from the header
    mode = None
    needs_to_be_compilable = None
    for line in lines:
        if line.strip().startswith("mode:"):
            mode = line.split("'")[1]
        elif line.strip().startswith("needs_to_be_compilable:"):
            needs_to_be_compilable = int(line.split(":")[1].strip())

    # Find the start of the CSV table (line starting with 'model_no,')
    start = 0
    while start < len(lines) and not lines[start].strip().startswith('model_no,'):
        start += 1

    # Find the end of the CSV table (line starting with '========END REPORT:')
    end = start + 1
    while end < len(lines) and not (lines[end].strip().startswith('mode:') or lines[end].strip().startswith('tries:')):
        end += 1

    # Extract the CSV lines
    csv_lines = lines[start:end]

    # Join and load into pandas
    csv_str = ''.join(csv_lines)
    df = pd.read_csv(StringIO(csv_str))

    # Add mode and needs_to_be_compilable as columns
    df['mode'] = mode
    df['needs_to_be_compilable'] = needs_to_be_compilable

    return df

def process_directory(directory):
    all_dfs = []
    for filepath in glob.glob(os.path.join(directory, '**', 'synth_report.csv'), recursive=True):
        if '/archive3/' not in filepath:
            continue
        try:
            df = extract_csv_part(filepath)
            all_dfs.append(df)
            print(f"Processed: {filepath}")
        except Exception as e:
            print(f"Error processing {filepath}: {e}")

    if all_dfs:
        combined_df = pd.concat(all_dfs, ignore_index=True)
        return combined_df
    else:
        return print("No valid data found.")