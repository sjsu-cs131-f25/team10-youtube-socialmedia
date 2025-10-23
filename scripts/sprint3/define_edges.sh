#!/bin/env bash

# This script processes the yt_comments.csv file to extract strctured data for analysis by creating multiple edge tables
# each directory needed for this script is defined as a variable 
# the execution is logged for tracking outputs
# the necessary file permissions are given to the user executing the script with chmod commands
# multiple awk commands are used to parse the CSV and create four different files:
# videos_and_comment_ids, comments_with_replies_ author_and_comment_replies, and great_in_comments


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

 echo "[$(date '+%F %T')] Done"

