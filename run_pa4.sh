#!/usr/bin/env bash
set -euo pipefail

# bash run_pa4.sh <INPUT_COMMENTS_CSV> [VIDEO_ID]
INPUT="${1:?Usage: bash run_pa4.sh <INPUT_COMMENTS_CSV> [VIDEO_ID] }"
VIDEO_ID="${2:-n_Lv_mw6m6c}"   # default video for 4b
OUT="out"
LOGS="logs"
mkdir -p "$OUT" "$LOGS"

log(){ echo "[$(date +'%F %T')]" "$@" | tee -a "$LOGS/run.log"; }

#############################################
# Step 1 — Clean & normalize
#############################################
log "Step 1: Clean & normalize"
head -n 10 "$INPUT" > "$OUT/sample_before.tsv"
sed -E 's/^[[:space:]]+//; s/[[:space:]]+$//; s/[“”]/"/g; s/[‘’]/'\''/g' "$INPUT" \
| tr ',' '\t' > "$OUT/clean.tsv"
head -n 10 "$OUT/clean.tsv" > "$OUT/sample_after.tsv"
log "Clean -> out/clean.tsv"

#############################################
# Step 2 — Freq/TopN/Skinny
#############################################
log "Step 2: Frequency tables, TopN, Skinny"
awk -F'\t' 'NR>1 {c[$3]++} END{print "author_display_name\tcount"; for(k in c) print k"\t"c[k]}' "$OUT/clean.tsv" \
| LC_ALL=C sort -s -t$'\t' -k2,2nr > "$OUT/freq_author.tsv"

awk -F'\t' 'NR>1 {c[$7]++} END{print "is_reply\tcount"; for(k in c) print k"\t"c[k]}' "$OUT/clean.tsv" \
| LC_ALL=C sort -s -t$'\t' -k2,2nr > "$OUT/freq_isreply.tsv"

{ head -n 1 "$OUT/clean.tsv"; tail -n +2 "$OUT/clean.tsv" | LC_ALL=C sort -s -t$'\t' -k5,5nr | head -n 10; } \
> "$OUT/topN.tsv"

awk -F'\t' -v OFS='\t' '
  NR==1 { print "comment_id","author_display_name","like_count","published_at"; next }
  { print $2,$3,$5,$4 }
' "$OUT/clean.tsv" > "$OUT/skinny.tsv"

#############################################
# Step 3 — Quality filters
#############################################
log "Step 3: Quality filters -> out/filtered.tsv"
awk -F'\t' -v OFS='\t' '
  NR==1 { print; next }
  $1!="" && $2!="" && $3!="" && $4 ~ /^[0-9]{4}-[0-9]{2}-[0-9]{2}T/ && $5 ~ /^[0-9]+$/ { print }
' "$OUT/clean.tsv" > "$OUT/filtered.tsv"

#############################################
# Step 4a — Ratios & like-count buckets
#############################################
log "Step 4a: Ratios & like-count buckets"
awk -F'\t' -v OFS='\t' '
  NR==1 { print "comment_id","like_count","like_bucket"; next }
  { lc = ($5 ~ /^[0-9]+$/ ? $5+0 : 0); b = (lc>=50 ? "HI" : (lc>=10 ? "MID" : "LO")); print $2, lc, b }
' "$OUT/filtered.tsv" > "$OUT/ratios.tsv"

awk -F'\t' 'NR==1{next}{ c[$3]++ } END{ print "like_bucket\tcount"; for(k in c) print k"\t"c[k] }' "$OUT/ratios.tsv" \
| LC_ALL=C sort -s -t$'\t' -k2,2nr > "$OUT/buckets.tsv"

#############################################
# Step 4b — Sentiment keyword families + entity summary
#############################################
log "Step 4b: Sentiment families + entity summary (VIDEO_ID=$VIDEO_ID)"

