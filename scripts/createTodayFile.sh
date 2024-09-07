#!/usr/bin/env sh

set -eo pipefail
# set -e # exit immediately on non-zero status of a command
# set -x # echo out all commands
# set -o pipefail # do not fail silently if piping erros
# readonly PROGDIR="$(readlink -m $(dirname $0))"
# source "$PROGDIR/common.lib.sh"
readonly PROGNAME=$(basename $0)

Help(){
    echo "Generates a today file named YYYY-MM-DD.md, copying all undone items from previous files with this name"
    echo "Usage eg: $PROGNAME"
    echo "Arguments: "
    echo "  TODO: None"
    exit 1
}

# ALL_TODO_ITEMS="$(rg '^[ \t]*\- \[ \]' .)"
ALL_TODO_ITEMS_FROM_DAILIES="$(rg '^[ \t]*\- \[ \]' --glob "[0-9][0-9][0-9][0-9]-[0-9][0-9]-[0-9][0-9].md")"
# ALL_TODO_ITEMS_FROM_OTHER_FILES="$(rg '^[ \t]*\- \[ \].*@[0-9][0-9][0-9][0-9]' --glob "![0-9][0-9][0-9][0-9]-[0-9][0-9]-[0-9][0-9].md")"
ALL_TODO_ITEMS_FROM_OTHER_FILES="$(rg '^[ \t]*\- \[ \].*(@[0-9][0-9][0-9][0-9]-[0-9][0-9]-[0-9][0-9]|@today|@tomorrow)' --glob "![0-9][0-9][0-9][0-9]-[0-9][0-9]-[0-9][0-9].md")"
# ALL_TODO_ITEMS_FROM_OTHER_FILES="$(rg '@today')"

echo "$ALL_TODO_ITEMS_FROM_DAILIES"
echo "===================="
echo "$ALL_TODO_ITEMS_FROM_OTHER_FILES"

# Problem with 'create' is, we can't / shouldn't really PULL this out of other files 
# unless we write into other file and mark a todo with a date as - [ ] xyz


# --glob "!${FILE_TO_PARSE}"

# lineNumber=
# fileToParse=
# while [ -n "$1" ]
# do
#   if [ "$1"  == "--line-number" ]; then
#     lineNumber="$2"; shift; shift;
#   elif [ -f "$1" ]; then
#     fileToParse="$1"; shift
#   else
#     Error "Error: Unknown argument: $1"
#     Help
#   fi
# done

# if [ -z "$fileToParse" ]; then
#     echo "Error: Must provide a filename to use as base."
#     Help
# fi
