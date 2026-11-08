/*
  eText.xs -- XS glue for Tk::eText.

  Copyright (c) 1996 Ilya Zakharevich.
  Modernization for Tk 804 (c) 2026.

  This program is free software; you can redistribute it and/or
  modify it under the same terms as Perl itself.
*/
#define PERL_NO_GET_CONTEXT
#include <EXTERN.h>
#include <perl.h>
#include <XSUB.h>

#include "tkGlue.def"

#include "pTk/tkPort.h"
#include "pTk/tkInt.h"
#include "tkGlue.h"
#include "tkGlue.m"
#include "pTk/tkVMacro.h"

#include "eTextSyms.h"

DECLARE_VTABLES;

extern int Tk_eTextCmd _ANSI_ARGS_((ClientData clientData,
			Tcl_Interp *interp, int argc, Tcl_Obj *CONST objv[]));

MODULE = Tk::eText	PACKAGE = Tk

PROTOTYPES: DISABLE

void
etext(...)
CODE:
 {
  TKXSRETURN(XSTkCommand(cv,1,Tk_eTextCmd,items,&ST(0)));
 }

BOOT:
 {
  IMPORT_VTABLES;
 }
