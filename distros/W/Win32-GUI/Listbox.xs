    /*
    ###########################################################################
    # (@)PACKAGE:Win32::GUI::Listbox
    #
    # $Id: Listbox.xs,v 1.6 2006/03/16 21:31:42 robertemay Exp $
    #
    ###########################################################################
    */

#include "GUI.h"

void Listbox_onPreCreate(NOTXSPROC LPPERLWIN32GUI_CREATESTRUCT perlcs) {

    perlcs->cs.lpszClass = "LISTBOX";
    perlcs->cs.style = WS_VISIBLE | WS_CHILD | LBS_NOTIFY;
    perlcs->cs.dwExStyle = WS_EX_CLIENTEDGE;
}

BOOL
Listbox_onParseOption(NOTXSPROC char *option, SV* value, LPPERLWIN32GUI_CREATESTRUCT perlcs) {

    BOOL retval = TRUE;

    if(strcmp(option, "-multisel") == 0) {
        if(SvIV(value) == 0) {
            SwitchBit(perlcs->cs.style, LBS_MULTIPLESEL, 0);
            SwitchBit(perlcs->cs.style, LBS_EXTENDEDSEL, 0);
        } else if(SvIV(value) == 1) {
            SwitchBit(perlcs->cs.style, LBS_MULTIPLESEL, 1);
            SwitchBit(perlcs->cs.style, LBS_EXTENDEDSEL, 0);
        } else if(SvIV(value) == 2) {
            SwitchBit(perlcs->cs.style, LBS_MULTIPLESEL, 1);
            SwitchBit(perlcs->cs.style, LBS_EXTENDEDSEL, 1);
        } else {
            if(PL_dowarn) warn("Win32::GUI: Invalid value for -multisel!");
        }
    } else if BitmaskOptionValue("-sort",             perlcs->cs.style, LBS_SORT)
    } else if BitmaskOptionValue("-multicolumn",      perlcs->cs.style, LBS_MULTICOLUMN)
    } else if BitmaskOptionValue("-nointegralheight", perlcs->cs.style, LBS_NOINTEGRALHEIGHT)
    } else if BitmaskOptionValue("-noredraw",         perlcs->cs.style, LBS_NOREDRAW)
    } else if BitmaskOptionValue("-notify",           perlcs->cs.style, LBS_NOTIFY)
    } else if BitmaskOptionValue("-usetabstop",       perlcs->cs.style, LBS_USETABSTOPS)
    } else if BitmaskOptionValue("-disablenoscroll",  perlcs->cs.style, LBS_DISABLENOSCROLL)
    } else retval = FALSE;

    return retval;
}

void
Listbox_onPostCreate(NOTXSPROC HWND myhandle, LPPERLWIN32GUI_CREATESTRUCT perlcs) {
}

BOOL
Listbox_onParseEvent(NOTXSPROC char *name, int* eventID) {

    BOOL retval = TRUE;

         if Parse_Event("GotFocus",   PERLWIN32GUI_NEM_GOTFOCUS)
    else if Parse_Event("LostFocus",  PERLWIN32GUI_NEM_LOSTFOCUS)
    else if Parse_Event("DblClick",   PERLWIN32GUI_NEM_DBLCLICK)
    else if Parse_Event("Click",      PERLWIN32GUI_NEM_CLICK)
    else if Parse_Event("Anonymous",  PERLWIN32GUI_NEM_CONTROL1)
    else if Parse_Event("SelCancel",  PERLWIN32GUI_NEM_CONTROL2)    
    else if Parse_Event("SelChange",  PERLWIN32GUI_NEM_CONTROL3)    
    else retval = FALSE;

    return retval;
}

