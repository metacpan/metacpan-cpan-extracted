    /*
    ###########################################################################
    # Win32::GUI Mutiple Document Interface
    #
    # $Id: MDI.xs,v 1.4 2010/04/08 21:26:48 jwgui Exp $
    #
    ###########################################################################
    */

#include "GUI.h"

    /*
    ###########################################################################
    # (@)PACKAGE:Win32::GUI::MDIFrame
    ###########################################################################
    */

void 
MDIFrame_onPreCreate(NOTXSPROC LPPERLWIN32GUI_CREATESTRUCT perlcs) {

    perlcs->cs.lpszClass = "PerlWin32GUI_MDIFrame";
    perlcs->cs.style     = WS_OVERLAPPEDWINDOW | WS_CLIPCHILDREN;
    perlcs->dwPlStyle    = PERLWIN32GUI_MDIFRAME;
}

BOOL
MDIFrame_onParseOption(NOTXSPROC char *option, SV* value, LPPERLWIN32GUI_CREATESTRUCT perlcs) {

    return Window_onParseOption(NOTXSCALL option, value, perlcs);
}

void 
MDIFrame_onPostCreate(NOTXSPROC HWND myhandle, LPPERLWIN32GUI_CREATESTRUCT perlcs) {

    Window_onPostCreate(NOTXSCALL myhandle, perlcs);
}

BOOL
MDIFrame_onParseEvent(NOTXSPROC char *name, int* eventID) {

    return Window_onParseEvent(NOTXSCALL name, eventID);
}

int  
MDIFrame_onEvent (NOTXSPROC LPPERLWIN32GUI_USERDATA perlud, UINT uMsg, WPARAM wParam, LPARAM lParam) {

    return Window_onEvent (NOTXSCALL perlud, uMsg, wParam, lParam);
}

    /*
    ###########################################################################
    # (@)PACKAGE:Win32::GUI::MDIClient
    ###########################################################################
    */

void
MDIClient_onPreCreate(NOTXSPROC LPPERLWIN32GUI_CREATESTRUCT perlcs) {

    static CLIENTCREATESTRUCT ccs;

    perlcs->cs.lpszClass = "MDICLIENT";
    perlcs->cs.style = WS_VISIBLE | WS_CHILD | WS_CLIPCHILDREN | WS_VSCROLL | WS_HSCROLL;
  
    perlcs->cs.lpCreateParams = &ccs;
    ccs.idFirstChild = 5000;
    ccs.hWindowMenu  = 0;
}

BOOL
MDIClient_onParseOption(NOTXSPROC char *option, SV* value, LPPERLWIN32GUI_CREATESTRUCT perlcs) {

    BOOL retval = TRUE;

    if(perlcs->cs.lpCreateParams != NULL) {
        LPCLIENTCREATESTRUCT ccs = (LPCLIENTCREATESTRUCT) perlcs->cs.lpCreateParams;

        if(strcmp(option, "-firstchild") == 0) {
            ccs->idFirstChild = (UINT)SvIV(value);
        } else if(strcmp(option, "-windowmenu") == 0) {
            ccs->hWindowMenu = handle_From(NOTXSCALL value);
        } else retval = FALSE;
    } else retval = FALSE;

    return retval;
}

void
MDIClient_onPostCreate(NOTXSPROC HWND myhandle, LPPERLWIN32GUI_CREATESTRUCT perlcs) {

    // Register Client handler into parent data
    if (perlcs->hvParent != NULL) {
        LPPERLWIN32GUI_USERDATA parentud;
        parentud = (LPPERLWIN32GUI_USERDATA) GetWindowLongPtr(perlcs->cs.hwndParent, GWLP_USERDATA);

        if (parentud->dwPlStyle & PERLWIN32GUI_MDIFRAME &&
            !(parentud->dwPlStyle & PERLWIN32GUI_HAVECHILDWINDOW)) {
            parentud->dwPlStyle |= PERLWIN32GUI_HAVECHILDWINDOW;
            parentud->dwData = PTR2IV(myhandle);
        }
    }
}

BOOL
MDIClient_onParseEvent(NOTXSPROC char *name, int* eventID) {
    return FALSE;
}

