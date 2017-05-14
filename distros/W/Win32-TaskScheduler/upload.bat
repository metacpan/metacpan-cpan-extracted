@echo off

call makedist.bat

scp Win32-TaskScheduler/Win32-TaskScheduler.tar.gz unicolet@shell.sourceforge.net:/home/groups/t/ta/taskscheduler/htdocs/perl/win32/Win32-TaskScheduler.tar.gz

scp Win32-TaskScheduler\Win32-TaskScheduler.ppd unicolet@shell.sourceforge.net:/home/groups/t/ta/taskscheduler/htdocs/perl/Win32-TaskScheduler.ppd

scp blib\html\site\lib\win32\TaskScheduler.htm unicolet@shell.sourceforge.net:/home/groups/t/ta/taskscheduler/htdocs/taskscheduler.html

zip -r -9 taskscheduler.zip Win32-TaskScheduler

scp taskscheduler.zip unicolet@shell.sourceforge.net:/home/groups/t/ta/taskscheduler/htdocs/perl/taskscheduler.zip

nmake distclean

cd ..

zip -r -9 Win32-TaskScheduler.zip TaskScheduler

