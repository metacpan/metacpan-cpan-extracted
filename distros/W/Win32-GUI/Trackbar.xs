    /*
    ###########################################################################
    # (@)PACKAGE:Win32::GUI::Trackbar
    #
    # $Id: Trackbar.xs,v 1.8 2006/03/16 21:11:12 robertemay Exp $
    #
    ###########################################################################
    */

#include "GUI.h"

void 
Trackbar_onPreCreate(NOTXSPROC LPPERLWIN32GUI_CREATESTRUCT perlcs) {

    perlcs->cs.lpszClass = TRACKBAR_CLASS;
    perlcs->cs.style = WS_VISIBLE | WS_CHILD | TBS_AUTOTICKS | TBS_ENABLESELRANGE;
}

BOOL
Trackbar_onParseOption(NOTXSPROC char *option, SV* value, LPPERLWIN32GUI_CREATESTRUCT perlcs) {

    BOOL retval= TRUE;

    if(strcmp(option, "-tooltip") == 0) {
        perlcs->hTooltip = (HWND) handle_From(NOTXSCALL value);
        SwitchBit(perlcs->cs.style, TBS_TOOLTIPS , 1);        
    } else if BitmaskOptionValue("-vertical",    perlcs->cs.style, TBS_VERT)
    } else if BitmaskOptionValue("-aligntop",    perlcs->cs.style, TBS_TOP)
    } else if BitmaskOptionValue("-alignleft",   perlcs->cs.style, TBS_LEFT)
    } else if BitmaskOptionValue("-noticks",     perlcs->cs.style, TBS_NOTICKS)
    } else if BitmaskOptionValue("-nothumb",     perlcs->cs.style, TBS_NOTHUMB)
    } else if BitmaskOptionValue("-selrange",    perlcs->cs.style, TBS_ENABLESELRANGE)
    } else if BitmaskOptionValue("-autoticks",   perlcs->cs.style, TBS_AUTOTICKS)
    } else if BitmaskOptionValue("-both",        perlcs->cs.style, TBS_BOTH)
    } else if BitmaskOptionValue("-fixedlength", perlcs->cs.style, TBS_FIXEDLENGTH)
    } else retval= FALSE;

    return retval;
}

void 
Trackbar_onPostCreate(NOTXSPROC HWND myhandle, LPPERLWIN32GUI_CREATESTRUCT perlcs) {

    if (perlcs->hTooltip != NULL) 
        SendMessage(myhandle, TBM_SETTOOLTIPS, (WPARAM) perlcs->hTooltip, 0);
}

BOOL
Trackbar_onParseEvent(NOTXSPROC char *name, int* eventID) {

    BOOL retval = TRUE;

         if Parse_Event("Scroll",     PERLWIN32GUI_NEM_CONTROL1)
    else retval = FALSE;

    return retval;
}

int
Trackbar_onEvent (NOTXSPROC LPPERLWIN32GUI_USERDATA perlud, UINT uMsg, WPARAM wParam, LPARAM lParam) {

    int PerlResult = 1;

    switch(uMsg) {
    case WM_HSCROLL:
    case WM_VSCROLL:

        /*
         * (@)EVENT:Scroll(SCROLLBAR, OPERATION, POSITION)
         * Sent when one of the window scrollbars is moved. B<SCROLLBAR> identifies
         * which bar was moved, 0 for horizontal and 1 for vertical.
         *
         * B<OPERATION> can be compared against one of the following constants:
         *  SB_LINEUP, SB_LINELEFT, SB_LINEDOWN, SB_LINERIGHT, SB_PAGEUP
         *  SB_PAGELEFT, SB_PAGEDOWN, SB_PAGERIGHT, SB_THUMBPOSITION,
         *  SB_THUMBTRACK, SB_TOP, SB_LEFT, SB_BOTTOM, SB_RIGHT, SB_ENDSCROLL
         *
         * (@)APPLIES_TO:Trackbar
         */
        PerlResult = DoEvent(NOTXSCALL perlud, PERLWIN32GUI_NEM_CONTROL1, "Scroll",
                             PERLWIN32GUI_ARGTYPE_INT, (uMsg == WM_HSCROLL ? 0 : 1),
                             PERLWIN32GUI_ARGTYPE_INT, (int) LOWORD(wParam),
                             PERLWIN32GUI_ARGTYPE_INT, (int) HIWORD(wParam), -1 );
        break;
    }

    return PerlResult;
}

