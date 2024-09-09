local micro = import("micro")
local util = import("micro/util")
local shell = import("micro/shell")
local config = import("micro/config")
local buffer = import("micro/buffer")
local strings = import("strings")
local filepath = import("path/filepath")

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
			Common.devlog("switched: " .. paneFilename .. ", was: " .. self.curpaneFilename)
		end
		self.curpaneFilename = paneFilename

		local curtab = micro.CurTab()
		for paneIdx, pane in Common.userdataIterator(curtab.Panes) do
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
	if TJConfig.DEBOUNCE_GET_TOC == true then
		-- devlog("debounced TOC, quitting")
		return false
	end
	TJConfig.DEBOUNCE_GET_TOC = true

	local curtab = micro.CurTab()
	for paneIdx, pane in Common.userdataIterator(curtab.Panes) do
		if string.find(pane.Buf.Path, "%.toc%.md$") then
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
	for paneIdx, pane in Common.userdataIterator(curtab.Panes) do
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
	if TJConfig.DEBOUNCE_GET_SIDEPANE == true then
		-- notify("Debouncing")
		return false
	end
	TJConfig.DEBOUNCE_GET_SIDEPANE = true

	for paneIdx, pane in ipairs(TJPanes.panesArray) do
		local dirname, filename = TJPanes:getPaneDirAndFilename(pane)
		-- devlog("Will refresh pane: " .. filename)
		local metaSuffix = Common.getPaneMetaname(filename)
		if metaSuffix ~= "" and metaSuffix ~= TJConfig.FILE_META_SUFFIXES.index then
			-- devlog("Refreshing sidepane with meta suffix: " .. metaSuffix)
			TJPanes:openSidePaneWithContext(metaSuffix, false)
			return metaSuffix
		end
	end
	TJConfig.DEBOUNCE_GET_SIDEPANE = false
	return ""
end

