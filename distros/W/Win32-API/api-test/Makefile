# Microsoft Developer Studio Generated NMAKE File, Based on API_test.dsp
!IF "$(CFG)" == ""
CFG=API_test - Win32 Release
!MESSAGE No configuration specified. Defaulting to API_test - Win32 Release.
!ENDIF 

!IF "$(CFG)" != "API_test - Win32 Release" && "$(CFG)" != "API_test - Win32 Debug"
!MESSAGE Invalid configuration "$(CFG)" specified.
!MESSAGE You can specify a configuration when running NMAKE
!MESSAGE by defining the macro CFG on the command line. For example:
!MESSAGE 
!MESSAGE NMAKE CFG="API_test - Win32 Debug"
!MESSAGE 
!MESSAGE Possible choices for configuration are:
!MESSAGE 
!MESSAGE "API_test - Win32 Release" (based on "Win32 (x86) Dynamic-Link Library")
!MESSAGE "API_test - Win32 Debug" (based on "Win32 (x86) Dynamic-Link Library")
!MESSAGE 
!ERROR An invalid configuration is specified.
!ENDIF 

!IF "$(OS)" == "Windows_NT"
NULL=
!ELSE 
NULL=nul
!ENDIF 

!IF  "$(CFG)" == "API_test - Win32 Release"

OUTDIR=.\Release
INTDIR=.\Release
# Begin Custom Macros
OutDir=.\Release
# End Custom Macros

ALL : "$(OUTDIR)\API_test.dll"


CLEAN :
	-@erase "$(INTDIR)\API_test.obj"
	-@erase "$(INTDIR)\API_test.pch"
	-@erase "$(INTDIR)\StdAfx.obj"
	-@erase "$(INTDIR)\vc60.idb"
	-@erase "$(OUTDIR)\API_test.dll"
	-@erase "$(OUTDIR)\API_test.exp"
	-@erase "$(OUTDIR)\API_test.lib"

"$(OUTDIR)" :
    if not exist "$(OUTDIR)/$(NULL)" mkdir "$(OUTDIR)"

CPP=cl.exe
CPP_PROJ=/nologo /MT /W3 /GX /O2 /D "WIN32" /D "NDEBUG" /D "_WINDOWS" /D "_MBCS" /D "_USRDLL" /D "API_TEST_EXPORTS" /Fp"$(INTDIR)\API_test.pch" /Yu"stdafx.h" /Fo"$(INTDIR)\\" /Fd"$(INTDIR)\\" /FD /c 

.c$(INTDIR).obj::
   $(CPP) @<<
   $(CPP_PROJ) $< 
<<

.cpp$(INTDIR).obj::
   $(CPP) @<<
   $(CPP_PROJ) $< 
<<

.cxx$(INTDIR).obj::
   $(CPP) @<<
   $(CPP_PROJ) $< 
<<

.c$(INTDIR).sbr::
   $(CPP) @<<
   $(CPP_PROJ) $< 
<<

.cpp$(INTDIR).sbr::
   $(CPP) @<<
   $(CPP_PROJ) $< 
<<

.cxx$(INTDIR).sbr::
   $(CPP) @<<
   $(CPP_PROJ) $< 
<<

MTL=midl.exe
MTL_PROJ=/nologo /D "NDEBUG" /mktyplib203 /win32 
RSC=rc.exe
BSC32=bscmake.exe
BSC32_FLAGS=/nologo /o"$(OUTDIR)\API_test.bsc" 
BSC32_SBRS= \
	
LINK32=link.exe
LINK32_FLAGS=kernel32.lib user32.lib gdi32.lib winspool.lib comdlg32.lib advapi32.lib shell32.lib ole32.lib oleaut32.lib uuid.lib odbc32.lib odbccp32.lib /nologo /dll /incremental:no /pdb:"$(OUTDIR)\API_test.pdb" /machine:I386 /def:".\API_test.def" /out:"$(OUTDIR)\API_test.dll" /implib:"$(OUTDIR)\API_test.lib" 
DEF_FILE= \
	".\API_test.def"
LINK32_OBJS= \
	"$(INTDIR)\API_test.obj" \
	"$(INTDIR)\StdAfx.obj"

"$(OUTDIR)\API_test.dll" : "$(OUTDIR)" $(DEF_FILE) $(LINK32_OBJS)
    $(LINK32) @<<
  $(LINK32_FLAGS) $(LINK32_OBJS)
<<

SOURCE="$(InputPath)"
PostBuild_Desc=Move DLL into place
DS_POSTBUILD_DEP=$(INTDIR)\postbld.dep

ALL : $(DS_POSTBUILD_DEP)

# Begin Custom Macros
OutDir=.\Release
# End Custom Macros

$(DS_POSTBUILD_DEP) : "$(OUTDIR)\API_test.dll"
   copy Release\API_Test.dll ..
	echo Helper for Post-build step > "$(DS_POSTBUILD_DEP)"

!ELSEIF  "$(CFG)" == "API_test - Win32 Debug"

OUTDIR=.\Debug
INTDIR=.\Debug
# Begin Custom Macros
OutDir=.\Debug
# End Custom Macros

