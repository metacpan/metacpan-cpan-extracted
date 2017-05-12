    /*
    ###########################################################################
    # (@)PACKAGE:Win32::GUI::Combobox
    #
    # $Id: Combobox.xs,v 1.9 2007/07/15 18:23:06 robertemay Exp $
    #
    ###########################################################################
    */

#include "GUI.h"

void Combobox_onPreCreate(NOTXSPROC LPPERLWIN32GUI_CREATESTRUCT perlcs) {

    perlcs->cs.lpszClass = "COMBOBOX";
    perlcs->cs.style = WS_VISIBLE | WS_CHILD;
    perlcs->cs.dwExStyle = WS_EX_CLIENTEDGE;
}

BOOL
Combobox_onParseOption(NOTXSPROC char *option, SV* value, LPPERLWIN32GUI_CREATESTRUCT perlcs) {

    BOOL retval = TRUE;
           
           if BitmaskOptionValue("-autohscroll",       perlcs->cs.style, CBS_AUTOHSCROLL)
    } else if BitmaskOptionValue("-disablenoscroll",   perlcs->cs.style, CBS_DISABLENOSCROLL)
    } else if BitmaskOptionValue("-hasstring",         perlcs->cs.style, CBS_HASSTRINGS)
    } else if BitmaskOptionValue("-lowercase",         perlcs->cs.style, CBS_LOWERCASE)
    } else if BitmaskOptionValue("-nointegraleheight", perlcs->cs.style, CBS_NOINTEGRALHEIGHT)
    } else if BitmaskOptionValue("-sort",              perlcs->cs.style, CBS_SORT)
    } else if BitmaskOptionValue("-uppercase",         perlcs->cs.style, CBS_UPPERCASE)
    }
    else if(strcmp(option, "-simple") == 0) {
        perlcs->cs.style &= ~CBS_DROPDOWNLIST;
        perlcs->cs.style |=  CBS_SIMPLE;
    }
    else if(strcmp(option, "-dropdown") == 0) {
        perlcs->cs.style &= ~CBS_DROPDOWNLIST;
        perlcs->cs.style |=  CBS_DROPDOWN;
    }
    else if(strcmp(option, "-dropdownlist") == 0) {
        perlcs->cs.style |=  CBS_DROPDOWNLIST;
    }
    else
        retval = FALSE;

    return retval;
}

void
Combobox_onPostCreate(NOTXSPROC HWND myhandle, LPPERLWIN32GUI_CREATESTRUCT perlcs) {
}

BOOL
Combobox_onParseEvent(NOTXSPROC char *name, int* eventID) {

    BOOL retval = TRUE;

         if Parse_Event("GotFocus",   PERLWIN32GUI_NEM_GOTFOCUS)
    else if Parse_Event("LostFocus",  PERLWIN32GUI_NEM_LOSTFOCUS)
    else if Parse_Event("DblClick",   PERLWIN32GUI_NEM_DBLCLICK)
    else if Parse_Event("Change",     PERLWIN32GUI_NEM_CONTROL1)
    else if Parse_Event("Anonymous",  PERLWIN32GUI_NEM_CONTROL2)
    else if Parse_Event("DropDown",   PERLWIN32GUI_NEM_CONTROL3)
    else if Parse_Event("CloseUp",    PERLWIN32GUI_NEM_CONTROL4)
    else retval = FALSE;

    return retval;
}

