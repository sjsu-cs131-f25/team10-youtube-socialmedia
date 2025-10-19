#! bin bash

: << 'DATA_QUALITY'
This Script ensures we maintain a high quality of data in our script
current data collected includes the following
video_id,comment_id,author_display_name,published_at,like_count,comment_text,Is_reply,parent_id,channel_id
DATA_QUALITY

set -euo pipefail

HOME_DIR = $(cd ../.. && pwd)
OUTPUT_DIR = "${HOME_DIR}/out" 
DATASET_DIR = "/mnt/scratch/CS131_jelenag/projects/team10_sec3/team10-youtube-socialmedia/data"
INPUT_CSV = "${DATASET_DIR}/yt_comments.csv"


cd "${OUTPUT_DIR}"




