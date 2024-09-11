local micro = import("micro")
local buffer = import("micro/buffer")
local shell = import("micro/shell")
local config = import("micro/config")
local filepath = import("path/filepath")

SidepaneContent = {}

function SidepaneContent.TOCIncrement()
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

function SidepaneContent.TOCDecrement()
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

return SidepaneContent
