#!/usr/bin/env python3

"""
Parses all markdown files in a folder and:
- copy undone todos from previous day files into today's file 2024-01-02
    - update tags like @tomorrow to @today, or @friday or @2024-01-02 to @today, if applicable
- extract list of [[tagname]] and #tagname strings
- build a network relationship graph of sorts, containing:
    - each tagname and the line of text its on
    - and directly succeeding lines that are indented more deeply by tabs
"""

import datetime
import glob
import os
from sys import stderr
from pprint import pp, pprint
import re
import time
import argparse


class Config:
    """
    Holds configuration and settings
    """
    files_to_process = "md"

    date_prefix = "@"
    habits_string = "@habit"
    tomorrow_string = "@tomorrow"
    today_string = "@today"

    # this is inserted in auto-generated tagname pages after which it lists hardcoded page references and snippets
    breakpoint = "All notes referencing this tag (readonly)"
    breakpoint_sep = "========================================="

    # ignore lines starting with these strings in compiling 'pseudotag' pages from folders
    # This strips out Joplin metatext strings in notes in a tagname/ directory, so they are not copied into .tagname.md pages
    for_pseudotag_ignore_lines_starting_with = ('title:', 'updated:', 'created:', 'latitude:', 'longitude:', 'altitude:')

    tabsize = 4


class Arg:
    """
    Parse the command line arguments
    """
    args = None

    @staticmethod
    def parse_cli_args():
        # This will alwyas be run by isset if we have no args defined yet
        arg_parser = argparse.ArgumentParser(description='Process Todo / Journal markdown files')
        # argParser.add_argument('integers', metavar='N', type=int, nargs='+',
        # 					help='an integer for the accumulator')
        # Stores the --file=bla in args.testfile
        arg_parser.add_argument('--file', dest='testfile', action='store',
                                help='parse a specific file rather than all')
        arg_parser.add_argument('--tag', dest='filterbytagname', action='store',
                                help='if --verbose, then filter output by one tagname')
        arg_parser.add_argument('--today', dest='today', action='store_true',
                                help='only write boilerplate and undone todos into a today file from a previous day')
        arg_parser.add_argument('--dry-run', dest='dryrun', action='store_true',
                                help='simulate a dry run, never write to disk')
        arg_parser.add_argument('--write', dest='write', action='store_true',
                                help='Write files to disk as .tagname.md dotfiles instead of stdout')
        arg_parser.add_argument('--verbose', '-v', dest='verbose', action='count', default=0,
                                help='use once to dump some information, up to -vvv to dump lots and lots of info for grep')
        arg_parser.add_argument('--stats', dest='stats', action='store_true',
                                help='gather and output statistics about run')

        Arg.args = arg_parser.parse_args()

    @staticmethod
    def isset(argname: str) -> bool:
        # if argname in vars(Arg.args) and ( vars(Arg.args)[argname] or vars(Arg.args)[argname] == 0):
        # if argname in vars(Arg.args) and ( vars(Arg.args)[argname]):
        if argname in vars(Arg.args) and vars(Arg.args)[argname]:
            return True
        else:
            return False

    @staticmethod
    def get(argname: str) -> str:
        if Arg.isset(argname):
            return str(vars(Arg.args)[argname])
        else:
            return ""

    @staticmethod
    def verbose() -> int:
        return int(vars(Arg.args)['verbose'])


class Main:
    """
    Start here, initialise everything
    """
    files_parsed: int = 0
    files_written: int = 0
    files_dryrunned: int = 0
    files_processed: int = 0
    taglines_recorded: int = 0
    perf_timer = {}
    stats_enabled = False
    writefiles = False

    def __init__(self) -> None:
        # Main initialises a bunch of stuff we need, and stores some Args it locally for faster access
        Arg.parse_cli_args()
        if Arg.isset('stats'):
            Main.stats_enabled = True

        if Arg.isset('stats'):
            Main.startwatch('main')

        if Arg.isset('write'):
            Main.writefiles = True

        # Initialise View and Taxonomy
        View()
        Taxonomy()

    @staticmethod
    def exit(errorcode=0, message=""):
        if Main.stats_enabled:
            Main.stopwatch('main')
            View.print("---")
            View.print("Files processed: " + str(Main.files_processed))
            View.print("Files parsed: " + str(Main.files_parsed))
            View.print("Files written: " + str(Main.files_written))
            if Arg.isset('dryrun'):
                View.print("File writes simulated: " + str(Main.files_dryrunned))
            View.print("Tags found: " + str(len(Taxonomy.tags)))
            View.print("Tagged lines recorded: " + str(Main.taglines_recorded))
            Main.showwatchall()

        if message:
            View.error(message)
        exit(errorcode)

    @staticmethod
    def startwatch(timername):
        # For performance reasons, use the locally set property
        if Main.stats_enabled is True:
            if timername not in Main.perf_timer:
                Main.perf_timer[timername] = {}
                Main.perf_timer[timername]['counter'] = 0
            Main.perf_timer[timername]['start'] = time.monotonic()

    @staticmethod
    def stopwatch(timername):
        if Main.stats_enabled is True:
            if Main.perf_timer[timername]['start'] == 0:
                Main.exit(1, "Can not stop timer twice that has not been re-started: " + timername)
            Main.perf_timer[timername]['stop'] = time.monotonic()
            if 'elapsed' not in Main.perf_timer[timername]:
                Main.perf_timer[timername]['elapsed'] = 0
            Main.perf_timer[timername]['elapsed'] += Main.perf_timer[timername]['stop'] - Main.perf_timer[timername]['start']
            Main.perf_timer[timername]['start'] = 0
            Main.perf_timer[timername]['counter'] += 1

    @staticmethod
    def showwatch(timername):
        if Main.stats_enabled is True:
            warning = ""
            if Main.perf_timer[timername]['counter'] > 1000:
                warning = " [WARNING: comment out this stopwatch in production, called more than 1000 times and may noticebly impact performance in reality]"
            percentageofmain = '100'
            # Fallback to show watch in case it hasn't been stopped yet
            if 'elapsed' not in Main.perf_timer[timername]:
                Main.stopwatch(timername)
            if timername != 'main':
                percentageofmain = str(round(Main.perf_timer[timername]['elapsed'] / Main.perf_timer['main']['elapsed'] * 100, 1))
            View.print("Stopwatch (" + timername + "): " + str(round(Main.perf_timer[timername]['elapsed'], 3)) + " sec (" + percentageofmain + "% of main), called " + str(Main.perf_timer[timername]['counter']) + " times" + warning)

    @staticmethod
    def showwatchall():
        if Main.stats_enabled is True:
            for timername in Main.perf_timer:
                Main.showwatch(timername)

    @staticmethod
    def run_main():
        # Files().populate_filelist()

        # only update today's file like 2024-01-02.md
        if Arg.isset('today'):
            DailyFile().populate_daily_file()
            Main.exit()

        # Debug testing mode only
        if Arg.isset('testfile'):
            file = File(Arg.get('testfile'))
            View.dump("*********** FILE DATA", 3)
            View.dump(file.display_file_object(), 3)

            parser = Parser(file)
            parser.parse_file()
            View.dump("*********** TAXONOMY DATA ", 3)

            View.preview_parsed_data()
        else:
            if not Arg.isset('filterbytagname'):
                # Normal run, parse all files
                DailyFile().populate_daily_file()

            # This can be run even when Arg.isset('filterbytagname'), they just grab it from there directly
            Main.startwatch('parse_markdown_files')
            Files().parse_markdown_files()
            Main.stopwatch('parse_markdown_files')
            Files().output_collected_tags()
            # if Arg.verbose():
            #     for key, file in Files._filelist.items():
            #         View.dump(key)
            #         View.dump(str(file.content))

        if Arg.verbose():
            if Arg.isset('filterbytagname'):
                View.preview_parsed_data_by_tagname(Arg.get('filterbytagname'))
            else:
                # if verbose, let's preview all parsed data
                View.preview_parsed_data()

        Main.exit()