MODULE = Win32::GUI::Trackbar       PACKAGE = Win32::GUI::Trackbar

PROTOTYPES: DISABLE

#pragma message( "*** PACKAGE Win32::GUI::Trackbar..." )

    ###########################################################################
    # (@)METHOD:ClearSel([REDRAW=1])
    # Clears the current selection.

LRESULT
ClearSel(handle, value=TRUE)
    HWND   handle
    WPARAM value
CODE:
    RETVAL = SendMessage(handle, TBM_CLEARSEL, value, 0);
OUTPUT:
    RETVAL

    ###########################################################################
    # (@)METHOD:ClearTics([REDRAW=1])
    # Removes the current tick marks. Does not remove the first and last tick marks.

LRESULT
ClearTics(handle, value=TRUE)
    HWND   handle
    WPARAM value
CODE:
    RETVAL = SendMessage(handle, TBM_CLEARTICS, value, 0);
OUTPUT:
    RETVAL

    ###########################################################################
    # (@)METHOD:GetBuddy(LOCATION)
    # Retrieves the handle to a trackbar control buddy window at a given location.
    #
    # The specified location is relative to the control's orientation (horizontal or vertical). 
    #  B<LOCATION> = FALSE : Retrieves buddy to the right of the trackbar (or below for vertical trackbar)
    #  B<LOCATION> = TRUE  : Retrieves buddy to the left of the trackbar (or above for vertical trackbar)
LRESULT
GetBuddy(handle, value)
    HWND   handle
    WPARAM value
CODE:
    RETVAL = SendMessage(handle, TBM_GETBUDDY, value, 0);
OUTPUT:
    RETVAL

    ###########################################################################
    # (@)METHOD:GetChannelRect()
    # Retrieves the bounding rectangle for a trackbar's channel.
    # The channel is the area over which the slider moves. It contains the highlight when a range is selected. 

void
GetChannelRect(handle)
    HWND   handle
PREINIT:
    RECT    myRect;
PPCODE:
    SendMessage(handle, TBM_GETCHANNELRECT, 0, (LPARAM) &myRect);
    EXTEND(SP, 4);
    XST_mIV(0, myRect.left);
    XST_mIV(1, myRect.top);
    XST_mIV(2, myRect.right);
    XST_mIV(3, myRect.bottom);
    XSRETURN(4);

    ###########################################################################
    # (@)METHOD:GetLineSize()
    # Retrieves the number of logical positions the trackbar's slider moves in response to keyboard input from the arrow keys, such as the RIGHT ARROW or DOWN ARROW keys.

LRESULT
GetLineSize(handle)
    HWND   handle
CODE:
    RETVAL = SendMessage(handle, TBM_GETLINESIZE, 0, 0);
OUTPUT:
    RETVAL

    ###########################################################################
    # (@)METHOD:GetNumTics()
    # Retrieves the number of logical positions the trackbar's slider moves in response to keyboard input from the arrow keys, such as the RIGHT ARROW or DOWN ARROW keys.

LRESULT
GetNumTics(handle)
    HWND   handle
CODE:
    RETVAL = SendMessage(handle, TBM_GETNUMTICS, 0, 0);
OUTPUT:
    RETVAL

    ###########################################################################
    # (@)METHOD:GetPageSize()
    # Retrieves the number of logical positions the trackbar's slider moves in response to keyboard input, such as the PAGE UP or PAGE DOWN keys, or mouse input, such as clicks in the trackbar's channel.

LRESULT
GetPageSize(handle)
    HWND   handle
CODE:
    RETVAL = SendMessage(handle, TBM_GETPAGESIZE, 0, 0);
OUTPUT:
    RETVAL

    ###########################################################################
    # (@)METHOD:GetPos()
    # Retrieves the current logical position of the slider in a trackbar.