int
Listbox_onEvent (NOTXSPROC LPPERLWIN32GUI_USERDATA perlud, UINT uMsg, WPARAM wParam, LPARAM lParam) {

    int PerlResult = 1;

    if ( uMsg == WM_COMMAND ) {

        switch(HIWORD(wParam)) {
        case LBN_SETFOCUS:
            /*
             * (@)EVENT:GotFocus()
             * Sent when the control is activated.
             * (@)APPLIES_TO:Listbox
             */
            PerlResult = DoEvent(NOTXSCALL perlud, PERLWIN32GUI_NEM_GOTFOCUS, "GotFocus", -1 );
            break;
        case LBN_KILLFOCUS:
            /*
             * (@)EVENT:LostFocus()
             * Sent when the control is deactivated.
             * (@)APPLIES_TO:Listbox
             */
            PerlResult = DoEvent(NOTXSCALL perlud, PERLWIN32GUI_NEM_LOSTFOCUS, "LostFocus", -1 );
            break;
        case LBN_SELCHANGE:
            /*
             * (@)EVENT:Click()
             * DEPRECATED use SelChange event.
             * (@)APPLIES_TO:Listbox
             */
             // TODO: Click but not change ?
            PerlResult = DoEvent(NOTXSCALL perlud, PERLWIN32GUI_NEM_CLICK, "Click", -1 );
            /*
             * (@)EVENT:SelChange()
             * (@)APPLIES_TO:Listbox
             */
            PerlResult = DoEvent(NOTXSCALL perlud, PERLWIN32GUI_NEM_CONTROL3, "SelChange", -1 );
            break;
        case LBN_DBLCLK:
            /*
             * (@)EVENT:DblClick()
             * Sent when the user double clicks on the control.
             * (@)APPLIES_TO:Listbox
             */
            PerlResult = DoEvent(NOTXSCALL perlud, PERLWIN32GUI_NEM_DBLCLICK, "DblClick", -1 );
            break;
        case LBN_SELCANCEL:
            /*
             * (@)EVENT:SelCancel()
             * Sent when the user cancels the selection in a Listbox. 
             * (@)APPLIES_TO:Listbox
             */
            PerlResult = DoEvent(NOTXSCALL perlud, PERLWIN32GUI_NEM_CONTROL2, "SelCancel", -1 );
            break;       
        default:
            PerlResult = DoEvent(NOTXSCALL perlud, PERLWIN32GUI_NEM_CONTROL1, "Anonymous", 
                PERLWIN32GUI_ARGTYPE_INT, HIWORD(wParam),
                -1 );
            break;
        }

    }

    return PerlResult;
}

MODULE = Win32::GUI::Listbox        PACKAGE = Win32::GUI::Listbox

PROTOTYPES: DISABLE

#pragma message( "*** PACKAGE Win32::GUI::Listbox..." )

    ###########################################################################
    # (@)METHOD:AddFile(STRING)
    # Add the specified filename to a list box that contains a directory listing. 
LRESULT
AddFile(handle,string)
    HWND handle
    LPCTSTR string
CODE:
    RETVAL = SendMessage(handle, LB_ADDFILE, 0, (LPARAM) string);
OUTPUT:
    RETVAL

    ###########################################################################
    # (@)METHOD:AddString(STRING)
    # Add a string to a Listbox.
LRESULT
AddString(handle,string)
    HWND handle
    LPCTSTR string
CODE:
    RETVAL = SendMessage(handle, LB_ADDSTRING, 0, (LPARAM) string);
OUTPUT:
    RETVAL

    ###########################################################################
    # (@)METHOD:DeleteString(index)
    # (@)METHOD:RemoveItem(INDEX)
    # Removes the zero-based INDEX item from the Listbox.
LRESULT
DeleteString(handle,index)
    HWND handle
    int index
ALIAS:
    Win32::GUI::Listbox::RemoveItem = 1
CODE:
    RETVAL = SendMessage(handle, LB_DELETESTRING, (WPARAM) index, 0);
OUTPUT:
    RETVAL

    ###########################################################################
    # (@)METHOD:Dir(string,flag)
    # Add a list of filenames to a Listbox.
LRESULT
Dir(handle,string,flag)
    HWND handle
    LPCTSTR string
    UINT flag
CODE:
    RETVAL = SendMessage(handle, LB_DIR, (WPARAM) flag, (LPARAM) string);
OUTPUT:
    RETVAL

    ###########################################################################
    # (@)METHOD:FindString(STRING, [INDEX])
    # Find the first string in a list box that contains the specified prefix.
LRESULT
FindString(handle,string,index=-1)
    HWND handle
    LPCTSTR string
    long index
CODE:
    RETVAL = SendMessage(handle, LB_FINDSTRING, (WPARAM) index, (LPARAM) string);
OUTPUT:
    RETVAL

    ###########################################################################
    # (@)METHOD:FindStringExact(STRING, [INDEX])
    # Find the first Listbox string that matches the specified string.
LRESULT
FindStringExact(handle,string,index=-1)
    HWND handle
    LPCTSTR string
    long index
