@echo off
if "%MSVCDir%"=="" call msvs6env
if exist Makefile call nmake realclean
if exist package rd /q/s package
