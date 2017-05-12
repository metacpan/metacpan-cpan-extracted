    /*
    ###########################################################################
    # (@)PACKAGE:Win32::GUI::Textfield
    #
    # $Id: Textfield.xs,v 1.10 2010/04/08 21:25:29 jwgui Exp $
    #
    ###########################################################################
    */

#include "GUI.h"


void
Textfield_onPreCreate(NOTXSPROC LPPERLWIN32GUI_CREATESTRUCT perlcs) {

    perlcs->cs.lpszClass = "EDIT";
    perlcs->cs.style = WS_VISIBLE | WS_CHILD | WS_BORDER | ES_LEFT | ES_AUTOHSCROLL | ES_AUTOVSCROLL; // evtl. DS_3DLOOK?
    perlcs->cs.dwExStyle = WS_EX_CLIENTEDGE;
}

BOOL
Textfield_onParseOption(NOTXSPROC char *option, SV* value, LPPERLWIN32GUI_CREATESTRUCT perlcs) {
    BOOL retval;

    if(strcmp(option, "-align") == 0) {
        if(strcmp(SvPV_nolen(value), "left") == 0) {
            SwitchBit(perlcs->cs.style, ES_LEFT, 1);
            SwitchBit(perlcs->cs.style, ES_CENTER, 0);
            SwitchBit(perlcs->cs.style, ES_RIGHT, 0);
        } else if(strcmp(SvPV_nolen(value), "center") == 0) {
            SwitchBit(perlcs->cs.style, ES_LEFT, 0);
            SwitchBit(perlcs->cs.style, ES_CENTER, 1);
            SwitchBit(perlcs->cs.style, ES_RIGHT, 0);
        } else if(strcmp(SvPV_nolen(value), "right") == 0) {
            SwitchBit(perlcs->cs.style, ES_LEFT, 0);
            SwitchBit(perlcs->cs.style, ES_CENTER, 0);
            SwitchBit(perlcs->cs.style, ES_RIGHT, 1);
        } else {
            W32G_WARN("Win32::GUI: Invalid value for -align!");
        }
    } else if(strcmp(option, "-multiline") == 0) {
        if(SvIV(value)) {
            SwitchBit(perlcs->cs.style, ES_MULTILINE, 1);
            SwitchBit(perlcs->cs.style, ES_AUTOHSCROLL, 0);
        } else {
            SwitchBit(perlcs->cs.style, ES_MULTILINE, 0);
            SwitchBit(perlcs->cs.style, ES_AUTOHSCROLL, 1);
        }
    } else if BitmaskOptionValue("-keepselection", perlcs->cs.style, ES_NOHIDESEL)
    } else if BitmaskOptionValue("-readonly",      perlcs->cs.style, ES_READONLY)
    } else if BitmaskOptionValue("-password",      perlcs->cs.style, ES_PASSWORD)
    } else if BitmaskOptionValue("-lowercase",     perlcs->cs.style, ES_LOWERCASE)
    } else if BitmaskOptionValue("-uppercase",     perlcs->cs.style, ES_UPPERCASE)
    } else if BitmaskOptionValue("-autohscroll",   perlcs->cs.style, ES_AUTOHSCROLL)
    } else if BitmaskOptionValue("-autovscroll",   perlcs->cs.style, ES_AUTOVSCROLL)
    } else if BitmaskOptionValue("-number",        perlcs->cs.style, ES_NUMBER)
    } else if BitmaskOptionValue("-wantreturn",    perlcs->cs.style, ES_WANTRETURN)
    } else retval = FALSE;

    return retval;
}

void
Textfield_onPostCreate(NOTXSPROC HWND myhandle, LPPERLWIN32GUI_CREATESTRUCT perlcs) {
}

