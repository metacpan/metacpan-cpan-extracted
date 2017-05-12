@echo off
echo -------------------------
echo Checking to see if you have a Microsoft compiler
echo -------------------------
cl.exe
if %errorlevel% == 0 goto :Microsoft
if %errorlevel% == 9009 echo You do not have CL.exe in your PATH.

echo -------------------------
echo Checking to see if you have a Borland c compiler.
echo -------------------------
bcc32.exe
if %errorlevel% == 9009 echo You do not have bcc32.exe in your PATH.
if %errorlevel% == 0 goto :Borland

goto :end

:Microsoft
echo -------------------------
echo Compiling using Microsoft
echo -------------------------
call clean_all.bat
call build_cl.bat
goto :end

:Borland
echo -------------------------
echo Compiling using Microsoft
echo -------------------------
call clean_all.bat
call build_borland.bat
goto :end


:end
echo -------------------------
echo All done
echo -------------------------
@echo on