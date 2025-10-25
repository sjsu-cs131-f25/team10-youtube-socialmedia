PROJECT_ROOT="/mnt/scratch/CS131_jelenag/projects/team10_sec3/team10-youtube-socialmedia"
DATASET="/mnt/scratch/CS131_jelenag/projects/team10_sec3/team10-youtube-socialmedia/data"
OUTPUT="/mnt/scratch/CS131_jelenag/projects/team10_sec3/team10-youtube-socialmedia/data/processed"
LOG_DIR="${PROJECT_ROOT}/out"
LOG_FILE="${LOG_DIR}/edge_log.txt"
INPUT_CSV="${DATASET}/yt_comments.csv"

mkdir -p "${OUTPUT}" "${LOG_DIR}"
chmod 775 "${OUTPUT}"
chmod 775 "${LOG_DIR}"

exec > >(tee -a "${LOG_FILE}") 2>&1
echo "[$(date '+%F %T')] Start"

N="${N:-10}"
# Proper CSV parsing: a field is either unquoted w/o commas OR a quoted string (commas allowed).
# We’ll re-use the same parser per file by writing each AWK once.

awk '
BEGIN { OFS=","; FPAT = "([^,]+)|(\"([^\"]|\"\")*\")" }
NR==1 { print "video_id,comment_id"; next }
{
	v=$1; c=$2
	gsub(/^"|"$/, "", v); gsub(/^"|"$/, "", c)
	if (v !~ /[[:space:]]/ && length(v)==11 &&
		c !~ /[[:space:]]/ && (length(c)==26 || length(c)==49)) {
	print v, c
}
}' "${INPUT_CSV}" > "${OUTPUT}/videos_and_comment_ids.csv"

awk '
BEGIN { OFS=","; FPAT = "([^,]+)|(\"([^\"]|\"\")*\")" }
NR==1 { print "parent_comment_id,reply_id"; next }
{
r=$7; p=$8; id=$2
gsub(/^"|"$/, "", r); gsub(/^"|"$/, "", p); gsub(/^"|"$/, "", id)
if (r=="1") { print p, id }
		    }
' "${INPUT_CSV}" > "${OUTPUT}/comments_with_replies.csv"

