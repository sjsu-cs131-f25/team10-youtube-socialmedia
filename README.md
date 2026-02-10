## Project Title:
Youtube Comment Sentiment Analysis

## Authors
Team Name: The Tag Team (TTT)  
Team Motto: It's T Time
Team Members:  
Trey C.
Hien T.
Richa V.
Karmehr A.
Jacob A.

## Dataset Description:
We are utilizing the YouTube API to collect comment, channel, and video data. Currently our dataset holds 314,383 rows of comment data in CSV files. Our data held on channel and video data is quite limited and remains at just the channel and video id's. We look to expand that to improve the variety of data collected moving forward. The data we collect for the YouTube comments includes the following columns: 

video_id,comment_id,author_display_name,published_at,like_count,comment_text,Is_reply,parent_id,channel_id

---

## Purpose / Overview
The repository contains a Bash-driven data processing pipeline (entrypoint: `run_pa4.sh`) that:
- Cleans and normalizes a CSV of YouTube comments,
- Produces frequency/top-N/token signals and temporal summaries,
- Applies quality filters and buckets by like-count,
- Optionally runs sprint4 sentiment/keyword/entity scripts (if present),
- Writes most outputs into `out/` and log output to `logs/run.log`.

---

## Prerequisites
- Unix-like environment (Linux or macOS). On Windows use WSL or Git Bash that provides GNU utilities.
- Bash (POSIX, ideally Bash 4+)
- Standard Unix tools: sed, awk, tr, sort, head, tail, tee, date, cp
- Python packages (if you use any Python scripts in `scripts/` or `src/`): install from `requirements.txt` (see below)

Install Python deps:
```bash
python3 -m venv .venv
source .venv/bin/activate
pip install -r requirements.txt
```
---

## How to run (commands & high-level config)
Usage:
```bash
# Make sure run_pa4.sh is executable:
chmod +x run_pa4.sh

# Run the pipeline:
bash run_pa4.sh <INPUT_COMMENTS_CSV> [VIDEO_ID]
```

- `<INPUT_COMMENTS_CSV>`: required — path to the input CSV file of comments.
- `[VIDEO_ID]`: optional — video id used by some sprint4 scripts (default: `n_Lv_mw6m6c`).

Example:
```bash
bash run_pa4.sh data/raw/comments_sample.csv UYV1_abcdef
```

What the script does at a high level:
- Creates `out/` and `logs/` if missing.
- Step 1: Clean & normalize CSV -> `out/clean.tsv`
- Step 2: Produce frequency tables, top N, and "skinny" view -> `out/freq_author.tsv`, `out/topN.tsv`, `out/skinny.tsv`, etc.
- Step 3: Quality filters -> `out/filtered.tsv`
- Step 4a: Buckets & ratios -> `out/ratios.tsv`, `out/buckets.tsv`
- Step 4b: (Optional) Calls sprint4 scripts in `scripts/sprint4/` for sentiment/keywords/entities. These scripts are run only if present.
- Step 5: Temporal aggregation -> `out/temporal.tsv`
- Step 6: Top tokens / signals -> `out/signals.tsv`
- Copies any sprint4-produced artifacts into `out/` for grading if present.

The script records progress and warnings to `logs/run.log`.

---

## Where outputs are written
- `out/` — primary outputs produced by the pipeline. Examples:
  - `out/clean.tsv`           — cleaned & normalized TSV version of the input
  - `out/sample_before.tsv`  — sample of original input head
  - `out/sample_after.tsv`   — sample of cleaned output head
  - `out/freq_author.tsv`    — frequency counts by author
  - `out/freq_isreply.tsv`   — frequency counts for reply vs non-reply
  - `out/topN.tsv`           — top-N comments (by likes)
  - `out/skinny.tsv`         — compact view of id/name/likes/date
  - `out/filtered.tsv`       — quality-filtered rows
  - `out/ratios.tsv`         — like counts + bucket labels
  - `out/buckets.tsv`        — counts per like bucket
  - `out/temporal.tsv`       — month-level temporal summary (YYYY-MM)
  - `out/signals.tsv`        — top tokens / signal discovery
  - Any sprint4 artifacts matching `data/processed/...` are copied into `out/` if they exist
- `logs/run.log` — run log (progress, warnings, copies). The pipeline appends timestamps and messages to this file.

---

## My Contributions — Jacob Atanacio ([@Javacadu](https://github.com/Javacadu))

| Area | Description | Tech | My Contributions |
|------|-------------|------|------------------|
| [YouTube Data Collector](src/collector.py) | Full YouTube API data collection pipeline for channel, video, and comment data with 314k+ rows collected | Python, YouTube Data API v3 | Designed and built the complete pipeline from scratch — channel/video/comment collection, threaded reply handling, CSV persistence, deduplication via collected-ID logs, error handling, logging, and type hints |
| [Pipeline — Steps 5 & 6](run_pa4.sh) | Temporal aggregation and signal/token discovery stages of the Bash processing pipeline | Bash, awk | Authored Step 5 (monthly comment volume and per-video averages → `out/temporal.tsv`) and Step 6 (stop-word–filtered top-token frequency → `out/signals.tsv`) |
| [Sprint 2 Scripts](scripts/sprint2/) | Exploratory data analysis and batch execution scripts | Bash | Created `access_and_snapshot.sh`, `eda.sh`, and `run_project2.sh` for initial EDA and batch runs |
| [Sprint 3 Scripts](scripts/sprint3/) | Statistical summaries and keyword-to-comment edge extraction | Bash, awk | Developed `comment_statistics.sh` and `define_edges.sh` for statistical analysis and edge relationship extraction |
| Project Infrastructure | Repository structure, dependency management, and sprint directory organization | Git, Python | Initialized repo structure, created `requirements.txt`, configured `.gitignore`, organized scripts into `scripts/sprint2/`, `scripts/sprint3/`, `scripts/sprint4/` |
| Code Review & Documentation | PR management, shared VM path configuration, and project README | Markdown, Git | Reviewed and merged team PRs, updated shared output paths for VM environment, authored the full project README |

---