int
Combobox_onEvent (NOTXSPROC LPPERLWIN32GUI_USERDATA perlud, UINT uMsg, WPARAM wParam, LPARAM lParam) {

    int PerlResult = 1;

    if ( uMsg == WM_COMMAND ) {

        switch(HIWORD(wParam)) {
        case CBN_SETFOCUS:
            /*
             * (@)EVENT:GotFocus()
             * Sent when the control is activated.
             * (@)APPLIES_TO:Combobox, ComboboxEx
             */
            PerlResult = DoEvent(NOTXSCALL perlud, PERLWIN32GUI_NEM_GOTFOCUS, "GotFocus", -1 );
            break;
        case CBN_KILLFOCUS:
            /*
             * (@)EVENT:LostFocus()
             * Sent when the control is deactivated.
             * (@)APPLIES_TO:Combobox, ComboboxEx
             */  
            PerlResult = DoEvent(NOTXSCALL perlud, PERLWIN32GUI_NEM_LOSTFOCUS, "LostFocus", -1 );
            break;
        case CBN_DBLCLK:
            /*
             * (@)EVENT:DblClick()
             * Sent when the user double clicks on an item from the Combobox
             * (@)APPLIES_TO:Combobox, ComboboxEx
             */ 
            PerlResult = DoEvent(NOTXSCALL perlud, PERLWIN32GUI_NEM_DBLCLICK, "DblClick", -1 );
            break;
        case CBN_SELCHANGE:
            /*
             * (@)EVENT:Change()
             * Sent when the user selects an item from the Combobox
             * (@)APPLIES_TO:Combobox, ComboboxEx
             */
            PerlResult = DoEvent(NOTXSCALL perlud, PERLWIN32GUI_NEM_CONTROL1, "Change", -1 );
            break;
        case CBN_DROPDOWN:
            /*
             * (@)EVENT:DropDown()
             * Sent when the user selects the list box. This event allows you to populate the
             * dropdown dynamically. This event is only fired if the combo box has the CBS_DROPDOWN or CBS_DROPDOWNLIST style.
             * (@)APPLIES_TO:Combobox, ComboboxEx
             */
            PerlResult = DoEvent(NOTXSCALL perlud, PERLWIN32GUI_NEM_CONTROL3, "DropDown", -1 );
            break;
        case CBN_CLOSEUP:
            /*
             * (@)EVENT:CloseUp()
             * Sent when the list box of a combo box has been closed. This event allows you to populate the
             * dropdown dynamically. This event is only fired if the combo box has the CBS_DROPDOWN or CBS_DROPDOWNLIST style.
             *
             * If the user changed the current selection, the combo box also sends the Change event when the drop-down list closes. 
             * In general, you cannot predict the order in which notifications will be sent. In particular, a Change event message 
             * may occur either before or after a CloseUp event.
             * (@)APPLIES_TO:Combobox, ComboboxEx
             */
            PerlResult = DoEvent(NOTXSCALL perlud, PERLWIN32GUI_NEM_CONTROL4, "CloseUp", -1 );
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
    # (@)PACKAGE:Win32::GUI::ComboboxEx
    ###########################################################################
    */

void ComboboxEx_onPreCreate(NOTXSPROC LPPERLWIN32GUI_CREATESTRUCT perlcs) {

    perlcs->cs.lpszClass = WC_COMBOBOXEX;
    perlcs->cs.style = WS_VISIBLE | WS_CHILD;
}

BOOL
ComboboxEx_onParseOption(NOTXSPROC char *option, SV* value, LPPERLWIN32GUI_CREATESTRUCT perlcs) {
    BOOL retval = TRUE;

    if(strcmp(option, "-imagelist") == 0) {
        perlcs->hImageList = (HIMAGELIST) handle_From(NOTXSCALL value);
    } else if BitmaskOptionValueMask("-casesensitive",     perlcs->dwFlags, CBES_EX_CASESENSITIVE )
    } else if BitmaskOptionValueMask("-noeditimage",       perlcs->dwFlags, CBES_EX_NOEDITIMAGE )
    } else if BitmaskOptionValueMask("-noeditimageindent", perlcs->dwFlags, CBES_EX_NOEDITIMAGEINDENT )
    } else if BitmaskOptionValueMask("-nosizelimit",       perlcs->dwFlags, CBES_EX_NOSIZELIMIT )
    } else retval = Combobox_onParseOption (NOTXSCALL option, value, perlcs);

    return retval;
}

void
ComboboxEx_onPostCreate(NOTXSPROC HWND myhandle, LPPERLWIN32GUI_CREATESTRUCT perlcs) {

    if(perlcs->hImageList != NULL) {
        SendMessage(myhandle, CBEM_SETIMAGELIST, 0, (LPARAM) perlcs->hImageList);
    }
    if ( perlcs->dwFlagsMask != 0) {
        SendMessage(myhandle, CBEM_SETEXTENDEDSTYLE, (WPARAM) perlcs->dwFlagsMask, (LPARAM) perlcs->dwFlags);
    }
}

