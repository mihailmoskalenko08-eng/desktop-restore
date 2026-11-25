@echo off
setlocal
set "APP=%~dp0app.py"
where py >nul 2>nul
if errorlevel 1 goto try_python
py -3 "%APP%"
goto finished

:try_python
where python >nul 2>nul
if errorlevel 1 goto no_python
python "%APP%"
goto finished

:no_python
echo Install Python 3.10 or later with Tcl/Tk from https://www.python.org/downloads/windows/
pause
exit /b 1

:finished
if errorlevel 1 pause
