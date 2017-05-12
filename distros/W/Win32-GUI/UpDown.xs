    /*
    ###########################################################################
    # (@)PACKAGE:Win32::GUI::UpDown
    #
    # $Id: UpDown.xs,v 1.5 2005/08/03 21:45:58 robertemay Exp $
    #
    ###########################################################################
    */

#include "GUI.h"

void 
UpDown_onPreCreate(NOTXSPROC LPPERLWIN32GUI_CREATESTRUCT perlcs) {

    perlcs->cs.lpszClass = UPDOWN_CLASS;
    perlcs->cs.style = WS_VISIBLE | WS_CHILD | UDS_SETBUDDYINT | UDS_AUTOBUDDY | UDS_ALIGNRIGHT;
}

BOOL
UpDown_onParseOption(NOTXSPROC char *option, SV* value, LPPERLWIN32GUI_CREATESTRUCT perlcs) {

    BOOL retval = FALSE;

    if(strcmp(option, "-align") == 0) {
        if(strcmp(SvPV_nolen(value), "left") == 0) {
            SwitchBit(perlcs->cs.style, UDS_ALIGNLEFT, 1);
            SwitchBit(perlcs->cs.style, UDS_ALIGNRIGHT, 0);
        } else if(strcmp(SvPV_nolen(value), "right") == 0) {
            SwitchBit(perlcs->cs.style, UDS_ALIGNLEFT, 0);
            SwitchBit(perlcs->cs.style, UDS_ALIGNRIGHT, 1);
        } else {
            W32G_WARN("Win32::GUI: Invalid value for -align!");
        }
    } else if BitmaskOptionValue("-nothousands", perlcs->cs.style, UDS_NOTHOUSANDS)
    } else if BitmaskOptionValue("-wrap", perlcs->cs.style, UDS_WRAP)
    } else if BitmaskOptionValue("-horizontal", perlcs->cs.style, UDS_HORZ)
    } else if BitmaskOptionValue("-autobuddy", perlcs->cs.style, UDS_AUTOBUDDY)
    } else if BitmaskOptionValue("-setbuddy", perlcs->cs.style, UDS_SETBUDDYINT)
    } else if BitmaskOptionValue("-arrowkeys", perlcs->cs.style, UDS_ARROWKEYS)
    } else retval = FALSE;

    return retval;
}

void 
UpDown_onPostCreate(NOTXSPROC HWND myhandle, LPPERLWIN32GUI_CREATESTRUCT perlcs) {
}

BOOL
UpDown_onParseEvent(NOTXSPROC char *name, int* eventID) {

    BOOL retval = TRUE;

         if Parse_Event("Scroll",     PERLWIN32GUI_NEM_CONTROL1)
    else retval = FALSE;

    return retval;
}

int
UpDown_onEvent (NOTXSPROC LPPERLWIN32GUI_USERDATA perlud, UINT uMsg, WPARAM wParam, LPARAM lParam) {

    int PerlResult = 1;

    switch(uMsg) {
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
         * (@)APPLIES_TO:UpDown
         */
        PerlResult = DoEvent(NOTXSCALL perlud, PERLWIN32GUI_NEM_CONTROL1, "Scroll",
                             PERLWIN32GUI_ARGTYPE_INT, (uMsg == WM_HSCROLL ? 0 : 1),
                             PERLWIN32GUI_ARGTYPE_INT, (int) LOWORD(wParam),
                             PERLWIN32GUI_ARGTYPE_INT, (int) HIWORD(wParam), -1 );
        break;
    }

    return PerlResult;
}

MODULE = Win32::GUI::UpDown     PACKAGE = Win32::GUI::UpDown

PROTOTYPES: DISABLE

#pragma message( "*** PACKAGE Win32::GUI::UpDown..." )

    # TODO : UDM_GETACCEL

    ###########################################################################
    # (@)METHOD:GetBase()
    # Gets the radix base for the UpDown control.
LRESULT
GetBase(handle)
    HWND handle
