#!/bin/env bash


PROJECT_ROOT="/mnt/scratch/CS131_jelenag/projects/team10_sec3/team10-youtube-socialmedia"
DATASET="/mnt/scratch/CS131_jelenag/projects/team10_sec3/team10-youtube-socialmedia/data"
OUTPUT="/mnt/scratch/CS131_jelenag/projects/team10_sec3/team10-youtube-socialmedia/data/processed"
LOG_DIR="${PROJECT_ROOT}/out"
LOG_FILE="${LOG_DIR}/sentiment_gen__log.txt"
INPUT_CSV="${DATASET}/yt_comments.csv"

mkdir -p "${OUTPUT}" "${LOG_DIR}"
chmod 775 "${OUTPUT}"
chmod 775 "${LOG_DIR}"

awk 'BEGIN{
  print "negative,neutral,positive"
  neg="angry,sad,terrible,bad,horrible,worst,disappointed,awful,annoyed,frustrated,upset,mad,irritated,unhappy,tragic,poor,lousy,dreadful,pathetic,depressing"
  neu="okay,average,fine,ordinary,moderate,unclear,indifferent,uncertain,expected,plain,neutral,balanced,steady,fair,regular,standard,typical,mediocre,common,adequate"
  pos="great,amazing,excellent,good,awesome,delightful,happy,superb,wonderful,fantastic,incredible,loved,perfect,brilliant,outstanding,pleased,joyful,exciting,positive,impressive"
  split(neg,n,","); split(neu,u,","); split(pos,p,",")
  for(i=1;i<=20;i++)
    printf "%s,%s,%s\n", n[i], u[i], p[i]
}' >"$DATASET/sentiment_keywords.csv"

echo "Wrote sentiment_keywords.csv"
