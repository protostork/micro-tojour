#!/usr/bin/env sh

set -e
# set -e # exit immediately on non-zero status of a command
# set -x # echo out all commands
# set -o pipefail # do not fail silently if piping erros
# readonly PROGDIR="$(readlink -m $(dirname $0))"
# source "$PROGDIR/common.lib.sh"
readonly PROGNAME=$(basename $0)

Help(){
    echo "Generates table of contents (TOC) from a file from its markdown heading tags"
    echo "Usage eg: $PROGNAME --line-number 5 filename.md"
    echo "Arguments: "
    echo "  --line-number n: mark a line number in the TOC (like current line number that cursor is on, but possibly need to add 2)"
    echo "  argument: filename"
    exit 1
}

# sleep 0.3

lineNumber=
fileToParse=
textToParse=
commentPrefix="<!--"
max_heading_level=3
# used by column --table below to truncate 
export COLUMNS=40
while [ -n "$1" ]
do
  if [ "$1" = '--line-number' ]; then
    lineNumber="$2"; shift; shift;
  elif [ "$1" = '--col-width' ]; then
    COLUMNS=$(($2 - 3)); shift; shift;
  elif [ "$1" = '--max-level' ]; then
    max_heading_level="$2"; shift; shift;
  elif [ "$1" = '--comment-prefix' ]; then
    commentPrefix="$2"; shift; shift;
  elif [ "$1" = '--text' ]; then
    textToParse="$2"; shift; shift;
  elif [ -f "$1" ]; then
    fileToParse="$1"; shift
  else
    echo "Error: Unknown argument: $1"
    Help
  fi
done

if [ -z "$fileToParse" ] && [ -z "$textToParse" ]; then
    echo "Error: Must provide a filename to use as base."
    Help
fi

# computed regex for awk https://www.gnu.org/software/gawk/manual/gawk.html#Computed-Regexps
comment_prefix_pat="^$commentPrefix"
column_separator="╡"


heading_pat="^[ \t]*#{1,${max_heading_level}}[ ]+"
if [ "$max_heading_level" -lt 6 ]; then
  filtered_heading_pat="^[ \t]*#{$((max_heading_level + 1)),6}[ ]+"
else
  filtered_heading_pat="NULULITULEUTLISEUTLIESTULIESTU"
fi

# If we only have mawk, like on raspi, then the awk below would fail so we do this simple grep-based toc which is also quite fast
command -v mawk > /dev/null && {
  # ( echo "$lineNumber:^^^^^^^^^^^^^^^^^^^^^^^^^^^"; grep -n '^\s*#\+\s' "$fileToParse" | sed -E 's#^([[:digit:]]+):\s*#\1:#g' ; ) \
  # | sort -h | sed -E 's#^[0-9]+:##g';
  # grep -n '^\s*#\+\s' "$fileToParse";
  grep '^\s*#\+\s' "$fileToParse";
  exit;
}

# awk -v cursor_linenum="1" -v comment_prefix="xzyzlkj" -v columns="40" -v column_separator="╡" -v heading_pat="^[ \t]*#{1,${max_heading_level}}[ ]+" -v filtered_heading_pat="nothinghere" '
# alas echo doesn't really work because it's very hard to pass a safe string without injections here via lua
# echo "$textToParse" | \
awk -v cursor_linenum="$lineNumber" -v comment_prefix="$comment_prefix_pat" -v columns="$COLUMNS" -v column_separator="$column_separator" -v heading_pat="$heading_pat" -v filtered_heading_pat="$filtered_heading_pat" '
BEGIN {
  hr="|-"; for(i=1; i<=columns - 20; i++) hr=hr"-"; hr=hr"╡---"
  # cursor="^"; for(i=1; i<=columns - 20; i++) cursor=cursor"^"; cursor=cursor"╡^^^"
  total_wordcount=0
  cursor_icon=">"
  filtered_heading_placeholder = ""
  in_yaml_md_frontmatter = 0
  # print hr
  # print "| Heading╡WC"
  # print hr
}
{
  if (NR == 1 && $0 == "---") {
    # Remove '---' markdown blocks from wordcount (if possible)
    in_yaml_md_frontmatter = 1
  }
  else if (NR > 1 && in_yaml_md_frontmatter == 1) {
    if ($0 == "---") {
      # found second matching --- after line 1, now stop uncounting wordcounts forever
      in_yaml_md_frontmatter = 0
    }
  }
  else if ($0 ~ heading_pat) {
    if (cursor_printed != 1 && NR > cursor_linenum - 1) {
      # print "[:" cursor_linenum - 1 "] ^^^^^^^^^^^^^^^^^^^^^^╡^^^"
      # print ":" cursor_linenum - 1 " " cursor
      # print cursor
      cursor_printed=1
      cursor_marker=cursor_icon
    } else {
      cursor_marker=" "
    }
    if (NR == 1) {
      prev_line = $0
      prev_linenum = NR
    } else {
      # remove all leading spaces and tabs from indented headings
      gsub(/^[\t\s]+/, "", $prev_line);
      print cursor_marker prev_line column_separator wordcount
      prev_line = $0
      prev_linenum = NR
      if (filtered_heading_placeholder != " ") {
        print filtered_heading_placeholder
        filtered_heading_placeholder = " "
      }
    }
    # Reset the wordcount on each heading
    wordcount = 0
  }
  else if ( $0 ~ filtered_heading_pat ) {
    filtered_heading_placeholder = filtered_heading_placeholder "."
  }
  else if (! ($0 ~ comment_prefix )) {
    # if we have a non-heading line that doesnt start with comment prefix, count the words on it
    wordcount += NF
    total_wordcount += NF
  }
}
END {
  # output the wordcount and title of the last found header
  cursor_marker=" "
  if (cursor_printed != 1 ) {
    # print cursor
    cursor_marker=cursor_icon
  }
  print cursor_marker prev_line column_separator wordcount
  if (filtered_heading_placeholder != "") {
    print filtered_heading_placeholder
    filtered_heading_placeholder = " "
  }
  print column_separator
  print hr
  print "| Total Wordcount" column_separator total_wordcount
  print hr
}' "$fileToParse" \
| column --separator="$column_separator" --output-width $COLUMNS --table-noheadings --table --table-columns heading,wordcount --table-truncate heading --table-right wordcount

# | sed -e 's#^\([a-zA-Z0-9]\)#  \1#g'  # Inserts a tab before the wrapped heading lines so it a hanging indent
# | sed 's#^[ \t]{2,}##g' \

# | tr -d '[:blank:]' \
# notify-send colwidth "$COLUMNS"

# | column -x --separator='|'
