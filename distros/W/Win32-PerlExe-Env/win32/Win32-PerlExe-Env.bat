@echo off
echo ===========================================================================
echo $Id: Win32-PerlExe-Env.bat 411 2006-08-27 18:54:00Z HVRTWall $
echo Copyright (c) 2006 Thomas Walloschke (thw@cpan.org). All rights reserved.
echo ===========================================================================

set script=perl Win32-PerlExe-Env.pl 
set executable=    Win32-PerlExe-Env.exe 

set opt11=
set opt21=

set opt12=:tmp
set opt22=Win32

set opt13=:vars
set opt23=

set opt14=:all
set opt24=Get_Info.ico

set opt15=:DEFAULT
set opt25=Copyright

set opt16=:undefined
set opt26=

set opt17=:tmp
set opt27=undefined

set log=Win32-Perl-Exe.log

set show=write

set ul============================
set nl=-------------------------------------------- 

rem ------------------------------------------------------------------------------------------------------------------------

echo TEST OF Win32::PerlExe::Env        >  %log%
echo %ul%                               >> %log%

rem --------------------------------------------

echo %script% %opt11% %opt21%           >> %log%
%script% %opt11% %opt21%                >> %log%
echo %nl%                               >> %log%

echo %script% %opt12% %opt22%           >> %log%
     %script% %opt12% %opt22%           >> %log%
echo %nl%                               >> %log%

echo %script% %opt13% %opt23%           >> %log%
     %script% %opt13% %opt23%           >> %log%
echo %nl%                               >> %log%

echo %script% %opt14% %opt24%           >> %log%
     %script% %opt14% %opt24%           >> %log%
echo %nl%                               >> %log%

echo %script% %opt15% %opt25%           >> %log%
     %script% %opt15% %opt25%           >> %log%
echo %nl%                               >> %log%

echo %script% %opt16% %opt27%           >> %log%
     %script% %opt16% %opt27%           >> %log%
echo %nl%                               >> %log%

echo %script% %opt17% %opt27%           >> %log%
     %script% %opt17% %opt27%           >> %log%
echo %nl%                               >> %log%

rem --------------------------------------------

echo %executable% %opt11% %opt21%       >> %log%
     %executable% %opt11% %opt21%       >> %log%
echo %nl%                               >> %log%

echo %executable% %opt12% %opt22%       >> %log%
     %executable% %opt12% %opt22%       >> %log%
echo %nl%                               >> %log%

echo %executable% %opt13% %opt23%       >> %log%
     %executable% %opt13% %opt23%       >> %log%
echo %nl%                               >> %log%

echo %executable% %opt14% %opt24%       >> %log%
     %executable% %opt14% %opt24%       >> %log%
echo %nl%                               >> %log%

echo %executable% %opt15% %opt25%       >> %log%
     %executable% %opt15% %opt25%       >> %log%
echo %nl%                               >> %log%

echo %executable% %opt16% %opt26%       >> %log%
     %executable% %opt16% %opt26%       >> %log%
echo %nl%                               >> %log%

echo %executable% %opt17% %opt27%       >> %log%
     %executable% %opt17% %opt27%       >> %log%
echo %nl%                               >> %log%

rem --------------------------------------------

echo Ready - Thank You for Testing      >> %log%

rem --------------------------------------------

%show% %log%

rem -------------------------------------------------------------------------------------------------------

echo %nl%
echo Result see %log%
echo %nl%

@pause
echo ============================================================================