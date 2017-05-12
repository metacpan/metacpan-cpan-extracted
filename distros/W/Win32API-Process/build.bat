@echo off
if "%MSVCDir%"=="" call msvs6env
if "%MSSdk%"=="" call psdk6env

call perl Makefile.PL
call nmake
call nmake test

if exist blib\html rd /q/s blib\html
md blib\html\site\lib\Win32API
copy /y Process.html blib\html\site\lib\Win32API
if exist Win32API-Process*.tar.gz del /q Win32API-Process*.tar.gz
call nmake dist

if exist package\MSWin32-x86-multi-thread rd /q/s package\MSWin32-x86-multi-thread
md package\MSWin32-x86-multi-thread
call tar cvf package\MSWin32-x86-multi-thread\Win32API-Process.tar blib
call gzip -9 package\MSWin32-x86-multi-thread\Win32API-Process.tar

if exist Win32API-Process*.zip del /q Win32API-Process*.zip
cd package
call zip -r -9 -S ..\Win32API-Process-0.01-mswin32-x86.zip *
cd ..