BOOL
ComboboxEx_onParseEvent(NOTXSPROC char *name, int* eventID) {

    return Combobox_onParseEvent(NOTXSCALL name, eventID);;
}

int
ComboboxEx_onEvent (NOTXSPROC LPPERLWIN32GUI_USERDATA perlud, UINT uMsg, WPARAM wParam, LPARAM lParam) {

    return Combobox_onEvent (NOTXSCALL perlud, uMsg, wParam, lParam);
}

MODULE = Win32::GUI::Combobox       PACKAGE = Win32::GUI::Combobox

PROTOTYPES: DISABLE

    ###########################################################################
    # (@)PACKAGE:Win32::GUI::Combobox
    ###########################################################################

#pragma message( "*** PACKAGE Win32::GUI::Combobox..." )

    ###########################################################################
    # (@)METHOD:AddString(STRING)
    # Adds an item at the end of the control's list.
LRESULT
AddString(handle,string)
    HWND handle
    LPCTSTR string
CODE:
    RETVAL = SendMessage(handle, CB_ADDSTRING, 0, (LPARAM) string);
OUTPUT:
    RETVAL

    ###########################################################################
    # (@)METHOD:DeleteString(INDEX)
    # (@)METHOD:RemoveItem(INDEX)
    # Removes the zero-based INDEX item from the Combobox.
LRESULT
DeleteString(handle,index)
    HWND handle
    WPARAM index
ALIAS:
    Win32::GUI::Combobox::RemoveItem = 1
CODE:
    RETVAL = SendMessage(handle, CB_DELETESTRING, index, 0);
OUTPUT:
    RETVAL

    ###########################################################################
    # (@)METHOD:Dir(PATH, [FLAG])
    # Add a list of filenames.
LRESULT
Dir(handle, path, flag = DDL_ARCHIVE | DDL_DIRECTORY | DDL_DRIVES | DDL_READWRITE)
    HWND handle
    LPCTSTR path
    WPARAM  flag
CODE:
    RETVAL = SendMessage(handle, CB_DIR, flag, (LPARAM) path);
OUTPUT:
    RETVAL

    ###########################################################################
    # (@)METHOD:FindString(STRING, [INDEX])
    # Search item beginning with specified string.
LRESULT
FindString(handle,string,index=-1)
    HWND handle
    LPCTSTR string
    long index
CODE:
    RETVAL = SendMessage(handle, CB_FINDSTRING, (WPARAM) index, (LPARAM) string);
OUTPUT:
    RETVAL

    ###########################################################################
    # (@)METHOD:FindStringExact(STRING, [INDEX])
    # Search item that match specified string.
LRESULT
FindStringExact(handle,string,index=-1)
    HWND handle
    LPCTSTR string
    long index
CODE:
    RETVAL = SendMessage(handle, CB_FINDSTRINGEXACT, (WPARAM) index, (LPARAM) string);
OUTPUT:
    RETVAL

    ###########################################################################
    # (@)METHOD:Count()
    # (@)METHOD:GetCount()
    # Return the number of items.
LRESULT
GetCount(handle)
    HWND handle
ALIAS:
    Win32::GUI::Combobox::Count = 1
CODE:
    RETVAL = SendMessage(handle, CB_GETCOUNT, 0, 0);
OUTPUT:
    RETVAL

    ###########################################################################
    # (@)METHOD:GetCurSel()
    # (@)METHOD:ListIndex()
    # (@)METHOD:SelectedItem()
    # Returns the zero-based index of the currently selected item, or -1 if
    # no item is selected.
LRESULT
GetCurSel(handle)
    HWND handle
ALIAS:
    Win32::GUI::Combobox::SelectedItem = 1
    Win32::GUI::Combobox::ListIndex    = 2
CODE:
    RETVAL = SendMessage(handle, CB_GETCURSEL, 0, 0);
