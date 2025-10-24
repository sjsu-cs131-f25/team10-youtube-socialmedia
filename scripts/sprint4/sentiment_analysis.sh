#!/bin/bash
: << 'SENTIMENT_ANALYSIS'
This script performs a sentiment analysis 
current data collected includes the following
positive, negatative, neutral words and their count
header: 
videoID, positive/negative/neutral, keyword, occurance count

In this script I will calculate the video's positive/negative ratio and also sort the video into a rating bucket
SENTIMENT_ANALYSIS

set -euo pipefail

#have user enter videoID, use n_Lv_mw6m6c as default
read -p "Please enter Youtube Video ID: " VIDEO_ID
VIDEO_ID="${VIDEO_ID:-n_Lv_mw6m6c}"

PROJECT_ROOT="$(cd ../.. && pwd)" 
DATASET_DIR="/mnt/scratch/CS131_jelenag/projects/team10_sec3/team10-youtube-socialmedia/data"
OUTPUT_DIR="${DATASET_DIR}/processed"
KEYWORD_CSV="${VIDEO_ID}_sentiment_keyword_family.csv"
OUTPUT_FILE="${VIDEO_ID}_sentiment_bucket_analysis.csv"

# Verify directories are correct
#echo "Home path: ${PROJECT_ROOT}"
#echo "Output directory: ${OUTPUT_DIR}"
#echo "Output file: ${OUTPUT_FILE}"
#echo "Dataset directory: ${DATASET_DIR}"
#echo "Video sentiment CSV Path: ${KEYWORD_CSV}"

[ -n "$VIDEO_ID" ] || { echo "ERROR: VIDEOID is empty"; exit 0; }

cd "$OUTPUT_DIR"

awk -F',' 'BEGIN { OFS="," }
NR==1{
	print "video_id","total_count","positive_ratio","positive_bin","negative_ratio","negative_bin"
	next
}
{
	videoid=$1
	key_fam=$2
	count=$4 + 0
	
	total += count
	if (key_fam == "positive"){
		pos += count
	} else if (key_fam == "negative"){
		neg += count
	}
}
END {
	if(total > 0){
		pos_ratio = (pos / total)
		neg_ratio = (neg / total)
	} else {
		pos_ratio = 0
		neg_ratio = 0
	}
	if (pos_ratio > 0.7) p_bin = "Highly Positive"
	else if (pos_ratio > 0.3) p_bin = "Moderately Positive"
	else p_bin = "Low Positive"

	if (neg_ratio > 0.7) n_bin = "Highly Negative"
	else if (neg_ratio > 0.3) n_bin = "Moderately Negative"
	else n_bin = "Low Negative"
	
	print videoid, total, pos_ratio, p_bin, neg_ratio, n_bin
}' "${OUTPUT_DIR}/${KEYWORD_CSV}" > "${OUTPUT_FILE}"

echo "input file: ${OUTPUT_DIR}/${KEYWORD_CSV}"
echo "output file: ${OUTPUT_DIR}/${OUTPUT_FILE}"


