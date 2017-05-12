    /*
    ###########################################################################
    # (@)PACKAGE:Win32::GUI::Splitter
    #
    # $Id: Splitter.xs,v 1.6 2010/04/08 21:26:48 jwgui Exp $
    #
    ###########################################################################
    */

#include "GUI.h"

void 
Splitter_onPreCreate(NOTXSPROC LPPERLWIN32GUI_CREATESTRUCT perlcs) {

    perlcs->cs.lpszClass = "Win32::GUI::Splitter(vertical)";
    perlcs->cs.style = WS_VISIBLE | WS_CHILD;
    perlcs->cs.dwExStyle = WS_EX_NOPARENTNOTIFY;
}

BOOL
Splitter_onParseOption(NOTXSPROC char *option, SV* value, LPPERLWIN32GUI_CREATESTRUCT perlcs) {

    SV* storing;
    SV** stored;
    BOOL retval = TRUE;

    if(strcmp(option, "-horizontal") == 0) {
        if(SvIV(value)) {
            perlcs->cs.lpszClass = "Win32::GUI::Splitter(horizontal)";
        } else {
            perlcs->cs.lpszClass = "Win32::GUI::Splitter(vertical)";
        }
        SwitchBit(perlcs->dwPlStyle, PERLWIN32GUI_HORIZONTAL, SvIV(value));
    } else if(strcmp(option, "-min") == 0) {
        storing = newSViv((LONG) SvIV(value));
        stored = hv_store_mg(NOTXSCALL perlcs->hvSelf, "-min", 4, storing, 0);
        perlcs->iMinWidth = (int)SvIV(value);
    } else if(strcmp(option, "-max") == 0) {
        storing = newSViv((LONG) SvIV(value));
        stored = hv_store_mg(NOTXSCALL perlcs->hvSelf, "-max", 4, storing, 0);
        perlcs->iMaxWidth = (int)SvIV(value);
    } else if(strcmp(option, "-range") == 0) {
        if(SvROK(value) && SvTYPE(SvRV(value)) == SVt_PVAV) {
            SV** t;
            t = av_fetch((AV*)SvRV(value), 0, 0);
            if(t != NULL) {
                storing = newSViv((LONG) SvIV(*t));
                stored = hv_store_mg(NOTXSCALL perlcs->hvSelf, "-min", 4, storing, 0);
                perlcs->iMinWidth = (int)SvIV(*t);
            }
            t = av_fetch((AV*)SvRV(value), 1, 0);
            if(t != NULL) {
                storing = newSViv((LONG) SvIV(*t));
                stored = hv_store_mg(NOTXSCALL perlcs->hvSelf, "-max", 4, storing, 0);
                perlcs->iMaxWidth = (int)SvIV(*t);
            }
        } else {
            W32G_WARN("Win32::GUI: Argument to -range is not an array reference!");
        }
    } else retval = FALSE;

    return retval;
}

void 
Splitter_onPostCreate(NOTXSPROC HWND myhandle, LPPERLWIN32GUI_CREATESTRUCT perlcs) {
}

BOOL
Splitter_onParseEvent(NOTXSPROC char *name, int* eventID) {

    BOOL retval = TRUE;

    if Parse_Event("Release",   PERLWIN32GUI_NEM_CONTROL1)
    else retval = FALSE;

    return retval;
}

