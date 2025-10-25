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
DATASET_DIR="/mnt/scratch/CS131_jelenag/projects/team10_sec3/team10-youtube-socialmedia/data"
OUTPUT_DIR="${DATASET_DIR}/processed"
COMMENT_CSV="${DATASET_DIR}/yt_comments.csv"
VIDEO_CSV="${DATASET_DIR}/yt_video_data.csv"

# Verify directories are correct
#echo "Home path: ${HOME_DIR}"
echo "Output directory: ${OUTPUT_DIR}"
#echo "Dataset directory: ${DATASET_DIR}"
#echo "Comment CSV Path: ${COMMENT_CSV}"
#echo "Video CSV Path: ${VIDEO_CSV}"

cd "${OUTPUT_DIR}"
#set -x # for debugging purposes

echo "separating comment date and time"
awk -F',' 'BEGIN {OFS=","}
NR==1{
        print "comment_id", "author_display_name", "published_at", "like_count", "comment_text", "is_reply", "parent_id", "channel_id", "date", "time"
        next
}
{
	split($4, a, "T")
	d=a[1]
	t=substr(a[2],1,8)
	if (d ~ /^[0-9]{4}-[0-9]{2}-[0-9]{2}$/ && t ~ /^[0-9]{2}:[0-9]{2}:[0-9]{2}$/){
		print $0, d, t 
	}
}' "${COMMENT_CSV}" > "yt_comments_datetime.csv" || true
sed -i 's/\r//g' "yt_comments_datetime.csv"

echo "seperating video date and time"
awk -F',' 'BEGIN {OFS=","}
NR==1{
        print "kind", "channel_id", "default_language", "video_id", "title", "description", "publish_date", "view_count", "like_count", "comment_count", "live_broadcast_content", "tags", "duration", "definition", "caption", "date", "time"
        next
}
{
        split($7, a, "T")
        d=a[1]
        t=substr(a[2],1,8)
        if (d ~ /^[0-9]{4}-[0-9]{2}-[0-9]{2}$/ && t ~ /^[0-9]{2}:[0-9]{2}:[0-9]{2}$/){
                print $0, d, t
        }
}' "${VIDEO_CSV}" > "yt_video_datetime.csv" || true
sed -i 's/\r//g' "yt_video_datetime.csv"

echo "operation completed"
