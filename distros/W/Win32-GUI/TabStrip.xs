    /*
    ###########################################################################
    # (@)PACKAGE:Win32::GUI::TabStrip
    #
    # $Id: TabStrip.xs,v 1.4 2010/04/08 21:26:48 jwgui Exp $
    #
    ###########################################################################
    */

#include "GUI.h"

void 
TabStrip_onPreCreate(NOTXSPROC LPPERLWIN32GUI_CREATESTRUCT perlcs) {

    perlcs->cs.lpszClass = WC_TABCONTROL;
    perlcs->cs.style = WS_VISIBLE | WS_CHILD;
}

BOOL
TabStrip_onParseOption(NOTXSPROC char *option, SV* value, LPPERLWIN32GUI_CREATESTRUCT perlcs) {

    BOOL retval = TRUE;

    if(strcmp(option, "-imagelist") == 0) {
        perlcs->hImageList = (HIMAGELIST) handle_From(NOTXSCALL value);
    } else if(strcmp(option, "-tooltip") == 0) {
        perlcs->hTooltip = (HWND) handle_From(NOTXSCALL value);
        SwitchBit(perlcs->cs.style, TCS_TOOLTIPS, 1);        
    } else if(strcmp(option, "-vertical") == 0) {
        SwitchBit(perlcs->cs.style, TCS_VERTICAL, SvIV(value));
        SwitchBit(perlcs->cs.style, TCS_MULTILINE, SvIV(value));
    } else if BitmaskOptionValue("-multiline",       perlcs->cs.style, TCS_MULTILINE)
    } else if BitmaskOptionValue("-bottom",          perlcs->cs.style, TCS_BOTTOM)
    } else if BitmaskOptionValue("-alignright",      perlcs->cs.style, TCS_RIGHT) 
    } else if BitmaskOptionValue("-hottrack",        perlcs->cs.style, TCS_HOTTRACK)
    } else if BitmaskOptionValue("-buttons",         perlcs->cs.style, TCS_BUTTONS)
    } else if BitmaskOptionValue("-flat",            perlcs->cs.style, TCS_FLATBUTTONS)
    } else if BitmaskOptionValue("-multiselect",     perlcs->cs.style, TCS_MULTISELECT)
    } else if BitmaskOptionValue("-forceiconleft",   perlcs->cs.style, TCS_FORCEICONLEFT)
    } else if BitmaskOptionValue("-forcelabelleft",  perlcs->cs.style, TCS_FORCELABELLEFT)
    } else if BitmaskOptionValue("-fixedwidth",      perlcs->cs.style, TCS_FIXEDWIDTH)
    } else if BitmaskOptionValue("-raggedright",     perlcs->cs.style, TCS_RAGGEDRIGHT)
    } else if BitmaskOptionValue("-focusbottondown", perlcs->cs.style, TCS_FOCUSONBUTTONDOWN)
    } else if BitmaskOptionValue("-focusnever",      perlcs->cs.style, TCS_FOCUSNEVER)
    } else if BitmaskOptionValueMask("-flatseparator",   perlcs->dwFlags,  TCS_EX_FLATSEPARATORS)
    } else retval = FALSE;

    return retval;
}

void
TabStrip_onPostCreate(NOTXSPROC HWND myhandle, LPPERLWIN32GUI_CREATESTRUCT perlcs) {

    if (perlcs->dwFlagsMask != 0)
        TabCtrl_SetExtendedStyle(myhandle, perlcs->dwFlags);

    if(perlcs->hImageList != NULL)
        TabCtrl_SetImageList(myhandle, perlcs->hImageList);

    if (perlcs->hTooltip != NULL) 
        TabCtrl_SetToolTips (myhandle, perlcs->hTooltip);
}

BOOL
TabStrip_onParseEvent(NOTXSPROC char *name, int* eventID) {

    BOOL retval = TRUE;

         if Parse_Event("Changing",    PERLWIN32GUI_NEM_CONTROL1)
    else if Parse_Event("Change",      PERLWIN32GUI_NEM_CONTROL2)
    else retval = FALSE;

    return retval;
}

