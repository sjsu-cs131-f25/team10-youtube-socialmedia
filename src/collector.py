import os
from dotenv import load_dotenv

import googleapiclient.errors
from googleapiclient.discovery import build

import csv
import logging
# added type hints for better code clarity and maintainability
from typing import List, Dict, Set, Tuple, Optional

# setup logging for debugging reasons
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(levelname)s - %(message)s',
    handlers=[
        logging.FileHandler('logs/collector.log'),
        logging.StreamHandler()
    ]
)
logger = logging.getLogger(__name__)


# making globals 

def create_youtube_client():
    try:
        load_dotenv()
        api_key = os.getenv('API_KEY')
        if not api_key:
            raise ValueError("API_KEY not found in environment variables. Please check your .env file.")
        
        client = build("youtube", "v3", developerKey=api_key)
        logger.info("YouTube API client created successfully")
        return client
    except Exception as e:
        logger.error(f"Failed to create YouTube client: {e}")
        raise

youtube = create_youtube_client()

# @TODO
# get channel -> get uploads playlist id -> get ~10 videos -> get max 100 comments using threads per video

""" 
9-4-2025

for now the top priority is getting the comments, i think its a good idea to consider channel & video metrics in the future though..
you dont use the channelID to seach for videos, theres another Id that is a playlist of all the channel's uploaded vids,
we will use this. getChannel_uplaodsId() grabs the uploaded vids playlist Id for each channel, we get a chanel uing the @handle(we dont need the @ just plaintext is fine)

next task is finding a good way to collect a batch of videos for each playlist... when we're doing 100's of videos and comments that will add up time and resource wise so lets just make it easier for future us now and come up with an efficient way now
 
9-26-2025

next steps are collecting channel data and video data to identify more relationships in data and more potential for data networking

we will collect all of the metadata available for channels and videos but when querying from our dataset we will focus on the following fields:
channel data: id, title, country
video data: id, title, description, publish date, stats {view count, like count, comment count}, live broadcast content, tags, content details {duration, definition, caption}
comment data: id, author display name, published at, like count, comment text, is reply (boolean), parent id (if reply), author channel id, video id

these will all be connected: channel : video -> channel_id, video : comment -> video_id

"""

# grabbing channels by their '@' handle may be the easiest if we have a predefined list of channels we want
def get_channel_uploads_id():
    uploads = {}
    with open('data/channels.txt', 'r') as channels:
        for channel in channels:
            handle = channel.strip()
            if not handle:
                continue
            try:
                request = youtube.channels().list(
                    part="snippet,contentDetails,statistics",
                    forHandle=handle
                )
                response = request.execute()
                if response['items']:
                    uploads[handle] = response['items'][0]['contentDetails']['relatedPlaylists']['uploads']
                else:
                    print(f"No channel found for handle: {handle}")
            except Exception as e:
                print(f"Error for {handle}: {e}")
                continue
    return uploads

def get_channel_data():
    channels_data = []
    with open('data/channels.txt', 'r') as channels:
        for channel in channels:
            handle = channel.strip()
            if not handle:
                continue
            try:
                request = youtube.channels().list(
                    part="snippet,contentDetails,statistics",
                    forHandle=handle
                )
                response = request.execute()
                if response['items']:
                    channel_info = {
                        'channel_id': response['items'][0]['id'],
                        'title': response['items'][0]['snippet']['title'],
                        'country': response['items'][0]['snippet'].get('country', 'N/A'),
                    }
                    channels_data.append(channel_info)
                else:
                    print(f"No channel found for handle: {handle}")
            except Exception as e:
                print(f"Error for {handle}: {e}")
                continue
    return channels_data

# save channel data to csv
def write_channel_data_to_csv(channels_data, csv_path='data/yt_channel_data.csv'):
    with open(csv_path, 'w', newline='', encoding='utf-8') as csvfile:
        fieldnames = ['channel_id', 'title', 'country']
        writer = csv.DictWriter(csvfile, fieldnames=fieldnames)
        writer.writeheader()
        for channel in channels_data:
            writer.writerow(channel)
    print(f"Channel data written to {csv_path}")