CODE:
    RETVAL = SendMessage(handle, LB_FINDSTRINGEXACT, (WPARAM) index, (LPARAM) string);
OUTPUT:
    RETVAL

    ###########################################################################
    # (@)METHOD:GetAnchorIndex()
    # Retrieve the index of the anchor item.
LRESULT
GetAnchorIndex(handle)
    HWND handle
CODE:
    RETVAL = SendMessage(handle, LB_GETANCHORINDEX, (WPARAM) 0, (LPARAM) 0);
OUTPUT:
    RETVAL

    ###########################################################################
    # (@)METHOD:GetCaretIndex()
    # Determine the index of the item that has the focus rectangle in a multiple-selection Listbox. 
LRESULT
GetCaretIndex(handle)
    HWND handle
CODE:
    RETVAL = SendMessage(handle, LB_GETCARETINDEX, (WPARAM) 0, (LPARAM) 0);
OUTPUT:
    RETVAL

    ###########################################################################
    # (@)METHOD:GetCount()
    # (@)METHOD:Count()
    # Returns the number of items in the Listbox.
LRESULT
GetCount(handle)
    HWND handle
ALIAS:
    Win32::GUI::Listbox::Count = 1
CODE:
    RETVAL = SendMessage(handle, LB_GETCOUNT, (WPARAM) 0, (LPARAM) 0);
OUTPUT:
    RETVAL

    ###########################################################################
    # (@)METHOD:GetCurSel()
    # (@)METHOD:SelectedItem()
    # Retrieve the index of the currently selected item, if any, in a single-selection Listbox.
LRESULT
GetCurSel(handle)
    HWND handle
ALIAS:
    Win32::GUI::Listbox::SelectedItem = 1
    Win32::GUI::Listbox::ListIndex    = 2
CODE:
    RETVAL = SendMessage(handle, LB_GETCURSEL, (WPARAM) 0, (LPARAM) 0);
OUTPUT:
    RETVAL

    ###########################################################################
    # (@)METHOD:GetHorizontalExtent()
    # Retrieve from a list box the width, in pixels, by which the Listbox can be scrolled horizontally (the scrollable width) if the list box has a horizontal scroll bar.
LRESULT
GetHorizontalExtent(handle)
    HWND handle
CODE:
    RETVAL = SendMessage(handle, LB_GETHORIZONTALEXTENT, (WPARAM) 0, (LPARAM) 0);
OUTPUT:
    RETVAL

    # TODO : LB_GETITEMDATA

    ###########################################################################
    # (@)METHOD:GetItemHeight(index)
    # Retrieve the height of items in a Listbox. 
LRESULT
GetItemHeight(handle,index)
    HWND handle
    int index
CODE:
    RETVAL = SendMessage(handle, LB_GETITEMHEIGHT, (WPARAM) index, (LPARAM) 0);
OUTPUT:
    RETVAL

    ###########################################################################
    # (@)METHOD:GetItemRect(index)
    # Retrieve the dimensions of the rectangle that bounds a Listbox item as it is currently displayed in the Listbox. 
void
GetItemRect(handle,index,code=LVIR_BOUNDS)
    HWND handle
    int index
    int code
PREINIT:
    RECT rect;
PPCODE:
    if (SendMessage(handle, LB_GETITEMRECT, (WPARAM) index, (LPARAM) &rect) != LB_ERR) {
        EXTEND(SP, 4);
        XST_mIV(0, rect.left);
        XST_mIV(1, rect.top);
        XST_mIV(2, rect.right);
        XST_mIV(3, rect.bottom);
        XSRETURN(4);
    }
    else
        XSRETURN_UNDEF;

    ###########################################################################
    # (@)METHOD:GetLocale()
    # Retrieve the current locale of the Listbox.
LRESULT
GetLocale(handle)
    HWND handle
CODE:
    RETVAL = SendMessage(handle, LB_GETLOCALE, (WPARAM) 0, (LPARAM) 0);
OUTPUT:
    RETVAL

    ###########################################################################
    # (@)METHOD:GetSel(index)
    # Retrieve the selection state of an item.
LRESULT
GetSel(handle,index)
    HWND handle
    int index
CODE:
    RETVAL = SendMessage(handle, LB_GETSEL, (WPARAM) index, (LPARAM) 0);