--
-- returns dirname, file from a given pane
--
function TJPanes:getPaneDirAndFilename(pane)
	return Common.getDirNameAndFile(pane.Buf.AbsPath)
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
			if Common.strStartswith(filename, "%.") then
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
	TJConfig.DEBOUNCE_GET_SIDEPANE = true
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
				local firstpaneDirname, firstpaneFilename =
					Common.getDirNameAndFile(Common.getRelativeFilepathOfCurrentPane())
				local fullfilepath = firstpaneDirname .. firstpaneFilename
				currentPaneName = fullfilepath

				if not Common.isFileHidden(firstpaneFilename) then
					local contents = ""
					local newpanename = ""
					if contextMeta == TJConfig.FILE_META_SUFFIXES.index then
						asyncUpdatePaneWithIndex(fullfilepath)
						return true
					elseif contextMeta == TJConfig.FILE_META_SUFFIXES.undone then
						asyncUpdatePaneWithUndone(fullfilepath)
						return true
					elseif contextMeta == TJConfig.FILE_META_SUFFIXES.toc then
						-- Asynchronously update this tab in background, and return so we don't trigger update below
						asyncUpdatePaneWithTocContent(fullfilepath, self.panescount, focusNewPane)
						return true
					elseif contextMeta == TJConfig.FILE_META_SUFFIXES.tree then
						newpanename = Common.makeFilepathMetaHidden(firstpaneFilename, "tree")
						-- tree is a bit ugly and broken alas - it produces garbage unicode characters if too close to the tree, sadly
						-- cmd = string.format("sh -c \"tree -i %s\"", firstpaneDirname)
						local cmd = string.format('sh -c "tree %q"', firstpaneDirname)
						contents, err = shell.RunCommand(cmd)
						local headingtext = "6. Tree"
						local heading = TJPanes.createContextHeading(headingtext, "tree")
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
		TJConfig.DEBOUNCE_GET_SIDEPANE = false
	end

	-- type: toc, index or todos
	function callbackPaneUpdate(relativeFilename, type, contents, headline)
		self:new()
		-- bail if we have switched tabs since first triggering update
		-- since this cancels update, have inserted forced update into onNextTab and onPrevTab
		if currentPaneName ~= Common.getRelativeFilepathOfCurrentPane() then
			TJConfig.DEBOUNCE_GET_SIDEPANE = false
			TJConfig.DEBOUNCE_GET_TOC = false
			return false
		end
		local newpanename = Common.makeFilepathMetaHidden(relativeFilename, type)
		self:createNewSidePane(TJPanes.createContextHeading(headline, type) .. contents, newpanename, focusNewPane)
		self:resizePanes()
		TJConfig.DEBOUNCE_GET_SIDEPANE = false
		-- Save the session with the new pane info
		TJSession:new()
	end

	--
	-- Runs in background and refreshes panel if required
	--
	function asyncUpdatePaneWithTocContent(relativeFilename, panescount, focusNewPane)
		local dirname, filename = Common.getDirNameAndFile(relativeFilename)
		local newpanename = Common.makeFilepathMetaHidden(filename, TJConfig.FILE_META_SUFFIXES.toc)
		local session = TJSession:new()
		local toc_level = session:getTocLevel()

		function onExit(contents)
			-- local headingtext = '[Toc] ' .. filename .. " "
			local headingtext = filename
			headingtext = headingtext .. " H" .. toc_level .. " [--] [++]"
			if contents == "" then
				headingtext = headingtext .. " (no markdown # headers found)"
			end

			callbackPaneUpdate(relativeFilename, TJConfig.FILE_META_SUFFIXES.toc, contents, headingtext)
			TJConfig.DEBOUNCE_GET_TOC = false
			if config.GetGlobalOption("tojour.potatomode") == true then
				micro.InfoBar():Message("Showing table of contents")
			end
			-- TODO: Should we grab the nearest headline above in main body and use as cursor in right pane? How?
		end

		if config.GetGlobalOption("tojour.potatomode") == true then
			micro.InfoBar():Message("Please wait: Fetching table of contents...")
		end

		-- to cludge line number into TOC
		local linenum = Common.getCurrentLineNumber(micro.CurPane())

		local escapedCommentPrefix =
			Common.strEscapeBadlyForShell(tostring(config.GetGlobalOption("tojour.mdcommentprefix")))
		if TJPanes.sidepanewidth == 0 then
			-- If sidepandwidth hasn't been initialised yet because pane isn't open yet, reconstruct this from config width
			TJPanes.sidepanewidth = math.floor(TJPanes.fullwidth / 100 * (100 - TJConfig.MAIN_PANE_WIDTH_PERCENT) + 0.5)
		end
		-- If we do this natively in micro, we get neither fast subshell nor sane shell escaping and get mangling of \n etc with %q
		-- local text = strEscapeBadlyForShell(cmdGetBufferText(micro.CurPane()))
		-- onExit(text)
		-- local text = strEscapeForShellRegex("$(notify-send inject);`notify-send inject2`")
		-- local cmd = string.format("sh " .. HELPER_SCRIPT_PATH .. "/generateTOC.sh --line-number %q --col-width %q --comment-prefix %q --max-level %q --text %q", tostring(linenum + 2), TJPanes.sidepanewidth, escapedCommentPrefix, toc_level, text)

		-- TODO: Performance boost possible by getting TOC's previous and next headings from cursor, and check if refresh is necessary before calling
		-- using /tmp fs is not significantly fasterr - local cmd = string.format("sh " .. HELPER_SCRIPT_PATH .. "/generateTOC.sh %q --line-number %q --col-width %q --comment-prefix %q --max-level %q", "/tmp/tmp.md", tostring(linenum + 2), TJPanes.sidepanewidth, escapedCommentPrefix, toc_level)
		local cmd = string.format(
			"sh "
				.. TJConfig.HELPER_SCRIPT_PATH
				.. "/generateTOC.sh %q --line-number %q --col-width %q --comment-prefix %q --max-level %q",
			dirname .. filename,
			tostring(linenum + 2),
			TJPanes.sidepanewidth,
			escapedCommentPrefix,
			toc_level
		)

		shell.JobSpawn("sh", { "-c", cmd }, function(input)
			return
		end, function(input)
			return
		end, function(input)
			onExit(input)
			return
		end, "")
	end

	--
	-- Opens a sidepane with the appropriate undone Todos, if there are any
	--
	function asyncUpdatePaneWithUndone(relativeFilename)
		local dirname, filename = Common.getDirNameAndFile(relativeFilename)

		-- get all todo items, not just the today or habit ones
		local filterByTagname = Common.strStripExtension(filename)

		function onExit(contents)
			callbackPaneUpdate(relativeFilename, TJConfig.FILE_META_SUFFIXES.undone, contents, relativeFilename)
			if config.GetGlobalOption("tojour.potatomode") == true then
				micro.InfoBar():Message("Showing undone todo items")
			end
		end

		if config.GetGlobalOption("tojour.potatomode") == true then
			micro.InfoBar():Message("Please wait: Fetching undone todo items...")
		end

		local cmd = ""
		local output, err
		if
			type(filterByTagname) == "string"
			and filterByTagname ~= ""
			and not string.match(filterByTagname, "%d%d%d%d%-%d%d%-%d%d")
		then
			cmd = string.format(
				"bash " .. TJConfig.HELPER_SCRIPT_PATH .. "/collectUndonesFromFile.sh %q --filter-by-tag %q",
				relativeFilename,
				filterByTagname
			)
			-- output, err = shell.RunCommand(cmd)
			shell.JobSpawn("sh", { "-c", cmd }, function(input)
				return
			end, function(input)
				return
			end, function(input)
				onExit(input)
				return
			end, "")
		else
			-- this just gets undone todos in the current file that have today or habit in it
			-- TODO: to deprecate - really we want the above option all the time now probably (even for daily files, why not)
			-- NO: If we are on today file, then simply search for @today instead everywhere in all files?
			cmd = string.format(
				"bash " .. TJConfig.HELPER_SCRIPT_PATH .. "/collectUndonesFromFile.sh %q",
				relativeFilename
			)
			-- output, err = shell.RunCommand(cmd)
			shell.JobSpawn("sh", { "-c", cmd }, function(input)
				return
			end, function(input)
				return
			end, function(input)
				onExit(input)
				return
			end, "")
		end
	end

	--
	-- synchronously generate and display references of tags and links for showing in sidepane
	--
	function asyncUpdatePaneWithIndex(relativeFilename)
		local dirname, filename = Common.getDirNameAndFile(relativeFilename)
		local tag_word = ""
		function onExit(contents)
			local headingtext = ""
			if contents == nil or contents == "" then
				headingtext = "Not found any cross-references of this tag file"
			else
				local pwd, shortFilename = Common.getDirNameAndFile(relativeFilename)
				-- headingtext = "[Index] to '" .. tag_word .. "'"
				headingtext = tag_word
			end
			micro.InfoBar():Message("Showing index for " .. tag_word)
			callbackPaneUpdate(relativeFilename, TJConfig.FILE_META_SUFFIXES.index, contents, headingtext)
		end

		local word = Common.getLinkTagsUnderCursor(bp)
		if word ~= "" then
			tag_word = word
			micro
				.InfoBar()
				:Message(
					"Please wait: Fetching cross-references index for '" .. tag_word .. "' (under cursor in sidebar)"
				)
		else
			tag_word = Common.strStripExtension(filename)
			micro.InfoBar():Message("Please wait: Fetching index for " .. filename)
		end

		-- if strContains(tagnameFromFile, ".") then
		--     tagnameFromFile = string.gsub('take last xyz.abc.thistag')
		-- end
		local dev_args = ""
		if TJConfig.TOJOUR_DEVMODE then
			dev_args = " --stats "
		end
		local cmd = string.format(
			"python " .. TJConfig.HELPER_SCRIPT_PATH .. "/todobuddy.py " .. dev_args .. " --tag '" .. tag_word .. "'"
		)
		local cmd = string.format("python %s/todobuddy.py %s --tag %q", TJConfig.HELPER_SCRIPT_PATH, dev_args, tag_word)

		shell.JobSpawn("sh", { "-c", cmd }, function(input)
			return
		end, function(input)
			return
		end, function(input)
			onExit(input)
			return
		end, "")
	end

	return run()
