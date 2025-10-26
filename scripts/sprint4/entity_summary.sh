#!/bin/bash
: << 'ENTITY SUMMARY'
This script performs a simple numerical analysis on our data 
current data collected includes the following

comment numerical categories $5: (could get average + min + max comment like count)
video_id,comment_id,author_display_name,published_at,like_count,comment_text,Is_reply,parent_id,channel_id

video data numerical categories $8, $9, $10, $13: ( could get averages of these columns) (view_count, like_count, comment_count, duration in order)
kind,channel_id,default_language,video_id,title,description,publish_date,view_count,like_count,comment_count,live_broadcast_content,tags,duration,definition,caption

In this script I will calculate the average & minmax max views, likes, comments, and duration for all videos. (HOWEVER, STILL NEED TO USE COUNT)

ALTERNATIVE OPTION:
positive, negatative, neutral words and their count, average occurence by category
header: 
videoID, positive/negative/neutral, keyword, occurance count

In this script, I will calculate the total counts for a video's positive/negative/neutral words. I will also calculate the average number of occurances of each keyword by category

ENTITY SUMMARY

set -euo pipefail

#have user enter videoID, use n_Lv_mw6m6c as default
read -p "Please enter Youtube Video ID: " VIDEO_ID
VIDEO_ID="${VIDEO_ID:-n_Lv_mw6m6c}"

PROJECT_ROOT="$(cd ../.. && pwd)" 
DATASET_DIR="/mnt/scratch/CS131_jelenag/projects/team10_sec3/team10-youtube-socialmedia/data"
OUTPUT_DIR="${DATASET_DIR}/processed"
KEYWORD_CSV="${VIDEO_ID}_sentiment_keyword_family.csv"
OUTPUT_FILE="${VIDEO_ID}_entity_numeric_analysis.csv"

# Verify directories are correct
#echo "Home path: ${PROJECT_ROOT}"
#echo "Output directory: ${OUTPUT_DIR}"
#echo "Output file: ${OUTPUT_FILE}"
#echo "Dataset directory: ${DATASET_DIR}"
#echo "Video sentiment CSV Path: ${KEYWORD_CSV}"

[ -n "$VIDEO_ID" ] || { echo "ERROR: VIDEOID is empty"; exit 0; }

cd "$OUTPUT_DIR"

awk -F',' 'BEGIN { OFS="," }
NR == 1{
	print "video_id","total_count","positive_count","neutral_count","negative_count","positive_avg","neutral_avg","negative_avg"
	next
}
{
	videoid=$1
	key_fam=$2
	count=$4 + 0

	total += count
		if (key_fam == "positive"){
			pos += count
			positive_keys += 1
		} else if (key_fam == "negative"){
			neg += count
			negative_keys += 1
		} else {
			neutral += count
			neutral_keys += 1
		}
}
END {
	# calculate averages here
	pos_avg=pos/positive_keys
	neutral_avg=neutral/neutral_keys
	neg_avg=neg/negative_keys
	
	print videoid, total, pos, neutral, neg, pos_avg, neutral_avg, neg_avg
}' "${OUTPUT_DIR}/${KEYWORD_CSV}" > "${OUTPUT_FILE}"

# awk -F',' 'BEGIN { OFS="," }
# NR==1{
# 	print "video_id","total_count","positive_ratio","positive_bin","negative_ratio","negative_bin"
# 	next
# }
# {
# 	videoid=$1
# 	key_fam=$2
# 	count=$4 + 0
	
# 	total += count
# 	if (key_fam == "positive"){
# 		pos += count
# 	} else if (key_fam == "negative"){
# 		neg += count
# 	}
# }
# END {
# 	if(total > 0){
# 		pos_ratio = (pos / total)
# 		neg_ratio = (neg / total)
# 	} else {
# 		pos_ratio = 0
# 		neg_ratio = 0
# 	}
# 	if (pos_ratio > 0.7) p_bin = "Highly Positive"
# 	else if (pos_ratio > 0.3) p_bin = "Moderately Positive"
# 	else p_bin = "Low Positive"

# 	if (neg_ratio > 0.7) n_bin = "Highly Negative"
# 	else if (neg_ratio > 0.3) n_bin = "Moderately Negative"
# 	else n_bin = "Low Negative"
	
# 	print videoid, total, pos_ratio, p_bin, neg_ratio, n_bin
# }' "${OUTPUT_DIR}/${KEYWORD_CSV}" > "${OUTPUT_FILE}"

echo "input file: ${OUTPUT_DIR}/${KEYWORD_CSV}"
echo "output file: ${OUTPUT_DIR}/${OUTPUT_FILE}"