OUTPUT:
    RETVAL

    ###########################################################################
    # (@)METHOD:GetSelCount()
    # (@)METHOD:SelectCount()
    # Retrieve the total number of selected items in a multiple-selection Listbox. 
LRESULT
GetSelCount(handle)
    HWND handle
ALIAS:
    Win32::GUI::Listbox::SelectCount = 1
CODE:
    RETVAL = SendMessage(handle, LB_GETSELCOUNT, 0, 0);
OUTPUT:
    RETVAL

    ###########################################################################
    # (@)METHOD:GetSelItems()
    # (@)METHOD:SelectedItems()
    # Returns an array containing the zero-based indexes of the selected items
    # in a multiple selection Listbox.
void
GetSelItems(handle)
    HWND handle
ALIAS:
    Win32::GUI::Listbox::SelectedItems = 1
PREINIT:
    LRESULT count;
    LRESULT lresult;
    LPINT selitems;
    int i;
PPCODE:
    count = SendMessage(handle, LB_GETSELCOUNT, 0, 0);
    if(count > 0) {
        selitems = (LPINT) safemalloc(sizeof(INT)*count);
        lresult = SendMessage(handle, LB_GETSELITEMS, (WPARAM) count, (LPARAM) selitems);
        if(lresult == -1) {
            safefree(selitems);
            XSRETURN_UNDEF;
        } else {
            EXTEND(SP, lresult);
            for(i=0; i<lresult; i++) {
                XST_mIV(i, (long) selitems[i]);
            }
            safefree(selitems);
            XSRETURN(lresult);
        }
    } else {
        XSRETURN_UNDEF;
    }

    ###########################################################################
    # (@)METHOD:GetText(INDEX)
    # (@)METHOD:GetString(INDEX)
    # Returns the string at the specified zero-based INDEX in the Listbox.
void
GetText(handle,index)
    HWND handle
    WPARAM index
ALIAS:
    Win32::GUI::Listbox::GetString = 1
PREINIT:
    STRLEN cbString;
    char *szString;
PPCODE:
    cbString = SendMessage(handle, LB_GETTEXTLEN, index, 0);
    if(cbString != LB_ERR) {
        szString = (char *) safemalloc(cbString+1);
        if(SendMessage(handle, LB_GETTEXT, index, (LPARAM) (LPCTSTR) szString) != LB_ERR) {
            EXTEND(SP, 1);
            XST_mPV(0, szString);
            safefree(szString);
            XSRETURN(1);
        } else {
            safefree(szString);
            XSRETURN_UNDEF;
        }
    } else {
        XSRETURN_UNDEF;
    }

    ###########################################################################
    # (@)METHOD:GetTextLen()
    # Retrieve the length of a string in a Listbox. 
LRESULT
GetTextLen(handle,index)
    HWND handle
    WPARAM index
CODE:
    RETVAL = SendMessage(handle, LB_GETTEXTLEN, index, 0);
OUTPUT:
    RETVAL

    ###########################################################################
    # (@)METHOD:GetTopIndex()
    # Retrieve the index of the first visible item in a Listbox.
LRESULT
GetTopIndex(handle)
    HWND handle
CODE:
    RETVAL = SendMessage(handle, LB_GETTOPINDEX, 0, 0);
OUTPUT:
    RETVAL

    # TODO : LB_INITSTORAGE

    ###########################################################################
    # (@)METHOD:InsertString(STRING, [INDEX])
    # (@)METHOD:InsertItem(STRING, [INDEX])
    # Inserts an item at the specified zero-based B<INDEX> in the Listbox,
    # or adds it at the end if INDEX is not specified.
LRESULT
InsertString(handle,string,index=-1)
    HWND handle
    LPCTSTR string
    long index
ALIAS:
    Win32::GUI::Listbox::InsertItem = 1
CODE:
    RETVAL = SendMessage(handle, LB_INSERTSTRING, (WPARAM) index, (LPARAM) string);
OUTPUT:
    RETVAL

    ###########################################################################
    # (@)METHOD:ItemFromPoint(X, Y)
    # Retrieve the zero-based index of the item nearest the specified point in a Listbox.
void
ItemFromPoint(handle,x,y)
    HWND handle
    UINT x
    UINT y
PREINIT:
    LRESULT lresult;
