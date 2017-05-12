/*
  Copyright (c) 1995-1997 Nick Ing-Simmons. All rights reserved.
  This program is free software; you can redistribute it and/or
  modify it under the same terms as Perl itself.
*/

#include <EXTERN.h>
#include <perl.h>
#include <XSUB.h>

#include <tkGlue.def>

#include <pTk/tkPort.h>
#include <pTk/tkInt.h>
#ifdef _WIN32
#include <pTk/tkWinInt.h>
#endif
#include <pTk/tkImgPhoto.h>
#include <pTk/tkVMacro.h>
#include <tkGlue.h>
#include <tkGlue.m>

extern int
ZincObjCmd(
	   ClientData client_data,
	   Tcl_Interp* interp,
	   int argc,
	   Tcl_Obj* CONST args[]);

extern int
ZnVideomapObjCmd(
	         ClientData client_data,
	         Tcl_Interp* interp,
	         int argc,
	         Tcl_Obj* CONST args[]);

extern int
ZnMapInfoObjCmd(
	        ClientData client_data,
	        Tcl_Interp* interp,
	        int argc,
	        Tcl_Obj* CONST args[]);

DECLARE_VTABLES;
TkimgphotoVtab *TkimgphotoVptr;

MODULE = Tk::Zinc	PACKAGE = Tk::Zinc

PROTOTYPES: DISABLE

BOOT:
 {
  IMPORT_VTABLES;
  TkimgphotoVptr = (TkimgphotoVtab *) SvIV(perl_get_sv("Tk::TkimgphotoVtab",GV_ADDWARN|GV_ADD));

  Lang_TkCommand("zinc", ZincObjCmd);
  Lang_TkCommand("videomap", ZnVideomapObjCmd);
  Lang_TkCommand("mapinfo", ZnMapInfoObjCmd);
 }