class File():
    """
    File object that contains a markdown file's contents and other things
    """
    full_filename: str
    dirname: str
    filename: str
    _content: list
    permalink: str
    modified: float
    created: float
    is_root_file: bool
    _slug: str
    _note_title: str

    def __init__(self, filename: str) -> None:
        self.full_filename: str = filename  # Original supplied filename with .md
        self.dirname: str = os.path.dirname(self.full_filename)  # directory name
        self.filename: str = os.path.basename(self.full_filename)  # file with basepath
        self._content: list = []
        self.permalink: str = self.strip_md_extension(self.full_filename)
        self.modified: float = os.path.getmtime(self.full_filename)
        self.created: float = self.get_inferred_created_date()
        self.is_root_file: bool = self.set_root_file()
        self._slug: str = ""  # self.slug() # a unique string for file to use as key
        self._note_title: str = ""
        # Files().add_file(self)

    @property  # when you do File.content, it will call this function like a getter
    def content(self) -> list:
        '''
        file._content is literally just an array of lines?
        '''
        if not self._content:
            try:
                with open(self.full_filename, "r") as file:
                    self._content = file.readlines()
            except UnicodeDecodeError:
                # Does a check to see if the file is binary / corrupt, and sort send a warning
                print("FATAL ERROR: " + self.full_filename + " unexpectedly looks like a binary file. This is either a bug or one of your markdown files is corrupted. Please take a look?")
                pass

        return self._content

    @content.setter
    def content(self, content: list):
        self._content = content

    def save_to_disk(self):
        '''
        Save file content to disk
        '''
        if Arg.isset('dryrun'):
            View.dump("simulating save_to_disk, not writing file: " + self.filename, 1)
            Main.files_dryrunned += 1
            return False

        if Main.writefiles is False:
            print("".join(self.content))
            Main.exit(0)
            return True

        with open(self.filename, "w") as file:
            print("".join(self.content), file=file)
            View.dump("save_to_disk wrote file: " + self.filename, 3)
            Main.files_written += 1

    def strip_md_extension(self, string):
        return re.sub(r"\.md$", "", string)

    def get_modified_date(self) -> str:
        return time.ctime(self.modified)

    def get_inferred_created_date(self) -> float:
        lookfordate = re.findall(r"^([1-2][0-9]{3}\-[0-1][0-9]\-[0-3][0-9])", self.filename)
        if lookfordate:
            createddate = datetime.datetime.strptime(lookfordate[0], "%Y-%m-%d")
            unixtime = datetime.datetime.timestamp(createddate)
            return unixtime
        else:
            return self.modified

    def display_file_object(self) -> None:
        """
        Preview / display what's in the file object
        """
        pp(vars(self))

    def set_root_file(self):
        """
        If the filename(sans .md) is the same name as the directory name
        we are talking about a rootfile - i.e., for diary / diary a collection
        of all diary tags in that file ( and maybe make it read only)
        FIXME: Also check if a sub - directory with name exists, in case they're siblings
        """
        # This file name is a root file, since its name is identical to the directory name
        strippedfilename = self.strip_md_extension(self.filename).lower()
        if strippedfilename in Files.dirnames:
            return True
        if self.dirname.lower() == strippedfilename:
            return True
        # if it is a file that does not start with 2022-05-18? Works fine-ish, since those that don't have tags won't get populated later
        if not re.match(r"^20\d\d-[1-2]\d-[0-3]\d", strippedfilename):
            # elif strippedfile in Taxonomy.tags:
            # Or, if it is a file that also exists as a tagname? Fundamental problem is - we don't have these yet
            return True
        return False

    @property
    def note_title(self) -> str:
        if self._note_title:
            return self._note_title

        self._note_title = self.full_filename.strip("#").strip()
        # elif len(self.dirname):
        #     # Remove dirname from file title to make more readable
        #     title = re.sub(r"^" + self.dirname + "", "", self.full_filename)
        # Converts spaces and other guff to _ so it can be used in TOCs
        # title = self.strip_md_extension(re.sub(r"[\-/ ]+", "_", title))
        return self._note_title

    @property
    def slug(self):
        """
        Create an alphanumeric slug for use in dicts etc
        """
        if self._slug:
            return self._slug

        if self.is_root_file:
            # View.dump("SLUGINGROOT of " + self.filename)
            slugbase = self.strip_md_extension(self.filename)
        else:
            slugbase = self.strip_md_extension(self.full_filename)

        # remove non-alphanumerics and not . and -, and lowercase the slug
        self._slug = re.sub(r"[^a-zA-Z0-9/\.\-]", "", slugbase).lower()
        return self._slug


class Tag:
    """
    Simple place to store all tags found
    """
    content: list
    permalink: str
    slug: str
    title: str
    linenumber: int  # The source line number this content originally lives in
    tagname: str


