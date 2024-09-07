#!/usr/bin/env bash

set -e
# set -e # exit immediately on non-zero status of a command

readonly PROGNAME=$(basename $0)
readonly PROGDIR=$(readlink -m "$(dirname "$0")")
readonly ARGS="$@"

readonly DEFAULT_CONFIG_DIR="$HOME/.config/micro"
MICRO_EXEC="$(command -v micro)"

cd "$PROGDIR"
source "$PROGDIR/scripts/common.lib.sh"

Help() {
    echo "Installs micro-tojour in a custom config directory. Run interactively, unless you specify both arguments."
    echo "Optional arguments:"
    echo "--config-dir DIRECTORY: specify a custom config dir to install into"
    echo "--journal-dir DIRECTORY: specify a custom dir to store your journal files"
}

NON_INTERACTIVE_MODE=""
ARG_JOURNAL_DIR=""
ARG_CONFIG_DIR=""

while [ -n "$1" ]
do
  if [ "$1" = '--config-dir' ]; then
    ARG_CONFIG_DIR="$2"; shift; shift;
  elif [ "$1" = '--journal-dir' ]; then
    ARG_JOURNAL_DIR="$2"; shift; shift;
  else
    echo "Error: Unknown argument: $1"
    Help
    Die
  fi
done

# Don't ask YesNo questions anymore but just install it since both args provided
if [[ -n "$ARG_CONFIG_DIR" ]] && [[ -n "$ARG_JOURNAL_DIR" ]]; then
    NON_INTERACTIVE_MODE="true"
fi

checkDependencies() {

    isCommandAvailable "fd" || { isCommandAvailable "fdfind" && echo "Creating symlink from fdfind to /usr/bin/fd" && sudo ln -s "$(command -v fdfind)" /usr/bin/fd; }
    
    ( isCommandAvailable "micro" && isCommandAvailable "fzf" &&  isCommandAvailable "rg" &&  isCommandAvailable "fd" ) || { 
        echo "You appear to be missing some dependencies before you can run tojour.";
        
        local notinstalled=""
        isCommandAvailable "micro" || notinstalled+="micro "
        isCommandAvailable "rg" || notinstalled+="ripgrep "
        isCommandAvailable "fzf" || notinstalled+="fzf "
        isCommandAvailable "fd" || notinstalled+="fd "

        if [[ -n "$notinstalled" ]]; then
            if [[ -n "$TERMUX_VERSION" ]]; then
                YesNo "Install with: 'pkg update && pkg install $notinstalled'?" && {
                    pkg update && pkg install $notinstalled
                } || Die "Aborted: Missing $notinstalled dependencies"
            elif cat /etc/os-release | grep -q '^ID.*arch$'; then
                YesNo "Install with: 'sudo pacman -Syu $notinstalled'?" && {
                    sudo pacman -Syu $notinstalled
                } || Die "Aborted: Missing $notinstalled dependencies"
            elif cat /etc/os-release | grep -iq '^ID.*debian\|ubuntu$'; then
                # in debian the fd package is called fd-find
                notinstalled=${notinstalled//fd /fd-find }
                YesNo "Install with: 'sudo apt install $notinstalled'?" && {
                    sudo apt update && sudo apt install $notinstalled
                } || Die "Aborted: Missing $notinstalled dependencies"
            else
                echo "Please install these packages in your distro, before proceeding: $notinstalled"
                Die "Aborted: Missing $notinstalled dependencies"
            fi
        fi
        isCommandAvailable "fd" || { isCommandAvailable "fdfind" && sudo ln -s "$(command -v fdfind)" /usr/bin/fd; }
    }
}

chooseConfigInstance() {
    echo
    echo "Where do you want to set up tojour?"
    echo "1. $DEFAULT_CONFIG_DIR (default micro configuration; backups of settings will be made)"
    echo "2. $HOME/.config/micro-tojour (can be useful to keep a separate editor settings, tailor made for journalling)"
    # echo "3. I want to tell you where to install it (not yet implemented)"
    echo "q. I've changed my mind and want to quit"

    while true; do
        local red=$(tput -T $TERM setaf 1)
        local reset=$(tput -T $TERM sgr0)
        read -s -n 1 -p "Enter ${red}[1/2/q]${reset}: 
" yn
        case $yn in
            [1]*) setConfigDir "$DEFAULT_CONFIG_DIR"; break ;;  
            [2]*) setConfigDir "$HOME/.config/micro-tojour"; break ;;
            [q]*) echo "Install aborted"; exit 0 ;;
            "") echo "Install aborted"; exit 0 ;;
        esac
    done

    return 0
}

