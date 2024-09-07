#!/usr/bin/env bash

set -euo pipefail
# set -e # exit immediately on non-zero status of a command
# set -u # fail on undefined variables
# set -o pipefail # do not fail silently if piping erros

readonly PROGNAME=$(basename $0)
readonly PROGDIR=$(readlink -m $(dirname $0))
readonly ARGS="$@"


source "$PROGDIR/common.lib.sh"
isCommandAvailable "xclip" || Die "xclip utility not available, please install 'xclip'"

compressImage="false"
isCommandAvailable "convert" && compressImage="true"
if [ "$compressImage" = "true" ]; then
    isCommandAvailable "convert" || Die "'convert' utility not available, please install 'imagemagick'"
fi

if [ $# -ne 1 ]; then
    Die "Usage: $PROGNAME <currentJournalFile>"
fi
currentJournalFile="$1"

whichImageFormatIsSmallest() {
    convert $1.png $1.webp > /dev/null 2>&1 || Die "Failed to convert image to webp"

    if [ $(stat -c%s "$1.png") -lt $(stat -c%s "$1.webp") ]; then
        echo -n "png"
    else
        echo -n "webp"
    fi
}

tmpFile=$(mktemp /tmp/$(basename $0).XXXXXX)

xclip -selection clipboard -t image/png -o > "$tmpFile.png" || { rm "$tmpFile.png"; Die "Failed to paste image from clipboard"; }

if [ "$compressImage" = "true" ]; then
    smallestFormat=$(whichImageFormatIsSmallest "$tmpFile")
else
    smallestFormat="png"
fi
timestampmicrotime=$(date +'%Hh%Mm%Ss_%N')
outputImagefile="${currentJournalFile}_${timestampmicrotime}.${smallestFormat}"

mv "${tmpFile}.${smallestFormat}" $outputImagefile || Die "Failed to move $outputImagefile to journal directory"
rm "$tmpFile"* || Die "Failed to remove temporary files"

# This is the file that can be pasted by Lua into micro
echo -n "$outputImagefile" ;
