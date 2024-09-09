local micro = import("micro")
local util = import("micro/util")
local shell = import("micro/shell")
local config = import("micro/config")
local buffer = import("micro/buffer")
local strings = import("strings")
local filepath = import("path/filepath")

TJSession = {}
-- Initialise a new TJSession instance, which contains all tabs and wordcount, sidepane, and toc_level
-- Structure: TJSession[project_pwd][file_path_in_tab] = { pane, wordcount, toc_level }
function TJSession:new()
	local project_pwd = TJSession:getProjectPwd()
	if self[project_pwd] == nil and project_pwd ~= nil then
		self[project_pwd] = {}
	end

	for tabIdx, tab in Common.userdataIterator(micro.Tabs().List) do
		local path = ""
		for paneIdx, pane in Common.userdataIterator(tab.Panes) do
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
				self[project_pwd][path].sidepane = Common.getPaneMetaname(pane.Buf.Path)
			end
		end
	end
	return self
end

function TJSession:getProjectPwd()
	-- local bp = micro.CurPane()
	-- bp.PwdCmd()
	return os.getenv("PWD")
end

local function get(attribute)
	local project_pwd = TJSession:getProjectPwd()
	local curtab = micro.CurTab()
	for paneIdx, pane in Common.userdataIterator(curtab.Panes) do
		if paneIdx == 1 then
			return TJSession[project_pwd][pane.Buf.Path][attribute]
		end
	end
end

local function set(attribute, value)
	local project_pwd = TJSession:getProjectPwd()
	local curtab = micro.CurTab()
	for paneIdx, pane in Common.userdataIterator(curtab.Panes) do
		if paneIdx == 1 then
			TJSession[project_pwd][pane.Buf.Path][attribute] = value
		end
	end
end

function TJSession:getSidepane()
	return get("sidepane")
end

function TJSession:setSidepane(val)
	return set("sidepane", val)
end

function TJSession:getWordcount()
	return get("wordcount")
end

function TJSession:setWordcount(val)
	set("wordcount", val)
end

function TJSession:getTocLevel()
	return get("toc_level")
end

function TJSession:setTocLevel(val)
	return set("toc_level", val)
end

-- Very basic implementation onf a serialiser, purely for the session
-- It's not JSON, but perhaps it doesn't have to be?
function TJSession:serializeSession(session_data)
	local filename_escape_char = "╡"
	local line_escape_character = ":"
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
	local filename_escape_char = "╡"
	local line_escape_character = ":"
	function unescape_filename(filename)
		local out = filename
		out = string.gsub(out, "_", "/")
		out = string.gsub(out, filename_escape_char, "_")
		return out
	end

	local lines = Common.strExplode(sessionlines, "\n")
	local session = {}
	project_pwd = unescape_filename(project_pwd)
	session[project_pwd] = {}
	for i, line in pairs(lines) do
		local line_parts = Common.strExplode(line, line_escape_character)
		local last_path = ""
		for k, part in pairs(line_parts) do
			if part == '""' then
				part = ""
			end
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

return TJSession