int
Splitter_onEvent (NOTXSPROC LPPERLWIN32GUI_USERDATA perlud, UINT uMsg, WPARAM wParam, LPARAM lParam) {

    int PerlResult = 0;
    POINT pt;
    HWND phwnd, hwnd;
    RECT rc;
    int w,h;

    BOOL tracking = perlud->dwPlStyle & PERLWIN32GUI_TRACKING;
    BOOL horizontal = perlud->dwPlStyle & PERLWIN32GUI_HORIZONTAL;

    switch(uMsg) {
    case WM_MOUSEMOVE:
        if(tracking) {
            hwnd  = handle_From (NOTXSCALL perlud->svSelf);
            phwnd = GetParent(hwnd);
            GetWindowRect(hwnd, &rc);
            w = rc.right - rc.left;
            h = rc.bottom - rc.top;
            ScreenToClient(phwnd, (POINT*)&rc);
            pt.x = GET_X_LPARAM(lParam);
            pt.y = GET_Y_LPARAM(lParam);
	    MapWindowPoints(hwnd, phwnd, (LPPOINT)&pt, 1);

            if(horizontal) {
                DrawSplitter(NOTXSCALL phwnd, rc.left, (int)perlud->dwData, w, h);
                pt.y = AdjustSplitterCoord(NOTXSCALL perlud, pt.y, h, phwnd);
	        perlud->dwData = (IV)(pt.y);
                DrawSplitter(NOTXSCALL phwnd, rc.left, pt.y, w, h);
            } else {
                DrawSplitter(NOTXSCALL phwnd, (int)perlud->dwData, rc.top, w, h);
                pt.x = AdjustSplitterCoord(NOTXSCALL perlud, pt.x, w, phwnd);
	        perlud->dwData = (IV)(pt.x);
                DrawSplitter(NOTXSCALL phwnd, pt.x, rc.top, w, h);
            }
        }
        break;
    case WM_LBUTTONDOWN:
        hwnd  = handle_From (NOTXSCALL perlud->svSelf);
        phwnd = GetParent(hwnd);
        GetWindowRect(hwnd, &rc);
        w = rc.right - rc.left;
        h = rc.bottom - rc.top;
        ScreenToClient(phwnd, (POINT*)&rc);
        pt.x = GET_X_LPARAM(lParam);
        pt.y = GET_Y_LPARAM(lParam);
        MapWindowPoints(hwnd, phwnd, (LPPOINT)&pt, 1);

        if(horizontal) {
            pt.y = AdjustSplitterCoord(NOTXSCALL perlud, pt.y, h, phwnd);
	    perlud->dwData = (IV)(rc.top);
            DrawSplitter(NOTXSCALL phwnd, rc.left, rc.top, w, h);
        } else {
            pt.x = AdjustSplitterCoord(NOTXSCALL perlud, pt.x, w, phwnd);
	    perlud->dwData = (IV)(rc.left);
            DrawSplitter(NOTXSCALL phwnd, rc.left, rc.top, w, h);
        }
        SwitchBit(perlud->dwPlStyle, PERLWIN32GUI_TRACKING, 1);        
        SetCapture(hwnd);
        break;
    case WM_LBUTTONUP:
        if(tracking) {
            ReleaseCapture();  // Sends us a WM_CAPTURECHANGED message
            hwnd  = handle_From (NOTXSCALL perlud->svSelf);
            phwnd = GetParent(hwnd);
            GetWindowRect(hwnd, &rc);
            w = rc.right - rc.left;
            h = rc.bottom - rc.top;
            ScreenToClient(phwnd, (POINT*)&rc);

            if(horizontal) {
                MoveWindow(hwnd, rc.left, (int)perlud->dwData, w, h, 1);
            } else {
                MoveWindow(hwnd, (int)perlud->dwData, rc.top, w, h, 1);
            }

            /*
            * (@)EVENT:Release(COORD)
            * Sent when the Splitter is released after being
            * dragged to a new location (identified by the
            * COORD parameter). COORD is the top coordinate
	    * of a horizontal splitter or the left coordinate
	    * of a vertical splitter.
            * (@)APPLIES_TO:Splitter
            */
            PerlResult = DoEvent(NOTXSCALL perlud, PERLWIN32GUI_NEM_CONTROL1, "Release",
                                 PERLWIN32GUI_ARGTYPE_LONG, perlud->dwData,
                                 -1);

        }
        break;
    case WM_CAPTURECHANGED:
        if(tracking) {
            hwnd  = handle_From (NOTXSCALL perlud->svSelf);
            phwnd = GetParent(hwnd);
            GetWindowRect(hwnd, &rc);
            w = rc.right - rc.left;
            h = rc.bottom - rc.top;
            ScreenToClient(phwnd, (POINT*)&rc);
            SwitchBit(perlud->dwPlStyle, PERLWIN32GUI_TRACKING, 0);

            if(horizontal) {
                DrawSplitter(NOTXSCALL phwnd, rc.left, (int)perlud->dwData, w, h);
            } else {
                DrawSplitter(NOTXSCALL phwnd, (int)perlud->dwData, rc.top, w, h);
            }
        }
        break;

    default :
        PerlResult = 1;
    }

    return PerlResult;
}

