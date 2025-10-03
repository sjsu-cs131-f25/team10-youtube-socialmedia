#!/usr/bin/env bash
# great_in_comments.csv
# N is the frequency threshold (10 for this)

N="${N:-10}"
WORKDIR="/mnt/scratch/CS131_jelenag/projects/team10_sec3/team10-youtube-socialmedia/data/processed"
OUTDIR="$PWD/edges"
mkdir -p "$OUTDIR"

# 1) Count how many times the LEFT entity appears
cut -d, -f1 "$WORKDIR/great_in_comments.csv" | tail -n +2 | tr -d '\r' \
| sort | uniq -c | sort -nr \
| awk '{print $2 "\t" $1}' \
> "$OUTDIR/great_in_comments_entity_counts.tsv"

# 2) Keep only entities with frequency >= N (should only be great)
awk -F'\t' -v n="$N" '$2>=n{print $1}' "$OUTDIR/great_in_comments_entity_counts.tsv" \
| sort -u > "$OUTDIR/kept_great.txt"

# 3) Extract subgraph edges

{ head -n 1 "$WORKDIR/great_in_comments.csv"
  awk -F, 'NR==FNR {keep[$1]=1; next}
  FNR>1 && keep[$1]' "$OUTDIR/kept_great.txt" "$WORKDIR/great_in_comments.csv"
} > "$OUTDIR/great_in_comments_edges_thresholded.tsv"

echo "Done. Outputs in: $OUTDIR"
ls -lh "$OUTDIR"/great_in_comments_*tsv