BOOL
Textfield_onParseEvent(NOTXSPROC char *name, int* eventID) {

    BOOL retval = TRUE;

         if Parse_Event("GotFocus",   PERLWIN32GUI_NEM_GOTFOCUS)
    else if Parse_Event("LostFocus",  PERLWIN32GUI_NEM_LOSTFOCUS)
    else if Parse_Event("Change",     PERLWIN32GUI_NEM_CONTROL1)
    else if Parse_Event("Anonymous",  PERLWIN32GUI_NEM_CONTROL2)
    else if Parse_Event("Scroll",     PERLWIN32GUI_NEM_CONTROL3)
    else if Parse_Event("MaxText",    PERLWIN32GUI_NEM_CONTROL4)
    else if Parse_Event("Update",     PERLWIN32GUI_NEM_CONTROL5)
    else retval = FALSE;

    return retval;
}

int
Textfield_onEvent (NOTXSPROC LPPERLWIN32GUI_USERDATA perlud, UINT uMsg, WPARAM wParam, LPARAM lParam) {

    int PerlResult = 1;

    if ( uMsg == WM_COMMAND ) {

        switch(HIWORD(wParam)) {
        case EN_SETFOCUS:
            /*
             * (@)EVENT:GotFocus()
             * Sent when the control is activated.
             * (@)APPLIES_TO:Textfield, RichEdit
             */
            PerlResult = DoEvent(NOTXSCALL perlud, PERLWIN32GUI_NEM_GOTFOCUS, "GotFocus", -1 );
            break;
        case EN_KILLFOCUS:
            /*
             * (@)EVENT:LostFocus()
             * Sent when the control is deactivated.
             * (@)APPLIES_TO:Textfield, RichEdit
             */
            PerlResult = DoEvent(NOTXSCALL perlud, PERLWIN32GUI_NEM_LOSTFOCUS, "LostFocus", -1 );
            break;
        case EN_CHANGE:
            /*
             * (@)EVENT:Change()
             * Sent when the text in the field is changed by the user.
             * (@)APPLIES_TO:Textfield, RichEdit
             */
            PerlResult = DoEvent(NOTXSCALL perlud, PERLWIN32GUI_NEM_CONTROL1, "Change", -1 );
            break;
        case EN_HSCROLL:
        case EN_VSCROLL:
            /*
             * (@)EVENT:Scroll(SCROLLBAR)
             * Sent when one of the window scrollbars is moved. SCROLLBAR identifies
             * which bar was moved, 0 for horizontal and 1 for vertical.
             * (@)APPLIES_TO:Textfield, RichEdit
             */
            PerlResult = DoEvent(NOTXSCALL perlud, PERLWIN32GUI_NEM_CONTROL3, "Scroll",
                                 PERLWIN32GUI_ARGTYPE_INT, (uMsg == EN_HSCROLL ? 0 : 1),
                                 -1 );
            break;
        case EN_MAXTEXT :
            /*
             * (@)EVENT:MaxText()
             * Sent when text has exceeded the specified number of characters
             * (@)APPLIES_TO:Textfield, RichEdit
             */
            PerlResult = DoEvent(NOTXSCALL perlud, PERLWIN32GUI_NEM_CONTROL4, "MaxText", -1 );
            break;
        case EN_UPDATE:
            /*
             * (@)EVENT:Update()
             * Sent when an edit control is about to display altered text.
             * (@)APPLIES_TO:Textfield, RichEdit
             */
            PerlResult = DoEvent(NOTXSCALL perlud, PERLWIN32GUI_NEM_CONTROL5, "Update", -1 );
            break;

        default:
            PerlResult = DoEvent(NOTXSCALL perlud, PERLWIN32GUI_NEM_CONTROL2, "Anonymous",
                PERLWIN32GUI_ARGTYPE_INT, HIWORD(wParam),
                -1 );
            break;

        }
    }

    return PerlResult;
}

   /*
    ###########################################################################
    # (@)PACKAGE:Win32::GUI::Textfield
    ###########################################################################
    */

MODULE = Win32::GUI::Textfield     PACKAGE = Win32::GUI::Textfield

