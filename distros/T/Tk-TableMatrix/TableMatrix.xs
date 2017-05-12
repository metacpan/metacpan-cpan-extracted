
#define PERL_NO_GET_CONTEXT
#include <EXTERN.h>
#include <perl.h>
#include <XSUB.h>

#undef MAX
#undef MIN

#include "tkGlue.def"

#include "pTk/tkPort.h"
#include "pTk/tkTable.h"
#include "pTk/tkInt.h"
#include "pTk/tixPort.h"
#include "pTk/tixInt.h"
#include "tkGlue.h"
#include "tkGlue.m"
#include "pTk/tkVMacro.h"


/* perltk TableMatrix's replacement for TCL_unsetVar. deletes an element in a hash */
EXTERN void	tkTableUnsetElement _ANSI_ARGS_((Var hashEntry, char * key)){
	int len;
	dTHX;	
	len = strlen(key);
	hv_delete( (HV*) hashEntry, key, len, G_DISCARD);
}


DECLARE_VTABLES;

MODULE = Tk::TableMatrix	PACKAGE = Tk

PROTOTYPES: DISABLE


#ifdef TK800XSTK

void
tablematrix(...)
CODE:
 {
  XSRETURN(XSTkCommand(cv,(Tcl_CmdProc *)Tk_TableObjCmd,items,&ST(0)));
 }

#else

void
tablematrix(...)
CODE:
 {
  XSRETURN(XSTkCommand(cv,1,Tk_TableObjCmd,items,&ST(0)));
 }
 
#endif

BOOT:
 {
  IMPORT_VTABLES;
 }
