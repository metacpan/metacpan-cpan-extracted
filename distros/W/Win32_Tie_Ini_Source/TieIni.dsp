# Microsoft Developer Studio Project File - Name="TieIni" - Package Owner=<4>
# Microsoft Developer Studio Generated Build File, Format Version 5.00
# ** DO NOT EDIT **

# TARGTYPE "Win32 (x86) Dynamic-Link Library" 0x0102

CFG=TieIni - Win32 Win32 Core
!MESSAGE This is not a valid makefile. To build this project using NMAKE,
!MESSAGE use the Export Makefile command and run
!MESSAGE 
!MESSAGE NMAKE /f "TieIni.mak".
!MESSAGE 
!MESSAGE You can specify a configuration when running NMAKE
!MESSAGE by defining the macro CFG on the command line. For example:
!MESSAGE 
!MESSAGE NMAKE /f "TieIni.mak" CFG="TieIni - Win32 Win32 Core"
!MESSAGE 
!MESSAGE Possible choices for configuration are:
!MESSAGE 
!MESSAGE "TieIni - Win32 Release" (based on "Win32 (x86) Dynamic-Link Library")
!MESSAGE "TieIni - Win32 Debug" (based on "Win32 (x86) Dynamic-Link Library")
!MESSAGE "TieIni - Win32 Win32 311" (based on\
 "Win32 (x86) Dynamic-Link Library")
!MESSAGE "TieIni - Win32 Win32 307" (based on\
 "Win32 (x86) Dynamic-Link Library")
!MESSAGE "TieIni - Win32 Win32 Core" (based on\
 "Win32 (x86) Dynamic-Link Library")
!MESSAGE 

# Begin Project
# PROP Scc_ProjName ""$/Win32 TieIni", JSBAAAAA"
# PROP Scc_LocalPath "."
CPP=cl.exe
MTL=midl.exe
RSC=rc.exe

!IF  "$(CFG)" == "TieIni - Win32 Release"

# PROP BASE Use_MFC 0
# PROP BASE Use_Debug_Libraries 0
# PROP BASE Output_Dir "Release"
# PROP BASE Intermediate_Dir "Release"
# PROP BASE Target_Dir ""
# PROP Use_MFC 0
# PROP Use_Debug_Libraries 0
# PROP Output_Dir "Release"
# PROP Intermediate_Dir "Release"
# PROP Ignore_Export_Lib 0
# PROP Target_Dir ""
# ADD BASE CPP /nologo /MT /W3 /GX /O2 /D "WIN32" /D "NDEBUG" /D "_WINDOWS" /YX /FD /c
# ADD CPP /nologo /MT /W3 /GX /O2 /D "WIN32" /D "NDEBUG" /D "_WINDOWS" /YX /FD /c
# ADD BASE MTL /nologo /D "NDEBUG" /mktyplib203 /o NUL /win32
# ADD MTL /nologo /D "NDEBUG" /mktyplib203 /o NUL /win32
# ADD BASE RSC /l 0x409 /d "NDEBUG"
# ADD RSC /l 0x409 /fo"out/TieIni.res" /i "s:\include\perl" /d "NDEBUG" /d "MSWIN32" /d "EMBED" /d "PERL_OBJECT"
BSC32=bscmake.exe
# ADD BASE BSC32 /nologo
# ADD BSC32 /nologo
LINK32=link.exe
# ADD BASE LINK32 kernel32.lib user32.lib gdi32.lib winspool.lib comdlg32.lib advapi32.lib shell32.lib ole32.lib oleaut32.lib uuid.lib odbc32.lib odbccp32.lib /nologo /subsystem:windows /dll /machine:I386
# ADD LINK32 kernel32.lib user32.lib gdi32.lib winspool.lib comdlg32.lib advapi32.lib shell32.lib ole32.lib oleaut32.lib uuid.lib odbc32.lib odbccp32.lib /nologo /subsystem:windows /dll /machine:I386 /out:"c:\perl\lib\auto\win32\Tie\Ini\Ini.pll"

!ELSEIF  "$(CFG)" == "TieIni - Win32 Debug"

