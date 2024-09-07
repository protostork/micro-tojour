#!/bin/bash

# used to open new or existing journal files by day or filename with fzf

set -eu
# set -e # exit immediately on non-zero status of a command
# set -u # fail on undefined variables

readonly PROGNAME=$(basename "$0")
readonly PROGDIR=$(readlink -m "$(dirname "$0")")

source "$PROGDIR/common.lib.sh"
isRgInstalledOrDie
isFzfInstalledOrDie

readonly previousQueryFile="/tmp/tojour.PrevBrowseJournal.log";
readonly previousPosFile="/tmp/tojour.PrevBrowsePos.log";
# rememberPreviousFzfQueryAndPos

if [[ -n "$*" ]]; then
    prepend_lines="$(echo "$*")"
    # a regex we can grep -E -v with to hide tab-open files
    prepend_lines_regex="$(echo "$prepend_lines" | sed 's#,#|#g')"
    # adds the '|' symbol after every 'newline'
    # NB: Also needs to be configured in tojour.lua (2x), previewFileWithTags.sh, and here
    # Add an \n at the end so we can echo -n and pass an empty file too without an empty line
    prepend_lines_with_tabs="$(echo "000 | $prepend_lines" | sed 's#,#\n000 | #g')
"
    # prepend_lines_with_tabs="$(echo "$prepend_lines")"
    # notify-send "$prepend_lines_regex"
else
    # E.g. a null file is currently open (i.e. no tabs) or other stuff is going on
    prepend_lines=""
    prepend_lines_regex="^$"
    prepend_lines_with_tabs=""
fi

# notify-send "$(pwd)"

# --nth=2 \
# --delimiter='>' \
# { echo "$prepend_lines_with_tabs" | tr ',' '\n'; find . -not -path '*/.*' -type f -printf '%T@ %p\n' | sort -k1,1r | cut -d' ' -f2- | grep -E -v "$prepend_lines_regex" & } \
# { echo -n "$prepend_lines_with_tabs"; find . -not -path '*/.*' -type f -printf '%T@ %p\n' | sort -k1,1r | cut -d' ' -f2- | grep -E -v "$prepend_lines_regex" & } \
# { echo -n "$prepend_lines_with_tabs"; find . -not -path '*/.*' -type f -printf '%T@ %p\n' | sort -k1,1r | grep -E -v "$prepend_lines_regex" & } \
# Tried speeding this up for android with fzf nth etc and some xargs in preview
# Each line is prepended with timestamp 1234.12414212etc filename.md
# NB: If you change this regex, also change it below in --bind c-x and c-p
{ echo -n "$prepend_lines_with_tabs"; find . -not -path '*/.*' -type f -printf '%T@ %p\n' | grep --line-buffered -E -v "$prepend_lines_regex" | sort -k1,1r & } \
| fzf --ansi --exact --print-query \
--query="" \
--preview-window=60%:wrap --preview="echo {} | sed 's#^[0-9\.|]\+ ##g' | xargs bash \"$PROGDIR/previewFileWithTags.sh\"" \
--layout=reverse \
--no-sort \
--with-nth=2.. --nth=1.. \
--header='[ Sort: C-s: alpha, C-d: created | C-x: delete | C-e: end | C-g: top ]' \
--bind "enter:unbind(change)+replace-query+print-query" \
--bind "esc:clear-query+cancel" \
--bind 'ctrl-e:last' \
--bind 'tab:down' \
--bind 'shift-tab:up' \
--bind 'ctrl-g:first' \
--bind "ctrl-x:execute(clear; rm -i \"\$(echo {} | sed 's#^[0-9\.|]\+ ##g')\";)+reload-sync(echo -n \"$prepend_lines_with_tabs\"; find . -not -path '*/.*' -type f -printf '%T@ %p\n' | grep -E -v \"$prepend_lines_regex\" | sort -k1,1r )" \
--bind "ctrl-y:execute(echo {} | sed 's#^[0-9\.| ]\+ ##g' | xclip -sel clip && notify-send 'Copied to clipboard')" \
--bind "ctrl-s:reload(find . -not -path '*/.*' -type f -printf '%p\n' | sort | sed 's#^#000 #g')" \
--bind "ctrl-d:reload(echo -n \"$prepend_lines_with_tabs\"; find . -not -path '*/.*' -type f -printf '%T@ %p\n' | grep -E -v \"$prepend_lines_regex\" | sort -k1,1r)" \
--bind "ctrl-p:unbind(load)+clear-query+first+reload-sync(rm $previousQueryFile $previousPosFile; echo -n \"$prepend_lines_with_tabs\"; find . -not -path '*/.*' -type f -printf '%T@ %p\n' | grep -E -v \"$prepend_lines_regex\" | sort -k1,1r )" \

# TODO: yank: --bind "ctrl-y:execute(bash -c \"echo {} | xclip;\")" \
# TODO: close tab ctrl-w (could be a bit tough?)
# --bind "ctrl-y:execute(bash -c \"notify-send 'got' {}\")" \

# --query="$previousQuery" \
# --bind "change:execute-silent(bash $PROGDIR/$PROGNAME)" \
# --bind "focus:execute-silent(bash $PROGDIR/$PROGNAME)" \
# --bind "load:pos(1)"
