REM  
REM  Makefile.bat ipadic-2.4.1
REM

@echo off
@echo Makefile.bat for ipadic-2.4.1

cd dic


@echo copy...
copy connect.cha _connect.c
if errorlevel 1 goto ERROREXIT

copy _connect.c _connect.cha
REM cl -E _connect.c > _connect.cha


@echo makemat...
..\mkchadic\makemat
if errorlevel 1 goto ERROREXIT

del _connect.c
del _connect.cha


@echo makeint...
..\mkchadic\makeint -o chadic.txt *.dic
if errorlevel 1 goto ERROREXIT


@echo sortdic...
..\mkchadic\sortdic chadic.txt chadic.int
if errorlevel 1 goto ERROREXIT

del chadic.txt


@echo pattool...
..\mkchadic\pattool -F chadic
if errorlevel 1 goto ERROREXIT

cd ..


@echo chasen dictionary compiled successfully.
goto LAST


:ERROREXIT
@echo cannot make chasen dictionary.


:LAST
@echo on
