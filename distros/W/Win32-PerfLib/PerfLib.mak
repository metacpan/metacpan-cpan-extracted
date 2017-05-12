# -*- Makefile -*-
NAME=PerfLib
VERSION=0.03
DLEXT=pll
LIB_EXT=.lib
OBJ_EXT=.obj
ZIP = pkzip25
SOURCE=$(NAME).cpp
PRESOURCE=$(NAME).c
PERLPATH=c:\asperl

ALL : $(NAME).$(DLEXT)


CLEAN :
	-@erase $(NAME).$(OBJ_EXT)
	-@erase "*.idb"
	-@erase "*.pdb"
	-@erase "$(NAME).exp"
	-@erase "$(NAME).ilk"
	-@erase "$(NAME).lib"
	-@erase "$(NAME).$(DLEXT)"
	-@rd /s /q zip
	-@erase "$(NAME)_316_$(VERSION).zip"
	-@erase $(SOURCE)
	-@erase PerfLib.cpp.bak

CPP=cl.exe
CPP_PROJ=-nologo -MD -TP -W3 -GX -O2 -DNDEBUG -DWIN32 -D_WINDOWS -D_MBCS -D_USRDLL -DMSWIN32 -DPERL_OBJECT -DEMBED -DNO_STRICT /c 

.SUFFIXES:
.SUFFIXES:	.exe .obj .asm .cpp .c .cxx .bas .cbl .f .f90 .for .pas .res .rc

.c.obj::
   $(CPP) @<<
   $(CPP_PROJ) $< 
<<

.cpp.obj::
   $(CPP) @<<
   $(CPP_PROJ) $< 
<<

.cxx.obj::
   $(CPP) @<<
   $(CPP_PROJ) $< 
<<

.c.sbr::
   $(CPP) @<<
   $(CPP_PROJ) $< 
<<

.cpp.sbr::
   $(CPP) @<<
   $(CPP_PROJ) $< 
<<

.cxx.sbr::
   $(CPP) @<<
   $(CPP_PROJ) $< 
<<

LINK32=link.exe
LINK32_FLAGS=kernel32.lib user32.lib gdi32.lib winspool.lib comdlg32.lib advapi32.lib shell32.lib ole32.lib oleaut32.lib uuid.lib odbc32.lib odbccp32.lib /nologo /dll /incremental:no /pdb:"$(NAME).pdb" /machine:I386 /def:".\$(NAME).def" /out:"$(NAME).$(DLEXT)" /implib:"$(NAME)$(LIB_EXT)" 
DEF_FILE= \
	$(NAME).def
LINK32_OBJS= \
	$(NAME)$(OBJ_EXT)

$(NAME).$(DLEXT) : $(DEF_FILE) $(LINK32_OBJS)
    $(LINK32) @<<
  $(LINK32_FLAGS) $(LINK32_OBJS)
<<

$(SOURCE) : $(PRESOURCE)
	copy $? $@
	perl -pi.bak -e "s/sv_2mortal/if (SvREFCNT(ST(0))) sv_2mortal/;" $@

dist : zipdist

zipdist : $(NAME)_316_$(VERSION).zip

$(NAME)_316_$(VERSION).zip : $(NAME).$(DLEXT) $(NAME).pm
	-@md zip\auto\win32\$(NAME)
	copy $(NAME).$(DLEXT) zip\auto\win32\$(NAME)
	-@md zip\win32
	copy $(NAME).pm zip\win32
	cd zip & $(ZIP) -add -dir=current ..\$@

install : $(NAME).$(DLEXT) $(NAME).pm
	-@if not exist $(PERLPATH)\lib\auto\win32\$(NAME) md $(PERLPATH)\lib\auto\win32\$(NAME)
	-@xcopy /r /c /d /f $(NAME).$(DLEXT) $(PERLPATH)\lib\auto\win32\$(NAME)
	-@if not exist $(PERLPATH)\lib\win32 md $(PERLPATH)\lib\win32
	-@xcopy /r /c /d /f $(NAME).pm $(PERLPATH)\lib\win32



$(NAME)$(OBJ_EXT) : $(SOURCE)
