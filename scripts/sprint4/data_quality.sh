#! bin bash

: << 'DATA_QUALITY'
This Script ensures we maintain a high quality of data in our script
current data collected includes the following
comment header $4: 
video_id,comment_id,author_display_name,published_at,like_count,comment_text,Is_reply,parent_id,channel_id

video header $7:
kind,channel_id,default_language,video_id,title,description,publish_date,view_count,like_count,comment_count,live_broadcast_content,tags,duration,definition,caption
DATA_QUALITY

set -euo pipefail

HOME_DIR="$(cd ../.. && pwd)"
OUTPUT_DIR="${HOME_DIR}/out" 
DATASET_DIR="/mnt/scratch/CS131_jelenag/projects/team10_sec3/team10-youtube-socialmedia/data"
COMMENT_CSV="${DATASET_DIR}/yt_comments.csv"
VIDEO_CSV="${DATASET_DIR}/yt_video_data.csv"

# Verify directories are correct
#echo "Home path: ${HOME_DIR}"
#echo "Output directory: ${OUTPUT_DIR}"
#echo "Dataset directory: ${DATASET_DIR}"
#echo "Comment CSV Path: ${COMMENT_CSV}"
#echo "Video CSV Path: ${VIDEO_CSV}"

cd "${OUTPUT_DIR}"

echo "comment date"
#0
#2025-09-27T11:35:03Z
#UCfSgZSFXfp-eQqqZT9s
#2025-09-27T11:33:09Z
# awk -F',' -v OFS="," 'NR>1{ m=substr($4,1,7)}’ file
#awk -F',' -v OFS="," 'NR==1 || m=substr($4,1,20) {}' "${COMMENT_CSV}"
awk -F',' '{
	split($4, a, "T")
	t=substr(a[2],1,8)
	if (a[1] ~ /^[0-9]{4}-[0-9]{2}-[0-9]{2}$/ && t ~ /^[0-9]{2}:[0-9]{2}:[0-9]{2}$/){
		print "date " a[1], "and time", t 
	}
}' "${COMMENT_CSV}" | head -n 10

echo "video date"
awk -F',' '{
        split($7, a, "T")
        t=substr(a[2],1,8)
        if (a[1] ~ /^[0-9]{4}-[0-9]{2}-[0-9]{2}$/ && t ~ /^[0-9]{2}:[0-9]{2}:[0-9]{2}$/){
                print "date " a[1], "and time", t
        }
}' "${VIDEO_CSV}" | head -n 10
#awk -F',' '{ split($7, a, "T"); t=substr(a[2],1,8);print "date " a[1], "and time", t }' "${VIDEO_CSV}" | head -n 10
#cut -f7 "${VIDEO_CSV}" | head -n 10


