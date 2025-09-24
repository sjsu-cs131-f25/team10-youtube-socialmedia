#!/usr/bin/env bash

# Adjust this to your folder name
OUTDIR="/mnt/scratch/CS131_jelenag/projects/team10_sec3/team10-youtube-socialmedia/out/"
# mkdir -p "$OUTDIR"

CSV="/mnt/scratch/CS131_jelenag/projects/team10_sec3/team10-youtube-socialmedia/data/yt_comments.csv"
# Columns:
# 1 video_id, 2 comment_id, 3 author_display_name, 4 published_at,
# 5 like_count, 6 comment_text, 7 is_reply, 8 parent_id, 9 channel_id

# 1) Frequency of channel_id (counts per channel)
cut -d, -f9 "$CSV" | tail -n +2 | grep '^UC' | sort | uniq -c | sort -nr \
	  > "$OUTDIR/freq_channel_id.txt"

# 2) Frequency of published dates (YYYY-MM-DD from col 4)
cut -d, -f4 "$CSV" | tail -n +2 \
	| grep -o -E '[0-9]{4}-[0-9]{2}-[0-9]{2}' \
	| sort | uniq -c | sort -nr \
	> "$OUTDIR/freq_dates.txt"

  # 3) Top-N entity list WITH counts (top videos by comment count)
  cut -d, -f1 "$CSV" | tail -n +2 | grep -v '^$' | sort | uniq -c | sort -nr | head -20 \
	    > "$OUTDIR/top_videos.txt"

  # 4) grep -i / grep -v (simple showcase)
  grep -i -c "great" "$CSV" > "$OUTDIR/grep_count_great.txt"
  grep -vi -c "bad"  "$CSV" > "$OUTDIR/grep_count_no_bad.txt"

  echo "Done. Results in $OUTDIR"