ALL : "$(OUTDIR)\API_test.dll"


CLEAN :
	-@erase "$(INTDIR)\API_test.obj"
	-@erase "$(INTDIR)\API_test.pch"
	-@erase "$(INTDIR)\StdAfx.obj"
	-@erase "$(INTDIR)\vc60.idb"
	-@erase "$(INTDIR)\vc60.pdb"
	-@erase "$(OUTDIR)\API_test.dll"
	-@erase "$(OUTDIR)\API_test.exp"
	-@erase "$(OUTDIR)\API_test.ilk"
	-@erase "$(OUTDIR)\API_test.lib"
	-@erase "$(OUTDIR)\API_test.pdb"

"$(OUTDIR)" :
    if not exist "$(OUTDIR)/$(NULL)" mkdir "$(OUTDIR)"

CPP=cl.exe
CPP_PROJ=/nologo /MTd /W3 /Gm /GX /ZI /Od /D "WIN32" /D "_DEBUG" /D "_WINDOWS" /D "_MBCS" /D "_USRDLL" /D "API_TEST_EXPORTS" /Fp"$(INTDIR)\API_test.pch" /Yu"stdafx.h" /Fo"$(INTDIR)\\" /Fd"$(INTDIR)\\" /FD /GZ /c 

.c{$(INTDIR)}.obj::
   $(CPP) @<<
   $(CPP_PROJ) $< 
<<

.cpp{$(INTDIR)}.obj::
   $(CPP) @<<
   $(CPP_PROJ) $< 
<<

.cxx{$(INTDIR)}.obj::
   $(CPP) @<<
   $(CPP_PROJ) $< 
<<

.c{$(INTDIR)}.sbr::
   $(CPP) @<<
   $(CPP_PROJ) $< 
<<

.cpp{$(INTDIR)}.sbr::
   $(CPP) @<<
   $(CPP_PROJ) $< 
<<

.cxx{$(INTDIR)}.sbr::
   $(CPP) @<<
   $(CPP_PROJ) $< 
<<

MTL=midl.exe
MTL_PROJ=/nologo /D "_DEBUG" /mktyplib203 /win32 
RSC=rc.exe
BSC32=bscmake.exe
BSC32_FLAGS=/nologo /o"$(OUTDIR)\API_test.bsc" 
BSC32_SBRS= \
	
LINK32=link.exe
LINK32_FLAGS=kernel32.lib user32.lib gdi32.lib winspool.lib comdlg32.lib advapi32.lib shell32.lib ole32.lib oleaut32.lib uuid.lib odbc32.lib odbccp32.lib /nologo /dll /incremental:yes /pdb:"$(OUTDIR)\API_test.pdb" /debug /machine:I386 /def:".\API_test.def" /out:"$(OUTDIR)\API_test.dll" /implib:"$(OUTDIR)\API_test.lib" /pdbtype:sept 
DEF_FILE= \
	".\API_test.def"
LINK32_OBJS= \
	"$(INTDIR)\API_test.obj" \
	"$(INTDIR)\StdAfx.obj"

"$(OUTDIR)\API_test.dll" : "$(OUTDIR)" $(DEF_FILE) $(LINK32_OBJS)
    $(LINK32) @<<
  $(LINK32_FLAGS) $(LINK32_OBJS)
<<

!ENDIF 


!IF "$(CFG)" == "API_test - Win32 Release" || "$(CFG)" == "API_test - Win32 Debug"
SOURCE=.\API_test.cpp

"$(INTDIR)\API_test.obj" : $(SOURCE) "$(INTDIR)" "$(INTDIR)\API_test.pch"


SOURCE=.\StdAfx.cpp

!IF  "$(CFG)" == "API_test - Win32 Release"

CPP_SWITCHES=/nologo /MT /W3 /GX /O2 /D "WIN32" /D "NDEBUG" /D "_WINDOWS" /D "_MBCS" /D "_USRDLL" /D "API_TEST_EXPORTS" /Fp"$(INTDIR)\API_test.pch" /Yc"stdafx.h" /Fo"$(INTDIR)\\" /Fd"$(INTDIR)\\" /FD /c 

"$(INTDIR)\StdAfx.obj"	"$(INTDIR)\API_test.pch" : $(SOURCE) "$(INTDIR)"
	$(CPP) @<<
  $(CPP_SWITCHES) $(SOURCE)
<<


!ELSEIF  "$(CFG)" == "API_test - Win32 Debug"

CPP_SWITCHES=/nologo /MTd /W3 /Gm /GX /ZI /Od /D "WIN32" /D "_DEBUG" /D "_WINDOWS" /D "_MBCS" /D "_USRDLL" /D "API_TEST_EXPORTS" /Fp"$(INTDIR)\API_test.pch" /Yc"stdafx.h" /Fo"$(INTDIR)\\" /Fd"$(INTDIR)\\" /FD /GZ /c 

"$(INTDIR)\StdAfx.obj"	"$(INTDIR)\API_test.pch" : $(SOURCE) "$(INTDIR)"
	$(CPP) @<<
  $(CPP_SWITCHES) $(SOURCE)
<<


!ENDIF 


!ENDIF 

