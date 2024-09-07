VERSION = "1.0.0"
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

--
-- Local config constants
--
function init()
    config.AddRuntimeFile("tojour", config.RTHelp, "help/tojour.md")
    -- TODO: None of these runtime loaders work (or if they do, like Colorschemes, they are not available from launch)
    -- config.AddRuntimeFile("tojour", config.RTColorscheme, "colorschemes/tojour-neon.micro")
    -- config.AddRuntimeFile("tojour", config.RTColorscheme, "colorschemes/tojour-default.micro")
    -- config.AddRuntimeFile("tojour", config.RTSyntax, "syntax/markdown-journal.yaml")

    config.TryBindKey("Alt-R", "command:set colorscheme tojour-neon", true) 
    config.TryBindKey("Alt-r", "command:set colorscheme tojour-default", true) 
    
    setupTojour(bp, false)
end

function cmdSetupTojour(bp)
    setupTojour(bp, true)
end

function setupTojour(bp, force_override_hotkeys)
    if force_override_hotkeys then
        -- make backup
        local backupfile = config.ConfigDir .. "/bindings.tojour-backup." .. getDateString() .. ".json"
        local output, err = shell.RunCommand("cp '" .. config.ConfigDir .. "/bindings.json' '" .. backupfile .. "'")
        if err == nil then
            notify("Made a backup of your keybindings to " .. backupfile)
        end
    end
    -- These would need overriding true
    config.TryBindKey("Ctrl-v", "lua:tojour.cmdSmarterPaste", force_override_hotkeys)
    config.TryBindKey("Tab", "IndentSelection|lua:tojour.cmdPressTabAnywhereToIndent|Autocomplete", force_override_hotkeys)

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
    
    -- regex that we can jump to directly with hotkeys
    config.RegisterCommonOption("tojour", "symbolsforjump", "^*#{1,6} .+")
    config.TryBindKey("Alt-]", "lua:tojour.cmdJumpToNextSymbol", force_override_hotkeys)
    config.TryBindKey("Alt-[", "lua:tojour.cmdJumpToPrevSymbol", force_override_hotkeys)
    config.RegisterCommonOption("tojour", "symbolsforaltjump", "#[A-Za-z0-9\\.$~/_-]+[A-Za-z0-9]|\\[\\[?[a-zA-Z0-9\\.$~/_\\s-]+[A-Za-z0-9]\\]?\\]|\\[[+-]{2}]")
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

    config.MakeCommand("tojour.setupbindings", cmdSetupTojour, config.NoComplete)

    -- TODO: add show wordcountnow toggle config.TryBindKey("Alt-w", "lua:tojour.cmdCountNowTODO", false)
    config.MakeCommand("wordcountreset", cmdResetGlobalWordcounts, config.NoComplete)
    config.TryBindKey("Alt-w", "lua:tojour.cmdWordcount", force_override_hotkeys)
    config.TryBindKey("Alt-W", "lua:tojour.cmdResetGlobalWordcounts", force_override_hotkeys)


    config.TryBindKey("Alt-u", "lua:tojour.cmdToggleSidePaneUndone", force_override_hotkeys)
    config.TryBindKey("Alt-i", "lua:tojour.cmdToggleSidePaneIndex", force_override_hotkeys)
    config.TryBindKey("Alt-o", "lua:tojour.cmdToggleSidePaneTOC", force_override_hotkeys)
    config.TryBindKey("Alt-O", "lua:tojour.cmdTOCDecrement", force_override_hotkeys)
    -- hotkeys available: alt z, v, m, p, r, w (dev test), q

    config.TryBindKey("Alt-q", "NextSplit", force_override_hotkeys)
    config.TryBindKey("Alt-Q", "lua:tojour.cmdCloseSidePane", force_override_hotkeys)

    HOME_DIR = tostring(os.getenv("HOME"))
    PLUGIN_PATH = config.ConfigDir .. "/plug/tojour"
    HELPER_SCRIPT_PATH = config.ConfigDir .. "/plug/tojour/scripts"

    -- use @today, @habit, @tomorrow to denote recurring, current and future todo items
    config.RegisterCommonOption("tojour", "dateprefix", "@")
    config.RegisterCommonOption("tojour", "todaystring", "today")
    config.RegisterCommonOption("tojour", "tomorrowstring", "tomorrow")
    config.RegisterCommonOption("tojour", "habitstring", "habit")
    -- '@' by default prefix to denote dates
    date_prefix = tostring(config.GetGlobalOption("tojour.dateprefix"))
    -- '@today' by default (prefixed with default date_prefix)
    today_string = date_prefix .. tostring(config.GetGlobalOption("tojour.todaystring"))
    -- '@tomorrow' by default (prefixed with default date_prefix)
    tomorrow_string = date_prefix .. tostring(config.GetGlobalOption("tojour.tomorrowstring"))
    -- '@habit' by default (prefixed with default date_prefix)
    habit_string = date_prefix .. tostring(config.GetGlobalOption("tojour.habitstring"))

    config.RegisterCommonOption("tojour", "mdcommentprefix", "[comment]:")
    
    config.RegisterCommonOption("tojour", "imageviewer", "")
    config.RegisterCommonOption("tojour", "filebrowser", "nnn")
    -- config.RegisterCommonOption("tojour", "notificationhelper", "/usr/bin/notify-send")
    config.RegisterCommonOption("tojour", "notificationhelper", "")

    -- Default build script does a git commit of all files
    config.RegisterCommonOption("tojour", "buildscript", "{ command -v git > /dev/null; } && git rev-parse 2> /dev/null && { cd $(git rev-parse --show-toplevel) && git add . && git commit -m 'pre-build autocommit' ; }; python " .. HELPER_SCRIPT_PATH .. "/todobuddy.py --today --write;")
    -- config.RegisterCommonOption("tojour", "buildscript", "command -v git && git rev-parse && cd $(git rev-parse --show-toplevel) && git add . && git commit -m 'pre-build autocommit' || echo 'No git repo here'; python " .. helper_script_path .. "/todobuddy.py --today --write")
    -- config.RegisterCommonOption("tojour", "buildscript",
    --     "command -v git && git rev-parse && cd $(git rev-parse --show-toplevel) && git add . && git commit -m 'build autocommit'; todobuddy.py")
    config.RegisterCommonOption("tojour", "autobuildtoday", true)
    
    -- can be false, toc, index and undone
    config.RegisterCommonOption("tojour", "alwaysopencontextpane", false)
    config.RegisterCommonOption("tojour", "alwaysopentodayundone", true)
    config.RegisterCommonOption("tojour", "potatomode", false)

    config.RegisterCommonOption("tojour", "mainpanewidth", 60)
    MAIN_PANE_WIDTH_PERCENT = tonumber(config.GetGlobalOption("tojour.mainpanewidth"))

    TOJOUR_DEVMODE = os.getenv("TOJOUR_DEVMODE") == "true"
    if TOJOUR_DEVMODE == true then
        tojourUnitTests()
    else
        TOJOUR_DEVMODE = false
    end

    config.TryBindKey("Alt-s", "lua:tojour.cmdGetBufferText", true)
end


-- Set this to true while currently getting a new TOC, is set by
DEBOUNCE_GET_TOC = false
DEBOUNCE_GET_SIDEPANE = false

-- The suffixes that sidepanes give to files, like .tagname.index.md
FILE_META_SUFFIXES = { index = 'index', undone = 'undone', toc = 'toc' }
FILE_META_HEADER_BEGIN = "-- "
FILE_META_MENU_START = FILE_META_HEADER_BEGIN .. ""
FILE_META_MENU_END = ""
-- store the previous tab that has been open for cmdOpenTodayFile
-- TODO: but improve this, to always get triggered
-- TODO: refactor this into the TJSession
PREVIOUS_TAB_FILENAME = ""

--
-- utility function to avoid triggering some functions on filetypes other than markdown
--
function isMarkdown()
    local filetype = micro.CurPane().Buf:FileType()
    if filetype == "markdown" or filetype == "markdownjournal" or filetype == "asciidoc" then return true end
    if filetype == "unknown" then 
        if getFileExtension(micro.CurPane().Buf.Path) == "txt" then
            return true
        end
    end
    return false
end

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

-- TODO: refactor in order to re-initialise TJPanes every time Tab or Pane is switched, closed, or new Pane created
TJPanes = {}
TJPanes.fullwidth = 0
TJPanes.sidepanewidth = 0
TJPanes.panesArray = {}
TJPanes.curpaneId = nil
TJPanes.panescount = 0
TJPanes.curpaneFilename = ""

--
-- call this (often) to initialise TJPanes.panesArray, curpaneId and panescount
-- Also writes global variable FULLWIDTH
--
function TJPanes:new()
    local function setCurpaneInfo()
        local curpane = micro.CurPane()
        local paneFilename = curpane.Buf.AbsPath
        if paneFilename == self.curpaneFilename then
            -- devlog("PANE NOT CHANGED")
            -- bail out if the pane has changed, and reuse the previous state of panes from self
            -- self.curPaneFilename = paneFilename
            -- return self.panesArray, self.curpaneId, self.panescount
        elseif self.curpaneFilename ~= nil then
            -- devlog(paneFilename .. ", was: " .. self.curPaneFilename)
            devlog("switched: " .. paneFilename .. ", was: " .. self.curpaneFilename)
        end
        self.curpaneFilename = paneFilename

        local curtab = micro.CurTab()
        for paneIdx, pane in userdataIterator(curtab.Panes) do
            -- local dirname, filename = TJPanes:getPaneDirAndFilename(pane)
            -- devlog("PaneId: " .. paneIdx .. ", dirName: " .. dirname .. ", filename: " .. filename)
    
            if pane.Buf.AbsPath == curpane.Buf.AbsPath then
                self.curpaneId = paneIdx
            end
            -- devlog(paneIdx)
    
            -- how many panes are in the current tab?
            self.panescount = self.panescount + 1
    
            -- measure the full width of all panes here, because it's a pain elsewhere
            self.fullwidth = self.fullwidth + pane:GetView().Width
            self.panesArray[tonumber(paneIdx)] = pane
            if self.panescount > 1 then
                -- the width of the sidepane in columns
                self.sidepanewidth = pane:GetView().Width
            end
        end
    end

    self.fullwidth = 0
    self.panesArray = {}
    -- panes = getPanesInTabAsArray()
    self.panescount = 0

    setCurpaneInfo()

    return self
end

--
-- Redraws the TOC sidepane if it is currently active (with debounce)
--
function TJPanes:redrawTocIfActive()
    if DEBOUNCE_GET_TOC == true then
        -- devlog("debounced TOC, quitting")
        return false
    end
    DEBOUNCE_GET_TOC = true

    local curtab = micro.CurTab()
    for paneIdx, pane in userdataIterator(curtab.Panes) do
        if string.find(pane.Buf.Path, '%.toc%.md$') then
            -- This redraw is kinda slow of course - the bash TOC is not instant obviously
            return TJPanes:refreshSidePaneIfHasContext()
        end
    end
end

--
-- Gets every pane that's open in current tab as array
--
function TJPanes:getPanesInTabAsArray()
    local panes = {}
    local curtab = micro.CurTab()
    -- for tabIdx, tab in userdataIterator(micro.Tabs().List) do
    for paneIdx, pane in userdataIterator(curtab.Panes) do
        panes[tonumber(paneIdx)] = pane
    end
    return panes
end

--
-- Check if a side panel is alrady open, and if so, refresh it
--
function TJPanes:refreshSidePaneIfHasContext(force)
    TJPanes:new()
    -- Bail out if we're already in a sidepane
    if TJPanes.curpaneId > 1 and not force then
        return ""
    end
    if DEBOUNCE_GET_SIDEPANE == true then
        -- notify("Debouncing")
        return false
    end
    DEBOUNCE_GET_SIDEPANE = true

    for paneIdx, pane in ipairs(TJPanes.panesArray) do
        local dirname, filename = TJPanes:getPaneDirAndFilename(pane)
        -- devlog("Will refresh pane: " .. filename)
        local metaSuffix = getPaneMetaname(filename)
        if metaSuffix ~= "" and metaSuffix ~= FILE_META_SUFFIXES.index then
            -- devlog("Refreshing sidepane with meta suffix: " .. metaSuffix)
            TJPanes:openSidePaneWithContext(metaSuffix, false)
            return metaSuffix
        end
    end
    DEBOUNCE_GET_SIDEPANE = false
    return ""
end

--
-- returns dirname, file from a given pane
--
function TJPanes:getPaneDirAndFilename(pane)
    return getDirNameAndFile(pane.Buf.AbsPath)
end

function TJPanes:getLeftPaneFilename()
    local curpane = self.panesArray[1]
    return curpane.Buf.Path
end

