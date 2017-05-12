/*
  Copyright (c) 1995-1997 Nick Ing-Simmons. All rights reserved.
  This program is free software; you can redistribute it and/or
  modify it under the same terms as Perl itself.
*/

#include <EXTERN.h>
#include <perl.h>
#include <XSUB.h>

#include "tkGlue.def"

#include "pTk/tkPort.h"
#include "pTk/tkInt.h"
#include "tkGlue.h"
#include "tkGlue.m"
#include "pTk/tkVMacro.h"

DECLARE_VTABLES;

extern Tk_ItemType ptkCanvPointType;


MODULE = Tk::Canvas::Point	PACKAGE = Tk

PROTOTYPES: DISABLE

BOOT:
 {
  IMPORT_VTABLES;
  Tk_CreateItemType(&ptkCanvPointType);
 }