awk '
BEGIN { OFS=","; FPAT = "([^,]+)|(\"([^\"]|\"\")*\")" }
 NR==1 { print "author_display_name,comment_id"; next }
{
a=$3; c=$2
gsub(/^"|"$/, "", a);
gsub(/^"|"$/, "", c)
if (length(a)>0 && length(c)>0 && a ~ /^@/) 
	print a, c
}' "${INPUT_CSV}" > "${OUTPUT}/author_and_comment_ids.csv"

 awk '
 BEGIN { OFS=","; FPAT = "([^,]+)|(\"([^\"]|\"\")*\")" }
 NR==1 { print "word,comment_id"; next }
{
 id=$2; txt=$6
 gsub(/^"|"$/, "", id); gsub(/"/, "", txt)
 txt=tolower(txt)
 if (txt ~ /(^|[^[:alnum:]_])great([^[:alnum:]_]|$)/) print "great", id
 }
 ' "${INPUT_CSV}" > "${OUTPUT}/great_in_comments.csv"

EDGES="${OUTPUT}/edges"
mkdir -p "${EDGES}"

# 1) videos_and_comment_ids.csv  (left = video_id)
cut -d, -f1 "${OUTPUT}/videos_and_comment_ids.csv" | tail -n +2 | tr -d "\r" \
| sed "s/^[[:space:]]*//;s/[[:space:]]*$//" \
| sort | uniq -c | sort -nr \
| awk "{print \$2 \"\t\" \$1}" > "${EDGES}/videos_and_comment_ids_entity_counts.tsv"

awk -F$'\t' -v n="${N}" '$2>=n{print $1}' "${EDGES}/videos_and_comment_ids_entity_counts.tsv" \
| sort -u > "${EDGES}/kept_videos.txt"

sed 's/$/,/' "${EDGES}/kept_videos.txt" > "${EDGES}/kept_videos_pat.txt"
{ head -n 1 "${OUTPUT}/videos_and_comment_ids.csv"
  tail -n +2 "${OUTPUT}/videos_and_comment_ids.csv" | grep -F -f "${EDGES}/kept_videos_pat.txt"
} > "${EDGES}/videos_and_comment_ids_edges_thresholded.tsv"

cut -d, -f1 "${EDGES}/videos_and_comment_ids_edges_thresholded.tsv" \
| tail -n +2 | sort | uniq -c | sort -nr | head -30 \
> "${EDGES}/videos_and_comment_ids_top30.txt"

# 2) comments_with_replies.csv  (left = parent_comment_id)
cut -d, -f1 "${OUTPUT}/comments_with_replies.csv" | tail -n +2 | tr -d "\r" \
| sort | uniq -c | sort -nr \
| awk "{print \$2 \"\t\" \$1}" > "${EDGES}/comments_with_replies_entity_counts.tsv"

awk -F$'\t' -v n="${N}" '$2>=n{print $1}' "${EDGES}/comments_with_replies_entity_counts.tsv" \
| sort -u > "${EDGES}/kept_cwr.txt"

sed 's/$/,/' "${EDGES}/kept_cwr.txt" > "${EDGES}/kept_cwr_pat.txt"
{ head -n 1 "${OUTPUT}/comments_with_replies.csv"
  tail -n +2 "${OUTPUT}/comments_with_replies.csv" | grep -F -f "${EDGES}/kept_cwr_pat.txt"
} > "${EDGES}/comments_with_replies_edges_thresholded.tsv"

cut -d, -f1 "${EDGES}/comments_with_replies_edges_thresholded.tsv" \
| tail -n +2 | sort | uniq -c | sort -nr | head -30 \
> "${EDGES}/comments_with_replies_top30.txt"

# 3) author_and_comment_ids.csv  (left = author_display_name)
cut -d, -f1 "${OUTPUT}/author_and_comment_ids.csv" | tail -n +2 | tr -d "\r" \
| sed "s/^[[:space:]]*//;s/[[:space:]]*$//" \
| grep -v '^$' \
| sort | uniq -c | sort -nr \
| awk "{print \$2 \"\t\" \$1}" > "${EDGES}/author_and_comment_ids_entity_counts.tsv"

awk -F$'\t' -v n="${N}" '$2>=n{print $1}' "${EDGES}/author_and_comment_ids_entity_counts.tsv" \
| sort -u > "${EDGES}/kept_authors.txt"

# assuming display names (starting with @) do not contain commas
sed 's/$/,/' "${EDGES}/kept_authors.txt" > "${EDGES}/kept_authors_pat.txt"
{ head -n 1 "${OUTPUT}/author_and_comment_ids.csv"
  tail -n +2 "${OUTPUT}/author_and_comment_ids.csv" | grep -F -f "${EDGES}/kept_authors_pat.txt"
} > "${EDGES}/author_and_comment_ids_edges_thresholded.tsv"

cut -d, -f1 "${EDGES}/author_and_comment_ids_edges_thresholded.tsv" \
| tail -n +2 | sort | uniq -c | sort -nr | head -30 \
> "${EDGES}/author_and_comment_ids_top30.txt"

# 4) great_in_comments.csv  (left = word; usually always "great")
# Keep the same simple pattern for consistency
cut -d, -f1 "${OUTPUT}/great_in_comments.csv" | tail -n +2 | tr -d "\r" \
| sort | uniq -c | sort -nr \
| awk "{print \$2 \"\t\" \$1}" > "${EDGES}/great_in_comments_entity_counts.tsv"

awk -F$'\t' -v n="${N}" '$2>=n{print $1}' "${EDGES}/great_in_comments_entity_counts.tsv" \
| sort -u > "${EDGES}/kept_great.txt"

sed 's/$/,/' "${EDGES}/kept_great.txt" > "${EDGES}/kept_great_pat.txt"
{ head -n 1 "${OUTPUT}/great_in_comments.csv"
  tail -n +2 "${OUTPUT}/great_in_comments.csv" | grep -F -f "${EDGES}/kept_great_pat.txt"
} > "${EDGES}/great_in_comments_edges_thresholded.tsv"

cut -d, -f1 "${EDGES}/great_in_comments_edges_thresholded.tsv" \
| tail -n +2 | sort | uniq -c | sort -nr | head -30 \
> "${EDGES}/great_in_comments_top30.txt"

# Create Top-30 videos from the yt_comments.csv (top30_overal.txt)
cut -d, -f1 "${INPUT_CSV}" \
  | tail -n +2 \
  | grep -v '^$' \
  | sort \
  | uniq -c \
  | sort -nr \
  | head -30 > "${EDGES}/top_30_videos.txt"

# Compare against videos_and_comment_ids_top30.txt and write diff
comm -3 <(sort "${EDGES}/videos_and_comment_ids_top30.txt") <(sort "${EDGES}/top_30_videos.txt") \
  | sed -e 's/^\t/> /' -e 's/^[^\t].*/< &/' > "${EDGES}/diff_top30.txt"
  
# If diff file is empty, write "No differences"
[ -s "${EDGES}/diff_top30.txt" ] || echo "No differences" > "${EDGES}/diff_top30.txt"
# ---------------------------------------------------------------------------

# Step 3 of Project 3 — compute cluster sizes and a size→frequency table
THRESHOLDED_AUTH_EDGES="${EDGES}/author_and_comment_ids_edges_thresholded.tsv"

cut -d',' -f1 "${THRESHOLDED_AUTH_EDGES}" \
| tail -n +2 \
| sort \
| uniq -c \
| sort -n \
| sed -E 's/^[[:space:]]*([0-9]+)[[:space:]]+(.+)$/\2\t\1/' \
> "${EDGES}/cluster_sizes.tsv"

cut -f2 "${EDGES}/cluster_sizes.tsv" \
| sort -n \
| uniq -c \
| sed -E 's/^[[:space:]]*([0-9]+)[[:space:]]+(.+)$/\2\t\1/' \
> "${EDGES}/cluster_sizes_histogram.tsv"

echo "[$(date '+%F %T')] Done. Outputs in: ${EDGES}"
