import argparse

import csv
import pandas as pd
import matplotlib.pyplot as plt
def sniff_delimiter(path):
with open(path, 'r', newline='') as f:
 sample = ''.join([next(f) for _ in range(5)])
dialect = csv.Sniffer().sniff(sample, delimiters=[',','\t',';','|'])
return dialect.delimiter

def load_edges(path, has_header, left_col, right_col, delimiter):
    if delimiter == "auto":
        delimiter = sniff_delimiter(path)
    if has_header:
        df = pd.read_csv(path, sep=delimiter)
        # Use provided column names if available, else fall back to first two cols
        if left_col and right_col and left_col in df.columns and right_col in df.columns:
            df = df.rename(columns={left_col:"left_entity", right_col:"right_entity"})
        else:
            first_two = list(df.columns[:2])
            df = df.rename(columns={first_two[0]:"left_entity", first_two[1]:"right_entity"})
    else:
        df = pd.read_csv(path, sep=delimiter, header=None, usecols=[0,1],
                         names=["left_entity","right_entity"])
    return df[["left_entity","right_entity"]]
def main():
    ap = argparse.ArgumentParser(description="Step 3: Histogram of cluster sizes (bin size = 1).")
    ap.add_argument("input", help="Edges file (CSV/TSV).")
    ap.add_argument("--has-header", action="store_true", help="Set if input has a header row.")
    ap.add_argument("--left-col", default=None, help="Column name to use as left_entity (if header).")
    ap.add_argument("--right-col", default=None, help="Column name to use as right_entity (if header).")
    ap.add_argument("--delimiter", default="auto", help="Delimiter: auto, ',', '\\t', ';', '|' (default: auto)")
    args = ap.parse_args()
edges = load_edges(args.input, args.has_header, args.left_col, args.right_col, args.delimiter)

cluster_sizes = (
        edges.groupby("left_entity")["right_entity"]
             .count()
             .reset_index()
             .rename(columns={"left_entity":"entity_id", "right_entity":"cluster_size"})
    )
cluster_sizes.to_csv("cluster_sizes.tsv", sep="\t", index=False)

if len(cluster_sizes) and cluster_sizes["cluster_size"].max() > 0:
        bins = range(1, int(cluster_sizes["cluster_size"].max()) + 2)
        plt.figure(figsize=(8,6))
        plt.hist(cluster_sizes["cluster_size"], bins=bins, edgecolor="black")
        plt.title("Histogram of Cluster Sizes")
        plt.xlabel("Cluster Size (# of edges)")
        plt.ylabel("Frequency (# of entities)")
        plt.tight_layout()
        plt.savefig("cluster_histogram.png")
        plt.close()
        print("✅ Wrote cluster_sizes.tsv and cluster_histogram.png")
    else:
        print("⚠️ No clusters found. Wrote cluster_sizes.tsv; skipped plot.")

if __name__ == "__main__":
    main()
