#!/usr/bin/env bash

set -euo pipefail
# set -e # exit immediately on non-zero status of a command
# set -u # fail on undefined variables
# set -o pipefail # do not fail silently if piping erros

searchterm="$FZF_QUERY"
filename="$(echo "$*" | awk -F: '{print $1}')"
linenumber="$(echo "$*" | awk -F: '{print $2}')"
echo "$filename:$linenumber"

# cat "$filename" | head -n $((linenumber + 3)) | tail -n 6 | rg -C 3 --color=always "$searchterm" 
cat "$filename" | head -n $((linenumber + 20)) | tail -n 21 | rg -i --max-count 1 -A 20 --color=always "$searchterm" 
