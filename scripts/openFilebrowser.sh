#!/bin/bash

readonly PROGNAME=$(basename $0)
readonly PROGDIR=$(readlink -m $(dirname $0))
readonly ARGS="$@"

fileBrowser="$1"

source "$PROGDIR/common.lib.sh"
isCommandAvailable "$fileBrowser" || Die "Fatal error: $fileBrowser utility is not available, please install '$fileBrowser'"

# Use this to configure nnn's editor invoked with 'e' key
# export EDITOR=/usr/bin/micro
# export VISUAL=/usr/bin/micro

if [ $fileBrowser = "nnn" ]; then
    # for some reason, paste and moving files doesn't work within micro
    # Can pipe to stderr otherwise it seems to choke: # /usr/bin/nnn -c > /dev/stderr
    # alternatively, '-p -' works even better: automatically echos file you press enter on to stdout (and seems to pipe GUI to somewhere else)
    # -H also shows hidden files
    # $(command -v nnn) -H -p - 
    # nnn -H -p -
    # nnn -p -
    # nnn -p /tmp/nnn-selected-file
    export EDITOR=/usr/bin/pico
    export VISUAL=/usr/bin/pico

    tempfile=$(mktemp "nnn-selected-file.XXXXXXX")
    # Pipe to stderr to stop garbage message from nnn polluting micro input
    nnn -H -p "$tempfile" > /dev/stderr 2>&1
    if [ -f "$tempfile" ]; then
        selectedFile="$(cat "$tempfile")"
        rm "$tempfile"
        if [ -f "$selectedFile" ]; then
            echo -n "$selectedFile"
        fi
    fi
else
    # TODO: Try out with ranger, Thunar, Nemo etc yet
    $(command -v $fileBrowser)
fi
