TJConfig = {}

TJConfig.TOJOUR_DEVMODE = false

TJConfig.HOME_DIR = ""
TJConfig.PLUGIN_PATH = ""
TJConfig.HELPER_SCRIPT_PATH = ""
TJConfig.PROJECT_CACHE_TAG_FILENAME = "tojour.tags.txt"

-- Set this to true while currently getting a new TOC, is set by
TJConfig.DEBOUNCE_GET_TOC = false
TJConfig.DEBOUNCE_GET_SIDEPANE = false

-- The suffixes that sidepanes give to files, like .tagname.index.md
TJConfig.FILE_META_SUFFIXES = { index = "index", undone = "undone", toc = "toc" }
TJConfig.FILE_META_HEADER_BEGIN = "-- "
TJConfig.FILE_META_MENU_START = TJConfig.FILE_META_HEADER_BEGIN .. ""
TJConfig.FILE_META_MENU_END = ""

-- store the previous tab that has been open for cmdOpenTodayFile
-- TODO: but improve this, to always get triggered
-- TODO: refactor this into the TJSession
TJConfig.PREVIOUS_TAB_FILENAME = ""

TJConfig.MAIN_PANE_WIDTH_PERCENT = 66 -- tonumber(config.GetGlobalOption("tojour.mainpanewidth"))

TJConfig.date_prefix = ""
TJConfig.today_string = ""
TJConfig.tomorrow_string = ""
TJConfig.habit_string = ""

return TJConfig