PROTOTYPES: DISABLE

#pragma message( "*** PACKAGE Win32::GUI::Textfield..." )

    ###########################################################################
    # (@)METHOD:CanUndo()
    # Determine whether an Textfield can be undone
LRESULT
CanUndo(handle)
    HWND handle
ALIAS:
    Win32::GUI::RichEdit::CanUndo = 1
CODE:
    RETVAL = SendMessage(handle, EM_CANUNDO, 0, 0);
OUTPUT:
    RETVAL

    ###########################################################################
    # (@)METHOD:CharFromPos(X, Y)
    # Returns a two elements array identifying the character nearest to the
    # position specified by X and Y.
    # The array contains the zero-based index of the character and its line
    # index.
void
CharFromPos(handle,x,y)
    HWND handle
    int x
    int y
PREINIT:
    LRESULT cfp;
PPCODE:
    cfp = SendMessage(handle, EM_CHARFROMPOS, 0, (LPARAM) MAKELPARAM(x, y));
    if(cfp == -1) {
        XSRETURN_UNDEF;
    } else {
        EXTEND(SP, 2);
        XST_mIV(0, LOWORD(cfp));
        XST_mIV(1, HIWORD(cfp));
        XSRETURN(2);
    }

    ###########################################################################
    # (@)METHOD:EmptyUndoBuffer()
    # Reset the undo flag of an Textfield.
LRESULT
EmptyUndoBuffer(handle)
    HWND handle
ALIAS:
    Win32::GUI::RichEdit::EmptyUndoBuffer = 1
CODE:
    RETVAL = SendMessage(handle, EM_EMPTYUNDOBUFFER, 0, 0);
OUTPUT:
    RETVAL

    ###########################################################################
    # (@)METHOD:FmtLines(FLAG)
    # Set the inclusion flag of soft line break characters on or off within a multiline TextField.
    # A soft line break consists of two carriage returns and a linefeed and is inserted at the end of a line that is broken because of word wrapping.

LRESULT
FmtLines(handle, value)
    HWND   handle
    WPARAM value
CODE:
    RETVAL = SendMessage(handle, EM_FMTLINES, value, 0);
OUTPUT:
    RETVAL


    ###########################################################################
    # (@)METHOD:GetFirstVisibleLine()
    # Return the uppermost visible line.
LRESULT
GetFirstVisibleLine(handle)
    HWND handle
ALIAS:
    Win32::GUI::Textfield::FirstVisibleLine = 1
    Win32::GUI::RichEdit::GetFirstVisibleLine = 2
    Win32::GUI::RichEdit::FirstVisibleLine = 3
CODE:
    RETVAL = SendMessage(handle, EM_GETFIRSTVISIBLELINE, 0, 0);
OUTPUT:
    RETVAL

    # EM_GETHANDLE
    # EM_GETIMESTATUS

    ###########################################################################
    # (@)METHOD:GetLimitText()
    # Return current text limit, in characters.
LRESULT
GetLimitText(handle)
    HWND handle
ALIAS:
    Win32::GUI::RichEdit::GetLimitText = 1
CODE:
    RETVAL = SendMessage(handle, EM_GETLIMITTEXT, 0, 0);
OUTPUT:
    RETVAL

    ###########################################################################
    # (@)METHOD:GetLine(LINE)
    # Get a line of text.
    #  LINE: zero based index to the line to be retrieved
    #
    # Returns the text of the line.  Returns undef if LINE is
    # greater than the number of lines in the Textfied.
void
GetLine(handle, line)
    HWND handle
    WPARAM line
ALIAS:
    Win32::GUI::RichEdit::GetLine = 1
