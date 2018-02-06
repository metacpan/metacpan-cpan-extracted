::# $Id$
:: to.bat [PATH]
:: cd with command line expansion
::
:: * if PATH exists, cd to it & exit
:: * if PATH == NULL, cd to home directory (aka "~") & exit
:: * expand PATH; if expand(PATH) exists, cd to it & exit
:: * expand ~PATH; if expand(~PATH) exists, cd to it & exit
::
:: compatible with CMD, 4NT/TCC/TCMD
:: NOT compatible with COMMAND
@echo off
setlocal

:: gather all arguments
set args=%*
:::: :CMD quirk
::set "args=%*"
:::: :4NT/TCC/TCMD quirk
::if 01 == 1.0 ( set args=%* )

:: <args> == null => to ~
if [%args%]==[] ( set args=~ )

::::: remove leading ~ (if it exists)
:::set tilde=~
:::set prefix_char=%args:~0,1%
:::set suffix=%args:~1%
:::
::::: ^%prefix_char% is used to escape the character in cases where it might be a quote character
:::if [^%prefix_char%] == [^%tilde%] (
:::::   : avoid interpretation of set unless the leading character is ~ [arguments surrounded by quotes would otherwise cause a syntax error for %suffix% with only a trailing quote
::: set args=%suffix%
::: )
:::if 01 == 1.0 (
:::::   : 4NT/TCC/TCMD quirk: "if [^%prefix_char%] == [^%tilde%]" DOESN'T work in 4NT/TCC/TCMD
:::::   : used 4NT/TCC/TCMD %@ltrim[] instead
::: set args=%@ltrim[~,%args%]
::: )
:::
:::::echo prefix_char = %prefix_char%
:::::echo suffix = %suffix%
:::::echo args = %args%

set ERROR=0
if EXIST "%args%" (
    cd "%args%" > nul 2> nul
    goto :CD_DONE
    )
call xx -s cd %args% > nul 2> nul
set ERROR=%ERRORLEVEL%
if "%ERROR%" == "0" ( goto :CD_DONE )
call xx -s cd ~%args% > nul 2> nul
set ERROR=%ERRORLEVEL%
:CD_DONE
set CWD=%CD%

:: handle any errors
:handle_errors
if "%ERROR%" == "0" ( goto :DONE )
:: check for missing Perl and/or XX
call perl -e 1 2> nul
if NOT "%ERRORLEVEL%" == "0" (
    echo ERROR: Missing Perl [which is required]; install perl and the Win32::CommandLine module [install from http://strawberryperl.com, then "cpan Win32::CommandLine"]
    goto :handle_errors_DONE
    )
call xx --version > nul 2> nul
if NOT "%ERRORLEVEL%" == "0" (
    echo ERROR: Missing XX [which is required]; install the Win32::CommandLine module for perl [use "cpan Win32::CommandLine"]
    goto :handle_errors_DONE
    )
call xx echo ERROR: Cannot find the specified path [%args% (or ~%args%)]
:handle_errors_DONE

:DONE
:: URLref: http://www.ss64.com/nt/endlocal.html @@ http://www.webcitation.org/66CFBlouF :: combining set with endlocal
endlocal & cd %CWD%
