#ifndef lint
static char rcsid[] = "$Id: ptclGlue.c,v 1.2 1996/01/14 23:15:07 ilya Exp $";
#endif

#include "ptcl.h"
#ifdef NO_STDLIB_H
#   include "compat/stdlib.h"
#else
#   include <stdlib.h>
#endif
#include <varargs.h>

void LangFreeSplitProc(int num, Arg* args) {ckfree((char *)args);}

/*
 *----------------------------------------------------------------------
 *
 * LangDoCallback --
 *
 *	Calls a portableTk callback.
 *
 * Results:
 *	Standard TCL result.
 *
 * Side effects:
 *	Can be almost anything.
 *
 *----------------------------------------------------------------------
 */
	/* VARARGS2 */
#ifndef lint
int
LangDoCallback(va_alist)
#else
int
	/* VARARGS2 */ /* ARGSUSED */
LangDoCallback(interp, cmd, result, count, va_alist)
    Tcl_Interp *interp;		/* Interpreter To use for a call. */
    LangCallback *cmd;		/* Command to call. */
    int result;			/* Whether to clear result before call. */
    int count;			/* How may arguments provided. */
#endif
    va_dcl			/* Format and arguments. */
{
#define CMD_LENGTH 4088
    va_list argList;
    register Tcl_Interp *iPtr;
    char *command;
    int res;
    int cnt;
    char buffer[CMD_LENGTH];
    char *format;		/* printf representation of arguments. */

    va_start(argList);
    iPtr = va_arg(argList, Tcl_Interp *);
    command = va_arg(argList, char *);
    res = va_arg(argList, int);
    cnt = va_arg(argList, int);
    format = va_arg(argList, char *);
    vsprintf(buffer, format, argList);
    va_end(argList);
    return Tcl_VarEval(iPtr, command, buffer, (char *) NULL);
}

/*
 *----------------------------------------------------------------------
 *
 * Tcl_DoubleResults --
 *
 *	Sets a result from a list of doubles.
 *
 * Results:
 *	None.
 *
 * Side effects:
 *	None.
 *
 *----------------------------------------------------------------------
 */
void
#ifndef lint
Tcl_DoubleResults(va_alist)
#else
	/* VARARGS2 */ /* ARGSUSED */
Tcl_DoubleResults(interp, count, append, va_alist)
    Tcl_Interp *interp;		/* Interpreter whose errorCode variable is
				 * to be set. */
    int count;			/* How many arguments. */
    int append;			/* Whether to clear result. */
#endif
    va_dcl
{
    va_list argList;
    register Tcl_Interp *iPtr;
    int cnt;
    int app;

    va_start(argList);
    iPtr = va_arg(argList, Tcl_Interp *);
    cnt = va_arg(argList, int);
    app = va_arg(argList, int);
    if (!app)
      Tcl_ResetResult(iPtr);
    if (!cnt) {
      panic("No results");
    }

    while (cnt--)  {
      double value = va_arg(argList, double);
      char buffer[TCL_DOUBLE_SPACE];

      Tcl_PrintDouble(iPtr, value, buffer);
      Tcl_AppendResult(iPtr, buffer, NULL);
    }
    va_end(argList);
}

/*
 *----------------------------------------------------------------------
 *
 * Tcl_IntResults --
 *
 *	Sets a result from a list of integers.
 *
 * Results:
 *	None.
 *
 * Side effects:
 *	None.
 *
 *----------------------------------------------------------------------
 */
void
#ifndef lint
Tcl_IntResults(va_alist)
#else
	/* VARARGS2 */ /* ARGSUSED */
Tcl_IntResults(interp, count, append, va_alist)
    Tcl_Interp *interp;		/* Interpreter whose errorCode variable is
				 * to be set. */
    int count;			/* How many arguments. */
    int append;			/* Whether to clear result. */
#endif
    va_dcl
{
    va_list argList;
    register Tcl_Interp *iPtr;
    int cnt;
    int app;

    va_start(argList);
    iPtr = va_arg(argList, Tcl_Interp *);
    cnt = va_arg(argList, int);
    app = va_arg(argList, int);
    if (!app)
      Tcl_ResetResult(iPtr);
    if (!cnt) {
      panic("No results");
    }

    while (cnt--)  {
      int value = va_arg(argList, int);
      char buffer[TCL_DOUBLE_SPACE];

      sprintf(buffer, "%d", value);
      Tcl_AppendResult(iPtr, buffer, NULL);
    }
    va_end(argList);
}

void
LangFreeArg(arg, freeProc)
Arg arg;
Tcl_FreeProc *freeProc;
{
    if (freeProc != 0) {
	if (freeProc == (Tcl_FreeProc *) free) {
	    ckfree(arg);
	} else {
	    (*freeProc)(arg);
	}
    }
}

void
ListFactoryAppendCopyWithType(lfPtr, arg, type)
     ListFactory *lfPtr;		/* Where to append. */
     Arg arg;				/* What to append */
     char *type;			/* What type to assign, NULL
					 * for default type. */
{
    if (!type) {
        type = "";
    }
    lfPtr = ListFactoryNewLevel(lfPtr);
    ListFactoryAppendCopy(lfPtr, type);
    ListFactoryAppendCopy(lfPtr, arg);
    ListFactoryEndLevel(lfPtr);
}
