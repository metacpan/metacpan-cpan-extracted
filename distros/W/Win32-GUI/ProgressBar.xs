
    /*
    ###########################################################################
    # (@)PACKAGE:Win32::GUI::ProgressBar
    #
    # $Id: ProgressBar.xs,v 1.2 2004/03/25 23:01:50 lrocher Exp $
    #
    ###########################################################################
    */

#include "GUI.h"

void ProgressBar_onPreCreate(NOTXSPROC LPPERLWIN32GUI_CREATESTRUCT perlcs) {

    perlcs->cs.lpszClass = PROGRESS_CLASS;
    perlcs->cs.style = WS_VISIBLE | WS_CHILD;
    perlcs->cs.dwExStyle = WS_EX_CLIENTEDGE;
}

BOOL
ProgressBar_onParseOption(NOTXSPROC char *option, SV* value, LPPERLWIN32GUI_CREATESTRUCT perlcs) {

    BOOL retval = TRUE;

    if BitmaskOptionValue("-smooth", perlcs->cs.style, PBS_SMOOTH)
    } else if BitmaskOptionValue("-vertical", perlcs->cs.style, PBS_VERTICAL)
    } else retval = FALSE;

    return retval;
}

void
ProgressBar_onPostCreate(NOTXSPROC HWND myhandle, LPPERLWIN32GUI_CREATESTRUCT perlcs) {

    if(perlcs->clrForeground != CLR_INVALID) {
        SendMessage(myhandle, PBM_SETBARCOLOR, (WPARAM) 0, (LPARAM) perlcs->clrForeground);
        perlcs->clrForeground = CLR_INVALID;  // Don't Store
    }
    if(perlcs->clrBackground != CLR_INVALID) {
        SendMessage(myhandle, PBM_SETBKCOLOR, (WPARAM) 0, (LPARAM) perlcs->clrBackground);
        perlcs->clrBackground = CLR_INVALID;  // Don't Store
    }
}

BOOL
ProgressBar_onParseEvent(NOTXSPROC char *name, int* eventID) {

    return FALSE;
}

int
ProgressBar_onEvent (NOTXSPROC LPPERLWIN32GUI_USERDATA perlud, UINT uMsg, WPARAM wParam, LPARAM lParam) {

    int PerlResult = 1;

    return PerlResult;
}

MODULE = Win32::GUI::ProgressBar        PACKAGE = Win32::GUI::ProgressBar

PROTOTYPES: DISABLE

#pragma message( "*** PACKAGE Win32::GUI::ProgressBar..." )


    ###########################################################################
    # (@)METHOD:DeltaPos(VALUE)
    # Advances the position of the ProgressBar by a specified increment.

LRESULT
DeltaPos(handle, value)
    HWND   handle
    WPARAM value
CODE:
    RETVAL = SendMessage(handle, PBM_DELTAPOS, value, 0);
OUTPUT:
    RETVAL

    ###########################################################################
    # (@)METHOD:GetPos()
    # Retrieves the current position of the ProgressBar.

LRESULT
GetPos(handle)
    HWND   handle
CODE:
    RETVAL = SendMessage(handle, PBM_GETPOS, 0, 0);
OUTPUT:
    RETVAL

    ###########################################################################
    # (@)METHOD:GetRange()
    # Retrieves Min and Max limits of the ProgressBar. 

void
GetRange(handle)
    HWND   handle
PREINIT:
    PBRANGE range;
PPCODE:
    SendMessage(handle, PBM_GETRANGE, (WPARAM)FALSE, (LPARAM) &range);
    EXTEND(SP, 2);
    XST_mIV(0, range.iLow);
    XST_mIV(1, range.iHigh);
    XSRETURN(2);

    ###########################################################################
    # (@)METHOD:SetBarColor(COLOR)
    # Sets the color of the progress indicator bar in the ProgressBar. 

COLORREF
SetBarColor(handle, color)
    HWND   handle
    COLORREF color
CODE:
    RETVAL = SendMessage(handle, PBM_SETBARCOLOR, 0, (LPARAM) color);
OUTPUT:
    RETVAL

    ###########################################################################
    # (@)METHOD:SetBkColor(COLOR)
    # Sets the background color in the ProgressBar.

COLORREF
SetBkColor(handle, color)
    HWND   handle
    COLORREF color
CODE:
    RETVAL = SendMessage(handle, PBM_SETBKCOLOR, 0, (LPARAM) color);
OUTPUT:
    RETVAL

    ###########################################################################
    # (@)METHOD:SetPos(VALUE)
    # Sets the position of the ProgressBar to the specified VALUE.

LRESULT
SetPos(handle, value)
    HWND   handle
    WPARAM value
CODE:
    RETVAL = SendMessage(handle, PBM_SETPOS, value, 0);
OUTPUT:
    RETVAL

    ###########################################################################
    # (@)METHOD:SetRange([MIN=0], MAX)
    # Sets the range of a ProgressBar between Min and Max value

LRESULT
SetRange(handle, min=0, max=min)
    HWND   handle
    WPARAM min
    WPARAM max
CODE:
    RETVAL = SendMessage(handle, PBM_SETRANGE32, min, (LPARAM) max);
OUTPUT:
    RETVAL

    ###########################################################################
    # (@)METHOD:SetStep([VALUE=10])
    # Sets the increment value for the ProgressBar; see StepIt().
LRESULT
SetStep(handle, value=10)
    HWND   handle
    WPARAM value
CODE:
    RETVAL = SendMessage(handle, PBM_SETSTEP, value, 0);
OUTPUT:
    RETVAL

    ###########################################################################
    # (@)METHOD:StepIt()
    # Increments the position of the ProgressBar of the defined step value;
    # see SetStep().

LRESULT
StepIt(handle)
    HWND   handle
CODE:
    RETVAL = SendMessage(handle, PBM_STEPIT, 0, 0);
OUTPUT:
    RETVAL

    ###########################################################################
    ###########################################################################
    ###########################################################################

    ###########################################################################
    # (@)METHOD:GetMin()

LRESULT
GetMin(handle)
    HWND   handle
CODE:
    RETVAL = SendMessage(handle, PBM_GETRANGE, (WPARAM)TRUE, (LPARAM) NULL);
OUTPUT:
    RETVAL

    ###########################################################################
    # (@)METHOD:GetMax()

LRESULT
GetMax(handle)
    HWND   handle
CODE:
    RETVAL = SendMessage(handle, PBM_GETRANGE, (WPARAM)FALSE, (LPARAM) NULL);
OUTPUT:
    RETVAL