CODE:
    LONG   index;
    WORD   size;
    LPTSTR pBuf;

    index = (LONG)SendMessage(handle, EM_LINEINDEX, line, 0);
    if (index < 0) { /* -1 if line greater than number of lines in control */
        XSRETURN_UNDEF;
    }

    size = (WORD)SendMessage(handle, EM_LINELENGTH, (WPARAM)index, 0);
    /* we don't check the error condition of size == 0, as we have
     * already checked the return value from EM_LINEINDEX, and have a valid
     * index.  A return value of zero means we have an empty line, and
     * should return that.
     */

    /* ensure buffer is big enough to hold a WORD */
    if (size < sizeof(WORD) ) {
        size = (sizeof(WORD)/sizeof(TCHAR));
    }
    /* allocate buffer, adding one for the NUL termination */
    /* TODO: The strategy used here results in the buffer being
    * copied twice: once from the textfield to pBuf, and then
    * a second time from pBuf into the SV.  We should create
    * an SV of the correct size, and pass the pointer to it's
    * buffer to EM_GETLINE
    */
    New(0, pBuf, (int)(size+1), TCHAR);

    /* put the size into the first word of the buffer */
    *((WORD*)pBuf) = size;

    /* get the text */
    size = (WORD)SendMessage(handle, EM_GETLINE, line, (LPARAM)pBuf);
    /* Again, we don't check the error condition of size == 0, as we have
     * already checked the return value from EM_LINEINDEX, and have a valid
     * line.  A return value of zero means we have an empty line, and
     * should return that.
     */

    /* ensure we are NUL terminated  - this is NOT done by EM_GETLINE */
    pBuf[size] = 0;

    /* return the text */
    EXTEND(SP, 1);
    XST_mPV(0, pBuf);
    Safefree(pBuf);
    XSRETURN(1);

    ###########################################################################
    # (@)METHOD:GetLineCount()
    # Return the number of lines in a multiline Textfield.

LRESULT
GetLineCount(handle)
    HWND handle
ALIAS:
    Win32::GUI::RichEdit::GetLineCount = 1
CODE:
    RETVAL = SendMessage(handle, EM_GETLINECOUNT, 0, 0);
OUTPUT:
    RETVAL

    ###########################################################################
    # (@)METHOD:GetMargins()
    # Return an array with right and left margins.
void
GetMargins(handle)
    HWND handle
ALIAS:
    Win32::GUI::RichEdit::GetMargins = 1
PREINIT:
    LRESULT res;
PPCODE:
    res = SendMessage(handle, EM_GETMARGINS, 0, 0);
    EXTEND(SP, 2);
    XST_mIV(0, LOWORD(res));
    XST_mIV(1, HIWORD(res));
    XSRETURN(2);

    ###########################################################################
    # (@)METHOD:GetModify()
    # Determine whether the content of a Textfield has been modified.

LRESULT
GetModify(handle)
    HWND handle
ALIAS:
    Win32::GUI::RichEdit::GetModify = 1
CODE:
    RETVAL = SendMessage(handle, EM_GETMODIFY, 0, 0);
OUTPUT:
    RETVAL

    ###########################################################################
    # (@)METHOD:GetPasswordChar()
    # Return the password character displayed .

LRESULT
GetPasswordChar(handle)
    HWND handle
CODE:
    RETVAL = SendMessage(handle, EM_GETPASSWORDCHAR, 0, 0);
OUTPUT:
    RETVAL

    ###########################################################################
    # (@)METHOD:GetRect()
    # Return formatting rectangle is the limiting rectangle of the text.

void
GetRect(handle)
    HWND handle
ALIAS:
    Win32::GUI::RichEdit::GetRect = 1
PREINIT:
    RECT myRect;
PPCODE:
    SendMessage(handle, EM_GETRECT, 0, (LPARAM) &myRect);
    EXTEND(SP, 4);
    XST_mIV(0, myRect.left);
    XST_mIV(1, myRect.top);
    XST_mIV(2, myRect.right);
    XST_mIV(3, myRect.bottom);
    XSRETURN(4);

    ###########################################################################
    # (@)METHOD:GetSel()
    # (@)METHOD:Selection()
    # Returns a 2 item list giving the index of the start and end of the current
    # selection

