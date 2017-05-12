    /*
    ###########################################################################
    # (@)PACKAGE:Win32::GUI::StatusBar
    #
    # $Id: StatusBar.xs,v 1.3 2004/04/08 21:23:39 lrocher Exp $
    #
    ###########################################################################
    */

#include "GUI.h"

void StatusBar_onPreCreate(NOTXSPROC LPPERLWIN32GUI_CREATESTRUCT perlcs) {

    perlcs->cs.lpszClass = STATUSCLASSNAME;
    perlcs->cs.style = WS_VISIBLE | WS_CHILD | SBT_TOOLTIPS;
}

BOOL
StatusBar_onParseOption(NOTXSPROC char *option, SV* value, LPPERLWIN32GUI_CREATESTRUCT perlcs) {
    BOOL retval = TRUE;

    if BitmaskOptionValue("-sizegrip", perlcs->cs.style, SBARS_SIZEGRIP )
    } else retval = FALSE;

    return retval;
}

void
StatusBar_onPostCreate(NOTXSPROC HWND myhandle, LPPERLWIN32GUI_CREATESTRUCT perlcs) {

    if(perlcs->clrBackground != CLR_INVALID) {
        SendMessage(myhandle, SB_SETBKCOLOR, (WPARAM) 0, (LPARAM) perlcs->clrBackground);
        perlcs->clrBackground = CLR_INVALID;  // Don't Store
    }
}

BOOL
StatusBar_onParseEvent(NOTXSPROC char *name, int* eventID) {

    return FALSE;
}

int
StatusBar_onEvent (NOTXSPROC LPPERLWIN32GUI_USERDATA perlud, UINT uMsg, WPARAM wParam, LPARAM lParam) {

    int PerlResult = 1;

    return PerlResult;
}

MODULE = Win32::GUI::StatusBar      PACKAGE = Win32::GUI::StatusBar

PROTOTYPES: DISABLE

#pragma message( "*** PACKAGE Win32::GUI::StatusBar..." )

    ###########################################################################
    # (@)METHOD:GetBorders()
    # Gets the border values for the status bar. Returns an array containing
    # width of the horizontal border, width of the vertical border, and the
    # width of the border between parts.
    #
void
GetBorders(handle)
    HWND handle
PREINIT:
    int aBorders [3];
PPCODE:
    if(SendMessage(handle, SB_GETBORDERS, (WPARAM) 0, (LPARAM) aBorders) == TRUE) {
        EXTEND(SP,3);
        XST_mIV(0,aBorders[0]);
        XST_mIV(1,aBorders[1]);
        XST_mIV(2,aBorders[2]);
        XSRETURN(3);
    }
    else {
        XSRETURN_UNDEF;
    }

    ###########################################################################
    # (@)METHOD:GetIcon(PART)
    # Retrieves the icon for a part in a status bar. 
HICON
GetIcon(handle, index)
    HWND handle
    WPARAM index
CODE:
    RETVAL = (HICON) SendMessage(handle, SB_GETICON, index, 0);
OUTPUT:
    RETVAL

    ###########################################################################
    # (@)METHOD:GetParts()
    # Retrieves a count of the parts in a status window. 
    # In Array context, return an list of coordinates for the current parts.
    # A value of -1 in the final coordinate means the last part will expand rightwards to fill the statusbar.
void
GetParts(handle)
    HWND handle
PREINIT:
    int aWidths [256];
    int count;
PPCODE:
    count = (int) SendMessage(handle, SB_GETPARTS, (WPARAM) 256, (LPARAM) aWidths);
    if(GIMME_V == G_ARRAY) {
        EXTEND(SP, count);
        for(int i = 0; i < count; i++) {
            XST_mIV(i, aWidths[i]);
        }
        XSRETURN(count);
    }
    else {
        EXTEND(SP, 1);
        XST_mIV(0, count);
        XSRETURN(1);
    }

    ###########################################################################
    # (@)METHOD:GetRect(part)
    # Gets the bounding rectangle for the given part of the status bar. Returns
    # left, top, right, bottom co-ordinates, or undef on failure. This is useful
    # for drawing in the status bar.
    #
