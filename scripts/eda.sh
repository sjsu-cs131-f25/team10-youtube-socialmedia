#!/usr/bin/env bash

# Output directory
OUTDIR="/mnt/scratch/CS131_jelenag/students/<yournamedir>/project"
mkdir -p "$OUTDIR"
CSV="/mnt/scratch/CS131_jelenag/projects/team10_sec3/team10-youtube-socialmedia/data/yt_comments.csv"
# Files used:
# yt_comments.csv columns:
# 1 video_id, 2 comment_id, 3 author_display_name, 4 published_at,
# 5 like_count, 6 comment_text, 7 is_reply, 9 channel_id

# 1) Frequency of channel_id (counts per channel)
cut -d, -f9 "$CSV" | tail -n +2 | grep '^UC' | sort | uniq -c | sort -nr \
	> "$OUTDIR/freq_channel_id.txt"

# 2) Frequency of replies and comments
cut -d, -f7 "$CSV" | tail -n +2 | grep -E '^(0|1)$' | sort | uniq -c | sort -nr \
	> "$OUTDIR/freq_is_reply.txt"

# 3) Top 20 most-liked comments (keep first 6 fields; sort by like_count = col 5)

tail -n +2 "$CSV" | rev | cut -d, -f4- | rev | sort -t, -k5 -nr | head -20 \
	> "$OUTDIR/top_comments.csv"
# 4) Skinny comments table (video_id, comment_id, like_count)
{ echo "video_id,comment_id,like_count"
	  tail -n +2 "$CSV" | cut -d, -f1,2,5 | sort -u
  } > "$OUTDIR/skinny_comments.csv"

echo "Done. Results in $OUTDIR"
  