void
GetSel(handle)
    HWND handle
ALIAS:
    Win32::GUI::Textfield::Selection = 1
PREINIT:
    DWORD start;
    DWORD end;
PPCODE:
    SendMessage(handle, EM_GETSEL, (WPARAM) &start, (LPARAM) &end);
    EXTEND(SP, 2);
    XST_mIV(0, (long) start);
    XST_mIV(1, (long) end);
    XSRETURN(2);

    ###########################################################################
    # (@)METHOD:GetThumb()
    # Return  the position of the scroll box (thumb) in a multiline Textfield.

LRESULT
GetThumb(handle)
    HWND handle
ALIAS:
    Win32::GUI::RichEdit::GetThumb = 1
CODE:
    RETVAL = SendMessage(handle, EM_GETTHUMB, 0, 0);
OUTPUT:
    RETVAL

    # TODO : EM_GETWORDBREAKPROC

    # EM_LIMITTEXT = EM_SETLIMITTEXT

    ###########################################################################
    # (@)METHOD:LineFromChar(INDEX)
LRESULT
LineFromChar(handle,index)
    HWND handle
    WPARAM index
CODE:
    RETVAL = SendMessage(handle, EM_LINEFROMCHAR, index, 0);
OUTPUT:
    RETVAL

    ###########################################################################
    # (@)METHOD:LineIndex(INDEX)
LRESULT
LineIndex(handle,index)
    HWND handle
    WPARAM index
ALIAS:
    Win32::GUI::RichEdit::LineIndex = 1
CODE:
    RETVAL = SendMessage(handle, EM_LINEINDEX, index, 0);
OUTPUT:
    RETVAL

    ###########################################################################
    # (@)METHOD:LineLength(INDEX)
LRESULT
LineLength(handle,index)
    HWND handle
    WPARAM index
ALIAS:
    Win32::GUI::RichEdit::LineLength = 1
CODE:
    RETVAL = SendMessage(handle, EM_LINELENGTH, index, 0);
OUTPUT:
    RETVAL

    ###########################################################################
    # (@)METHOD:LineScroll(X,Y)
LRESULT
LineScroll(handle,x,y)
    HWND handle
    WPARAM x
    WPARAM y
ALIAS:
    Win32::GUI::RichEdit::LineScroll = 1
CODE:
    RETVAL = SendMessage(handle, EM_LINESCROLL, x, (LPARAM) y);
OUTPUT:
    RETVAL

    ###########################################################################
    # (@)METHOD:PosFromChar(INDEX)
LRESULT
PosFromChar(handle,index)
    HWND handle
    WPARAM index
CODE:
    RETVAL = SendMessage(handle, EM_POSFROMCHAR, index, 0);
OUTPUT:
    RETVAL

    ###########################################################################
    # (@)METHOD:ReplaceSel(STRING, [FLAG])
    # Replaces the current selection with the given STRING.
    # The optional FLAG parameter can be set to zero to tell the control that
    # the operation cannot be undone; see also Undo().
LRESULT
ReplaceSel(handle,string,flag=TRUE)
    HWND handle
    LPCTSTR string
    BOOL flag
ALIAS:
    Win32::GUI::RichEdit::ReplaceSel = 1
CODE:
    RETVAL = SendMessage(handle, EM_REPLACESEL, (WPARAM) flag, (LPARAM) string);
OUTPUT:
    RETVAL

    ###########################################################################
    # (@)METHOD:Scroll(COMMAND | LINE | HORIZONTAL, VERTICAL)
LRESULT
Scroll(handle, line, otherdirection=0)
    SV* handle
    SV* line
    DWORD otherdirection
ALIAS:
    Win32::GUI::RichEdit::Scroll = 1
PREINIT:
    HWND hwnd;
    WPARAM wparam;
    char *arg;