int
TabStrip_onEvent (NOTXSPROC LPPERLWIN32GUI_USERDATA perlud, UINT uMsg, WPARAM wParam, LPARAM lParam) {

    int PerlResult = 1;
    
    if ( uMsg == WM_NOTIFY ) {

        LPNMHDR notify = (LPNMHDR) lParam;
        switch(notify->code) {

        case TCN_SELCHANGING:

            /*
             * (@)EVENT:Changing()
             * Sent before the current selection changes.
             * Use SelectedItem() to determine the
             * current selection.
             * The event should return 0 to prevent
             * the selection changing, 1 to allow it.
             * (@)APPLIES_TO:TabStrip
             */

            PerlResult = DoEvent(NOTXSCALL perlud, PERLWIN32GUI_NEM_CONTROL1, "Changing", -1);

            // Force result if event is handle
            if (perlud->dwPlStyle & PERLWIN32GUI_EVENTHANDLING) {
                perlud->forceResult = (PerlResult == 0 ? TRUE : FALSE);
                PerlResult = 0; // MsgLoop return ForceResult 
            }
            break;

        case TCN_SELCHANGE:
            /*
             * (@)EVENT:Change()
             * Sent when the current
             * selection has changed. Use SelectedItem()
             * to determine the current selection.
             * (@)APPLIES_TO:TabStrip
             */
            PerlResult = DoEvent(NOTXSCALL perlud, PERLWIN32GUI_NEM_CONTROL2, "Change", -1);
            break;
        } 
    }
    return PerlResult;
}

MODULE = Win32::GUI::TabStrip       PACKAGE = Win32::GUI::TabStrip

PROTOTYPES: DISABLE

#pragma message( "*** PACKAGE Win32::GUI::TabStrip..." )

      ################################################
      # (@)METHOD:AdjustRect(LEFT, TOP, RIGHT, BOTTOM, [FLAG=0])
      # Calculates a tab control's display area given a window rectangle, or calculates the window rectangle that would correspond to a specified display area.
      # If FLAG is 0, rect specifies a window rectangle and receives the corresponding display area.
      # Otherwise, rect specifies a display rectangle and receives the corresponding window rectangle.
void
AdjustRect(handle,left,top,right,bottom,flag=0)
    HWND handle
    int left
    int top
    int right
    int bottom
    BOOL flag
PREINIT:
    RECT myRect;
PPCODE:
    myRect.left   = left;
    myRect.top    = top;
    myRect.right  = right;
    myRect.bottom = bottom;
    TabCtrl_AdjustRect(handle, flag, &myRect);
    EXTEND(SP, 4);
    XST_mIV(0, myRect.left);
    XST_mIV(1, myRect.top);
    XST_mIV(2, myRect.right);
    XST_mIV(3, myRect.bottom);
    XSRETURN(4);

    ###########################################################################
    # (@)METHOD:Reset()
    # (@)METHOD:DeleteAllItems()
    # Deletes all items from the TabStrip.
BOOL
DeleteAllItems(handle)
    HWND handle
ALIAS:
    Win32::GUI::TabStrip::Reset = 1
CODE:
    RETVAL = TabCtrl_DeleteAllItems(handle);
OUTPUT:
    RETVAL

    ###########################################################################
    # (@)METHOD:DeleteItem(ITEM)
    # Removes the specified ITEM from the TabStrip.
BOOL
DeleteItem(handle,item)
    HWND handle
    int item
CODE:
    RETVAL = TabCtrl_DeleteItem(handle, item);
OUTPUT:
    RETVAL

    ###########################################################################
    # (@)METHOD:DeselectAll([ExcludeFocus=0])
    # Resets items in a tab control, clearing any that were set to the TCIS_BUTTONPRESSED state.
    # If ExcludeFocus is set to 0, all tab items will be reset. Otherwise, all but the currently selected tab item will be reset. 

void
DeselectAll(handle,ExcludeFocus=0)
    HWND handle
    int ExcludeFocus
CODE:
    TabCtrl_DeselectAll(handle, ExcludeFocus);

    ###########################################################################
    # (@)METHOD:GetCurFocus()
    # Returns the index of the item that has the focus in a tab control
int
GetCurFocus(handle)
    HWND handle
CODE:
    RETVAL = TabCtrl_GetCurFocus(handle);
OUTPUT:
    RETVAL

    ###########################################################################
    # (@)METHOD:SelectedItem()
    # (@)METHOD:GetCurSel()
    # Returns the zero-based index of the currently selected item.
int
GetCurSel(handle)
    HWND handle
ALIAS:
    Win32::GUI::TabStrip::SelectedItem = 1
CODE:
    RETVAL = TabCtrl_GetCurSel(handle);
OUTPUT:
    RETVAL

    ###########################################################################
    # (@)METHOD:GetExtendedStyle()
    # Retrieves the extended styles that are currently in use for TabStrip.