int
MDIClient_onEvent (NOTXSPROC LPPERLWIN32GUI_USERDATA perlud, UINT uMsg, WPARAM wParam, LPARAM lParam) {
    return 1;
}

    /*
    ###########################################################################
    # (@)PACKAGE:Win32::GUI::MDIChild
    ###########################################################################
    */

void 
MDIChild_onPreCreate(NOTXSPROC LPPERLWIN32GUI_CREATESTRUCT perlcs) {

    perlcs->cs.lpszClass = "PerlWin32GUI_MDIChild";
    perlcs->cs.lpszName  = "Untitled";
    perlcs->cs.style     = WS_CHILD | WS_VISIBLE | WS_CLIPCHILDREN | WS_CLIPSIBLINGS;
    perlcs->cs.dwExStyle = WS_EX_MDICHILD;
    perlcs->cs.x         = CW_USEDEFAULT;
    perlcs->cs.y         = CW_USEDEFAULT;
    perlcs->cs.cx        = CW_USEDEFAULT;
    perlcs->cs.cy        = CW_USEDEFAULT;
    perlcs->dwPlStyle    = PERLWIN32GUI_MDICHILD; 
}

BOOL
MDIChild_onParseOption(NOTXSPROC char *option, SV* value, LPPERLWIN32GUI_CREATESTRUCT perlcs) {

    return Window_onParseOption(NOTXSCALL option, value, perlcs);
}

void 
MDIChild_onPostCreate(NOTXSPROC HWND myhandle, LPPERLWIN32GUI_CREATESTRUCT perlcs) {

    Window_onPostCreate(NOTXSCALL myhandle, perlcs);
}

BOOL
MDIChild_onParseEvent(NOTXSPROC char *name, int* eventID) {

    BOOL retval = TRUE;

         if Parse_Event("Deactivate", PERLWIN32GUI_NEM_CONTROL1)
    else if Parse_Event("Activate",   PERLWIN32GUI_NEM_CONTROL2)
    else if Parse_Event("Terminate",  PERLWIN32GUI_NEM_CONTROL3)
    else if Parse_Event("Minimize",   PERLWIN32GUI_NEM_CONTROL4)
    else if Parse_Event("Maximize",   PERLWIN32GUI_NEM_CONTROL5)
    else if Parse_Event("Resize",     PERLWIN32GUI_NEM_CONTROL6)
    else if Parse_Event("Scroll",     PERLWIN32GUI_NEM_CONTROL7)
    else if Parse_Event("GotFocus",   PERLWIN32GUI_NEM_GOTFOCUS)
    else retval = FALSE;

    return retval;
}