void
GetRect(handle,part)
    HWND handle
    int part
PREINIT:
    RECT Rect;
PPCODE:
    if(SendMessage(handle, SB_GETRECT, (WPARAM) part, (LPARAM) &Rect) == TRUE) {
        EXTEND(SP, 4);
        XST_mIV(0,Rect.left);
        XST_mIV(1,Rect.top);
        XST_mIV(2,Rect.right);
        XST_mIV(3,Rect.bottom);
        XSRETURN(4);
    }
    else {
        XSRETURN_UNDEF;
    }

    ###########################################################################
    # (@)METHOD:GetText(part)
    # Retrieves the text from the specified part of a status window. 
    # In array context, return an array (TEXT,STYLE)
void
GetText(handle,part)
    HWND handle
    int part
PPCODE:
    int gettextlength = (INT) SendMessage(handle, SB_GETTEXTLENGTH, (WPARAM) part, (LPARAM) 0); 

    short length = (short) LOWORD(gettextlength);
    short style  = (short) HIWORD(gettextlength);

    char * text = (char *) safemalloc(length + 1);
    SendMessage(handle, SB_GETTEXT, (WPARAM) part, (LPARAM) text);

    if(GIMME_V == G_ARRAY) {
        EXTEND(SP, 2);
        XST_mPV(0, text);
        safefree(text);
        XST_mIV(1, (I32) style);
        XSRETURN(2);
    }
    else {
        EXTEND(SP, 1);
        XST_mPV(0, text);
        safefree(text);
        XSRETURN(1);
    }

    ###########################################################################
    # (@)METHOD:GetTextLength(part)
    # Retrieves the text from the specified part of a status window. 
    # In array context, return an array (LENGTH,STYLE)
void
GetTextLength(handle,part)
    HWND handle
    int part
PPCODE:
    int gettextlength = (INT) SendMessage(handle, SB_GETTEXTLENGTH, (WPARAM) part, (LPARAM) 0); 

    short length = (short) LOWORD(gettextlength);
    short style  = (short) HIWORD(gettextlength);

    if(GIMME_V == G_ARRAY) {
        EXTEND(SP, 2);
        XST_mIV(0, (I32) length);
        XST_mIV(1, (I32) style);
        XSRETURN(2);
    }
    else {
        EXTEND(SP, 1);
        XST_mIV(0, (I32) length);
        XSRETURN(1);
    }

    ###########################################################################
    # (@)METHOD:GetTipText(part)
    # Retrieves the tooltip text for a part in a status bar.
void
GetTipText(handle,part)
    HWND handle
    int part
PREINIT:
    char buffer [256];
PPCODE:
    SendMessage(handle, SB_GETTIPTEXT, (WPARAM) MAKEWPARAM(part, 255), (LPARAM) buffer);
    EXTEND(SP, 1);
    XST_mPV(0, buffer);
    XSRETURN(1);    

    ###########################################################################
    # (@)METHOD:GetUnicodeFormat()
    # Retrieves the UNICODE character format flag for the control.
BOOL
GetUnicodeFormat(handle)
    HWND handle
CODE:
    RETVAL = (BOOL) SendMessage(handle, SB_GETUNICODEFORMAT, 0, 0);
OUTPUT:
    RETVAL

    ###########################################################################
    # (@)METHOD:IsSimple()
    # Checks a status bar control to determine if it is in simple mode.
BOOL
IsSimple(handle)
    HWND handle
CODE:
    RETVAL = (BOOL) SendMessage(handle, SB_ISSIMPLE, 0, 0);
OUTPUT:
    RETVAL

    ###########################################################################
    # (@)METHOD:SetBkColor([color])
    # Sets the background color of the status bar. If no color is given,
    # it sets the background color to the default background color.
    #
void
SetBkColor(handle, color = CLR_DEFAULT)
    HWND     handle
    COLORREF color