PPCODE:
    lresult = SendMessage(handle, LB_ITEMFROMPOINT, 0, (LPARAM) MAKELPARAM(x, y));
    if(GIMME == G_ARRAY) {
        EXTEND(SP, 2);
        XST_mIV(0, (long) LOWORD(lresult));
        if(HIWORD(lresult) == 0)
            XST_mIV(1, 1);
        else
            XST_mIV(1, 0);
        XSRETURN(2);
    } else {
        XSRETURN_IV((long) LOWORD(lresult));
    }

    ###########################################################################
    # (@)METHOD:ResetContent()
    # Remove all items from a Listbox. 
LRESULT
ResetContent(handle)
    HWND handle
ALIAS:
    Win32::GUI::Listbox::Reset = 1
    Win32::GUI::Listbox::Clear = 2
CODE:
    RETVAL = SendMessage(handle, LB_RESETCONTENT, (WPARAM) 0, (LPARAM) 0);
OUTPUT:
    RETVAL

    ###########################################################################
    # (@)METHOD:SelectString(STRING, [INDEX])
    # Search in a Listbox for an item that begins with the characters in a specified string. If a matching item is found, the item is selected. 
LRESULT
SelectString(handle,string,index=-1)
    HWND handle
    LPCTSTR string
    long index
CODE:
    RETVAL = SendMessage(handle, LB_SELECTSTRING, (WPARAM) index, (LPARAM) string);
OUTPUT:
    RETVAL

    ###########################################################################
    # (@)METHOD:SelItemRange(FIRST,LAST,[FLAG=TRUE])
    # Select one or more consecutive items in a multiple-selection Listbox. 
LRESULT
SelItemRange(handle,first,last,flag=TRUE)
    HWND handle
    int  first
    int  last
    BOOL flag
CODE:
    RETVAL = SendMessage(handle, LB_SELITEMRANGE, (WPARAM) flag, (LPARAM) MAKELPARAM(first, last));
OUTPUT:
    RETVAL

    ###########################################################################
    # (@)METHOD:SelItemRangeEx(FIRST,LAST)
    # Select one or more consecutive items in a multiple-selection Listbox. 
LRESULT
SelItemRangeEx(handle,first,last)
    HWND handle
    int  first
    int  last
CODE:
    RETVAL = SendMessage(handle, LB_SELITEMRANGEEX, (WPARAM) first, (LPARAM) last);
OUTPUT:
    RETVAL

    ###########################################################################
    # (@)METHOD:SetAnchorIndex(index)
    # Set the anchor item that is, the item from which a multiple selection starts. A multiple selection spans all items from the anchor item to the caret item.
LRESULT
SetAnchorIndex(handle,index)
    HWND handle
    int index
CODE:
    RETVAL = SendMessage(handle, LB_SETANCHORINDEX, (WPARAM) index, (LPARAM) 0);
OUTPUT:
    RETVAL

    ###########################################################################
    # (@)METHOD:SetCaretIndex(index)
    # Set the focus rectangle to the item at the specified index in a multiple-selection Listbox. If the item is not visible, it is scrolled into view. 
LRESULT
SetCaretIndex(handle,index)
    HWND handle
    int index
CODE:
    RETVAL = SendMessage(handle, LB_SETCARETINDEX, (WPARAM) index, (LPARAM) 0);
OUTPUT:
    RETVAL

    ###########################################################################
    # (@)METHOD:SetColumnWidth(Width)
    # Set the width, in pixels, of all columns in a multi-column Listbox. 
LRESULT
SetColumnWidth(handle,index)
    HWND handle
    int index
CODE:
    RETVAL = SendMessage(handle, LB_SETCOLUMNWIDTH, (WPARAM) index, (LPARAM) 0);
OUTPUT:
    RETVAL

    ###########################################################################
    # (@)METHOD:SetCount(Count)
    # Set the count of items in a Listbox.
LRESULT
SetCount(handle,index)
    HWND handle
    int index
CODE:
    RETVAL = SendMessage(handle, LB_SETCOUNT, (WPARAM) index, (LPARAM) 0);
OUTPUT:
    RETVAL

    ###########################################################################
    # (@)METHOD:SetCurSel(INDEX)
    # (@)METHOD:Select(INDEX)
    # Selects the zero-based INDEX item in the Listbox.  Can only be used
    # with single selection listboxes.  For multiple-selection listboxes
    # see SetSel().
LRESULT
SetCurSel(handle,index)
    HWND handle
    int index
ALIAS:
    Win32::GUI::Listbox::Select = 1
