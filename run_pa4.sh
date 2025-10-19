set -euo pipefail

INPUT="$1"
OUT="out"
mkdir -p "$OUT"

echo "[INFO] Cleaning file: $INPUT"

head -n 10 "$INPUT" > "$OUT/sample_before.tsv"

sed -E 's/^[[:space:]]+//; s/[[:space:]]+$//; s/[“”]/"/g; s/[‘’]/'\''/g' "$INPUT" \
| tr ',' '\t' > "$OUT/clean.tsv"

head -n 10 "$OUT/clean.tsv" > "$OUT/sample_after.tsv"

echo "[INFO] Cleaning complete -> out/clean.tsv"
echo "[INFO] Generating frequency tables and summaries..."

awk -F'\t' 'NR>1 {count[$3]++} END{
print "author_display_name\tcount"
for(k in count) print k"\t"count[k]
}' "$OUT/clean.tsv" | sort -t$'\t' -k2,2nr > "$OUT/freq_author.tsv"

awk -F'\t' 'NR>1 {count[$7]++} END{
print "is_reply\tcount"
for(k in count) print k"\t"count[k]
}' "$OUT/clean.tsv" | sort -t$'\t' -k2,2nr > "$OUT/freq_isreply.tsv"

(head -n 1 "$OUT/clean.tsv";
tail -n +2 "$OUT/clean.tsv" | sort -t$'\t' -k5,5nr | head -n 10) > "$OUT/topN.tsv"

awk -F'\t' -v OFS='\t' '{print $1,$3,$5,$4}' "$OUT/clean.tsv" > "$OUT/skinny.tsv"

awk -F'\t' -v OFS='\t' '{print $1,$3,$5,$4}' "$OUT/clean.tsv" > "$OUT/skinny.tsv"
echo "[DONE] All required TSVs generated:"
ls -1 "$OUT" | sed 's/^/out\//'