OUTPUT:
    RETVAL

    ###########################################################################
    # (@)METHOD:GetDroppedControlRect()
    # Retrieves screen coordinates of the drop-down list box. 

void
GetDroppedControlRect(handle)
    HWND   handle
PREINIT:
    RECT    myRect;
PPCODE:
    SendMessage(handle, CB_GETDROPPEDCONTROLRECT, 0, (LPARAM) &myRect);
    EXTEND(SP, 4);
    XST_mIV(0, myRect.left);
    XST_mIV(1, myRect.top);
    XST_mIV(2, myRect.right);
    XST_mIV(3, myRect.bottom);
    XSRETURN(4);

    ###########################################################################
    # (@)METHOD:GetDroppedState()
    # Determine whether the list box of a combo box is dropped down. 
LRESULT
GetDroppedState(handle)
    HWND handle
CODE:
    RETVAL = SendMessage(handle, CB_GETDROPPEDSTATE, 0, 0);
OUTPUT:
    RETVAL

    ###########################################################################
    # (@)METHOD:GetDroppedWidth()
    # Retrieve the minimum allowable width, in pixels, of the list box af a Combobox with the CBS_DROPDOWN or CBS_DROPDOWNLIST style.

LRESULT
GetDroppedWidth(handle)
    HWND handle
CODE:
    RETVAL = SendMessage(handle, CB_GETDROPPEDWIDTH, 0, 0);
OUTPUT:
    RETVAL

    ###########################################################################
    # (@)METHOD:GetEditSel()
    # Get the starting and ending character positions of the current selection in the edit control of a Combobox.
void
GetEditSel(handle)
    HWND handle
PREINIT:
    DWORD start;
    DWORD end;
PPCODE:
    SendMessage(handle, CB_GETEDITSEL, (WPARAM) &start, (LPARAM) &end);
    EXTEND(SP, 2);
    XST_mIV(0, (long) start);
    XST_mIV(1, (long) end);
    XSRETURN(2);

    ###########################################################################
    # (@)METHOD:GetExtendedUI()
    # Determine whether a combo box has the default user interface or the extended user interface. 
LRESULT
GetExtendedUI(handle)
    HWND handle
CODE:
    RETVAL = SendMessage(handle, CB_GETEXTENDEDUI, 0, 0);
OUTPUT:
    RETVAL

    ###########################################################################
    # (@)METHOD:GetHorizontalExtent()
    # Retrieve from a combo box the width, in pixels, by which the list box can be scrolled horizontally (the scrollable width).
LRESULT
GetHorizontalExtent(handle)
    HWND handle
CODE:
    RETVAL = SendMessage(handle, CB_GETHORIZONTALEXTENT, 0, 0);
OUTPUT:
    RETVAL

    # TODO : CB_GETITEMDATA  : Store SV* ?

    ###########################################################################
    # (@)METHOD:GetItemHeight(INDEX)
    # Determine the height of list items or the selection field in a combo box. 

LRESULT
GetItemHeight(handle, index)
    HWND handle
    WPARAM index
CODE:
    RETVAL = SendMessage(handle, CB_GETITEMHEIGHT, index, 0);
OUTPUT:
    RETVAL

    ###########################################################################
    # (@)METHOD:GetLBText(INDEX)    
    # (@)METHOD:GetString(INDEX)
    # Returns the string at the specified zero-based INDEX in the Combobox.
void
GetLBText(handle,index)
    HWND handle
    WPARAM index
ALIAS:
    Win32::GUI::Combobox::GetString = 1
PREINIT:
    STRLEN cbString;
    char *szString;