# note: cost of this operation is 100 units of the alloted 10,000 units per 24 hours
# get video IDs from a playlist (uploads playlist from channel)
def get_video_ids_from_playlist(playlist_id: str, max_results: int = 10) -> List[str]:
    video_ids = []
    nextPageToken = None
    while len(video_ids) < max_results:
        try:
            request = youtube.playlistItems().list(
                part="contentDetails",
                playlistId=playlist_id,
                maxResults=min(50, max_results - len(video_ids)),
                pageToken=nextPageToken
            )
            response = request.execute()
            for item in response.get('items', []):
                video_id = item['contentDetails']['videoId']
                video_ids.append(video_id)
            nextPageToken = response.get('nextPageToken')
            if not nextPageToken:
                break
        except Exception as e:
            print(f"Error fetching videos from playlist {playlist_id}: {e}")
            break
    return video_ids

# get video data from a list of video IDs
def get_video_data(video_ids) -> list:
    videos_data = []
    for id in video_ids:
        try:
            request = youtube.videos().list(
                part="snippet,contentDetails,statistics",
                id=id
            )
            response = request.execute()
            if response['items']:
                item = response['items'][0]
                video_data = {
                    'kind': item['kind'],
                    'channel_id': item['snippet']['channelId'],
                    'default_language': item['snippet'].get('defaultLanguage', 'N/A'),
                    'video_id': item['id'],
                    'title': item['snippet']['title'],
                    'description': item['snippet']['description'],
                    'publish_date': item['snippet']['publishedAt'],
                    'view_count': item['statistics'].get('viewCount', 0),
                    'like_count': item['statistics'].get('likeCount', 0),
                    'comment_count': item['statistics'].get('commentCount', 0),
                    'live_broadcast_content': item['snippet'].get('liveBroadcastContent', 'none'),
                    'tags': ','.join(item['snippet'].get('tags', [])),
                    'duration': item['contentDetails'].get('duration', ''),
                    'definition': item['contentDetails'].get('definition', ''),
                    'caption': item['contentDetails'].get('caption', 'false'),
                }
                videos_data.append(video_data)
            else:
                print(f"No video found for ID: {id}")
        except Exception as e:
            print(f"Error fetching data for video {id}: {e}")
            continue
    return videos_data

# save video data to csv
def write_video_data_to_csv(videos_data, csv_path='data/yt_video_data.csv'):
    if not videos_data:
        return
    
    file_exists = os.path.exists(csv_path)
    with open(csv_path, 'a', newline='', encoding='utf-8') as csvfile:
        fieldnames = videos_data[0].keys()
        writer = csv.DictWriter(csvfile, fieldnames=fieldnames)
        if not file_exists:
            writer.writeheader()
        writer.writerows(videos_data)
    print(f"Video data appended to {csv_path}")

# Collect comments for each video and write to CSV
def load_ids_from_csv(csv_path, id_col):
    ids = set()
    if not os.path.exists(csv_path):
        return ids
    with open(csv_path, 'r', encoding='utf-8') as f:
        reader = csv.DictReader(f)
        for row in reader:
            ids.add(row[id_col])
    return ids

def save_ids_to_csv(csv_path, ids, header):
    mode = 'a' if os.path.exists(csv_path) else 'w'
    with open(csv_path, mode, newline='', encoding='utf-8') as f:
        writer = csv.writer(f)
        if mode == 'w':
            writer.writerow(header)
        for id_val in ids:
            writer.writerow([id_val])

def write_comment_row(writer, video_id, comment_id, snippet, is_reply, parent_id):
    writer.writerow([
        video_id,
        comment_id,
        snippet.get('authorDisplayName', ''),
        snippet.get('publishedAt', ''),
        snippet.get('likeCount', 0),
        snippet.get('textDisplay', ''),
        is_reply,
        parent_id,
        snippet.get('authorChannelId', {}).get('value', '')
    ])

def fetch_comments_for_video(video_id, collected_comments):
    comments = []
    nextPageToken = None
    while True:
        try:
            request = youtube.commentThreads().list(
                part="snippet,replies",
                maxResults=100,
                order="time",
                textFormat="plainText",
                videoId=video_id,
                pageToken=nextPageToken
            )
            response = request.execute()
            for item in response.get('items', []):
                comment_id = item['id']
                if comment_id not in collected_comments:
                    snippet = item['snippet']['topLevelComment']['snippet']
                    comments.append((video_id, comment_id, snippet, 0, ''))
                # Replies
                for reply in item.get('replies', {}).get('comments', []):
                    reply_id = reply['id']
                    if reply_id not in collected_comments:
                        reply_snippet = reply['snippet']
                        comments.append((video_id, reply_id, reply_snippet, 1, reply_snippet.get('parentId', '')))
            nextPageToken = response.get('nextPageToken')
            if not nextPageToken:
                break
        except Exception as e:
            print(f"Error fetching comments for video {video_id}: {e}")
            break
    return comments

