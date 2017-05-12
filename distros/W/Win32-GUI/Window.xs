    /*
    ###########################################################################
    # (@)PACKAGE:Win32::GUI::Window
    #
    # $Id: Window.xs,v 1.13 2010/04/08 21:26:48 jwgui Exp $
    #
    ###########################################################################
    */

#include "GUI.h"

void 
Window_onPreCreate(NOTXSPROC LPPERLWIN32GUI_CREATESTRUCT perlcs) {

    perlcs->cs.lpszClass = "PerlWin32GUI_STD";
    perlcs->cs.style = WS_OVERLAPPEDWINDOW;
}

BOOL
Window_onParseOption(NOTXSPROC char *option, SV* value, LPPERLWIN32GUI_CREATESTRUCT perlcs) {

    BOOL retval = TRUE;
    SV** stored;
    SV* storing;

    if(strcmp(option, "-minsize") == 0) {
        if(SvROK(value) && SvTYPE(SvRV(value)) == SVt_PVAV) {
            SV** t;
            t = av_fetch((AV*)SvRV(value), 0, 0);
            if(t != NULL) {
                perlcs->iMinWidth = (int) SvIV(*t);
                storing = newSViv((LONG) SvIV(*t));
                stored = hv_store_mg(NOTXSCALL perlcs->hvSelf, "-minwidth", 9, storing, 0);
            }
            t = av_fetch((AV*)SvRV(value), 1, 0);
            if(t != NULL) {
                perlcs->iMinHeight = (int) SvIV(*t);
                storing = newSViv((LONG) SvIV(*t));
                stored = hv_store_mg(NOTXSCALL perlcs->hvSelf, "-minheight", 10, storing, 0);
            }
        } else {
            W32G_WARN("Win32::GUI: Argument to -minsize is not an array reference!");
        }
    } else if(strcmp(option, "-maxsize") == 0) {
        if(SvROK(value) && SvTYPE(SvRV(value)) == SVt_PVAV) {
            SV** t;
            t = av_fetch((AV*)SvRV(value), 0, 0);
            if(t != NULL) {
                perlcs->iMaxWidth = (int) SvIV(*t);
                storing = newSViv((LONG) SvIV(*t));
                stored = hv_store_mg(NOTXSCALL perlcs->hvSelf, "-maxwidth", 9, storing, 0);
            }
            t = av_fetch((AV*)SvRV(value), 1, 0);
            if(t != NULL) {
                perlcs->iMaxHeight = (int) SvIV(*t);
                storing = newSViv((LONG) SvIV(*t));
                stored = hv_store_mg(NOTXSCALL perlcs->hvSelf, "-maxheight", 10, storing, 0);
            }
        } else {
            W32G_WARN("Win32::GUI: Argument to -maxsize is not an array reference!");
        }
    } else if(strcmp(option, "-minwidth") == 0) {
        perlcs->iMinWidth = (int) SvIV(value);
        storing = newSViv((LONG) SvIV(value));
        stored = hv_store_mg(NOTXSCALL perlcs->hvSelf, "-minwidth", 9, storing, 0);
    } else if(strcmp(option, "-minheight") == 0) {
        perlcs->iMinHeight = (int) SvIV(value);
        storing = newSViv((LONG) SvIV(value));
        stored = hv_store_mg(NOTXSCALL perlcs->hvSelf, "-minheight", 10, storing, 0);
    } else if(strcmp(option, "-maxwidth") == 0) {
        perlcs->iMaxWidth = (int) SvIV(value);
        storing = newSViv((LONG) SvIV(value));
        stored = hv_store_mg(NOTXSCALL perlcs->hvSelf, "-maxwidth", 9, storing, 0);
    } else if(strcmp(option, "-maxheight") == 0) {
        perlcs->iMaxHeight = (int) SvIV(value);
        storing = newSViv((LONG) SvIV(value));
        stored = hv_store_mg(NOTXSCALL perlcs->hvSelf, "-maxheight", 10, storing, 0);
    } else if(strcmp(option, "-accel") == 0
    ||        strcmp(option, "-accelerators") == 0
    ||        strcmp(option, "-acceleratortable") == 0) {
        perlcs->hAcc = (HACCEL) handle_From(NOTXSCALL value);
        storing = newSViv(PTR2IV(handle_From(NOTXSCALL value)));
        stored = hv_store_mg(NOTXSCALL perlcs->hvSelf, "-accel", 6, storing, 0);
    } else if(strcmp(option, "-hasmaximize") == 0
    ||        strcmp(option, "-maximizebox") == 0) {
        SwitchBit(perlcs->cs.style, WS_MAXIMIZEBOX, SvIV(value));
    } else if(strcmp(option, "-hasminimize") == 0
    ||        strcmp(option, "-minimizebox") == 0) {
        SwitchBit(perlcs->cs.style, WS_MINIMIZEBOX, SvIV(value));
    } else if(strcmp(option, "-sizable") == 0
    ||        strcmp(option, "-resizable") == 0) {
        SwitchBit(perlcs->cs.style, WS_THICKFRAME, SvIV(value));
    } else if(strcmp(option, "-sysmenu") == 0
    ||        strcmp(option, "-menubox") == 0
    ||        strcmp(option, "-controlbox") == 0) {
        SwitchBit(perlcs->cs.style, WS_SYSMENU, SvIV(value));
    } else if(strcmp(option, "-helpbutton") == 0
    ||        strcmp(option, "-helpbox") == 0
    ||        strcmp(option, "-hashelp") == 0) {
        SwitchBit(perlcs->cs.dwExStyle, WS_EX_CONTEXTHELP, SvIV(value));
    } else if BitmaskOptionValue("-titlebar",      perlcs->cs.style,     WS_CAPTION)
    } else if BitmaskOptionValue("-toolwindow",    perlcs->cs.dwExStyle, WS_EX_TOOLWINDOW)
    } else if BitmaskOptionValue("-appwindow",     perlcs->cs.dwExStyle, WS_EX_APPWINDOW)
    } else if BitmaskOptionValue("-topmost",       perlcs->cs.dwExStyle, WS_EX_TOPMOST)
    } else if BitmaskOptionValue("-controlparent", perlcs->cs.dwExStyle, WS_EX_CONTROLPARENT)
    } else if BitmaskOptionValue("-noflicker",     perlcs->dwPlStyle,    PERLWIN32GUI_FLICKERFREE)
    } else if BitmaskOptionValue("-dialogui",      perlcs->dwPlStyle,    PERLWIN32GUI_DIALOGUI)
    } else retval = FALSE;

    return retval;
}

