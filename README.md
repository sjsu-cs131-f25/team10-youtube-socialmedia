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

## Individual Contributions

### Jacob Atanacio ([@Javacadu](https://github.com/Javacadu))

- **YouTube Data Collector** (`src/collector.py`): Designed and built the complete YouTube API data collection pipeline from scratch. Implemented functions for collecting channel metadata, video metadata, and comments (including threaded replies) with CSV persistence, deduplication via collected-ID logs, robust error handling, logging, and type hints.
- **Project Infrastructure & Setup**: Initialized the repository structure, created `requirements.txt` for dependency management, configured `.gitignore`, and organized scripts into sprint-based directories (`scripts/sprint2/`, `scripts/sprint3/`, `scripts/sprint4/`).
- **Bash Pipeline — Steps 5 & 6**: Authored the temporal aggregation logic (Step 5 — monthly comment volume and per-video averages → `out/temporal.tsv`) and the signal/token discovery logic (Step 6 — stop-word–filtered top-token frequency → `out/signals.tsv`) in `run_pa4.sh`.
- **Sprint 2 Scripts**: Created `access_and_snapshot.sh`, `eda.sh`, and `run_project2.sh` for initial exploratory data analysis and batch execution.
- **Sprint 3 Scripts**: Developed `comment_statistics.sh` for statistical summaries and `define_edges.sh` for extracting keyword-to-comment-ID edge relationships.
- **Code Review & Project Management**: Reviewed and merged team pull requests, updated shared output paths, and ensured the pipeline ran correctly on the team's shared VM environment.
- **Documentation**: Authored the project README covering dataset description, prerequisites, usage instructions, and output descriptions.

### Karmehr Arora

- **Data Quality & Clustering** (`scripts/sprint3/Sprint3_runnable.sh`, `scripts/sprint4/data_quality.sh`): Set up data quality filtering, datetime processing, and cluster-based analysis.
- **Sentiment Analysis** (`scripts/sprint4/sentiment_analysis.sh`, `scripts/sprint4/sentiment_kw_gen.sh`): Created sentiment analysis scripts with positive/negative ratio bucketing and keyword-family generation.
- **Entity Summary** (`scripts/sprint4/entity_summary.sh`): Built the entity numeric analysis pipeline.
- **Dataset Maintenance**: Updated the dataset description, created data cards, managed CSV data hosting, and cleaned project folders.

### Hien Ly ([@H13NL](https://github.com/H13NL))

- **Sprint 3 — Steps 2 & 4** (`scripts/sprint3/Step2_4.sh`): Developed frequency tables, Top-N entity lists, and comparison steps for sprint 3 deliverables.
- **TypeScript Port** (`scripts/typescript/`): Ported analysis steps into TypeScript.
- **Top-30 Overall**: Created the `top30_overall` aggregation for cross-video comment ranking.

### Richa Vakharia

- **Runnable Pipeline Script** (`run_pa4.sh`): Integrated steps 3–6 into the main `run_pa4.sh` pipeline and ensured end-to-end execution.
- **Skinny Table Preview**: Implemented the compact "skinny" table view of 10k rows for quick data inspection.
- **PR Management**: Reviewed and merged multiple team pull requests across sprints 3 and 4.

### Trey C. ([@Trv3son](https://github.com/Trv3son))

- **Reproducible sed + awk Pipeline (Steps 1 & 2)**: Authored the core `sed`/`awk` cleaning and normalization pipeline for raw CSV → clean TSV conversion.
- **Sprint 3 — Step 3 Histogram** (`scripts/sprint3/step3_cluster_histogram.sh`): Created the cluster-size histogram shell script and generated the histogram PNG (`Project3/cluster_histogram.png`).
- **Project3 Deliverables**: Consolidated Project3 outputs and finalized reproducible artifacts.

---
