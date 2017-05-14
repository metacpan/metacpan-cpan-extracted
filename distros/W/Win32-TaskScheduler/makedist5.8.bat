@echo off

set PACKAGE=Win32-TaskScheduler
set PACKAGE-DIR=%PACKAGE%-58
set PM=TaskScheduler

echo Making distribution...

perl makefile.PL
nmake

echo Copying files...
if not exist %PACKAGE-DIR% mkdir %PACKAGE-DIR%

del /Q %PACKAGE-DIR%\*

mkdir blib\html\site\lib\win32

nmake ppd
call pod2html --cs=..\..\..\Active.css --quiet --infile=%PM%.pm --outfile=blib\html\site\lib\win32\%PM%.htm

tar cvf %PACKAGE-DIR%.tar blib
gzip --best %PACKAGE-DIR%.tar

sed "s/CODEBASE HREF=\"\"/CODEBASE HREF=\"http:\/\/taskscheduler\.sourceforge\.net\/perl\/win32\/%PACKAGE-DIR%\.tar\.gz\"/" %PACKAGE%.ppd > %PACKAGE-DIR%\%PACKAGE%.ppd

mv *.gz %PACKAGE-DIR%