class Taxonomy:
    """
    Final taxonomy gets saved into this class
    """
    tags: dict = {}  # Semi-global class variable, can also be accessed statically from elsewhere

    @staticmethod
    def add_line_to_tag(file: File, line: str, tag: str, linenumber=0, level=0):
        # Main.startwatch('addLineToTag')
        tag_key = tag.lower()
        # Do NOT put cross-references in here if it's from the tagname file itself
        # so it does not double duplicate the content in .tagname in the sidepane
        if tag_key == file.slug:
            return False

        # This is messy: basically, multiply the starting tabs by level
        line = re.sub(r"^[\s\t]*", "\t" * level, line.rstrip("\n\r"))

        Taxonomy().add_tag(file, tag_key, line, linenumber)
        # Main.stopwatch('addLineToTag')
        View.dump("Taxonomy().addLineToTag added to tagKey: " + str(tag_key) + ", " + line, 3)

    def add_tag(self, file: File, tag_key: str, line: str, linenumber: int):
        if tag_key not in Taxonomy.tags:
            # Should this not combine tags case insensitively?
            # Might be possible if looking for .md files without case
            Taxonomy.tags[tag_key] = {}

        # just append to 'content' key if it already exists, so we don't duplicate [[2022-05-16]] stuff
        uniquetimestamp = str(file.created) \
            + ":" + str(file.modified) \
            + file.slug

        if uniquetimestamp in Taxonomy.tags[tag_key]:
            # adds content to the end of a uniquetimestamped tag element
            # Taxonomy.tags[tagKey][uniquetimestamp][-1]['content'].append(line)
            Taxonomy.tags[tag_key][uniquetimestamp][-1].content.append(line)
        else:
            # create new full key with all meta data
            tagdata = Tag()
            tagdata.content = [line]
            tagdata.permalink = file.permalink
            tagdata.slug = file.slug
            tagdata.title = file.note_title
            tagdata.linenumber = linenumber  # The source line number this content originally lives in
            tagdata.tagname = tag_key

            Taxonomy.tags[tag_key][uniquetimestamp] = []
            # Taxonomy.tags[tagKey][uniquetimestamp].append(insertion)
            Taxonomy.tags[tag_key][uniquetimestamp].append(tagdata)

        if Main.stats_enabled is True:
            Main.taglines_recorded += 1

    def get_tag_data(self, tag_key: str, uniquetimestamp: str):
        return Taxonomy.tags[tag_key][uniquetimestamp]

    def create_tag(self, tag):
        # Taxonomy.tags[tag] = {}
        # Taxonomy.tags[tagKey][uniquetimestamp][-1]['content'] += line
        pass


