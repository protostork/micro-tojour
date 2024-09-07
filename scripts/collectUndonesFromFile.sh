#!/usr/bin/env bash

readonly PROGDIR="$(readlink -m "$(dirname "$0")")"
source "$PROGDIR/common.lib.sh"
function Help(){
    echo "Usage: "
    echo "  --filter-by-tag tagname: optionally fetch all occurrences of tagname in undone items in all files elsewhere"
    Die
}

# sleep 0.5

FILTER_BY_TAG=
FILE_TO_PARSE=
while [ -n "$1" ]
do
  if [ "$1"  == "--filter-by-tag" ]; then
    FILTER_BY_TAG="$2"; shift; shift;
  elif [ -f "$1" ]; then
    FILE_TO_PARSE="$1"; shift
  else
    Error "Unknown argument: $1"
    Help
  fi
done

if [ -z "$FILE_TO_PARSE" ]; then
    Error "Must provide a filename to use as base to find undone items."
    Help
fi

# Returns day of the week in lowercase
function getFutureDayOfWeek(){
    if [ -z "$1" ]; then
        return 
    fi
    date -d "+ $1 day" +"%A" | tr '[:upper:]' '[:lower:]'
}

# Returns date in format 2024-01-01 (etc)
function getFutureCalDateISO(){
    if [ -z "$1" ]; then
        return 
    fi
    date -d "+ $1 day" +"%Y-%m-%d"
}

todayDay="$(getFutureDayOfWeek 0)"
todayDate="$(getFutureCalDateISO 0)"

tomorrowDay="$(getFutureDayOfWeek 1)"
tomorrowDate="$(getFutureCalDateISO 1)"

day2="$(getFutureDayOfWeek 2)"
date2="$(getFutureCalDateISO 2)"

TODO_REGEX="^[ \t]*((?:\- \[ \] |TODO).*)"

# ALL_TODO_ITEMS="$(rg "$TODO_REGEX" "$FILE_TO_PARSE")"
# only show captured group
ALL_TODO_ITEMS="$(rg -or '$1' "$TODO_REGEX$" "$FILE_TO_PARSE")"
# If we are parsing a simple daily file, also search for other todos in non-daily files (since all daily should hopefully be empty of todos)
if [[ "$FILE_TO_PARSE" =~ ^[0-9][0-9][0-9][0-9]-[0-9][0-9]-[0-9][0-9]\.md$ ]]; then
    # DATED_ITEMS_ELSEWHERE="$(rg '^[ \t]*\- \[ \].*(@[0-9][0-9][0-9][0-9]-[0-9][0-9]-[0-9][0-9]|@today|@tomorrow)' --glob "![0-9][0-9][0-9][0-9]-[0-9][0-9]-[0-9][0-9].md" .)"
    DATED_ITEMS_ELSEWHERE="$(rg -i "$TODO_REGEX(@[0-9][0-9][0-9][0-9]-[0-9][0-9]-[0-9][0-9]|@(?:today|tomorrow|monday|tuesday|wednesday|thursday|friday|saturday|sunday))" --line-number --glob "![0-9][0-9][0-9][0-9]-[0-9][0-9]-[0-9][0-9].md" . \
    | sed -E 's/^(\.\/)?([^ ]+)\.md:([0-9]+):(.*)$/\4 <via: [\2:\3] > /g' \
    )"
    ALL_TODO_ITEMS="$DATED_ITEMS_ELSEWHERE
$ALL_TODO_ITEMS"
fi

# If we're also looking for a tag in ALL the files, add them to the list
# TODO: And also make it work in the PWD of the root of the project ?!
# in a daily file, this searches for a tag like #2024-08-28
if [ -n "$FILTER_BY_TAG" ]; then
    # --glob ! excludes the tagfilename from first search (since later search grabs that)
    # are searching for todos by tagname, so this gets all undone items containing the current tag in all files
    # the sed puts the file name at the end without leading ./ and trailing .md, plus linenumer, e.g [filename:14]
    # ugh, complex to add this -|^[ \t*-]*TODO
    fileNameNoDir=$(basename $FILE_TO_PARSE)
    taggedTodos="$(rg "$TODO_REGEX(#${FILTER_BY_TAG}|\[\[${FILTER_BY_TAG}\]\])" --line-number --glob "!${fileNameNoDir}" . \
    | sed -E 's/^(\.\/)?([^ ]+)\.md:([0-9]+):(.*)$/\4 <via: [\2:\3] > /g' \
    )"
    ALL_TODO_ITEMS="$taggedTodos
$ALL_TODO_ITEMS"
fi

declare -A todos

function addline() {
    local index=$1
    if [[ -z "${todos["$index"]}" ]]; then
        todos["$index"]="
## ${index}
"
    fi
    todos["$index"]+="$2
"
}

while IFS= read -r line
do
    if [[ $line == *@* ]]; then
        if [[ $line == *@habit* ]]; then
            addline "Habits" "$line"
        elif [[ $line =~ @today|$todayDay|$todayDate ]]; then
            addline "Due today" "$line"
        elif [[ $line =~ @tomorrow|$tomorrowDay|$tomorrowDate ]]; then
            addline "Due tomorrow" "$line"
        elif [[ $line =~ $day2|$date2 ]]; then
            addline "Day after tomorrow" "$line"
        else
            addline "Other dated items" "$line"
        fi
    else
        addline "Undated items" "$line"
    fi
done <<< "$ALL_TODO_ITEMS"

echo -n "${todos["Habits"]}"
echo -n "${todos["Due today"]}"
echo -n "${todos["Due tomorrow"]}"
echo -n "${todos["Day after tomorrow"]}"
echo -n "${todos["Other dated items"]}" | sort -t@ -k2 # sort other dated items in order of @numerical-datestring at least
echo -n "${todos["Undated items"]}"