int  
MDIChild_onEvent (NOTXSPROC LPPERLWIN32GUI_USERDATA perlud, UINT uMsg, WPARAM wParam, LPARAM lParam) {

    int PerlResult = 1;

    switch (uMsg) {

    case WM_MDIACTIVATE :

        if( perlud->dwData == PTR2IV(wParam) ) {
            /*
             * (@)EVENT:Deactivate()
             * Sent when the window is deactivated.
             * (@)APPLIES_TO:MDIChild
             */  
            PerlResult = DoEvent(NOTXSCALL perlud, PERLWIN32GUI_NEM_CONTROL1, "Deactivate", -1 );
        } else {
            /*
             * (@)EVENT:Activate()
             * Sent when the window is activated.
             * (@)APPLIES_TO:MDIChild
             */ 
            PerlResult = DoEvent(NOTXSCALL perlud, PERLWIN32GUI_NEM_CONTROL2, "Activate", -1 );
        }        
        break;

    case WM_SETFOCUS:

        PerlResult = DoEvent(NOTXSCALL perlud, PERLWIN32GUI_NEM_GOTFOCUS, "GotFocus", -1 );
        // Force SetFocus on first child if not handle
        if ( !(perlud->dwPlStyle & PERLWIN32GUI_EVENTHANDLING) ) {
            HWND child = GetWindow(INT2PTR(HWND, perlud->dwData), GW_CHILD);
            if (child) {
                SetFocus(child);
            }
        }
        PerlResult = 1; // Always go to default child procedure
        break;

    case WM_SYSCOMMAND:

        switch(wParam & 0xFFF0) {
        case SC_CLOSE:
            /*
             * (@)EVENT:Terminate()
             * Sent when the window is closed.
             * The event should return -1 to terminate the interaction
             * and return control to the perl script; see Dialog().
             * (@)APPLIES_TO:Window, DialogBox
             */
            PerlResult = DoEvent(NOTXSCALL perlud, PERLWIN32GUI_NEM_CONTROL3, "Terminate", -1 );
            break;
        case SC_MINIMIZE:
            /*
             * (@)EVENT:Minimize()
             * Sent when the window is minimized.
             * (@)APPLIES_TO:Window, DialogBox
             */ 
            PerlResult = DoEvent(NOTXSCALL perlud, PERLWIN32GUI_NEM_CONTROL4, "Minimize", -1 );
            break;
        case SC_MAXIMIZE:
            /*
             * (@)EVENT:Maximize()
             * Sent when the window is maximized.
             * (@)APPLIES_TO:Window, DialogBox
             */
            PerlResult = DoEvent(NOTXSCALL perlud, PERLWIN32GUI_NEM_CONTROL5, "Maximize", -1 );
            PerlResult = 1; // Always go to default child procedure
            break;
        }
        break;

    case WM_SIZE:

        /*
         * (@)EVENT:Resize()
         * Sent when the window is resized.
         * (@)APPLIES_TO:Window, DialogBox
         */
        PerlResult = DoEvent(NOTXSCALL perlud, PERLWIN32GUI_NEM_CONTROL6, "Resize", -1 );
        PerlResult = 1; // Always go to default child procedure
        break;

    case WM_HSCROLL:
    case WM_VSCROLL:

        /*
         * (@)EVENT:Scroll(SCROLLBAR, OPERATION, POSITION)
         * Sent when one of the window scrollbars is moved. SCROLLBAR identifies
         * which bar was moved, 0 for horizontal and 1 for vertical.
         *
         * OPERATION can be compared against one of the following constants:
         * SB_LINEUP, SB_LINELEFT, SB_LINEDOWN, SB_LINERIGHT, SB_PAGEUP
         * SB_PAGELEFT, SB_PAGEDOWN, SB_PAGERIGHT, SB_THUMBPOSITION,
         * SB_THUMBTRACK, SB_TOP, SB_LEFT, SB_BOTTOM, SB_RIGHT, SB_ENDSCROLL
         *
         * Related messages: WM_HSCROLL, WM_VSCROLL
         * (@)APPLIES_TO:Window, DialogBox
         */
        PerlResult = DoEvent(NOTXSCALL perlud, PERLWIN32GUI_NEM_CONTROL7, "Scroll",
                             PERLWIN32GUI_ARGTYPE_INT, (uMsg == WM_HSCROLL ? 0 : 1),
                             PERLWIN32GUI_ARGTYPE_INT, (int) LOWORD(wParam),
                             PERLWIN32GUI_ARGTYPE_INT, (int) HIWORD(wParam), -1 );
        break;
    }

    return PerlResult;
}

MODULE = Win32::GUI::MDI     PACKAGE = Win32::GUI::MDIFrame

PROTOTYPES: DISABLE

    ###########################################################################
    # (@)PACKAGE:Win32::GUI::MDIFrame
    ###########################################################################

#pragma message( "*** PACKAGE Win32::GUI::MDIFrame..." )

    ###########################################################################
    # (@)PACKAGE:Win32::GUI::MDIClient
    ###########################################################################

#pragma message( "*** PACKAGE Win32::GUI::MDIClient..." )

MODULE = Win32::GUI::MDI     PACKAGE = Win32::GUI::MDIClient

    ###########################################################################
    # (@)METHOD:Activate(MDICHILD)
    # Activate a MDI child window.
LRESULT
Activate(handle, child)
    HWND handle
    HWND child
CODE:
    RETVAL = SendMessage(handle, WM_MDIACTIVATE, (WPARAM) child, 0);
OUTPUT:
    RETVAL

    ###########################################################################
    # (@)METHOD:Cascade([FLAG=MDITILE_SKIPDISABLED])
    # Arrange all its child windows in a cascade format.