class Files():
    '''
    Generates a list of all markdown files and pre-processes their contents, reading into memory
    '''
    _filelist: dict = {}  # A clean dict of file objects, with attributes for each, the key is the fileslug
    dirnames = ()  # parser = None
    _file: File

    def __init__(self) -> None:
        def get_dir_names():
            # Lowercase dirs (includes .vscode and .git) with a nice map + lambda
            return tuple(map(lambda x: x.lower(), next(os.walk('.'))[1]))

        if not self.dirnames:
            Files.dirnames = get_dir_names()
        if not self._filelist:
            self.populate_filelist()

    @property
    def filelist(self) -> dict:
        return Files._filelist

    def get_file(self, fileslug: str) -> File:
        return Files._filelist[fileslug]

    def add_file(self, file: File):
        Files._filelist[file.slug] = file

    def populate_filelist(self):
        """
        Gets array of all markdown files in folder
        """
        def get_markdown_files_by_extension(file_ext_glob: str) -> list:
            markdown_fileslist = glob.glob(file_ext_glob, recursive=True)
            return markdown_fileslist

        # Parse all markdown files in the folder
        if Arg.isset('filterbytagname'):
            tagname = Arg.get('filterbytagname').lower()
            # tagnameRegex = "\\[\\[" + tagname + "\\]\\]|#" + tagname
            # tagname_regex = "\\[\\[" + tagname + "\\]\\]|#" + tagname
            tagname_regex = "\\[\\[" + tagname + "\\]\\]\\|#" + tagname
            # get all files with ripgrep that contain variable tagname
            filelist = os.popen("grep  --include='*.md' --exclude='.*' --exclude-dir='.*' -ir --files-with-matches '" + tagname_regex + "'").read()
            files = str.splitlines(filelist)
            # NB: For subprocess you also need to supply PWD, os.popen inherits more easily in micro Lua JobSpawn
            # filelist = subprocess.run(["grep", "--include='*.md'", "-ir", "--files-with-matches", tagname_regex], capture_output=True, text=True)
            # files = str.splitlines(filelist.stdout)
            # NB: Ripgrep for some reason doesn't work inside a lua JobStart + popen, weird
            # filelist = os.popen("rg --threads=1 -g '**/*.md' -g '!.*' -i --no-hidden --files-with-matches '" + tagname_regex + "'").read()

            View.dump("Files.populate_filelist rg filtered by tagname found: " + str(filelist), 2)

            # Manually add currentagname file so it generates for ones that are not root (?)
            filethathastagname = os.popen("fd -i --extension 'md' '" + tagname + ".md'").read()
            # filethathastagname = os.popen("find -iname '" + tagname + ".md'").read()

            View.dump("Files.populate_filelist manually added find tagname file: " + filethathastagname, 3)
            # TODO: Question: How to deal with more than one file of tagname.md in diff subdirectories?
            # TODO: Consider - when more than one file ends in tagname.md, this just adds both files to list now
            if filethathastagname:
                files = files + str.splitlines(filethathastagname)

            for file in files:
                View.dump("Filtering by tagname in file: " + file, 1)
                file = File(file)
                self._filelist[file.slug] = file
                Main.files_processed += 1
        else:
            # filelist = os.popen("fdfind --extension 'md'").read()
            # files = str.splitlines(str(filelist))
            # for mdFile in files:
            for md_file in get_markdown_files_by_extension("**/*." + Config.files_to_process):
                # if os.path.isfile(mdFile):
                # Make dict of files with lowercase filename key, each containing a file object
                file = File(md_file)
                self._filelist[file.slug] = file
                Main.files_processed += 1

    def parse_markdown_files(self):
        # Custom sort function
        def custom_sort(item):
            # Extracting the numerical part 2024xxx and the alphabetical part of the key and sticking it at front of sortkey
            number = "".join(re.findall(r'\d{4}(?:\-?[0-9]{2}){0,2}', item))
            if not number:
                number = "0000"
            letters = re.sub(r'[^a-zA-Z]+', '', item)
            # if number and letters:
            # print("parse_mark ITEM: " + item + " and sortkey: " + number + letters)
            return number + letters
            # return (number, letters)

        if not self.filelist:
            print("No markdown files found with this tag")
            Main.exit(0)
        # Now parse all files (now that we have the full filelist), sorted alphabetically
        # and ignore folder names for the todosort (and others) with the re.sub lambda
        # for fileslug in {k: v for k, v in sorted(self._filelist, key=custom_sort)}:
        # for fileslug in sorted(self._filelist, key=lambda x: str(re.sub(r'^[^/]+/', '', x)), reverse=True):
        # Try to sort by numerical only, ignoring alphas as sort key
        # for fileslug in sorted(self._filelist, key=lambda x: str(re.sub(r'[^0-9]+', '', x)), reverse=True):
        for fileslug in sorted(self._filelist, key=custom_sort, reverse=True):
            View.dump("parse_markdown_files, parsing fileslug " + fileslug + ": " + str(self._filelist[fileslug].filename), 2)

            # TODO: Re-understand: How does this ignore files like write/write.md? and does it ignore files like /write.md?
            # Maybe, This kicks in at the parser level with is_file_part_of_dir_collection:
            # only if a file also exists as tagname/tagname.md, then does it write those tags?
            # NO, I got it: stop_parsing_file_at_breakpoint is the secret - NOTHING after the ===readonly=== string breakpoint is reparsed.
            # Clever or good? Hard to say :)

            # Initialise parser instance for this file & parse, this is very fast
            parser = Parser(self._filelist[fileslug])
            # Main.startwatch('parse files')
            parser.parse_file()
            # Main.stopwatch('parse files')

    def output_collected_tags(self):
        def prepare_front_matter_toc(file: File) -> list:
            # Adds basic TOC stuff
            toc = list()
            if len(file.content):
                toc.append("# " + file.slug)
                toc.append("")
                toc.append("## [[" + file.slug + "]]")
                toc.append("(file empty)" if not len(file.content) else "(" + str(len(file.content)) + " lines)")
                toc.append("")
            return toc

        def collect_all_matching_tags_from_taxonomy(tag_key: str) -> list:
            file_content_with_tags: list = []
            # key: str
            xrefs: list
            # for key, xrefs in Taxonomy.tags[file.slug].items():
            if tag_key not in Taxonomy.tags:
                print("Tag not found")
                Main.exit(1)
                # return ["Tag not found"]
            for key, xrefs in Taxonomy.tags[tag_key].items():
                xref: Tag
                for index, xref in enumerate(xrefs):
                    # Only show the permalink [[2022-05-16]] the first time
                    if index == 0:
                        # fileContentWithTags.append("")
                        # file_content_with_tags.append("## " + heading)
                        # Line numbering is broken
                        # file_content_with_tags.appejnd("## [[" + xref.permalink + ":" + str(xref['linenumber']) + "]]\n\t" + xref['content'])

                        # Initially put tagheadline above xref content like: ## [[tagname:24]]
                        # heading = xref['title']
                        heading = "## [[" + xref.permalink + ":" + str(xref.linenumber) + "]]"
                        file_content_with_tags.append(heading)

                        # file_content_with_tags.append("".join(xref.content))
                        for contentline in xref.content:
                            file_content_with_tags.append(contentline)

                        # Comment this out to REMOVE full verbose TOC
                        # toc.append("- [" + fileslug + "](" + "##" + heading + ")")

                    # FIXME: this never kicks in apparently: there's only ever a single xref per
                    else:
                        View.dump("FIXME: LINE 375 Loop was Triggered", 0)
                        # file_content_with_tags.append("\t" + "".join(xref.content))
                        for contentline in xref.content:
                            # file_content_with_tags.append("\tFIXME: XXXLine375" + xref.content)
                            file_content_with_tags.append("\tFIXME: XXXLine375")

                # Add empty element so we get a line break at the end of each item
                file_content_with_tags.append("")
            return file_content_with_tags

        def prepare_file_contents(file: File) -> list:
            file_content_with_tags = []
            # TODO: Refactor file_content_with tags into a method, perhaps in taxonomy class?

            # toc.append("## [[" + file.slug + "]](#" + file.slug + ")")
            # toc.append("")

            toc = prepare_front_matter_toc(file)
            tag_key = file.slug
            file_content_with_tags = collect_all_matching_tags_from_taxonomy(tag_key)
            # NB: This creates the 'front-matter' in .tagname.md files by taking file.content from tagname.md
            # front matter now hidden, since visible side-by-side in micro journal
            # for line in file.content:
            #     if not str.isspace(line):
            #         file_content_with_tags.append(line.rstrip("\n\r"))
            # file_content_with_tags.append("")

            # NB: This creates the 'front-matter' in .tagname.md files by taking file.content from tagname.md
            # front matter now hidden, since visible side-by-side in micro journal
            # for line in file.content:
            #     if not str.isspace(line):
            #         file_content_with_tags.append(line.rstrip("\n\r"))
            # file_content_with_tags.append("")

            # Remove TOC completely
            # return [Config.breakpoint] + [""] + file_content_with_tags
            if Main.writefiles is False:
                return toc + file_content_with_tags

            return toc + file_content_with_tags

        View.dump("Outputting collected tags now", 1)

        View.dump("output_collected_tags, dumping full Taxonomy.tags next: ", 2)
        View.dump(Taxonomy.tags, 2)

        View.dump("try output_collected_tags fileist.items: [" + ', '.join(self._filelist) + "]", 3)
        for fileslug, file in self._filelist.items():
            # Effectively only act on items that are root tags
            View.dump("try output_collected_tags with Fileslug (" + fileslug + "), and file.filename: " + str(file.filename), 2)

            if fileslug in Taxonomy.tags:
                View.dump("output_collected_tags found fileslug in .tags, writing to: " + fileslug, 2)

                file_content_with_tags = prepare_file_contents(file)

                if Main.writefiles is False:
                    print("\n".join(file_content_with_tags))
                    Main.exit(0)
                    return True

                # Whenever there are any files that have tags and a tagname.md exists somewhere, create a .tagname.md file?
                # Create a hidden .tagname.md file with name
                tagfile_prefix = "."
                tagfile_name = tagfile_prefix + file.filename
                if file.dirname:
                    tagfile_name = file.dirname + "/" + tagfile_name
                # View.dump(vars(file))

                # Remove readonly from file before writing https://stackoverflow.com/questions/28492685/change-file-to-read-only-mode-in-python
                # os.chmod(file.full_filename, S_IWUSR|S_IREAD)
                if Arg.isset('dryrun'):
                    View.dump("In simulation, output_collected_tags not writing file: " + tagfile_name, 2)
                    Main.files_dryrunned += 1
                    return True
                else:
                    View.dump("save_to_disk writing file: " + tagfile_name, 1)
                    with open(tagfile_name, "w") as write_file:
                        print("\n".join(file_content_with_tags), file=write_file)
                        Main.files_written += 1
                    # mark file as readonly after writing
                    # os.chmod(file.full_filename, S_IREAD|S_IRGRP|S_IROTH)
                    return True
                # if Arg.verbose() >= 3:
                    # View.dump("output_collected_tags to dump full joined filecontent next: ", 3)
                    # View.dump("\n".join(fileContentWithTags), 3)

        # Very simple fallback, when tagname.md does not exist and only outputting one filtered tagname to stdout, skip the frontmatter stuff
        if Arg.isset('filterbytagname') and Main.writefiles is False:
            View.dump("No tagname.md found, but fallback outputting collected tag content now: ", 1)
            tag_key = Arg.get('filterbytagname').lower()
            file_content_with_tags = collect_all_matching_tags_from_taxonomy(tag_key)
            print("\n".join(file_content_with_tags))
            Main.exit(0)
            return True


