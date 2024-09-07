#!/usr/bin/env bash

set -eu
# set -e # exit immediately on non-zero status of a command
# set -u # fail on undefined variables

readonly PROGNAME=$(basename $0)
readonly PROGDIR=$(readlink -m "$(dirname "$0")")

fzfOutputFile="$*"

# NB: This second sed also strips out any leading '|', which are tab indicators in browseJournals.sh
filename=$(printf "%s" "$fzfOutputFile" | sed 's#^| ##' | sed 's#.*::\s*\(.*\)#\1#')
tagname=$(echo "$filename" | sed 's#\./##g' | sed 's#\.md$##g' | sed 's#^.*/##g')
# notify-send "file" "$filename"
# notify-send "tag" "$tagname"

if command -v bat > /dev/null; then
    fileviewer="bat --color=always --style plain --pager never --language md"
else
    fileviewer="cat" 
fi

if [[ -f "$filename" ]]; then
    $fileviewer "$filename"
else
    echo "File $filename does not exist (yet)"
    exit
fi

# rg 

# tags=$(python $PROGDIR/todobuddy.py --tag "${filename/.md//}")
# look for tagname (without md ending)
tags=$(python $PROGDIR/todobuddy.py --tag "$tagname")
# notify-send "ercode" "$?"
# if [[ -z "$?" ]]; then
    echo ""
    echo "===================================="
    echo "References to tag '$tagname' in other files"
    echo "===================================="
    echo "$tags" | $fileviewer
# else
#     echo ""
#     echo "========================="
#     echo "Tag $tagname does not seem to have been used anywhere"
# fi