end

function TJPanes:resizePanes()
	if self.panescount == 1 then
		-- if the old tab had been closed, reinitialise
		Common.devlog("reiniting TJPanes in resize")
		self:new()
	end
	if self.panescount > 1 then
		Common.devlog("resizing mainpane % to " .. TJConfig.MAIN_PANE_WIDTH_PERCENT)
		local newwidth = math.floor(self.fullwidth * TJConfig.MAIN_PANE_WIDTH_PERCENT / 100 + 0.5)
		local cp = TJPanes.panesArray[1]
		cp:ResizePane(newwidth)
		TJPanes:redrawTocIfActive()
		return true
	end
	Common.devlog("not resizing")
	return false
end

-- actually split the pane and open file
function TJPanes:createNewSidePane(content, panename, focusNewPane)
	Common.devlog("creating new sidepane with " .. TJConfig.MAIN_PANE_WIDTH_PERCENT)
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

function TJPanes.openAppropriateContextSidePane()
	if
		config.GetGlobalOption("tojour.alwaysopencontextpane") == false
		and config.GetGlobalOption("tojour.alwaysopentodayundone") == false
	then
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

	if Common.isCurfileTodayfile(bp) and config.GetGlobalOption("tojour.alwaysopentodayundone") == true then
		-- open a todo side pane if we are on today's file
		TJPanes:openSidePaneWithContext(TJConfig.FILE_META_SUFFIXES.undone, false)
		return true
	elseif Common.isMarkdown() and config.GetGlobalOption("tojour.alwaysopencontextpane") ~= false then
		-- Allow valid options true, 'toc', 'index', 'undone'
		-- if a file is in a subdirectory, then it's likely a tag, so open index
		local dirname, file = Common.getDirNameAndFile(bp.Buf.Path)
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
		for key, val in pairs(TJConfig.FILE_META_SUFFIXES) do
			if val == tostring(config.GetGlobalOption("tojour.alwaysopencontextpane")) then
				return TJPanes:openSidePaneWithContext(TJConfig.FILE_META_SUFFIXES[val], false)
			end
		end
		-- fallback if another value like true, just use TOC as default
		return TJPanes:openSidePaneWithContext(TJConfig.FILE_META_SUFFIXES.toc, false)
	end
