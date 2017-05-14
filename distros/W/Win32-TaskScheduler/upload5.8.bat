@echo off

call makedist5.8.bat

scp Win32-TaskScheduler-58/Win32-TaskScheduler-58.tar.gz unicolet@shell.sourceforge.net:/home/groups/t/ta/taskscheduler/htdocs/perl58/win32/

scp Win32-TaskScheduler-58/Win32-TaskScheduler.ppd unicolet@shell.sourceforge.net:/home/groups/t/ta/taskscheduler/htdocs/perl58/

zip -r -9 taskscheduler.zip Win32-TaskScheduler

scp taskscheduler.zip unicolet@shell.sourceforge.net:/home/groups/t/ta/taskscheduler/htdocs/perl58/taskscheduler.zip

nmake distclean

cd ..

zip -r -9 Win32-TaskScheduler.zip TaskScheduler