LRESULT
GetPos(handle)
    HWND   handle
CODE:
    RETVAL = SendMessage(handle, TBM_GETPOS, 0, 0);
OUTPUT:
    RETVAL

    ###########################################################################
    # (@)METHOD:GetPics()
    # Retrieves an array of logical positions of the trackbar's tick marks, not including the first and last tick. 

void
GetPics(handle)
    HWND   handle
PREINIT:
    UINT nTics;
    DWORD *pTics;
PPCODE:
    nTics = (UINT) SendMessage(handle, TBM_GETNUMTICS, 0, 0);
    nTics -= 2;  // Remove first and last
    if (nTics > 0) {
        pTics = (DWORD *) SendMessage(handle, TBM_GETPTICS, 0, 0);
        if (pTics) {
            EXTEND(SP, nTics);
            for (UINT i = 0; i < nTics; i++) 
                XST_mIV(i, pTics[i]);
            XSRETURN(nTics);
        }
        else
            XSRETURN_UNDEF;
    }
    else
        XSRETURN_UNDEF;

    ###########################################################################
    # (@)METHOD:GetRangeMax()
    # Retrieves the maximum position for the slider in a trackbar.

LRESULT
GetRangeMax(handle)
    HWND   handle
CODE:
    RETVAL = SendMessage(handle, TBM_GETRANGEMAX, 0, 0);
OUTPUT:
    RETVAL

    ###########################################################################
    # (@)METHOD:GetRangeMin()
    # Retrieves the minimum position for the slider in a trackbar.

LRESULT
GetRangeMin(handle)
    HWND   handle
CODE:
    RETVAL = SendMessage(handle, TBM_GETRANGEMIN, 0, 0);
OUTPUT:
    RETVAL

    ###########################################################################
    # (@)METHOD:GetSelEnd()
    # Retrieves the ending position of the current selection range in a trackbar.

LRESULT
GetSelEnd(handle)
    HWND   handle
CODE:
    RETVAL = SendMessage(handle, TBM_GETSELEND, 0, 0);
OUTPUT:
    RETVAL

    ###########################################################################
    # (@)METHOD:GetSelStart()
    # Retrieves the starting position of the current selection range in a trackbar.

LRESULT
GetSelStart(handle)
    HWND   handle
CODE:
    RETVAL = SendMessage(handle, TBM_GETSELSTART, 0, 0);
OUTPUT:
    RETVAL

    ###########################################################################
    # (@)METHOD:GetThumbLength()
    # Retrieves the length of the slider in a trackbar.

LRESULT
GetThumbLength(handle)
    HWND   handle
CODE:
    RETVAL = SendMessage(handle, TBM_GETTHUMBLENGTH, 0, 0);
OUTPUT:
    RETVAL

    ###########################################################################
    # (@)METHOD:GetThumbRect()
    # Retrieves the bounding rectangle for the slider in a trackbar. 

void
GetThumbRect(handle)
    HWND   handle
PREINIT:
    RECT    myRect;
PPCODE:
    SendMessage(handle, TBM_GETTHUMBRECT, 0, (LPARAM) &myRect);
    EXTEND(SP, 4);
    XST_mIV(0, myRect.left);
    XST_mIV(1, myRect.top);
    XST_mIV(2, myRect.right);
    XST_mIV(3, myRect.bottom);
    XSRETURN(4);

    ###########################################################################
    # (@)METHOD:GetTic(index)
    # Retrieves the logical position of a tick mark in a trackbar or -1 for a valid index.

LRESULT
GetTic(handle, value)
    HWND   handle
    WPARAM value
CODE:
    RETVAL = SendMessage(handle, TBM_GETTIC, value, 0);
OUTPUT:
    RETVAL

    ###########################################################################
    # (@)METHOD:GetTicPos(index)
    # Retrieves the distance, in client coordinates, from the left or top of the trackbar's client area of a tick mark in a trackbar or -1 for a valid index.

LRESULT
GetTicPos(handle, value)
    HWND   handle
    WPARAM value
CODE:
    RETVAL = SendMessage(handle, TBM_GETTICPOS, value, 0);
