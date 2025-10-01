#!/usr/bin/env bash
# run_project2.sh - PART E
# Usage:
#	run_project2.sh
#
# Dataset: /mnt/scratch/CS131_jelenag/projects/team10_sec3/team10-youtube-socialmedia/data/yt_comments.csv
# Delimiter: comma ","
# Assumptions: youtube comments contain multiple replies via comment threads that discuss thoughts and opinions on each respective video.
# 	youtube comment content can be used to perform sentiment alalysis on each video to provide an accurate gague on how good or poorly recieved the
#	video was.


PROJECT_ROOT="$HOME/team10-youtube-socialmedia"
DATASET="/mnt/scratch/CS131_jelenag/projects/team10_sec3/team10-youtube-socialmedia/data/yt_comments.csv"
OUT_DIR="$PROJECT_ROOT/out"
LOG="$OUT_DIR/run_$(date +%F_%H-%M-%S).log"

mkdir -p "$OUT_DIR"

set -x
{
  echo "=== START: $(date) ==="

  echo "Generating sample (1000 rows) from: $DATASET"
  bash "$PROJECT_ROOT/scripts/access_and_snapshot.sh" "$DATASET" 1000

  echo "Perform EDA"
  bash "$PROJECT_ROOT/scripts/eda.sh"

  echo "Done"
  echo "=== END: $(date) ==="
} >"$LOG" 2>&1
set +x

echo "Log saved to: $LO"