setConfigDir() {
    if [[ "$DEFAULT_CONFIG_DIR" == "$1" ]]; then
        CONFIG_DIR="$DEFAULT_CONFIG_DIR"
    else
        CONFIG_DIR="$1"; 
        MICRO_EXEC="$MICRO_EXEC --config-dir $CONFIG_DIR";
    fi

    if [[ -f "$CONFIG_DIR/settings.json" ]]; then
        cp "$CONFIG_DIR/settings.json" "$CONFIG_DIR/settings.tojour-install.json"
        echo "* Backed up $CONFIG_DIR/settings.tojour-install.json"
    fi
    if [[ -f "$CONFIG_DIR/bindings.json" ]]; then
        cp "$CONFIG_DIR/bindings.json" "$CONFIG_DIR/bindings.tojour-install.json"
        echo "* Backed up $CONFIG_DIR/bindings.tojour-install.json"
    fi

    JOURNAL_PLUGIN_DIR="$CONFIG_DIR/plug/tojour"
}

createNewConfigInstance() {
    if [[ -z "$CONFIG_DIR" ]]; then
        Die "No config dir specified, aborting install."
    fi

    echo "* Setting up config instance..."
    if [[ ! -d "$JOURNAL_PLUGIN_DIR" ]]; then
        mkdir -p "$JOURNAL_PLUGIN_DIR"
    fi
    cp -dr ./* "$JOURNAL_PLUGIN_DIR/"

    # add sample settings.json file if none exists?
    # if [ ! -f "$CONFIG_DIR/settings.json" ]; then
        # cp "$PROGDIR/settings.json" "$CONFIG_DIR/settings.json"
        # echo
    # fi

    echo "✔ Installed standalone journal config to $CONFIG_DIR"

    echo "* Activating plugin..."
    $MICRO_EXEC -plugin list | grep -q ^tojour && {
        echo "✔ (Plugin was already activated)"
    } || {
        $MICRO_EXEC -plugin install tojour
        echo "✔ Plugin activated..."
    }

    echo "* Copying colourschemes to $CONFIG_DIR/colorschemes"
    mkdir -p "$CONFIG_DIR/colorschemes" || :
    cp ./colorschemes/*.micro "$CONFIG_DIR/colorschemes/"
    
    echo "* Copying advanced markdown syntax highlighting to $CONFIG_DIR/syntax"
    mkdir -p "$CONFIG_DIR/syntax" || :
    cp "./syntax/markdown-journal.yaml" "$CONFIG_DIR/syntax/"

    # TODO: Install markdown-journal.yaml somehow
}

chooseJournalDocsDir() {
    local documents_dir="$HOME/Documents"
    if [[ $(command -v xdg-user-dir) ]]; then
        documents_dir="$(xdg-user-dir DOCUMENTS)"
    fi
    
    echo
    echo "Where do you want to keep your journal files?"
    echo "1. $documents_dir/journal (recommended)"
    echo "2. $documents_dir/tojour"
    echo "3. $JOURNAL_PLUGIN_DIR/journal (use only for testing: if you uninstall the plugin you might lose all your journals)"
    # echo "3. I want to tell you where to install it (warning, not implemented)"
    echo "4. Don't create a journal folder, I've got something of my own"
    echo "q. I've changed my mind completely and want to quit"


    while true; do
        local red=$(tput -T $TERM setaf 1)
        local reset=$(tput -T $TERM sgr0)
        read -s -n 1 -p "Enter ${red}[1/2/3/4/q]${reset}: 
" yn
        case $yn in
            [1]*) setJournalDir "$documents_dir/journal"; break ;;
            [2]*) setJournalDir "$documents_dir/tojour"; break ;;  
            [3]*) setJournalDir "$JOURNAL_PLUGIN_DIR/journal"; break ;;
            [4]*) setJournalDir ""; break ;;
            [q]*) echo "Install aborted"; exit 0 ;;
            "") echo "Install aborted"; exit 0 ;;
        esac
    done

    return 0
}

setJournalDir() {
    JOURNAL_FILES_DIR="$1"
    if [[ -n "$JOURNAL_FILES_DIR" ]]; then
        echo "✔ Will use $JOURNAL_FILES_DIR to store your journal files..."; 
        test -d "$JOURNAL_FILES_DIR" || mkdir -p "$JOURNAL_FILES_DIR"; 
        MICRO_EXEC="cd \"$JOURNAL_FILES_DIR\" && $MICRO_EXEC"
    fi
    TUTORIAL_SRC="$JOURNAL_PLUGIN_DIR/tojour.tutorial.md"
}

# create open-micro-journal bash file
createNewMicrojournalExecutable() {
    echo "* Creating tojour shortcut to new config..."
    touch "$TOJOUR_SHORTCUT"
    chmod +x "$TOJOUR_SHORTCUT"

    echo '#!/bin/bash' > "$TOJOUR_SHORTCUT" && \
    # echo 'LC_ALL="en_US.utf8"' >> "$TOJOUR_SHORTCUT" && \
    echo 'export EDITOR=micro' >> "$TOJOUR_SHORTCUT" && \
    echo 'todaysFile="$(date +'%Y-%m-%d').md"' >> "$TOJOUR_SHORTCUT" && \
    echo "$MICRO_EXEC \$* \"\$todaysFile\"" >> "$TOJOUR_SHORTCUT" && \
    echo "✔ Created tojour shortcut: $TOJOUR_SHORTCUT" \
    && echo "You can now run micro tojour at any time with: " \
    && echo "    $TOJOUR_SHORTCUT" \
    || echo "Warning: could not create tojour shortcut"
}

install() {
    echo "This script will try to install and setup the tojour journalling plugin for micro (including any dependencies you might require)"
    if [[ -z "$NON_INTERACTIVE_MODE" ]]; then
        YesNo "Do you want to continue?" || { echo "Install aborted by user."; exit 0; }
    fi
    checkDependencies

    if [[ -z "$ARG_CONFIG_DIR" ]]; then
        chooseConfigInstance
    else
        setConfigDir "$ARG_CONFIG_DIR"
        echo "Installing into custom config dir: $ARG_CONFIG_DIR"
    fi
    echo

    createNewConfigInstance

    ## TODO: Ask to install some recommended plugins?

    if [[ -z "$ARG_JOURNAL_DIR" ]]; then
        chooseJournalDocsDir 
    else
        setJournalDir "$ARG_JOURNAL_DIR"
        echo "Installing into custom journal dir: $ARG_JOURNAL_DIR"
    fi
    echo

    TOJOUR_SHORTCUT="$CONFIG_DIR/tojour"

    if [[ -n "$JOURNAL_FILES_DIR" ]]; then 
        createNewMicrojournalExecutable
        echo
        if [[ -z "$NON_INTERACTIVE_MODE" ]]; then
            YesNo "Copy and try the 5-minute tojour.tutorial.md?" && {
                cp "$TUTORIAL_SRC" "$JOURNAL_FILES_DIR/"; 
                $TOJOUR_SHORTCUT "$JOURNAL_FILES_DIR/tojour.tutorial.md"; 
            } 
        else
            cp "$TUTORIAL_SRC" "$JOURNAL_FILES_DIR/"; 
        fi
        echo "Tip: You can check out the tutorial any time with:" 
        echo "    $TOJOUR_SHORTCUT $JOURNAL_FILES_DIR/tojour.tutorial.md"
    else
        YesNo "Do you want to try the 5-minute tojour.tutorial.md?" && eval $MICRO_EXEC "$TUTORIAL_SRC"
        echo "Tip: You can start tojour and the tutorial again at any time with:" 
        echo "    $MICRO_EXEC $TUTORIAL_SRC"
    fi

    echo
    echo "Thanks for installing tojour!"
    echo "Hope you have focus and fun, and do leave feedback, suggestions, bugs and stars in the project repo."
}

install