OUTPUT:
    RETVAL

    ###########################################################################
    # (@)METHOD:GetToolTips()
    # Retrieves the handle to the tooltip control assigned to the trackbar, if any. 

LRESULT
GetToolTips(handle)
    HWND   handle
CODE:
    RETVAL = SendMessage(handle, TBM_GETTOOLTIPS, 0, 0);
OUTPUT:
    RETVAL

    ###########################################################################
    # (@)METHOD:GetUnicodeFormat()
    # Retrieves the UNICODE character format flag for the control.  

LRESULT
GetUnicodeFormat(handle)
    HWND   handle
CODE:
    RETVAL = SendMessage(handle, TBM_GETUNICODEFORMAT, 0, 0);
OUTPUT:
    RETVAL

    ###########################################################################
    # (@)METHOD:SetBuddy(LOCATION, HWND)
    # Assigns a window as the buddy window for a trackbar control
    # Returns the handle to the window that was previously assigned to the control at that location
    # The specified location is relative to the control's orientation (horizontal or vertical). 
    # LOCATION = FALSE : Retrieves buddy to the right of the trackbar (or below for vertical trackbar)
    # LOCATION = TRUE  : Retrieves buddy to the left of the trackbar (or above for vertical trackbar)
LRESULT
SetBuddy(handle, value, param)
    HWND   handle
    WPARAM value
    HWND   param
CODE:
    RETVAL = SendMessage(handle, TBM_SETBUDDY, value, (LPARAM) param);
OUTPUT:
    RETVAL

    ###########################################################################
    # (@)METHOD:SetLineSize([SIZE=1])
    # Sets the number of logical positions the trackbar's slider moves in response to keyboard input from the arrow keys, such as the RIGHT ARROW or DOWN ARROW keys.

LRESULT
SetLineSize(handle, param=1)
    HWND   handle
    WPARAM param
CODE:
    RETVAL = SendMessage(handle, TBM_SETLINESIZE, 0, (LPARAM) param);
OUTPUT:
    RETVAL

    ###########################################################################
    # (@)METHOD:SetPageSize([SIZE=10])
    # Sets the number of logical positions the trackbar's slider moves in response to keyboard input, such as the PAGE UP or PAGE DOWN keys, or mouse input, such as clicks in the trackbar's channel. 

LRESULT
SetPageSize(handle, param=10)
    HWND   handle
    WPARAM param
CODE:
    RETVAL = SendMessage(handle, TBM_SETPAGESIZE, 0, (LPARAM) param);
OUTPUT:
    RETVAL

    ###########################################################################
    # (@)METHOD:SetPos(POSITION, [REDRAW=TRUE])
    # Sets the current logical position of the slider in a trackbar.

LRESULT
SetPos(handle, param, value=TRUE)
    HWND   handle
    WPARAM param
    WPARAM value
CODE:
    RETVAL = SendMessage(handle, TBM_SETPOS, value, (LPARAM) param);
OUTPUT:
    RETVAL

    ###########################################################################
    # (@)METHOD:SetRange([MIN=0], MAX, [REDRAW=TRUE])
    # Sets the range of minimum and maximum logical positions for the slider in a trackbar. 

LRESULT
SetRange(handle, min=0, max=min, value=TRUE)
    HWND   handle
    UINT   min
    UINT   max
    WPARAM value
CODE:
    RETVAL = SendMessage(handle, TBM_SETRANGE, value, (LPARAM) MAKELONG(min,max));
OUTPUT:
    RETVAL

    ###########################################################################
    # (@)METHOD:SetRangeMax(MAX, [REDRAW=TRUE])
    # Sets the maximum logical position for the slider in a trackbar.

LRESULT
SetRangeMax(handle, param, value=TRUE)
    HWND   handle
    WPARAM param
    WPARAM value
CODE:
    RETVAL = SendMessage(handle, TBM_SETRANGEMAX, value, (LPARAM) param);
OUTPUT:
    RETVAL

    ###########################################################################
    # (@)METHOD:SetRangeMin(MIN, [REDRAW=TRUE])
    # Sets the minimum logical position for the slider in a trackbar.