LRESULT
Cascade(handle, flag=MDITILE_SKIPDISABLED)
    HWND handle
    UINT flag
CODE:
    RETVAL = SendMessage(handle, WM_MDICASCADE, (WPARAM) flag, 0);
OUTPUT:
    RETVAL

    ###########################################################################
    # (@)METHOD:Close(MDICHILD)
    # Close an MDI child window
LRESULT
Close(handle, child)
    HWND handle
    HWND child
CODE:
    RETVAL = SendMessage(handle, WM_MDIDESTROY, (WPARAM) child, 0);
OUTPUT:
    RETVAL

    ###########################################################################
    # (@)METHOD:GetActive()
    # Return handle to active child
HWND
GetActive(handle)
    HWND handle
CODE:
    RETVAL = (HWND) SendMessage(handle, WM_MDIGETACTIVE, 0, 0);
OUTPUT:
    RETVAL

    ###########################################################################
    # (@)METHOD:IconArrange()
    # Arrange all minimized MDI child windows. It does not affect child windows that are not minimized. 
LRESULT
IconArrange(handle, child)
    HWND handle
CODE:
    RETVAL = SendMessage(handle, WM_MDIICONARRANGE, 0, 0);
OUTPUT:
    RETVAL

    ###########################################################################
    # (@)METHOD:Maximize(MDICHILD)
    # Maximize an MDI child window
LRESULT
Maximize(handle, child)
    HWND handle
    HWND child
CODE:
    RETVAL = SendMessage(handle, WM_MDIMAXIMIZE, (WPARAM) child, 0);
OUTPUT:
    RETVAL

    ###########################################################################
    # (@)METHOD:Next([MDICHILD])
    # Activate the next child window. 
LRESULT
Next(handle, child=(HWND)NULL)
    HWND handle
    HWND child
CODE:
    RETVAL = SendMessage(handle, WM_MDINEXT, (WPARAM) child, 0);
OUTPUT:
    RETVAL

    ###########################################################################
    # (@)METHOD:Previous([MDICHILD])
    # Activate the previous child window.
LRESULT
Previous(handle, child=(HWND)NULL)
    HWND handle
    HWND child
CODE:
    RETVAL = SendMessage(handle, WM_MDINEXT, (WPARAM) child, 1);
OUTPUT:
    RETVAL

    ###########################################################################
    # (@)METHOD:RefreshMenu()
    # Activate the previous child window.
BOOL
RefreshMenu(handle)
    HWND handle
PREINIT:
    HWND frame;
CODE:
    frame = (HWND) SendMessage(handle, WM_MDIREFRESHMENU, 0, 0);
    if (frame != NULL)
        RETVAL = DrawMenuBar(frame);
    else
        RETVAL = FALSE;
OUTPUT:
    RETVAL

    ###########################################################################
    # (@)METHOD:Restore(MDICHILD)
    # Restore a child window.
LRESULT
Restore(handle, child)
    HWND handle
    HWND child
CODE:
    RETVAL = SendMessage(handle, WM_MDIRESTORE, (WPARAM) child, 0);
OUTPUT:
    RETVAL

    # TODO : WM_MDISETMENU

    ###########################################################################
    # (@)METHOD:Tile([FLAG=MDITILE_HORIZONTAL])
    # Tiled child windows.
    #
    # B<FLAG> :
    #  MDITILE_VERTICAL     0 Tiles MDI child windows so that they are tall rather than wide.
    #  MDITILE_HORIZONTAL   1 Tiles MDI child windows so that they are wide rather than tall.
    #  MDITILE_SKIPDISABLED 2 Prevents disabled MDI child windows from being tiled.
LRESULT
Tile(handle, flag=MDITILE_HORIZONTAL)
    HWND handle
    UINT flag
CODE:
    RETVAL = SendMessage(handle, WM_MDITILE, (WPARAM) flag, 0);
OUTPUT:
    RETVAL

    ###########################################################################
    # (@)PACKAGE:Win32::GUI::MDIChild
    ###########################################################################

#pragma message( "*** PACKAGE Win32::GUI::MDIChild..." )

MODULE = Win32::GUI::MDI     PACKAGE = Win32::GUI::MDIChild
