#!/bin/env bash


PROJECT_ROOT="/mnt/scratch/CS131_jelenag/projects/team10_sec3/team10-youtube-socialmedia"
DATASET="/mnt/scratch/CS131_jelenag/projects/team10_sec3/team10-youtube-socialmedia/data"
OUTPUT="/mnt/scratch/CS131_jelenag/projects/team10_sec3/team10-youtube-socialmedia/data/processed"
LOG_DIR="${PROJECT_ROOT}/out"
LOG_FILE="${LOG_DIR}/signal_data_log.txt"
INPUT_CSV="${DATASET}/yt_comments.csv"

mkdir -p "${OUTPUT}" "${LOG_DIR}"
chmod 775 "${OUTPUT}"
chmod 775 "${LOG_DIR}"

awk -F',' -v OFS=',' '
NR==1 {
  header=$0
  print "cleaned_comment" > "$OUTPUT/cleaned_comments_only.csv"                                                      
  print header > "$OUTPUT/cleaned_full_dataset.csv"                                                                  
  next
}
{
  line=tolower($6)
  gsub(/[[:punct:]]+/, "", line)
  gsub(/[[:space:]]+/, " ", line)
  sub(/^ +/, "", line)
  sub(/ +$/, "", line)
  print line > "$OUTPUT/cleaned_comments_only.csv"                                                                   
  $6=line
  print > "$OUTPUT/cleaned_full_dataset.csv"                                                                         
}
' yt_comments.csv
