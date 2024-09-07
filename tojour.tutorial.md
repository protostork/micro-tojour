# Tojour Tutorial: Diving right in

Hi! Welcome to the basic tutorial that should explain some of the stuff you can do in [tojour](https://github.com/protostork/micro-tojour/). 

If you're on board, why don't you mark the following undone todo item as done. You can either move your cursor down over the line and press `Alt-c` (or if you're into the mouse, you can right-click or hold down the `Alt` key and click or tap).

- [ ] Commit to completing this 10-minute tojour tutorial @today

## Preliminaries

But briefly, first things first: we will assume you've installed the tojour plugin and its dependencies). If not, please look at the help (`Ctrl-e` and type 'help tojour') or just run the file [your_micro_config_dir]/plug/tojour/install.sh to set this up. 

To take over the default hotkeys from the tutorial, press `Ctrl-e` in micro and enter this command: 'tojour.setupbindings', or to potentially overwrite your custom keybindings, 'tojour.setupbindingsforce' (don't worry, it will make a backup of your existing keyboard shortcuts).

## Managing Todos

Now hit `Alt-u` to open the Undone side pane. There you can see all undone todo items in this file (and also in other files, if you tag a todo item there with the #tojour.tutorial tag - but more on that later)

You can make a new todo item out of any line in a markdown file by pressing `Alt-c`.

**Note**: Once we get to the section on [Daily files](#daily-files) below, some of the below will hopefully make even more sense. 

### Scheduling and snoozing todos

Please read and then mark each of the below todo item as done (`Alt-c`) once you feel you're ready to move on.
- [ ] If you need to do something today, you can just type the word @today, starting with @ (or you can hit `Alt-z`). That will push it towards the top of the Undone side pane, for example. 
- [ ] Hit `Alt-z` again to postpone the due date by one day into the future, like @tomorrow (you can use `Alt-shift-Z` to unsnooze it again by one day). 
- [ ] Hit `Ctrl-Alt-z` to snooze due dates by one week into the far future each time (so if you press it enough times, you could end up with a date tag like this: @2038-01-19)

**Tip**: If you create such a future date in a daily file, when that date actually comes around (i.e., it is actually 'tomorrow' or 2038-01-19 or later) those due tags should automatically change to @today and appear near the top.

### Tracking good habits every day

Having things to do every day is great and all but sometimes there are things you want to remember to do every day, without having to recreate a new todo item every day. 

You can simply make any todo item a daily recurring one by adding the @habit tag, like this:

- [ ] Every morning, write in my tojour diary for one minute @habit

Mark this as done. If you did this in a **Daily file**, then the following day the todo item would re-appear and be marked as undone again.

## Daily files

Which finally brings us to the **Daily files**, which can be at the heart of tojour (if you want). The idea is that every day, tojour will generate a file for you, like `2012-12-31.md`, for example, and this Daily file could contain:

- your diary, 
- any random thoughts for a day, on any topic, that you want to be able to find later,
- lots of sloppily collected todo items (both done and undone), 
- some habits you would like to knock on the head every day.

### Creating your first Today file

Hit `Alt-d` to create a Today file and add a new todo item and maybe a new habit there. Come back to this tutorial once done (the `Alt-d` shortcut will take you back, or you can click on tojour.tutorial.md in the tab bar).

Whenever the clock strikes midnight and a new day has come, press `Alt-d` again and this will create a new Today file.

Daily files can do some of the following useful things:

- Every new day, the most recent previous Daily file's undone items are copied to the new Today file, 
- Any todos marked @habit from the previous day are marked undone again and are added near the top of the file
- Undone item marked with @tomorrow or a future date like @2038-01-19 get marked as @today in the new Today's file (if it is in fact tomorrow or the correct date), and puts it to the top of the new todo pile.
- Undone todo items in older daily files are marked as postponed, like this:
	- [/] this is a 'postponed' todo item, which was not finished a previous day and has been copied to a today file.

## Organising your ideas

### Headings + Table of contents view

Now press `Alt-o` to get the Table Of Content (TOC) sidepanel for this file, which shows you all the markdown headings in the currently opened file.

You can switch to any sidepane with `Alt-q`, and from there directly jump to a heading with `Alt-f` to follow anything. If you like the mouse, you can also right-click or Alt-left-click or tap on any heading in this sidepane.

**Pro-tip**: You can filter out higher heading levels by pressing `Alt-Shift-o` several times (or `Alt-o` to increase the visible header level again).

#### Navigating by headings

Press `Alt-o` to see all Markdown headings at once, and fuzzy search for the one you want. 

You can also jump between headings one by one in the main body:

Alt-[ and Alt-] : navigate to the next and previous markdown heading
Alt-{ and Alt-} : navigate to the next heading, markdown comment or #hashtag 

**Pro-tip**: Exactly where this jumps to in each case is customisable in settings.json with a regex. Please check the README.md for more info.

### Tagging or categorising content

Tags are just hashtagged words, like #hashtag, or [[categoryname]], which means you can find the line that contains the tag more easily later. 
	Any lines indented more deeply under your tag by tabs (like this one), will also get linked to this tag.
		This one too will inherit all parent paragraphs' tags.

Tags are also hyperlinks: press `Alt-f` while the cursor is on a tag. For example, this #hashtag will take you to the file hashtag.md (or you will get asked to create it), from where you can find other files that contain this tag.

**Tip**: You can also follow most links with Right-click or holding down Alt on the keyboard while tapping your touchpad.

#### Exercise: Tagging in action

- [ ] Create the file [hashtag.md], and add (something like) this line: "Hello #tojour.tutorial world! Consider yourself tagged."
	
Return to this tab afterwards (hotkeys `Alt-comma` or `Alt-period` can be used to change tabs also).

#### Tags Info Side Pane

When you opened up this [tojour.tutorial.md] file, a sidepane should have opened up automatically on the right.

This is called the Info side pane, which gives you context about the use of this #tojour.tutorial tag, which you're currently on (you can call this up any time with `Alt-i`).

The Info side pane provides references to all other markdown files and the lines that use this tag, anywhere (except on done todo items). 

## Navigating between files

`Ctrl-p` opens up a fuzzy search dialog that shows all open tabs and all files in the current directory and beneath.

## Finished. Done. Happy days!

You should now know enough tojour to get cracking. 

Some time in future, once you feel comfortable, do check back here, there are a few more poweruser-y functions explained below. 

## More Poweruser stuff

### Default Keyboard Shortcuts

Activate all of these and then some hotkey keybindings (at the risk of overwriting your defaults) with the Ctrl-E command `tojour.setuphotkeys`

#### Editing
- Alt-1 to Alt-6 : Toggle markdown heading level
- Alt-t / Alt-shift-t : insert timestamp / datestamp
- Alt-z : mark as due @today or snooze by one day
- Alt-shift-z : unsnooze by one day
- Ctrl-Alt-z : snooze by 7 days
- Ctrl-/ : Comment a line
- Alt-m : mark block selection from markdown heading, paragraph or indentation

#### Navigating
- Ctrl-o : fuzzy jump to markdown headings and todo items in the current file
- Ctrl-p : fuzzy open a file / switch to existing gtab
- Alt-d : go to today file / toggle back
- Alt-shift-d : Open files from the last 7 days (and tomorrow)
- Alt-f : follow a tag or link under the cursor
- Alt-e : open file editor (nnn by default)

#### Finding
- Ctrl-alt-f : fuzzy-search all files in your current working directory
- Alt-u,i,o : open sidepanes for undone, tags info and table of contents
- Alt-a : browse all tags

#### Movement:
- Alt-j, k, l, h : Move cursor like in vim. Additionally hold Shift to select text, and Ctrl to jump by word (or page up and down)
- Alt-], Alt-[ : Jump to next / previous markdown heading
- Alt-}, Alt-{ : Jump to next / previous specified markdown tags

### Markdown line comments

Press Ctrl-/ to quickly comment a markdown line. In some [flavours of markdown](https://stackoverflow.com/questions/4823468/comments-in-markdown) (pandoc's markdown and mmd for instance) this will be classified as a comment:

[comment]: TODO: syntax highlighting install. And pandoc brief intro.

But you can also use traditional <!-- comments --> or redefine it the `tojour.mdcommentprefix` config.

Do also make sure you've installed the markdown-journal.yaml syntax highlighter, so it looks the part.

#### Pandoc 

If you want to convert your markdown file to something more graphical, [pandoc](https://pandoc.org/) understands comments like this with something like these arguments: 

`pandoc --from=markdown_mmd+smart+autolink_bare_uris+task_lists+yaml_metadata_block+hard_line_breaks+lists_without_preceding_blankline --to=html5 --embed-resource --standalone --metadata pagetitle="$filename" --toc -o "$outputfile.html" "$filename"`

### Selecting header & indent blocks with alt-m

Move your mouse up to a markdown header and press `Alt-m`. It will select all text and lower-level headers beneath it, and you can now cut and paste it wherever you need it. This also works with indented lines.

### Paste images with Ctrl-v

You can paste images from the clipboard with `Ctrl-v`, which will get saved next to your markdown file, and you can open so-embedded image links with `Alt-f`. If you install `imagemagick`, this will compress the PNG images further into formats like webp, if there is a space saving.

### Colourschemes, syntax & prettification

Slightly more advanced markdown syntax highlighting is included in [MICRO_CONFIG_DIR/plug/tojour/syntax/markdown-journal.yaml]. You should copy this to your micro config directory (~/.config/micro/syntax/ by default) if you want this kick in. 

There are also two dark colourschemes that are tweaked for some of those markdown syntax rules and that might (or might not) be pleasing to you:

- [MICRO_CONFIG_DIR/plug/tojour/colorschemes/tojour-default.micro]
- [MICRO_CONFIG_DIRplug/tojour/colorschemes/tojour-neon.micro]

Activate it by typing in micro's `Ctrl-e` command mode: `set colorscheme tojour-default`

Also, make sure you get and set up a nice terminal font that has support for italics, underlines, NerdFonts and more. [Cascadia Mono NF](https://github.com/microsoft/cascadia-code/) is quite pretty, for example.

If you're a heavy user of tojour's indentation, the micro version with the `wrapindent` option from [this pull request](https://github.com/zyedidia/micro/pull/3107) is worth compiling so indentation looks a bit more readable (thanks @ [Neko-Box-Coder](https://github.com/Neko-Box-Coder)).

### Quality of life tweaks

Adding these to settings.json (or adding via micro's `Ctrl-e` command and typing `set softwrap on`) can improve your daily quality of tojour life (YMMV):

- "indentchar": "◦", 
- "autoindent": true,
- "savecursor": true,
- "keepautoindent": true,
- "softwrap": true,
- "wordwrap": true,
- "tabstospaces": false,
- "reload": true,

### File manager

If you have `nnn` or another Terminal file browser installed (or potentially some graphical ones too), press `Alt-e` to start this up and work with your filesystem.

### Helpful plugins

There are lots of amazing micro plugins by amazing developers, but these are especially helpful when working with markdown files:

- `plugin install quoter` (allows easy-insertion of surrounding quote marks)
- `plugin install manipulator` (easily turn text to lowercase, uppercase, etc)
- `plugin install palettero` (gives acces to a customisable command palette)

Also useful via [Neko-Box-Coder's unofficial plugin channel](https://github.com/Neko-Box-Coder/unofficial-plugin-channel):
- [MicroOmni](https://github.com/Neko-Box-Coder/MicroOmni) (useful navigation shortcuts, copy current file path & more)

### Link to your micro config dynamically from markdown

Start a link with the magic string MICRO_CONFIG_DIR, which tojour will point to your ~/.config/micro directory (or wherever your instance is installed). E.g., use it for quick access to micro's bindings or settings:

- [MICRO_CONFIG_DIR/bindings.json]
- [MICRO_CONFIG_DIR/settings.json]

## Delete this tutorial (and other files)

Hope that wasn't too horrible. If you're done and want to delete the tutorial (or any other file in your current working directory), it's pretty simple. Press `Ctrl-p`, type tojour.tutorial (or just select this file in the list), then hit `Ctrl-x`.

Goodbye, thanks for persevering until the end. If you have any feedback, please open up an issue on [github](https://github.com/protostork/micro-tojour/)