class DailyFile():
    '''
    Creates today's file by copying habits and
    undone todos from the nearest previous date's file
    '''
    today: datetime.date
    yesterday: str
    todayfile: File
    yesterdayfile: File
    today_yaml_frontmatter: dict
    frontmatter_autogenerated_keyword: str = "autogenerated"
    today_journal_title: str = "Daily Journal of " + str(datetime.date.today())
    old_frontmatter_linepos_end = 0
    ordered_todos = {}

    def __init__(self) -> None:
        self.today: datetime.date = datetime.date.today()
        if not Files().filelist:
            Files()
        self.yesterday = self.get_last_file_before_today(self.today)
        if not self.yesterday:
            View.error("Try again tomorrow? No previous date file found before " + str(self.today) + ".md.")
            Main.exit(0)
        self.yesterdayfile = Files().get_file(self.yesterday)

    # Get the most recent previous diary file before today
    def get_last_file_before_today(self, todaydate: datetime.date) -> str:
        yesterday: datetime.date = todaydate - datetime.timedelta(days=1)  # Yesterday's date as a string like 2022-05-29
        i = 0
        while i < 365:
            if str(yesterday) in Files._filelist:  # and len(Files._filelist[str(yesterday)].content) > 0:
                return str(yesterday)
            else:
                yesterday: datetime.date = yesterday - datetime.timedelta(days=1)
            i += 1
        return ""

    def populate_daily_file(self):
        def run():
            if str(self.today) in Files().filelist:
                self.todayfile = Files().get_file(str(self.today))
                View.dump("Today file is: " + self.todayfile.filename, 1)
                # Get contents that was already in today file, if any
                # if Config.habits_string not in self.pre_existing_today_content:
                self.today_yaml_frontmatter = get_pre_existing_yaml_frontmatter_if_any()
                if self.today_yaml_frontmatter:
                    if self.frontmatter_autogenerated_keyword in self.today_yaml_frontmatter and not Arg.isset('dryrun'):
                        View.dump("Today's file has already been automatically processed before, not writing into it again", 1)
                        Main.exit(1)

                # for extra-safety, avoid writing into any file that has any significant content
                # if len(self.todayfile.content) < 4 or Arg.isset('dryrun'):
                    # self.pre_existing_today_content = []
                self.todayfile.content = create_daily_file_content_from_yesterday()
                if Arg.isset('dryrun'):
                    print("".join(self.todayfile.content))
                else:
                    self.todayfile.save_to_disk()
                # Mark yesterday's file all as undone (in dry-run, it won't get saved)
                mark_all_undone_in_file(self.yesterdayfile)

                # else:
                #     View.dump("Today's file already has content, not writing into it", 1)

        def get_pre_existing_yaml_frontmatter_if_any() -> dict:
            yaml_frontmatter = {}
            if len(self.todayfile.content) > 1:
                # If there's already a yaml frontmatter, then return it
                for i, line in enumerate(self.todayfile.content):
                    # if file does not start with ---, we have zero yaml frontmatter
                    if i == 0 and str.strip(line) != "---":
                        return {}
                    # Iterate through each line of the file until we hit "---" again and return frontmatter then
                    elif i > 0 and str.strip(line) == "---":
                        self.old_frontmatter_linepos_end = i
                        return yaml_frontmatter
                    # elif ":" not in line:
                    #     # If not reached end of frontmatter yet, immediately bail with nothing if a line doesn't have a key value pair
                    #     return {}

                    linesplit = str.split(line, ":", 1)
                    if len(linesplit) == 2:
                        yaml_frontmatter[linesplit[0].strip()] = linesplit[1].strip()

            return {}

        def create_daily_file_content_from_yesterday() -> list:
            View.dump("Yesterday's file is: " + self.yesterdayfile.filename, 1)
            return generate_and_get_markdown_yaml_front_matter() \
                + generate_top_boilerplate() \
                + get_pre_existing_today_content_without_frontmatter() \
                + get_everything_except_undone(self.yesterdayfile)

        def generate_and_get_markdown_yaml_front_matter() -> list:
            self.today_yaml_frontmatter.setdefault("title", self.today_journal_title)
            self.today_yaml_frontmatter.setdefault(self.frontmatter_autogenerated_keyword, str(datetime.date.today()))
            self.today_yaml_frontmatter.setdefault("created", str(datetime.date.today()))

            # Generate yaml-ish frontmatter list for returning and making content from
            if self.today_yaml_frontmatter:
                frontmatter = []
                frontmatter.append("---\n")
                for key, value in self.today_yaml_frontmatter.items():
                    frontmatter.append(key + ": " + value + "\n")
                frontmatter.append("---\n")
                frontmatter.append("\n")
                return frontmatter

            return []

        # Generates basic header for a diary file
        def generate_top_boilerplate() -> list:
            prefix_boilerplate = []
            prefix_boilerplate.append("# " + get_human_timestamp_with_dayofweek(self.today) + "\n")
            prefix_boilerplate.append("- [" + get_human_timestamp(self.today) + "](#" + get_human_timestamp(self.today).lower() + ")\n\n")
            prefix_boilerplate.append("# Diary\n")
            prefix_boilerplate.append("[[diary]]\n\n")
            return prefix_boilerplate

        def get_human_timestamp(today: datetime.date) -> str:
            return str(today.strftime("%d %B %Y"))

        def get_human_timestamp_with_dayofweek(today: datetime.date) -> str:
            return str(today.strftime("%d %B %Y, %a"))

        # Gets all undone todo items from another file (usually the previous day)
        def get_everything_except_undone(file: File) -> list:
            content = file.content
            within_yaml_frontmatter = False
            # todos_reached = False
            # todo_category = "" # make this local scope
            ordered_todos = {Config.habits_string: [], "new_found_today_todos": [], Config.today_string: [], "default": []}
            for index, line in enumerate(content):
                # Don't include any previous yaml front matter
                if index == 0:
                    if str.strip(line) == "---":
                        within_yaml_frontmatter = True
                if within_yaml_frontmatter:
                    if str.strip(line) == "---":
                        within_yaml_frontmatter = False
                    continue

                todo_category = ""
                if Config.habits_string in line or "@daily" in line:
                    # Line contains a @habit todo, so let's repeat it again today
                    line = convert_futuredates_to_todays(Parser.mark_todo_undone(line))
                    todo_category = Config.habits_string
                    ordered_todos[todo_category].append(line)
                elif Parser.is_line_undone_todo(line):
                    todo_category = 'default'
                    # Line is a todo that's not done (ie "- [ ]") from yday
                    if Config.today_string in line:
                        todo_category = Config.today_string
                    elif does_line_have_tomorrowdate(line):
                        # Converts @tomorrow, @2024-06-15, etc to @today, if it's today
                        line = convert_futuredates_to_todays(Parser.mark_todo_undone(line))
                        todo_category = 'new_found_today_todos'
                    else:
                        # If we haven't run this script in a while, we may have missed older @1990-08-05 type dates
                        # because above only checks if today's date equals @1990-08-05. This grabs those:
                        longpastdate = does_line_have_longpastdate(line)
                        if longpastdate and type(longpastdate) is str:
                            line = line.replace(longpastdate, Config.today_string)
                            todo_category = 'new_found_today_todos'

                    ordered_todos[todo_category].append(line)

                # If at least one habit has been found already
                # check previous lines for a headline,
                # and add it above this todo item
                if todo_category:
                    previous_line = content[index - 1]
                    if index >= 2 and re.match(r"^\s*", previous_line):
                        previous_line = content[index - 2]
                    if index >= 1 and re.match(r"^#{1,6}\s", previous_line):
                        penultimate_list_pos = len(ordered_todos[todo_category]) - 2
                        ordered_todos[todo_category].insert(penultimate_list_pos, previous_line)

            # add new today todos to top of today list
            if ordered_todos["new_found_today_todos"]:
                ordered_todos[Config.today_string] = ordered_todos["new_found_today_todos"] + ordered_todos[Config.today_string]

            return ordered_todos[Config.habits_string] + ["\n"] + ordered_todos[Config.today_string] + ["\n"] + ordered_todos["default"]

        def does_line_have_longpastdate(line: str) -> str | bool:
            # Do we have any date on the line?
            datematch = re.search(Config.date_prefix + r"[0-9]{4}-[0-9]{2}-[0-9]{2}", line)
            if datematch:
                date_str = datematch[0]
                if type(date_str) is str:
                    date_obj = datetime.datetime.strptime(date_str.lstrip(Config.date_prefix), "%Y-%m-%d")
                    if date_obj < datetime.datetime.now():
                        return date_str
            return False

        def does_line_have_tomorrowdate(line: str) -> bool:
            # Today's date in the format like @2023-12-28
            today_date_string = Config.date_prefix + str(datetime.date.today())
            # get today's date as @Monday, @Tuesday, etc, based on locale
            day_of_week_today_string = Config.date_prefix + (datetime.datetime.now()).strftime('%A')

            # Replace all things like @tomorrow, @monday (if today is monday), or @2023-12-30 (if today is that date)
            date_regexes = Config.tomorrow_string + r"|" + day_of_week_today_string + r"|" + today_date_string
            if re.search(date_regexes, line, flags=re.IGNORECASE):
                return True
            return False

        def convert_futuredates_to_todays(line: str) -> str:
            # Today's date in the format like @2023-12-28
            today_date_string = Config.date_prefix + str(datetime.date.today())
            # get today's date as @Monday, @Tuesday, etc, based on locale
            day_of_week_today_string = Config.date_prefix + (datetime.datetime.now()).strftime('%A')

            # Replace all things like @tomorrow, @monday (if today is monday), or @2023-12-30 (if today is that date)
            date_regexes = Config.tomorrow_string + r"|" + day_of_week_today_string + r"|" + today_date_string
            line = re.sub(date_regexes, Config.today_string, line, flags=re.IGNORECASE)

            return line

        # Get today's date pre-existing file content, if this should exist, but without the yaml frontmatter
        def get_pre_existing_today_content_without_frontmatter() -> list:
            pre_existing_today_content = []
            end_of_yaml_frontmatter = 0
            if self.old_frontmatter_linepos_end > 0:
                end_of_yaml_frontmatter = self.old_frontmatter_linepos_end + 2
            pre_existing_today_content = self.todayfile.content[end_of_yaml_frontmatter:]
            return pre_existing_today_content

        # def mark_everything_from_date_undone_in_file_of_date(filedate: str):

        def mark_all_undone_in_file(file: File):
            new_file_content = []

            # with open(str(file) + ".md", "r") as file:
            # for line in file.readlines():
            for line in file.content:
                if Parser.is_line_undone_todo(line):
                    # mark - [ ] of previous days as - [/]
                    # postponed_item = re.sub(r"- \[ \]", "- [/]", line)
                    postponed_item = Parser.mark_todo_postponed(line)
                    line = postponed_item
                new_file_content.append(line)

            if View.verbosity > 0:
                View.dump("Yesterday's file new content is: " + str(new_file_content), 1)
            file.content = new_file_content
            file.save_to_disk()

        return run()