DWORD
GetExtendedStyle(handle)
    HWND handle
CODE:
    RETVAL = TabCtrl_GetExtendedStyle(handle);
OUTPUT:
    RETVAL

    ###########################################################################
    # (@)METHOD:GetImageList()
    # Retrieves the image list handle associated with a tab control.
HIMAGELIST
GetImageList(handle)
    HWND handle
CODE:
    RETVAL = TabCtrl_GetImageList(handle);
OUTPUT:
    RETVAL

    ###########################################################################
    # (@)METHOD:GetItem(ITEM)
    # Retrieves information about an ITEM in the TabStrip.
void
GetItem(handle,item)
    HWND handle
    int item
PREINIT:
    char szString [1024];
    TC_ITEM tcItem;
PPCODE:
    ZeroMemory(&tcItem, sizeof(TC_ITEM));
    tcItem.pszText = szString;
    tcItem.cchTextMax = 1024;
    tcItem.mask = TCIF_TEXT | TCIF_STATE | TCIF_IMAGE;
    if(TabCtrl_GetItem(handle, item, &tcItem)) {
        EXTEND(SP, 6);
        XST_mPV(0, "-text");
        XST_mPV(1, tcItem.pszText);
        XST_mPV(2, "-image");
        XST_mIV(3, tcItem.iImage);
        XST_mPV(4, "-state");
        XST_mIV(5, tcItem.dwState);
        XSRETURN(6);
    } else {
        XSRETURN_UNDEF;
    }

    ###########################################################################
    # (@)METHOD:Count()
    # (@)METHOD:GetItemCount()
    # Returns the number of items in the TabStrip.
int
GetItemCount(handle)
    HWND handle
ALIAS:
    Win32::GUI::TabStrip::Count = 1
CODE:
    RETVAL = TabCtrl_GetItemCount(handle);
OUTPUT:
    RETVAL

    ###########################################################################
    # (@)METHOD:GetItemRect(index)
    # Retrieves the bounding rectangle for a tab in a tab control
void
GetItemRect(handle,index)
    HWND handle
    int index
PREINIT:
    RECT myRect;
PPCODE:
    ZeroMemory(&myRect, sizeof(RECT));
    if(TabCtrl_GetItemRect(handle, index, &myRect)) {
        EXTEND(SP, 4);
        XST_mIV(0, myRect.left);
        XST_mIV(1, myRect.top);
        XST_mIV(2, myRect.right);
        XST_mIV(3, myRect.bottom);
        XSRETURN(4);
    } else {
        XSRETURN_UNDEF;
    }

    ###########################################################################
    # (@)METHOD:RowCount()
    # (@)METHOD:GetRowCount()
    # Retrieves the current number of rows of tabs in a tab control.
int
GetRowCount(handle)
    HWND handle
ALIAS:
    Win32::GUI::TabStrip::RowCount = 1
CODE:
    RETVAL = TabCtrl_GetRowCount(handle);
OUTPUT:
    RETVAL

    ###########################################################################
    # (@)METHOD:GetToolTips()
    # Retrieves the handle to the tooltip control associated with a tab control.
HWND
GetToolTips(handle)
    HWND handle
CODE:
    RETVAL = TabCtrl_GetToolTips(handle);
OUTPUT:
    RETVAL

    ###########################################################################
    # (@)METHOD:GetUnicodeFormat()
    # Retrieves the UNICODE character format flag.
BOOL
GetUnicodeFormat(handle)
    HWND handle
CODE:
    RETVAL = TabCtrl_GetUnicodeFormat(handle);
OUTPUT:
    RETVAL

    ###########################################################################
    # (@)METHOD:HighlightItem(index, [fHighlight=1])
    # Sets the highlight state of a tab item.
    # If fHighlight is nonzero, the tab is highlighted. If fHighlight is zero, the tab is set to its default state. 
BOOL 
HighlightItem(handle, index, fHighlight=1)
    HWND handle         
    int index       
    int fHighlight
CODE:
    RETVAL = TabCtrl_HighlightItem(handle, index, (WORD) fHighlight);
OUTPUT:
    RETVAL

    ###########################################################################
    # (@)METHOD:HitTest(X,Y)
    # Determines which tab, if any, is at a specified screen position.
void
HitTest(handle,x,y,flags=0)
    HWND handle
    int x
    int y
PREINIT:
    TCHITTESTINFO ht;
    int index;
