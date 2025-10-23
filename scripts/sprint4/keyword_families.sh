set -euo pipefail
read -p "Please enter Youtube Video ID: " VIDEOID
VIDEOID="${VIDEOID:-n_Lv_mw6m6c}"
OUTPUT="${OUTPUT:-/mnt/scratch/CS131_jelenag/projects/team10_sec3/team10-youtube-socialmedia/data/processed/}"
KW="${KW:-/mnt/scratch/CS131_jelenag/projects/team10_sec3/team10-youtube-socialmedia/data/sentiment_keywords.csv}"
CMT="${CMT:-/mnt/scratch/CS131_jelenag/projects/team10_sec3/team10-youtube-socialmedia/data/yt_comments.csv}"

[ -n "$VIDEOID" ] || { echo "ERROR: VIDEOID is empty"; exit 1; }
mkdir -p "$OUTPUT"

OUTFILE="$OUTPUT/${VIDEOID}_sentiment_keyword_family.csv"

gawk -v FPAT='([^,]+)|(\"([^\"]|\"\")*\")' -v OFS=',' \
     -v vid="$VIDEOID" -v out="$OUTFILE" '
BEGIN {
  print "video_id,keyword_family,keyword,count" > out
}
FNR==NR {
  if (FNR==1 && (tolower($1)=="negative" || tolower($2)=="neutral" || tolower($3)=="positive")) next
  if ($1!="") { k=tolower($1); kw2fam[k]="negative"; allkw["negative",k]=1 }
  if ($2!="") { k=tolower($2); kw2fam[k]="neutral";  allkw["neutral",k]=1 }
  if ($3!="") { k=tolower($3); kw2fam[k]="positive"; allkw["positive",k]=1 }
  next
}
NR==1 { next }                                 
$1 == vid {
  txt = tolower($6)
  gsub(/[[:punct:]]+/, " ", txt)
  gsub(/[[:space:]]+/, " ", txt)
  sub(/^ +/, "", txt); sub(/ +$/, "", txt)

  delete seen
  n = split(txt, w, /[[:space:]]+/)
  for (i=1; i<=n; i++) {
    k = w[i]
    if (k in kw2fam && !(k in seen)) {
      fam = kw2fam[k]
      counts[fam, k]++
      seen[k] = 1
    }
  }
}
END {
  fams[1]="negative"; fams[2]="neutral"; fams[3]="positive"
  for (fi=1; fi<=3; fi++) {
    fam = fams[fi]
    for (key in allkw) {
      split(key, kk, SUBSEP)
      if (kk[1] != fam) continue
      k = kk[2]
      c = ((fam SUBSEP k) in counts ? counts[fam, k] : 0)
      print vid, fam, k, c > out
    }
  }
}
' "$KW" "$CMT"

echo "wrote: $OUTFILE"

{ head -n 1 "$OUTFILE"; tail -n +2 "$OUTFILE" | sort -t',' -k4,4nr; } > "${OUTFILE}.tmp" && mv "${OUTFILE}.tmp" "$OUTFILE"

echo "sorted file $OUTFILE"