CODE:
    hwnd = handle_From(NOTXSCALL handle);
    if(items == 2) {
        if(SvPOK(line)) {
            arg = strlwr( SvPV_nolen(line) );

            if(0 == strcmp( arg, "bottom" )) {
                RETVAL = SendMessage( hwnd, EM_GETLINECOUNT, 0, 0 );
                wparam = RETVAL;
                RETVAL = SendMessage( hwnd, EM_GETFIRSTVISIBLELINE, 0, 0);
                wparam -= RETVAL;
                RETVAL = SendMessage( hwnd, EM_LINESCROLL, 0, wparam);
            } else if(0 == strcmp( arg, "top" )) {
                wparam = SendMessage( hwnd, EM_GETFIRSTVISIBLELINE, 0, 0);
                RETVAL = SendMessage( hwnd, EM_LINESCROLL, 0, (LPARAM) -((INT)wparam));
            } else {
                if(0 == strcmp( arg, "up" )) {
                    wparam = SB_LINEUP;
                } else if(0 == strcmp( arg, "down" )
                ||        0 == strcmp( arg, "dn" )) {
                    wparam = SB_LINEDOWN;
                } else if(0 == strcmp( arg, "pageup" )
                ||        0 == strcmp( arg, "pgup" )) {
                    wparam = SB_PAGEUP;
                } else if(0 == strcmp( arg, "pagedown" )
                ||        0 == strcmp( arg, "pagedn" )
                ||        0 == strcmp( arg, "pgdown" )
                ||        0 == strcmp( arg, "pgdn")) {
                    wparam = SB_PAGEDOWN;
                }
                RETVAL = SendMessage(
                    hwnd, EM_SCROLL, (WPARAM) wparam, (LPARAM) 0
                );
            }
        } else {
            RETVAL = SendMessage(
                hwnd, EM_LINESCROLL, 0, (WPARAM) SvIV(line)
            );
        }
    } else {
        if(sv_derived_from(handle, "Win32::GUI::RichEdit")) {
            RETVAL = SendMessage(
                hwnd, EM_LINESCROLL, 0, (WPARAM) otherdirection
            );
        } else {
            RETVAL = SendMessage(
                hwnd, EM_LINESCROLL, (LPARAM) SvIV(line), (WPARAM) otherdirection
            );
        }
    }
    SendMessage( hwnd , EM_SCROLLCARET, 0, 0);
OUTPUT:
    RETVAL

    ###########################################################################
    # (@)METHOD:ScrollCaret()

LRESULT
ScrollCaret(handle)
    HWND handle
ALIAS:
    Win32::GUI::RichEdit::ScrollCaret = 1
CODE:
    RETVAL = SendMessage(handle, EM_SCROLLCARET, 0, 0);
OUTPUT:
    RETVAL

    # TODO : EM_SETHANDLE
    # TODO : EM_SETIMESTATUS

    ###########################################################################
    # (@)METHOD:SetLimitText(SIZE)
LRESULT
SetLimitText(handle,index)
    HWND handle
    WPARAM index
ALIAS:
    Win32::GUI::RichEdit::SetLimitText = 1
CODE:
    RETVAL = SendMessage(handle, EM_SETLIMITTEXT, index, 0);
OUTPUT:
    RETVAL

    ###########################################################################
    # (@)METHOD:SetMargins([LEFT],[RIGHT])
LRESULT
SetMargins(handle,Left=0,Right=0)
    HWND handle
    int  Left
    int  Right
CODE:
    WPARAM flag = EC_USEFONTINFO;
    if (items == 2)
        flag = EC_LEFTMARGIN;
    else if (items == 3)
        flag = EC_LEFTMARGIN | EC_RIGHTMARGIN;
    RETVAL = SendMessage(handle, EM_SETMARGINS, flag, (LPARAM) MAKELONG(Left, Right));
