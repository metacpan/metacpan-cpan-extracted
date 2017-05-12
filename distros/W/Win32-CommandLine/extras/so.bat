:: so.bat :: so.bat <COMMAND> <ARGS>
:: $Id: so.bat,v 0.1.0 ( r1 ) 2009/02/19 11:24:45 rivy $
::
:: Source Output of <COMMAND> in the current process context
:: ::Processes the STDOUT of <COMMAND> as command(s) to the current shell (i.e., as if typed directly at current command line)
:: ::This is a batch file trick to allow parent process modification from a child process (spiritually similar to bash sourcing of scripts ["source z.sh"] or bash "eval").
:: ::*allows child processes to chdir and set/change parent environment vars for their parent shell
:: DISCUSSION: All batch files run 'in-process' (hence the need for setlocal/endlocal), but other processes (.exe files for example) are run by the shell in a seperate "child" process, disallowing normal modification of parent current working directory or enviroment vars without some trickery (such as this script).
::
:: EXAMPLE: `so echo chdir ..`					:: chdir to parent directory for current shell
:: EXAMPLE: `so echo set x=1`					:: set x=1 in current set of shell environment variables
:: EXAMPLE: `so mybetterchdir.exe ~` 			:: mybetterchdir.exe may interpret '~' and print "chdir <WHATEVER>" to STDIO :: NOTE: use "doskey cd=so mybetterchdir.exe $*" to replace the usual cd command
:: EXAMPLE: `so mybettersetx.exe x PI` 			:: mybettersetx.exe may interpret 'PI' and print "set x=3.1415926..." to STDIO
:: EXAMPLE: `so perl -e "print q{set x=200}"` 	:: perl example
@echo OFF

setlocal

:: under 4NT/TCC, DISABLE nested variable interpretation (prevents overinterpretation of % characters)
if 01 == 1.0 ( setdos /x-4 )

:findUniqueTempFile
set _so_bat="%temp%\so.script.%RANDOM%.bat"
if EXIST %_so_bat% ( goto :findUniqueTempFile )

echo @::(so: TEMP batch script [%_so_bat%]) > %_so_bat%
echo @echo OFF >> %_so_bat%

call %* >> %_so_bat%
if NOT %errorlevel% == 0 (
	erase %_so_bat% 1>nul 2>nul
	endlocal & exit /B %errorlevel%
	)

endlocal & call %_so_bat% & erase %_so_bat% 1>nul 2>nul