class Parser:
    """
    Parses files and and upates supplied taxonomies?
    """
    filterbytag: str = ""
    currentLinenumber: int = 0
    nestedContents = []

    # precompiling regexes seems to be twice as slow
    # tagWords = re.findall(r"\[\[([^\]]+)\]\]", line)
    # hashTagWords = re.findall(r"[^a-zA-Z0-9/\[\]\(\)]#([a-zA-Z][^#\s:,\]\)%\.']+)", line)
    tagwordsRe = re.compile(r"\[\[([^\]]+)\]\]")
    hash_tag_words_re = re.compile(r"[^a-zA-Z0-9/\[\]\(\)]#([a-zA-Z][^#\s:,\]\)%\.']+)")

    def __init__(self, file: File) -> None:
        self.file = file
        if Arg.isset('filterbytagname'):
            self.filterbytag = Arg.get('filterbytagname')
            # NB: This search needs to be case insensitive, else we miss all the variations of tags
            # self.tagwordsRe=re.compile(r"\[\[(" + self.filterbytag + r")\]\]", re.IGNORECASE)
            # This makes it search for any [[tagname.xyz even, if they don't close. Is that ok?
            self.tagwords_re = re.compile(r"\[\[(" + self.filterbytag + r")", re.IGNORECASE)
            # self.hash_tag_words_re=re.compile(r"[^a-zA-Z0-9/\[\]\(\)]#(" + self.filterbytag + ")", re.IGNORECASE)
            # Find #tagword starting on line or without a letter or brackets or link etc preceding it
            self.hash_tag_words_re = re.compile(r"(?:^|[^a-zA-Z0-9/\[\]\(\)])#(" + self.filterbytag + ")", re.IGNORECASE)
        # else:
        #     self.tagwordsRe=re.compile(r"\[\[([^\]]+)\]\]")
        #     self.hash_tag_words_re=re.compile(r"[^a-zA-Z0-9/\[\]\(\)]#([a-zA-Z][^#\s:,\]\)%\.']+)")

    @ staticmethod
    def is_line_todo(line):
        # check if a line starts with - [ ] or - [/]
        return bool(re.match(r"^[\s\t]*(\-\s\[.\]\s)|^[\*\[\]\t\s-]*TODO\b", line))

    @ staticmethod
    def is_line_contains_done_todo_fast(line: str):
        # check slightly faster if a line starts with - [ ] or - [/]
        # Main.startwatch('is_line_done_todo_fast')
        return "- [/] " in line or "- [x] " in line or " DONE" in line
        # All these regexes seem slower
        # stripped_line = line.lstrip(" *-")
        # result = str.startswith(stripped_line, ("[/] ", "[x] ", "DONE"))
        # result = bool(re.match(r"^[\s\t]*(\-\s\[[x/]\]\s)|^[\*\[\]\t\s-]*DONE", line))
        # result = bool(re.match(Parser.is_line_todo_fast_re, str.lstrip(line)))
        # result = bool(re.match(Parser.is_line_todo_fast_re, str.lstrip(line)))
        # result = bool(re.match(Parser.is_line_todo_fast_re, str.lstrip(line)))
        # result = re.match(r"\- \[[x/]\] |[\*\t -]*DONE", str.lstrip(line))
        # is_line_todo_fast_re = re.compile(r"\- \[[x/]\] |[\*\t -]*DONE")
        # Precompiled regex also not faster
        # is_line_todo_fast_re = re.compile(r"^[\s\t]*(\-\s\[[x/]\]\s)|^[\*\[\]\t\s-]*DONE")
        # Main.stopwatch('is_line_done_todo_fast')
        # return result
        # return "- [/] " in line or "- [x] " in line or "DONE" in line

    @ staticmethod
    def is_line_undone_todo(line):
        # check if a line starts with - [ ] or - [/]
        Main.startwatch('is_line_undone_todo')
        out = bool(re.match(r"^[\s\t]*\-\s\[[\s/]\]\s|^[\*\[\]\t\s-]*TODO\b", line))
        # out = bool("- [ ]" in line)
        Main.stopwatch('is_line_undone_todo')
        return out

    @ staticmethod
    def mark_todo_undone(line):
        undone = re.sub(r"^([\*\[\]\t\s-]*)TODO\b", "\\1 DONE", line)
        return re.sub(r"^([\s\t]*)\-\s\[.\]", "\\1- [ ]", undone)

    @ staticmethod
    def mark_todo_postponed(line):
        undone = re.sub(r"^([\*\[\]\t\s-]*)TODO\b\s*", "\\1", line)
        return re.sub(r"^([\s\t]*)\-\s\[.\]", "\\1- [/]", undone)

    def parse_file(self):
        # TODO: populateTaxonomy should NOT be part of parser, right? it should be taxonomy.populate(parser)
        # Because otherwise this essentially modifies the taxonomy object input ARGUMENT from the parser class, which is disgusting
        if Main.stats_enabled is True:
            Main.files_parsed += 1
            # This is the brunt of the work, takes 90% of total runtime
            # Main.startwatch('parse file for tag strings')

        self.parse_file_for_tag_strings()

        # if Main.stats_enabled is True:
        # Main.stopwatch('parse file for tag strings')

        # This pseudotag functionality seems buggy, pushes out
        # DEPRECATED:flaky and unclear how it works...
        # self.add_pseudotag_for_files_in_dir_collection()

    def add_pseudotag_for_files_in_dir_collection(self):
        '''
        This adds everything in a tagname/tagname.md file for future .tagname.md collection inclusion
        '''
        def add_first_usable_lines_of_text_to_tag():
            # lines = []
            index = 0
            for line in self.file.content:
                if len(line) > 5:
                    if not line.startswith(Config.for_pseudotag_ignore_lines_starting_with):
                        if str.isspace(line):
                            break
                        # return line
                        # lines.append(line)
                        Taxonomy().add_line_to_tag(self.file, line, self.file.dirname.lower())
                        index += 1

        def is_file_part_of_dir_collection():
            """
            Check if the file is part of a dir collection, like tagname/tagname.md
            """
            # FIXME: This test is wrong. It gets confused when e.g. there is code.md somewhere and code/projectX, obviously
            return bool(len(self.file.dirname)
                        and self.file.dirname.lower() in Files().filelist)

        # If a file is like tagname/tagname.md,
        # then add all of its contents to the .tagname Taxonomy list
        if is_file_part_of_dir_collection():
            # Taxonomy().addTagdata(get_first_usable_line_of_text(), self.file.dirname.lower())
            add_first_usable_lines_of_text_to_tag()

            return True
        else:
            return False

    # Opens the file and parses through it line-by-line
    def parse_file_for_tag_strings(self):
        def tags_contained_in_line(line: str):
            '''
            Returns a list of tags found on a line
            '''
            # Main.startwatch('tags_contained_in_line')
            tag_words = []
            hashtag_words = []
            # Hashtag words should not contain )] and others, be at a word boundary,
            # nor start with (#) (which are links)
            # Then combine (this works better than two separate regexes producing messy objects somehow)
            # FYI: These regexes are dynamic, based on tagwordsRe precompiled once at the top, which is indeed a tiny bit faster (from 15% to 10%)
            tag_words = self.tagwords_re.findall(line)
            hashtag_words = self.hash_tag_words_re.findall(line)

            if hashtag_words:
                tag_words = tag_words + hashtag_words

            # Main.stopwatch('tags_contained_in_line')
            return tag_words

        def should_i_add_line(line: str) -> bool:
            '''
            If line starts with anything like: - [x]
            i.e.: anything except - [ ] space, then it's a crap todo we can delete
            lines should only not be added if done todos
            '''
            def is_line_done_todo(line: str) -> bool:
                return Parser.is_line_contains_done_todo_fast(line)
                # return bool(re.match(r"^[\s\t]*\-\s\[[^\s]\]", line))
                #  perf: 15% (shaved from 30% by removing regex)
                # find not quite the same, ignores some strings
                # return str.find(r"^[\s\t]*\-\s\[[^\s]\]", line) > -1

            if len(line) == 0 or is_line_done_todo(line):
                return False

            return True

        def get_descendant_lines(parent_line: str, currentlinenumber) -> list:
            '''
            Recursively get all lines that are indented more deeply than the parent line
            # Gets all descendant lines
            1. get the whitespace at beginning of line that tag is found
            2. add each succeeding line that begins with '[whitespace]+ - slash')
            3. break out of loop when that's not true
            -- AND/OR break out of loop when special readonly xref syntax begins in a file, to avoid recursive mess
            '''
            def count_tabs_in_line(s, tabsize=Config.tabsize):
                '''
                Seems like an efficient way to count tabs and space indents with str.expandtabs
                Replace all tab-like-stuff-with-single-spaces-first
                Via: https://stackoverflow.com/posts/13241784/revisions
                '''
                sx: str = s.expandtabs(tabsize)
                return 0 if sx.isspace() else len(sx) - len(sx.lstrip())

            descendant_lines = []
            parentline_indentation_count = count_tabs_in_line(parent_line)
            View.dump("Parser.get_descendant_lines parent_line indent count: " + str(parentline_indentation_count) + ", file: " + self.file.filename + ", line: " + parent_line + ", [linenum: " + str(currentlinenumber) + "]", 3)

            # Look from [nextlinenumberafterparent] (to end) in file with [num:]
            for line in self.file.content[currentlinenumber + 1:]:
                currentline_indentation_count = count_tabs_in_line(line)
                View.dump("Parser.get_descendant_lines childlines, indent count: " + str(currentline_indentation_count) + ", file: " + self.file.filename + ", line: " + line, 3)
                # We want to allow empty linebreaks within nestings
                if line.isspace():
                    continue
                if currentline_indentation_count <= parentline_indentation_count:
                    break
                else:
                    if should_i_add_line(line):
                        # reduce all indent levels by the parent line, so even nested indents start initially at 1, and pass 'level' to the descendant line dict
                        # Make all child lines level 1 (so we don't run out of space)
                        line = line.strip("\t ")
                        descendant_lines.append({
                            "text": line,
                            # "level": currentline_indentation_count - parentline_indentation_count
                            "level": 1
                        })

            return descendant_lines

        # MAIN PARSER FUNCTION
        # Walk through each line of a file's content, and add lines if they have tags or are special
        for linenum, line in enumerate(self.file.content):
            View.dump("Parser.parse_file_for_tag_string: " + str(linenum) + ": " + line, 3)

            # perf: this is relatively fast, 10% of total, for 114,739 iterations
            # if is_breakpoint_reached_in_file(line):
            #     break

            # add the tag to dict, along with the line it's on
            if should_i_add_line(line):
                View.dump("Parser.should_i_add_line passed: " + line, 3)
                tags_in_line = tags_contained_in_line(line)
                # View.dump("Parser.tags_contained_in_line: " + "\n".join(tagsInLine), 3)
                # We have found a tag in the line, now add the line itself, and possible descendants
                if tags_in_line:
                    for tag in tags_in_line:
                        # Don't (necessarily) add  lines that have nothing but an empty tag on them
                        # and line_has_more_than_just_tag(line):
                        Taxonomy().add_line_to_tag(self.file, line, tag, linenum + 1)
                        View.dump("Found tag '" + tag + "' in file: " + self.file.filename, 1)
                        View.dump("Parser adding line to Taxonomy: " + line, 3)

                        # {text: line (str), level: 1 (int)}
                        # NB: Don't forget to set linenumber, ugh
                        # Main.startwatch('parse descendant lines')
                        descendant_lines = get_descendant_lines(line, linenum)
                        if descendant_lines:

                            for childline in descendant_lines:
                                Taxonomy().add_line_to_tag(self.file, childline['text'], tag, linenum + 1, childline['level'])
                                # Taxonomy().addTagdata(descendantLines, tag)
                                # if should_i_add_line(line):
                        # Main.stopwatch('parse descendant lines')

                            # Taxonomy().addTagdata("".join(descendantLines), tag)

            argtest = True
            # Main.startwatch('empty_add_undones_to_todo')
            # this is SLOW, parses EVERYTHING lots
            # if Parser.is_line_undone_todo(line):
            #     Taxonomy().addLineToTag(self.file, line, 'todo')
            # Main.stopwatch('empty_add_undones_to_todo')


