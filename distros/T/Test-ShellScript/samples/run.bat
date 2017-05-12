@echo off

REM Testing aware output
echo TEST: params=%1
echo TEST: executed=false

REM execute the command
IF  not %1 == echo goto end
echo TEST: executed=true
%1
:end

REM Testing aware output
echo TEST: output=0