--
-- Closes a context sidepane if its mainpane is closed
--
function TJPanes:preQuitCloseSidePane()
    local panes = TJPanes:getPanesInTabAsArray()
    local curPane = micro.CurPane()
    -- devlog(curPane.Buf.Path)
    for paneIdx, pane in ipairs(panes) do
        -- devlog("PaneId: " .. paneIdx .. ", dirName: " .. dirname .. ", filename: " .. filename)
        -- devlog(pane.Buf.Path)
        if tonumber(paneIdx) == 2 and curPane.Buf.Path ~= pane.Buf.Path then
            local dirname, filename = TJPanes:getPaneDirAndFilename(pane)
            if strStartswith(filename, "%.") then
                -- devlog("we have a second dot pane open, closing it")
                pane:Quit()
            end
        end
    end
end

--
-- Opens or toggles a specified related file or information in side panel
-- contextMeta: toc, index, todos
--
function TJPanes:openSidePaneWithContext(contextMeta, focusNewPane)
    TJPanes:new()
    DEBOUNCE_GET_SIDEPANE = true
    local currentPaneName = ""
    
    function run()
        -- if we're in a side pane with the appropriate context, then refresh it
        if self.curpaneId == 2 then
            if self.panescount == 2 then
                -- select left pane, and run this again (but with force focus change)
                local curtab = micro.CurTab()
                curtab:SetActive(0)
                TJPanes:openSidePaneWithContext(contextMeta, true)
                return true
            end
        end

        -- if in mainpane and have to create second (or update it)
        if self.curpaneId == 1 then
            if self.panescount == 1 or self.panescount == 2 then
                local firstpaneDirname, firstpaneFilename = getDirNameAndFile(getRelativeFilepathOfCurrentPane())
                local fullfilepath = firstpaneDirname .. firstpaneFilename
                currentPaneName = fullfilepath

                if not isFileHidden(firstpaneFilename) then
                    local contents = ""
                    local newpanename = ""
                    if contextMeta == FILE_META_SUFFIXES.index then
                        asyncUpdatePaneWithIndex(fullfilepath)
                        return true
                    elseif contextMeta == FILE_META_SUFFIXES.undone then
                        asyncUpdatePaneWithUndone(fullfilepath)
                        return true
                    elseif contextMeta == FILE_META_SUFFIXES.toc then
                        -- Asynchronously update this tab in background, and return so we don't trigger update below
                        asyncUpdatePaneWithTocContent(fullfilepath, self.panescount, focusNewPane)
                        return true
                    elseif contextMeta == FILE_META_SUFFIXES.tree then
                        newpanename = makeFilepathMetaHidden(firstpaneFilename, 'tree')
                        -- tree is a bit ugly and broken alas - it produces garbage unicode characters if too close to the tree, sadly
                        -- cmd = string.format("sh -c \"tree -i %s\"", firstpaneDirname)
                        local cmd = string.format("sh -c \"tree %q\"", firstpaneDirname)
                        contents, err = shell.RunCommand(cmd)
                        local headingtext = '6. Tree'
                        local heading = createContextHeading(headingtext, "tree")
                        contents = heading .. contents
                        TJPanes:createNewSidePane(contents, newpanename, focusNewPane)
                    end
                else
                    -- Nearly deprecated since we have auto quit event (does NOT open a new pane but instead open the non-hidden file in the current pane)
                    namewithoutleadingdot = string.gsub(firstpaneFilename, "^%.(.*)$", "%1")
                    bp = micro.CurPane()
                    FileLink:openFileInCurrentTab(bp, firstpaneDirname .. namewithoutleadingdot)
                    self:resizePanes()
                end
            end
        end
        DEBOUNCE_GET_SIDEPANE = false
    end

    -- type: toc, index or todos
    function callbackPaneUpdate(relativeFilename, type, contents, headline)
        self:new()
        -- bail if we have switched tabs since first triggering update
        -- since this cancels update, have inserted forced update into onNextTab and onPrevTab
        if currentPaneName ~= getRelativeFilepathOfCurrentPane() then
            DEBOUNCE_GET_SIDEPANE = false
            DEBOUNCE_GET_TOC = false
            return false
        end
        local newpanename = makeFilepathMetaHidden(relativeFilename, type)
        self:createNewSidePane(createContextHeading(headline, type) .. contents, newpanename, focusNewPane)
        self:resizePanes()
        DEBOUNCE_GET_SIDEPANE = false
        -- Save the session with the new pane info
        TJSession:new()
    end

    --
    -- Runs in background and refreshes panel if required
    --
    function asyncUpdatePaneWithTocContent(relativeFilename, panescount, focusNewPane)
        local dirname, filename = getDirNameAndFile(relativeFilename)
        local newpanename = makeFilepathMetaHidden(filename, FILE_META_SUFFIXES.toc)
        local session = TJSession:new()
        local toc_level = session:getTocLevel()

        function onExit(contents)
            -- local headingtext = '[Toc] ' .. filename .. " "
            local headingtext = filename
            headingtext = headingtext .. " H" .. toc_level .. " [--] [++]"
            if contents == "" then
                headingtext = headingtext .. " (no markdown # headers found)"
            end
            
            callbackPaneUpdate(relativeFilename, FILE_META_SUFFIXES.toc, contents, headingtext)
            DEBOUNCE_GET_TOC = false
            if config.GetGlobalOption("tojour.potatomode") == true then
                micro.InfoBar():Message("Showing table of contents")
            end
            -- TODO: Should we grab the nearest headline above in main body and use as cursor in right pane? How?
        end


        if config.GetGlobalOption("tojour.potatomode") == true then
            micro.InfoBar():Message("Please wait: Fetching table of contents...")
        end

        -- to cludge line number into TOC
        local linenum = getCurrentLineNumber(micro.CurPane())

        local escapedCommentPrefix = strEscapeBadlyForShell(tostring(config.GetGlobalOption("tojour.mdcommentprefix")))
        if TJPanes.sidepanewidth == 0 then
            -- If sidepandwidth hasn't been initialised yet because pane isn't open yet, reconstruct this from config width
            TJPanes.sidepanewidth = math.floor(TJPanes.fullwidth / 100 * (100 - MAIN_PANE_WIDTH_PERCENT) + 0.5)
        end
        -- If we do this natively in micro, we get neither fast subshell nor sane shell escaping and get mangling of \n etc with %q
        -- local text = strEscapeBadlyForShell(cmdGetBufferText(micro.CurPane()))
        -- onExit(text)
        -- local text = strEscapeForShellRegex("$(notify-send inject);`notify-send inject2`")
        -- local cmd = string.format("sh " .. HELPER_SCRIPT_PATH .. "/generateTOC.sh --line-number %q --col-width %q --comment-prefix %q --max-level %q --text %q", tostring(linenum + 2), TJPanes.sidepanewidth, escapedCommentPrefix, toc_level, text)

        -- TODO: Performance boost possible by getting TOC's previous and next headings from cursor, and check if refresh is necessary before calling
        -- using /tmp fs is not significantly fasterr - local cmd = string.format("sh " .. HELPER_SCRIPT_PATH .. "/generateTOC.sh %q --line-number %q --col-width %q --comment-prefix %q --max-level %q", "/tmp/tmp.md", tostring(linenum + 2), TJPanes.sidepanewidth, escapedCommentPrefix, toc_level)
        local cmd = string.format("sh " .. HELPER_SCRIPT_PATH .. "/generateTOC.sh %q --line-number %q --col-width %q --comment-prefix %q --max-level %q", dirname .. filename, tostring(linenum + 2), TJPanes.sidepanewidth, escapedCommentPrefix, toc_level)

        shell.JobSpawn("sh", { "-c", cmd }, function(input) return end, function(input) return end,
        function(input)
            onExit(input); return
        end, "")
    end

    --
    -- Opens a sidepane with the appropriate undone Todos, if there are any
    --
    function asyncUpdatePaneWithUndone(relativeFilename)
        local dirname, filename = getDirNameAndFile(relativeFilename)

        -- get all todo items, not just the today or habit ones
        local filterByTagname = strStripExtension(filename)

        function onExit(contents)
            callbackPaneUpdate(relativeFilename, FILE_META_SUFFIXES.undone, contents, relativeFilename)
            if config.GetGlobalOption("tojour.potatomode") == true then
                micro.InfoBar():Message("Showing undone todo items")
            end
        end
        
        if config.GetGlobalOption("tojour.potatomode") == true then
            micro.InfoBar():Message("Please wait: Fetching undone todo items...")
        end

        local cmd = ""
        local output, err
        if type(filterByTagname) == "string" and filterByTagname ~= "" and not string.match(filterByTagname, "%d%d%d%d%-%d%d%-%d%d") then
            cmd = string.format("bash " .. HELPER_SCRIPT_PATH .. "/collectUndonesFromFile.sh %q --filter-by-tag %q", relativeFilename, filterByTagname)
            -- output, err = shell.RunCommand(cmd)
            shell.JobSpawn("sh", { "-c", cmd }, function(input) return end, function(input) return end,
            function(input)
                onExit(input); return
            end, "")
        else
            -- this just gets undone todos in the current file that have today or habit in it
            -- TODO: to deprecate - really we want the above option all the time now probably (even for daily files, why not)
            -- NO: If we are on today file, then simply search for @today instead everywhere in all files?
            cmd = string.format("bash " .. HELPER_SCRIPT_PATH .. "/collectUndonesFromFile.sh %q", relativeFilename)
            -- output, err = shell.RunCommand(cmd)
            shell.JobSpawn("sh", { "-c", cmd }, function(input) return end, function(input) return end,
            function(input)
                onExit(input); return
            end, "")
        end
    end

    --
    -- synchronously generate and display references of tags and links for showing in sidepane
    --
    function asyncUpdatePaneWithIndex(relativeFilename)
        local dirname, filename = getDirNameAndFile(relativeFilename)
        local tag_word = ""
        function onExit(contents)
            local headingtext = ""
            if contents == nil or contents == "" then
                headingtext = "Not found any cross-references of this tag file"
            else
                local pwd, shortFilename = getDirNameAndFile(relativeFilename)
                -- headingtext = "[Index] to '" .. tag_word .. "'"
                headingtext = tag_word
            end
            micro.InfoBar():Message("Showing index for " .. tag_word)
            callbackPaneUpdate(relativeFilename, FILE_META_SUFFIXES.index, contents, headingtext)
        end

        local word = getLinkTagsUnderCursor(bp)
        if word ~= "" then
            tag_word = word
            micro.InfoBar():Message("Please wait: Fetching cross-references index for '" .. tag_word .. "' (under cursor in sidebar)")
        else 
            tag_word = strStripExtension(filename)
            micro.InfoBar():Message("Please wait: Fetching index for " .. filename)
        end

        -- if strContains(tagnameFromFile, ".") then
        --     tagnameFromFile = string.gsub('take last xyz.abc.thistag')
        -- end
        local dev_args = ""
        if TOJOUR_DEVMODE then dev_args=" --stats " end
        local cmd = string.format("python " .. HELPER_SCRIPT_PATH .. "/todobuddy.py " .. dev_args .. " --tag '" .. tag_word .. "'")
        local cmd = string.format("python %s/todobuddy.py %s --tag %q", HELPER_SCRIPT_PATH, dev_args, tag_word)

        shell.JobSpawn("sh", { "-c", cmd }, function(input) return end, function(input) return end,
        function(input)
            onExit(input); return
        end, "")
    end

    return run()
end

function TJPanes:resizePanes()
    -- if MAIN_PANE_WIDTH_PERCENT <= 0 then MAIN_PANE_WIDTH_PERCENT = 66 end
    -- local newwidth = math.floor(FULLWIDTH * MAIN_PANE_WIDTH_PERCENT / 100 + 0.5)
    if self.panescount == 1 then
        -- if the old tab had been closed, reinitialise
        devlog("reiniting TJPanes in resize")
        self:new()
    end
    if self.panescount > 1 then
        devlog("resizing mainpane % to " .. MAIN_PANE_WIDTH_PERCENT)
        local newwidth = math.floor(self.fullwidth * MAIN_PANE_WIDTH_PERCENT / 100 + 0.5)
        local cp = TJPanes.panesArray[1]
        cp:ResizePane(newwidth)
        TJPanes:redrawTocIfActive()
        return true
    end
    devlog('not resizing')
    return false
end

-- actually split the pane and open file
function TJPanes:createNewSidePane(content, panename, focusNewPane)
    devlog("creating new sidepane with " .. MAIN_PANE_WIDTH_PERCENT)
    -- close the old second pane, so we can refresh it with new content on toggle (nothing else seems to work here)
    if TJPanes.panescount == 2 then
        TJPanes.panesArray[2]:Quit()
    end
    local b = buffer.NewBuffer(content, panename)
    b.Type.Scratch = true
    b.Type.Readonly = true
    micro.CurPane():VSplitIndex(b, true)

    if focusNewPane == false then
        local tab = micro.CurTab()
        -- do not focus the split tab
        tab:SetActive(0)
    end

    self:resizePanes()
end

function cmdCloseSidePane()
    local panes = TJPanes:new()
    if panes.panescount > 1 then
        panes.panesArray[2]:Quit()
    end
end


