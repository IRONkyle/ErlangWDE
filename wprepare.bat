@echo off

echo Prepare Windows Build Environment...

set EDK_XTOOLS=%CD%\xtools

set ERLANG_ROOT=%EDK_XTOOLS%\erl5.8.2
set ERLANG_BIN=%ERLANG_ROOT%\bin

set HG_ROOT=%EDK_XTOOLS%\Mercurial

set PATH=%ERLANG_BIN%;%HG_ROOT%;%PATH%

set EDK_TOOLS=%CD%\tools

set REBAR_BIN=%EDK_TOOLS%\rebar

set PATH=%REBAR_BIN%;%PATH%

doskey ls=dir /b $*
doskey cat=type $*
doskey rm=del $*
doskey mv=move $*
doskey cp=copy $*
doskey clear=cls
doskey sudo=runas /user:Administrator $*
doskey kill=taskkill /F /IM $*

IF "%~1"=="" (
echo Error: Missing Visual Studio version.
GOTO :EOF
) 

if %PROCESSOR_ARCHITECTURE% == x86 (
set VCVARS_BAT="C:\Program Files\Microsoft Visual Studio %~1\VC\vcvarsall.bat"
) else (
set VCVARS_BAT="C:\Program Files (x86)\Microsoft Visual Studio %~1\VC\vcvarsall.bat"
)

echo %VCVARS_BAT%
IF NOT EXIST %VCVARS_BAT% (
echo Error: Could not find vcvarsall.bat for this Visual Studio version.
GOTO :EOF
) 

call %VCVARS_BAT%

:Done
echo Done Preparing Windows Build Environment...


