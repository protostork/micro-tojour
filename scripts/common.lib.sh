#!/bin/bash

isCommandAvailable() {
    command -v "$1" >/dev/null 2>&1 && return 0 || return 1
}

isFzfInstalledOrDie() {
  isCommandAvailable "fzf" || Die "fzf utility is not available, please install 'fzf'"
}

isRgInstalledOrDie() {
  isCommandAvailable "rg" || Die "rg utility is not available, please install 'ripgrep'"
}

# via https://github.com/martinburger/bash-common-helpers/blob/master/bash-common-helpers.sh
Error() (
	# echo -e "$@" > /dev/stderr
  # Output to stdout, so we can grab it in Lua instead of type Error? https://pkg.go.dev/github.com/zyedidia/micro/v2@v2.0.13/internal/shell#RunCommand
	echo -e " [Fatal error in $PROGNAME: $*]" 
)

Die() {
  Error "$@" 
  exit 99
}

function YesNo {
	export TERM=xterm-256color
	    while true; do
	    	local red=$(tput -T $TERM setaf 1)
			local reset=$(tput -T $TERM sgr0)
	        read -s -n 1 -p "$* ${red}[y/n]${reset}: 
" yn
	        case $yn in
	            [Yy]*) return 0  ;;  
	            [Nn]*) return  1 ;;
				"") return 0 ;;
	        esac
	    done
}

# If called by an FZF action, write the current query and position into temporary files
# Requires set $previousQueryFile & $previousPosFile defined in parentscript
# sets global variables $previousQuery & $previousPos
# e.g. to be used by fzf in --query="$previousQuery" and --bind "load:pos($previousPos)"
# NB: in such case ensure you unbind load if you want to use the reload() action, etc
rememberPreviousFzfQueryAndPos() {
	# If spawned by fzf --bind:change, $FZF_QUERY is set and then save current query to the log
	if [[ -n "${FZF_QUERY+isset}" ]] || [[ -n "${FZF_POS+isset}" ]]; then
		if [[ $(cat "$previousQueryFile") != "$FZF_QUERY" ]]; then
			# The fzf query has changed since last time
			echo -n "$FZF_QUERY" > "$previousQueryFile"
		fi
		if [[ $(cat "$previousPosFile") -ne "$FZF_POS" ]]; then
			# The fzf cursor position has changed since last save
			echo -n "$FZF_QUERY" > "$previousQueryFile"
		fi
		exit
	fi

	previousQuery=""
	if [[ -f "$previousQueryFile" ]]; then
		# was saved more than X minutes ago, therefore ignore it
		if [[ $(find "$previousQueryFile" -mmin +10) ]]; then
			rm "$previousQueryFile"
		else
			previousQuery="$(cat "$previousQueryFile")"
		fi 
	fi

	previousPos=""
	if [[ -f "$previousPosFile" ]]; then
		# was saved more than X minutes ago, therefore ignore it
		if [[ $(find "$previousPosFile" -mmin +10) ]]; then
			rm "$previousPosFile"
		else
			previousPos="$(cat "$previousPosFile")"
		fi
	fi
}