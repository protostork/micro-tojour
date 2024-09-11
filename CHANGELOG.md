# Changelog

## 2024-09-11 v.1.0.4

- fix: refactor regressed TOC increment functions out into new SidepaneContent
- fix: collectUndones now only parses dates prefaced with hardcoded '@'
- testing: refactors test.sh to create instance only from files in git  

## 2024-09-09 v.1.0.3

- fix: regression that broke checkbox and date line operations from sidepane 
- feature: collectUndones now adds any overdue dates found at the very top 

## 2024-09-09 v.1.0.2

- performance: optional caching of tags in a project's .micro/cache directory, useful on Android Termux and with `tojour.potatomode` (configurable with `tojour.cache` and `tojour.cache_dir` options)
- refactor: splits Lua codebase into separate files for Tests, TJSession, TJPanes, FileLink, TJConfig, Common (thanks [MicroOmni](https://github.com/Neko-Box-Coder/MicroOmni) sourcecode for help in getting 'require' to finally work) 
- refactor: reformats all Lua files with [StyLua](https://github.com/JohnnyMorganz/StyLua) code formatter.
- performance: Unit testing Tests.lua lib is now only required if env variable TOJOUR_DEVMODE=true

## 2024-09-07 v.1.0.1

- Do not automatically take over hotkeys anymore
- Updates README with repo link
- Additional links to useful plugins in tutorial

## 2024-09-06 v.1.0.0

- First release