CODE:
    SendMessage(handle,SB_SETBKCOLOR,(WPARAM) 0,(LPARAM) color);

    ###########################################################################
    # (@)METHOD:SetIcon(part,[icon])
    # (@)METHOD:Icon(part,[icon])
    # Sets or unsets the icon for a particular part of the status bar. If icon
    # is set to 0 or less, the icon for the specified part of the status bar is
    # removed. icon should be a Win32::GUI::Icon object.
    #
BOOL
SetIcon(handle,part,icon=NULL)
    HWND handle
    int part
    HICON icon
ALIAS:
    Win32::GUI::StatusBar::Icon = 1
CODE:
    RETVAL = SendMessage(handle, SB_SETICON, (WPARAM) part, (LPARAM) icon);
OUTPUT:
    RETVAL

    ###########################################################################
    # (@)METHOD:SetMinHeight(height)
    # Sets the minimum height of a status window's drawing area, and redraws
    # the status bar.
    #
    # The minimum height produced will be: height + (2 * vertical border width)
    #
void
SetMinHeight(handle,height)
    HWND handle
    int height
CODE:
    SendMessage(handle, SB_SETMINHEIGHT, (WPARAM) height, (LPARAM) 0);
    SendMessage(handle, WM_SIZE, (WPARAM) 0, (LPARAM) 0);

    ###########################################################################
    # (@)METHOD:SetParts(x1,[x2, x3...])
    # Sets the number of parts in a status window and the coordinate of the right edge of each part. 

LRESULT
SetParts(handle, part, ...)
    HWND handle
    UINT part
PREINIT:
    int     aWidths [256];
CODE:
    for(int i = 1; i < items; i++) {
        aWidths[i - 1] = (int) SvIV(ST(i));
    }
    RETVAL = SendMessage(handle, SB_SETPARTS, (WPARAM) items - 1, (LPARAM) aWidths);
OUTPUT:
    RETVAL

    ###########################################################################
    # (@)METHOD:SetText(part,text,[type=0])
    # Sets the text in the specified part of a status window. 
    # Type of drawing operation :
    #   0 = The text is drawn with a border to appear lower than the plane of the window. 
    #   SBT_NOBORDERS = The text is drawn without borders. 
    #   SBT_OWNERDRAW = The text is drawn by the parent window. 
    #   SBT_POPOUT = The text is drawn with a border to appear higher than the plane of the window. 
    #   SBT_RTLREADING = Displays text using right-to-left reading order on Hebrew or Arabic systems. 

LRESULT
SetText(handle, part, text, type=0)
    HWND handle
    UINT part
    LPTSTR text
    UINT type
CODE:
    RETVAL = SendMessage(handle, SB_SETTEXT , (WPARAM) part | type, (LPARAM) text);
OUTPUT:
    RETVAL

    ###########################################################################
    # (@)METHOD:SetTipText(part,string)
    # (@)METHOD:Tip(part,string)
    # Sets the tooltip text for a particular part of the status bar.
    #
    # From SDK documentation:
    # This ToolTip text is displayed in two situations:
    # When the corresponding pane in the status bar contains only an icon.
    # When the corresponding pane in the status bar contains text that is
    # truncated due to the size of the pane.
void
SetTipText(handle,part,text)
    HWND    handle
    int     part
    LPCTSTR text
ALIAS:
    Win32::GUI::StatusBar::Tip = 1
CODE:
    SendMessage(handle, SB_SETTIPTEXT, (WPARAM) part, (LPARAM) text);

    ###########################################################################
    # (@)METHOD:SetUnicodeFormat()
    # Sets the UNICODE character format flag for the control.
LRESULT
SetUnicodeFormat(handle)
    HWND handle
CODE:
    RETVAL = SendMessage(handle, SB_SETUNICODEFORMAT, 0, 0);
OUTPUT:
    RETVAL

    ###########################################################################
    # (@)METHOD:Simple([simplemode])
    # If simplemode is not 0, turns simple mode on. Otherwise, turns simple
    # mode off. Simple mode means the statusbar just shows text, with only one
    # partition.
    #
    # Returns the status of simple mode (0 = off, non-zero = on)
