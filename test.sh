#!/usr/bin/env bash

set -eu
# set -e # exit immediately on non-zero status of a command
# set -u # fail on undefined variables

readonly PROGNAME=$(basename $0)
readonly PROGDIR=$(readlink -m "$(dirname "$0")")
readonly ARGS="$@"

cd "$PROGDIR"
source "$PROGDIR/scripts/common.lib.sh"

TEST_INSTALL_DIR="/tmp/micro-tojour-test-installation-deleteme/"
PLUG_DIR="$PROGDIR"

rsync -q -av --delete "$PLUG_DIR/tojour.lua" "$TEST_INSTALL_DIR/" &&
rsync -q -av --delete "$PLUG_DIR/install.sh" "$TEST_INSTALL_DIR/" &&
rsync -q -av --delete "$PLUG_DIR/repo.json" "$TEST_INSTALL_DIR/" &&
rsync -q -av --delete "$PLUG_DIR/tojour.tutorial.md" "$TEST_INSTALL_DIR/" &&
rsync -q -av --delete "$PLUG_DIR/README.md" "$TEST_INSTALL_DIR/" &&
rsync -q -av --delete "$PLUG_DIR"/help/* "$TEST_INSTALL_DIR/help/" &&
rsync -q -av --delete "$PLUG_DIR"/scripts/*.{py,sh} "$TEST_INSTALL_DIR/scripts/" &&
rsync -q -av --delete "$PLUG_DIR"/src/*.lua "$TEST_INSTALL_DIR/src/" &&
rsync -q -av --delete "$PLUG_DIR"/syntax/*.yaml "$TEST_INSTALL_DIR/syntax/" &&
rsync -q -av --delete "$PLUG_DIR"/colorschemes/*.micro "$TEST_INSTALL_DIR/colorschemes/" &&
echo 'Copied to repo' || echo "Some error copying to repo"

cd "$TEST_INSTALL_DIR"
TEST_CONFIG_DIR="/tmp/micro-tojour-test-config-deleteme"

rm -rf "/tmp/micro-tojour-test-old-deleteme/" || :
mv "$TEST_CONFIG_DIR" "/tmp/micro-tojour-test-old-deleteme/" || :

./install.sh --config-dir "$TEST_CONFIG_DIR" --journal-dir "$TEST_CONFIG_DIR/plug/tojour/journals"

TOJOUR_DEVMODE=true "$TEST_CONFIG_DIR/tojour" "$TEST_CONFIG_DIR/tojour.tutorial.md" || Die "Error in installing test instance"
if [[ -f "/tmp/micro-tojour-test-result.log" ]]; then
    notify-send "$(cat "/tmp/micro-tojour-test-result.log")"
    echo "$(cat "/tmp/micro-tojour-test-result.log")"
    echo "SOME UNIT TEST FAILURES, check 'cat /tmp/luajournal.txt | grep FAILED'"
    exit 1
else 
    echo "All tests passed"
fi

rm -rf "$TEST_INSTALL_DIR"