void 
Window_onPostCreate(NOTXSPROC HWND myhandle, LPPERLWIN32GUI_CREATESTRUCT perlcs) {
}

BOOL
Window_onParseEvent(NOTXSPROC char *name, int* eventID) {

    BOOL retval = TRUE;

         if Parse_Event("Deactivate", PERLWIN32GUI_NEM_CONTROL1)
    else if Parse_Event("Activate",   PERLWIN32GUI_NEM_CONTROL2)
    else if Parse_Event("Terminate",  PERLWIN32GUI_NEM_CONTROL3)
    else if Parse_Event("Minimize",   PERLWIN32GUI_NEM_CONTROL4)
    else if Parse_Event("Maximize",   PERLWIN32GUI_NEM_CONTROL5)
    else if Parse_Event("Resize",     PERLWIN32GUI_NEM_CONTROL6)
    else if Parse_Event("Scroll",     PERLWIN32GUI_NEM_CONTROL7)
    else if Parse_Event("InitMenu",   PERLWIN32GUI_NEM_CONTROL8)
    else if Parse_Event("Paint",      PERLWIN32GUI_NEM_PAINT)
    else retval = FALSE;

    return retval;
}

int
Window_onEvent (NOTXSPROC LPPERLWIN32GUI_USERDATA perlud, UINT uMsg, WPARAM wParam, LPARAM lParam) {

    int PerlResult = 1;

    switch (uMsg) {

    case WM_PAINT:

       /*
        * (@)EVENT:Paint(DC)
        * Sent when the window needs to be repainted.
        *
        * Note that you get the DC of the window object in parameter, 
        * and then Validate() the DC to inform Windows
        * that you painted the DC area (otherwise it will
        * continue to call the Paint event continuously).
        * Example:
        *   sub Graphic_Paint {
        *       my $DC = shift;
        *       $DC->MoveTo(0, 0);
        *       $DC->LineTo(100, 100);
        *       $DC->Validate();
        *   }
        *
        * (@)APPLIES_TO:Window, DialogBox, MDIFrame
        */

      PerlResult = DoEvent_Paint(NOTXSCALL perlud); 
      break;

    case WM_ACTIVATE :

        if(LOWORD(wParam) == WA_INACTIVE) {
            /*
             * (@)EVENT:Deactivate()
             * Sent when the window is deactivated.
             * (@)APPLIES_TO:Window, DialogBox, MDIFrame
             */  
            PerlResult = DoEvent(NOTXSCALL perlud, PERLWIN32GUI_NEM_CONTROL1, "Deactivate", -1 );
        } else {
            /*
             * (@)EVENT:Activate()
             * Sent when the window is activated.
             * (@)APPLIES_TO:Window, DialogBox, MDIFrame
             */ 
            PerlResult = DoEvent(NOTXSCALL perlud, PERLWIN32GUI_NEM_CONTROL2, "Activate", -1 );
        }
        break;

    case WM_SYSCOMMAND:

        switch(wParam & 0xFFF0) {
        case SC_CLOSE:
            /*
             * (@)EVENT:Terminate()
             * Sent when the window is closed.
             * The event should return -1 to terminate the interaction
             * and return control to the perl script; see Dialog().
             * (@)APPLIES_TO:Window, DialogBox, MDIFrame
             */
            PerlResult = DoEvent(NOTXSCALL perlud, PERLWIN32GUI_NEM_CONTROL3, "Terminate", -1 );

            // Force Quit if event isn't handle
            if ( !(perlud->dwPlStyle & PERLWIN32GUI_EVENTHANDLING) ) {
                PerlResult = -1; // Quit
            }

            break;
        case SC_MINIMIZE:
            /*
             * (@)EVENT:Minimize()
             * Sent when the window is minimized.
             * (@)APPLIES_TO:Window, DialogBox, MDIFrame
             */ 
            PerlResult = DoEvent(NOTXSCALL perlud, PERLWIN32GUI_NEM_CONTROL4, "Minimize", -1 );
            break;
        case SC_MAXIMIZE:
            /*
             * (@)EVENT:Maximize()
             * Sent when the window is maximized.
             * (@)APPLIES_TO:Window, DialogBox, MDIFrame
             */
            PerlResult = DoEvent(NOTXSCALL perlud, PERLWIN32GUI_NEM_CONTROL5, "Maximize", -1 );
            break;
        }
        break;

    case WM_SIZE:

        /*
         * (@)EVENT:Resize()
         * Sent when the window is resized.
         * (@)APPLIES_TO:Window, DialogBox, MDIFrame
         */
        PerlResult = DoEvent(NOTXSCALL perlud, PERLWIN32GUI_NEM_CONTROL6, "Resize", -1 );
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
         * (@)APPLIES_TO:Window, DialogBox, MDIFrame
         */
        PerlResult = DoEvent(NOTXSCALL perlud, PERLWIN32GUI_NEM_CONTROL7, "Scroll",
                             PERLWIN32GUI_ARGTYPE_INT, (uMsg == WM_HSCROLL ? 0 : 1),
                             PERLWIN32GUI_ARGTYPE_INT, (int) LOWORD(wParam),
                             PERLWIN32GUI_ARGTYPE_INT, (int) HIWORD(wParam), -1 );
        break;

    case WM_INITMENU :

        /*
         * (@)EVENT:InitMenu(MENU)
         * Sent when a menu is about to become active. It occurs when the user clicks
         * an item on the menu bar or presses a menu key. This allows the application
         * to modify the menu before it is displayed. 
         * (@)APPLIES_TO:Window, DialogBox, MDIFrame
         */
        PerlResult = DoEvent(NOTXSCALL perlud, PERLWIN32GUI_NEM_CONTROL8, "InitMenu",
                             PERLWIN32GUI_ARGTYPE_INT, (int) wParam,
                             -1 );
        break;
    }

    return PerlResult;
}

    /*
    ###########################################################################
    # (@)PACKAGE:Win32::GUI::DialogBox
    ###########################################################################
    */

