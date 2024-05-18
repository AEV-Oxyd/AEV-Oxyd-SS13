@echo off
rem Cheridan asked for this. - N3X
call "%~dp0\bootstrap\python" ../tools/ss13_genchangelog.py ../html/changelogs
pause
