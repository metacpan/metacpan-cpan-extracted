/*
 * tkWinWm.c --
 *
 *	This module adds the capture and release "wm" commands to Tk
 */
#ifdef WIN32
#include "tkWinInt.h"
#else
#include "tkInt.h"
int             TkpWmSetState _ANSI_ARGS_((TkWindow * winPtr,
                                int state));
#endif /* WIN32 */




#include "WmCaptureRelease.h" 
#include "tkVMacro.h"

/*
 * Forward declarations for procedures defined in this file:
 */
static int 		WmCaptureCmd _ANSI_ARGS_((Tk_Window tkwin,
			    TkWindow *winPtr, Tcl_Interp *interp, int objc,
			    Tcl_Obj *CONST objv[]));
static int 		WmReleaseCmd _ANSI_ARGS_((Tk_Window tkwin,
			    TkWindow *winPtr, Tcl_Interp *interp, int objc,
			    Tcl_Obj *CONST objv[]));

static void		UnmanageGeometry _ANSI_ARGS_((Tk_Window tkwin));

			    
			    
			    
			    
/*
 *----------------------------------------------------------------------
 *
 * WmCaptureReleaseCmd --
 *
 *	This procedure is invoked to process the "wm" Tcl command.
 *	See the user documentation for details on what it does.
 *
 * Results:
 *	A standard Tcl result.
 *
 * Side effects:
 *	See the user documentation.
 *
 *----------------------------------------------------------------------
 */

	/* ARGSUSED */
int
WmCaptureReleaseCmd(clientData, interp, objc, objv)
    ClientData clientData;	/* Main window associated with
				 * interpreter. */
    Tcl_Interp *interp;		/* Current interpreter. */
    int objc;			/* Number of arguments. */
    Tcl_Obj *CONST objv[];	/* Argument objects. */
{
    Tk_Window tkwin = (Tk_Window) clientData;
    static CONST char *optionStrings[] = {
	"capture", "release",    NULL };
    enum options {
        WMOPT_CAPTURE, WMOPT_RELEASE };
    int index, length;
    char *argv1;
    TkWindow *winPtr;
    TkDisplay *dispPtr = ((TkWindow *) tkwin)->dispPtr;

    if (objc < 2) {
	wrongNumArgs:
	Tcl_WrongNumArgs(interp, 1, objv, "option window ?arg ...?");
	return TCL_ERROR;
    }

    argv1 = Tcl_GetStringFromObj(objv[1], &length);
    if ((argv1[0] == 't') && (strncmp(argv1, "tracing", length) == 0)
	    && (length >= 3)) {
	int wmTracing;
	if ((objc != 2) && (objc != 3)) {
	    Tcl_WrongNumArgs(interp, 2, objv, "?boolean?");
	    return TCL_ERROR;
	}
	if (objc == 2) {
	    Tcl_SetResult(interp, ((dispPtr->flags & TK_DISPLAY_WM_TRACING) ? "1" : ""), TCL_STATIC);


	    return TCL_OK;
	}
	if (Tcl_GetBooleanFromObj(interp, objv[2], &wmTracing) != TCL_OK) {
	    return TCL_ERROR;
	}
	if (wmTracing) {
	    dispPtr->flags |= TK_DISPLAY_WM_TRACING;
	} else {
	    dispPtr->flags &= ~TK_DISPLAY_WM_TRACING;
	}
	return TCL_OK;
    }

    if (Tcl_GetIndexFromObj(interp, objv[1], optionStrings, "option", 0,
	    &index) != TCL_OK) {
	return TCL_ERROR;
    }

    if (objc < 3) {
	goto wrongNumArgs;
    }

    if (TkGetWindowFromObj(interp, tkwin, objv[2], (Tk_Window *) &winPtr)
	    != TCL_OK) {
	return TCL_ERROR;
    }
    if (Tk_IsTopLevel(winPtr)) {
	if ((enum options) index == WMOPT_RELEASE) {
	    Tcl_AppendResult(interp, "window \"", winPtr->pathName,
			"\" is already top-level window",          NULL);
	    return TCL_ERROR;
	}
    }
    else if ((enum options) index != WMOPT_RELEASE) {
	Tcl_AppendResult(interp, "window \"", winPtr->pathName,
		"\" isn't a top-level window",          NULL);
	    return TCL_ERROR;
    }

    switch ((enum options) index) {
      case WMOPT_CAPTURE:
	return WmCaptureCmd(tkwin, winPtr, interp, objc, objv);
      case WMOPT_RELEASE:
	return WmReleaseCmd(tkwin, winPtr, interp, objc, objv);
    }

    /* This should not happen */
    return TCL_ERROR;
}

