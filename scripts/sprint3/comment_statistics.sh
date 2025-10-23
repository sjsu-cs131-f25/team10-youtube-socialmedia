#!/bin/env bash


# gets statistics of the comment counts of each video
# project directories are initiated 
# comment_count.csv counts each comment that shares the same video_id
# we use datamash to compute summary statistics for the sum, mean, and median to create comment_status.tsv

PROJECT_ROOT="/mnt/scratch/CS131_jelenag/projects/team10_sec3/team10-youtube-socialmedia"
DATASET="/mnt/scratch/CS131_jelenag/projects/team10_sec3/team10-youtube-socialmedia/data"
OUTPUT="/mnt/scratch/CS131_jelenag/projects/team10_sec3/team10-youtube-socialmedia/data/processed"
LOG_DIR="${PROJECT_ROOT}/out"
LOG_FILE="${LOG_DIR}/edge_log.txt"
INPUT_CSV="${DATASET}/yt_comments.csv"

mkdir -p "${OUTPUT}" "${LOG_DIR}"
chmod 775 "${OUTPUT}"
chmod 775 "${LOG_DIR}"

cd "${OUTPUT}"

# create seperate csv that creates numerical data for comment count per video_id
awk -F, 'NR>1 {print $1","$2}' videos_and_comment_ids.csv | sort -t, -k1,1 -k2,2 | uniq | awk -F, 'BEGIN{OFS=","} {count[$1]++} END{for (v in count) print v "," count[v]}' | sort -t, -k2,2nr | sed '1i video_id,#comments' > comment_count.csv

#use datamash to make tsv with stats
datamash -t, --header-in --output-delimiter=$'\t' sum 2 mean 2 median 2 < comment_count.csv > comment_status.tsv