TJSession = {}
-- Initialise a new TJSession instance, which contains all tabs and wordcount, sidepane, and toc_level
-- Structure: TJSession[project_pwd][file_path_in_tab] = { pane, wordcount, toc_level }
function TJSession:new()
    local project_pwd = os.getenv("PWD")
    if self[project_pwd] == nil and project_pwd ~= nil then
        self[project_pwd] = {}
    end

    for tabIdx, tab in userdataIterator(micro.Tabs().List) do
        local path = ""
        for paneIdx, pane in userdataIterator(tab.Panes) do
            if paneIdx == 1 then
                path = pane.Buf.Path
                if self[project_pwd][path] == nil then
                    self[project_pwd][path] = {}
                    self[project_pwd][path].sidepane = ""
                    self[project_pwd][path].wordcount = ""
                    self[project_pwd][path].toc_level = 3
                end
            elseif paneIdx == 2 then
                -- Store the type of pane (if one is open)
                self[project_pwd][path].sidepane = getPaneMetaname(pane.Buf.Path)
            end
        end
    end
    return self
end

function TJSession:get(attribute)
    local project_pwd = os.getenv("PWD")
    local curtab = micro.CurTab()
    for paneIdx, pane in userdataIterator(curtab.Panes) do
        if paneIdx == 1 then
            return self[project_pwd][pane.Buf.Path][attribute]
        end
    end
end

function TJSession:set(attribute, value)
    local project_pwd = os.getenv("PWD")
    local curtab = micro.CurTab()
    for paneIdx, pane in userdataIterator(curtab.Panes) do
        if paneIdx == 1 then
            self[project_pwd][pane.Buf.Path][attribute] = value
        end
    end
end

function TJSession:getSidepane()
    return self:get('sidepane')
end

function TJSession:setSidepane(val)
    return self:set('sidepane', val)
end

function TJSession:getWordcount()
    return self:get('wordcount')
end

function TJSession:setWordcount(val)
    self:set('wordcount', val)
end

function TJSession:getTocLevel()
    return self:get('toc_level')
end

function TJSession:setTocLevel(val)
    return self:set('toc_level', val)
end

function TJSession:serializeSession(session_data)
    local filename_escape_char="╡"
    local line_escape_character=':'
    function unescape_filename(filename)
        local out = filename
        out = string.gsub(out, "_", filename_escape_char)
        out = string.gsub(out, "/", "_")
        return out
    end
    local lines = ""
    local session_pwd_file_name = ""
    for workingdir, sessiontable in pairs(session_data) do
        if type(sessiontable) ~= "function" then
            session_pwd_file_name = unescape_filename(workingdir)
            for filepath, file_state in pairs(sessiontable) do
                lines = lines .. filepath .. line_escape_character
                for k, file_attribute in pairs(file_state) do
                    if file_attribute == "" or file_attribute == nil then
                        file_attribute = '""'
                    end
                    lines = lines .. tostring(file_attribute) .. line_escape_character
                end
                lines = lines .. "\n"
            end
        end
    end
    return session_pwd_file_name, lines
end


function TJSession:deserializeSession(project_pwd, sessionlines)
    local filename_escape_char="╡"
    local line_escape_character=':'
    function unescape_filename(filename)
        local out = filename
        out = string.gsub(out, "_", "/")
        out = string.gsub(out, filename_escape_char, "_")
        return out
    end

    local lines = strExplode(sessionlines, "\n")
    local session = {}
    project_pwd = unescape_filename(project_pwd)
    session[project_pwd] = {}
    for i, line in pairs(lines) do
        local line_parts = strExplode(line, line_escape_character)
        local last_path = ""
        for k, part in pairs(line_parts) do
            if part == '""' then part = "" end
            if k == 1 then
                last_path = part
                session[project_pwd][last_path] = {}
            elseif k == 2 then
                session[project_pwd][last_path].pane = part
            elseif k == 3 then
                session[project_pwd][last_path].wordcount = part
            elseif k == 4 then
                session[project_pwd][last_path].toc_level = part
            end
        end
    end
    return session
end

function cmdTOCIncrement(bp)
    local session = TJSession:new()
    local toc_level = session:getTocLevel()
    if toc_level < 6 then
        session:setTocLevel(toc_level + 1)
        micro.InfoBar():Message("Increased sidepane TOC Heading level to " .. toc_level + 1)
    else
        micro.InfoBar():Message("Can't increase sidepane TOC Heading level above 6 (lower with Alt-Shift-o)")
    end
    TJPanes:refreshSidePaneIfHasContext(true)
end

function cmdTOCDecrement(bp)
    local session = TJSession:new()
    local toc_level = session:getTocLevel()
    if toc_level > 1 then
        session:setTocLevel(toc_level - 1)
        micro.InfoBar():Message("Decreased sidepane TOC Heading level to " .. toc_level - 1)
    else
        micro.InfoBar():Message("Can't increase sidepane TOC Heading level below 1 (increase with Alt-o)")
    end
    TJPanes:refreshSidePaneIfHasContext(true)
end


FileLink = {}
FileLink.rawlink = ""
FileLink.linenum = 0
FileLink.anchorlink = ""
FileLink.filewithpath = ""
FileLink.ext = ""
FileLink.exists = false
FileLink.tabid = false
FileLink.isurl = false
 
-- FileLink.paneid = false

-- Private method pseudo-constructor to initialise a new FileLink
-- Do not call this directly but instead:
-- FileLink:openInternalDocumentLink(filestring), or
-- FileLink:openFileInCurrentTab(filestring)
function FileLink:new(filestring)
   filestring = strings.TrimSpace(filestring)
   self.rawlink = filestring
   self.linenum = 0
   self.anchorlink = ""
   self.filewithpath = filestring
   self.ext = ""
   self.exists = false
   self.tabid = nil -- we are using the globals here for tabid
   self.isurl = false 
--    self.paneid = nil

    local function onFileFound()
        self.exists = true
        tabid, paneid = findTabname(self.filewithpath)
        if tabid ~= nil then
            devlog("confirmed TABNAME exists with " .. self.filewithpath)
            -- devlog("tabid " .. tabid)
            self.tabid = tabid
            self.paneid = paneid
        end
        if self.anchorlink ~= "" then
            local linenumber = FileLink:getLinenumMatchingTextInFile(self.filewithpath, self.anchorlink, true)
            if linenumber > 0 then
                self.linenum = tonumber(linenumber)
            end
        end
        devlog(self)
        return self
    end

    if strStartswith(self.filewithpath, "https?://") then
        self.isurl = true
        return onFileFound()
    end

    -- Do poor man's shell expansion of ~tilde and $HOME here already, so lua has access
    if strStartswithStrict(self.filewithpath, "~") then
        self.filewithpath = string.gsub(self.filewithpath, "^~", HOME_DIR)
    elseif strStartswithStrict(self.filewithpath, "$HOME") then
        self.filewithpath = string.gsub(self.filewithpath, "^$HOME", HOME_DIR)
    elseif strStartswithStrict(self.filewithpath, "MICRO_CONFIG") then
        self.filewithpath = string.gsub(self.filewithpath, "^MICRO_CONFIG_DIR", config.ConfigDir)
    end

    -- get linenumbers:123 (if available)
   if strEndsswith(self.filewithpath, ":[0-9]+") then
        -- tonumber needs (()) double brackets to actually convert here strangely
        self.linenum = tonumber((string.gsub(filestring, ".*:([0-9]+)$", "%1")))
        self.filewithpath = string.gsub(filestring, "^(.*):[0-9]+$", "%1")
   end

    -- we probably just found an internal pseudo-anchor markdown link like '#feature-heading' or 'filename#heading-name'
    if strEndsswith(self.filewithpath, "#[a-zA-Z0-9-]+") then
        local fragments = strExplode(self.filewithpath, "#")
        -- local anchor_link = ""
        -- local filename = fragments[1]
        if #fragments == 1 then
            -- '#link-like-this', so internal anchor and get currentpane name as filename
            self.anchorlink = fragments[1]
            local panes = TJPanes:new()
            self.filewithpath = panes:getLeftPaneFilename()
        else
            self.anchorlink = fragments[2]
            -- assign prelim anchor tag
            self.filewithpath = fragments[1]
        end
        -- replace all spaces with space search (with optional leading space . for punctuations like ':' and ' - ' etc)
        self.anchorlink = string.gsub(self.anchorlink, "%-", "\\s?.?\\s?")
        -- replace beginning with regex looking for up to 6 headings
        self.anchorlink = string.gsub(self.anchorlink, "^", "[#]{1,6}[ ]+")
        self.anchorlink = string.gsub(self.anchorlink, "$", ".?")
        -- onFileFound finally looks whether the anchortag actually exists in a file...
    end

   -- try to find the file as given
    self.ext = getFileExtension(self.filewithpath)
    if fileExists(self.filewithpath) then
        devlog("file exists plainly: " .. self.filewithpath)
        return onFileFound()
    end
    
    -- TODO: should we also add currentPaneDirname for file and look for it? 
    -- local currentPaneDirname, filename = getDirNameAndFile(bp.Buf.Path)
   -- if fileExists(currentPaneDirname .. linkstring) then
   
   -- try adding .md to the end and see if the file exists
   -- (but do not double-add md to the end)
    -- if self.ext == "" or self.ext ~= "md" then
    -- end
    if fileExists(self.filewithpath .. ".md") then
        devlog("found only after added md: " .. self.filewithpath)
        self.filewithpath = self.filewithpath .. ".md"
        self.ext = "md"
        return onFileFound()
    end

   -- last ditch effort to search for file and find first unique hit, if possible
    --    local cmd = string.format("sh -c \"find -type f -not -path '.git' -iwholename '%s' \"", "*/" .. self.filewithpath .. "")
    -- local cmd = string.format("sh -c \"find -type f -not -path '*/.*' \\( -iwholename '%s' -o -iwholename '%s' \\) \"", "*/" .. self.filewithpath .. "", "*/" .. self.filewithpath .. ".md")
    -- local cmd = string.format("sh -c \"fd --type f --full-path '.*/%s(\\.md)?$' ./ \"", self.filewithpath)
    local searchstring = '.*/' .. self.filewithpath .. '(\\.md)?$'
    local cmd = string.format("sh -c 'fd --type f --full-path %q ./ '", searchstring)
    local output, err = shell.RunCommand(cmd)
    if output ~= "" then
        local lines_count = select(2, output:gsub("\n", "\n"))

        if lines_count == 1 then
            output = string.gsub(output, "%c", "")
            if fileExists(output) then
                self.filewithpath = output
                self.ext = getFileExtension(self.filewithpath)
                devlog("found by find: " .. self.filewithpath)
                return onFileFound()
            end
        elseif lines_count > 1 then
            output = string.gsub(output, '"', "'")
            cmd = string.format('sh -c \'echo %q | fzf --prompt "Jump to root tag document [Esc to search all tags]: " --select-1 --exit-0\'', output)
            local fzf, fzf_err = shell.RunInteractiveShell(cmd, false, true)
            if fzf ~= "" then
                fzf = string.gsub(fzf, "%c", "")
                if fileExists(fzf) then
                    self.filewithpath = fzf
                    self.ext = getFileExtension(self.filewithpath)
                    devlog("found by fzf: " .. self.filewithpath)
                    return onFileFound()
                end
            end
        end

    end
    devlog("nothing found of " .. self.rawlink .. " with filepath " .. self.filewithpath)
    return self
end

--
-- open an internal link semi-intelligently (but also dumbly)
-- word can include :123 line number at the end
--
function FileLink:openInternalDocumentLink(bp, filestring)
    self:new(filestring)
    
    if self.isurl then
    -- TODO: Add configurable/optional prompt before opening external links?
        bp.RunCmd(bp, { "xdg-open", filestring })
        return true
    end
    
    if self.exists then
        -- micro.InfoBar():Message("Opening link in external viewer: " .. self.filewithpath)     
        -- If there is a direct link to an image file
        if self.ext == "png" or self.ext == "jpeg" or self.ext == "jpg" or self.ext == "gif" or self.ext == "webp" then
            local viewer = tostring(config.GetGlobalOption("tojour.imageviewer"))
            if viewer == "" then viewer = "xdg-open" end
            micro.InfoBar():Message("Opened in image in " .. viewer .. ": " .. self.filewithpath)
            bp.RunCmd(bp, { viewer, self.filewithpath })
            return true
        end
        -- If there is a direct link to a pdf file
        if self.ext == "pdf" then
            micro.InfoBar():Message("Opened file in external default viewer: " .. self.filewithpath)
            bp.RunCmd(bp, { "xdg-open", self.filewithpath })
            return true
        end
    end
    
    if self.tabid ~= nil then
        return self:_switchToTabWithFile(bp)
    end

    if self.exists then
        return self:_openFile(bp, true)
    else
        -- Creates a new file if it doesnt exist yet
        return self:_createNew(bp, true)
    end
end

function FileLink:getLinenumMatchingTextInFile(file, linetext, regex)
    local strict_rg_arg = "--ignore-case "
    if regex == false then
        strict_rg_arg = "--fixed-strings "
    end
    -- tries --fixed-strings to disable regex
    -- need -e for rg leading - dash matching, like in todo items
    local cmd = string.format("rg --max-count 1 %s --line-number -e %q %q | awk -F: '{print $1}'", strict_rg_arg, linetext, file)
    local linenumber, err = shell.RunCommand(string.format("sh -c %q", cmd))
    if err ~= nil then
        devlog("error in ripgrep looking for line number in file")
    end
    if linenumber ~= "" then
        return tonumber(linenumber)
    end
    return 0
