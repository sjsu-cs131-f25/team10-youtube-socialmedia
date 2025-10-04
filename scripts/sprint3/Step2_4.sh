#!/usr/bin/env bash
# Build entity counts + thresholded edges + Top-30 for all 4 edge CSVs
# NEW HEADERS SUPPORTED (author_display_name,comment_id)
# Outputs go to:  ~/project2/edges
# Set threshold via:  N=25 bash build_edges.sh

set -euo pipefail

# Threshold
N="${N:-10}"

# Read-only datasets
PROC="/mnt/scratch/CS131_jelenag/projects/team10_sec3/team10-youtube-socialmedia/data/processed"
V="$PROC/videos_and_comment_ids.csv"
CWR="$PROC/comments_with_replies.csv"
AUTH="$PROC/author_and_comment_ids.csv"
GREAT="$PROC/great_in_comments.csv"

# Writable output
OUT="/mnt/scratch/CS131_jelenag/projects/team10_sec3/team10-youtube-socialmedia/out/project3/edges"
mkdir -p "$OUT"

echo "Threshold N = $N"
echo "Writing to  $OUT"
echo

##############################################################################
# 1) videos_and_comment_ids.csv  (left = video_id)
##############################################################################
# counts (video_id -> count)
cut -d, -f1 "$V" | tail -n +2 | tr -d '\r' \
| sed 's/^[[:space:]]*//;s/[[:space:]]*$//' \
| sort | uniq -c | sort -nr \
| awk '{print $2 "\t" $1}' > "$OUT/videos_and_comment_ids_entity_counts.tsv"

# kept list
awk -F'\t' -v n="$N" '$2>=n{print $1}' "$OUT/videos_and_comment_ids_entity_counts.tsv" \
| sort -u > "$OUT/kept_videos.txt"

# thresholded edges (keep header + rows with kept left entity)
sed 's/$/,/' "$OUT/kept_videos.txt" > "$OUT/kept_videos_pat.txt"
{ head -n 1 "$V"
  grep -F -f "$OUT/kept_videos_pat.txt" "$V"
} > "$OUT/videos_and_comment_ids_edges_thresholded.tsv"

# Top-30 by left entity in the thresholded edges
cut -d, -f1 "$OUT/videos_and_comment_ids_edges_thresholded.tsv" \
| tail -n +2 | sort | uniq -c | sort -nr | head -30 \
> "$OUT/videos_and_comment_ids_top30.txt"

##############################################################################
# 2) comments_with_replies.csv  (left = parent_comment_id)
##############################################################################
# counts
cut -d, -f1 "$CWR" | tail -n +2 | tr -d '\r' \
| sort | uniq -c | sort -nr \
| awk '{print $2 "\t" $1}' > "$OUT/comments_with_replies_entity_counts.tsv"

# kept list
awk -F'\t' -v n="$N" '$2>=n{print $1}' "$OUT/comments_with_replies_entity_counts.tsv" \
| sort -u > "$OUT/kept_cwr.txt"

# thresholded edges
sed 's/$/,/' "$OUT/kept_cwr.txt" > "$OUT/kept_cwr_pat.txt"
{ head -n 1 "$CWR"
  grep -F -f "$OUT/kept_cwr_pat.txt" "$CWR"
} > "$OUT/comments_with_replies_edges_thresholded.tsv"

# Top-30
cut -d, -f1 "$OUT/comments_with_replies_edges_thresholded.tsv" \
| tail -n +2 | sort | uniq -c | sort -nr | head -30 \
> "$OUT/comments_with_replies_top30.txt"

##############################################################################
# 3) author_and_comment_ids.csv  (left = author_display_name)  << CHANGED
##############################################################################
# counts (author_display_name -> count)
cut -d, -f1 "$AUTH" | tail -n +2 | tr -d '\r' \
| sed 's/^[[:space:]]*//;s/[[:space:]]*$//' \
| grep -v '^$' \
| sort | uniq -c | sort -nr \
| awk '{print $2 "\t" $1}'> "$OUT/author_and_comment_ids_entity_counts.tsv"

# (two awk steps: first strip the leading count; second move the trailing count into its own field)

# kept list
awk -F'\t' -v n="$N" '$NF>=n{print $1}' "$OUT/author_and_comment_ids_entity_counts.tsv" \
| sort -u > "$OUT/kept_authors.txt"

# thresholded edges (header + rows where author_display_name is kept)
# (safe because sample names do not contain commas)
sed 's/$/,/' "$OUT/kept_authors.txt" > "$OUT/kept_authors_pat.txt"
{ head -n 1 "$AUTH"
  grep -F -f "$OUT/kept_authors_pat.txt" "$AUTH"
} > "$OUT/author_and_comment_ids_edges_thresholded.tsv"

# Top-30
cut -d, -f1 "$OUT/author_and_comment_ids_edges_thresholded.tsv" \
| tail -n +2 | sort | uniq -c | sort -nr | head -30 \
> "$OUT/author_and_comment_ids_top30.txt"

##############################################################################
# 4) great_in_comments.csv  (left = word)
##############################################################################
# Entity count = total rows (minus header)
cut -d, -f1 "$GREAT" | tail -n +2 | tr -d '\r' \
| sort | uniq -c | sort -nr \
| awk '{print $2 "\t" $1}' > "$OUT/great_in_comments_entity_counts.tsv"

# Thresholded edges = identical to input (keeps header + all rows)
cp "$GREAT" "$OUT/great_in_comments_edges_thresholded.tsv"

# Top-30 = just the single token with its count
cut -d, -f1 "$OUT/great_in_comments_edges_thresholded.tsv" \
| tail -n +2 | sort | uniq -c | sort -nr | head -30 \
> "$OUT/great_in_comments_top30.txt"

##############################################################################
echo "Done. Files in $OUT:"
ls -1 "$OUT" | sed 's/^/  /'

