/*
  Copyright (c) 2010 Slaven Rezic. All rights reserved.
  This program is free software; you can redistribute it and/or
  modify it under the same terms as Perl itself.
*/

#include <EXTERN.h>
#include <perl.h>
#include <XSUB.h>

#include <X11/Xlib.h>
#include <X11/Xcursor/Xcursor.h>

#include "tkGlue.def"

#include "pTk/tkPort.h"
#include "pTk/tkInt.h"
#include "tkGlue.h"
#include "tkGlue.m"
#include "pTk/tkVMacro.h"

DECLARE_VTABLES;

MODULE = Tk::Xcursor	PACKAGE = Tk::Xcursor

PROTOTYPES: DISABLE

int
SupportsARGB(Tk_Window tkwin)
CODE:
    if (Tk_WindowId(tkwin) == None)
        Tk_MakeWindowExist(tkwin);
    RETVAL = XcursorSupportsARGB(Tk_Display(tkwin));
OUTPUT:
    RETVAL

Cursor
LoadCursor(Tk_Window tkwin, const char *file)
CODE:
    if (Tk_WindowId(tkwin) == None)
        Tk_MakeWindowExist(tkwin);
    RETVAL = XcursorFilenameLoadCursor(Tk_Display(tkwin), file);
OUTPUT:
    RETVAL

int
Set(Cursor self, Tk_Window tkwin)
CODE:
    if (Tk_WindowId(tkwin) == None)
        Tk_MakeWindowExist(tkwin);
    RETVAL = XDefineCursor(Tk_Display(tkwin), Tk_WindowId(tkwin), self);
OUTPUT:
    RETVAL

BOOT:
 {
  IMPORT_VTABLES;
 }