end


function FileLink:openFileInCurrentTab(bp, filestring)
    self:new(filestring)
    local dirname, filename = getDirNameAndFile(self.filewithpath)
    if strStartswith(dirname, "%./") then
        dirname = string.gsub(dirname, "^%./", "")
    end
    self:_openFile(bp, false)
end

--
-- open buffer in a new tab, or switch to existing tab if open alrady
--
function FileLink:_switchToTabWithFile(bp)

    -- devlog("existing tab alrady found")
    tabs = micro.Tabs()
    tabs:SetActive(self.tabid - 1)
    tab = micro.CurTab()
    tab:SetActive(self.paneid - 1)

    if self.linenum > 0 then
        micro.CurPane().Cursor.Y = self.linenum - 1
    end

    -- refresh second pane if it exists
    TJPanes:refreshSidePaneIfHasContext()
    return true
end


function FileLink:_createNew(bp, newtab)
    if self.ext == "" or self.ext ~= "md" then
        self.filewithpath = self.filewithpath .. ".md"
        self.ext = "md"
    end
    -- -- Ask to create a new file if it doesn't exist yet
    micro.InfoBar():Prompt("Create new file '" .. self.filewithpath .. "'? [press 'y' to proceed]): ", "", "search", function(input)
        return
    end, function(input, canceled)
        if not canceled and ( input == "y" or input == "Y" or input == "yes") then
            local yaml_frontmatter = "---\ntitle: " .. strStripExtension(self.filewithpath) .. 
            "\ncreated: " .. getDateString(0) .. 
            "\n---\n"
            shell.RunCommand(string.format("sh -c 'echo \"%s\" > %q '",  yaml_frontmatter, self.filewithpath))
            -- it didn't exist yet, but it does now!
            self.exists = true
            FileLink:_openFile(bp, newtab)
        else
            micro.InfoBar():Message("Cancelled " .. input)
            return
        end
    end)
end

function FileLink:_openFile(bp, newtab)
    self.filewithpath = strings.TrimSpace(self.filewithpath)
    micro.InfoBar():Message("Opening link: " .. tostring(self.filewithpath))

    local buf, err = buffer.NewBufferFromFile(self.filewithpath)
    if err == nil then
        if newtab == true then
            bp.addTab(bp)
        end
        micro.CurPane():OpenBuffer(buf)
        if self.linenum > 0 then
            micro.CurPane().Cursor.Y = self.linenum - 1
        end
    end
    -- Get new instance of newly opened file, and potentially open a sidepane
    return openAppropriateContextSidePane()
end


--
-- Events you can hook to: https://github.com/zyedidia/micro/issues/875
-- Sends InfoBar Message with first todo point, on every save Event (excluding autosave)
--
function onSave(bp)
    if not isMarkdown() then return false end

    TJPanes:refreshSidePaneIfHasContext()
end

function isCurfileTodayfile(bp)
    return bp.Buf.Path == getDateString() .. ".md"
end

function onRune(rune)
    if not isMarkdown() or config.GetGlobalOption("tojour.potatomode") == true then return false end

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
    if not isMarkdown() then return false end

    micro.InfoBar():Message("")
    TJPanes:refreshSidePaneIfHasContext()
end

function onPreviousTab()
    if not isMarkdown() then return false end

    micro.InfoBar():Message("")
    TJPanes:refreshSidePaneIfHasContext()
end

-- function preNextSplit()
--     if not isMarkdown() then return false end

--     TJPanes:refreshSidePaneIfHasContext()
--     -- micro.InfoBar():Message("")
-- end

function onNextSplit()
    if not isMarkdown() then return false end

    TJPanes:refreshSidePaneIfHasContext()
    -- micro.InfoBar():Message("")
end

function onMousePress()
    if not isMarkdown() then return false end
    -- save file
    TJPanes:redrawTocIfActive()
end

-- Hacky attempt to bind ctrl-alt-h without deleting the left word (but instead jumping left and right)
-- function preDeleteWordLeft()
--     if not isMarkdown() then return true end
--     local curPane = micro.CurPane()
--     curPane:WordLeft()
--     return false
-- end

-- TODO: bearable but still a tiny bit too slow, even with job spawn and debounce
function onCursorUp()
    if not isMarkdown() or config.GetGlobalOption("tojour.potatomode") == true then return false end
    TJPanes:redrawTocIfActive()
end

function onCursorDown()
    if not isMarkdown() or config.GetGlobalOption("tojour.potatomode") == true then return false end
    -- save file
    TJPanes:redrawTocIfActive()
end

function onCursorPageUp()
    if not isMarkdown() or config.GetGlobalOption("tojour.potatomode") == true then return false end
    TJPanes:redrawTocIfActive()
end

function onCursorPageDown()
    if not isMarkdown() or config.GetGlobalOption("tojour.potatomode") == true then return false end
    TJPanes:redrawTocIfActive()
end

--
-- Trigger autocomplete if we start a tag with # or [[
--
function onRuneTriggerTagAutocomplete()
    if not isMarkdown() then return false end
    local word = getWordUnderCursor()

    if string.find(word, "#[^%s#]$") then
        -- Replace #tagnames after first letter pressed
        local bp = micro.CurPane()
        local selectedTag = showTags(bp, "Insert #tag: ", string.gsub(word, "^#", ""))
        if selectedTag ~= "" then
            micro.CurPane():Backspace()
            if strContains(selectedTag, " ") then
                -- if we have a space in our tag, then use square brackets instead of #
                selectedTag = "[[" .. selectedTag .. "]]"
                micro.CurPane():Backspace()
            end
            selectedTag = selectedTag .. " "
            insertTextAtCursor(bp, selectedTag)
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
            insertTextAtCursor(bp, selectedTag)
        end
    end
end


function cmdTogglePaneFocus(curpaneId)
    if not isMarkdown() then return false end

    micro.CurPane():NextSplit()
end

function cmdOpenFirstPane()
    if not isMarkdown() then return false end
    TJPanes:new()
    if TJPanes.panescount > 1 and TJPanes.curpaneId > 1 then
        tab = micro.CurTab()
        tab:SetActive(0)
        -- Disable debounce here (so we get live updates when we switch back)
        DEBOUNCE_GET_TOC = false
    end
end

function cmdOpenSecondPane()
    if not isMarkdown() then return false end
    TJPanes:new()
    if TJPanes.panescount > 1 and TJPanes.curpaneId == 1 then
        tab = micro.CurTab()
        tab:SetActive(1)
    elseif TJPanes.panescount == 1 then
        TJPanes:openSidePaneWithContext('placeholder', false)
        tab = micro.CurTab()
        tab:SetActive(1)
        openAppropriateContextSidePane()
    end
end

--
-- For attaching shortcuts to sidepane openers without arguments
--
function cmdToggleSidePaneIndex(bp)
    if not isMarkdown() then return false end

    TJPanes:openSidePaneWithContext('index', false)
end

function cmdToggleSidePaneTOC(bp)
    if not isMarkdown() then return false end

    TJPanes:new()
    local metaSuffix = ""
    for paneIdx, pane in ipairs(TJPanes.panesArray) do
        local dirname, filename = TJPanes:getPaneDirAndFilename(pane)
        metaSuffix = getPaneMetaname(filename)
    end
    if metaSuffix == "toc" then
        -- if a TOC pane is already open, increment TOC
        cmdTOCIncrement()
    else
        TJPanes:openSidePaneWithContext(FILE_META_SUFFIXES.toc, false)
    end
end

function cmdToggleSidePaneUndone(bp)
    if not isMarkdown() then return false end

    TJPanes:openSidePaneWithContext(FILE_META_SUFFIXES.undone, false)
end

function cmdToggleSidePaneTree(bp)
    if not isMarkdown() then return false end

    TJPanes:openSidePaneWithContext(FILE_META_SUFFIXES.tree, false)
end

function cmdSidepaneResizeUp(bp)
    local panes = TJPanes:new()
    MAIN_PANE_WIDTH_PERCENT = MAIN_PANE_WIDTH_PERCENT + 3
    panes:resizePanes()
    config.SetGlobalOptionNative("tojour.mainpanewidth", MAIN_PANE_WIDTH_PERCENT)
end

function cmdSidepaneResizeDown(bp)
    local panes = TJPanes:new()
    MAIN_PANE_WIDTH_PERCENT = MAIN_PANE_WIDTH_PERCENT - 3
    panes:resizePanes()
    config.SetGlobalOptionNative("tojour.mainpanewidth", MAIN_PANE_WIDTH_PERCENT)
end

--
-- generic string heading creator to be used above a virtual sidepane
--
function createContextHeading(heading, context_type)
    local function strCapitalise(str)
        return string.upper(string.sub(str, 1, 1)) .. string.sub(str, 2, -1)
    end
    local pane_menu = ""
    for key, val in pairs(FILE_META_SUFFIXES) do
        if pane_menu ~= "" then
            pane_menu = pane_menu .. " | "
        end
        if val ~= context_type then
            -- insert capitalised meta suffix name into 'menu'
            pane_menu = pane_menu .. "[" .. strCapitalise(val) .. "]"
        else
            pane_menu = pane_menu .. "" .. strCapitalise(val) .. ""
        end
    end
    -- pane_menu = "" .. strCapitalise(context_type) .. " | " .. pane_menu
    pane_menu = FILE_META_MENU_START .. pane_menu
    return FILE_META_HEADER_BEGIN .. heading .. "\n" .. pane_menu .. "\n\n"
end

--
-- Finds textstring in all files fast with ripgrep
--
function cmdFindTextInAllFiles(bp)
    if not isMarkdown() then return false end

    -- FZF search for strings in files, with follow up file opener
    local cmd = string.format("bash " .. HELPER_SCRIPT_PATH .. "/findInAllFiles.sh")
    local output, err = shell.RunInteractiveShell(cmd, false, true)
    if err ~= nil then
        micro.InfoBar():Error(tostring(err) .. ": " .. output)
    elseif output ~= "" then
        FileLink:openInternalDocumentLink(bp, output)
    end
end

function cmdHandleMouseEvent(bp, tcell)
    -- Click the mouse again, but only if tcell / mousepress exists in this tty / micro
    if type(tcell) ~= 'nil' then
        bp:MousePress(tcell)
    end
    if cmdFollowInternalLink(bp) == false then
        local line = getLineAtCursor(bp)
        if string.find(line, "%- %[[ x/-]%]|[%*%[%] \t-]TODO") then
            cmdToggleCheckbox(bp)
        end
    end
end

--
-- Grab word under cursor and follow it in new window if it's a link
--
function cmdFollowInternalLink(bp)
    if not isMarkdown() then return false end
    
    local function jumptoLineMatchInPrimaryPanel()
        local panes = TJPanes:new()
        -- if we're in a TOC table of contents file or Undones file sidepane
        local cursor = micro.CurPane().Cursor
        local localbuffer = micro.CurPane().Buf
        local line = localbuffer:Line(cursor.Y)
        -- parse internal menu 'button' from createContextHeading
        -- if strStartswithStrict(line, FILE_META_MENU_START) then
        if strStartswithStrict(line, FILE_META_HEADER_BEGIN) then
            devlog("Special contextHeader 'menu' block detected")
            local link = getLinkTagsUnderCursor(bp)
            if link == "++" then
                return cmdTOCIncrement(bp)
            elseif link == "--" then
                return cmdTOCDecrement(bp)
            elseif link then
                TJPanes:openSidePaneWithContext(string.lower(link))
                return true
            end
        end

        -- remove line numbers from TOC at the end
        line = string.gsub(line, "[%s]*[0-9]*$", "")
        -- remove TOC '>' cursor from beginning of line
        line = string.gsub(line, "^%>", "")
        -- strip out the space in the first column added by generateTOC or indents to space things more nicely
        line = string.gsub(line, "^[ \t]*", "")
        -- looks for <via: [link] > strings produced by collectUndonesFromFile, when ref is to a todo in another file
        if strEndsswith(line, "%<via: %[.*%] %>") then
            local link = string.gsub(line, "^.*%<via: %[(.*)%] %>$", "%1")
            if link then
                FileLink:openInternalDocumentLink(bp, link)
                return true
            end
        end

        -- in the index view, we don't want to do more advanced sidepane jumps
        -- but just to follow normal links
        if isPanenameMetapane(micro.CurPane().Buf.Path, FILE_META_SUFFIXES.index) then
            return false
        end
        

        -- get the left pane and search it
        -- local panes = TJPanes:new()
        firstpaneName = panes:getLeftPaneFilename()
        -- local linenumber = FileLink:getLinenumMatchingTextInFile(firstpaneName, line, false)
        local cp = panes.panesArray[1]
        cp.Buf.LastSearchRegex = false
        cp.Buf.LastSearch = line
        devlog("Did text-find for: " .. line)
        -- alas Findnext just seems to always return a true bool, so hard to react if nothing found (could figure out with terrible pane logic instead)
        if cp:FindNext() then
            DEBOUNCE_GET_TOC = false
            DEBOUNCE_GET_SIDEPANE = false
            return true
        end
        DEBOUNCE_GET_TOC = false
        DEBOUNCE_GET_SIDEPANE = false
        micro.InfoBar():Message("Couldn't find line '" .. line .. "' in left pane...")
        return false
        -- TODO: else find a ## [[tagname]] in a line above, and try finding the line in that file?
    end

    -- if we're in a META sidepane like toc, undone
    -- then try searching for special <via tags, commands or matching lines in left pane
    local curpaneName = micro.CurPane().Buf.Path
    for i, meta in pairs(FILE_META_SUFFIXES) do
        -- if isPanenameMetapane(curpaneName, FILE_META_SUFFIXES.toc) or isPanenameMetapane(curpaneName, FILE_META_SUFFIXES.undone) then
        if isPanenameMetapane(curpaneName, meta) then
            if jumptoLineMatchInPrimaryPanel() then
                devlog('jumping to line match in primary pane')
                return true
            end
        end
    end

    word = getLinkTagsUnderCursor(bp)
    if word ~= nil and word ~= "" then
        if FileLink:openInternalDocumentLink(bp, word) then
            return true
        end
    end
    return false