MODULE = Win32::GUI::Splitter       PACKAGE = Win32::GUI::Splitter

PROTOTYPES: DISABLE

#pragma message( "*** PACKAGE Win32::GUI::Splitter..." )

    ###########################################################################
    # (@)METHOD:Min([VALUE])
    # Get or Set Min value. The min value is the minimum position
    # to which the left(top) of the splitter can be dragged, in
    # the parent window for a horizontal(vertical) splitter.

void
Min(handle,...)
    HWND handle
PREINIT:
    LPPERLWIN32GUI_USERDATA perlud;
PPCODE:
    if(items > 2) {
        CROAK("Usage: Min(handle, [value]);\n");
    }
    perlud = (LPPERLWIN32GUI_USERDATA) GetWindowLongPtr(handle, GWLP_USERDATA);
    if( ValidUserData(perlud) ) {
        if(items == 1) {
            XSRETURN_IV(perlud->iMinWidth);
        } else {
            perlud->iMinWidth = (int)SvIV(ST(1));
            XSRETURN_YES;
        }
    } else {
        XSRETURN_UNDEF;
    }

    ###########################################################################
    # (@)METHOD:Max([VALUE])
    # Get or Set Max value. The max value is the maximum position
    # to which the left(top) of the splitter can be dragged, in
    # the parent window for a horizontal(vertical) splitter.

void
Max(handle,...)
    HWND handle
PREINIT:
    LPPERLWIN32GUI_USERDATA perlud;
PPCODE:
    if(items > 2) {
        CROAK("Usage: Max(handle, [value]);\n");
    }
    perlud = (LPPERLWIN32GUI_USERDATA) GetWindowLongPtr(handle, GWLP_USERDATA);
    if( ValidUserData(perlud) ) {
        if(items == 1) {
            XSRETURN_IV(perlud->iMaxWidth);
        } else {
            perlud->iMaxWidth = (int)SvIV(ST(1));
            XSRETURN_YES;
        }
    } else {
        XSRETURN_UNDEF;
    }

    ###########################################################################
    # (@)METHOD:Horizontal([VALUE])
    # Get or Set Horizontal orientation.  If value is true, then sets
    # the splitter orientation to horizontal.  If value is false, then
    # sets the splitter to Vertical orintation.

void
Horizontal(handle,...)
    HWND handle
PREINIT:
    LPPERLWIN32GUI_USERDATA perlud;
PPCODE:
    if(items > 2) {
        CROAK("Usage: Horizontal(handle, [value]);\n");
    }
    perlud = (LPPERLWIN32GUI_USERDATA) GetWindowLongPtr(handle, GWLP_USERDATA);
    if( ValidUserData(perlud) ) {
        if(items == 1) {
            XSRETURN_IV(perlud->dwPlStyle & PERLWIN32GUI_HORIZONTAL);
        } else {
            SwitchBit(perlud->dwPlStyle, PERLWIN32GUI_HORIZONTAL, SvIV(ST(1)));
            SetWindowLongPtr(handle, GWLP_USERDATA, (LONG_PTR) perlud);
            XSRETURN_YES;
        }
    } else {
        XSRETURN_UNDEF;
    }
    ###########################################################################
    # (@)METHOD:Vertical([VALUE])
    # Get or Set Vertical orientation.  If value is true, then sets
    # the splitter orientation to vertuical.  If value is false, then
    # sets the splitter to horizontal orintation.

void
Vertical(handle,...)
    HWND handle
PREINIT:
    LPPERLWIN32GUI_USERDATA perlud;
PPCODE:
    if(items > 2) {
        CROAK("Usage: Vertical(handle, [value]);\n");
    }
    perlud = (LPPERLWIN32GUI_USERDATA) GetWindowLongPtr(handle, GWLP_USERDATA);
    if( ValidUserData(perlud) ) {
        if(items == 1) {
            XSRETURN_IV(!(perlud->dwPlStyle & PERLWIN32GUI_HORIZONTAL));
        } else {
            SwitchBit(perlud->dwPlStyle, PERLWIN32GUI_HORIZONTAL, !SvIV(ST(1)));
            SetWindowLongPtr(handle, GWLP_USERDATA, (LONG_PTR) perlud);
            XSRETURN_YES;
        }
    } else {
        XSRETURN_UNDEF;
    }
