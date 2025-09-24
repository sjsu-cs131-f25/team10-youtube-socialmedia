# Data Card: Youtube Comments Dataset
## Dataset Source: 
https://github.com/sjsu-cs131-f25/team10-youtube-socialmedia/blob/main/src/collector.py

To download the dataset, run the collector.py file from the link above. Please note that data retrieved may not be the exact same for every time you run the program.

## File formats: 
Data collection is done by collecting data from the YouTube API
The data is stored in several .csv files inside of the /data directory
Note that collector.py utilizes the channels.txt file to create the csv data files

## Dataset Shape

### Yt_comments.csv
314,383 rows of data
Columns: video_id,comment_id,author_display_name,published_at,like_count,comment_text,
Is_reply,parent_id,channel_id
Size: 52 Megabytes

### Collected_comments.csv
249,282 rows of data
Columns: comment_id
Size: 7.2 Megabytes

### Collected_videos.csv
142 rows of data
Columns: video_id
Size: 1.7 Kilobytes

