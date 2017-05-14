@echo off

set PACKAGE=Win32-TaskScheduler
set PM=TaskScheduler

echo Making distribution...

perl makefile.PL
nmake

echo Copying files...
if not exist %PACKAGE% mkdir %PACKAGE%

del /Q %PACKAGE%\*

mkdir blib\html\site\lib\win32

nmake ppd
call pod2html --cs=..\..\..\Active.css --quiet --infile=%PM%.pm --outfile=blib\html\site\lib\win32\%PM%.htm

tar cvf %PACKAGE%.tar blib
gzip --best %PACKAGE%.tar

sed "s/CODEBASE HREF=\"\"/CODEBASE HREF=\"http:\/\/taskscheduler\.sourceforge\.net\/perl\/win32\/%PACKAGE%\.tar\.gz\"/" %PACKAGE%.ppd > %PACKAGE%\%PACKAGE%.ppd

mv *.gz %PACKAGE%

echo Now you only have to ZIP the %PACKAGE% directory
echo to dist your extension!
