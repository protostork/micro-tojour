local micro = import("micro")
local buffer = import("micro/buffer")
local shell = import("micro/shell")
local config = import("micro/config")

Tests = {}

-- function Self.notifyme(msg)
--     shell.RunCommand(string.format("notify-send %q", msg))
-- end

-- TODO: test = getWordUnderCursor("Sentence http://example.org/123")
-- Ensure at the end of every test, all tabs are closed except /dev/null with tabid = 1
-- by using test_setup() at the beginning of the test, and test_reset() at the end
function Tests.tojourUnitTests(bp)
    passed = 0
    failed = 0
    -- local nullfile = "/dev/null"
    local nullfile = "/tmp/tojour_nullfile"
    -- FIXME: Flaky test tied to readme.md Headings like: t = FileLink:new("#features")
    local filethatexists = TJConfig.PLUGIN_PATH .. "/README.md"
    local tmpfile = "/tmp/tojour.tests.md"
    local output, err = shell.RunCommand("touch " .. tmpfile)

    -- Initialise with /dev/null open in first tab
    local buf, err = buffer.NewBufferFromFile(nullfile)
    micro.CurPane():OpenBuffer(buf)

    local function assertTrue(condition, msg)
        if not condition == true then
            Common.devlog("🔴 FAILED: expected " .. msg) --  .. " was actually " .. tostring(condition))
            Common.notify("🔴 FAILED: expected " .. msg)
            failed = failed + 1
            return false
        end
        Common.devlog("PASSED: " .. msg) -- .. " - was " .. tostring(condition))
        passed = passed + 1
        return true
    end

    local function assertEquals(leftval, rightval, msg)
        return assertTrue(
            leftval == rightval,
            msg .. ' (EXPECTED: "' .. tostring(leftval) .. '" == "' .. tostring(rightval) .. '")'
        )
    end

    local function assertNotEquals(leftval, rightval, msg)
        return assertTrue(
            leftval ~= rightval,
            msg .. ' (EXPECTED: "' .. tostring(leftval) .. '" != "' .. tostring(rightval) .. '")'
        )
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
        assertTrue(
            TJPanes.curpaneFilename == nullfile,
            "test_reset: closed second tab, TJPanes should be nullfile; is: " .. TJPanes.curpaneFilename
        )
        local output, err = shell.RunCommand("rm " .. tmpfile)
    end

    local function test_end_summary()
        local bp = micro.CurPane()
        local test_result_file = "/tmp/micro-tojour-test-result.log"
        local output, err = shell.RunCommand("rm " .. test_result_file)

        local symbol = "🟢 "
        if failed > 0 then
            symbol = "🔴 "
        end
        msg = symbol .. passed .. " tests passed, " .. failed .. " failed."
        micro.InfoBar():Message(msg)
        Common.notify(msg)

        if failed > 0 then
            local output, err = shell.RunCommand("bash -c \"echo '" .. msg .. "' > " .. test_result_file .. '"')
        end
        bp:ForceQuit()
    end

    local function test_OpenDummyPane(curfile, type, text)
        local newpanename = Common.makeFilepathMetaHidden(curfile, type)
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
        assertTrue(
            t.tabid > 1,
            filethatexists .. " tabbed file tabid expected larger than 1, was: " .. tonumber(t.tabid)
        )

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
        assertEquals(t.filewithpath, TJConfig.HOME_DIR .. "/xyz", "can parse $HOME")
        t = FileLink:new("~/xyz")
        assertEquals(t.filewithpath, TJConfig.HOME_DIR .. "/xyz", "can parse ~")

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
        assertTrue(
            TJPanes.curpaneFilename == filethatexists,
            "FileLink:openInternalDocumentLink: TJPanes is filethatexists"
        )

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
        Common.replaceLineAtCursor(bp, "123", 0)
        assertEquals(Common.getLineAtCursor(bp), "123", "line 123 has been written in first line, is ")
        Common.cmdToggleCheckbox(bp)
        Common.cmdToggleCheckbox(bp)
        assertEquals(Common.getLineAtCursor(bp), "- [x] 123", "line 123 has been checked twice and is unchecked, is ")

        -- on 2nd line, making sure it doesn't bleed
        bp:EndOfLine()
        bp:InsertNewline()

        Common.replaceLineAtCursor(bp, "abc", 0)
        assertEquals(Common.getLineAtCursor(bp), "abc", "line abc has been written, is ")

        Common.cmdToggleCheckbox(bp)
        assertEquals(Common.getLineAtCursor(bp), "- [ ] abc", "checkbox abc has been created")

        Common.cmdToggleCheckbox(bp)
        assertEquals(Common.getLineAtCursor(bp), "- [x] abc", "checkbox abc has been checked")

        -- remove this function, checkboxse now stay
        -- cmdToggleCheckbox(bp)
        --EqualsertTrue(getLineAtCursor(bp), "abc", "checkbox abc has been removed")

        Common.replaceLineAtCursor(bp, "abc", 0)
        Common.cmdIncrementDaystring(bp)
        assertEquals(Common.getLineAtCursor(bp), "abc @today", "@today tag inserted")

        Common.cmdIncrementDaystring(bp)
        assertEquals(Common.getLineAtCursor(bp), "abc @tomorrow", "@tomorrow tag inserted")

        Common.cmdIncrementDaystring(bp)
        assertTrue(
            string.match(Common.getLineAtCursor(bp), "abc @%d%d%d%d%-%d%d%-%d%d"),
            "@[0-9]+ date tag inserted, is: "
        )

        Common.cmdDecrementDaystring(bp)
        assertEquals(Common.getLineAtCursor(bp), "abc @tomorrow", "date tag decreased by one")

        Common.cmdToggleCheckbox(bp)
        bp:EndOfLine()
        bp:InsertNewline()

        Common.replaceLineAtCursor(bp, "XYZ", 0)
        Common.cmdToggleCheckbox(bp)
        bp:CursorUp()
        Common.cmdToggleCheckbox(bp)
        assertEquals(Common.getLineAtCursor(bp), "- [x] abc @tomorrow", "just first todo item to be checked: ")
        Common.cmdToggleCheckbox(bp)
        assertEquals(Common.getLineAtCursor(bp), "- [ ] abc @tomorrow", "just first todo item to be unchecked again: ")

        Common.replaceLineAtCursor(bp, "TODO abc", 0)
        Common.cmdToggleCheckbox(bp)
        assertEquals(Common.getLineAtCursor(bp), "DONE abc", "toggling TODO to DONE: ")
        Common.cmdToggleCheckbox(bp)
        assertEquals(Common.getLineAtCursor(bp), "TODO abc", "toggling DONE back to TODO: ")

        Common.replaceLineAtCursor(bp, "* TODO abc", 0)
        Common.cmdToggleCheckbox(bp)
        assertEquals(Common.getLineAtCursor(bp), "* DONE abc", "toggling * TODO to DONE: ")

        Common.cmdToggleCheckbox(bp)
        assertEquals(Common.getLineAtCursor(bp), "* TODO abc", "toggling * DONE back to TODO: ")

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
            Common.replaceLineAtCursor(bp, linetext, cursor_pos)
            local word = Common.getLinkTagsUnderCursor(bp)
            assertEquals(word, expect, msg)
        end

        testWord("#hashtag123 something", 0, "hashtag123", "#hashtag found at start of line: ")
        testWord("[[hashtag123]] something", 0, "hashtag123", "[[hashtag]] found at start of line: ")
        testWord("1234567890 abc [[hashtag123]] something", 15, "hashtag123", "[[hashtag]] found in middle of line: ")
        testWord("1234567890 abc #hashtag123 something", 15, "hashtag123", "#hashtag found in middle of line: ")

        local link = "https://www.example.org/xyz?query=123&test=false"
        testWord("Hello there " .. link .. " something", 15, link, link .. " hyperlink found in middle of line: ")

        local mdlink = "[thisisahyperlink](" .. link .. ")"
        testWord("Hello there " .. mdlink .. " something", 40, link, link .. " md hyperlink found in middle of line: ")
        testWord(
            mdlink .. " something",
            0,
            link,
            link .. " md hyperlink also found in [firstpart_if_theres_no_space](https://etc...): "
        )

        -- TODO: Test artificially passes - fefactor wordundercursor for linkundercursor
        linkwithmanychars = "https://www.example.org/xyz?query=123&test=false" -- if we add ;, or other crapa behind the url it would fail
        testWord(
            "Hello there [thisisahyperlink](" .. linkwithmanychars .. ") something",
            40,
            link,
            link .. " TODO: hyperlink with funny chars NOT found in middle of line: "
        )

        -- local link = "[thisisahyperlink](#internal-reference)"
        testWord("[hyperlink](#internal-reference)", 20, "#internal-reference", "looking for internal hypderlink")
        testWord(
            "[hyperlink](someotherfile#internal-reference)",
            20,
            "someotherfile#internal-reference",
            "looking for internal hypderlink"
        )
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
        assertTrue(session:getSidepane() == "", "session has stored zero side pane state: ")

        FileLink:openInternalDocumentLink(bp, filethatexists)
        -- TJPanes:openSidePaneWithContext('toc', false)
        -- open synchronous sidepane (rather than async which screws with test)
        test_OpenDummyPane(filethatexists, TJConfig.FILE_META_SUFFIXES.toc, "DUMMY TOC CONTENT FOR TESTING")
        local new_session = TJSession:new()
        assertEquals(
            new_session:getSidepane(),
            TJConfig.FILE_META_SUFFIXES.toc,
            "session has stored side pane FILE_META_SUFFIXES.toc state"
        )

        local project_pwd, lines = TJSession:serializeSession(new_session)
        assertTrue(Common.strContains(lines, filethatexists), "filethatexists found in session")
        assertTrue(Common.strContains(lines, tmpfile), "tmpfile found in session")

        local reconstructed_session = TJSession:deserializeSession(project_pwd, lines)
        local new_project_pwd, new_lines = TJSession:serializeSession(reconstructed_session)
        assertTrue(
            project_pwd == new_project_pwd,
            "Reconstructed serialised project_pwd from session is identical: "
                .. project_pwd
                .. " vs "
                .. new_project_pwd
        )
        assertTrue(
            lines == new_lines,
            "Reconstructed serialised lines from session is identical: " .. lines .. " vs " .. new_lines
        )

        -- FileLink:openInternalDocumentLink(bp, "~/.config/micro-journal/plug/tojour/tojour.tutorial.md")
        -- test_reset()
    end

    -- tests.notifyme('bla')
    testFileLink()
    testOpenInternalLink()
    testLineOperations()
    testWordUnderCursor()
    testTJSession()
    test_end_summary()
end

return Tests