CODE:
    RETVAL = SendMessage(handle, LB_SETCURSEL, (WPARAM) index, (LPARAM) 0);
OUTPUT:
    RETVAL

    ###########################################################################
    # (@)METHOD:SetHorizontalExtent(cxExtent)
    # Set the width, in pixels, by which a Listbox can be scrolled horizontally.
LRESULT
SetHorizontalExtent(handle,index)
    HWND handle
    int index
CODE:
    RETVAL = SendMessage(handle, LB_SETHORIZONTALEXTENT, (WPARAM) index, (LPARAM) 0);
OUTPUT:
    RETVAL

    # TODO : LB_SETITEMDATA

    ###########################################################################
    # (@)METHOD:SetItemHeight(Height)
    # Set the height, in pixels, of items in a Listbox.
LRESULT
SetItemHeight(handle,index,cy)
    HWND handle
    int index
    int cy
CODE:
    RETVAL = SendMessage(handle, LB_SETITEMHEIGHT, (WPARAM) index, (LPARAM) MAKELPARAM(cy, 0));
OUTPUT:
    RETVAL
    
    ###########################################################################
    # (@)METHOD:SetLocal(local)
    # Set the current locale of the Listbox.
LRESULT
SetLocal(handle,index)
    HWND handle
    int index
CODE:
    RETVAL = SendMessage(handle, LB_SETLOCALE, (WPARAM) index, (LPARAM) 0 );
OUTPUT:
    RETVAL
    
    ###########################################################################
    # (@)METHOD:SetSel(index,[FLAG=TRUE])
    # Select a string in a multiple-selection Listbox.
LRESULT
SetSel(handle,index,flag=TRUE)
    HWND handle
    int index
    BOOL flag
CODE:
    RETVAL = SendMessage(handle, LB_SETSEL, (WPARAM) flag, (LPARAM) index );
OUTPUT:
    RETVAL

    ###########################################################################
    # (@)METHOD:SetTabStops(...)
    # Set the tab-stop positions in a Listbox. 
LRESULT
SetTabStops(handle,tab,...)
    HWND handle
    UINT tab
CODE:
    DWORD * pBuf = (DWORD *) safemalloc((items-1) * sizeof(DWORD));
    for (int i = 1; i < items; i++)
        pBuf[i-1] = (DWORD)SvIV(ST(i));
    RETVAL = SendMessage(handle, LB_SETTABSTOPS, items-1, (LPARAM) pBuf);
    safefree(pBuf);
OUTPUT:
    RETVAL

    ###########################################################################
    # (@)METHOD:SetTopIndex(index)
    # Ensure that a particular item in a Listbox is visible.
LRESULT
SetTopIndex(handle,index)
    HWND handle
    int index
CODE:
    RETVAL = SendMessage(handle, LB_SETTOPINDEX, (WPARAM) index, (LPARAM) 0 );
OUTPUT:
    RETVAL

    ###########################################################################
    ###########################################################################
    ###########################################################################

    ###########################################################################
    # (@)METHOD:Add(STRING, STRING .. STRING)
    # Add multiple string.
void
Add(handle,...)
    HWND handle
PREINIT:
    int i;
CODE:
    for(i = 1; i < items; i++) {
        SendMessage(handle, LB_ADDSTRING, 0, (LPARAM) (LPCTSTR) SvPV_nolen(ST(i)));
    }

    ###########################################################################
    # (@)METHOD:ItemHeight([HEIGHT])
    # Gets or sets the items height in a Listbox.
LRESULT
ItemHeight(handle,height=-1)
    HWND handle
    long height
CODE:
    if(items == 1) {
        RETVAL = SendMessage(handle, LB_GETITEMHEIGHT, 0, 0);
    } else {
        RETVAL = SendMessage(handle, LB_SETITEMHEIGHT, 0, MAKELPARAM(height, 0));
    }
OUTPUT:
    RETVAL

    ###########################################################################
    # (@)METHOD:FirstVisibleItem([INDEX])
    # Set or Get first visible item.
LRESULT
FirstVisibleItem(handle,index=-1)
    HWND handle
    long index
CODE:
    if(items == 1)
        RETVAL = SendMessage(handle, LB_GETTOPINDEX, 0, 0);
    else
        RETVAL = SendMessage(handle, LB_SETTOPINDEX, (WPARAM) index, 0);
OUTPUT:
    RETVAL