# PROP BASE Use_MFC 0
# PROP BASE Use_Debug_Libraries 1
# PROP BASE Output_Dir "Debug"
# PROP BASE Intermediate_Dir "Debug"
# PROP BASE Target_Dir ""
# PROP Use_MFC 0
# PROP Use_Debug_Libraries 1
# PROP Output_Dir "out"
# PROP Intermediate_Dir "out"
# PROP Ignore_Export_Lib 0
# PROP Target_Dir ""
# ADD BASE CPP /nologo /MTd /W3 /Gm /GX /Zi /Od /D "WIN32" /D "_DEBUG" /D "_WINDOWS" /YX /FD /c
# ADD CPP /nologo /MTd /W3 /Gm /GX /Zi /Od /I "s:\include\perl" /I "s:\include\perl\inc" /D "WIN32" /D "_DEBUG" /D "_WINDOWS" /D "PERL_OBJECT" /D "EMBED" /D "MSWIN32" /YX /FD /c
# ADD BASE MTL /nologo /D "_DEBUG" /mktyplib203 /o NUL /win32
# ADD MTL /nologo /D "_DEBUG" /mktyplib203 /o NUL /win32
# ADD BASE RSC /l 0x409 /d "_DEBUG"
# ADD RSC /l 0x409 /i "s:\include\perl" /d "_DEBUG" /d "MSWIN32" /d "EMBED" /d "PERL_OBJECT"
BSC32=bscmake.exe
# ADD BASE BSC32 /nologo
# ADD BSC32 /nologo
LINK32=link.exe
# ADD BASE LINK32 kernel32.lib user32.lib gdi32.lib winspool.lib comdlg32.lib advapi32.lib shell32.lib ole32.lib oleaut32.lib uuid.lib odbc32.lib odbccp32.lib /nologo /subsystem:windows /dll /debug /machine:I386 /pdbtype:sept
# ADD LINK32 kernel32.lib user32.lib /nologo /subsystem:windows /dll /debug /machine:I386 /out:"c:\perl\lib\auto\win32\Tie\Ini\Ini.pll" /pdbtype:sept

!ELSEIF  "$(CFG)" == "TieIni - Win32 Win32 311"

# PROP BASE Use_MFC 0
# PROP BASE Use_Debug_Libraries 1
# PROP BASE Output_Dir "TieIni__"
# PROP BASE Intermediate_Dir "TieIni__"
# PROP BASE Ignore_Export_Lib 0
# PROP BASE Target_Dir ""
# PROP Use_MFC 0
# PROP Use_Debug_Libraries 1
# PROP Output_Dir "TieIni__"
# PROP Intermediate_Dir "TieIni__"
# PROP Ignore_Export_Lib 0
# PROP Target_Dir ""
# ADD BASE CPP /nologo /MTd /W3 /Gm /GX /Zi /Od /I "s:\include\perl" /I "s:\include\perl\inc" /D "WIN32" /D "_DEBUG" /D "_WINDOWS" /D "PERL_OBJECT" /D "EMBED" /D "MSWIN32" /YX /FD /c
# ADD CPP /nologo /MTd /W3 /Gm /GX /Zi /O2 /I "s:\include\311\perl" /I "s:\include\perl\311\inc" /D "WIN32" /D "_DEBUG" /D "_WINDOWS" /D "PERL_OBJECT" /D "EMBED" /D "MSWIN32" /YX /FD /c
# ADD BASE MTL /nologo /D "_DEBUG" /mktyplib203 /o NUL /win32
# ADD MTL /nologo /D "_DEBUG" /mktyplib203 /o NUL /win32
# ADD BASE RSC /l 0x409 /d "_DEBUG"
# ADD RSC /l 0x409 /fo"out/TieIni.res" /i "s:\include\perl\311" /d "_DEBUG" /d "MSWIN32" /d "EMBED" /d "PERL_OBJECT"
BSC32=bscmake.exe
# ADD BASE BSC32 /nologo
# ADD BSC32 /nologo
LINK32=link.exe
# ADD BASE LINK32 kernel32.lib user32.lib /nologo /subsystem:windows /dll /debug /machine:I386 /out:"c:\perl\lib\auto\win32\Tie\Ini.pll" /pdbtype:sept
# ADD LINK32 kernel32.lib user32.lib /nologo /subsystem:windows /dll /debug /machine:I386 /out:"bin/Ini_311.pll" /pdbtype:sept

!ELSEIF  "$(CFG)" == "TieIni - Win32 Win32 307"

