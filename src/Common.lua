local micro = import("micro")
local buffer = import("micro/buffer")
local shell = import("micro/shell")
local config = import("micro/config")
local filepath = import("path/filepath")

Common = {}

function Common.notify(msg)
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
function Common.userdataIterator(data)
	local idx = 0
	return function()
		idx = idx + 1
		local success, item = pcall(function()
			return data[idx]
		end)
		if success then
			return idx, item
		end
	end
end

-----------------------------------
-- utility string functions
-----------------------------------

--
-- strip a string by a separator string and return an array of lines
--
function Common.strExplode(str, separator)
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
function Common.strContains(str, search)
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
function Common.strStartswith(str, search)
	return string.find(str, "^" .. search) ~= nil
end

function Common.strStartswithStrict(str, searchstr)
	return str:sub(1, #searchstr) == searchstr
end

function Common.strEndsswith(str, search)
	return string.find(str, search .. "$") ~= nil
end

function Common.strEndsswithStrict(str, searchstr)
	return string.sub(str, -#searchstr) == searchstr
end

-- Slightly escapes [ and ] for use in awk regexp ~ matching
function Common.strEscapeBadlyForShell(str)
	local escaped = str
	escaped = string.gsub(escaped, "([%[%]])", "\\\\%1")
	escaped = string.gsub(escaped, "`", "'")
	return string.gsub(escaped, "%$", "$$")
end

--
-- strips the md file extension from end of file
--
function Common.strStripExtension(str)
	if Common.strContains(str, "/") then
		return string.gsub(str, "(.*/)(.*).%md$", "%2")
	else
		return string.gsub(str, "(.*)%.md$", "%1")
	end
end

function Common.getFileExtension(str)
	if Common.strEndsswith(str, "%.[A-Za-z0-9]+") then
		return string.gsub(str, ".*%.([A-Za-z0-9]+)$", "%1")
	end
	return ""
end

function Common.getDateString(offsetInDays)
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
function Common.getLineAtCursor(bp)
	local v = micro.CurPane()
	-- local c = v.Cursor
	-- local cs = buffer.Loc(c.Loc.X, c.Loc.Y)
	-- local line = v.Buf:Line(c.Loc.Y)
	local lineNumber = Common.getCurrentLineNumber(bp)
	-- micro.InfoBar():Message(line)
	local line = v.Buf:Line(lineNumber)
	-- micro.InfoBar():Message(c.Loc.X)
	-- micro.InfoBar():Message(line)
	return line
end

function Common.getCurrentLineNumber(bp)
	local c = bp.Cursor
	local lineNumber = c.Loc.Y
	return lineNumber
end

function Common.insertTextAtCursor(bp, text)
	local v = micro.CurPane()
	local c = bp.Cursor
	local cs = buffer.Loc(c.Loc.X, c.Loc.Y)
	v.Buf:Insert(cs, text)
end

-- offset is the number of chars to add to new cursor position
function Common.replaceLineAtCursor(bp, text, offsetByNewStringlen)
	-- local v = micro.CurPane()
	local v = bp
	local c = v.Cursor
	local originalCursorLoc = buffer.Loc(c.Loc.X, c.Loc.Y)

	-- Gets start of the line Location
	local startOfLine = buffer.Loc(0, c.Loc.Y)
	-- Get the end of the line
	-- local endOfLine = buffer.Loc(-1, c.Loc.Y)
	local endOfLine = buffer.Loc(#Common.getLineAtCursor(bp), c.Loc.Y)
	v.Buf:Remove(startOfLine, endOfLine)
	-- Insert new line
	v.Buf:Insert(startOfLine, text)

	-- restore previous cursor position
	local newCursorLoc = buffer.Loc(originalCursorLoc.X + offsetByNewStringlen, originalCursorLoc.Y)
	v.Cursor:GotoLoc(newCursorLoc)
end

--
-- output a semi-clever log to a tmp file
--
function Common.devlog(text)
	function add(line)
		outlog = outlog .. line .. "\n"
	end

	if TJConfig.TOJOUR_DEVMODE == false then
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
			for key, value in Common.userdataIterator(text) do
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

-----------------------------------
-- utility file and pane functions
-----------------------------------

--
-- gives a relative file name, which is usually what we want
--
function Common.getRelativeFilepathOfCurrentPane()
	local bp = micro.CurPane()
	local currentFilename = bp.Buf.Path
	return currentFilename
end

function Common.fileExists(name)
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
	else
		return false
	end
end

--
-- get dirname, file from a given full path
--
function Common.getDirNameAndFile(fullpathtofile)
	return filepath.Split(fullpathtofile)
end

--
-- does a file start with a dot?
--
function Common.isFileHidden(filename)
	return Common.strStartswith(filename, "%.")
end

--
-- Check if the given filename of a pane includes a specified suffix like .index.md with 'index' as parameter
function Common.isPanenameMetapane(panename, metasuffix)
	local dirname, filename = Common.getDirNameAndFile(panename)
	if Common.strStartswith(filename, "%.") and string.find(filename, "^.*%." .. metasuffix .. "%.md$") then
		return true
	else
		return false
	end
end

--
-- get a pane's filename meta suffix (if this exists), e.g. index for .xxx.index.md
function Common.getPaneMetaname(panefilename)
	local dirname, filename = Common.getDirNameAndFile(panefilename)
	if Common.isFileHidden(filename) then
		-- check whether file has any of the suffixes
		for i, suffix in pairs(TJConfig.FILE_META_SUFFIXES) do
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
function Common.makeFilepathMetaHidden(filenamepath, metatag)
	local dirname, filename = Common.getDirNameAndFile(filenamepath)
	return dirname .. "." .. Common.strStripExtension(filename) .. "." .. metatag .. ".md"
end

--
-- remove a hidden metatag from a filename and path
--
function Common.removeHiddenFilenameMeta(filename, metatag)
	local dirname, filename = Common.getDirNameAndFile(filename)
	local newfilename = string.gsub(filename, "^%.(.*)%." .. metatag .. "%.md$", "%1")
	return dirname .. newfilename
end

--
-- find if a filename is already open in a tab
--
function Common.findTabname(tabfilename)
	-- notify("found tabfilename: " .. tabfilename)
	for tabIdx, tab in Common.userdataIterator(micro.Tabs().List) do
		for paneIdx, pane in Common.userdataIterator(tab.Panes) do
			-- panes[tonumber(paneIdx)] = pane
			-- devlog(tostring(tabIdx) .. " " .. tostring(paneIdx) .. " " .. pane.Buf.Path)
			local path = pane.Buf.Path
			if path == tabfilename then
				Common.devlog("found tabfilename == " .. tabfilename)
				return tabIdx, paneIdx
			end
			-- also remove leading ./ from URL and try to find a match with the end of the URL
			if Common.strEndsswithStrict(path, string.gsub(tabfilename, "^[%./]*", "")) then
				Common.devlog("Found tab ENDING in " .. tabfilename)
				return tabIdx, paneIdx
			end
		end
	end
	return nil, nil
end

function Common.getWordUnderCursor()
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

function Common.isCurfileTodayfile(bp)
	return bp.Buf.Path == Common.getDateString() .. ".md"
end

--
-- utility function to avoid triggering some functions on filetypes other than markdown
--
function Common.isMarkdown()
	local filetype = micro.CurPane().Buf:FileType()
	if filetype == "markdown" or filetype == "markdownjournal" or filetype == "asciidoc" then
		return true
	end
	if filetype == "unknown" then
		if Common.getFileExtension(micro.CurPane().Buf.Path) == "txt" then
			return true
		end
	end
	return false
end

-- semi-intelligently figures out whether there's a followable link under cursor
-- API: we want this to ALWAYS return a file path of some sort as string (or a url)
function Common.getLinkTagsUnderCursor(bp)
	function run()
		local wordUnderCursor = Common.getWordUnderCursor()
		Common.devlog("word under cursor would be: " .. wordUnderCursor)

		-- special - this is NOT an internal link but external.
		-- therefore bail out and handle diff?
		if Common.strStartswithStrict(wordUnderCursor, "https://") then
			return string.gsub(wordUnderCursor, "[%)]$", "")
		end

		-- TODO: Allow executing bash code here in some special syntax?
		-- shorcuts like bash -c 'git add . && git commit -m "saved"'
		-- code within md? cute (though dangerous?)
		-- But basically like jupyter notebooks (without graphics)
		-- or py: (no, not a word, needs another cmd - alt-b)

		-- strip some trailing punctuation in words
		wordUnderCursor = string.gsub(wordUnderCursor, "[:;,%.]$", "")

		if Common.strStartswithStrict(wordUnderCursor, "[[") and Common.strEndsswithStrict(wordUnderCursor, "]]") then
			-- devlog("Found hashtag style link early: " .. wordUnderCursor)
			local link = string.gsub(wordUnderCursor, "^%[%[", "")
			return string.gsub(link, "%]%]$", "")
		end

		if Common.strStartswithStrict(wordUnderCursor, "[") and Common.strEndsswithStrict(wordUnderCursor, "]") then
			-- devlog("Found wiki style link early: " .. wordUnderCursor)
			local link = string.gsub(wordUnderCursor, "^%[", "")
			link = string.gsub(link, "%]$", "")
			-- we want to avoid triggering on a checked checkbox
			if link ~= "x" then
				return link
			end
		end

		if Common.strStartswithStrict(wordUnderCursor, "#") then
			-- devlog("Found hashtag style link early: " .. wordUnderCursor)
			return string.gsub(wordUnderCursor, "^#", "")
		end

		-- markdown link finder (the start of the word might be a space or a [)
		-- but does NOT work when [cusorishere whenspaces here](https://link) without change to getWordUnderCursor or new bespoke parser just for this
		if
			Common.strEndsswithStrict(wordUnderCursor, ")") and Common.strStartswith(wordUnderCursor, "!?%[?[^%s]+%]%(")
		then
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

		micro
			.InfoBar()
			:Message(
				"No #link, [[link]], [link] or https url found under current cursor in '" .. wordUnderCursor .. "'"
			)
		return ""
	end

	return run()
end

function Common.cmdToggleCheckbox(bp)
	TJPanes:new()

	if TJPanes.curpaneId > 1 then
		-- if we're in the second pane, toggle the checkbox in the first pane
		TJPanes:followInternalLink(bp, 0)
		bp = micro.CurPane()
	end

	-- micro.InfoBar():Message("Toggling checkbox")
	-- Checking for different spellings / variations of a todo list item
	-- notably: `- [ ]` and `- [x]`
	local line = Common.getLineAtCursor(bp)
	if string.find(line, "%- %[ %]") then
		local newline = string.gsub(line, "- %[ %]", "- [x]")
		Common.replaceLineAtCursor(bp, newline, 0)
	elseif string.find(line, "- %[x%]") then
		-- removes checkbox
		-- local newline = string.gsub(line, "- %[x%]%s", "")
		-- untoggles checkbox
		local newline = string.gsub(line, "- %[x%]", "- [ ]")
		Common.replaceLineAtCursor(bp, newline, -6)
	elseif string.find(line, "^[*%[%] \t-]*TODO%s") then
		local newline = string.gsub(line, "^([*%[%] \t-]*)TODO%s", "%1DONE ")
		Common.replaceLineAtCursor(bp, newline, 0)
	elseif string.find(line, "^[*%[%] \t-]*DONE%s") then
		local newline = string.gsub(line, "^([*%[%] \t-]*)DONE%s", "%1TODO ")
		Common.replaceLineAtCursor(bp, newline, 0)
	elseif string.find(line, "- %[/%]") then
		local newline = string.gsub(line, "- %[/%]", "- [ ]")
		Common.replaceLineAtCursor(bp, newline, 0)
	elseif string.find(line, "- %[%-]") then
		local newline = string.gsub(line, "- %[%-%]", "- [ ]")
		Common.replaceLineAtCursor(bp, newline, 0)
	else
		local newline = string.gsub(line, "^(%s*)(.*)$", "%1- [ ] %2")
		Common.replaceLineAtCursor(bp, newline, 6)
	end
	bp:Save()
	TJPanes:refreshSidePaneIfHasContext()
end

-- TODO: Consider refactor of some stuff into
-- TJLineEdit = {}

function Common.incrementPrefixedDateInLine(bp, n)
	if not Common.isMarkdown() then
		return false
	end

	local human_readable_date = ""
	local days_diff_from_today = 0

	local panes = TJPanes:new()

	if panes.curpaneId > 1 then
		-- if we're in the second pane, jump to correct place in first pane and carry out action
		TJPanes:followInternalLink(bp, 0)
		bp = micro.CurPane()
	end

	local function add_days_to_date(date_string, n)
		-- Parse the input date string
		local year, month, day = date_string:match("(%d+)-(%d+)-(%d+)")

		year = tonumber(year)
		month = tonumber(month)
		day = tonumber(day)

		-- Convert the input date to a time table
		local input_date = os.time({ year = year, month = month, day = day, hour = 12 })

		-- Calculate the new date by adding or subtracting 'n' days
		local new_date = input_date + (n * 24 * 60 * 60)

		-- Convert the new date back to a readable format
		local new_date_table = os.date("*t", new_date)
		-- local today_date =
		days_diff_from_today = math.floor(os.difftime(new_date, os.time()) / (24 * 60 * 60) + 1)

		local new_date_string =
			string.format("%04d-%02d-%02d", new_date_table.year, new_date_table.month, new_date_table.day)
		-- local weekdayInt = string.format("%01d", new_date_table.wday)
		local weekdayTable = { "Sunday", "Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday" }
		local monthTable = {
			"January",
			"February",
			"March",
			"April",
			"May",
			"June",
			"July",
			"August",
			"September",
			"October",
			"November",
			"December",
		}
		human_readable_date = " ("
			.. weekdayTable[tonumber(new_date_table.wday)]
			.. ", "
			.. tostring(new_date_table.day)
			.. ". "
			.. monthTable[tonumber(new_date_table.month)]
			.. ")"

		return new_date_string
	end

	local line = Common.getLineAtCursor(bp)
	local founddate = ""
	local newdate = ""
	local newline = ""
	local snoozemsg = ""

	if string.match(line, "@%d%d%d%d%-%d%d%-%d%d") then
		founddate = string.match(line, "@%d%d%d%d%-%d%d%-%d%d")
	elseif string.match(line, TJConfig.today_string) then
		founddate = TJConfig.today_string
	elseif string.match(line, TJConfig.tomorrow_string) then
		founddate = TJConfig.tomorrow_string
		-- TODO: Possibly make it aware of @monday, @tuesday etc too
	end

	if founddate ~= "" then
		local normalised_date = ""
		if founddate == TJConfig.today_string then
			normalised_date = tostring(Common.getDateString(0))
		elseif founddate == TJConfig.tomorrow_string then
			normalised_date = tostring(Common.getDateString(1))
		else
			normalised_date = founddate
		end

		newdate = add_days_to_date(normalised_date, n)

		-- convert the new date to @today, @tomorrow or @2000-01-31 format (or as initialised / configured in settings.json)
		if newdate == tostring(Common.getDateString(0)) then
			newdate = TJConfig.today_string
		elseif newdate == tostring(Common.getDateString(1)) then
			newdate = TJConfig.tomorrow_string
		else
			newdate = TJConfig.date_prefix .. newdate
		end

		-- manually escape the symbols unfortunately for gsub
		newline = string.gsub(line, founddate:gsub("%-", "%%-"), newdate)
		-- days_diff_from_today = " (" .. days_diff_from_today .. " days from today) "
		-- notify("Snoozed by: " .. n .. " days" .. days_diff_from_today .."to " .. newdate .. human_readable_date)
		snoozemsg = "Snoozed " .. days_diff_from_today .. " days from today to " .. newdate .. human_readable_date
	else
		-- days_diff_from_today = " "
		snoozemsg = "Marked item to do " .. TJConfig.today_string
		newdate = TJConfig.today_string
		newline = string.gsub(line, "^(.-)%s*$", "%1 " .. TJConfig.today_string)
	end
	Common.replaceLineAtCursor(bp, newline, 0)

	-- save document
	bp:Save()
	TJPanes:refreshSidePaneIfHasContext()
	micro.InfoBar():Message(snoozemsg)
end

function Common.cmdIncrementDaystring(bp)
	Common.incrementPrefixedDateInLine(bp, 1)
end

function Common.cmdIncrementDaystringByWeek(bp)
	Common.incrementPrefixedDateInLine(bp, 7)
end

function Common.cmdDecrementDaystring(bp)
	Common.incrementPrefixedDateInLine(bp, -1)
end

return Common
