# ********************************************************************* 
# * Win32::Monitoring::DllInject - 
# *    Injects code into Win32 programs to overloaded functions
# * *********************************************************************
# * Makefile: Makefile for compiling example DLL with mingw32
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
# * $Id: Makefile.migw32.mak 203 2009-07-23 09:09:58Z rplessl $ 
# ***********************************************************************

CPPFLAGS=-D_UNICODE -DUNICODE -mconsole
# compiling this with -O2 renders a dll that causes the injected program to crash ... hmmm
CFLAGS=-fno-strict-aliasing -Wall -std=c99 -pedantic -Wundef -Wshadow -Wpointer-arith -Wcast-align -Wmissing-prototypes -Wmissing-declarations -Wnested-externs -Winline -Wold-style-definition
DLLFLAGS=-mno-cygwin -mwindows -mdll -DWIN32 -DNDEBUG -D_WINDOWS -D_USRDLL -DTHEDLL_EXPORTS -D_WINDLL
LIBS=-limagehlp
CC=i386-mingw32-gcc

all: HookedFunctions.dll 

%.dll: %.c
	@echo Compiling $<
	$(CC) $(DLLFLAGS) $(CPPFLAGS) $(CFLAGS) $< $(LIBS) -o $@

test_llu.exe: test_llu.c
	@echo Compiling $<
	$(CC) $(CPPFLAGS) $(CFLAGS) $< -o $@

HookedFunctions.dll: HookedFunctions.c

clean:
	rm -f *.dll *.exe *~
