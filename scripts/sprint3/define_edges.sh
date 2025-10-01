# !/usr/bin/env bash
# Finding edges in data - jacob atanacio
# setup

PROJECT_ROOT="/mnt/scratch/CS131_jelenag/projects/team10_sec3/team10-youtube-socialmedia"
DATASET="/mnt/scratch/CS131_jelenag/projects/team10_sec3/team10-youtube-socialmedia/data"
OUTPUT="/mnt/scratch/CS131_jelenag/projects/team10_sec3/team10-youtube-socialmedia/data/processed"
LOG_DIR="${PROJECT_ROOT}/out"
LOG_FILE="${LOG_DIR}/edge_log.txt"
INPUT_CSV="${DATASET}/yt_comments.csv"


mkdir -p "${OUTPUT}" "${LOG_DIR}"
# implementation

# log will stream output to the logfile and append a timestamp to track exactly when the script is called each time
log() {
	  printf '%s - %s\n' "$(date '+%Y-%m-%d %H:%M:%S')" "$1" | tee -a "${LOG_FILE}" >/dev/null
  }

log "Starting edge extraction"

if [[ ! -f "${INPUT_CSV}" ]]; then
	log "ERROR: Input file not found: ${INPUT_CSV}"
	exit 1
fi

cd "${DATASET}"

echo "Finding relationships in dataset (edges)"

# 1) Video_id | Comment_id  (one video -> many comments)
echo "Video_id | Comment_id"
awk -F, 'NR==1 {print "video_id,comment_id"; next} {print $2 "," $1}' \
	"yt_comments.csv" > "${OUTPUT}/videos_and_comment_ids.csv"

# 2) Parent comment id -> reply id
echo "parent_comment_id | reply_id"
awk -F, 'NR==1 {print "parent_comment_id,reply_id"; next} $7 == 1 { print $2 "," $4 }' \
	"yt_comments.csv" > "${OUTPUT}/comments_with_replies.csv"

# 3) author channel id -> comment id
echo "author_id | comment_id"
awk -F, 'NR==1 {print "author_id,comment_id"; next} {print $9 "," $1}' \
	"yt_comments.csv" > "${OUTPUT}/author_and_comment_ids.csv"

# 4) "great" -> comment id (whole-word, case-insensitive)
echo "all comment id's that have the word 'great'"
awk -F, '
NR==1 { print "word,comment_id"; next }
{
	id=$2
	txt=$6
	gsub(/"/, "", txt)
	txt=tolower(txt)
	if (txt ~ /(^|[^[:alnum:]_])great([^[:alnum:]_]|$)/) {print "great," id}
}' "yt_comments.csv" > "${OUTPUT}/great_in_comments.csv"

log "Successfully finished defining edges!"