PPCODE:
    cbString = SendMessage(handle, CB_GETLBTEXTLEN, index, 0);
    if(cbString != LB_ERR) {
        szString = (char *) safemalloc(cbString+1);
        if(SendMessage(handle, CB_GETLBTEXT,
                       index, (LPARAM) (LPCTSTR) szString) != LB_ERR) {
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
    # (@)METHOD:GetLBTextLen(INDEX)
    # Retrieve the length, in characters, of a string in the list of a combo box. 

LRESULT
GetLBTextLen(handle,index)
    HWND   handle
    WPARAM index
CODE:
    RETVAL = SendMessage(handle, CB_GETLBTEXTLEN, index, 0);
OUTPUT:
    RETVAL

    ###########################################################################
    # (@)METHOD:GetLocale()
    # Retrieve the current locale of the Combobox.
LRESULT
GetLocale(handle)
    HWND handle
CODE:
    RETVAL = SendMessage(handle, CB_GETLOCALE, 0, 0);
OUTPUT:
    RETVAL

    ###########################################################################
    # (@)METHOD:GetTopIndex()
    # Retrieve the zero-based index of the first visible item in the list box portion of a Combobox.
LRESULT
GetTopIndex(handle)
    HWND handle
CODE:
    RETVAL = SendMessage(handle, CB_GETTOPINDEX, 0, 0);
OUTPUT:
    RETVAL

    ###########################################################################
    # (@)METHOD:InitStorage(count,size)
    # Allocates memory for storing list box items.
LRESULT
InitStorage(handle,count,size)
    HWND handle
    WPARAM count
    WPARAM size
CODE:
    RETVAL = SendMessage(handle, CB_INITSTORAGE, count, (LPARAM) size);
OUTPUT:
    RETVAL

    ###########################################################################    
    # (@)METHOD:InsertString(STRING, [INDEX])
    # (@)METHOD:InsertItem(STRING, [INDEX])
    # Inserts an item at the specified zero-based INDEX in the Combobox,
    # or adds it at the end if INDEX is not specified.
LRESULT
InsertString(handle,string,index=-1)
    HWND handle
    LPCTSTR string
    long index
ALIAS:
    Win32::GUI::Combobox::InsertItem = 1
CODE:
    RETVAL = SendMessage(handle, CB_INSERTSTRING, (WPARAM) index, (LPARAM) string);
OUTPUT:
    RETVAL

    ###########################################################################
    # (@)METHOD:LimitText(SIZE)
    # Set limit of the text length the user may type into the Textfield of a Combobox.
LRESULT
LimitText(handle,index)
    HWND   handle
    WPARAM index
CODE:
    RETVAL = SendMessage(handle, CB_LIMITTEXT, index, 0);
OUTPUT:
    RETVAL

    ###########################################################################
    # (@)METHOD:ResetContent()
    # (@)METHOD:Reset()
    # (@)METHOD:Clear()
    # Remove all items from the Listbox and Textfield of a Combobox. 

LRESULT
ResetContent(handle)
    HWND handle
ALIAS:
    Win32::GUI::Combobox::Reset = 1
    Win32::GUI::Combobox::Clear = 2
CODE:
    RETVAL = SendMessage(handle, CB_RESETCONTENT, 0, 0);
OUTPUT:
    RETVAL

    ###########################################################################
    # (@)METHOD:SelectString(STRING, [INDEX])
    # Search for an item that begins with the specified string in the Listbox.
    # If a matching item is found, it is selected and copied to the Textfield.
LRESULT
SelectString(handle,string,index=-1)
    HWND handle
    LPCTSTR string
    long index
CODE:
    RETVAL = SendMessage(handle, CB_SELECTSTRING, (WPARAM) index, (LPARAM) string);
OUTPUT:
    RETVAL

    ###########################################################################
    # (@)METHOD:SetCurSel(INDEX)
    # (@)METHOD:Select(INDEX)
    # Selects the zero-based INDEX item in the Combobox.

LRESULT
SetCurSel(handle,index)
    HWND   handle
    WPARAM index
ALIAS:
    Win32::GUI::Combobox::Select = 1
CODE:
    RETVAL = SendMessage(handle, CB_SETCURSEL, index, 0);
OUTPUT:
    RETVAL

    ###########################################################################
    # (@)METHOD:SetDroppedWidth(WIDTH)
    # Set the maximum allowable width, in pixels, of the Listbox of a Combobox.
LRESULT
SetDroppedWidth(handle,index)
    HWND   handle
    WPARAM index
CODE:
    RETVAL = SendMessage(handle, CB_SETDROPPEDWIDTH, index, 0);
OUTPUT:
    RETVAL

    ###########################################################################
    # (@)METHOD:SetEditSel(START,END)
    # Select characters in the textfield.  START and END are the
    # (zero-based) index of the characters to be selected.  START
    # is the index of the first character to be selected, and END
    # is the index of the first character following the selection.
    # For example to select the first 4 characters:
    # 
    #    $combobox->SetEditSel(0,4);
    #
    # If START is -1, the any selection is removed.  If END is -1,
    # then the selection is from START to the last character in the
    # textfield.
    #
    # Returns 1 on success, 0 on failure and -1 if sent to a
    # Combobox that does not have a textfield (C<-dropdownlist => 1>).
LRESULT
SetEditSel(handle,start,end)
    HWND handle
    UINT start
    UINT end
CODE:
    RETVAL = SendMessage(handle, CB_SETEDITSEL, 0, MAKELPARAM(start, end));
OUTPUT:
    RETVAL

    ###########################################################################
    # (@)METHOD:SetExtendedUI(FLAG)
    # Select either the default user interface or the extended user interface for a Combobox.
LRESULT
SetExtendedUI(handle,index)
    HWND   handle
    WPARAM index
CODE:
    RETVAL = SendMessage(handle, CB_SETEXTENDEDUI, index, 0);
OUTPUT:
    RETVAL

    ###########################################################################
    # (@)METHOD:SetHorizontalExtend(CX)
    # Set the width, in pixels, by which a listbox can be scrolled horizontally (the scrollable width). 
LRESULT
SetHorizontalExtend(handle,index)
    HWND   handle
    WPARAM index
CODE:
    RETVAL = SendMessage(handle, CB_SETHORIZONTALEXTENT, index, 0);
OUTPUT:
    RETVAL

    # TODO : CB_SETITEMDATA 

    ###########################################################################
    # (@)METHOD:SetItemHeight(INDEX,HEIGHT)
    # Set the height of list items or the selection field in a Combobox. 
LRESULT
SetItemHeight(handle,wparam,lparam)
    HWND   handle
    WPARAM wparam
    WPARAM lparam
CODE:
    RETVAL = SendMessage(handle, CB_SETITEMHEIGHT, wparam, (LPARAM) lparam);
OUTPUT:
    RETVAL

    ###########################################################################
    # (@)METHOD:SetLocale(LOCALE)
    # Set the current locale of the Combobox.
LRESULT
SetLocale(handle,wparam)
    HWND   handle
    WPARAM wparam
CODE:
    RETVAL = SendMessage(handle, CB_SETLOCALE, wparam, 0);
OUTPUT:
    RETVAL

    ###########################################################################
    # (@)METHOD:SetTopIndex(INDEX)
    # Ensure that a particular item is visible in the Listbox of a Combobox. 
LRESULT
SetTopIndex(handle,index)
    HWND   handle
    WPARAM index
CODE:
    RETVAL = SendMessage(handle, CB_SETTOPINDEX, index, 0);
OUTPUT:
    RETVAL

    ###########################################################################
    # (@)METHOD:ShowDropDown(FLAG)
    # Show or hide the Listbox of a Combobox.
LRESULT
ShowDropDown(handle,index)
    HWND   handle
    WPARAM index
CODE:
    RETVAL = SendMessage(handle, CB_SHOWDROPDOWN, index, 0);
OUTPUT:
    RETVAL

    ###########################################################################
    ###########################################################################
    ###########################################################################

    ###########################################################################
    # (@)METHOD:Add(STRING, STRING .. STRING)
    # Adds one or more items at the end of the control's list.
void
Add(handle,...)
    HWND handle
PREINIT:
    int i;
CODE:
    for(i = 1; i < items; i++) {
        SendMessage(handle, CB_ADDSTRING, 0, (LPARAM) (LPCTSTR) SvPV_nolen(ST(i)));
    }

    ###########################################################################
    # (@)METHOD:ItemHeight([HEIGHT])
    # Gets or sets the items height in a Combobox.
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
    # (@)METHOD:TopIndex([INDEX])
    # (@)METHOD:FirstVisibleItem([INDEX])
    # Set or Get first visible item index.
LRESULT
TopIndex(handle,index=-1)
    HWND handle
    long index
ALIAS:
    Win32::GUI::Combobox::FirstVisibleItem = 1
CODE:
    if(items == 1)
        RETVAL = SendMessage(handle, CB_GETTOPINDEX, 0, 0);
    else
        RETVAL = SendMessage(handle, CB_SETTOPINDEX, (WPARAM) index, 0);
OUTPUT:
    RETVAL

    ###########################################################################
    # (@)PACKAGE:Win32::GUI::ComboboxEx
    ###########################################################################

MODULE = Win32::GUI::Combobox     PACKAGE = Win32::GUI::ComboboxEx

#pragma message( "*** PACKAGE Win32::GUI::ComboboxEx..." )



    ###########################################################################
    # (@)METHOD:DeleteItem(INDEX)
    # Delete an indexed item of the control's list.
LRESULT
DeleteItem(handle,index)
    HWND handle
    WPARAM index
CODE:
    RETVAL = SendMessage(handle, CBEM_DELETEITEM, index, 0);
OUTPUT:
    RETVAL

    ###########################################################################
    # (@)METHOD:GetComboControl()
    # Retrieves the handle to the child combo box control.
HWND
GetComboControl(handle)
    HWND handle
CODE:
    RETVAL = (HWND) SendMessage(handle, CBEM_GETCOMBOCONTROL, 0, 0);
OUTPUT:
    RETVAL

    ###########################################################################
    # (@)METHOD:GetEditControl()
    # Retrieves the handle to the edit control portion of a ComboBoxEx control.
HWND
GetEditControl(handle)
    HWND handle
CODE:
    RETVAL = (HWND) SendMessage(handle, CBEM_GETEDITCONTROL, 0, 0);
OUTPUT:
    RETVAL

    ###########################################################################
    # (@)METHOD:GetImageList()
    # Retrieves the handle to an image list assigned to a ComboBoxEx.
HIMAGELIST
GetImageList(handle)
    HWND handle
CODE:
    RETVAL = (HIMAGELIST) SendMessage(handle, CBEM_GETIMAGELIST, 0, 0);
OUTPUT:
    RETVAL

    ###########################################################################
    # (@)METHOD:GetExtendedStyle()
    # Retrieves the extended styles that are in use for a ComboBoxEx control. 
HWND
GetExtendedStyle(handle)
    HWND handle
CODE:
    RETVAL = (HWND) SendMessage(handle, CBEM_GETEXTENDEDSTYLE, 0, 0);
OUTPUT:
    RETVAL

    ###########################################################################
    # (@)METHOD:GetItem(NODE)
    # Retrieves item information for a given ComboBoxEx item.
void
GetItem(handle,item)
    HWND handle
    int item
PREINIT:
    COMBOBOXEXITEM cb_item;
    char pszText[1024];
PPCODE:
    ZeroMemory(&cb_item, sizeof(COMBOBOXEXITEM));
    cb_item.iItem = item;
    cb_item.mask = CBEIF_DI_SETITEM | CBEIF_IMAGE | CBEIF_INDENT
                 | CBEIF_LPARAM | CBEIF_OVERLAY 
                 | CBEIF_SELECTEDIMAGE | CBEIF_TEXT;
    cb_item.pszText = pszText;
    cb_item.cchTextMax = 1024;
    if(SendMessage(handle, CBEM_GETITEM, 0, (LPARAM) &item) != 0) {
        EXTEND(SP, 14);
        XST_mPV(0, "-text");
        XST_mPV(1, cb_item.pszText);
        XST_mPV(2, "-image");
        XST_mIV(3, cb_item.iImage);
        XST_mPV(4, "-selectedimage");
        XST_mIV(5, cb_item.iSelectedImage);
        XST_mPV(6, "-item");
        XST_mIV(7, cb_item.iItem);
        XST_mPV(8, "-overlay");
        XST_mIV(9, cb_item.iOverlay);
        XST_mPV(10, "-indent");
        XST_mIV(11, cb_item.iIndent);
        XST_mPV(12, "-lparam");
        XST_mIV(13, cb_item.lParam);
        XSRETURN(14);
    } else {
        XSRETURN_UNDEF;
    }

    ###########################################################################
    # (@)METHOD:GetUnicodeFormat()
    # Retrieves the UNICODE character format flag for the control. 
LRESULT
GetUnicodeFormat(handle)
    HWND handle
CODE:
    RETVAL = SendMessage(handle, CBEM_GETUNICODEFORMAT, 0, 0);
OUTPUT:
    RETVAL

    ###########################################################################
    # (@)METHOD:HasEditChanged()
    # Determines if the user has changed the contents of the ComboBoxEx edit control by typing.
LRESULT
HasEditChanged(handle)
    HWND handle
CODE:
    RETVAL = SendMessage(handle, CBEM_HASEDITCHANGED, 0, 0);
OUTPUT:
    RETVAL

    ###########################################################################
    # (@)METHOD:InsertItem(%OPTIONS)
    # Inserts a new item in the ComboboxEx control. Returns the newly created
    # item zero-based index or -1 on errors.
    #
    # B<%OPTIONS> can be:
    #   -index => position (-1 for the end of the list)
    #   -image => index of an image from the associated ImageList
    #   -selectedimage => index of an image from the associated ImageList
    #   -text => string
    #   -indent => indentation spaces (1 space == 10 pixels)
LRESULT
InsertItem(handle,...)
    HWND handle
PREINIT:
    COMBOBOXEXITEM Item;
CODE:
    ZeroMemory(&Item, sizeof(COMBOBOXEXITEM));
    Item.iItem = -1;
    ParseComboboxExItemOptions(NOTXSCALL sp, mark, ax, items, 1, &Item);
    RETVAL = SendMessage(handle, CBEM_INSERTITEM, 0, (LPARAM) &Item);
OUTPUT:
    RETVAL

    ###########################################################################
    # (@)METHOD:SetExtendedStyle(mask, exstyle)
    # Sets extended styles within a ComboBoxEx control.
LRESULT
SetExtendedStyle(handle, mask, exstyle)
    HWND handle
    DWORD mask
    DWORD exstyle
CODE:
    RETVAL = SendMessage(handle, CBEM_SETEXTENDEDSTYLE, (WPARAM) mask, (LPARAM) exstyle);
OUTPUT:
    RETVAL

    ###########################################################################
    # (@)METHOD:SetImageList(imagelist)
    # Sets an image list for a ComboBoxEx control.
LRESULT
SetImageList(handle, himl)
    HWND handle
    HIMAGELIST himl
CODE:
    RETVAL = SendMessage(handle, CBEM_SETIMAGELIST, (WPARAM) 0, (LPARAM) himl);
OUTPUT:
    RETVAL

    ###########################################################################
    # (@)METHOD:SetItem(%OPTIONS)
    # Sets the attributes for an item in a ComboBoxEx control.
    #
    # B<%OPTIONS> can be:
    #   -image => index of an image from the associated ImageList
    #   -selectedimage => index of an image from the associated ImageList
    #   -text => string
    #   -indent => indentation spaces (1 space == 10 pixels)
LRESULT
SetItem(handle,item,...)
    HWND handle
    int item
PREINIT:
    COMBOBOXEXITEM Item;
CODE:
    ZeroMemory(&Item, sizeof(COMBOBOXEXITEM));
    Item.iItem = item;
    ParseComboboxExItemOptions(NOTXSCALL sp, mark, ax, items, 2, &Item);
    RETVAL = SendMessage(handle, CBEM_SETITEM, 0, (LPARAM) &Item);
OUTPUT:
    RETVAL

    ###########################################################################
    # (@)METHOD:SetUnicodeFormat(FLAG)
    # Sets the UNICODE character format flag for the control.
LRESULT
SetUnicodeFormat(handle,flag)
    HWND handle
    BOOL flag
CODE:
    RETVAL = SendMessage(handle, CBEM_SETUNICODEFORMAT, (WPARAM) flag, 0);
OUTPUT:
    RETVAL

    ###########################################################################
    ###########################################################################
    ###########################################################################