# PROP BASE Use_MFC 0
# PROP BASE Use_Debug_Libraries 1
# PROP BASE Output_Dir "TieIni_0"
# PROP BASE Intermediate_Dir "TieIni_0"
# PROP BASE Ignore_Export_Lib 0
# PROP BASE Target_Dir ""
# PROP Use_MFC 0
# PROP Use_Debug_Libraries 1
# PROP Output_Dir "TieIni_0"
# PROP Intermediate_Dir "TieIni_0"
# PROP Ignore_Export_Lib 0
# PROP Target_Dir ""
# ADD BASE CPP /nologo /MTd /W3 /Gm /GX /Zi /Od /I "s:\include\perl" /I "s:\include\perl\inc" /D "WIN32" /D "_DEBUG" /D "_WINDOWS" /D "PERL_OBJECT" /D "EMBED" /D "MSWIN32" /YX /FD /c
# ADD CPP /nologo /MTd /W3 /Gm /GX /Zi /O2 /I "s:\include\perl\307" /I "s:\include\perl\307\inc" /D "WIN32" /D "_DEBUG" /D "_WINDOWS" /D "PERL_OBJECT" /D "EMBED" /D "MSWIN32" /YX /FD /c
# ADD BASE MTL /nologo /D "_DEBUG" /mktyplib203 /o NUL /win32
# ADD MTL /nologo /D "_DEBUG" /mktyplib203 /o NUL /win32
# ADD BASE RSC /l 0x409 /d "_DEBUG"
# ADD RSC /l 0x409 /fo"out/TieIni.res" /i "s:\include\perl\307" /d "_DEBUG" /d "MSWIN32" /d "EMBED" /d "PERL_OBJECT"
BSC32=bscmake.exe
# ADD BASE BSC32 /nologo
# ADD BSC32 /nologo
LINK32=link.exe
# ADD BASE LINK32 kernel32.lib user32.lib /nologo /subsystem:windows /dll /debug /machine:I386 /out:"c:\perl\lib\auto\win32\Tie\Ini.pll" /pdbtype:sept
# ADD LINK32 kernel32.lib user32.lib /nologo /subsystem:windows /dll /debug /machine:I386 /out:"bin/Ini_307.pll" /pdbtype:sept

!ELSEIF  "$(CFG)" == "TieIni - Win32 Win32 Core"

# PROP BASE Use_MFC 0
# PROP BASE Use_Debug_Libraries 1
# PROP BASE Output_Dir "TieIni_1"
# PROP BASE Intermediate_Dir "TieIni_1"
# PROP BASE Ignore_Export_Lib 0
# PROP BASE Target_Dir ""
# PROP Use_MFC 0
# PROP Use_Debug_Libraries 1
# PROP Output_Dir "TieIni_1"
# PROP Intermediate_Dir "TieIni_1"
# PROP Ignore_Export_Lib 0
# PROP Target_Dir ""
# ADD BASE CPP /nologo /MTd /W3 /Gm /GX /Zi /Od /I "s:\include\perl" /I "s:\include\perl\inc" /D "WIN32" /D "_DEBUG" /D "_WINDOWS" /D "PERL_OBJECT" /D "EMBED" /D "MSWIN32" /YX /FD /c
# ADD CPP /nologo /MTd /W3 /Gm /GX /Zi /O2 /I "s:\include\perl\core" /I "s:\include\perl\core\inc" /D "WIN32" /D "_DEBUG" /D "_WINDOWS" /D "MSWIN32" /D "EMBED" /YX /FD /c
# ADD BASE MTL /nologo /D "_DEBUG" /mktyplib203 /o NUL /win32
# ADD MTL /nologo /D "_DEBUG" /mktyplib203 /o NUL /win32
# ADD BASE RSC /l 0x409 /d "_DEBUG"
# ADD RSC /l 0x409 /fo"out/TieIni.res" /i "s:\include\perl\core" /d "_DEBUG"
BSC32=bscmake.exe
# ADD BASE BSC32 /nologo
# ADD BSC32 /nologo
LINK32=link.exe
# ADD BASE LINK32 kernel32.lib user32.lib /nologo /subsystem:windows /dll /debug /machine:I386 /out:"c:\perl\lib\auto\win32\Tie\Ini.pll" /pdbtype:sept
# ADD LINK32 perl.lib kernel32.lib user32.lib /nologo /subsystem:windows /dll /debug /machine:I386 /out:"bin/ini_core.dll" /pdbtype:sept /libpath:"s:\lib\perl\core"

!ENDIF 

# Begin Target

# Name "TieIni - Win32 Release"
# Name "TieIni - Win32 Debug"
# Name "TieIni - Win32 Win32 311"
# Name "TieIni - Win32 Win32 307"
# Name "TieIni - Win32 Win32 Core"
# Begin Source File

SOURCE=.\ini.pm
# End Source File
# Begin Source File

SOURCE=.\README
# End Source File
# Begin Source File

SOURCE=.\TEST.PL
# End Source File
# Begin Source File

SOURCE=.\TieIni.cpp
# End Source File
# Begin Source File

SOURCE=.\TieIni.def
# End Source File
# Begin Source File

SOURCE=.\TieIni.h
# End Source File
# Begin Source File

SOURCE=.\TieIni.rc

!IF  "$(CFG)" == "TieIni - Win32 Release"

!ELSEIF  "$(CFG)" == "TieIni - Win32 Debug"

!ELSEIF  "$(CFG)" == "TieIni - Win32 Win32 311"

!ELSEIF  "$(CFG)" == "TieIni - Win32 Win32 307"

!ELSEIF  "$(CFG)" == "TieIni - Win32 Win32 Core"

!ENDIF 

# End Source File
# Begin Source File

SOURCE=.\TieIniBuild.h
# End Source File
# End Target
# End Project
