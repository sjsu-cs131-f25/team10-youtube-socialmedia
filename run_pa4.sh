#!/usr/bin/env bash
set -euo pipefail

# usage: bash run_pa4.sh <INPUT_COMMENTS_CSV>
INPUT="${1:?Usage: bash run_pa4.sh <INPUT_COMMENTS_CSV>}"

OUT="out"; LOGS="logs"
mkdir -p "$OUT" "$LOGS"

log(){ echo "[$(date +'%F %T')]" "$@" | tee -a "$LOGS/run.log"; }

#############################################
# Step 1 — Clean & normalize (SED)
#############################################
log "Step 1: Clean & normalize"
head -n 10 "$INPUT" > "$OUT/sample_before.tsv"


sed -E 's/^[[:space:]]+//; s/[[:space:]]+$//; s/[“”]/"/g; s/[‘’]/'\''/g' "$INPUT" \
| tr ',' '\t' > "$OUT/clean.tsv"

head -n 10 "$OUT/clean.tsv" > "$OUT/sample_after.tsv"

#############################################
# Step 2 — Two freq tables + TopN + Skinny
#############################################
log "Step 2: Frequency tables, TopN, Skinny"
# Header indices from your file:
# 1 video_id | 2 comment_id | 3 author_display_name | 4 published_at
# 5 like_count | 6 comment_text | 7 is_reply | 8 parent_id | 9 channel_id

# author_display_name frequency
awk -F'\t' 'NR==1{next}{c[$3]++} END{print "author_display_name\tcount"; for(k in c) print k"\t"c[k]}' "$OUT/clean.tsv" \
| LC_ALL=C sort -s -t$'\t' -k2,2nr > "$OUT/freq_author.tsv"

# is_reply frequency
awk -F'\t' 'NR==1{next}{c[$7]++} END{print "is_reply\tcount"; for(k in c) print k"\t"c[k]}' "$OUT/clean.tsv" \
| LC_ALL=C sort -s -t$'\t' -k2,2nr > "$OUT/freq_isreply.tsv"

# Top-N by like_count (col 5), keep header, deterministic sort
{ head -n 1 "$OUT/clean.tsv"; tail -n +2 "$OUT/clean.tsv" | LC_ALL=C sort -s -t$'\t' -k5,5nr | head -n 10; } \
> "$OUT/topN.tsv"

# Skinny table (comment_id, author_display_name, like_count, published_at)
awk -F'\t' -v OFS='\t' '
  NR==1 { print "comment_id","author_display_name","like_count","published_at"; next }
  { print $2,$3,$5,$4 }
' "$OUT/clean.tsv" > "$OUT/skinny.tsv"

#############################################
# Step 3 — Quality filters (AWK)
# keep header; drop rows with missing key fields; coerce like_count numeric
#############################################
log "Step 3: Quality filters -> out/filtered.tsv"
awk -F'\t' -v OFS='\t' '
  NR==1 { print; next }
  $1!="" && $2!="" && $3!="" && $4 ~ /^[0-9]{4}-[0-9]{2}-[0-9]{2}T/ && $5 ~ /^[0-9]+$/ { print }
' "$OUT/clean.tsv" > "$OUT/filtered.tsv"

#############################################
# Step 4 — Ratios & Buckets
# Example: like_count per comment -> bucket HI/MID/LO (thresholds adjustable)
#############################################
log "Step 4: Ratios & Buckets"
# Ratios table (comment_id, like_count, like_bucket)
awk -F'\t' -v OFS='\t' '
  NR==1 { print "comment_id","like_count","like_bucket"; next }
  {
    lc = ($5 ~ /^[0-9]+$/ ? $5+0 : 0)
    b = (lc>=50 ? "HI" : (lc>=10 ? "MID" : "LO"))
    print $2, lc, b
  }
' "$OUT/filtered.tsv" > "$OUT/ratios.tsv"

# Bucket counts summary
awk -F'\t' '
  NR==1{next} { b[$3]++ } END{ print "like_bucket\tcount"; for(k in b) print k"\t"b[k] }
' "$OUT/ratios.tsv" \
| LC_ALL=C sort -s -t$'\t' -k2,2nr > "$OUT/buckets.tsv"

#############################################
# Step 5 — Temporal structure (YYYY-MM)
#############################################
log "Step 5: Temporal structure -> out/temporal.tsv"
awk -F'\t' -v OFS='\t' '
  NR==1{next}
  {
    # published_at looks like 2025-09-13T22:03:48Z
    if ($4 ~ /^[0-9]{4}-[0-9]{2}-[0-9]{2}T/) {
      ym = substr($4,1,7)
      tot[ym]++
      vid = $1
      if (!(ym SUBSEP vid in seen)) { seen[ym SUBSEP vid]=1; vids[ym]++ }
    }
  }
  END {
    print "month","month_total","avg_per_video"
    PROCINFO["sorted_in"]="@ind_str_asc"
    for (m in tot) {
      t=tot[m]; v=(m in vids ? vids[m] : 0)
      avg=(v>0?t/v:0)
      printf "%s\t%d\t%.2f\n", m, t, avg
    }
  }
' "$OUT/filtered.tsv" > "$OUT/temporal.tsv"

#############################################
# Step 6 — Signal discovery (Top keywords)
# Super-simple tokenizer over comment_text, stopword filter, Top-N
#############################################
log "Step 6: Signal discovery -> out/signals.tsv"
cat > "$OUT/.stop.txt" <<'STOP'
the a an and or of to in is it this that for with on at by from as be are was were has have had not no you your i we they he she them him her our us their my me
STOP

awk -F'\t' -v OFS='\t' '
  BEGIN {
    while ((getline w < "'$OUT'/.stop.txt") > 0) { for (i=1;i<=NF;i++) stop[w]=1 }
  }
  NR==1{next}
  {
    txt = tolower($6)
    gsub(/[^[:alnum:][:space:]]+/, " ", txt)
    gsub(/[[:space:]]+/, " ", txt)
    sub(/^ +/, "", txt); sub(/ +$/, "", txt)
    n=split(txt, a, /[[:space:]]+/)
    for (i=1;i<=n;i++) {
      k=a[i]
      if (k!="" && !(k in stop)) { c[k]++ }
    }
  }
  END {
    print "token","count"
    for (k in c) print k, c[k]
  }
' "$OUT/filtered.tsv" \
| LC_ALL=C sort -s -t$'\t' -k2,2nr | head -n 101 > "$OUT/signals.tsv"

log "All steps complete. Outputs in ./out, log at ./logs/run.log"
