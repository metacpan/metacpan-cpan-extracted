/*
 * $Id: tkWinPrint.h,v 1.2 2004/03/20 20:39:39 eserte Exp $
 * Author: Slaven Rezic
 *
 * Copyright (C) 1999 Slaven Rezic. All rights reserved.
 *
 * Mail: eserte@cs.tu-berlin.de
 * WWW:  http://user.cs.tu-berlin.de/~eserte/
 *
 */

#ifndef _WINPRINT
#define _WINPRINT

#include "pTk/tkInt.h"
#include "pTk/tkCanvas.h"

EXTERN void PrintCanvasCmd _ANSI_ARGS_((TkCanvas *canvasPtr, Tcl_Interp *interp, int argc, Arg *argv));

#endif /* _WINPRINT */