LRESULT
SetRangeMin(handle, param, value=TRUE)
    HWND   handle
    WPARAM param
    WPARAM value
CODE:
    RETVAL = SendMessage(handle, TBM_SETRANGEMIN, value, (LPARAM) param);
OUTPUT:
    RETVAL

    ###########################################################################
    # (@)METHOD:SetSel([MIN=0], MAX, [REDRAW=TRUE])
    # Sets the starting and ending logical positions for the current selection range in a trackbar. 

LRESULT
SetSel(handle, min=0, max=min, value=TRUE)
    HWND   handle
    UINT   min
    UINT   max
    WPARAM value
CODE:
    RETVAL = SendMessage(handle, TBM_SETSEL, value, (LPARAM) MAKELONG(min,max));
OUTPUT:
    RETVAL

    ###########################################################################
    # (@)METHOD:SetSelEnd(END, [REDRAW=TRUE])
    # Sets the ending logical position of the current selection range in a trackbar.

LRESULT
SetSelEnd(handle, param, value=TRUE)
    HWND   handle
    WPARAM param
    WPARAM value
CODE:
    RETVAL = SendMessage(handle, TBM_SETSELEND, value, (LPARAM) param);
OUTPUT:
    RETVAL

    ###########################################################################
    # (@)METHOD:SetSelStart(START, [REDRAW=TRUE])
    # Sets the starting logical position of the current selection range in a trackbar.

LRESULT
SetSelStart(handle, param, value=TRUE)
    HWND   handle
    WPARAM param
    WPARAM value
CODE:
    RETVAL = SendMessage(handle, TBM_SETSELSTART, value, (LPARAM) param);
OUTPUT:
    RETVAL

    ###########################################################################
    # (@)METHOD:SetThumbLength(SIZE)
    # Sets the length of the slider in a trackbar.

LRESULT
SetThumbLength(handle, value)
    HWND   handle
    WPARAM value
CODE:
    RETVAL = SendMessage(handle, TBM_SETTHUMBLENGTH, value, 0);
OUTPUT:
    RETVAL

    ###########################################################################
    # (@)METHOD:SetTic(POSITION)
    # Sets a tick mark in a trackbar at the specified logical position. 

LRESULT
SetTic(handle, param)
    HWND   handle
    WPARAM param
CODE:
    RETVAL = SendMessage(handle, TBM_SETTIC, 0, (LPARAM) param);
OUTPUT:
    RETVAL

    ###########################################################################
    # (@)METHOD:SetTicFreq(POSITION)
    # Sets the interval frequency for tick marks in a trackbar.

LRESULT
SetTicFreq(handle, value)
    HWND   handle
    WPARAM value
ALIAS:
    Win32::GUI::Trackbar::TicFrequency = 1
CODE:
    RETVAL = SendMessage(handle, TBM_SETTICFREQ, value, 0);
OUTPUT:
    RETVAL

    ###########################################################################
    # (@)METHOD:SetTipSide(LOCATION)
    # Positions a tooltip control used by a trackbar control.
    # TBTS_TOP : The tooltip control will be positioned above the trackbar. This flag is for use with horizontal trackbars.
    # TBTS_LEFT  The tooltip control will be positioned to the left of the trackbar. This flag is for use with vertical trackbars. 
    # TBTS_BOTTOM  The tooltip control will be positioned below the trackbar. This flag is for use with horizontal trackbars. 
    # TBTS_RIGHT  The tooltip control will be positioned to the right of the trackbar. This flag is for use with vertical trackbars. 

LRESULT
SetTipSide(handle, value)
    HWND   handle
    WPARAM value
CODE:
    RETVAL = SendMessage(handle, TBM_SETTIPSIDE, value, 0);
OUTPUT:
    RETVAL

    ###########################################################################
    # (@)METHOD:SetToolTips(HWND)
    # Assigns a tooltip control to a trackbar control.

LRESULT
SetToolTips(handle, value)
    HWND   handle
    HWND   value
CODE:
    RETVAL = SendMessage(handle, TBM_SETTOOLTIPS, (WPARAM) value, 0);