OUTPUT:
    RETVAL

    ###########################################################################
    # (@)METHOD:SetModify(FLAG)

LRESULT
SetModify(handle,value)
    HWND handle
    WPARAM value
ALIAS:
    Win32::GUI::RichEdit::SetModify = 1
CODE:
    RETVAL = SendMessage(handle, EM_SETMODIFY, value, 0);
OUTPUT:
    RETVAL

    ###########################################################################
    # (@)METHOD:SetPasswordChar(CHAR)

LRESULT
SetPasswordChar(handle,value)
    HWND handle
    WPARAM value
CODE:
    RETVAL = SendMessage(handle, EM_SETPASSWORDCHAR, value, 0);
OUTPUT:
    RETVAL

    ###########################################################################
    # (@)METHOD:SetReadOnly(FLAG)

LRESULT
SetReadOnly(handle,value)
    HWND handle
    WPARAM value
ALIAS:
    Win32::GUI::RichEdit::SetReadOnly = 1
CODE:
    RETVAL = SendMessage(handle, EM_SETREADONLY, value, 0);
OUTPUT:
    RETVAL

    ###########################################################################
    # (@)METHOD:SetRect(LEFT,TOP,RIGHT,BOTTOM,[REDRAW])

void
SetRect(handle,left,top,right,bottom, flag=1)
    HWND handle
    int left
    int top
    int right
    int bottom
    int flag
PREINIT:
    RECT myRect;
PPCODE:
    myRect.left   = left;
    myRect.top    = top;
    myRect.right  = right;
    myRect.bottom = bottom;
    SendMessage(handle, (flag ? EM_SETRECT : EM_SETRECTNP), 0, (LPARAM) &myRect);

    ###########################################################################
    # (@)METHOD:SetSel(START,END)
    # (@)METHOD:Select(START, END)
    # Selects the specified range of characters.

LRESULT
SetSel(handle,start,end)
    HWND handle
    WPARAM start
    WPARAM end
ALIAS:
    Win32::GUI::Textfield::Select = 1
CODE:
    RETVAL = SendMessage(handle, EM_SETSEL, start, (LPARAM) end);
OUTPUT:
    RETVAL

    ###########################################################################
    # (@)METHOD:SetTabStops( ...)

LRESULT
SetTabStops(handle,tab,...)
    HWND handle
    UINT tab
CODE:
    DWORD * pBuf = (DWORD *) safemalloc(items * sizeof(DWORD));
    for (int i = 1; i < items; i++)
        pBuf[i] = (DWORD)SvIV(ST(i));
    RETVAL = SendMessage(handle, EM_SETTABSTOPS, items-1, (LPARAM) pBuf);
    safefree(pBuf);
OUTPUT:
    RETVAL

    # TODO : EM_SETWORDBREAKPROC


    ###########################################################################
    ###########################################################################
    ###########################################################################

    ###########################################################################
    # (@)METHOD:Undo()

BOOL
Undo(handle)
    HWND handle
ALIAS:
    Win32::GUI::RichEdit::Undo = 1
CODE:
    RETVAL = SendMessage(handle, WM_UNDO, 0, 0);
OUTPUT:
    RETVAL

    ###########################################################################
    # (@)METHOD:Clear()

BOOL
Clear(handle)
    HWND handle
ALIAS:
    Win32::GUI::RichEdit::Clear = 1
CODE:
    RETVAL = SendMessage(handle, WM_CLEAR, 0, 0);
OUTPUT:
    RETVAL

    ###########################################################################
    # (@)METHOD:Copy()

BOOL
Copy(handle)
    HWND handle
ALIAS:
    Win32::GUI::RichEdit::Copy = 1
CODE:
    RETVAL = SendMessage(handle, WM_COPY, 0, 0);
OUTPUT:
    RETVAL

    ###########################################################################
    # (@)METHOD:Cut()

BOOL
Cut(handle)
    HWND handle
ALIAS:
    Win32::GUI::RichEdit::Cut = 1
