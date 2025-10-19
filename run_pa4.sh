set -euo pipefail
INPUT="$1"
OUT="out"
mkdir -p "$OUT"

sed -E 's/^[[:space:]]+//; s/[[:space:]]+$//; s/[“”]/"/g; s/[‘’]/'\''/g' "$INPUT" > "$OUT/clean.csv"
awk -F, 'NR>1 {count[$3]++} END{print "author_display_name,count"; for(k in count) print k","count[k]}' "$OUT/clean.csv" \
| sort -t, -k2,2nr > "$OUT/freq_author.csv"
awk -F, 'NR>1 {count[$7]++} END{print "is_reply,count"; for(k in count) print k","count[k]}' "$OUT/clean.csv" \
| sort -t, -k2,2nr > "$OUT/freq_isreply.csv"

(head -n 1 "$OUT/clean.csv"; tail -n +2 "$OUT/clean.csv" | sort -t, -k5,5nr | head -n 10) > "$OUT/topN.csv"
awk -F, -v OFS=',' '{print $1,$3,$5,$4}' "$OUT/clean.csv" > "$OUT/skinny.csv"
echo "Done! Check the out/ folder:"
ls -1 "$OUT"

