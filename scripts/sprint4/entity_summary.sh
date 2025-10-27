#!/bin/bash
: << 'ENTITY SUMMARY'
This script performs a simple numerical analysis on our data 
current data collected includes the following
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
OUTPUT_FILE="entity_numeric_analysis.csv"

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
NR>1{
	videoid=$1
	key_fam=$2
	count=$4 + 0

	total[videoid] += count
		if (key_fam == "positive"){
			pos[videoid] += count
			positive_keys[videoid] += 1
		} else if (key_fam == "negative"){
			neg[videoid] += count
			negative_keys[videoid] += 1
		} else {
			neutral[videoid] += count
			neutral_keys[videoid] += 1
		}
}
END {
	# calculate averages, prints counts 
	for (v in total) {
		pos_avg=pos[v]/positive_keys[v]
		neutral_avg=neutral[v]/neutral_keys[v]
		neg_avg=neg[v]/negative_keys[v]
		print v, total[v], pos[v]+0, neutral[v]+0, neg[v]+0, pos_avg, neutral_avg, neg_avg
	}
}' "${OUTPUT_DIR}/${KEYWORD_CSV}" > "${OUTPUT_FILE}"

echo "input file: ${OUTPUT_DIR}/${KEYWORD_CSV}"
echo "output file: ${OUTPUT_DIR}/${OUTPUT_FILE}"
