@echo off
if "%MSVCDir%"=="" call msvs6env
call perl Makefile.PL
call nmake
md blib\html\site\lib\Win32
copy ToolHelp.html blib\html\site\lib\Win32
call nmake test
call nmake dist
md package\MSWin32-x86-multi-thread
call tar cvf package\MSWin32-x86-multi-thread\Win32-ToolHelp.tar blib
call gzip -9 package\MSWin32-x86-multi-thread\Win32-ToolHelp.tar
echo To install this ActiveState PPM package, run the following command>package\README
echo in the current directory:>>package\README
echo.>>package\README
echo     ppm install Win32-ToolHelp.ppd>>package\README
echo.>>package\README
copy Win32-ToolHelp.ppd package
cd package
call zip -r -9 -S ..\Win32-ToolHelp-0.2-mswin32-x86.zip *
cd ..
