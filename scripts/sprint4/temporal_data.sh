#!/bin/env bash


PROJECT_ROOT="/mnt/scratch/CS131_jelenag/projects/team10_sec3/team10-youtube-socialmedia"
DATASET="/mnt/scratch/CS131_jelenag/projects/team10_sec3/team10-youtube-socialmedia/data"
OUTPUT="/mnt/scratch/CS131_jelenag/projects/team10_sec3/team10-youtube-socialmedia/data/processed"
LOG_DIR="${PROJECT_ROOT}/out"
LOG_FILE="${LOG_DIR}/temporal_log.txt"
INPUT_CSV="${DATASET}/yt_comments.csv"

mkdir -p "${OUTPUT}" "${LOG_DIR}"
chmod 775 "${OUTPUT}"
chmod 775 "${LOG_DIR}"

echo "The following script analyzes YouTube comment data to show, for each month:

the total number of comments, and

the average number of comments per video"

echo "columns: month | tmonth_total (total comments in month) | tavg_per_video (average # of comments per vid that month)"

cd "${OUTPUT}"

awk -F',' -v OFS="," '
NR>1{
  m=substr($4,1,7)
  if(m~/^[0-9]{4}-[0-9]{2}$/){
    vid=$1
    month_count[m]++
    if(!(m SUBSEP vid in seen)){ seen[m SUBSEP vid]=1; video_count[m]++ }
  }
}
END{
  print "month\tmonth_total\tavg_per_video"
  PROCINFO["sorted_in"]="@ind_str_asc"
  for(m in month_count){
    total=month_count[m]
    vids=video_count[m]
    avg=(vids>0?total/vids:0)
    printf "%s\t%d\t%.2f\n",m,total,avg
  }
}' "$INPUT_CSV" > "$OUTPUT/monthly_comment_stats.csv"

echo "Finished... Wrote to: processed/monthly_comment_stats.csv"
