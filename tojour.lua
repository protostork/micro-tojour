VERSION = "1.0.4"
--
-- Copyright (c) 2024, released under MIT licence
--

local micro = import("micro")
local util = import("micro/util")
local shell = import("micro/shell")
local config = import("micro/config")
local buffer = import("micro/buffer")
local strings = import("strings")
local filepath = import("path/filepath")

local fmt = import("fmt")
package.path = fmt.Sprintf("%s;%s/plug/tojour/src/?.lua", package.path, config.ConfigDir)

local Common = require("Common")
local FileLink = require("FileLink")
local TJPanes = require("TJPanes")
local TJConfig = require("TJConfig")
local TJSession = require("TJSession")
local SidepaneContent = require("SidepaneContent")

--
-- Local config constants
--
function init()
    config.AddRuntimeFile("tojour", config.RTHelp, "help/tojour.md")
    -- TODO: None of these runtime loaders work (or if they do, like Colorschemes, they are not available from launch)
    -- config.AddRuntimeFile("tojour", config.RTColorscheme, "colorschemes/tojour-neon.micro")
    -- config.AddRuntimeFile("tojour", config.RTColorscheme, "colorschemes/tojour-default.micro")
    -- config.AddRuntimeFile("tojour", config.RTSyntax, "syntax/markdown-journal.yaml")

    -- regex that we can jump to directly with hotkeys on cmdJumpToNextSymbol and cmdJumpToNextAltSymbol (and Prev)
    config.RegisterCommonOption("tojour", "symbolsforjump", "^*#{1,6} .+")
    config.RegisterCommonOption(
        "tojour",
        "symbolsforaltjump",
        "#[A-Za-z0-9\\.$~/_-]+[A-Za-z0-9]|\\[\\[?[a-zA-Z0-9\\.$~/_\\s-]+[A-Za-z0-9]\\]?\\]|\\[[+-]{2}]"
    )

    config.MakeCommand("tojour.setupbindings", cmdSetupTojour, config.NoComplete)
    config.MakeCommand("tojour.setupbindingsforce", cmdSetupTojourForce, config.NoComplete)

    config.MakeCommand("wordcountreset", cmdResetGlobalWordcounts, config.NoComplete)

    TJConfig.HOME_DIR = tostring(os.getenv("HOME"))
    TJConfig.PLUGIN_PATH = config.ConfigDir .. "/plug/tojour"
    TJConfig.HELPER_SCRIPT_PATH = config.ConfigDir .. "/plug/tojour/scripts"

    -- use @today, @habit, @tomorrow to denote recurring, current and future todo items
    config.RegisterCommonOption("tojour", "dateprefix", "@")
    config.RegisterCommonOption("tojour", "todaystring", "today")
    config.RegisterCommonOption("tojour", "tomorrowstring", "tomorrow")
    config.RegisterCommonOption("tojour", "habitstring", "habit")
    -- '@' by default prefix to denote dates
    TJConfig.date_prefix = tostring(config.GetGlobalOption("tojour.dateprefix"))
    -- '@today' by default (prefixed with default date_prefix)
    TJConfig.today_string = TJConfig.date_prefix .. tostring(config.GetGlobalOption("tojour.todaystring"))
    -- '@tomorrow' by default (prefixed with default date_prefix)
    TJConfig.tomorrow_string = TJConfig.date_prefix .. tostring(config.GetGlobalOption("tojour.tomorrowstring"))
    -- '@habit' by default (prefixed with default date_prefix)
    TJConfig.habit_string = TJConfig.date_prefix .. tostring(config.GetGlobalOption("tojour.habitstring"))

    config.RegisterCommonOption("tojour", "mdcommentprefix", "[comment]:")
    config.RegisterCommonOption("tojour", "imageviewer", "")
    config.RegisterCommonOption("tojour", "filebrowser", "nnn")
    -- config.RegisterCommonOption("tojour", "notificationhelper", "/usr/bin/notify-send")
    config.RegisterCommonOption("tojour", "notificationhelper", "")

    -- Default build script does a git commit of all files
    config.RegisterCommonOption(
        "tojour",
        "buildscript",
        "{ command -v git > /dev/null; } && git rev-parse 2> /dev/null && { cd $(git rev-parse --show-toplevel) && git add . && git commit -m 'pre-build autocommit' ; }; python "
            .. TJConfig.HELPER_SCRIPT_PATH
            .. "/todobuddy.py --today --write;"
    )
    config.RegisterCommonOption("tojour", "autobuildtoday", true)

    -- can be false, toc, index and undone
    config.RegisterCommonOption("tojour", "alwaysopencontextpane", false)
    config.RegisterCommonOption("tojour", "alwaysopentodayundone", true)
    config.RegisterCommonOption("tojour", "potatomode", false)
    config.RegisterCommonOption("tojour", "cache", false)
    config.RegisterCommonOption("tojour", "cache_dir", ".micro/.cache")

    -- remembers the width of hte mainpane
    config.RegisterCommonOption("tojour", "mainpanewidth", 60)
    TJConfig.MAIN_PANE_WIDTH_PERCENT = tonumber(config.GetGlobalOption("tojour.mainpanewidth"))

    -- if devmode is enabled with TOJOUR_DEVMODE=true env variable, all devlog functions write into /tmp/luajournal.txt
    TJConfig.TOJOUR_DEVMODE = os.getenv("TOJOUR_DEVMODE") == "true"
    if TJConfig.TOJOUR_DEVMODE == true then
        local Tests = require("Tests")
        Tests.tojourUnitTests()
    else
        TJConfig.TOJOUR_DEVMODE = false
    end