PPCODE:
    ZeroMemory(&ht, sizeof(TCHITTESTINFO));
    ht.pt.x = x;
    ht.pt.y = y;
    index = TabCtrl_HitTest(handle, &ht);
    if(GIMME == G_ARRAY) {
        EXTEND(SP, 2);
        XST_mIV(0, index);
        XST_mIV(1, ht.flags);
        XSRETURN(2);
    } else {
        XSRETURN_IV(index);
    }

    ###########################################################################
    # (@)METHOD:InsertItem(%OPTIONS)
    # Adds an item to the TabStrip.
    # Allowed %OPTIONS are:
    #  -image => NUMBER
    #    the index of an image from the associated ImageList
    #  -index => NUMBER
    #    the position for the new item (if not specified, the item
    #    is added at the end of the control)
    #  -text  => STRING
    #    the text that will appear on the item
int
InsertItem(handle,...)
    HWND handle
PREINIT:
    TC_ITEM Item;
    int iIndex;
    STRLEN chText;
    int i, next_i;
CODE:
    ZeroMemory(&Item, sizeof(TC_ITEM));
    iIndex = TabCtrl_GetItemCount(handle)+1;
    next_i = -1;
    for(i = 1; i < items; i++) {
        if(next_i == -1) {
            if(strcmp(SvPV_nolen(ST(i)), "-image") == 0) {
                next_i = i + 1;
                Item.iImage = (int)SvIV(ST(next_i));
                Item.mask |= TCIF_IMAGE;
            }
            else if(strcmp(SvPV_nolen(ST(i)), "-index") == 0) {
                next_i = i + 1;
                iIndex = (int) SvIV(ST(next_i));
            }
            else if(strcmp(SvPV_nolen(ST(i)), "-text") == 0) {
                next_i = i + 1;
                Item.pszText = SvPV(ST(next_i), chText);
                Item.cchTextMax = (int) chText;
                Item.mask |=  TCIF_TEXT;
            }
        } else {
            next_i = -1;
        }
    }
    RETVAL = TabCtrl_InsertItem(handle, iIndex, &Item);
OUTPUT:
    RETVAL

    ###########################################################################
    # (@)METHOD:RemoveImage(iImage)
    # Removes an image from a tab control's image list.
    # The tab control updates each tab's image index, so each tab remains associated
    # with the same image as before. If a tab is using the image being removed, 
    # the tab will be set to have no image.
void
RemoveImage(handle, iImage)
    HWND handle
    int iImage      
CODE:
    TabCtrl_RemoveImage(handle, iImage);

    ###########################################################################
    # (@)METHOD:SetCurFocus(index)
    # Sets the focus to a specified tab in a tab control.
    # Returns the index of the previously selected tab if successful, or -1 otherwise. 
void
SetCurFocus(handle, index)
    HWND handle
    int index       
CODE:
    TabCtrl_SetCurFocus(handle, index);

    ###########################################################################
    # (@)METHOD:Select(INDEX)
    # (@)METHOD:SetCurSel(index)
    # Selects a tab in a tab control.
    # Returns the index of the previously selected tab if successful, or -1 otherwise. 
int
SetCurSel(handle, index)
    HWND handle
    int index
ALIAS:
    Win32::GUI::TabStrip::Select = 1            
CODE:
    RETVAL = TabCtrl_SetCurSel(handle, index);
OUTPUT:
    RETVAL

    ###########################################################################
    # (@)METHOD:SetExtendedStyle(STYLE)
    # Sets the extended styles that the TabStrip will use.
DWORD
SetExtendedStyle(handle, style)
    HWND handle
    DWORD style
CODE:
    RETVAL = TabCtrl_SetExtendedStyle(handle, style);
OUTPUT:
    RETVAL

    ###########################################################################
    # (@)METHOD:SetImageList(IMAGELIST)
    # Assigns an image list to a tab control. 
    # Return previous imagelist
HIMAGELIST
SetImageList(handle,imagelist)
    HWND handle
    HIMAGELIST imagelist
CODE:
    RETVAL = TabCtrl_SetImageList(handle, imagelist);
OUTPUT:
    RETVAL

    ###########################################################################
    # (@)METHOD:ChangeItem(ITEM, %OPTIONS)
    # (@)METHOD:SetItem(ITEM, %OPTIONS)
    # Change most of the options used when the item was created
    # (see InsertItem()).
    # Allowed B<%OPTIONS> are:
    #     -image
    #     -text
BOOL
SetItem(handle,item,...)
    HWND handle
    int item
