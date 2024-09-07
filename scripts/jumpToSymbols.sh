#!/usr/bin/env bash

set -o pipefail

Help(){
    echo "Jump to a heading or other 'symbol' in a markdown file"
    echo "Usage eg: $PROGNAME --line-number 5 filename.md"
    echo "Arguments: "
    echo "  argument: filename"
    echo "  --line-number n: Optionally provide the current line number in the file"
    echo "  --next: Jump to next match after current line number"
    echo "  --previous: Jump to previous match before current line number"
    exit 1
}

lineNumber=0
direction=
symbols="^#"
text=""
# can supply the following also, to jump to all lines starting with #, %, .. or [comment]:
#symbols="^#|^% |^.. |^\\\\[comment\\\\]:"
while [ -n "$1" ]
do
  if [ "$1" == "--line-number" ]; then
    lineNumber="$2"; shift; shift;
  elif [ "$1" == "--symbols" ]; then
    symbols="$2"; shift; shift;
  elif [ "$1" == "--next" ]; then
    direction="next"; shift;
  elif [ "$1" == "--previous" ]; then
    direction="previous"; shift;
  elif [ "$1" == "--text" ]; then
    text="$2"; shift;
  elif [ -f "$1" ]; then
    fileToParse="$1"; shift
  else
    echo "Error: Unknown argument: $1"
    Help
  fi
done

# TODO: Allow defining commentprefix as CLI so it can be customised
# commentprefix="|^\\[comment\\]:|^%[[:space:]]|\\.\\."

# notify-send "bla" "$symbols"
# symbols="\\[comment\\]:"

# commentprefix=""

# Filter out 
# heading
# - [ ] 
# commentprefixes (as above, but needs escaping)
showAllLines() {
    ( cat "$fileToParse" | rg --line-number "^[[:space:]]*#|^[[:space:]]*\\-[[:space:]]\\[[[:space:]]\\]$commentprefix"; ) \
    | sed 's#:[[:space:]]*#\t#g' \
    | fzf --layout=reverse --exact --no-sort --prompt 'Jump to header or todo item in file: ' \
    | tr ':' '\n' \
    | tail -1 \
    | awk '{print $1}'
}

if [[ -z "$direction" ]]; then
    showAllLines
elif [[ "$direction" == "next" ]] || [[ "$direction" == "previous" ]]; then
    # Searches for next match of the supplied symbols parameter (careful, square brackets from shell need \\\\[ escaping like this)
    # but only FROM current line number + 1
    # awk -v linenum="$lineNumber" -v awksymbols="$symbols" '$1 ~ awksymbols{if(NR>linenum+1){print NR; exit}}' "$fileToParse"
    # matches="$(grep --line-number "$symbols" "$fileToParse" | cut -d: -f1)"
    matches="$(grep --line-number "$symbols" "$fileToParse" | cut -d: -f1)"
    # matches="$(echo "$text" | grep --line-number "$symbols" | cut -d: -f1)"
    # notify-send "lines" "$matches"
    ((lineNumber++))
    if [[ "$direction" == "next" ]]; then
        for linenum_of_match in $matches; do 
            if [[ "$linenum_of_match" -gt "$lineNumber" ]]; then
                echo "$linenum_of_match"
                exit
            fi
        done
    elif [[ "$direction" == "previous" ]]; then
        for linenum_of_match in $matches; do 
            if [[ "$linenum_of_match" -lt "$lineNumber" ]]; then
                found="$linenum_of_match"
                # notify-send "line" "$linenum_of_match"
            fi
        done
        echo "$found"
        exit
    fi
elif [[ "$direction" == "previous" ]]; then
    # before line number, look for regex
    awk -v linenum="$lineNumber" -v awksymbols="$symbols" '$1 ~ awksymbols && NR <= linenum {lastMatch = NR} END {print lastMatch}' "$fileToParse"
fi