void 
DialogBox_onPreCreate(NOTXSPROC LPPERLWIN32GUI_CREATESTRUCT perlcs) {

    perlcs->cs.lpszClass = "PerlWin32GUI_STD";
    perlcs->cs.style = WS_BORDER | DS_MODALFRAME | WS_POPUP | WS_CAPTION | WS_SYSMENU;
    perlcs->cs.dwExStyle = WS_EX_DLGMODALFRAME | WS_EX_WINDOWEDGE | WS_EX_CONTEXTHELP | WS_EX_CONTROLPARENT;

    // Force DialogUI for a dialog box
    perlcs->dwPlStyle |= PERLWIN32GUI_DIALOGUI;
}

BOOL
DialogBox_onParseOption(NOTXSPROC char *option, SV* value, LPPERLWIN32GUI_CREATESTRUCT perlcs) {

    return Window_onParseOption (NOTXSCALL option, value, perlcs);
}

void 
DialogBox_onPostCreate(NOTXSPROC HWND myhandle, LPPERLWIN32GUI_CREATESTRUCT perlcs) {
    
}

BOOL
DialogBox_onParseEvent(NOTXSPROC char *name, int* eventID) {

    return Window_onParseEvent(NOTXSCALL name, eventID);
}

int  
DialogBox_onEvent (NOTXSPROC LPPERLWIN32GUI_USERDATA perlud, UINT uMsg, WPARAM wParam, LPARAM lParam) {

    return Window_onEvent(NOTXSCALL perlud, uMsg, wParam, lParam);
}


    /*
    ###########################################################################
    # (@)PACKAGE:Win32::GUI::Graphic
    ###########################################################################
    */

