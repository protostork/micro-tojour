# tojour: Daily journalling, todo and habit tracker IDE for micro

[Tojour](https://github.com/protostork/micro-tojour/) is a daily journalling and self-organisation plugin for the [micro](https://micro-editor.github.io/) text editor. 

Tojour aims to be a fast and low-friction way to keep a daily digital bullet-like journal, manage todo lists, track habits and write short, medium and long-form content and documentation, seamlessly across one (or thousands) of portable markdown files, with low mental (and CPU) overheads. 

Think of it as a super-fast and slightly smart digital diary for people who like using the keyboard. If you're a coder, you might like to think of it as a baby IDE for your markdown files, or a lightly-opinionated and simple-minded Emacs Orgmode for people who think Markdown is beautiful and that getting organised should be uncomplicated.

## Demo

![DemoDiary](https://github.com/user-attachments/assets/17ccbd1b-cc4a-42c2-87d9-b7f65db4a47f)

## Quickstart

### Installation (Linux)

Paste this into your terminal and follow the instructions: 

`cd /tmp && git clone https://github.com/protostork/micro-tojour && cd micro-tojour && bash ./install.sh`

Once complete, if you want to dive right in, say yes to the tutorial option, which will open [MICRO_CONFIG_DIR/plug/tojour/tojour.tutorial.md]

Fuller [manual installation instructions below](#installation--requirements).

### Syntax

Broadly tojour likes a [Github-style Markdown](https://github.github.com/gfm/) syntax, with a few additional semantical flavourings:

- `[[taggedwords]]` or, alternatively, #taggedwords, can be used to categorise ideas and to link files to each other.
- todo items on lines leading with `- [ ]` or `TODO`; completed items are marked with `- [x]` or `DONE`
- @today or @tomorrow or @2038-01-19 to schedule tasks; @habit to mark a task as recurring daily.

### Ultra-rapid crashcourse

If you'd rather get stuck right in than go through the [tutorial](MICRO_CONFIG_DIR/plug/tojour/tojour.tutorial.md), here's a very tiny run-through of some of tojour's main hotkeys that can should get you productive. 

Open any md file in micro, then try the following, in order and observe what happens: press `Alt-d` (confirming creation of a new file with 'y'), type 'Hello World!', hit `Alt-c` to create todo item, `Alt-u` to see undones, `Alt-z` to snooze, `Alt-c` again to mark it done, type 'Title 1', `Alt-1`, hit Enter, type 'Title 2', `Alt-2`, then `Alt-o` to see headings, `Alt-q`, and move to a heading with the cursor and press `Alt-f` to follow that heading.

That's a good chunk of it! If you're interested in more in-depth tutorial of advanced features, do check out the [Features](#features) below, or [MICRO_CONFIG_DIR/plug/tojour/tojour.tutorial.md]

## Features

- *Common syntaxes* for journaling, todo and habit tracking, scheduling tasks, personal information management and retrieval combining flavoured Markdown with Wikipedia style quick linking and some sprinklings of Orgmode.
- *Todo items* anywhere instantly by starting a line with `- [ ]` or by pressing `Alt-c`. Mark it as done (`- [x]`) with the same hotkey or by mouse right- or alt-left-clicking (or if you prefer, you can type out `TODO` near the start of a line, which the hotkey marks as `DONE`)
- *Schedule and snooze* todos anytime with `Alt-z`, `Alt-Shift-z` and `Ctrl-Alt-z` or strings like @monday, @tomorrow or @2038-01-19
- *Habit tracking*: Just add @habit to any todo item and it will recur every day.
- *Tagging*: Use #hashtag or [[hashtag]] anywhere as catogories for knowledge, to tag ideas and to link to your notes like in Wikipedia. This creates a cross-reference with other files also using that tag, that you can see with `Alt-i`. You also get an autocomplete when you start entering a tag. Press `Alt-f` to 'follow' a tag.
- *Indentation* makes it easy to organise information hierarchically: any lines that are indented more deeply than the previous line (either tabs or spaces), will 'inherit' the previous lines(s) tag.
- *Find files* with SublimeText / VSCode-style `Ctrl-p` project and file browser, and an interactive 'find text in all files' tool with `Ctrl-Alt-f`
- *Customise*: Almost all hotkeys and many default configs can be changed.
- *Link* to any local files, pdfs, images or websites directly from any markdown file, like this: [~/.config/micro/settings.json].
- *Navigate markdown* files and tags with ease, jumping between markdown headers and user-configurable tags with `Ctrl-o` (inspired by the [micro-jump](https://github.com/terokarvinen/micro-jump) plugin, and next and previous headers and more with `Alt-[`, `Alt-]`, `Alt-{` and `Alt-}`
- *Follow links* with `Alt-f` (or mouse right-click or Alt-click). You can do this with #hashtags, [[hashtags]], urls, links to files on your computer, [heading anchors](#features), [:10] line numbers in the current file or line numbers in other files #tojour.tutorial:10, for instance, and more...
- *Compatibility*: tojour's core are simple plain daily markdown files with names like 2024-12-31.md (or self-managed naming and directory structures if you would like to use those).
- *Vim-like cursor movement* with `Alt-j`, `k`, `l` and `h`, plus more h, j, k, l movements when also holding down `Shift` or `Ctrl`.
- *Paste images* from the clipboard directly into a markdown file with Ctrl-v.
- *Wordcounts* calculated between each heading in the TOC / `Alt-o` view. Count all words in your current document any time with `Alt-w` and track how many words you've written in the current session; reset the wordcount in a session with `Alt-shift-w`
- *Automatic admin*: your daily journal files are automagically re-populated and tidied every day, copying last day's undone items to today
- *Helpful side-panes* that show your undone todos `Alt-u` in relation to the current file, cross referenced tags `Alt-i` and a navigable table of content with wordcounts `Alt-o` of your current document.
- *Markdown goodies* like configurable line comments `Ctrl-/`, advanced markdown syntax highlighting, header and indentation aware block selections `Alt-m`, advanced file management with nnn.

## Plugin-specific options

* `tojour.setupbindings`: Force setting tojour's basic opinionated hotkeys (potentially overwriting some of your existing shortcuts, though it will make a backup of your bindings.json)
  
* `tojour.imageviewer`: will use this executable to open embedded markdown image links, ending in .png, .webp, .jpg, etc. Just use the name of an executable without a path, that can be run from the command line. Examples: `feh`, `nsxiv`, `nomacs`, `gimp`, `viu`. If empty, will use `xdg-open` to call default associated app.

    default value: `` 

* `tojour.filebrowser`: a filebrowser (command line or graphical) to allow quickly browsing and modifying the file system. `nnn` is recommended and configured to allow opening files back in micro by pressing enter.

    default value: `nnn` 
    
* `tojour.mdcommentprefix`: the string to prefix in front of a line of markdown comments. If running the [comment plugin](https://github.com/micro-editor/comment-plugin), maybe define this keybinding, binding 'Ctrl-/ (slash)' with `"CtrlUnderscore": "lua:tojour.cmdInsertLineComment|lua:comment.comment"` - this keeps the default comment functionality in all files except markdown files

    default value: `[comment]:`

### Expert plugin options

Please note: Here Be Dragons. Don't mess with these or the other many undocumented options unless you broadly know what you're doing. Some of these may break things and even cause data loss if you're too adventurous and experimental (see [disclaimer](#licence-disclaimer) below).  

* `tojour.alwaysopencontextpane`: Specify true or 'toc', 'index' or 'undone' to automatically open that kind of sidepane when opening a markdown file for the first time

	default value: `false`
	
* `tojour.alwaysopentodayundone`: Whether the undone items sidepane should be always be opened when in a today file for the first time

	default value: `true`

* `tojour.potatomode`: Disables many of the real-time sidepane updates and auto-completes that may be quite slow on slower Raspberry Pis or older Android / Termux phones (you can still update the sidepane when you save)

	default value: `false`

* `tojour.symbolsforjump`: takes a regular expression to describe what you would like `Alt-[` and `Alt-]` to skip between (next and previous markdown headers by default)

    default value: `^*#{1,6} .+`

* `tojour.symbolsforjump`: more granular jumping with `Alt-{` and `Alt-}` to skip to an alternative set of symbols by regex. By default this jumps to the next #hashtag,[[category]] or [link]

    default value: `"#[A-Za-z0-9\\.$~/_-]+[A-Za-z0-9]|\\[\\[?[a-zA-Z0-9\\.$~/_\\s-]+[A-Za-z0-9]\\]?\\]|\\[[+-]{2}]"`

* `tojour.buildscript`: an external build or script to invoke manually by hotkey (`Alt-b` by default), or automatically when starting a new today file (if enabled). `todobuddy.py` does some cool stuff under the hood to make tojour's daily files and todo management work, but you can write your own or add actions you want taken like committing your journals to git before running it, uploading them somewhere, etc. Make sure you replace " .. helper_script_path .. " with an absolute location to a file, if you are changing the config.

	default value: `{ command -v git > /dev/null; } && git rev-parse 2> /dev/null && { cd $(git rev-parse --show-toplevel) && git add . && git commit -m 'pre-build autocommit' ; }; python " .. helper_script_path .. "/todobuddy.py --today --write;`
	alternative value: `python ~/.config/micro/plug/tojour/scripts/todobuddy.py --today --write`

* `tojour.autobuildtoday`: automatically call the build script defined in `journal.autobuildtoday` when opening a new empty today file via the ctrl-p hotkey. Examples: can be used to do an automatic git commit regularly, rsync backups or syncs, run some seds and awks, or with todobuddy.py to automatically populate a new today file with yesterday's undone items or habits and to process tags, or to add boilerplate text to a new today file.

    default value: `true`
    
## Installation / Requirements

### Linux / Android Termux (automatic install)

Download this repository and run `install.sh`, then follow instructions to semi-automatically install the plugin (and micro, if required), or copy and paste this one-liner into your terminal:

`cd /tmp && git clone https://github.com/protostork/micro-tojour && cd micro-tojour && bash ./install.sh`

This should make it all work On Ubuntu and other Debian-derived, Arch-like systems and Android's Termux, this should be all you need to do.

### Manual installation

Copy this repository to ~/.config/micro/plugs/tojour and then install the plugin with `micro -plugin install tojour`

#### Dependencies

Besides the standard bash and POSIX-type utilities like find, awk, sed, etc, make sure you have the following external command line utilities / software installed to make this work: 

- fzf
- ripgrep / rg
- fd (fdfind)
- python
- bash
- xclip (optional, to paste images on Linux but probably not on Wayland)
- imagemagick (optional, to paste images)
- nnn (optional, to browse filesystem)

#### Windows / Mac / *BSDs, etc

I haven't been able to try this out, but Micro might run natively on MacOS and most likely on on Windows, at the very least via WSL (but both will likely need may need some adjustments), and via the various BSD flavours.

If someone can get it to work, please do post an issue and/or a pull request for this README.

## Default tojour keybindings

You can force restore these any time (and make a backup of your old bindings, in case any hotkeys clash), with the micro `Ctrl-e` command `tojour.setupbinding`.

- "Alt-,": "PreviousTab",
- "Alt--": "lua:tojour.cmdSidepaneResizeDown",
- "Alt-.": "NextTab",
- "Alt-1": "lua:tojour.cmdInsertHeader1",
- "Alt-2": "lua:tojour.cmdInsertHeader2",
- "Alt-3": "lua:tojour.cmdInsertHeader3",
- "Alt-4": "lua:tojour.cmdInsertHeader4",
- "Alt-5": "lua:tojour.cmdInsertHeader5",
- "Alt-6": "lua:tojour.cmdInsertHeader6",
- "Alt-=": "lua:tojour.cmdSidepaneResizeUp",
- "Alt-CtrlH": "WordLeft",
- "Alt-CtrlL": "WordRight",
- "Alt-Ctrlj": "MoveLinesDown",
- "Alt-Ctrlk": "MoveLinesUp",
- "Alt-D": "lua:tojour.cmdBrowseDateJournals",
- "Alt-H": "SelectLeft",
- "Alt-J": "SelectDown",
- "Alt-K": "SelectUp",
- "Alt-L": "SelectRight",
- "Alt-MouseLeft": "MousePress,lua:tojour.cmdHandleMouseEvent",
- "Alt-O": "lua:tojour.cmdTOCDecrement",
- "Alt-T": "lua:tojour.cmdInsertDateTimestamp",
- "Alt-W": "lua:tojour.cmdResetGlobalWordcounts",
- "Alt-Z": "lua:tojour.cmdDecrementDaystring",
- "Alt-[": "lua:tojour.cmdJumpToPrevSymbol",
- "Alt-]": "lua:tojour.cmdJumpToNextSymbol",
- "Alt-a": "lua:tojour.cmdJumpToTag",
- "Alt-b": "lua:tojour.cmdRunBuildScript",
- "Alt-c": "lua:tojour.cmdToggleCheckbox",
- "Alt-d": "lua:tojour.cmdOpenTodayFile",
- "Alt-e": "lua:tojour.cmdRunFilebrowser",
- "Alt-f": "lua:tojour.cmdFollowInternalLink",
- "Alt-h": "CursorLeft",
- "Alt-i": "lua:tojour.cmdToggleSidePaneIndex",
- "Alt-j": "CursorDown",
- "Alt-k": "CursorUp",
- "Alt-l": "CursorRight",
- "Alt-m": "lua:tojour.cmdSelectBlock",
- "Alt-o": "lua:tojour.cmdToggleSidePaneTOC",
- "Alt-q": "NextSplit",
- "Alt-Q": "lua:tojour.cmdCloseSidePane",
- "Alt-t": "lua:tojour.cmdInsertTimestamp",
- "Alt-u": "lua:tojour.cmdToggleSidePaneUndone",
- "Alt-w": "lua:tojour.cmdWordcount",
- "Alt-z": "lua:tojour.cmdIncrementDaystring",
- "Alt-{": "lua:tojour.cmdJumpToPrevAltSymbol",
- "Alt-}": "lua:tojour.cmdJumpToNextAltSymbol",
- "Ctrl-Alt-F": "lua:tojour.cmdFindTextInAllFiles",
- "Ctrl-Alt-z": "lua:tojour.cmdIncrementDaystringByWeek",
- "Ctrl-o": "lua:tojour.cmdJumpToSymbols",
- "Ctrl-p": "lua:tojour.cmdBrowseOpenTabsAndJournals",
- "Ctrl-v": "lua:tojour.cmdSmarterPaste",
- "CtrlUnderscore": "lua:tojour.cmdInsertLineComment|lua:comment.comment",
- "MouseRight": "MousePress,lua:tojour.cmdHandleMouseEvent",
- "Tab": "IndentSelection|lua:tojour.cmdPressTabAnywhereToIndent|Autocomplete"

# Contributing

If you discover any bugs or feature requests, please open up an issue. 

If you would like to contribute, bugfix or add features, that too would be forevermore appreciated.

## Development

Tojour is an unholy Unix-y fusion of Lua, shell and Python scripts that has organically evolved into this abomination over several years. You can just edit the source `tojour.lua` file, as in any other micro plugin, and begin hacking to your liking. Or even better, submit an issue and or pull request if you are adding features, configs, etc.

Note that a lot of the utility shell scripts, which all live in the plugin's `scripts` directory, are used for some of the interactive functions or where the performance of tools like find or ripgrep leaves even Lua in the dust and can run in a background subshell, so you can keep doing other stuff while it crunches the strings. Some of the main scripts are:

- `todobuddy.py`: searches and presents tags in all documents (the 'index' sidepane), and creates daily files from previous days' files.
- `generateTOC.sh`: generates a table of contents for the TOC sidepane, from a provided file's markdown headers (with option to highlight the current line-number / cursor).
- `collectUndonesFromFile.sh`: pulls undone todos out of the current file and also dated todos out of other files in the current journal for the 'undone' sidepane.
- `pasteImage.sh`: copies an image pasted into micro from the clipboard into a file.

### Testing 

A rudimentary unit test suite for the plugin to test for a few regressions can be triggered by starting micro like this:

`TOJOUR_DEVMODE=true micro`

This will also write a lot of very chatty debugging noise into /tmp/luajournal.txt, which can be triggered with the devlog() function in tojour.lua. With the included `test.sh` script, you can also install a temporary clean version of micro in some /tmp/ sub-directories and automatically run the main tests.

## Roadmap / works in progress

Currently on the cards, though with no strict deadline, are:

- [ ] Allow renaming/refactoring tags, categories and accompanying filenames across all files in your journal
- [ ] Project session management and restoration on restart
- [ ] Interactive Pandoc export support
- [ ] General UX and workflow improvements
- [ ] Bug and performance tweaks and fixes

If you have other suggestions, please do open up an issue in the [repo](https://github.com/protostork/micro-tojour/issues).

## Licence & Disclaimer

This project is released under an open source MIT licence for free and comes without any warranties or the like. 

Be aware that *this is also beta software*, so catastrophic data loss is, while unlikely, always a possibility: **please make backups of any of your valuable journal files regularly**!

## FAQs

### Why another writing / note taking / diary / todo list / habit tracker application?

I have been using tojour in various more or less primitive versions for a while and especially coupled with micro it has been really useful to me as a daily driver and discipline in its own right, so I thought perhaps others might enjoy it too. 

### But also why else?

In the search for the perfect daily digital diary system I have tried out and abandoned many tools over the years, usually for a variety of curmudgeonly reasons (some might have insisted on eating 500-1000MB of RAM or were a bit sluggish, or couldn't be operated entirely by keyboard, or forced me to repeat myself once too often, or were too verbose in syntax, or not customisable or portable enough, not open source, or, sometimes, they may have just looked at me funny).

But fortunately, despite my flightiness, using plaintext or markdown diary files has always meant that migration between software and even organisational paradigms has been pretty painless.

After spending some time with micro and its plugin ecosystem, I found it ticked nearly all of my boxes. Thanks to [zyedidia](https://github.com/zyedidia) and the community it is an amazing default editor, with saner default UX, insaner customisability and blindingly faster performance than most. Thanks mostly to micro (and the help of tools like grep, rg, fd and fzf), it has been zippy on my ageing laptop (and slower but useable on Android [Termux](https://termux.dev/) with an external keyboard or on a Raspberry Pi Zero 2). 

Once you sync your journal folder with something like [syncthing](https://syncthing.net/), it gives you ready access your journals and writings on nearly any device. 

### Similar software

Tojour is inspired by / has liberally magpied the philosophies and workflow of several tools and plugins and is customisable to where it could theoretically emulate some of their (or your own) syntaxes or idiosyncrasies. Do check these out, there is a lot of amazing software here:

- Hierarchical / indented note-taking from [Workflowy](https://workflowy.com), [Notion](https://www.notion.so/) and the venerable MS Word Outline View.
- Tagging and categorisation from software like [Obsidian](http://obsidian.md/) and [LogSeq](https://github.com/logseq/logseq/releases/), 
- Daily todo management from [Todo.txt](https://github.com/todotxt/todo.txt) and [Emacs Org-mode](https://orgmode.org/), 
- Long form writing and organisation from [Scrivener](https://www.literatureandlatte.com/scrivener/overview) and [NovelWriter](https://novelwriter.io/)
- Syntaxes from Markdown and Mediawiki

Several VSCode plugins also share similarities and ideas:
- org-checkbox https://marketplace.visualstudio.com/items?itemName=publicus.org-checkbox
- Markdown Memo https://open-vsx.org/vscode/item?itemName=svsool.markdown-memo
- MarkDown To-Do https://github.com/TomasHubelbauer/vscode-markdown-todo
- Dendron https://www.dendron.so

### Tojour is slow on my Potato SOC

Micro is very fast and tojour wants to be too and on most laptops and Android phones it is generally fine. However, on very low-powered devices (aka potatoes) some of the bells and whistles like real-time updates of sidepanes and indexes that regularly call greps, ripgreps or fdfinds may slow your cursor down. If you are finding things a bit sluggish, try these options from within micro: `set tojour.potatomode true` and/or `set tojour.alwaysopencontextpane false` and `set tojour.alwaysopentodayundone false`.

If there's interest, there may be some ways to speed things up more for small devices. 

### Why the name tojour?

Tojour is an un/happy mashup of the words *todo* and the French words *jour* (meaning day) and *toujours* (meaning always).

