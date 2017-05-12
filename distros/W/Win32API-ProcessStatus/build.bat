@echo off
if "%MSVCDir%"=="" call msvs6env
if "%MSSdk%"=="" call psdk6env

call perl Makefile.PL
call nmake
call nmake test

if exist blib\html rd /q/s blib\html
md blib\html\site\lib\Win32API
copy /y ProcessStatus.html blib\html\site\lib\Win32API
if exist Win32API-ProcessStatus*.tar.gz del /q Win32API-ProcessStatus*.tar.gz
call nmake dist

if exist package\MSWin32-x86-multi-thread rd /q/s package\MSWin32-x86-multi-thread
md package\MSWin32-x86-multi-thread
call tar cvf package\MSWin32-x86-multi-thread\Win32API-ProcessStatus.tar blib
call gzip -9 package\MSWin32-x86-multi-thread\Win32API-ProcessStatus.tar

if exist Win32API-ProcessStatus*.zip del /q Win32API-ProcessStatus*.zip
cd package
call zip -r -9 -S ..\Win32API-ProcessStatus-0.01-mswin32-x86.zip *
cd ..
