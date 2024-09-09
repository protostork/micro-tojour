local micro = import("micro")
local buffer = import("micro/buffer")
local shell = import("micro/shell")
local strings = import("strings")
local config = import("micro/config")

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
		tabid, paneid = Common.findTabname(self.filewithpath)
		if tabid ~= nil then
			Common.devlog("confirmed TABNAME exists with " .. self.filewithpath)
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
		Common.devlog(self)
		return self
	end

	if Common.strStartswith(self.filewithpath, "https?://") then
		self.isurl = true
		return onFileFound()
	end

	-- Do poor man's shell expansion of ~tilde and $HOME here already, so lua has access
	if Common.strStartswithStrict(self.filewithpath, "~") then
		self.filewithpath = string.gsub(self.filewithpath, "^~", TJConfig.HOME_DIR)
	elseif Common.strStartswithStrict(self.filewithpath, "$HOME") then
		self.filewithpath = string.gsub(self.filewithpath, "^$HOME", TJConfig.HOME_DIR)
	elseif Common.strStartswithStrict(self.filewithpath, "MICRO_CONFIG") then
		self.filewithpath = string.gsub(self.filewithpath, "^MICRO_CONFIG_DIR", config.ConfigDir)
	end

	-- get linenumbers:123 (if available)
	if Common.strEndsswith(self.filewithpath, ":[0-9]+") then
		-- tonumber needs (()) double brackets to actually convert here strangely
		self.linenum = tonumber((string.gsub(filestring, ".*:([0-9]+)$", "%1")))
		self.filewithpath = string.gsub(filestring, "^(.*):[0-9]+$", "%1")
	end

	-- we probably just found an internal pseudo-anchor markdown link like '#feature-heading' or 'filename#heading-name'
	if Common.strEndsswith(self.filewithpath, "#[a-zA-Z0-9-]+") then
		local fragments = Common.strExplode(self.filewithpath, "#")
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
	self.ext = Common.getFileExtension(self.filewithpath)
	if Common.fileExists(self.filewithpath) then
		Common.devlog("file exists plainly: " .. self.filewithpath)
		return onFileFound()
	end

	-- TODO: should we also add currentPaneDirname for file and look for it?
	-- local currentPaneDirname, filename = getDirNameAndFile(bp.Buf.Path)
	-- if fileExists(currentPaneDirname .. linkstring) then

	-- try adding .md to the end and see if the file exists
	-- (but do not double-add md to the end)
	-- if self.ext == "" or self.ext ~= "md" then
	-- end
	if Common.fileExists(self.filewithpath .. ".md") then
		Common.devlog("found only after added md: " .. self.filewithpath)
		self.filewithpath = self.filewithpath .. ".md"
		self.ext = "md"
		return onFileFound()
	end

	-- last ditch effort to search for file and find first unique hit, if possible
	--    local cmd = string.format("sh -c \"find -type f -not -path '.git' -iwholename '%s' \"", "*/" .. self.filewithpath .. "")
	-- local cmd = string.format("sh -c \"find -type f -not -path '*/.*' \\( -iwholename '%s' -o -iwholename '%s' \\) \"", "*/" .. self.filewithpath .. "", "*/" .. self.filewithpath .. ".md")
	-- local cmd = string.format("sh -c \"fd --type f --full-path '.*/%s(\\.md)?$' ./ \"", self.filewithpath)
	local searchstring = ".*/" .. self.filewithpath .. "(\\.md)?$"
	local cmd = string.format("sh -c 'fd --type f --full-path %q ./ '", searchstring)
	local output, err = shell.RunCommand(cmd)
	if output ~= "" then
		local lines_count = select(2, output:gsub("\n", "\n"))

		if lines_count == 1 then
			output = string.gsub(output, "%c", "")
			if Common.fileExists(output) then
				self.filewithpath = output
				self.ext = Common.getFileExtension(self.filewithpath)
				Common.devlog("found by find: " .. self.filewithpath)
				return onFileFound()
			end
		elseif lines_count > 1 then
			output = string.gsub(output, '"', "'")
			cmd = string.format(
				"sh -c 'echo %q | fzf --prompt \"Jump to root tag document [Esc to search all tags]: \" --select-1 --exit-0'",
				output
			)
			local fzf, fzf_err = shell.RunInteractiveShell(cmd, false, true)
			if fzf ~= "" then
				fzf = string.gsub(fzf, "%c", "")
				if Common.fileExists(fzf) then
					self.filewithpath = fzf
					self.ext = Common.getFileExtension(self.filewithpath)
					Common.devlog("found by fzf: " .. self.filewithpath)
					return onFileFound()
				end
			end
		end
	end
	Common.devlog("nothing found of " .. self.rawlink .. " with filepath " .. self.filewithpath)
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
			if viewer == "" then
				viewer = "xdg-open"
			end
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
	local cmd = string.format(
		"rg --max-count 1 %s --line-number -e %q %q | awk -F: '{print $1}'",
		strict_rg_arg,
		linetext,
		file
	)
	local linenumber, err = shell.RunCommand(string.format("sh -c %q", cmd))
	if err ~= nil then
		Common.devlog("error in ripgrep looking for line number in file")
	end
	if linenumber ~= "" then
		return tonumber(linenumber)
	end
	return 0
end

function FileLink:openFileInCurrentTab(bp, filestring)
	self:new(filestring)
	local dirname, filename = Common.getDirNameAndFile(self.filewithpath)
	if Common.strStartswith(dirname, "%./") then
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
	micro
		.InfoBar()
		:Prompt(
			"Create new file '" .. self.filewithpath .. "'? [press 'y' to proceed]): ",
			"",
			"search",
			function(input)
				return
			end,
			function(input, canceled)
				if not canceled and (input == "y" or input == "Y" or input == "yes") then
					local yaml_frontmatter = "---\ntitle: "
						.. Common.strStripExtension(self.filewithpath)
						.. "\ncreated: "
						.. Common.getDateString(0)
						.. "\n---\n"
					shell.RunCommand(string.format("sh -c 'echo \"%s\" > %q '", yaml_frontmatter, self.filewithpath))
					-- it didn't exist yet, but it does now!
					self.exists = true
					FileLink:_openFile(bp, newtab)
				else
					micro.InfoBar():Message("Cancelled " .. input)
					return
				end
			end
		)
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
	return TJPanes.openAppropriateContextSidePane()
end

return FileLink
