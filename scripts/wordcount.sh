#!/usr/bin/env bash

readonly PROGNAME=$(basename "$0")
readonly PROGDIR=$(readlink -m "$(dirname "$0")")

source "$PROGDIR/common.lib.sh"
isRgInstalledOrDie

input=""
if [[ -e "$1" ]]; then
    filename="$1"
    # Strip lines starting with % or @ or / or <!-- 
    # as well as markdown-esque comments like: 
    # [foo]: this is a comment
    input=$(cat "$filename")
elif [[ -z "$1" ]]; then
	input=$(cat) 
else
    echo "Usage: $0 [filename], or pipe to it"
    exit 1
fi

if [[ -z "$input" ]]; then
    echo "No input to wordcount"
    exit 1
fi

echo "$input" | rg -v '^[%@/]|^\[[^\]]*\]: |^<!-- ' | wc -w