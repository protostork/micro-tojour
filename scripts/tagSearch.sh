#!/bin/bash

readonly PROGNAME=$(basename $0)
readonly PROGDIR=$(readlink -m "$(dirname "$0")")

source "$PROGDIR/common.lib.sh"
isRgInstalledOrDie
isFzfInstalledOrDie

prompt="Searching tags: "
searchquery=""
cacheLocation=false

while [ -n "$1" ]
do
  if [ "$1" = '--query' ]; then
    searchquery="$2"; shift; shift;
  elif [ "$1" = '--prompt' ]; then
    prompt=$2; shift; shift;
  elif [ "$1" = '--cache-file' ]; then
    cacheLocation=$2; shift; shift;
  else
    echo "Error: Unknown argument: $1"
    Help
  fi
done

# sorting options in ripgrep: created, modified, accessed, path
sortby=modified

# TODO: filter out css hex color codes like #[a-fA-F0-9]{6} - but will be hard not to catch false positives sometimes - six letter words from a-f? certainly: fedafa
# Get most recently 'used' tags
# rg --sortr=$sortby --no-line-number --no-filename --only-matching --replace '$1$2$3' '\[\[(\w[\w_\-\.\s]*\w)\]\]|[^\w/\(\)\[]#(\w[\w_\-\.]*\w)|^#(\w[\w_\-\.]*\w)' \

getAllTags() {
    CacheSave() {
        echo "$1" > "$cacheLocation"
        return
    }
    CacheFetch() {
      local cache_location="$1"
      if [[ "$cache_location" ]]; then  
        notify "We have a cachefile at $cache_location"
        if [[ -f "$cache_location" ]]; then
            cachedResults="$(cat "$cache_location")"
            # Output the cache immediately
            echo "$cachedResults"
        else
          local project_cache_dir=$(readlink -m "$(dirname "$cache_location")")
          mkdir -p "$project_cache_dir"
          notify "$project_cache_dir"
        fi
      fi
      return
    }
    CacheIsFresh() {
      diff <(echo -e "${1}") <(echo -e "${2}") > /dev/null && { 
          # notify "is fresh"; 
          return 0; 
        } || {
          # notify "cache and new are identical"
          return 1
      }
    }
    
    # Helper function - enable this to aid debugging
    notify() {
      # notify-send "$1"
      return
    }
    local cachedResults=""

    CacheFetch "$cacheLocation"

    local freshResults=""
    if ! freshResults="$(rg --sortr=$sortby --no-line-number --no-filename --only-matching --replace '$1$2$3' '\[\[(\w[\w_\-\.\s]*\w)\]\]|[^\w/\(\)\["]#(\w[\w_\-\.]*\w)|^#(\w[\w_\-\.]*\w)' \
      | tr '[:upper:]' '[:lower:]' \
      | awk '!seen[$0]++')"; then
      # In case we have killed the rg with the fzf --binds below, dont rewrite the cache
      return
    fi

    # cache is disabled, we're done here
    if ! [[ "$cacheLocation" ]]; then
      echo "$freshResults"
      return
    fi

    # if the files are identical, then quit
    # diff <(echo -e "$freshResults") <(echo -e "$cachedResults") > /dev/null && {
    CacheIsFresh "$freshResults" "$cachedResults" && {
        notify "cache and new are identical"
        return
    }

    notify "cache is different"
    local cache_linecount="$(echo "$cachedResults" | wc -l)"
    local fresh_linecount="$(echo "$freshResults" | wc -l)"
    if [[ "$fresh_linecount" -lt "$cache_linecount" ]]; then
        # new line count is lower than current, cache might be probably old
        notify "fresh has fewer lines than cache, refreshing with fresh"
        # just overwrite old cache with only fresh and bail
        CacheSave "$freshResults"
        return
    fi

    # fresh list is larger than old list or equal in length (but still difference)
    # only output the difference
    freshResults="$({ echo -n "$cachedResults" && echo "$freshResults"; } \
    | awk '!seen[$0]++')"
    notify "Final list without duplicates" "$freshResults"
    CacheSave "$freshResults"

    # output additional lines that were not in cache 
    echo "$freshResults"
}


# rg --sortr=$sortby --no-line-number --no-filename --only-matching --replace '$1$2$3' '\[\[(\w[\w_\-\.\s]*\w)\]\]|[^\w/\(\)\["]#(\w[\w_\-\.]*\w)|^#(\w[\w_\-\.]*\w)' \
# | tr '[:upper:]' '[:lower:]' \
# | awk '!seen[$0]++' \
# echo "$(getAllTags)" \
getAllTags \
| fzf --no-sort -i --prompt "$prompt" --query "$searchquery" --exact --print-query \
--bind="enter:replace-query+print-query+execute(killall --quiet rg)" \
--bind="tab:replace-query+print-query+execute(killall --quiet rg)" \
--bind="esc:hide-preview+execute(killall --quiet rg)+close" \
--bind=space:replace-query+print-query \
--preview-window=:wrap \
--preview="echo {} | xargs -I _ rg --sortr=$sortby -i --color=always '\[\[_\]\]|#_' | rg -v '\- \[[/xX]\]' 2> /dev/null" 

# --preview="sleep 5; echo 'hi'" 

# --bind "load:execute-silent(bash $PROGDIR/$PROGNAME)" \