OUTPUT:
    RETVAL

    ###########################################################################
    # (@)METHOD:SetUnicodeFormat(FLAG)
    # Sets the UNICODE character format flag for the control. 

LRESULT
SetUnicodeFormat(handle, value)
    HWND   handle
    BOOL   value
CODE:
    RETVAL = SendMessage(handle, TBM_SETUNICODEFORMAT, (WPARAM) value, 0);
OUTPUT:
    RETVAL

    ###########################################################################
    ###########################################################################
    ###########################################################################

    ###########################################################################
    # (@)METHOD:Min([VALUE],[REDRAW=1])
    # Set or Get minimum logical position for the slider in a trackbar

LRESULT
Min(handle, ...)
    HWND   handle
CODE:
    if(items > 1) {        
        if(items > 2)
            RETVAL = SendMessage(handle, TBM_SETRANGEMIN, (WPARAM) SvIV(ST(2)), (LPARAM) SvIV(ST(1))); 
        else
            RETVAL = SendMessage(handle, TBM_SETRANGEMIN, 1, (LPARAM) SvIV(ST(1)));
    }
    else
        RETVAL = SendMessage(handle, TBM_GETRANGEMIN, 0, 0);
OUTPUT:
    RETVAL


    ###########################################################################
    # (@)METHOD:Max([VALUE],[REDRAW=1])
    # Set or Get maximal logical position for the slider in a trackbar

LRESULT
Max(handle, ...)
    HWND   handle
CODE:
    if(items > 1) {        
        if(items > 2)
            RETVAL = SendMessage(handle, TBM_SETRANGEMAX, (WPARAM) SvIV(ST(2)), (LPARAM) SvIV(ST(1))); 
        else
            RETVAL = SendMessage(handle, TBM_SETRANGEMAX, 1, (LPARAM) SvIV(ST(1)));
    }
    else
        RETVAL = SendMessage(handle, TBM_GETRANGEMAX, 0, 0);
OUTPUT:
    RETVAL

    ###########################################################################
    # (@)METHOD:Pos([VALUE],[REDRAW=1])
    # Set or Get maximum logical position for the slider in a trackbar

LRESULT
Pos(handle, ...)
    HWND   handle
CODE:
    if(items > 1) {        
        if(items > 2)
            RETVAL = SendMessage(handle, TBM_SETPOS, (WPARAM) SvIV(ST(2)), (LPARAM) SvIV(ST(1))); 
        else
            RETVAL = SendMessage(handle, TBM_SETPOS, 1, (LPARAM) SvIV(ST(1)));
    }
    else
        RETVAL = SendMessage(handle, TBM_GETPOS, 0, 0);
OUTPUT:
    RETVAL

    ###########################################################################
    # (@)METHOD:SelStart([VALUE],[REDRAW=1])
    # Set or Get the starting logical position of the current selection range in a trackbar.

LRESULT
SelStart(handle, ...)
    HWND   handle
CODE:
    if(items > 1) {        
        if(items > 2)
            RETVAL = SendMessage(handle, TBM_SETSELSTART, (WPARAM) SvIV(ST(2)), (LPARAM) SvIV(ST(1))); 
        else
            RETVAL = SendMessage(handle, TBM_SETSELSTART, 1, (LPARAM) SvIV(ST(1)));
    }
    else
        RETVAL = SendMessage(handle, TBM_GETSELSTART, 0, 0);
OUTPUT:
    RETVAL

    ###########################################################################
    # (@)METHOD:SelEnd([VALUE],[REDRAW=1])
    # Set or Get the starting logical position of the current selection range in a trackbar.

LRESULT
SelEnd(handle, ...)
    HWND   handle
CODE:
    if(items > 1) {        
        if(items > 2)
            RETVAL = SendMessage(handle, TBM_SETSELEND, (WPARAM) SvIV(ST(2)), (LPARAM) SvIV(ST(1))); 
        else
            RETVAL = SendMessage(handle, TBM_SETSELEND, 1, (LPARAM) SvIV(ST(1)));
    }
    else
        RETVAL = SendMessage(handle, TBM_GETSELEND, 0, 0);
OUTPUT:
    RETVAL
