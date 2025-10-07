#!/usr/bin/env bash
# Script: step3_cluster_histogram.sh
# Purpose: Step 3 of Project 3 — compute cluster sizes and a size→frequency table
set -euo pipefail
EDGES="/mnt/scratch/CS131_jelenag/projects/team10_sec3/team10-youtube-socialmedia/out/project3/edges/author_and_comment_ids_edges_thresholded.tsv"
cut -d',' -f1 "$EDGES" \
| tail -n +2 \
| sort \
| uniq -c \
| sort -n \
| sed -E 's/^[[:space:]]*([0-9]+)[[:space:]]+(.+)$/\2\t\1/' \
> Project3/cluster_sizes.tsv
cut -f2 Project3/cluster_sizes.tsv \
| sort -n \
| uniq -c \
| sed -E 's/^[[:space:]]*([0-9]+)[[:space:]]+(.+)$/\2\t\1/' \
> Project3/cluster_sizes_histogram.tsv
