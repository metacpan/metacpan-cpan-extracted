/*
 * (c) 2000 Slaven Rezic
 *
 */

#ifdef __cplusplus
extern "C" {
#endif

#include <EXTERN.h>
#include <perl.h>
#include <XSUB.h>

#include <windows.h>

#include "tkGlue.def"

#include "pTk/tkPort.h"
#include "pTk/tkInt.h"
#include "pTk/tkWin.h"
#include "pTk/tkWinInt.h"
#include "pTk/tkVMacro.h"
#include "tkGlue.h"
#include "tkGlue.m"

#include "tkWinPrint.h"
#include "tkWinPrint.m"

#ifdef __cplusplus
}
#endif

DECLARE_VTABLES;
DECLARE_WIN32_VTABLES;

XS(XS_Tk__Canvas_PrintCanvasCmd)
{
    dXSARGS;

    //TkCanvas *canvasPtr = (TkCanvas *) clientData;

    TkCanvas *	canvasPtr = WindowCommand(ST(0),NULL,1)->Tk.clientData; //ST(0);
    Tcl_Interp *	interp = WindowCommand(ST(1),NULL,1)->interp;

    PrintCanvasCmd(canvasPtr, interp, items,&ST(0));
    XSRETURN_EMPTY;
}

#ifdef __cplusplus
extern "C"
#endif
XS(boot_Tk__WinPrint)
{
    dXSARGS;
    char* file = __FILE__;

    XS_VERSION_BOOTCHECK ;

    newXS("Tk::Canvas::PrintCanvasCmd", XS_Tk__Canvas_PrintCanvasCmd, file);

    /* Initialisation Section */

 {
  IMPORT_VTABLES;
  IMPORT_WIN32_VTABLES;
#ifdef GCC
  install_vtab("TkwinprintVtab",TkwinprintVGet(),sizeof(TkwinprintVtab));
#else
  sv_setiv(FindTkVarName("TkwinprintVtab",GV_ADD|GV_ADDMULTI),(IV) TkwinprintVGet());
#endif

 }

    /* End of Initialisation Section */

    XSRETURN_YES;
}

