#!/usr/bin/env bash
#
# Greps all files for a searchstring, ordering by last modified date
# Pipes into FZF to return to micro: './filename.md:linenumber'

set -eu
# set -e # exit immediately on non-zero status of a command
# set -u # fail on undefined variables    

readonly PROGNAME=$(basename $0)
readonly PROGDIR=$(readlink -m $(dirname $0))

source "$PROGDIR/common.lib.sh"
isRgInstalledOrDie
isFzfInstalledOrDie

readonly previousQueryFile="/tmp/tojour.PrevFindQuery.log";
readonly previousPosFile="/tmp/tojour.PrevFindPos.log";
rememberPreviousFzfQueryAndPos

# rg -i --line-number --sortr=modified --trim '.' | rg -v '\- \[/\]' \
# rg '.' -i --line-number --sortr=modified --trim --block-buffered | rg --block-buffered -v '\- \[/\]' \
rg -v '\- \[/\]' -i --line-number --sortr=modified --trim --block-buffered \
| fzf \
--header='[ Ctrl-s: sort alpha | C-d: sort by new | C-e: end | C-g: top ]' \
--delimiter=':' \
--no-sort \
--ansi \
--query="$previousQuery" --prompt "Open file containing string: " \
--exact \
--layout=reverse --no-hscroll \
--with-nth=1,2,3.. --nth=1,3.. \
--preview="bash $PROGDIR/previewFileAtLine.sh {}" --preview-window=30%:wrap \
--bind 'ctrl-e:last' \
--bind 'ctrl-g:first' \
--bind 'tab:down' \
--bind 'shift-tab:up' \
--bind 'ctrl-s:reload(rg -i --line-number --trim --sort=path "." | rg -v "\- \[[/x]\]")' \
--bind 'ctrl-d:reload(rg -i --line-number --trim --sortr=modified "." | rg -v "\- \[[/x]\]")' \
--bind "ctrl-alt-f:unbind(load)+clear-query+first" \
--bind "esc:clear-query+cancel" \
--bind "change:execute-silent(bash $PROGDIR/$PROGNAME)" \
--bind "focus:execute-silent(bash $PROGDIR/$PROGNAME)" \
--bind "load:pos($previousPos)" \
| cut -d: -f1-2
# --bind "ctrl-r:become(fzf --delimiter=':' --no-sort --query='$previousQuery' --layout=reverse --no-hscroll  )" \

# ctrl-s / d: sort by name, date
# ctrl-r fuzzy match mode? Not great like this