end

--
-- generic string heading creator to be used above a virtual sidepane
--
function TJPanes.createContextHeading(heading, context_type)
	local function strCapitalise(str)
		return string.upper(string.sub(str, 1, 1)) .. string.sub(str, 2, -1)
	end
	local pane_menu = ""
	for key, val in pairs(TJConfig.FILE_META_SUFFIXES) do
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
	pane_menu = TJConfig.FILE_META_MENU_START .. pane_menu
	return TJConfig.FILE_META_HEADER_BEGIN .. heading .. "\n" .. pane_menu .. "\n\n"
end

--
-- Grab word under cursor and follow it in new window if it's a link
-- focus_which can be nil or can start at 0, to select left pane, and 1 to select second
--
function TJPanes:followInternalLink(bp, focus_which)
	if not Common.isMarkdown() then
		return false
	end

	local function jumpFromLineMatchInSidepane()
		local panes = TJPanes:new()
		-- if we're in a TOC table of contents file or Undones file sidepane
		local cursor = micro.CurPane().Cursor
		local localbuffer = micro.CurPane().Buf
		local line = localbuffer:Line(cursor.Y)
		-- parse internal menu 'button' from createContextHeading
		if Common.strStartswithStrict(line, TJConfig.FILE_META_HEADER_BEGIN) then
			Common.devlog("Special contextHeader 'menu' block detected")
			local link = Common.getLinkTagsUnderCursor(bp)
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
		if Common.strEndsswith(line, "%<via: %[.*%] %>") then
			local link = string.gsub(line, "^.*%<via: %[(.*)%] %>$", "%1")
			if link then
				Common.devlog("Opening <via: link from sidepane")
				FileLink:openInternalDocumentLink(bp, link)
				return true
			end
		end

		-- in the index view, we don't want to do more advanced sidepane jumps (yet) taking actions
		-- but just to follow normal links (since format is different: line before containts header)
		if Common.isPanenameMetapane(micro.CurPane().Buf.Path, TJConfig.FILE_META_SUFFIXES.index) then
			return false
		end

		-- get the left pane and search it
		-- local panes = TJPanes:new()
		-- local firstpaneName = panes:getLeftPaneFilename()
		-- local linenumber = FileLink:getLinenumMatchingTextInFile(firstpaneName, line, false)
		local cp = panes.panesArray[1]
		cp.Buf.LastSearchRegex = false
		cp.Buf.LastSearch = line
		-- alas Findnext just seems to always return a true bool, so hard to react if nothing is found (could figure out with terrible pane logic instead)
		if cp:FindNext() then
			Common.devlog("Searched for line in mainpane: " .. line)
			TJConfig.DEBOUNCE_GET_TOC = false
			TJConfig.DEBOUNCE_GET_SIDEPANE = false
			if focus_which ~= nil then
				Common.devlog("explicitly told to focus pane number: " .. tostring(focus_which))
				local curtab = micro.CurTab()
				curtab:SetActive(tonumber(focus_which))
			end
			return true
		end
		TJConfig.DEBOUNCE_GET_TOC = false
		TJConfig.DEBOUNCE_GET_SIDEPANE = false
		micro.InfoBar():Message("Couldn't find line '" .. line .. "' in left pane...")
		return false
		-- TODO: else find a ## [[tagname]] in a line above, and try finding the line in that file?
	end

	-- if we're in a META sidepane like toc, undone
	-- then try searching for special <via tags, commands or matching lines in left pane
	local curpaneName = micro.CurPane().Buf.Path
	for i, meta in pairs(TJConfig.FILE_META_SUFFIXES) do
		-- if isPanenameMetapane(curpaneName, FILE_META_SUFFIXES.toc) or isPanenameMetapane(curpaneName, FILE_META_SUFFIXES.undone) then
		if Common.isPanenameMetapane(curpaneName, meta) then
			if jumpFromLineMatchInSidepane() then
				Common.devlog("jumping to line match in primary pane via text-search or other options")
				return true
			end
		end
	end

	word = Common.getLinkTagsUnderCursor(bp)
	if word ~= nil and word ~= "" then
		if FileLink:openInternalDocumentLink(bp, word) then
			return true
		end
	end
	return false
end

return TJPanes