CODE:
    RETVAL = SendMessage(handle, UDM_GETBASE, 0, 0);
OUTPUT:
    RETVAL

    ###########################################################################
    # (@)METHOD:GetBuddy()
    # Returns the handle of the buddy.
HWND
GetBuddy(handle)
    HWND handle
PREINIT:
    HWND oldbuddy;
CODE:
    oldbuddy = (HWND) SendMessage(handle, UDM_GETBUDDY, 0, 0);
    //RETVAL = (HV*) GetWindowLongPtr(oldbuddy, GWLP_USERDATA);
    RETVAL = oldbuddy;
OUTPUT:
    RETVAL

    ###########################################################################
    # (@)METHOD:GetPos()
    # Gets the current position of the UpDown control.
LRESULT
GetPos(handle)
    HWND handle
CODE:
    RETVAL = SendMessage(handle, UDM_GETPOS, 0, 0);
OUTPUT:
    RETVAL

    ###########################################################################
    # (@)METHOD:GetRange()
    # Gets the range for the UpDown control (16bit values)
void
GetRange(handle)
    HWND handle
PREINIT:
    LRESULT res;
PPCODE:
    res = SendMessage(handle, UDM_GETRANGE, 0, 0);
    EXTEND(SP, 2);
    XST_mIV(0, HIWORD(res));
    XST_mIV(1, LOWORD(res));
    XSRETURN(2);

    ###########################################################################
    # (@)METHOD:GetRange32()
    # Gets the range for the UpDown control (32bit values)
void
GetRange32(handle)
    HWND handle
PREINIT:
    LRESULT res;
    UINT start;
    UINT end;
PPCODE:
    res = SendMessage(handle, UDM_GETRANGE32, (WPARAM) &start, (LPARAM) &end);
    EXTEND(SP, 2);
    XST_mIV(0, start);
    XST_mIV(1, end);
    XSRETURN(2);

    # UDM_GETUNICODEFORMAT

    # UDM_SETACCEL

    ###########################################################################
    # (@)METHOD:SetBase(VALUE)
    # Sets the radix base for the UpDown control; VALUE can be
    # either 10 or 16 for decimal or hexadecimal base numbering.
LRESULT
SetBase(handle,base)
    HWND handle
    WPARAM base
CODE:
    RETVAL = SendMessage(handle, UDM_SETBASE, base, 0);
OUTPUT:
    RETVAL

    ###########################################################################
    # (@)METHOD:SetBuddy(OBJECT)
    # Sets the buddy window for the UpDown control. Returns the handle of the previous buddy.
HWND
SetBuddy(handle,buddy)
    HWND handle
    HWND buddy
PREINIT:
    HWND oldbuddy;
CODE:
    oldbuddy = (HWND) SendMessage(handle, UDM_SETBUDDY, (WPARAM) buddy, 0);
    RETVAL = oldbuddy;
OUTPUT:
    RETVAL

    ###########################################################################
    # (@)METHOD:SetPos(VALUE)
    # Sets the current position of the UpDown control.
LRESULT
SetPos(handle,pos)
    HWND handle
    WPARAM pos
CODE:
    RETVAL = SendMessage(handle, UDM_SETPOS, 0, (LPARAM) MAKELONG(pos, 0));
OUTPUT:
    RETVAL

    ###########################################################################
    # (@)METHOD:SetRange(START,END)
    # Sets the range for the UpDown control (16bit values)
LRESULT
SetRange(handle,start,end)
    HWND handle
    WPARAM start
    WPARAM end
CODE:
    RETVAL = SendMessage(handle, UDM_SETRANGE, 0, (LPARAM) MAKELONG(end, start));
OUTPUT:
    RETVAL

    ###########################################################################
    # (@)METHOD:SetRange32(START,END)
    # Sets the range for the UpDown control (32bit values)
LRESULT
SetRange32(handle,start,end)
    HWND handle
    WPARAM start
    WPARAM end
CODE:
    RETVAL = SendMessage(handle, UDM_SETRANGE32, start, (LPARAM) end);