end

function cmdSetupTojour(bp)
    setupTojourBindings(bp, false)
end

function cmdSetupTojourForce(bp)
    setupTojourBindings(bp, true)
end

function setupTojourBindings(bp, force_override_hotkeys)
    if force_override_hotkeys then
        -- make backup
        local backupfile = config.ConfigDir .. "/bindings.tojour-backup." .. Common.getDateString() .. ".json"
        local output, err = shell.RunCommand("cp '" .. config.ConfigDir .. "/bindings.json' '" .. backupfile .. "'")
        if err == nil then
            Common.notify("Made a backup of your keybindings to " .. backupfile)
        end
    end

    -- These would need overriding true
    config.TryBindKey("Ctrl-v", "lua:tojour.cmdSmarterPaste", force_override_hotkeys)
    config.TryBindKey(
        "Tab",
        "IndentSelection|lua:tojour.cmdPressTabAnywhereToIndent|Autocomplete",
        force_override_hotkeys
    )

    -- config.TryBindKey("Ctrl-P", "lua:tojour.cmdBrowseJournals", false)
    config.TryBindKey("Ctrl-p", "lua:tojour.cmdBrowseOpenTabsAndJournals", force_override_hotkeys)
    config.TryBindKey("Ctrl-o", "lua:tojour.cmdJumpToSymbols", force_override_hotkeys)

    config.TryBindKey("Alt-d", "lua:tojour.cmdOpenTodayFile", force_override_hotkeys)
    config.TryBindKey("Alt-D", "lua:tojour.cmdBrowseDateJournals", force_override_hotkeys)
    config.TryBindKey("Alt-a", "lua:tojour.cmdJumpToTag", force_override_hotkeys)
    config.TryBindKey("Alt-f", "lua:tojour.cmdFollowInternalLink", force_override_hotkeys)

    -- Allow right clicking to follow stuff (warning, some versions of micro don't have MousePress event)
    config.TryBindKey("MouseRight", "lua:tojour.cmdHandleMouseEvent", true)
    config.TryBindKey("Alt-MouseLeft", "lua:tojour.cmdHandleMouseEvent", true)

    config.TryBindKey("Alt-]", "lua:tojour.cmdJumpToNextSymbol", force_override_hotkeys)
    config.TryBindKey("Alt-[", "lua:tojour.cmdJumpToPrevSymbol", force_override_hotkeys)
    config.TryBindKey("Alt-}", "lua:tojour.cmdJumpToNextAltSymbol", force_override_hotkeys)
    config.TryBindKey("Alt-{", "lua:tojour.cmdJumpToPrevAltSymbol", force_override_hotkeys)

    config.TryBindKey("Alt-m", "lua:tojour.cmdSelectBlock", force_override_hotkeys)

    config.TryBindKey("Ctrl-Alt-F", "lua:tojour.cmdFindTextInAllFiles", force_override_hotkeys)

    config.TryBindKey("Alt-c", "lua:tojour.cmdToggleCheckbox", force_override_hotkeys)
    config.TryBindKey("CtrlUnderscore", "lua:tojour.cmdInsertLineComment|lua:comment.comment", force_override_hotkeys)

    config.TryBindKey("Alt-z", "lua:tojour.cmdIncrementDaystring", force_override_hotkeys)
    config.TryBindKey("Alt-Z", "lua:tojour.cmdDecrementDaystring", force_override_hotkeys)
    config.TryBindKey("Ctrl-Alt-z", "lua:tojour.cmdIncrementDaystringByWeek", force_override_hotkeys)

    config.TryBindKey("Alt-T", "lua:tojour.cmdInsertDateTimestamp", force_override_hotkeys)
    config.TryBindKey("Alt-t", "lua:tojour.cmdInsertTimestamp", force_override_hotkeys)

    -- FIXME: Doesn't work
    config.TryBindKey("Alt-1", "lua:tojour.cmdInsertHeader1", force_override_hotkeys)
    config.TryBindKey("Alt-2", "lua:tojour.cmdInsertHeader2", force_override_hotkeys)
    config.TryBindKey("Alt-3", "lua:tojour.cmdInsertHeader3", force_override_hotkeys)
    config.TryBindKey("Alt-4", "lua:tojour.cmdInsertHeader4", force_override_hotkeys)
    config.TryBindKey("Alt-5", "lua:tojour.cmdInsertHeader5", force_override_hotkeys)
    config.TryBindKey("Alt-6", "lua:tojour.cmdInsertHeader6", force_override_hotkeys)

    -- Movement alt-vim-like kes
    config.TryBindKey("Alt-j", "CursorDown", force_override_hotkeys)
    config.TryBindKey("Alt-k", "CursorUp", force_override_hotkeys)
    config.TryBindKey("Alt-l", "CursorRight", force_override_hotkeys)
    config.TryBindKey("Alt-h", "CursorLeft", force_override_hotkeys)
    config.TryBindKey("Alt-J", "SelectDown", force_override_hotkeys)
    config.TryBindKey("Alt-K", "SelectUp", force_override_hotkeys)
    config.TryBindKey("Alt-L", "SelectRight", force_override_hotkeys)
    config.TryBindKey("Alt-H", "SelectLeft", force_override_hotkeys)
    config.TryBindKey("Alt-CtrlH", "WordLeft", force_override_hotkeys) -- NB: Needs preDeleteWordLeft action that disables this Alt-Backspace like behaviour
    config.TryBindKey("Alt-CtrlL", "WordRight", force_override_hotkeys)
    config.TryBindKey("Alt-Ctrlj", "MoveLinesDown", force_override_hotkeys)
    config.TryBindKey("Alt-Ctrlk", "MoveLinesUp", force_override_hotkeys)

    config.TryBindKey("Alt-,", "PreviousTab", force_override_hotkeys)
    config.TryBindKey("Alt-.", "NextTab", force_override_hotkeys)

    config.TryBindKey("Alt-=", "lua:tojour.cmdSidepaneResizeUp", force_override_hotkeys)
    config.TryBindKey("Alt--", "lua:tojour.cmdSidepaneResizeDown", force_override_hotkeys)

    -- config.TryBindKey("Alt-Ctrlj", "CursorPageDown", force_override_hotkeys)
    -- config.TryBindKey("Alt-Ctrlk", "CursorPageUp", force_override_hotkeys)

    -- VSCode style "Ctrl-d": "SpawnMultiCursor",
    -- VSCode style "alt-n": "duplicate line thing",

    config.TryBindKey("Alt-b", "lua:tojour.cmdRunBuildScript", force_override_hotkeys)
    config.TryBindKey("Alt-e", "lua:tojour.cmdRunFilebrowser", force_override_hotkeys)
    config.TryBindKey("Alt-w", "lua:tojour.cmdWordcount", force_override_hotkeys)
    config.TryBindKey("Alt-W", "lua:tojour.cmdResetGlobalWordcounts", force_override_hotkeys)

    config.TryBindKey("Alt-u", "lua:tojour.cmdToggleSidePaneUndone", force_override_hotkeys)
    config.TryBindKey("Alt-i", "lua:tojour.cmdToggleSidePaneIndex", force_override_hotkeys)
    config.TryBindKey("Alt-o", "lua:tojour.cmdToggleSidePaneTOC", force_override_hotkeys)
    config.TryBindKey("Alt-O", "lua:tojour.cmdTOCDecrement", force_override_hotkeys)
    -- hotkeys available: alt z, v, m, p, r, w (dev test), q

    config.TryBindKey("Alt-q", "NextSplit", force_override_hotkeys)
    config.TryBindKey("Alt-Q", "lua:tojour.cmdCloseSidePane", force_override_hotkeys)
end

function cmdCloseSidePane()
    local panes = TJPanes:new()
    if panes.panescount > 1 then
        panes.panesArray[2]:Quit()
    end
end

function cmdTOCIncrement(bp)
    SidepaneContent.TOCIncrement()
end

function cmdTOCDecrement(bp)
    SidepaneContent.TOCDecrement()
end

function cmdIncrementDaystring(bp)
    -- Common.cmdIncrementDaystring(bp)
    Common.incrementPrefixedDateInLine(bp, 1)
end

function cmdDecrementDaystring(bp)
    -- Common.cmdDecrementDaystring(bp)
    Common.incrementPrefixedDateInLine(bp, -1)
end

function cmdIncrementDaystringByWeek(bp)
    -- Common.cmdIncrementDaystringByWeek(bp)
    Common.incrementPrefixedDateInLine(bp, 7)
end

--
-- Events you can hook to: https://github.com/zyedidia/micro/issues/875
-- Sends InfoBar Message with first todo point, on every save Event (excluding autosave)
--
function onSave(bp)
    if not Common.isMarkdown() then
        return false
    end

    TJPanes:refreshSidePaneIfHasContext()
end

function onRune(rune)
    if config.GetGlobalOption("tojour.potatomode") == true or not Common.isMarkdown() then
        return false
    end

    -- makeSmartQuotes(rune)
    onRuneTriggerTagAutocomplete()
end

-- function onAnyEvent(bp)
--     if not isJournal() then return false end
--     -- TODO: is there an easy way to catch resize events here?
--     -- micro.CurPane():ResizePane(newwidth)
--     -- h = micro.CurPane()
--     -- w = h:GetView().Width
--     -- micro.InfoBar():Message(w, FULLWIDTH)
--     -- MAIN_PANE_WIDTH = (FULLWIDTH - w) / FULLWIDTH * 100
--     -- getInfoOnPanesInTab maybe better?
-- end

function preQuit()
    -- if not isMarkdown() then
    --     return
    -- end

    TJPanes:preQuitCloseSidePane()
end

function onNextTab()
    if not Common.isMarkdown() then
        return false
    end

    micro.InfoBar():Message("")
    TJPanes:refreshSidePaneIfHasContext()
end

function onPreviousTab()
    if not Common.isMarkdown() then
        return false
    end

    micro.InfoBar():Message("")
    TJPanes:refreshSidePaneIfHasContext()
end

-- function preNextSplit()
--     if not isMarkdown() then return false end

--     TJPanes:refreshSidePaneIfHasContext()
--     -- micro.InfoBar():Message("")
-- end

function onNextSplit()
    if not Common.isMarkdown() then
        return false
    end

    TJPanes:refreshSidePaneIfHasContext()
    -- micro.InfoBar():Message("")
end

function onMousePress()
    if not Common.isMarkdown() then
        return false
    end
    -- save file
    TJPanes:redrawTocIfActive()
end

-- TODO: bearable but still a tiny bit too slow, even with job spawn and debounce
function onCursorUp()
    if config.GetGlobalOption("tojour.potatomode") == true or not Common.isMarkdown() then
        return false
    end
    TJPanes:redrawTocIfActive()
end

function onCursorDown()
    if config.GetGlobalOption("tojour.potatomode") == true or not Common.isMarkdown() then
        return false
    end
    -- save file
    TJPanes:redrawTocIfActive()
end

function onCursorPageUp()
    if config.GetGlobalOption("tojour.potatomode") == true or not Common.isMarkdown() then
        return false
    end
    TJPanes:redrawTocIfActive()
end

function onCursorPageDown()
    if config.GetGlobalOption("tojour.potatomode") == true or not Common.isMarkdown() then
        return false
    end
    TJPanes:redrawTocIfActive()
end

--
-- Trigger autocomplete if we start a tag with # or [[
--
function onRuneTriggerTagAutocomplete()
    if not Common.isMarkdown() then
        return false
    end
    local word = Common.getWordUnderCursor()

    if string.find(word, "#[^%s#]$") then
        -- Replace #tagnames after first letter pressed
        local bp = micro.CurPane()
        local selectedTag = showTags(bp, "Insert #tag: ", string.gsub(word, "^#", ""))
        if selectedTag ~= "" then
            micro.CurPane():Backspace()
            if Common.strContains(selectedTag, " ") then
                -- if we have a space in our tag, then use square brackets instead of #
                selectedTag = "[[" .. selectedTag .. "]]"
                micro.CurPane():Backspace()
            end
            selectedTag = selectedTag .. " "
            Common.insertTextAtCursor(bp, selectedTag)
        end
    elseif string.find(word, "^%[%[%]?%]?$") then
        -- replace [[tagname if two [[ are typed
        local bp = micro.CurPane()
        local selectedTag = showTags(bp, "Insert [[tag]]: ", string.gsub(word, "[%[%]]", ""))
        if selectedTag ~= "" then
            -- in case autoclose is not activated, manually add ]] at the end
            -- hack: (only check for one ] since word is captured before the second autoclose kicks in)
            if not string.find(word, "%]$") then
                selectedTag = selectedTag .. "]]"
            end
            selectedTag = selectedTag .. " "
            Common.insertTextAtCursor(bp, selectedTag)
        end
    end
end

function cmdTogglePaneFocus(curpaneId)
    if not Common.isMarkdown() then
        return false
    end

    micro.CurPane():NextSplit()
end

function cmdOpenFirstPane()
    if not Common.isMarkdown() then
        return false
    end
    TJPanes:new()
    if TJPanes.panescount > 1 and TJPanes.curpaneId > 1 then
        tab = micro.CurTab()
        tab:SetActive(0)
        -- Disable debounce here (so we get live updates when we switch back)
        TJConfig.DEBOUNCE_GET_TOC = false
    end
end

function cmdOpenSecondPane()
    if not Common.isMarkdown() then
        return false
    end
    TJPanes:new()
    if TJPanes.panescount > 1 and TJPanes.curpaneId == 1 then
        tab = micro.CurTab()
        tab:SetActive(1)
    elseif TJPanes.panescount == 1 then
        TJPanes:openSidePaneWithContext("placeholder", false)
        tab = micro.CurTab()
        tab:SetActive(1)
        TJPanes.openAppropriateContextSidePane()
    end
end

--
-- For attaching shortcuts to sidepane openers without arguments
--
function cmdToggleSidePaneIndex(bp)
    if not Common.isMarkdown() then
        return false
    end

    TJPanes:openSidePaneWithContext("index", false)
end

function cmdToggleSidePaneTOC(bp)
    if not Common.isMarkdown() then
        return false
    end

    TJPanes:new()
    local metaSuffix = ""
    for paneIdx, pane in ipairs(TJPanes.panesArray) do
        local dirname, filename = TJPanes:getPaneDirAndFilename(pane)
        metaSuffix = Common.getPaneMetaname(filename)
    end
    if metaSuffix == "toc" then
        -- if a TOC pane is already open, increment TOC
        cmdTOCIncrement()
    else
        TJPanes:openSidePaneWithContext(TJConfig.FILE_META_SUFFIXES.toc, false)
    end
end

function cmdToggleSidePaneUndone(bp)
    if not Common.isMarkdown() then
        return false
    end

    TJPanes:openSidePaneWithContext(TJConfig.FILE_META_SUFFIXES.undone, false)
end

function cmdToggleSidePaneTree(bp)
    if not Common.isMarkdown() then
        return false
    end

    TJPanes:openSidePaneWithContext(TJConfig.FILE_META_SUFFIXES.tree, false)
end

function cmdSidepaneResizeUp(bp)
    local panes = TJPanes:new()
    TJConfig.MAIN_PANE_WIDTH_PERCENT = TJConfig.MAIN_PANE_WIDTH_PERCENT + 3
    TJPanes:resizePanes()
    config.SetGlobalOptionNative("tojour.mainpanewidth", TJConfig.MAIN_PANE_WIDTH_PERCENT)
end

function cmdSidepaneResizeDown(bp)
    local panes = TJPanes:new()
    TJConfig.MAIN_PANE_WIDTH_PERCENT = TJConfig.MAIN_PANE_WIDTH_PERCENT - 3
    panes:resizePanes()
    config.SetGlobalOptionNative("tojour.mainpanewidth", TJConfig.MAIN_PANE_WIDTH_PERCENT)
end

function cmdToggleCheckbox(bp)
    if not Common.isMarkdown() then
        return false
    end
    Common.cmdToggleCheckbox(bp)
end

--
-- Finds textstring in all files fast with ripgrep
--
function cmdFindTextInAllFiles(bp)
    if not Common.isMarkdown() then
        return false
    end

    -- FZF search for strings in files, with follow up file opener
    local cmd = string.format("bash " .. TJConfig.HELPER_SCRIPT_PATH .. "/findInAllFiles.sh")
    local output, err = shell.RunInteractiveShell(cmd, false, true)
    if err ~= nil then
        micro.InfoBar():Error(tostring(err) .. ": " .. output)
    elseif output ~= "" then
        FileLink:openInternalDocumentLink(bp, output)
    end
end

function cmdHandleMouseEvent(bp, tcell)
    -- Click the mouse again, but only if tcell / mousepress exists in this tty / micro
    if type(tcell) ~= "nil" then
        bp:MousePress(tcell)
    end
    if cmdFollowInternalLink(bp) == false then
        local line = Common.getLineAtCursor(bp)
        if string.find(line, "%- %[[ x/-]%]|[%*%[%] \t-]TODO") then
            Common.cmdToggleCheckbox(bp)
        end
    end
end

--
-- Grab word under cursor and follow it in new window if it's a link
--
function cmdFollowInternalLink(bp)
    if not Common.isMarkdown() then
        return false
    end

    TJPanes:followInternalLink(bp)
end

function cmdOpenTodayFile(bp)
    local todayFile = Common.getDateString(0) .. ".md"

    -- bounce to previous selected tab (if there was one)
    -- TODO: Improve this maybe for on every tab switch?
    local curTabFilename = Common.getRelativeFilepathOfCurrentPane()
    if todayFile == curTabFilename then
        -- micro.InfoBar():Message("already on todayfile")
        if TJConfig.PREVIOUS_TAB_FILENAME ~= "" then
            -- micro.InfoBar():Message("opening " .. PREVIOUS_TAB_FILENAME)
            FileLink:openInternalDocumentLink(bp, TJConfig.PREVIOUS_TAB_FILENAME)
        end
        return true
    end
    TJConfig.PREVIOUS_TAB_FILENAME = curTabFilename

    -- if autobuilding is enabled, then create the today file and run a defined buildscript (default todobuddy)
    if config.GetGlobalOption("tojour.autobuildtoday") then
        if not Common.fileExists(todayFile) then
            local file = io.open(todayFile, "w")
            file:write()
            file:close()
            local output, err =
                shell.RunCommand('bash -c "' .. tostring(config.GetGlobalOption("tojour.buildscript")) .. '"')
            if err ~= nil then
                micro.InfoBar():Error(tostring(err) .. ": " .. output)
                return false
            else
                micro.InfoBar():Message("Build script completed successfully: " .. output)
            end
        end
    end
    FileLink:openInternalDocumentLink(bp, todayFile)
end

function cmdSmarterPaste(bp)
    local c = bp.Cursor
    local cursor = buffer.Loc(c.Loc.X, c.Loc.Y)

    -- paste clipboard, returns a boolean that's more or less always true
    result = bp.paste(bp)

    if not Common.isMarkdown() then
        return true
    end

    local cursorAfterPaste = buffer.Loc(c.Loc.X, c.Loc.Y)

    -- if cursor position has shifted since paste
    if cursor ~= cursorAfterPaste then
        micro.InfoBar():Message("Pasted text")
    else
        micro.InfoBar():Message("Pasting image...")
        local currentFilename = Common.getRelativeFilepathOfCurrentPane()
        -- remove extension from filename
        local currentFilename = string.gsub(currentFilename, "%..*$", "")
        local cmd = "bash " .. TJConfig.HELPER_SCRIPT_PATH .. "/pasteImage.sh '" .. currentFilename .. "'"
        local output, err = shell.RunCommand(cmd)
        if err ~= nil then
            micro.InfoBar():Error(tostring(err) .. ": " .. output)
        elseif output ~= "" then
            currentTime = os.date("%Y-%m-%d %H:%M:%S")
            Common.insertTextAtCursor(bp, "![Image " .. currentTime .. "](" .. output .. ")")
            micro.InfoBar():Message("Pasted image: " .. output)
        end
    end
end

--
-- Indent from anywhere in the line
--
function cmdPressTabAnywhereToIndent(bp)
    if not Common.isMarkdown() and not micro.CurPane().Buf:FileType() == "yaml" then
        bp:InsertTab()
        return true
    end
    bp:IndentLine()
    return true
end

-- inserts configured symbols at the beginning of a line
function cmdInsertLineComment(bp)
    if not Common.isMarkdown() then
        return false
    end

    local symbol = tostring(config.GetGlobalOption("tojour.mdcommentprefix"))
    if symbol == "" then
        -- if comment symbol is blank, then use default behaviour
        return false
    end

    return toggleSymbolsStartOfLine(bp, symbol, 1)
end

--
-- Use fzf to allow inserting tags from all files
--
function showTags(bp, prompt, query)
    local cache_enabled = config.GetGlobalOption("tojour.cache")
    local cmd = string.format("bash '" .. TJConfig.HELPER_SCRIPT_PATH .. "/tagSearch.sh' --prompt %q", prompt)
    if query ~= nil then
        cmd = string.format(cmd .. " --query %q", query)
    end
    if cache_enabled ~= false then
        -- put a cache file into PROJECT_DIR/.micro/ by default
        local cache_file = TJSession:getProjectPwd()
            .. "/"
            .. tostring(config.GetGlobalOption("tojour.cache_dir"))
            .. "/"
            .. TJConfig.PROJECT_CACHE_TAG_FILENAME
        cmd = string.format(cmd .. " --cache-file %q", cache_file)
    end
    Common.devlog(cmd)
    local output, err = shell.RunInteractiveShell(cmd, false, true)

    -- with --bind=enter:replace-query+print-query this actually works, even if no match found, it doesn't return err 1
    -- if err ~= nil then
    --     -- if tostring(err) ~= "exit status 1" then
    --     micro.InfoBar():Error(tostring(err) .. ": " .. output)
    --     return ""
    -- end

    if output ~= "" then
        micro.InfoBar():Message("Selected tag: " .. output)
        output = strings.TrimSpace(output)
        return output
    end

    return ""
end

function cmdInsertTag(bp)
    if not Common.isMarkdown() then
        return false
    end

    local tag = showTags(bp, "Insert tag: ")
    if tag == "" then
        return ""
    end

    local text = ""
    -- if tag has space in it
    if string.find(tag, "%s") then
        text = "[[" .. tag .. "]] "
    else
        text = "#" .. tag .. " "
    end

    micro.InfoBar():Message("Inserting tag: " .. text)
    Common.insertTextAtCursor(bp, text)
end

function cmdJumpToTag(bp)
    if not Common.isMarkdown() then
        return false
    end

    local tag = showTags(bp, "Jump to tag: ")
    if tag == "" then
        return ""
    end

    FileLink:openInternalDocumentLink(bp, tag)
end

function cmdBrowseDateJournals(bp)
    local datesShow = ""
    local today = ""
    -- Only show journal dates when in a markdown file in journal
    if Common.isMarkdown() then
        today = Common.getDateString() .. ".md"
        local yesterday = Common.getDateString(-1) .. ".md"
        -- local twodaysago = getDateString(-2) .. ".md"
        -- local threedaysago = getDateString(-3) .. ".md"
        local tomorrow = Common.getDateString(1) .. ".md"
        datesShow = "today:: ./" .. today .. ",yesterday:: ./" .. yesterday .. ",tomorrow:: ./" .. tomorrow
        for i = 2, 7 do
            datesShow = datesShow .. "," .. i .. " days ago:: ./" .. Common.getDateString(-i) .. ".md"
        end
    end
    cmdBrowseJournals(bp, datesShow)
end

function cmdBrowseOpenTabsAndJournals(bp)
    cmdBrowseJournals(bp, "")
end

--
-- Open a new file in the current buffer
-- Inspired by fzf plugin: https://github.com/zyedidia/micro/blob/master/runtime/help/plugins.md
--
function cmdBrowseJournals(bp, prepend_text)
    local separator = " "

    -- check for extra files in other tabs, if so, display them too at the top
    local extra_lines = ""
    for tabIdx, tab in Common.userdataIterator(micro.Tabs().List) do
        for paneIdx, pane in Common.userdataIterator(tab.Panes) do
            if pane.Buf.Path then
                if Common.fileExists(pane.Buf.Path) and pane.Buf.Path ~= "" then
                    if extra_lines ~= "" then
                        -- add separator only after we've found at least one
                        separator = ","
                    end
                    extra_lines = extra_lines .. separator .. pane.Buf.Path
                    -- Turn separator to ',', so that we don't have a stray comma if we are not in md file (and datesShow is therefore empty)
                    --     separator = ","
                end
            end
        end
    end

    -- if prepend_text then
    --     notify(prepend_text)
    -- end
    -- notify(extra_lines)
    if prepend_text and extra_lines then
        extra_lines = prepend_text .. extra_lines
    end

    local cmd = string.format("bash " .. TJConfig.HELPER_SCRIPT_PATH .. "/browseJournals.sh %q", extra_lines)

    local output, err = shell.RunInteractiveShell(cmd, false, true)
    if err ~= nil then
        micro.InfoBar():Error(tostring(err) .. ": " .. output)
    else
        if output ~= "" then
            -- do we have a daily file?
            if Common.strContains(output, "::") then
                -- Strip strings before double colons, like yesterday:: ./2021-01-01.md
                -- NB: Also '|' which is hardcoded tab marker
                output = string.match(output, "^[|a-zA-Z0-9 ]+[:][:][ ](.+)$")
                if Common.strContains(output, Common.getDateString() .. ".md") then
                    return cmdOpenTodayFile(bp)
                end
            end

            -- strip leading | which can be introduced as tab indicator above and in browseJournal.sh
            if Common.strStartswithStrict(output, "|") then
                output = string.gsub(output, "^|", "")
            end

            -- if not strStartswithStrict(output, "/") and not strStartswithStrict(output, ".") then
            --     output = string.gsub(output, "^", "./")
            -- end

            return FileLink:openInternalDocumentLink(bp, output)

            -- exit if autobuildtoday is false
            -- if not config.GetGlobalOption("tojour.autobuildtoday") then
            --     return
            -- end

            -- if we have opened a today file (and it's new)
            -- deprecated, since all files have frontmatter now?
            -- if strContains(output, today) then
            --     bp:Save()
            --     -- get filesize of filename
            --     local filesize, err = shell.RunCommand("bash -c \"stat -c %s '" .. output .. "'\"")
            --     -- if not fileExists(output) or filesize == "0" then
            --     if tonumber(filesize) == 0 then
            --         cmdRunBuildScript(bp)
            --     end
            -- end
        end
    end
end

--
-- Run a configurable buildscript (can define with tojour.buildscript)
--
function cmdRunBuildScript(bp)
    if not Common.isMarkdown() then
        return false
    end

    bp:Save()
    local buildScript = tostring(config.GetGlobalOption("tojour.buildscript"))
    -- notify("Starting Build script")
    local output, err = shell.RunCommand('bash -c "' .. buildScript .. '"')
    if err ~= nil then
        micro.InfoBar():Error(tostring(err) .. ": " .. output)
    else
        micro.InfoBar():Message("Build script completed successfully: " .. output)
    end
end

-- Can be used for status message but is a bit slow, gets triggered on every cursor movement, etc
function wordcount()
    local bp = micro.CurPane()
    local wc = cmdWordcount(bp)
    return wc
end

--
-- Do a super fast GNU wordcount, ignoring lines starting with / or % or @ comments
--
function cmdWordcount(bp)
    if not Common.isMarkdown() then
        return ""
    end
    if micro.CurPane().Buf:Modified() then
        bp:Save()
    end
    local wordcountmsg = ""
    local wordcountScript = TJConfig.HELPER_SCRIPT_PATH .. "/wordcount.sh"
    local cmd = string.format("bash " .. wordcountScript .. " %q", bp.Buf.path)
    local wordcount, err = shell.RunCommand(cmd)
    -- notify(wordcount)
    if err ~= nil then
        micro.InfoBar():Error(tostring(err) .. " in word count")
        return false
    else
        local oldwc = 0
        local session = TJSession:new()
        if session:getWordcount() == "" then
            session:setWordcount(wordcount)
            wordcountmsg = "Word count: " .. tostring(wordcount) .. " (session wordcount reset to 0)"
            micro.InfoBar():Message(wordcountmsg)
            return wordcountmsg
        else
            oldwc = session:getWordcount()
        end

        -- Alternative: if there is global variable of oldwc, then use this for session, rather than git
        if oldwc ~= 0 then
            wordcountmsg = "Word count: "
                .. tostring(wordcount)
                .. " ("
                .. tostring(tonumber(wordcount) - tonumber(oldwc))
                .. " this session)"
            micro.InfoBar():Message(wordcountmsg)
            return wordcountmsg
        end
    end
    return wordcountmsg
end

function cmdResetGlobalWordcounts(bp)
    TJSession:setWordcount("")
    micro.InfoBar():Message("Wordcounts in session reset. " .. cmdWordcount(bp))
end

--
-- Starts an CLI file browser, defaults to nnn, can be configured in sh file
--
function cmdRunFilebrowser(bp)
    if not Common.isMarkdown() then
        return false
    end

    local output, err = shell.RunInteractiveShell(
        "bash -i "
            .. TJConfig.HELPER_SCRIPT_PATH
            .. "/openFilebrowser.sh '"
            .. tostring(config.GetGlobalOption("tojour.filebrowser"))
            .. "'",
        false,
        true
    )
    if err ~= nil then
        micro.InfoBar():Error(tostring(err) .. ": " .. output)
    elseif output ~= "" then
        local dirname, filename = Common.getDirNameAndFile(output)
        filename = strings.TrimSpace(filename) -- for some reason there's a whitespace at the end
        FileLink:openInternalDocumentLink(bp, dirname .. filename)
    end
end

function cmdSelectBlock(bp)
    local function getMdHeadingLevel(line)
        return #line - #string.gsub(line, "^(%s*)#*(%s)", "%1%2")
    end

    local firstline = Common.getLineAtCursor(bp)
    local firstline_heading_level = getMdHeadingLevel(firstline)
    local firstline_leading_space = util.GetLeadingWhitespace(firstline)

    local function selectChildBlocks()
        local line_num = Common.getCurrentLineNumber(bp)
        if line_num + 1 >= bp.Buf:LinesNum() then
            return false
        end
        local child_line = bp.Buf:Line(line_num + 1)
        local child_leading_space = util.GetLeadingWhitespace(child_line)
        local child_heading_level = getMdHeadingLevel(child_line)
        -- select the next paragraph if:
        -- the next para is indented further, or
        -- the next para is empty (i.e. it is just made of spaces), or
        -- the selection starts on an md '# headline' until the next md headline
        -- (strStartswith(firstline, "%s*##*%s") and not strStartswith(child_line, "%s" .. string.rep("#?", child_heading_level) .. "%s") and child_leading_space >= firstline_leading_space) then
        if
            (child_leading_space > firstline_leading_space)
            or (#child_leading_space == #child_line)
            or (
                firstline_heading_level > 0
                and not (child_heading_level > 0 and child_heading_level <= firstline_heading_level)
                and child_leading_space >= firstline_leading_space
            )
        then
            -- devlog("WE ARE WITH CHILD")
            local c = bp.Cursor
            c.Y = c.Y + 1
            bp.Cursor:AddLineToSelection()
            return true
        else
            return false
        end
    end

    if not bp.Cursor:HasSelection() then
        bp.Cursor:SelectLine()
    end

    while selectChildBlocks() do
        selectChildBlocks()
    end
    micro.CurPane():Center()
end

-- based on
-- https://github.com/terokarvinen/micro-jump
-- Copyright 2020-2021 Tero Karvinen http://TeroKarvinen.com
--
function cmdJumpToSymbols(bp) -- bp BufPane
    if not Common.isMarkdown() then
        return false
    end

    local filename = Common.getRelativeFilepathOfCurrentPane()
    local cmd = string.format("bash " .. TJConfig.HELPER_SCRIPT_PATH .. "/jumpToSymbols.sh %q", filename)
    local out = shell.RunInteractiveShell(cmd, false, true)
    if tonumber(out) == nil then
        -- micro.InfoBar():Message("Jump cancelled.")
        return
    end
    local linenum = tonumber(out) - 1
    -- deselect current selection so we can jump properly
    bp.Buf:GetActiveCursor():Deselect(false)
    bp.Cursor.Y = linenum
    micro.InfoBar():Message(string.format("Jumped to line %s", tostring(linenum)))
end

function cmdJumpToNextSymbol(bp)
    if not Common.isMarkdown() then
        return false
    end
    bp.Buf.LastSearchRegex = true
    bp.Buf.LastSearch = config.GetGlobalOption("tojour.symbolsforjump")
    bp:FindNext()
    TJPanes:redrawTocIfActive()
    -- bp.CursorLeft()
    -- bp.Buf:GetActiveCursor():Deselect(false)
end

function cmdJumpToPrevSymbol(bp)
    if not Common.isMarkdown() then
        return false
    end
    bp.Buf.LastSearchRegex = true
    bp.Buf.LastSearch = config.GetGlobalOption("tojour.symbolsforjump")
    bp:FindPrevious()
    TJPanes:redrawTocIfActive()
    -- bp.Buf:GetActiveCursor():Deselect(false)
end

function cmdJumpToNextAltSymbol(bp)
    if not Common.isMarkdown() then
        return false
    end
    bp.Buf.LastSearchRegex = true
    bp.Buf.LastSearch = config.GetGlobalOption("tojour.symbolsforaltjump")
    bp:FindNext()
    TJPanes:redrawTocIfActive()
end

function cmdJumpToPrevAltSymbol(bp)
    if not Common.isMarkdown() then
        return false
    end
    bp.Buf.LastSearchRegex = true
    bp.Buf.LastSearch = config.GetGlobalOption("tojour.symbolsforaltjump")
    bp:FindPrevious()
    TJPanes:redrawTocIfActive()
end

function cmdInsertTimestamp(bp)
    Common.insertTextAtCursor(bp, tostring(os.date("%H:%M ")))
end

function cmdInsertDateTimestamp(bp)
    Common.insertTextAtCursor(bp, tostring(os.date("%Y-%m-%d ")))
end

function cmdInsertHeader1(bp)
    toggleMdHeader(bp, 1)
end
function cmdInsertHeader2(bp)
    toggleMdHeader(bp, 2)
end
function cmdInsertHeader3(bp)
    toggleMdHeader(bp, 3)
end
function cmdInsertHeader4(bp)
    toggleMdHeader(bp, 4)
end
function cmdInsertHeader5(bp)
    toggleMdHeader(bp, 5)
end
function cmdInsertHeader6(bp)
    toggleMdHeader(bp, 6)
end

function toggleMdHeader(bp, level)
    lines = Common.getLineAtCursor(bp)
    symbol = "#"
    spacer = " "
    repetition = level
    if Common.strStartswithStrict(lines, string.rep(symbol, repetition) .. tostring(spacer)) then
        -- If line starts with '### ' already and we're trying to set ### (h3), then toggle it
        toggleSymbolsStartOfLine(bp, "#", level)
        -- line = string.gsub(line, "^" .. symbol .. "*" .. spacer, "")
    elseif Common.strStartswithStrict(lines, symbol) then
        -- if line starts with any other number of single #'s, do a replace
        local c = bp.Cursor
        local new_line = string.gsub(
            lines,
            "^" .. symbol .. "*" .. spacer .. "*",
            string.rep(symbol, repetition) .. tostring(spacer)
        )
        adjustCursorToNewLinelength(bp, new_line, lines)
    else
        -- nothing is here yet, so just do normal toggle
        toggleSymbolsStartOfLine(bp, "#", level)
    end
end

-- Inserts the symbols followed by a whitespace at the beginning of a line
function toggleSymbolsStartOfLine(bp, symbols, repetition)
    -- add symbols and space to the beginning of the line
    local line = Common.getLineAtCursor(bp)
    local old_line = line
    local spacer = " "

    if Common.strStartswithStrict(line, symbols) then
        -- cut out the part of the line from after the symbols and spacer to the end
        if repetition > 1 then
            line = string.gsub(line, "^" .. symbols .. "*" .. spacer, "")
        else
            line = string.sub(line, #(symbols .. spacer) + 1, -1)
        end
    else
        symbols = string.rep(symbols, repetition)
        -- add symbols to beginning of line
        if Common.strStartswith(line, "%s") then
            spacer = ""
        end
        line = symbols .. spacer .. line
    end

    adjustCursorToNewLinelength(bp, line, old_line)
    return true
end

-- adjust the total line length, a negative number if shortening a line, so we don't have leftovers at the end
function adjustCursorToNewLinelength(bp, line, oldline)
    local charsLen = #line - #oldline
    local c = bp.Cursor
    local originalCursorLoc = buffer.Loc(c.Loc.X, c.Loc.Y)
    bp.Buf:Replace(buffer.Loc(0, c.Y), buffer.Loc(#line - charsLen, c.Y), line)

    -- restore previous cursor position
    local newCursorLoc = buffer.Loc(originalCursorLoc.X + charsLen, originalCursorLoc.Y)
    bp.Cursor:GotoLoc(newCursorLoc)
end

-- Not in use
-- TODO: Find a very fast way (faster than a spawned sub-shell file access) to grab the current buffer
function cmdGetBufferText(bp)
    -- local curline = getCurrentLineNumber(bp)
    local num_lines = bp.Buf:LinesNum()
    local lines = bp.Buf:Line(0) .. "\n"
    -- local cursor = false
    -- this is slooow... also because we don't get to fork into the background in shell, as above
    for i = 1, num_lines + 1, 1 do
        local line = bp.Buf:Line(i)
        -- if strStartswith(line, "#+") then
        -- lines = lines .. "\n"
        -- if i >= curline and cursor == false then
        -- lines = lines .. "> "
        -- cursor = true
        -- end
        lines = lines .. line .. ""
        -- end
    end

    -- notify(lines)
    return lines
end