end

function cmdOpenTodayFile(bp)
    local todayFile = getDateString(0) ..'.md'
    
    -- bounce to previous selected tab (if there was one)
    -- TODO: Improve this maybe for on every tab switch?
    local curTabFilename = getRelativeFilepathOfCurrentPane()
    if todayFile == curTabFilename then
        -- micro.InfoBar():Message("already on todayfile")
        if PREVIOUS_TAB_FILENAME ~= "" then
            -- micro.InfoBar():Message("opening " .. PREVIOUS_TAB_FILENAME)
            FileLink:openInternalDocumentLink(bp, PREVIOUS_TAB_FILENAME)
        end
        return true
    end
    PREVIOUS_TAB_FILENAME=curTabFilename

    -- if autobuilding is enabled, then create the today file and run a defined buildscript (default todobuddy)
    if config.GetGlobalOption("tojour.autobuildtoday") then
        if not fileExists(todayFile) then
            local file = io.open(todayFile, "w")
            file:write()
            file:close()
            local output, err = shell.RunCommand("bash -c \"" .. tostring(config.GetGlobalOption("tojour.buildscript")) .. "\"")
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

-- semi-intelligently figures out whether there's a followable link under cursor
-- API: we want this to ALWAYS return a file path of some sort as string (or a url)
function getLinkTagsUnderCursor(bp)
    function run()
        local wordUnderCursor = getWordUnderCursor()
        devlog("word under cursor would be: " .. wordUnderCursor)

        -- special - this is NOT an internal link but external. 
        -- therefore bail out and handle diff?
        if strStartswithStrict(wordUnderCursor, "https://") then
            return string.gsub(wordUnderCursor, "[%)]$", "")
        end

        -- TODO: Allow executing bash code here in some special syntax?
        -- shorcuts like bash -c 'git add . && git commit -m "saved"'
        -- code within md? cute (though dangerous?) 
        -- But basically like jupyter notebooks (without graphics)
        -- or py: (no, not a word, needs another cmd - alt-b)

        -- strip some trailing punctuation in words
        wordUnderCursor = string.gsub(wordUnderCursor, "[:;,%.]$", "")

        if strStartswithStrict(wordUnderCursor, "[[") and strEndsswithStrict(wordUnderCursor, "]]") then
            -- devlog("Found hashtag style link early: " .. wordUnderCursor)
            local link = string.gsub(wordUnderCursor, "^%[%[", "")
            return string.gsub(link, "%]%]$", "")
        end

        if strStartswithStrict(wordUnderCursor, "[") and strEndsswithStrict(wordUnderCursor, "]") then
            -- devlog("Found wiki style link early: " .. wordUnderCursor)
            local link = string.gsub(wordUnderCursor, "^%[", "")
            link = string.gsub(link, "%]$", "")
            -- we want to avoid triggering on a checked checkbox
            if link ~= "x" then
                return link
            end
        end
        
        if strStartswithStrict(wordUnderCursor, "#") then
            -- devlog("Found hashtag style link early: " .. wordUnderCursor)
            return string.gsub(wordUnderCursor, "^#", "")
        end
        
        -- markdown link finder (the start of the word might be a space or a [)
        -- but does NOT work when [cusorishere whenspaces here](https://link) without change to getWordUnderCursor or new bespoke parser just for this
        if strEndsswithStrict(wordUnderCursor, ")") and strStartswith(wordUnderCursor, "!?%[?[^%s]+%]%(") then
            if string.find(wordUnderCursor, ".*%]%((https?://.*)%)$") then
                -- Caught https?:// links
                return string.gsub(wordUnderCursor, ".*%]%((https?://.*)%)$", "%1")
            elseif string.find(wordUnderCursor, ".*%]%((.*#.*)%)$") then
                -- Caught #internal-doc-jump
                return string.gsub(wordUnderCursor, ".*%]%((.*#.*)%)$", "%1")
            -- elseif string.find(wordUnderCursor, "[a-z0-9A-z]+%]%((.*)%)$") then
            else
                -- Caught #internal-doc-jump
                return string.gsub(wordUnderCursor, ".*%]%((.*)%)$", "%1")
            end
        end
        -- if strStartswithStrict(wordUnderCursor, "(") and strEndsswithStrict(wordUnderCursor, "]") then
        --     -- devlog("Found wikilinky early (..]: " .. wordUnderCursor)
        -- end
        -- if strStartswithStrict(wordUnderCursor, "(") and strEndsswith(wordUnderCursor, "]") then
        --     -- devlog("Found wikilinky early (..]: " .. wordUnderCursor)
        --     -- return wordUnderCursor
        -- end
        -- if strEndsswithStrict(wordUnderCursor, ".md") then
        -- if strEndsswith(wordUnderCursor, "%.md") then
        --     -- devlog("Found md early: " .. wordUnderCursor)
        --     return strStripExtension(wordUnderCursor)
        -- end

        micro.InfoBar():Message("No #link, [[link]], [link] or https url found under current cursor in '" .. wordUnderCursor .. "'")
        return ""
    end

    return run()
end


function openAppropriateContextSidePane()
    if config.GetGlobalOption("tojour.alwaysopencontextpane") == false and config.GetGlobalOption("tojour.alwaysopentodayundone") == false then
        return false
    end

    bp = micro.CurPane()
    TJPanes:new()
    local session = TJSession:new()
    local sidepane = session:getSidepane()
    if sidepane ~= "" then
        TJPanes:openSidePaneWithContext(sidepane, false)
        return true
    end

    if isCurfileTodayfile(bp) and config.GetGlobalOption("tojour.alwaysopentodayundone") == true then
        -- open a todo side pane if we are on today's file
        TJPanes:openSidePaneWithContext(FILE_META_SUFFIXES.undone, false)
        return true
    elseif isMarkdown() and config.GetGlobalOption("tojour.alwaysopencontextpane") ~= false then
        -- Allow valid options true, 'toc', 'index', 'undone'
        -- if a file is in a subdirectory, then it's likely a tag, so open index
        local dirname, file = getDirNameAndFile(bp.Buf.Path)
        -- if it is a 2024-01-01.md file
        -- if string.find(file, "^%d%d%d%d%-%d%d%-%d%d%.md$") then
        --     TJPanes:openSidePaneWithContext(FILE_META_SUFFIXES.toc, false)
        --     return true
        -- end
        -- if (dirname ~= "" and dirname ~= "./") then
        -- if string.find(file, "^[%d%w%.]+%.md$") then
        --     TJPanes:openSidePaneWithContext('index', false)
        --     return true
        -- end
        for key, val in pairs(FILE_META_SUFFIXES) do
            if val == tostring(config.GetGlobalOption("tojour.alwaysopencontextpane")) then
                return TJPanes:openSidePaneWithContext(FILE_META_SUFFIXES[val], false)
            end
        end
        -- fallback if another value like true, just use TOC as default
        return TJPanes:openSidePaneWithContext(FILE_META_SUFFIXES.toc, false)
    end
end

--
-- find if a filename is already open in a tab
--
function findTabname(tabfilename)
    -- notify("found tabfilename: " .. tabfilename)
    for tabIdx, tab in userdataIterator(micro.Tabs().List) do
        for paneIdx, pane in userdataIterator(tab.Panes) do
            -- panes[tonumber(paneIdx)] = pane
            -- devlog(tostring(tabIdx) .. " " .. tostring(paneIdx) .. " " .. pane.Buf.Path)
            local path = pane.Buf.Path
            if path == tabfilename then
                devlog("found tabfilename == " .. tabfilename)
                return tabIdx, paneIdx
            end
            -- also remove leading ./ from URL and try to find a match with the end of the URL
            if strEndsswithStrict(path, string.gsub(tabfilename, "^[%./]*", "")) then
                devlog("Found tab ENDING in " .. tabfilename)
                return tabIdx, paneIdx
            end
        end
    end
    return nil, nil
end

function getWordUnderCursor()
    local cursor = micro.CurPane().Cursor
    local buffer = micro.CurPane().Buf
    local line = buffer:Line(cursor.Y)
    local x = cursor.X
    local start = x
    local finish = x

    -- Adjust start if cursor is at the beginning of the line
    -- Find the start of a word
    while start > 0 and string.match(line:sub(start, start), "[^%s]") do
        -- devlog(line:sub(start, start))
        start = start - 1
    end
    -- add 1 to pick the beginning of word, not the control char
    start = start + 1

    rightStringSeparator = "[^%s,;'\"]"
    -- Find the end of the word
    finish = finish + 1
    while finish <= #line and string.match(line:sub(finish, finish), rightStringSeparator) do
        -- devlog(line:sub(finish, finish))
        finish = finish + 1
    end
    finish = finish - 1

    -- Extract the word
    local word = line:sub(start, finish)
    return tostring(word)
end

function cmdSmarterPaste(bp)
    local c = bp.Cursor
    local cursor = buffer.Loc(c.Loc.X, c.Loc.Y)

    -- paste clipboard, returns a boolean that's more or less always true
    result = bp.paste(bp)

    if not isMarkdown() then return true end

    local cursorAfterPaste = buffer.Loc(c.Loc.X, c.Loc.Y)

    -- if cursor position has shifted since paste
    if cursor ~= cursorAfterPaste then
        micro.InfoBar():Message("Pasted text")
    else
        micro.InfoBar():Message("Pasting image...")
        local currentFilename = getRelativeFilepathOfCurrentPane()
        -- remove extension from filename
        local currentFilename = string.gsub(currentFilename, "%..*$", "")
        local cmd = "bash " .. HELPER_SCRIPT_PATH .. "/pasteImage.sh '" .. currentFilename .. "'"
        local output, err = shell.RunCommand(cmd)
        if err ~= nil then
            micro.InfoBar():Error(tostring(err) .. ": " .. output)
        elseif output ~= "" then
            currentTime = os.date("%Y-%m-%d %H:%M:%S")
            insertTextAtCursor(bp, "![Image " .. currentTime .. "](" .. output .. ")")
            micro.InfoBar():Message("Pasted image: " .. output)
        end
    end
end

--
-- Indent from anywhere in the line
--
function cmdPressTabAnywhereToIndent(bp)
    if not isMarkdown() and not micro.CurPane().Buf:FileType() == 'yaml' then 
        bp:InsertTab()    
        return true 
    end
    bp:IndentLine()
    return true
end

-- inserts configured symbols at the beginning of a line
function cmdInsertLineComment(bp)
    if not isMarkdown() then return false end

    local symbol = tostring(config.GetGlobalOption("tojour.mdcommentprefix"))
    if symbol == "" then
        -- if comment symbol is blank, then use default behaviour
        return false
    end

    return toggleSymbolsStartOfLine(bp, symbol, 1)
end

function cmdInsertHeader1(bp) toggleMdHeader(bp, 1) end
function cmdInsertHeader2(bp) toggleMdHeader(bp, 2) end
function cmdInsertHeader3(bp) toggleMdHeader(bp, 3) end
function cmdInsertHeader4(bp) toggleMdHeader(bp, 4) end
function cmdInsertHeader5(bp) toggleMdHeader(bp, 5) end
function cmdInsertHeader6(bp) toggleMdHeader(bp, 6) end

function toggleMdHeader(bp, level)
    lines = getLineAtCursor(bp)
    symbol = "#"
    spacer = " "
    repetition = level
    if strStartswithStrict(lines, string.rep(symbol, repetition) .. tostring(spacer)) then
        -- If line starts with '### ' already and we're trying to set ### (h3), then toggle it
        toggleSymbolsStartOfLine(bp, "#", level)
        -- line = string.gsub(line, "^" .. symbol .. "*" .. spacer, "")
    elseif strStartswithStrict(lines, symbol) then
        -- if line starts with any other number of single #'s, do a replace
        local c = bp.Cursor
        local new_line = string.gsub(lines, "^" .. symbol .. "*" .. spacer .. "*", string.rep(symbol, repetition) .. tostring(spacer))
        adjustCursorToNewLinelength(bp, new_line, lines)
    else
        -- nothing is here yet, so just do normal toggle
        toggleSymbolsStartOfLine(bp, "#", level)
    end

end


-- Inserts the symbols followed by a whitespace at the beginning of a line
function toggleSymbolsStartOfLine(bp, symbols, repetition)
    -- add symbols and space to the beginning of the line
    local line = getLineAtCursor(bp)
    local old_line = line
    local spacer = " "

    if strStartswithStrict(line, symbols) then
        -- cut out the part of the line from after the symbols and spacer to the end
        if repetition > 1 then
            line = string.gsub(line, "^" .. symbols .. "*" .. spacer, "")
        else
            line = string.sub(line, #(symbols .. spacer) + 1, -1)
        end
        
    else
        symbols = string.rep(symbols, repetition)
        -- add symbols to beginning of line
        if strStartswith(line, '%s') then
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

--
-- Use fzf to allow inserting tags from all files
--
function showTags(bp, prompt, query)
    local cmd = "bash " .. HELPER_SCRIPT_PATH .. "/tagSearch.sh '" .. prompt .. "'"
    if query ~= nil then
        cmd = cmd .. " '" .. query .. "'"
    end
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
    if not isMarkdown() then return false end

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
    insertTextAtCursor(bp, text)
end

function cmdJumpToTag(bp)
    if not isMarkdown() then return false end

    local tag = showTags(bp, "Jump to tag: ")
    if tag == "" then
        return ""
    end

    FileLink:openInternalDocumentLink(bp, tag)
end

--
-- Toggle a checkbox on the current line
--
function cmdToggleCheckbox(bp)
    if not isMarkdown() then return false end

    TJPanes:new()

    if TJPanes.curpaneId > 1 then
        -- if we're in the second pane, toggle the checkbox in the first pane
        cmdFollowInternalLink(bp)
        bp = micro.CurPane()
    end

    -- micro.InfoBar():Message("Toggling checkbox")
    -- Checking for different spellings / variations of a todo list item
    -- notably: `- [ ]` and `- [x]`
    local line = getLineAtCursor(bp)
    if string.find(line, "%- %[ %]") then
        local newline = string.gsub(line, "- %[ %]", "- [x]")
        replaceLineAtCursor(bp, newline, 0)
    elseif string.find(line, "- %[x%]") then
        -- removes checkbox
        -- local newline = string.gsub(line, "- %[x%]%s", "")
        -- untoggles checkbox
        local newline = string.gsub(line, "- %[x%]", "- [ ]")
        replaceLineAtCursor(bp, newline, -6)
    elseif string.find(line, "^[*%[%] \t-]*TODO%s") then
        local newline = string.gsub(line, "^([*%[%] \t-]*)TODO%s", "%1DONE ")
        replaceLineAtCursor(bp, newline, 0)
    elseif string.find(line, "^[*%[%] \t-]*DONE%s") then
        local newline = string.gsub(line, "^([*%[%] \t-]*)DONE%s", "%1TODO ")
        replaceLineAtCursor(bp, newline, 0)
    elseif string.find(line, "- %[/%]") then
        local newline = string.gsub(line, "- %[/%]", "- [ ]")
        replaceLineAtCursor(bp, newline, 0)
    elseif string.find(line, "- %[%-]") then
        local newline = string.gsub(line, "- %[%-%]", "- [ ]")
        replaceLineAtCursor(bp, newline, 0)
    else
        local newline = string.gsub(line, "^(%s*)(.*)$", "%1- [ ] %2")
        replaceLineAtCursor(bp, newline, 6)
    end
    bp:Save()
    TJPanes:refreshSidePaneIfHasContext()
end

-- TODO: Consider refactor of some stuff into
-- TJLineEdit = {}

function incrementPrefixedDateInLine(bp, n)
    if not isMarkdown() then return false end

    TJPanes:new()

    if TJPanes.curpaneId > 1 then
        -- if we're in the second pane, jump to correct place in first pane and carry out action
        cmdFollowInternalLink(bp)
        bp = micro.CurPane()
    end

    local function add_days_to_date(date_string, n)
        -- Parse the input date string
        local year, month, day = date_string:match("(%d+)-(%d+)-(%d+)")
        
        year = tonumber(year)
        month = tonumber(month)
        day = tonumber(day)

        -- Convert the input date to a time table
        local input_date = os.time({year = year, month = month, day = day, hour = 12})

        -- Calculate the new date by adding or subtracting 'n' days
        local new_date = input_date + (n * 24 * 60 * 60)

        -- Convert the new date back to a readable format
        local new_date_table = os.date("*t", new_date)
        -- local today_date = 
        days_diff_from_today = math.floor(os.difftime(new_date, os.time()) / ( 24 * 60 * 60 ) + 1)

        local new_date_string = string.format("%04d-%02d-%02d", new_date_table.year, new_date_table.month, new_date_table.day)
        -- local weekdayInt = string.format("%01d", new_date_table.wday)
        local weekdayTable = {"Sunday", "Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday"} 
        local monthTable = {"January","February","March","April","May","June","July","August","September","October","November","December"}
        human_readable_date = " (" .. weekdayTable[tonumber(new_date_table.wday)] .. ", " .. tostring(new_date_table.day) .. ". " .. monthTable[tonumber(new_date_table.month)] .. ")"
        
        return new_date_string
    end
    
    local line = getLineAtCursor(bp)
    local founddate = ""
    local newdate = ""
    local newline = ""
    human_readable_date = ""
    days_diff_from_today = ""
    local snoozemsg = ""
    
    if string.match(line, "@%d%d%d%d%-%d%d%-%d%d") then 
        founddate = string.match(line, "@%d%d%d%d%-%d%d%-%d%d")
    elseif string.match(line, today_string) then
        founddate = today_string
    elseif string.match(line, tomorrow_string) then
        founddate = tomorrow_string
        -- TODO: Possibly make it aware of @monday, @tuesday etc too
    end

    if founddate ~= "" then
        local normalised_date = ""
        if founddate == today_string then normalised_date = tostring(getDateString(0))
        elseif founddate == tomorrow_string then normalised_date = tostring(getDateString(1))
        else normalised_date = founddate end

        newdate = add_days_to_date(normalised_date, n)

        -- convert the new date to @today, @tomorrow or @2000-01-31 format (or as initialised / configured in settings.json)
        if newdate == tostring(getDateString(0)) then newdate = today_string
        elseif newdate == tostring(getDateString(1)) then newdate = tomorrow_string
        else newdate = date_prefix .. newdate
        end

        -- manually escape the symbols unfortunately for gsub
        newline = string.gsub(line, founddate:gsub("%-", "%%-"), newdate)
        -- days_diff_from_today = " (" .. days_diff_from_today .. " days from today) "
        -- notify("Snoozed by: " .. n .. " days" .. days_diff_from_today .."to " .. newdate .. human_readable_date)
        snoozemsg = "Snoozed " .. days_diff_from_today .." days from today to " .. newdate .. human_readable_date
    else
        -- days_diff_from_today = " "
        snoozemsg = "Marked item to do " .. today_string
        newdate = today_string
        newline = string.gsub(line, "^(.-)%s*$", "%1 " .. today_string)
    end
    replaceLineAtCursor(bp, newline, 0)

    -- save document
    bp:Save()
    TJPanes:refreshSidePaneIfHasContext()
    micro.InfoBar():Message(snoozemsg)
end

function cmdIncrementDaystring(bp)
    incrementPrefixedDateInLine(bp, 1)
end

function cmdIncrementDaystringByWeek(bp)
    incrementPrefixedDateInLine(bp, 7)
end

function cmdDecrementDaystring(bp)
    incrementPrefixedDateInLine(bp, -1)
end

function cmdBrowseDateJournals(bp)
    local datesShow = ""
    local today = ""
    -- Only show journal dates when in a markdown file in journal
    if isMarkdown() then
        today = getDateString() .. ".md"
        local yesterday = getDateString(-1) .. ".md"
        -- local twodaysago = getDateString(-2) .. ".md"
        -- local threedaysago = getDateString(-3) .. ".md"
        local tomorrow = getDateString(1) .. ".md"
        datesShow = 'today:: ./' .. today ..
        ',yesterday:: ./' .. yesterday ..
        ',tomorrow:: ./' .. tomorrow
        for i = 2, 7 do
            datesShow = datesShow .. ',' .. i .. ' days ago:: ./' .. getDateString(-i) .. ".md"
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
    for tabIdx, tab in userdataIterator(micro.Tabs().List) do
        for paneIdx, pane in userdataIterator(tab.Panes) do
            if pane.Buf.Path then
                if fileExists(pane.Buf.Path) and pane.Buf.Path ~= "" then
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

    

    local cmd = string.format("bash " .. HELPER_SCRIPT_PATH .. "/browseJournals.sh %q", extra_lines)

    local output, err = shell.RunInteractiveShell(cmd, false, true)
    if err ~= nil then
        micro.InfoBar():Error(tostring(err) .. ": " .. output)
    else
        if output ~= "" then
            -- do we have a daily file?
            if strContains(output, "::") then
                -- Strip strings before double colons, like yesterday:: ./2021-01-01.md
                -- NB: Also '|' which is hardcoded tab marker
                output = string.match(output, "^[|a-zA-Z0-9 ]+[:][:][ ](.+)$")
                if strContains(output, getDateString() .. ".md") then
                    return cmdOpenTodayFile(bp)
                end
            end

            -- strip leading | which can be introduced as tab indicator above and in browseJournal.sh
            if strStartswithStrict(output, "|") then
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
    if not isMarkdown() then return false end

    bp:Save()
    local buildScript = tostring(config.GetGlobalOption("tojour.buildscript"))
    -- notify("Starting Build script")
    local output, err = shell.RunCommand("bash -c \"" .. buildScript .. "\"")
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
    if not isMarkdown() then return "" end
    if micro.CurPane().Buf:Modified() then
        bp:Save()
    end
    local wordcountmsg = ""
    local wordcountScript = HELPER_SCRIPT_PATH .. "/wordcount.sh"
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
            wordcountmsg = "Word count: " .. tostring(wordcount) .. " (" .. tostring(tonumber(wordcount) - tonumber(oldwc)) .. " this session)"
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
    if not isMarkdown() then return false end

    local output, err = shell.RunInteractiveShell(
    "bash -i " .. HELPER_SCRIPT_PATH .. "/openFilebrowser.sh '" .. tostring(config.GetGlobalOption("tojour.filebrowser")) .. "'", false, true)
    if err ~= nil then
        micro.InfoBar():Error(tostring(err) .. ": " .. output)
    elseif output ~= "" then
        local dirname, filename = getDirNameAndFile(output)
        filename = strings.TrimSpace(filename) -- for some reason there's a whitespace at the end
        FileLink:openInternalDocumentLink(bp, dirname .. filename)
    end
end

function cmdSelectBlock(bp)
    function getMdHeadingLevel(line)
        return #line - #string.gsub(line, "^(%s*)#*(%s)", "%1%2")
    end

    function selectChildBlocks()
        local line_num = getCurrentLineNumber(bp)
        if line_num + 1 >= bp.Buf:LinesNum() then return false end
        local child_line = bp.Buf:Line(line_num + 1)
        local child_leading_space = util.GetLeadingWhitespace(child_line)
        local child_heading_level = getMdHeadingLevel(child_line)
        -- select the next paragraph if: 
        -- the next para is indented further, or
        -- the next para is empty (i.e. it is just made of spaces), or
        -- the selection starts on an md '# headline' until the next md headline
        -- (strStartswith(firstline, "%s*##*%s") and not strStartswith(child_line, "%s" .. string.rep("#?", child_heading_level) .. "%s") and child_leading_space >= firstline_leading_space) then
        if (child_leading_space > firstline_leading_space) or 
            (#child_leading_space == #child_line) or 
            (firstline_heading_level > 0 and not (child_heading_level > 0 and child_heading_level <= firstline_heading_level) and child_leading_space >= firstline_leading_space) then
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
    
    firstline = getLineAtCursor(bp)
    firstline_heading_level = getMdHeadingLevel(firstline)
    -- notify(tostring(firstline_heading_level))
    firstline_leading_space = util.GetLeadingWhitespace(firstline)
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
    if not isMarkdown() then return false end

    local filename = getRelativeFilepathOfCurrentPane()
    local cmd = string.format("bash " .. HELPER_SCRIPT_PATH .. "/jumpToSymbols.sh %q", filename)
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
    if not isMarkdown() then return false end
    bp.Buf.LastSearchRegex = true
    bp.Buf.LastSearch = config.GetGlobalOption("tojour.symbolsforjump")
    bp:FindNext()
    TJPanes:redrawTocIfActive()
    -- bp.CursorLeft()
    -- bp.Buf:GetActiveCursor():Deselect(false)
end

function cmdJumpToPrevSymbol(bp)
    if not isMarkdown() then return false end
    bp.Buf.LastSearchRegex = true
    bp.Buf.LastSearch = config.GetGlobalOption("tojour.symbolsforjump")
    bp:FindPrevious()
    TJPanes:redrawTocIfActive()
    -- bp.Buf:GetActiveCursor():Deselect(false)
end

function cmdJumpToNextAltSymbol(bp)
    if not isMarkdown() then return false end
    bp.Buf.LastSearchRegex = true
    bp.Buf.LastSearch = config.GetGlobalOption("tojour.symbolsforaltjump")
    bp:FindNext()
    TJPanes:redrawTocIfActive()
end

function cmdJumpToPrevAltSymbol(bp)
    if not isMarkdown() then return false end
    bp.Buf.LastSearchRegex = true
    bp.Buf.LastSearch = config.GetGlobalOption("tojour.symbolsforaltjump")
    bp:FindPrevious()
    TJPanes:redrawTocIfActive()
end

-----------------------------------
-- utility file and pane functions
-----------------------------------

--
-- gives a relative file name, which is usually what we want
--
function getRelativeFilepathOfCurrentPane()
    local bp = micro.CurPane()
    local currentFilename = bp.Buf.Path
    return currentFilename
end

function fileExists(name)
    local f = io.open(name, "r")
    if f ~= nil then
      -- warning: also finds directories, so check if it is one
      local dir = io.open(name .. "/", "r")
      if dir ~= nil then
         io.close(dir)
         return false
      end
      io.close(f)
      return true
   else return false end
end

--
-- get dirname, file from a given full path
--
function getDirNameAndFile(fullpathtofile)
    return filepath.Split(fullpathtofile)
end

--
-- does a file start with a dot?
--
function isFileHidden(filename)
    return strStartswith(filename, "%.")
end

--
-- Check if the given filename of a pane includes a specified suffix like .index.md with 'index' as parameter
function isPanenameMetapane(panename, metasuffix)
    local dirname, filename = getDirNameAndFile(panename)
    if strStartswith(filename, "%.") and string.find(filename, "^.*%." .. metasuffix .. "%.md$") then
        return true
    else
        return false
    end
end

--
-- get a pane's filename meta suffix (if this exists), e.g. index for .xxx.index.md
function getPaneMetaname(panefilename)
    local dirname, filename = getDirNameAndFile(panefilename)
    if isFileHidden(filename) then
        -- check whether file has any of the suffixes
        for i, suffix in pairs(FILE_META_SUFFIXES) do
            if string.find(filename, "^.*%." .. suffix .. "%.md$") then
                -- devlog("We found a meta: " .. suffix)
                return suffix
            end
        end
    end
    return ""
end

--
-- if given a file's full pathname, return the full path filename but with the file hidden
--
function makeFilepathMetaHidden(filenamepath, metatag)
    local dirname, filename = getDirNameAndFile(filenamepath)
    return dirname .. "." .. strStripExtension(filename) .. "." .. metatag .. ".md"
end

--
-- remove a hidden metatag from a filename and path
--
function removeHiddenFilenameMeta(filename, metatag)
    local dirname, filename = getDirNameAndFile(filename)
    local newfilename = string.gsub(filename, "^%.(.*)%." .. metatag .. "%.md$", "%1")
    return dirname .. newfilename
end

function notify(msg)
    local notifybin = tostring(config.GetGlobalOption("tojour.notificationhelper"))
    if notifybin ~= "" then
        shell.RunCommand(string.format(notifybin .. " %q", msg))
    else
        micro.InfoBar():Message(msg)
    end
end

--
-- Iterates over userdata tables
-- Thanks Andriamanitra! https://github.com/Andriamanitra/dotfiles/blob/052bbdc501a4ac5490f3aa2406b69d6fe302d318/micro/.config/micro/plug/ag2/ag.lua#L135-L154
--
function userdataIterator(data)
    local idx = 0
    return function()
        idx = idx + 1
        local success, item = pcall(function() return data[idx] end)
        if success then return idx, item end
    end
end

-----------------------------------
-- utility string functions
-----------------------------------


--
-- strip a string by a separator string and return an array of lines
--
function strExplode(str, separator)
    local lines = {}
    local i = 1
    for line in str:gmatch("[^" .. separator .. "]+") do
        lines[i] = line
        i = i + 1
    end
    return lines
end

--
-- check if string contains strict matching string (without pseudo-regex)
--
function strContains(str, search)
    -- 0 is where it starts searching from,
    -- true disables pattern matching
    if string.find(str, search, 0, true) then
        return true
    else
        return false
    end
end

--
-- Does string start with another string (careful, escape special chars with lua %)
function strStartswith(str, search)
    return string.find(str, '^' .. search) ~= nil
end

function strStartswithStrict(str, searchstr)
    return str:sub(1, #searchstr) == searchstr
end

function strEndsswith(str, search)
    return string.find(str, search .. '$') ~= nil
end

function strEndsswithStrict(str, searchstr)
    return string.sub(str, -#searchstr) == searchstr
end

-- Slightly escapes [ and ] for use in awk regexp ~ matching
function strEscapeBadlyForShell(str)
    local escaped = str
    escaped = string.gsub(escaped, "([%[%]])", "\\\\%1")
    escaped = string.gsub(escaped, "`", "'")
    return string.gsub(escaped, "%$", "$$")
end

--
-- strips the md file extension from end of file
--
function strStripExtension(str)
    if strContains(str, "/") then
        return string.gsub(str, "(.*/)(.*).%md$", "%2")
    else
        return string.gsub(str, "(.*)%.md$", "%1")
    end
end

function getFileExtension(str)
    if strEndsswith(str, "%.[A-Za-z0-9]+") then
        return string.gsub(str, ".*%.([A-Za-z0-9]+)$", "%1")
    end
    return ""
end

function getDateString(offsetInDays)
    if offsetInDays == nil then
        return os.date("%Y-%m-%d")
    else
        return os.date("%Y-%m-%d", os.time() + (offsetInDays * 24 * 60 * 60))
    end
end

-----------------------------------
-- buf line manipulation string functions
-----------------------------------

-- Returns str line of current cursor's line number
function getLineAtCursor(bp)
    local v = micro.CurPane()
    -- local c = v.Cursor
    -- local cs = buffer.Loc(c.Loc.X, c.Loc.Y)
    -- local line = v.Buf:Line(c.Loc.Y)
    local lineNumber = getCurrentLineNumber(bp)
    -- micro.InfoBar():Message(line)
    local line = v.Buf:Line(lineNumber)
    -- micro.InfoBar():Message(c.Loc.X)
    -- micro.InfoBar():Message(line)
    return line
end

function getCurrentLineNumber(bp)
    local c = bp.Cursor
    local lineNumber = c.Loc.Y
    return lineNumber
end

function cmdInsertTimestamp(bp)
    insertTextAtCursor(bp, tostring(os.date("%H:%M ")))
end
    
function cmdInsertDateTimestamp(bp)
    insertTextAtCursor(bp, tostring(os.date("%Y-%m-%d ")))
end

function insertTextAtCursor(bp, text)
    local v = micro.CurPane()
    local c = bp.Cursor
    local cs = buffer.Loc(c.Loc.X, c.Loc.Y)
    v.Buf:Insert(cs, text)
end

-- offset is the number of chars to add to new cursor position
function replaceLineAtCursor(bp, text, offsetByNewStringlen)
    -- local v = micro.CurPane()
    local v = bp
    local c = v.Cursor
    local originalCursorLoc = buffer.Loc(c.Loc.X, c.Loc.Y)

    -- Gets start of the line Location
    local startOfLine = buffer.Loc(0, c.Loc.Y)
    -- Get the end of the line
    -- local endOfLine = buffer.Loc(-1, c.Loc.Y)
    local endOfLine = buffer.Loc(#getLineAtCursor(bp), c.Loc.Y)
    v.Buf:Remove(startOfLine, endOfLine)
    -- Insert new line
    v.Buf:Insert(startOfLine, text)

    -- restore previous cursor position
    local newCursorLoc = buffer.Loc(originalCursorLoc.X + offsetByNewStringlen, originalCursorLoc.Y)
    v.Cursor:GotoLoc(newCursorLoc)
end

--
--
-- DEV TESTS START HERE
--
--


--
-- output a semi-clever log to a tmp file
--
function devlog(text)
    function add(line)
        outlog = outlog .. line .. "\n"
    end

    if TOJOUR_DEVMODE == false then
        return false
    end

    file = io.open("/tmp/luajournal.txt", "a")

    currentTime = os.date("%H:%M:%S")
    outlog = ""
    add("=== " .. currentTime .. " [" .. type(text) .. "] ===")
    file:write(outlog)

    outlog = ""
    if type(text) == "number" then
        text = tostring(text)
    end
    if type(text) ~= "string" then
        -- add("Is type: " .. type(text))
        if type(text) == "userdata" then
            add("Userdata pointer found: " .. type(text))
            for key, value in userdataIterator(text) do
                add("ud key is:")
                add(key)
                add("ud value is:")
                add(value)
            end
        end
        if type(text) == "table" then
            for index, value in pairs(text) do
                add("{ " .. tostring(index) .. ": " .. tostring(value) .. " }")
            end
        end
    else
        add(text)
    end
    file:write(outlog)
    -- file:write("==============================\n")
    file:close()
end

-- TODO: test = getWordUnderCursor("Sentence http://example.org/123")
-- Ensure at the end of every test, all tabs are closed except /dev/null with tabid = 1
-- by using test_setup() at the beginning of the test, and test_reset() at the end
function tojourUnitTests(bp)
    passed = 0
    failed = 0
    -- local nullfile = "/dev/null"
    local nullfile = "/tmp/tojour_nullfile"
    -- FIXME: Flaky test tied to readme.md Headings like: t = FileLink:new("#features")
    local filethatexists = PLUGIN_PATH .. "/README.md"
    local tmpfile = "/tmp/tojour.tests.md"
    local output, err = shell.RunCommand("touch " .. tmpfile)

    -- Initialise with /dev/null open in first tab
    local buf, err = buffer.NewBufferFromFile(nullfile)
    micro.CurPane():OpenBuffer(buf)
    
    local function assertTrue(condition, msg)
        if not condition == true then 
            devlog("🔴 FAILED: expected " .. msg) --  .. " was actually " .. tostring(condition))
            notify("🔴 FAILED: expected " .. msg)
            failed = failed + 1
            return false
        end
        devlog("PASSED: " .. msg) -- .. " - was " .. tostring(condition))
        passed = passed + 1
        return true
    end

    local function assertEquals(leftval, rightval, msg)
        return assertTrue(leftval == rightval, msg .. " (EXPECTED: \"" .. tostring(leftval) .. "\" == \"" .. tostring(rightval) .. "\")")
    end

    local function assertNotEquals(leftval, rightval, msg)
        return assertTrue(leftval ~= rightval, msg .. " (EXPECTED: \"" .. tostring(leftval) .. "\" != \"" .. tostring(rightval) .. "\")")
    end

    local function test_setup()
        local output, err = shell.RunCommand("rm " .. tmpfile)
        local output, err = shell.RunCommand("touch " .. tmpfile)
        local output, err = shell.RunCommand("rm " .. nullfile)
        local output, err = shell.RunCommand("touch " .. nullfile)
    end

    local function test_reset()
        TJPanes:new()
        -- close all files
        while TJPanes.curpaneFilename ~= nullfile do
            bp = micro.CurPane()
            bp:Quit()
            TJPanes:new()
            -- if filename then
                -- FileLink:openInternalDocumentLink(bp, filename)
                -- local curPane = micro.CurPane()
                -- if TJPanes.panescount > 1 then
                --     local sidepane = TJPanes.panesArray[2]
                --     sidepane:Quit()
                -- end
                -- curPane:Quit()
            -- end
        end
        TJPanes:new()
        assertTrue(TJPanes.curpaneFilename == nullfile, "test_reset: closed second tab, TJPanes should be nullfile; is: " .. TJPanes.curpaneFilename)
        local output, err = shell.RunCommand("rm " .. tmpfile)
    end

    local function test_end_summary()
        local bp = micro.CurPane()
        local test_result_file = "/tmp/micro-tojour-test-result.log"
        local output, err = shell.RunCommand("rm " .. test_result_file)

        local symbol = "🟢 "
        if failed > 0 then symbol = "🔴 " end
        msg = symbol .. passed .. " tests passed, " .. failed .. " failed."
        micro.InfoBar():Message(msg)
        notify(msg)
        
        if failed > 0 then
            local output, err = shell.RunCommand("bash -c \"echo '" .. msg .. "' > " .. test_result_file .. "\"")
        end
        bp:ForceQuit()
    end

    local function test_OpenDummyPane(curfile, type, text)
        local newpanename = makeFilepathMetaHidden(curfile, type)
        TJPanes:new()
        TJPanes:createNewSidePane(text, newpanename)
    end

    local function testFileLink()
        test_setup()
        
        local t = {}
        -- run tests on open nullfile
        t = FileLink:new(nullfile)
        assertTrue(t.rawlink == nullfile, "nullfile rawlink is correct")
        assertTrue(t.exists, "nullfile exists")
        assertTrue(t.filewithpath == nullfile, "fileispath is nullfile")
        assertTrue(t.ext == "", "nullfile ext is ''")
        assertTrue(t.tabid == 1, "open nullfile's tabid is 1")
        
        TJPanes:new()
        assertTrue(TJPanes.curpaneFilename == nullfile, "TJPanes has dev/null")
        assertTrue(TJPanes.curpaneId == 1, "TJPanes curpaneId is 1")
        
        -- run tests on not yet open filethatexists
        t = FileLink:new(filethatexists)
        assertTrue(t.tabid == nil, "closed filethatexists's tabid is nil")

        -- opens filethatexists in new tab
        local buf, err = buffer.NewBufferFromFile(filethatexists)
        if err == nil then
            local bp = micro.CurPane()
            bp.addTab(bp)
        end
        micro.CurPane():OpenBuffer(buf)

        -- check that new tab filethatexists is parsed properly
        t = FileLink:new(filethatexists)
        assertEquals(t.rawlink, filethatexists, filethatexists .. " rawlink")
        assertTrue(t.exists, filethatexists .. " exists")
        assertEquals(t.filewithpath, filethatexists, "filepath is README.md")
        assertEquals(t.ext, "md", filethatexists .. " ext")
        assertEquals(t.linenum, 0, filethatexists .. " linenum")
        assertTrue(t.tabid > 1, filethatexists .. " tabbed file tabid expected larger than 1, was: " .. tonumber(t.tabid))
        
        -- check that :line numbers are parsed
        t = FileLink:new(filethatexists .. ":10")
        assertEquals(t.linenum, 10, filethatexists .. " linenum")

        -- try to open a sidepane (should be TOC)
        -- instead of: openAppropriateContextSidePane()
        -- this also doesn't work though
        -- test_OpenDummyPane(filethatexists, 'toc', "DUMMY TOC CONTENT FOR TESTING")
        TJPanes:new()
        assertEquals(TJPanes.curpaneFilename, filethatexists, "TJPanes stays filethatexists")

        -- TODO: This test does nothing, really - sidepane doesnt seem to be focusable automatically
        assertEquals(TJPanes.curpaneId, 1, "TJPanes curpaneId is still 1")

        -- nullfile tabid still findable even though we're on another file
        t = FileLink:new(nullfile)
        assertEquals(t.tabid, 1, "can get tabid of nullfile tabid should be 1, was " .. tonumber(t.tabid))

        -- checks manual parsing of $HOME and ~
        t = FileLink:new("$HOME/xyz")
        assertEquals(t.filewithpath, HOME_DIR .. '/xyz', "can parse $HOME")
        t = FileLink:new("~/xyz")
        assertEquals(t.filewithpath, HOME_DIR .. '/xyz', "can parse ~")
        
        t = FileLink:new("uniquestring_4yzYjME2kZk5XzcKCj7y3qCnKX3QDcga.md")
        assertEquals(t.exists, false, "uniquestring file does not exist")
        assertEquals(t.ext, "md", "uniquestring has md extension")

        -- FIXME: Flaky test tied to readme.md header
        t = FileLink:new("#features")
        assertEquals(t.exists, true, "internal anchor link found file")
        assertTrue(t.linenum > 0, "internal anchor link found linenum")
        
        t = FileLink:new("#installatIon-requiRements")
        assertEquals(t.exists, true, "internal anchor link with dash and funny cases found file")
        assertTrue(t.linenum > 0, "internal anchor link with dash found linenum")
        
        t = FileLink:new("#header-that-doesnot-exist")
        assertEquals(t.exists, true, "non-existent internal anchor link file doesnt exist")
        assertNotEquals(t.anchorlink, "", "non-existent internal anchor link file doesnt exist")
        assertEquals(t.linenum, 0, "non-existent internal anchor link has no linenum")

        t = FileLink:new("random-file#header-that-doesnot-exist")
        assertEquals(t.exists, false, "non-existent internal anchor link file doesnt exist")
        assertEquals(t.linenum, 0, "non-existent internal anchor link has no linenum")

        -- TODO: Find link to a new file in another tab that does exist
        -- t = FileLink:new("existing-file#header-that-does-exist")
        -- assertEquals(t.exists, true, "internal anchor link to diff file exists")
        -- assertTrue(t.linenum > 0, "internal anchor link to diff file has linenum")

        test_reset()
        
        -- look for a file somewhere find out pwd
        -- local output, err = shell.RunCommand("bash -c \"pwd\"")
        -- devlog(output) -- consider changing to repo root
    end

    
    -- Open files directly with the openInternalDocumentLink function
    local function testOpenInternalLink()
        test_setup()
        local bp = micro.CurPane()
        FileLink:openInternalDocumentLink(bp, filethatexists)
        TJPanes:new()
        assertTrue(TJPanes.curpaneFilename == filethatexists, "FileLink:openInternalDocumentLink: TJPanes is filethatexists")

        -- return to nullfile
        FileLink:openInternalDocumentLink(bp, nullfile)
        TJPanes:new()
        assertTrue(TJPanes.curpaneFilename == nullfile, "FileLink:openInternalDocumentLink: returns to nullfile")
        
        -- return to filethatexists, and close it
        test_reset()

        -- only nullfile is open
    end

    local function testLineOperations()
        test_setup()
        local bp = micro.CurPane()
        
        FileLink:openInternalDocumentLink(bp, tmpfile)
        local bp = micro.CurPane()

        -- in line 0
        replaceLineAtCursor(bp, "123", 0)
        assertEquals(getLineAtCursor(bp), "123", "line 123 has been written in first line, is ")
        cmdToggleCheckbox(bp)
        cmdToggleCheckbox(bp)
        assertEquals(getLineAtCursor(bp), "- [x] 123", "line 123 has been checked twice and is unchecked, is ")
        
        -- on 2nd line, making sure it doesn't bleed
        bp:EndOfLine()
        bp:InsertNewline()
        
        replaceLineAtCursor(bp, "abc", 0)
        assertEquals(getLineAtCursor(bp), "abc", "line abc has been written, is ")
        
        cmdToggleCheckbox(bp)
        assertEquals(getLineAtCursor(bp), "- [ ] abc", "checkbox abc has been created")
        
        cmdToggleCheckbox(bp)
        assertEquals(getLineAtCursor(bp), "- [x] abc", "checkbox abc has been checked")
        
        -- remove this function, checkboxse now stay
        -- cmdToggleCheckbox(bp)
        --EqualsertTrue(getLineAtCursor(bp), "abc", "checkbox abc has been removed")
        
        replaceLineAtCursor(bp, "abc", 0)
        cmdIncrementDaystring(bp)
        assertEquals(getLineAtCursor(bp), "abc @today", "@today tag inserted")

        cmdIncrementDaystring(bp)
        assertEquals(getLineAtCursor(bp), "abc @tomorrow", "@tomorrow tag inserted")

        cmdIncrementDaystring(bp)
        assertTrue(string.match(getLineAtCursor(bp), "abc @%d%d%d%d%-%d%d%-%d%d"), "@[0-9]+ date tag inserted, is: ")
        
        cmdDecrementDaystring(bp)
        assertEquals(getLineAtCursor(bp), "abc @tomorrow", "date tag decreased by one")
        
        cmdToggleCheckbox(bp)
        bp:EndOfLine()
        bp:InsertNewline()

        replaceLineAtCursor(bp, "XYZ", 0)
        cmdToggleCheckbox(bp)
        bp:CursorUp()
        cmdToggleCheckbox(bp)
        assertEquals(getLineAtCursor(bp), "- [x] abc @tomorrow", "just first todo item to be checked: ")
        cmdToggleCheckbox(bp)
        assertEquals(getLineAtCursor(bp), "- [ ] abc @tomorrow", "just first todo item to be unchecked again: ")
        
        replaceLineAtCursor(bp, "TODO abc", 0)
        cmdToggleCheckbox(bp)
        assertEquals(getLineAtCursor(bp), "DONE abc", "toggling TODO to DONE: ")
        cmdToggleCheckbox(bp)
        assertEquals(getLineAtCursor(bp), "TODO abc", "toggling DONE back to TODO: ")
        
        replaceLineAtCursor(bp, "* TODO abc", 0)
        cmdToggleCheckbox(bp)
        assertEquals(getLineAtCursor(bp), "* DONE abc", "toggling * TODO to DONE: ")
        
        cmdToggleCheckbox(bp)
        assertEquals(getLineAtCursor(bp), "* TODO abc", "toggling * DONE back to TODO: ")

        bp:Save()
        -- local output, err = shell.RunCommand("rm " .. tmpfile)
        -- test_reset()
    end

    local function testWordUnderCursor()
        test_setup()

        local bp = micro.CurPane()
        FileLink:openInternalDocumentLink(bp, tmpfile)
        local bp = micro.CurPane()
        
        function testWord(linetext, cursor_pos, expect, msg)
            bp:CursorStart()
            replaceLineAtCursor(bp, linetext, cursor_pos)
            local word = getLinkTagsUnderCursor(bp)
            assertEquals(word, expect, msg)
        end
        
        testWord("#hashtag123 something", 0, "hashtag123", "#hashtag found at start of line: ")
        testWord("[[hashtag123]] something", 0, "hashtag123", "[[hashtag]] found at start of line: ")
        testWord("1234567890 abc [[hashtag123]] something", 15, "hashtag123", "[[hashtag]] found in middle of line: ")
        testWord("1234567890 abc #hashtag123 something", 15, "hashtag123", "#hashtag found in middle of line: ")

        local link = "https://www.example.org/xyz?query=123&test=false"
        testWord("Hello there " .. link .. " something", 15, link, link .. " hyperlink found in middle of line: ")

        local mdlink = "[thisisahyperlink](" .. link ..")"
        testWord("Hello there " .. mdlink .. " something", 40, link, link .. " md hyperlink found in middle of line: ")
        testWord(mdlink .. " something", 0, link, link .. " md hyperlink also found in [firstpart_if_theres_no_space](https://etc...): ")
        
        -- TODO: Test artificially passes - fefactor wordundercursor for linkundercursor
        linkwithmanychars = "https://www.example.org/xyz?query=123&test=false" -- if we add ;, or other crapa behind the url it would fail
        testWord("Hello there [thisisahyperlink](" .. linkwithmanychars .. ") something", 40, link, link .. " TODO: hyperlink with funny chars NOT found in middle of line: ")

        -- local link = "[thisisahyperlink](#internal-reference)"
        testWord("[hyperlink](#internal-reference)", 20, "#internal-reference", "looking for internal hypderlink")
        testWord("[hyperlink](someotherfile#internal-reference)", 20, "someotherfile#internal-reference", "looking for internal hypderlink")
        -- testWord(mdlink .. " something", 0, link, link .. " md hyperlink also found in [firstpart_if_theres_no_space](https://etc...): ")
        
        -- links containing comma, semicolon, or other funky stuff don't get found
        -- notify(strEscapeForShellRegex("[comment]:"))
        bp:Save()

        -- openAppropriateContextSidePane()
        -- TJPanes:initialise()
        -- test_reset()
    end
    
    local function testTJSession()
        test_setup()
        local bp = micro.CurPane()
        FileLink:openInternalDocumentLink(bp, tmpfile)

        bp:Save()
        local session = TJSession:new()
        assertTrue(session:getSidepane() == '', "session has stored zero side pane state: ")

        FileLink:openInternalDocumentLink(bp, filethatexists)
        -- TJPanes:openSidePaneWithContext('toc', false)
        -- open synchronous sidepane (rather than async which screws with test)
        test_OpenDummyPane(filethatexists, FILE_META_SUFFIXES.toc, "DUMMY TOC CONTENT FOR TESTING")
        local new_session = TJSession:new()
        assertEquals(new_session:getSidepane(), FILE_META_SUFFIXES.toc, "session has stored side pane FILE_META_SUFFIXES.toc state")

        local project_pwd, lines = TJSession:serializeSession(new_session)
        assertTrue(strContains(lines, filethatexists), "filethatexists found in session")
        assertTrue(strContains(lines, tmpfile), "tmpfile found in session")

        local reconstructed_session = TJSession:deserializeSession(project_pwd, lines)
        local new_project_pwd, new_lines = TJSession:serializeSession(reconstructed_session)
        assertTrue(project_pwd == new_project_pwd, "Reconstructed serialised project_pwd from session is identical: " .. project_pwd .. " vs " .. new_project_pwd)
        assertTrue(lines == new_lines, "Reconstructed serialised lines from session is identical: " .. lines .. " vs " .. new_lines)

        -- FileLink:openInternalDocumentLink(bp, "~/.config/micro-journal/plug/tojour/tojour.tutorial.md")
        -- test_reset()
    end
  
    testFileLink()
    testOpenInternalLink()
    testLineOperations()
    testWordUnderCursor()
    testTJSession()

    test_end_summary()
end