CODE:
    RETVAL = SendMessage(handle, WM_CUT, 0, 0);
OUTPUT:
    RETVAL

    ###########################################################################
    # (@)METHOD:Paste()

BOOL
Paste(handle)
    HWND handle
ALIAS:
    Win32::GUI::RichEdit::Paste = 1
CODE:
    RETVAL = SendMessage(handle, WM_PASTE, 0, 0);
OUTPUT:
    RETVAL

    ###########################################################################
    # (@)METHOD:CanPaste()
    # Text data availlable in clibboard for a Paste.
BOOL
CanPaste(handle)
    HWND handle
CODE:
    RETVAL = IsClipboardFormatAvailable(CF_TEXT);
OUTPUT:
    RETVAL


    ###########################################################################
    # (@)METHOD:ReadOnly([FLAG])
BOOL
ReadOnly(handle,...)
    HWND handle
CODE:
    if(items > 1)
        RETVAL = SendMessage(handle, EM_SETREADONLY, (WPARAM) (BOOL) SvIV(ST(1)), 0);
    else
        RETVAL = (((LONG)GetWindowLongPtr(handle, GWL_STYLE)) & ES_READONLY);
OUTPUT:
    RETVAL

    ###########################################################################
    # (@)METHOD:Modified([FLAG])
    # (@)METHOD:Modify([FLAG])
BOOL
Modify(handle,...)
    HWND handle
ALIAS :
    Win32::GUI::TextField::Modified = 1
CODE:
    if(items > 1)
        RETVAL = SendMessage(handle, EM_SETMODIFY, (WPARAM) (UINT) SvIV(ST(1)), 0);
    else
        RETVAL = SendMessage(handle, EM_GETMODIFY, 0, 0);
OUTPUT:
    RETVAL

    ###########################################################################
    # (@)METHOD:LimitText([CHARS])
    # (@)METHOD:MaxLength([CHARS])
LRESULT
LimitText(handle,value=0)
    HWND handle
    WPARAM value
ALIAS:
    Win32::GUI::Textfield::MaxLength = 1
CODE:
    if(items == 1) {
        RETVAL = SendMessage(handle, EM_GETLIMITTEXT, 0, 0);
    } else {
        RETVAL = SendMessage(handle, EM_SETLIMITTEXT, (WPARAM) value, 0);
    }
OUTPUT:
    RETVAL

    ###########################################################################
    # (@)METHOD:PasswordChar([CHAR])
LRESULT
PasswordChar(handle,passchar=0)
    HWND handle
    UINT passchar
CODE:
    if(items == 1) {
        RETVAL = SendMessage(handle, EM_GETPASSWORDCHAR, 0, 0);
    } else {
        RETVAL = SendMessage(handle, EM_SETPASSWORDCHAR, (WPARAM) passchar, 0);
    }
OUTPUT:
    RETVAL

    ###########################################################################
    # (@)METHOD:HaveSel()
    # Check if a selection is availlable.
BOOL
HaveSel(handle)
    HWND handle
PREINIT:
    DWORD start;
    DWORD end;
CODE:
    SendMessage(handle, EM_GETSEL, (WPARAM) &start, (LPARAM) &end);
    RETVAL = (start != end);
OUTPUT:
    RETVAL

    ###########################################################################
    # (@)METHOD:SelectAll()
LRESULT
SelectAll(handle)
    HWND handle
CODE:
    RETVAL = SendMessage(handle, EM_SETSEL, 0, -1);
OUTPUT:
    RETVAL

    ###########################################################################
    # (@)METHOD:Append(TEXT)
void
Append(handle, text)
    HWND handle
    char * text
PREINIT:
    int length;
CODE:
    length = GetWindowTextLength(handle);
    SendMessage(handle, EM_SETSEL, length, length);
    SendMessage(handle, EM_REPLACESEL, (WPARAM) TRUE, (LPARAM) text);