void 
Graphic_onPreCreate(NOTXSPROC LPPERLWIN32GUI_CREATESTRUCT perlcs) {

    perlcs->cs.lpszClass = "Win32::GUI::Graphic";
    perlcs->cs.style = WS_VISIBLE | WS_CHILD;
    perlcs->cs.dwExStyle = WS_EX_NOPARENTNOTIFY;
}

BOOL
Graphic_onParseOption(NOTXSPROC char *option, SV* value, LPPERLWIN32GUI_CREATESTRUCT perlcs) {

    BOOL retval = TRUE;

        if BitmaskOptionValue("-interactive", perlcs->dwPlStyle, PERLWIN32GUI_INTERACTIVE)
    } else retval = FALSE;

    return retval;;
}

void 
Graphic_onPostCreate(NOTXSPROC HWND myhandle, LPPERLWIN32GUI_CREATESTRUCT perlcs) {
    
}

BOOL
Graphic_onParseEvent(NOTXSPROC char *name, int* eventID) {

    BOOL retval = TRUE;

         if Parse_Event("Paint",       PERLWIN32GUI_NEM_PAINT)
    else if Parse_Event("LButtonDown", PERLWIN32GUI_NEM_CONTROL1)
    else if Parse_Event("LButtonUp",   PERLWIN32GUI_NEM_CONTROL2)
    else if Parse_Event("RButtonDown", PERLWIN32GUI_NEM_CONTROL3)
    else if Parse_Event("RButtonUp",   PERLWIN32GUI_NEM_CONTROL4)    
    else retval = FALSE;

    return retval;
}

