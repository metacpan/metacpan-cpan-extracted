# *********************************************************************
# * Win32::Monitoring::DllInject - 
# *    Injects code into Win32 programs to overloaded functions
# * *********************************************************************
# * Makefile: Visual Studio nmake file for compiling example DLL
# * *********************************************************************
# * Authors: Tobias Oetiker
# *          Roman Plessl
# *
# * Copyright (c) 2008 by OETIKER+PARTNER AG. All rights reserved.
# * 
# * Win32::Monitoring::DllInject is free software: you can redistribute 
# * it and/or modify it under the terms of the GNU General Public License 
# * as published by the Free Software Foundation, either version 3 of the 
# * License, or (at your option) any later version.
# *
# * $Id: Makefile 203 2009-07-23 09:09:58Z rplessl $ 
# ***********************************************************************

CC=cl
CCFLAGS=-c -I. -nologo -GF -W3 -MT -Zi -O1 -DNDEBUG -D_CONSOLE -DWIN32 -DNO_STRICT -DNO_HASH_SEED
CPPFLAGS=-D_UNICODE -DUNICODE -mconsole
LINK=link
DLLFLAGS=-dll -nologo -nodefaultlib -machine:x86 
LIBS=kernel32.lib shell32.lib psapi.lib imagehlp.lib libcmt.lib user32.lib

all: HookedFunctions.dll

HookedFunctions.dll: HookedFunctions.c
	@echo Compiling HookedFunctions.obj
	$(CC) $(CCFLAGS) HookedFunctions.c
	@echo Linking HookedFunctions.dll 
	$(LINK) $(DLLFLAGS) HookedFunctions.obj $(LIBS) 

test_llu.exe: test_llu.c
	@echo Compiling $<
	$(CC) $(CPPFLAGS) $(CFLAGS) $< -o $@ 

clean:
	del *.dll *.obj *.pdb *~