if [[ -f "scripts/sprint4/sentiment_kw_gen.sh" ]]; then
  bash scripts/sprint4/sentiment_kw_gen.sh || log "WARN: sentiment_kw_gen.sh skipped (path dependent)"
else
  log "WARN: scripts/sprint4/sentiment_kw_gen.sh not found"
fi

if [[ -f "scripts/sprint4/keyword_families.sh" ]]; then
  printf '%s\n' "$VIDEO_ID" | bash scripts/sprint4/keyword_families.sh || log "WARN: keyword_families.sh skipped (path dependent)"
else
  log "WARN: scripts/sprint4/keyword_families.sh not found"
fi

if [[ -f "scripts/sprint4/sentiment_analysis.sh" ]]; then
  printf '%s\n' "$VIDEO_ID" | bash scripts/sprint4/sentiment_analysis.sh || log "WARN: sentiment_analysis.sh skipped (path dependent)"
else
  log "WARN: scripts/sprint4/sentiment_analysis.sh not found"
fi

if [[ -f "scripts/sprint4/entity_summary.sh" ]]; then
  VIDEO_ID="$VIDEO_ID" bash scripts/sprint4/entity_summary.sh || log "WARN: entity_summary.sh skipped (path dependent)"
else
  log "WARN: scripts/sprint4/entity_summary.sh not found"
fi

# copy any produced 4b artifacts into ./out for grading
for f in \
  "data/processed/${VIDEO_ID}_sentiment_keyword_family.csv" \
  "data/processed/${VIDEO_ID}_sentiment_bucket_analysis.csv" \
  "data/processed/entity_numeric_analysis.csv"
do
  [[ -f "$f" ]] && cp -f "$f" "$OUT/" && log "copied $(basename "$f") -> out/"
done

#############################################
# Step 5 — Temporal structure (YYYY-MM)
#############################################
log "Step 5: Temporal structure -> out/temporal.tsv"
awk -F'\t' -v OFS='\t' '
  NR==1{next}
  {
    if ($4 ~ /^[0-9]{4}-[0-9]{2}-[0-9]{2}T/) {
      m = substr($4,1,7); tot[m]++
      vid=$1; if (!(m SUBSEP vid in seen)) { seen[m SUBSEP vid]=1; vids[m]++ }
    }
  }
  END {
    print "month","month_total","avg_per_video"
    PROCINFO["sorted_in"]="@ind_str_asc"
    for (m in tot) {
      t=tot[m]; v=(m in vids ? vids[m] : 0); avg=(v>0?t/v:0)
      printf "%s\t%d\t%.2f\n", m, t, avg
    }
  }
' "$OUT/filtered.tsv" > "$OUT/temporal.tsv"

#############################################
# Step 6 — Signal discovery (top tokens)
#############################################
log "Step 6: Signal discovery -> out/signals.tsv"
cat > "$OUT/.stop.txt" <<'STOP'
the a an and or of to in is it this that for with on at by from as be are was were has have had not no you your i we they he she them him her our us their my me
STOP

awk -F'\t' -v OFS='\t' '
  BEGIN {
    while ((getline w < "'"$OUT"'/.stop.txt") > 0) {
      n=split(w, a, /[[:space:]]+/); for(i=1;i<=n;i++) stop[a[i]]=1
    }
  }
  NR==1{next}
  {
    txt=tolower($6)
    gsub(/[^[:alnum:][:space:]]+/, " ", txt)
    gsub(/[[:space:]]+/, " ", txt)
    sub(/^ +/,"",txt); sub(/ +$/,"",txt)
    n=split(txt, a, /[[:space:]]+/)
    for(i=1;i<=n;i++){ k=a[i]; if(k!="" && !(k in stop)) c[k]++ }
  }
  END {
    print "token","count"
    for(k in c) print k, c[k]
  }
' "$OUT/filtered.tsv" \
| LC_ALL=C sort -s -t$'\t' -k2,2nr | head -n 101 > "$OUT/signals.tsv"

log "DONE. Outputs in ./out, log at ./logs/run.log"