LRESULT
Simple(handle, mode=0)
    HWND handle
    BOOL mode
CODE:
    if(items == 2) {
        SendMessage(handle, SB_SIMPLE, (WPARAM) mode, (LPARAM) 0);
    }
    RETVAL = SendMessage(handle, SB_ISSIMPLE, (WPARAM) 0, (LPARAM) 0);
OUTPUT:
    RETVAL

    ###########################################################################
    ###########################################################################
    ###########################################################################

    ###########################################################################
    # (@)METHOD:Parts([x1, x2, x3...])
    # Divides the statusbar into sections. The list of co-ordinates define the
    # right-hand edge of each part.
    #
    # This method will return a list of co-ordinates for the current parts.
    # A value of -1 in the final co-ordinate means the last part will
    # expand rightwards to fill the statusbar.
LRESULT
Parts(handle,...)
    HWND handle
PREINIT:
    int     aWidths [256];
CODE:
    if(items > 1) {
        for(int i = 1; i < items; i++) {
            aWidths[i - 1] = (int) SvIV(ST(i));
        }
        SendMessage(handle, SB_SETPARTS, (WPARAM) items - 1, (LPARAM) aWidths);
    }

    RETVAL = (int) SendMessage(handle, SB_GETPARTS, (WPARAM) 256, (LPARAM) aWidths);
    if(GIMME_V == G_ARRAY) {
        EXTEND(SP, RETVAL);
        for(int i = 0; i < RETVAL; i++) {
        XST_mIV(i, aWidths[i]);
    }
        XSRETURN(RETVAL);
    }
OUTPUT:
    RETVAL

    ###########################################################################
    # (@)METHOD:PartText(part,[string,[flags]])
    # Sets or gets the text in a particular part of the status bar.
    #
    # Flags are as follows:
    #   0
    #        The text is drawn with a border to appear lower than the plane of
    #        the window.
    #
    #   SBT_NOBORDERS = 256
    #        The text is drawn without borders.
    #
    #   SBT_POPOUT = 512
    #        The text is drawn with a border to appear higher than the plane of
    #        the window.
    #
    #   SBT_RTLREADING = 1024
    #        The text will be displayed in the opposite direction to the text
    #        in the parent window.
    #
    #   SBT_OWNERDRAW = 4096
    #        The text is drawn by the parent window.
    #
    # When called with no string or flags, in scalar context the method will
    # return the text string in the specified part of the status bar. In array
    # context, the method will return the text string and the style flags of
    # the text in the specified part.
    #
void
PartText(handle,part,...)
    HWND handle
    int part
PREINIT:
    LRESULT gettextlength;
    short length;
    short style;
    char* text;
CODE:
    if(items == 4) {
        if(SendMessage(handle, SB_SETTEXT, (WPARAM) part | SvIV(ST(3)), (LPARAM) (LPCTSTR) SvPV_nolen(ST(2))) != TRUE)
            XSRETURN_YES;
    }
    else if (items == 3) {
        if(SendMessage(handle, SB_SETTEXT, (WPARAM) part, (LPARAM) (LPCTSTR) SvPV_nolen(ST(2))) == TRUE)
            XSRETURN_YES;
    }
    else if (items == 2) {
        gettextlength = SendMessage(handle, SB_GETTEXTLENGTH, (WPARAM) part, (LPARAM) 0);
        
        length = (short) LOWORD(gettextlength);
        style  = (short) HIWORD(gettextlength);

        text = (char *) safemalloc(length + 1);
        SendMessage(handle, SB_GETTEXT, (WPARAM) part, (LPARAM) text);

        if(GIMME_V == G_ARRAY) {
            EXTEND(SP, 2);
            XST_mPV(0, text);
            safefree(text);
            XST_mIV(1, (I32) style);
            XSRETURN(2);
        }
        else {
            EXTEND(SP, 1);
            XST_mPV(0, text);
            safefree(text);
            XSRETURN(1);
        }
    }
    XSRETURN_NO;
