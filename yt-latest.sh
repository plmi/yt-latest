#!/bin/bash

# author: plmi
# date: 10/24/2020

BASE_URL="https://www.googleapis.com/youtube/v3/"

getUploadPlaylist() {
  local channel_id="$1"
  curl -s\
    "${BASE_URL}channels?part=contentDetails&id=${channel_id}&key=${API_KEY}" \
    --header 'Accept: application/json' \
    --compressed | jq --raw-output '. | .items[0].contentDetails.relatedPlaylists.uploads'
}

getVideosByPlaylist() {
  local playlist_id="$1"
   curl -s\
    "${BASE_URL}playlistItems?part=contentDetails&playlistId=${playlist_id}&key=${API_KEY}" \
    --header 'Accept: application/json' \
    --compressed | jq '[.items[] | .contentDetails]'
}

getLatestVideo() {
  local videos="$1"
  # we sort it ourselves to be very sure about the order
  echo "${videos}" | jq \
    --raw-output '. | sort_by(.videoPublishedAt) | reverse | .[0].videoId' | \
    xargs printf "https://youtube.com/watch?v=%s"
}

getLatestVideoByChannelId() {
  local channel_id="$1"
  local playlist_id=$(getUploadPlaylist "$channel_id")
  local videos=$(getVideosByPlaylist "$playlist_id")
  getLatestVideo "$videos"
}

program_exists() {
	hash "$1" 2>/dev/null && return 0 || return 1
}

usage() {
  echo "usage $(basename $0) --api_key <api key> --channel <channel id>"
}

while [ "$1" != "" ]; do
  case $1 in
    -a | --api-key )        shift ; API_KEY="$1" ;;
    -c | --channel )        shift ; CHANNEL_ID="$1" ;;
    -h | --help )           usage ; exit ;;
    * )                     usage ; exit 1 ;;
  esac
  shift
done

if [ -z "$API_KEY" ] || [ -z "$CHANNEL_ID" ]; then
 usage && exit 1
fi

declare -a required=("curl" "mpv" "jq")
for program in "${required[@]}"; do 
  # https://unix.stackexchange.com/a/156887
  program_exists "$program" || { echo >&1 "[-] ${program} not installed" & exit 1; }
done

VIDEO_URL="$(getLatestVideoByChannelId "$CHANNEL_ID")"
FORMAT='247+bestaudio/best' # 720p

mpv --ontop --geometry=--0-0 "$VIDEO_URL" --ytdl-format=${FORMAT}