int  
Graphic_onEvent (NOTXSPROC LPPERLWIN32GUI_USERDATA perlud, UINT uMsg, WPARAM wParam, LPARAM lParam) {

    int PerlResult = 1;

    if (uMsg == WM_PAINT) {
        /*
        * (@)EVENT:Paint(DC)
        * Sent when the Graphic object needs to be repainted.
        *
        * Note that you get the DC of the Graphic object in parameter, 
        * and then Validate() the DC to inform Windows
        * that you painted the DC area (otherwise it will
        * continue to call the Paint event continuously).
        * Example:
        *   sub Graphic_Paint {
        *       my $DC = shift;
        *       $DC->MoveTo(0, 0);
        *       $DC->LineTo(100, 100);
        *       $DC->Validate();
        *   }
        *
        * (@)APPLIES_TO:Graphic
        */

        PerlResult = DoEvent_Paint(NOTXSCALL perlud); 
    }
    // Interactive Graphics ?
    else if (perlud->dwPlStyle & PERLWIN32GUI_INTERACTIVE) {
        // For compatibility reason whe have specific event name.
        switch(uMsg) {
        case WM_LBUTTONDOWN:
            /*
             * (@)EVENT:LButtonDown()
             * Mouse left button down.
             * (@)APPLIES_TO:Graphic
             */
            PerlResult = DoEvent(NOTXSCALL perlud, PERLWIN32GUI_NEM_CONTROL1, "LButtonDown",
                PERLWIN32GUI_ARGTYPE_LONG, GET_X_LPARAM(lParam),
                PERLWIN32GUI_ARGTYPE_LONG, GET_Y_LPARAM(lParam),
                PERLWIN32GUI_ARGTYPE_LONG, wParam,
                -1);
            break;
        case WM_LBUTTONUP:
            /*
             * (@)EVENT:LButtonUp()
             * Mouse Left button Up.
             * (@)APPLIES_TO:Graphic
             */
            PerlResult = DoEvent(NOTXSCALL perlud, PERLWIN32GUI_NEM_CONTROL2, "LButtonUp",
                PERLWIN32GUI_ARGTYPE_LONG, GET_X_LPARAM(lParam),
                PERLWIN32GUI_ARGTYPE_LONG, GET_Y_LPARAM(lParam),
                PERLWIN32GUI_ARGTYPE_LONG, wParam,
                -1);
            break;
        case WM_RBUTTONDOWN:
            /*
             * (@)EVENT:RButtonDown()
             * Mouse right button down.
             * (@)APPLIES_TO:Graphic
             */ 
            PerlResult = DoEvent(NOTXSCALL perlud, PERLWIN32GUI_NEM_CONTROL3, "RButtonDown",
                PERLWIN32GUI_ARGTYPE_LONG, GET_X_LPARAM(lParam),
                PERLWIN32GUI_ARGTYPE_LONG, GET_Y_LPARAM(lParam),
                PERLWIN32GUI_ARGTYPE_LONG, wParam,
                -1);
            break;
        case WM_RBUTTONUP:
            /*
             * (@)EVENT:RButtonUp()
             * Mouse right button up.
             * (@)APPLIES_TO:Graphic
             */ 
            PerlResult = DoEvent(NOTXSCALL perlud, PERLWIN32GUI_NEM_CONTROL4, "RButtonUp",
                PERLWIN32GUI_ARGTYPE_LONG, GET_X_LPARAM(lParam),
                PERLWIN32GUI_ARGTYPE_LONG, GET_Y_LPARAM(lParam),
                PERLWIN32GUI_ARGTYPE_LONG, wParam,
                -1);
            break;
        }
    }

    return PerlResult;
}

MODULE = Win32::GUI::Window     PACKAGE = Win32::GUI::Window

PROTOTYPES: DISABLE

    ###########################################################################
    # (@)PACKAGE:Win32::GUI::Window
    ###########################################################################

#pragma message( "*** PACKAGE Win32::GUI::Window..." )


    ###########################################################################
    # (@)PACKAGE:Win32::GUI::DialogBox
    ###########################################################################

MODULE = Win32::GUI::Window     PACKAGE = Win32::GUI::DialogBox

#pragma message( "*** PACKAGE Win32::GUI::DialogBox..." )

