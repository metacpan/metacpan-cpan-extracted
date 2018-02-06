@echo off
set "ERRORLEVEL="

:: NOTE: contains some peculiar statement ordering and redirections b/c of AppVeyor bugs when executing BAT/CMD scripts

if not defined perl_version ( set "perl_version=latest" )

set "perl_download="
if "%perl_version%"=="5.8.8" ( set "perl_version=5.8.8"  & set "perl_download=http://strawberryperl.com/download/5.8.8/strawberry-perl-5.8.8.4.zip" )
if "%perl_version%"=="5.8"   ( set "perl_version=5.8.9"  & set "perl_download=http://strawberryperl.com/download/5.8.9/strawberry-perl-5.8.9.5.zip" )
if "%perl_version%"=="5.10"  ( set "perl_version=5.10.1" & set "perl_download=http://strawberryperl.com/download/5.10.1.1/strawberry-perl-5.10.1.1.zip" )
if "%perl_version%"=="5.12"  ( set "perl_version=5.12.1" & set "perl_download=http://strawberryperl.com/download/5.12.1.0/strawberry-perl-5.12.1.0.zip" )
if "%perl_version%"=="5.14"  ( set "perl_version=5.14.4" & set "perl_download=http://strawberryperl.com/download/5.14.4.1/strawberry-perl-5.14.4.1-64bit.zip" )
if "%perl_version%"=="5.16"  ( set "perl_version=5.16.3" & set "perl_download=http://strawberryperl.com/download/5.16.3.1/strawberry-perl-5.16.3.1-64bit.zip" )
if "%perl_version%"=="5.18"  ( set "perl_version=5.18.4" & set "perl_download=http://strawberryperl.com/download/5.18.4.1/strawberry-perl-5.18.4.1-64bit.zip" )

:: ## install
echo|set /p OUTPUT="Installing Strawberry Perl "

set "cinst_options=--yes"
if /i not "%perl_version%" == "latest" ( set "cinst_options=%cinst_options% --version %perl_version%" )

if not defined perl_download (
  echo|set /p OUTPUT="(%perl_version%; via Chocolatey ['cinst %cinst_options% StrawberryPerl']) ... "
  cinst %cinst_options% StrawberryPerl | rem # script fails here if STDOUT redirected to NUL [AppVeyor bug]
) else (
  echo|set /p OUTPUT="(%perl_version%; via direct download) ... "
    curl -# -L "%perl_download%" -o c:\strawberryperl.zip >NUL 2>&1 && 7z -bd x c:\strawberryperl.zip -oc:\strawberry >NUL
    )
)

if "%ERRORLEVEL%" == "0" ( echo done ) else ( echo FAILED [ERRORLEVEL=%ERRORLEVEL%] & exit /b -1 )

:: ## configure
echo|set /p OUTPUT="Configuring Perl ... "

set "PATH=C:\strawberry\c\bin;C:\strawberry\perl\site\bin;C:\strawberry\perl\bin;%PATH%"

for /f "usebackq delims=" %%d in (`perl -MConfig -e"print $Config{make}"`) do set make=%%d

echo done
