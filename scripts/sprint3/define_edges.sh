# vid id's -> comment id (one video, many comments)

# parent comment id -> reply id (each parent comment and all of it's replies)

# channel id(of commenter) -> comment id (basically comments from the same author relationship)

# "great" -> comment id (all comments with the word "great")

PROJECT_ROOT = "$HOME/team10-youtube-socialmedia"
DATASET = "/mnt/scratch/CS131_jelenag/projects/team10_sec3/team10-youtube-socialmedia/data" # dataset dir
OUTPUT = "/mnt/scratch/CS131_jelenag/projects/team10_sec3/team10-youtube-socialmedia/data/processed" # processed data

echo "Finding relationships in dataset (edges)"
cd DATASET
echo "Video_id | Comment_id"
cut -d $',' -f1,2 yt_comments.csv > processed/videos_and_comment_ids.csv

echo "parent_comment_id | reply_id"
awk -F, 'NR==1 {print "parent_comment_id,reply_id"; next} $7 == 1 { print $2 "," $4 }' yt_comments.csv > processed/comments_with_replies.csv

echo "author_id | video_id" # author's channel and each other their comments posted
cut -d $ '\t' -f9,1 yt_comments.csv > processed/author_and_comment_ids.csv

echo "all comment id's that have the word 'great' "
awk -F, 'NR>1 {
	id = $1
	txt=tolower($2)
	gsub(/"/,"",txt)
	if(txt ~ /(^|[[:space:]])great([[:space:]]|$)/) {
		print ("great," id
	}
}' yt_comments.csv > processed/great_in_comments.csv