/* ---------------------------------------------------------------
   Function that implements the wmCapture command 
    "Captures" a toplevel window and makes it a sub-window.
*/
static int
WmCaptureCmd(tkwin, winPtr, interp, objc, objv)
Tk_Window tkwin;		/* Main window of the application. */
TkWindow *winPtr;		/* Toplevel to work with */
Tcl_Interp *interp;		/* Current interpreter. */
int objc;			/* Number of arguments. */
Tcl_Obj *CONST objv[];		/* Argument objects. */
{

    if (winPtr->parentPtr == NULL) {
	Tcl_AppendResult(interp, "Cannot capture main window", NULL);
	return TCL_ERROR;
    }

    if ((winPtr->flags & TK_TOP_LEVEL) == 0) {
	/* Window is already captured */
	return TCL_OK;
    }
    /* Withdraw the window */
    TkpWmSetState(winPtr, WithdrawnState);
 
    if (winPtr->window == None) {
	/* cause this and parent window to exist */
	winPtr->atts.event_mask &= ~StructureNotifyMask;
	winPtr->flags &= ~TK_TOP_LEVEL;

	UnmanageGeometry((Tk_Window) winPtr);
	
	/* Can't delete the TopLevelEventProc, because this definition only exists
	    in tkWinWm or tkUnixWm.c 
	    Is having this event handler around really cause a problem?
	*/
	/* Tk_DeleteEventHandler((Tk_Window) winPtr, StructureNotifyMask,
			      TopLevelEventProc, (ClientData) winPtr);
	*/
    }
    else {
	unsigned long serial;
	XSetWindowAttributes atts;

	    

#ifdef WIN32
	/* SetParent must be done before TkWmDeadWindow or it's DestroyWindow on the 
	         parent Hwnd will also destroy the child */
	Tk_MakeWindowExist((Tk_Window) winPtr->parentPtr);
	SetParent(TkWinGetHWND(winPtr->window), TkWinGetHWND(winPtr->parentPtr->window)); 
	/* Dis-associate from wm */
	TkWmDeadWindow(winPtr);
#else
	TkWmDeadWindow(winPtr);
	XUnmapWindow(winPtr->display, winPtr->window);
	Tk_MakeWindowExist((Tk_Window) winPtr->parentPtr);
	XReparentWindow(winPtr->display, winPtr->window,
			    winPtr->parentPtr->window, 0, 0);
#endif /* WIN32 */


        /* clear those attributes that non-toplevel windows don't
	 * possess
	 */
	winPtr->flags &= ~(TK_TOP_HIERARCHY|TK_TOP_LEVEL|TK_HAS_WRAPPER|TK_WIN_MANAGED);
	atts.event_mask = winPtr->atts.event_mask;
	atts.event_mask &= ~StructureNotifyMask;
	Tk_ChangeWindowAttributes((Tk_Window) winPtr, CWEventMask, &atts);

	UnmanageGeometry((Tk_Window) winPtr);
        
	/* Get rid of the extra TopLevelEventProc that is attached to the window */
	/* Can't delete the TopLevelEventProc, because this definition only exists
	    in tkWinWm or tkUnixWm.c 
	    Is having this event handler around really cause a problem?
	*/
	/* Tk_DeleteEventHandler((Tk_Window) winPtr, StructureNotifyMask,
			      TopLevelEventProc, (ClientData) winPtr);
	*/
    }
    return TCL_OK;
}

/* ---------------------------------------------------------------
   Function that implements the wmCapture command 
    "Captures" a toplevel window and makes it a sub-window.
*/
static int
WmReleaseCmd(tkwin, winPtr, interp, objc, objv)
Tk_Window tkwin;		/* Main window of the application. */
TkWindow *winPtr;		/* Toplevel to work with */
Tcl_Interp *interp;		/* Current interpreter. */
int objc;			/* Number of arguments. */
Tcl_Obj *CONST objv[];		/* Argument objects. */
{


    if (Tk_IsTopLevel(winPtr)) {
	Tcl_AppendResult(interp, "Already a toplevel window", NULL);
	return TCL_ERROR;
    }
    

    /* detach the window from its gemoetry manager, if any */
    UnmanageGeometry((Tk_Window) winPtr);

    if (winPtr->window == None) {
	/* Good, the window is not created yet, we still have time
	 * to make it an legitimate toplevel window
	 */
	winPtr->dirtyAtts |= CWBorderPixel;
    }
    else {
	Window parent;

	if (winPtr->flags & TK_MAPPED) {
	    Tk_UnmapWindow((Tk_Window) winPtr);
	}

#ifdef WIN32	
	/* Reparent to NULL so UpdateWrapper won't delete our original parent window */
	SetParent(TkWinGetHWND(winPtr->window), NULL);
#else
	parent = XRootWindow(winPtr->display, winPtr->screenNum);
	XReparentWindow(winPtr->display, winPtr->window, parent, 0, 0);
#endif /* WIN32 */

	/* Should flush the events here */
    }

    winPtr->flags |= TK_TOP_HIERARCHY|TK_TOP_LEVEL|TK_HAS_WRAPPER|TK_WIN_MANAGED;

    TkWmNewWindow(winPtr);

    TkpWmSetState(winPtr, WithdrawnState);

    /* Size was set - force a call to Geometry Manager */
    winPtr->reqWidth++;
    winPtr->reqHeight++;
    Tk_GeometryRequest((Tk_Window) winPtr, winPtr->reqWidth - 1,
		       winPtr->reqHeight - 1);

    return TCL_OK;
}

/* Support Procedures for release and capture */
/*
 *----------------------------------------------------------------------
 *
 * UnmanageGeometry --
 *
 *	Since there is a bug in tkGeometry.c, we need this routine to
 *	replace Tk_ManageGeometry(tkwin, NULL, NULL);
 *
 * Results:
 *	None.
 *
 * Side effects:
 *	The window given by the clientData argument is mapped.
 *
 *----------------------------------------------------------------------
 */
static void UnmanageGeometry(tkwin)
    Tk_Window tkwin;		/* Window whose geometry is to
				 * be unmanaged.*/
{
    register TkWindow *winPtr = (TkWindow *) tkwin;

    if ((winPtr->geomMgrPtr != NULL) &&
	(winPtr->geomMgrPtr->lostSlaveProc != NULL)) {
	(*winPtr->geomMgrPtr->lostSlaveProc)(winPtr->geomData, tkwin);
    }

    winPtr->geomMgrPtr = NULL;
    winPtr->geomData = NULL;
}