class View:
    verbosity: int

    def __init__(self) -> None:
        # View.verbosity = 3 # Arg.verbose()
        View.verbosity = Arg.verbose()

    @staticmethod
    def dump(text, verbositylevel=0):
        '''
        verbositylevel can be 0 to 3
        0 will get output always
        1 will get output if verbose is set to 1 with --verbose or -v
        2 and 3 with -vv or -vvv
        '''
        """
        Echos text to stdout if 'verbose' arg provided
        """
        # Main.startwatch('viewdump')
        # if Arg.verbose():
        # if verbositylevel <= Arg.verbose():
        if verbositylevel <= View.verbosity:
            # get line number of caller in future
            # print(inspect.stack()[1][2])
            if type(text) is str:
                print(": " + text)
            elif text:
                pprint(text, indent=4, width=160)
            else:
                pprint("EMPTY DUMP", indent=4, width=160)
        # Main.stopwatch('viewdump')

    @staticmethod
    def error(text):
        """
        Always echos errors to stderr
        """
        if text:
            stderr.write(text)

    @staticmethod
    def print(text):
        """
        Always echos text to stdout without decoration
        """
        # TODO: Pipe this to stdout
        if text:
            print(text)

    @staticmethod
    def preview_parsed_data():
        # loop through entire generated dict and display on screen
        output = ""
        for key in Taxonomy.tags:
            # View.dump(key + ":", "\n")
            for tag, content in Taxonomy.tags[key].items():
                # View.dump("\n")
                View.dump(" === " + key + ":", 3)
                View.dump(tag, 3)
                View.dump(" ::: " + str(content), 3)

    @staticmethod
    def preview_parsed_data_by_tagname(filter_by_tagname: str):
        # loop through entire generated dict and display on screen
        # output = ""
        for key in Taxonomy.tags:
            if key == filter_by_tagname:
                View.dump(key)
                for items in Taxonomy.tags[key].items():
                    for item in items:
                        # View.dump(item)
                        if 'content' in item:
                            View.dump(item.content)


if __name__ == "__main__":
    # Call with Main() to initalise stuff
    Main().run_main()
