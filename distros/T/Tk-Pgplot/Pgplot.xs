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
#include "pTk/tkVMacro.h"
#include "tkGlue.h"
#include "tkGlue.m"
#include "ptkpgplot.h"

DECLARE_VTABLES;


MODULE = Tk::Pgplot	PACKAGE = Tk

void
pgplot(...)
CODE:
 {
   TKXSRETURN(XSTkCommand(cv,0,PgplotCmd,items,&ST(0)));
 }

PROTOTYPES: DISABLE

BOOT:
 {
  IMPORT_VTABLES;
 }