ALIAS:
    Win32::GUI::TabStrip::ChangeItem = 1     
PREINIT:
    TC_ITEM Item;
    STRLEN chText;
    int i, next_i;
CODE:
    ZeroMemory(&Item, sizeof(TC_ITEM));
    next_i = -1;
    for(i = 2; i < items; i++) {
        if(next_i == -1) {
            if(strcmp(SvPV_nolen(ST(i)), "-image") == 0) {
                next_i = i + 1;
                Item.mask = Item.mask | TCIF_IMAGE;
                Item.iImage = (int)SvIV(ST(next_i));
            }
            if(strcmp(SvPV_nolen(ST(i)), "-text") == 0) {
                next_i = i + 1;
                Item.pszText = SvPV(ST(next_i), chText);
                Item.cchTextMax = (int) chText;
                Item.mask = Item.mask | TCIF_TEXT;
            }
        } else {
            next_i = -1;
        }
    }
    RETVAL = TabCtrl_SetItem(handle, item, &Item);
OUTPUT:
    RETVAL

    # TODO : TabCtrl_SetItemExtra

    ###########################################################################
    # (@)METHOD:SetItemSize(STYLE)
    # Sets the width and height of tabs in a fixed-width.
DWORD
SetItemSize(handle,x,y)
    HWND handle
    int x
    int y
CODE:
    RETVAL = TabCtrl_SetItemSize(handle, x, y);
OUTPUT:
    RETVAL

    ###########################################################################
    # (@)METHOD:MinTabWidth(WIDTH)
    # (@)METHOD:SetMinTabWidth(WIDTH)
    # Sets the minimum width of items in a tab control.
int
SetMinTabWidth(handle,width)
    HWND handle
    int width
ALIAS:
    Win32::GUI::TabStrip::MinTabWidth = 1
CODE:
    RETVAL = TabCtrl_SetMinTabWidth(handle, width);
OUTPUT:
    RETVAL

    ################################################
    # (@)METHOD:Padding(X,Y)
    # (@)METHOD:SetPadding(X,Y)
    # Sets the amount of space (padding) around each tab's icon and label in a tab control. 
void
SetPadding(handle,x,y)
    HWND handle
    int x
    int y
ALIAS:
    Win32::GUI::TabStrip::Padding = 1
CODE:
    TabCtrl_SetPadding(handle, x, y);

    ################################################
    # (@)METHOD:SetToolTips(TOOLTIP)
    # Assigns a tooltip to a TabStrip.
void
SetToolTips(handle,tooltip)
    HWND handle
    HWND tooltip
CODE:
    TabCtrl_SetToolTips(handle,tooltip);

    ###########################################################################
    # (@)METHOD:SetUnicodeFormat(FLAG)
    # Set the UNICODE character format flag.
BOOL
SetUnicodeFormat(handle,flag)
    HWND handle
    BOOL flag
CODE:
    RETVAL = TabCtrl_SetUnicodeFormat(handle, flag);
OUTPUT:
    RETVAL

    ###########################################################################
    ###########################################################################
    ###########################################################################

    ###########################################################################
    # (@)METHOD:GetString(ITEM)
    # Returns the string associated with the specified ITEM in the TabStrip.
void
GetString(handle,item)
    HWND handle
    int item
PREINIT:
    char *szString;
    TC_ITEM tcItem;
PPCODE:
    szString = (char *) safemalloc(1024);
    tcItem.pszText = szString;
    tcItem.cchTextMax = 1024;
    tcItem.mask = TCIF_TEXT;
    if(TabCtrl_GetItem(handle, item, &tcItem)) {
        EXTEND(SP, 1);
        XST_mPV(0, szString);
        safefree(szString);
        XSRETURN(1);
    } else {
        safefree(szString);
        XSRETURN_UNDEF;
    }

    ###########################################################################
    # (@)METHOD:DisplayArea()
    # Retrieve position en size of Display Area.
    # Return an array (x, y, width, heigth)
void
DisplayArea(handle)
    HWND   handle
PREINIT:
    RECT    myRect;
PPCODE:
    GetClientRect (handle, &myRect);
    TabCtrl_AdjustRect(handle, 0, &myRect);
    EXTEND(SP, 4);
    XST_mIV(0, myRect.left);
    XST_mIV(1, myRect.top);
    XST_mIV(2, myRect.right  - myRect.left);
    XST_mIV(3, myRect.bottom - myRect.top);
    XSRETURN(4);
