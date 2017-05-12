@echo off
:: Copyright © 2010-2011 Olivier Mengu‚
::
:: This program is free software: you can redistribute it and/or modify
:: it under the terms of the GNU General Public License as published by
:: the Free Software Foundation, either version 3 of the License, or
:: (at your option) any later version.
::
:: This program is distributed in the hope that it will be useful,
:: but WITHOUT ANY WARRANTY; without even the implied warranty of
:: MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
:: GNU General Public License for more details.
::
:: You should have received a copy of the GNU General Public License
:: along with this program.  If not, see L<http://www.gnu.org/licenses/>.

setlocal
set SPEC=First
if "%~1"=="-a" (
    set SPEC=All
    shift
)
if "%~1"=="--" shift

if "%~1"=="" exit /B 2

:: Add the current directory to the PATH
for %%D in (.) do set "PATH=%%~fD;%PATH%"

set Found=

:: Shortcut for this special case that the shell knows how to handle
if %SPEC%==First if not "%~x1"=="" goto :FirstExtBuiltin

::Slow
if not "%~x1"=="" call :VisitPATH :Visit%SPEC%Ext "%~1"
if not "%~x1"=="" (
    if not #%Found%==#1 call :VisitPATH :Visit%SPEC% "%~n1"
) else (
    call :VisitPATH :Visit%SPEC% "%~1"
)
:End
endlocal & if #%Found%==#1 exit /B 0
echo %~1 not found.>&2
exit /B 1

:: Use builtin for this special case
:FirstExtBuiltin
set "Found=%~$PATH:1"
if not "%Found%"=="" echo %Found%& set Found=1
goto :End

:: Test one filename
:VisitFirstExt2
if #%Found%==#1 goto :EOF
:VisitFirstExt
:VisitAllExt
:VisitAllExt2
::echo %~1 ?
if not exist "%~1" goto :EOF
echo %~f1
set Found=1
goto :EOF

:: Test all extensions for the %1 filename
:VisitFirst
:VisitAll
for %%e in (%PATHEXT%) do call :Visit%SPEC%Ext2 "%~1%%e"
goto :EOF

:: VisitPATH
::
:: %1 callback name
::
: == VisitPATH ==
set "VisitPATH_P=%PATH:;=§%
set "VisitPATH_P=%VisitPATH_P:)=²%
:VisitPATH_Loop
for /F "usebackq tokens=1 delims=§" %%D in ('%VisitPATH_P%') do call :VisitPATH_one %1 "%%~fD\%~2"
set "VisitPATH_Q=%VisitPATH_P%
set "VisitPATH_P=%VisitPATH_P:*§=%
if not "%SPEC%%Found%"=="First1" if not "%VisitPATH_P%"=="%VisitPATH_Q%" goto :VisitPATH_Loop
set VisitPATH_P=
set VisitPATH_Q=
goto :EOF


: == VisitPATH_one ==
set "VisitPATH_Q=%~2
call %1 "%VisitPATH_Q:²=)%"
goto :EOF