# writes comments to yt_comments.csv and returns set of new comment IDs
def write_comments_to_csv(comments, csv_path):

    new_comments = set() # to track newly added comments and add to seen comments log later

    with open(csv_path, 'a', newline='', encoding='utf-8') as csvfile:
        writer = csv.writer(csvfile)
        if csvfile.tell() == 0:
            writer.writerow([
                'video_id', 'comment_id', 'author_display_name', 'published_at',
                'like_count', 'comment_text', 'is_reply', 'parent_id', 'channel_id'
            ])

        for video_id, comment_id, snippet, is_reply, parent_id in comments: # where the writing happens
            write_comment_row(writer, video_id, comment_id, snippet, is_reply, parent_id)
            new_comments.add(comment_id)

    return new_comments

# main function to collect comments for a list of video IDs and write to CSV
def collect_and_write_comments(video_ids, csv_path='data/yt_comments.csv', video_log='data/collected_videos.csv', comment_log='data/collected_comments.csv'): 

    collected_videos = load_ids_from_csv(video_log, 'video_id')
    collected_comments = load_ids_from_csv(comment_log, 'comment_id')

    new_videos = set()
    all_new_comments = set()

    for video_id in video_ids:
        if video_id in collected_videos: # check if we've already collected comments for this video
            print(f"Skipping already collected video: {video_id}")
            continue
        
        comments = fetch_comments_for_video(video_id, collected_comments)
        new_comments = write_comments_to_csv(comments, csv_path)
        all_new_comments.update(new_comments)
        new_videos.add(video_id)

    if new_videos: # log newly processed videos to avoid reprocessing
        save_ids_to_csv(video_log, new_videos, ['video_id'])
    if all_new_comments: # log newly collected comments
        save_ids_to_csv(comment_log, all_new_comments, ['comment_id'])

def testAPI(): # simple test function to ensure API is working
    global youtube
    request = youtube.channels().list(
        part="snippet,contentDetails,statistics",
        id="UC_x5XG1OV2P6uZZ5FSM9Ttw"
    )
    response = request.execute()

    print('\n\n\n' + 'REQUESTED' + '\n\n\n')
    
    try:
        print(response)
        print('\n\n\n' + 'REQUEST SUCCESS!' + '\n\n\n')    
    except:
        print('\n\n\n' + 'REQUEST FAILED' + '\n\n\n')
        

def main():
    print("=== Starting YouTube Data Collection ===")
    
    # Test API connection first
    print("\n1. Testing API connection...")
    testAPI()
    
    try:
        # channel data
        print("\n2. Collecting channel metadata...")
        channels_data = get_channel_data()
        write_channel_data_to_csv(channels_data)
        print(f"Collected data for {len(channels_data)} channels")

        # get uploads playlist IDs
        print("\n3. Getting channel upload playlists...")
        channel_uploads = get_channel_uploads_id()
        print(f"Found upload playlists for {len(channel_uploads)} channels")

        # process each channel
        total_videos = 0
        for handle, playlist_id in channel_uploads.items():
            print(f"\n4. Processing channel: {handle}")
            print(f"Playlist ID: {playlist_id}")
            
            # get video IDs from playlist
            video_ids = get_video_ids_from_playlist(playlist_id, max_results=10)
            print(f"Found {len(video_ids)} videos")
            
            if video_ids:
                # get video data
                video_data = get_video_data(video_ids)
                write_video_data_to_csv(video_data)
                print(f"Saved {len(video_data)} video records")
                
                # collect comments for these videos
                print(f"Collecting comments...")
                collect_and_write_comments(video_ids)
                print(f"Completed comments for {handle}")
                
                total_videos += len(video_ids)
            else:
                print(f"No videos found for {handle}")
        
        print(f"\nCollection Complete")
        print(f"Summary:")
        print(f"Channels processed: {len(channel_uploads)}")
        print(f"Total videos processed: {total_videos}")
        print(f"Files created:")
        print(f"data/yt_channel_data.csv")
        print(f"data/yt_video_data.csv")
        print(f"data/yt_comments.csv")
        print(f"data/collected_videos.csv (log)")
        print(f"data/collected_comments.csv (log)")

    except Exception as e:
        print(f"\nError in main execution: {e}")
        import traceback
        traceback.print_exc()


if __name__ == "__main__":
    main()