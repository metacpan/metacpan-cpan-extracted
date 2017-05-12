@echo off
if "%MSVCDir%"=="" call msvs6env
if "%MSSdk%"=="" call psdk6env

if exist Makefile call nmake realclean
if exist package\MSWin32-x86-multi-thread rd /q/s package\MSWin32-x86-multi-thread
