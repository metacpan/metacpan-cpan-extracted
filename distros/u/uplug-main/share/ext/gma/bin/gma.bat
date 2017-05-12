rem *******************
rem *** GMA program ***
rem *******************

rem Check Java
if "%JAVA_HOME%" == "" goto noJavaHome
goto start

:noJavaHome
echo Warning: You have not set the JAVA_HOME environment variable.

:start
set GMA_PATH=..\lib\gma.jar

java -classpath %GMA_PATH% gma.GMA %1 %2 %3 %4 %5 %6 %7 %8


