#!/bin/bash

readonly PROGNAME=$(basename $0)
readonly PROGDIR=$(readlink -m "$(dirname "$0")")

source "$PROGDIR/common.lib.sh"
isRgInstalledOrDie
isFzfInstalledOrDie

prompt="Searching tags: "
term=""
if [ -n "$1" ]; then
    prompt="$1"
fi

if [ -n "$2" ]; then
    term="$2"
fi

# sorting options in ripgrep: created, modified, accessed, path
sortby=modified

# TODO: filter out css hex color codes like #[a-fA-F0-9]{6} - but will be hard not to catch false positives sometimes - six letter words from a-f? certainly: fedafa
# Get most recently 'used' tags
# rg --sortr=$sortby --no-line-number --no-filename --only-matching --replace '$1$2$3' '\[\[(\w[\w_\-\.\s]*\w)\]\]|[^\w/\(\)\[]#(\w[\w_\-\.]*\w)|^#(\w[\w_\-\.]*\w)' \
rg --sortr=$sortby --no-line-number --no-filename --only-matching --replace '$1$2$3' '\[\[(\w[\w_\-\.\s]*\w)\]\]|[^\w/\(\)\["]#(\w[\w_\-\.]*\w)|^#(\w[\w_\-\.]*\w)' \
| tr '[:upper:]' '[:lower:]' \
| awk '!seen[$0]++' \
| fzf --no-sort -i --prompt "$prompt" --query "$term" --exact --print-query \
--bind=enter:replace-query+print-query \
--bind=tab:replace-query+print-query \
--bind=space:replace-query+print-query \
--preview-window=:wrap \
--preview="echo {} | xargs -I _ rg --sortr=$sortby -i --color=always '\[\[_\]\]|#_' | rg -v '\- \[[/xX]\]' 2> /dev/null" 
