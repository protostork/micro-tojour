#!/usr/bin/env bash

set -eu
# set -e # exit immediately on non-zero status of a command
# set -u # fail on undefined variables

readonly PROGNAME=$(basename $0)
readonly PROGDIR=$(readlink -m "$(dirname "$0")")
readonly ARGS="$@"

cd "$PROGDIR"
source "$PROGDIR/scripts/common.lib.sh"

TEST_INSTALL_DIR="/tmp/micro-tojour-test-installation-deleteme"
rm -rf "$TEST_INSTALL_DIR" > /dev/null
mkdir -p "$TEST_INSTALL_DIR" > /dev/null
PLUG_DIR="$PROGDIR"

# Only copy files that are in git
for gitfile in $(git ls-files); do
  mkdir -p "$(realpath --relative-to=. "$(dirname "$TEST_INSTALL_DIR/$gitfile")")" > /dev/null
  cp "$gitfile" "$TEST_INSTALL_DIR/$gitfile"
done
# tree -a "$TEST_INSTALL_DIR"

cd "$TEST_INSTALL_DIR"
CONFIG_DEPLOY_DIR="/tmp/micro-tojour-test-deploy-deleteme"

# Make backup of old config
rm -rf "/tmp/micro-tojour-test-old-deleteme/" > /dev/null || :
mv "$CONFIG_DEPLOY_DIR" "/tmp/micro-tojour-test-old-deleteme/" > /dev/null || :
journalDir="$CONFIG_DEPLOY_DIR/plug/tojour/journals"

./install.sh --config-dir "$CONFIG_DEPLOY_DIR" --journal-dir "$journalDir"

TOJOUR_DEVMODE=true "$CONFIG_DEPLOY_DIR/tojour" "$CONFIG_DEPLOY_DIR/tojour.tutorial.md" || Die "Error in installing test instance"
if [[ -f "/tmp/micro-tojour-test-result.log" ]]; then
    notify-send "$(cat "/tmp/micro-tojour-test-result.log")"
    echo "$(cat "/tmp/micro-tojour-test-result.log")"
    echo "SOME UNIT TEST FAILURES, check 'cat /tmp/luajournal.txt | grep FAILED'"
    exit 1
else 
    echo "All tests passed"
fi