OUTPUT:
    RETVAL

    # UDM_SETUNICODEFORMAT

    ###########################################################################
    ###########################################################################
    ###########################################################################

    ###########################################################################
    # (@)METHOD:Base([VALUE])
    # Gets or sets the radix base for the UpDown control; VALUE can be
    # either 10 or 16 for decimal or hexadecimal base numbering.
LRESULT
Base(handle,base=0)
    HWND handle
    WPARAM base
CODE:
    if(items == 1)
        RETVAL = SendMessage(handle, UDM_GETBASE, 0, 0);
    else
        RETVAL = SendMessage(handle, UDM_SETBASE, base, 0);
OUTPUT:
    RETVAL

    ###########################################################################
    # (@)METHOD:Buddy([OBJECT])
    # Gets or sets the buddy window for the UpDown control. Returns the handle of the buddy.
HWND
Buddy(handle,buddy=NULL)
    HWND handle
    HWND buddy
PREINIT:
    HWND oldbuddy;
CODE:
    if(items == 1) {
        oldbuddy = (HWND) SendMessage(handle, UDM_GETBUDDY, 0, 0);
        //RETVAL = (HV*) GetWindowLongPtr(oldbuddy, GWLP_USERDATA);
    } else {
        oldbuddy = (HWND) SendMessage(handle, UDM_SETBUDDY, (WPARAM) buddy, 0);
        //RETVAL = (HV*) GetWindowLongPtr(oldbuddy, GWLP_USERDATA);
    }
    RETVAL = oldbuddy;
OUTPUT:
    RETVAL


    ###########################################################################
    # (@)METHOD:Pos([VALUE])
    # Gets or sets the current position of the UpDown control.
LRESULT
Pos(handle,pos=(short)-1)
    HWND handle
    short pos
CODE:
    if(items == 1)
        RETVAL = SendMessage(handle, UDM_GETPOS, 0, 0);
    else
        RETVAL = SendMessage(handle, UDM_SETPOS, 0, (LPARAM) MAKELONG(pos, 0));
OUTPUT:
    RETVAL


    ###########################################################################
    # (@)METHOD:Range([MIN, MAX])
    # Gets or sets the range for the UpDown control; if no parameter is given,
    # returns a two element array containing the MIN and MAX range values,
    # otherwise sets them to the given values.
    # If MAX is lower than MIN, the UpDown control function is reversed, eg.
    # the up button decrements the value and the down button increments it
void
Range(handle,min=(short)-1,max=(short)-1)
    HWND handle
    short min
    short max
PREINIT:
    LRESULT range;
PPCODE:
    if(items == 1) {
        range = SendMessage(handle, UDM_GETRANGE, 0, 0);
        EXTEND(SP, 2);
        XST_mIV(0, HIWORD(range));
        XST_mIV(1, LOWORD(range));
        XSRETURN(2);
    } else {
        SendMessage(handle, UDM_SETRANGE, 0, (LPARAM) MAKELONG(max, min));
        XSRETURN_YES;
    }

    ###########################################################################
    # (@)METHOD:Range32([MIN, MAX])
    # Gets or sets the range for the UpDown control; if no parameter is given,
    # returns a two element array containing the MIN and MAX range values,
    # otherwise sets them to the given values.
    # If MAX is lower than MIN, the UpDown control function is reversed, eg.
    # the up button decrements the value and the down button increments it
void
Range32(handle,min=(UINT)-1,max=(UINT)-1)
    HWND handle
    UINT min
    UINT max
PREINIT:
    UINT start;
    UINT end;
PPCODE:
    if(items == 1) {
        SendMessage(handle, UDM_GETRANGE32, (WPARAM)&start, (LPARAM)&end);
        EXTEND(SP, 2);
        XST_mIV(0, start);
        XST_mIV(1, end);
        XSRETURN(2);
    } else {
        SendMessage(handle, UDM_SETRANGE32, (WPARAM) min, (LPARAM) max);
        XSRETURN_YES;
    }
