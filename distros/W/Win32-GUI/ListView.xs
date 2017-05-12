    /*
    ###########################################################################
    # (@)PACKAGE:Win32::GUI::ListView
    #
    # $Id: ListView.xs,v 1.16 2010/04/08 21:26:48 jwgui Exp $
    #
    ###########################################################################
    */

#include "GUI.h"

void 
ListView_onPreCreate(NOTXSPROC LPPERLWIN32GUI_CREATESTRUCT perlcs) {

    perlcs->cs.lpszClass = WC_LISTVIEW;
    perlcs->cs.style = WS_VISIBLE | WS_CHILD | WS_BORDER | LVS_REPORT | LVS_SHOWSELALWAYS;
    perlcs->cs.dwExStyle = WS_EX_CLIENTEDGE;
}

BOOL
ListView_onParseOption(NOTXSPROC char *option, SV* value, LPPERLWIN32GUI_CREATESTRUCT perlcs) {

    BOOL retval = TRUE;

    if(strcmp(option, "-align") == 0) {
        if(strcmp(SvPV_nolen(value), "left") == 0) {
            SwitchBit(perlcs->cs.style, LVS_ALIGNLEFT, 1);
            SwitchBit(perlcs->cs.style, LVS_ALIGNTOP, 0);
        } else if(strcmp(SvPV_nolen(value), "top") == 0) {
            SwitchBit(perlcs->cs.style, LVS_ALIGNLEFT, 0);
            SwitchBit(perlcs->cs.style, LVS_ALIGNTOP, 1);
        } else {
            W32G_WARN("Win32::GUI: Invalid value for -align!");
        }
    } else if(strcmp(option, "-imagelist") == 0) {
        perlcs->hImageList = (HIMAGELIST) handle_From(NOTXSCALL value);
    
    } else if BitmaskOptionValue("-report",           perlcs->cs.style, LVS_REPORT)
    } else if BitmaskOptionValue("-list",             perlcs->cs.style, LVS_LIST)
    } else if BitmaskOptionValue("-singlesel",        perlcs->cs.style, LVS_SINGLESEL)    
    } else if BitmaskOptionValue("-showselalways",    perlcs->cs.style, LVS_SHOWSELALWAYS)
    } else if BitmaskOptionValue("-sortascending",    perlcs->cs.style, LVS_SORTASCENDING)
    } else if BitmaskOptionValue("-sortdescending",   perlcs->cs.style, LVS_SORTDESCENDING)
    } else if BitmaskOptionValue("-nolabelwrap",      perlcs->cs.style, LVS_NOLABELWRAP)
    } else if BitmaskOptionValue("-autoarrange",      perlcs->cs.style, LVS_AUTOARRANGE)
    } else if BitmaskOptionValue("-editlabel",        perlcs->cs.style, LVS_EDITLABELS)
    } else if BitmaskOptionValue("-noscroll",         perlcs->cs.style, LVS_NOSCROLL)
    } else if BitmaskOptionValue("-alignleft",        perlcs->cs.style, LVS_ALIGNLEFT)
    } else if BitmaskOptionValue("-ownerdrawfixed",   perlcs->cs.style, LVS_OWNERDRAWFIXED)
    } else if BitmaskOptionValue("-nocolumnheader",   perlcs->cs.style, LVS_NOCOLUMNHEADER)
    } else if BitmaskOptionValue("-nosortheader",     perlcs->cs.style, LVS_NOSORTHEADER)
    } else if BitmaskOptionValueMask("-gridlines",        perlcs->dwFlags,  LVS_EX_GRIDLINES)
    } else if BitmaskOptionValueMask("-subitemimages",    perlcs->dwFlags,  LVS_EX_SUBITEMIMAGES)
    } else if BitmaskOptionValueMask("-checkboxes",       perlcs->dwFlags,  LVS_EX_CHECKBOXES)
    } else if BitmaskOptionValueMask("-hottrack",         perlcs->dwFlags,  LVS_EX_TRACKSELECT)
    } else if BitmaskOptionValueMask("-reordercolumns",   perlcs->dwFlags,  LVS_EX_HEADERDRAGDROP)
    } else if BitmaskOptionValueMask("-fullrowselect",    perlcs->dwFlags,  LVS_EX_FULLROWSELECT)
    } else if BitmaskOptionValueMask("-oneclickactivate", perlcs->dwFlags,  LVS_EX_ONECLICKACTIVATE)
    } else if BitmaskOptionValueMask("-twoclickactivate", perlcs->dwFlags,  LVS_EX_TWOCLICKACTIVATE)
    } else if BitmaskOptionValueMask("-flatsb",           perlcs->dwFlags,  LVS_EX_FLATSB)
    } else if BitmaskOptionValueMask("-regional",         perlcs->dwFlags,  LVS_EX_REGIONAL)
    } else if BitmaskOptionValueMask("-infotip",          perlcs->dwFlags,  LVS_EX_INFOTIP)
    } else if BitmaskOptionValueMask("-labeltip",         perlcs->dwFlags,  LVS_EX_LABELTIP) // Version 5.80
    } else if BitmaskOptionValueMask("-underlinehot",     perlcs->dwFlags,  LVS_EX_UNDERLINEHOT)
    } else if BitmaskOptionValueMask("-underlinecold",    perlcs->dwFlags,  LVS_EX_UNDERLINECOLD)
    } else if BitmaskOptionValueMask("-multiworkareas",   perlcs->dwFlags,  LVS_EX_MULTIWORKAREAS)
    } else retval = FALSE;

    return retval;
}

void
ListView_onPostCreate(NOTXSPROC HWND myhandle, LPPERLWIN32GUI_CREATESTRUCT perlcs) {

    if (perlcs->dwFlagsMask != 0)
        ListView_SetExtendedListViewStyleEx(myhandle, perlcs->dwFlagsMask, perlcs->dwFlags);

    if(perlcs->hImageList != NULL) {
        ListView_SetImageList(myhandle, perlcs->hImageList, LVSIL_NORMAL);
        ListView_SetImageList(myhandle, perlcs->hImageList, LVSIL_SMALL);
    }
    if(perlcs->clrBackground != CLR_INVALID) {
        SendMessage((HWND)myhandle, LVM_SETBKCOLOR, (WPARAM) 0, (LPARAM) perlcs->clrBackground);
        perlcs->clrBackground = CLR_INVALID;  // Don't store  
    }
}

BOOL
ListView_onParseEvent(NOTXSPROC char *name, int* eventID) {

    BOOL retval = TRUE;

         if Parse_Event("ItemChanging",   PERLWIN32GUI_NEM_CONTROL1)
    else if Parse_Event("ItemChanged",    PERLWIN32GUI_NEM_CONTROL2)
    else if Parse_Event("ItemClick",      PERLWIN32GUI_NEM_CONTROL3)
    else if Parse_Event("ItemCheck",      PERLWIN32GUI_NEM_CONTROL4)
    else if Parse_Event("ColumnClick",    PERLWIN32GUI_NEM_CONTROL5)
    else if Parse_Event("BeginLabelEdit", PERLWIN32GUI_NEM_CONTROL6)
    else if Parse_Event("EndLabelEdit",   PERLWIN32GUI_NEM_CONTROL7)
    else if Parse_Event("BeginDrag",      PERLWIN32GUI_NEM_CONTROL8)
    else if Parse_Event("KeyDown",        PERLWIN32GUI_NEM_KEYDOWN)
    else retval = FALSE;


    return retval;
}

int
ListView_onEvent (NOTXSPROC LPPERLWIN32GUI_USERDATA perlud, UINT uMsg, WPARAM wParam, LPARAM lParam) {

    int PerlResult = 1;
    LV_ITEM *pItem;

    if ( uMsg == WM_NOTIFY ) {

        LPNM_LISTVIEW lv_notify = (LPNM_LISTVIEW) lParam;

        switch(lv_notify->hdr.code) {

        // TODO :  case LVN_INSERTITEM :
        case LVN_BEGINDRAG:
        /*
         * (@)EVENT:BeginDrag(ITEM)
         * Notifies a list-view control that a drag-and-drop operation involving the left mouse 
         * button is being initiated. Passes the item being dragged.
         * (@)APPLIES_TO:ListView
         */        
          PerlResult = DoEvent(NOTXSCALL perlud, PERLWIN32GUI_NEM_CONTROL8, "BeginDrag",
                       PERLWIN32GUI_ARGTYPE_LONG, (LONG) lv_notify->iItem,-1);
        break;
        /*
         * (@)EVENT:ItemChanging(ITEM, NEWSTATE, OLDSTATE, CHANGED)
         * Sent when the item is about to change state.
         * The event should return 0 to prevent the action, 1 to allow it.
         * ITEM specifies the zero-based index of the selected item.
         * NEWSTATE specifies the new item state (LVIS_).
         * OLDSTATE specifies the old item state (LVIS_).
         * CHANGED specifies the item attributes that have changed (LVIF_).
         * (@)APPLIES_TO:ListView
         */        

        case LVN_ITEMCHANGING:

            PerlResult = DoEvent(NOTXSCALL perlud, PERLWIN32GUI_NEM_CONTROL1, "ItemChanging",
               PERLWIN32GUI_ARGTYPE_LONG, (LONG) lv_notify->iItem,
               PERLWIN32GUI_ARGTYPE_LONG, (LONG) lv_notify->uNewState,
               PERLWIN32GUI_ARGTYPE_LONG, (LONG) lv_notify->uOldState,
               PERLWIN32GUI_ARGTYPE_LONG, (LONG) lv_notify->uChanged,
               -1);

           // Force result if event is handle
           if (perlud->dwPlStyle & PERLWIN32GUI_EVENTHANDLING) {
               perlud->forceResult = (PerlResult == 0 ? TRUE : FALSE);
               PerlResult = 0; // MsgLoop return ForceResult
           }

            break;
 
        /*
         * (@)EVENT:ItemChanged(ITEM, NEWSTATE, OLDSTATE, CHANGED)
         * Sent for any change of state of an item in the ListView.
         * ITEM specifies the zero-based index of the selected item.
         * NEWSTATE specifies the new item state (LVIS_).
         * OLDSTATE specifies the old item state (LVIS_).
         * CHANGED specifies the item attributes that have changed (LVIF_).
         * (@)APPLIES_TO:ListView
         */

        case LVN_ITEMCHANGED:

            PerlResult = DoEvent(NOTXSCALL perlud, PERLWIN32GUI_NEM_CONTROL2, "ItemChanged",
               PERLWIN32GUI_ARGTYPE_LONG, (LONG) lv_notify->iItem,
               PERLWIN32GUI_ARGTYPE_LONG, (LONG) lv_notify->uNewState,
               PERLWIN32GUI_ARGTYPE_LONG, (LONG) lv_notify->uOldState,
               PERLWIN32GUI_ARGTYPE_LONG, (LONG) lv_notify->uChanged,
               -1);

            if(lv_notify->uChanged & LVIF_STATE &&
               lv_notify->uNewState & LVIS_SELECTED) {
                /*
                 * (@)EVENT:ItemClick(ITEM)
                 * Sent when the user selects an item in the ListView;
                 * ITEM specifies the zero-based index of the selected item.
                 * (@)APPLIES_TO:ListView
                 */
                PerlResult = DoEvent(NOTXSCALL perlud, PERLWIN32GUI_NEM_CONTROL3, "ItemClick",
                    PERLWIN32GUI_ARGTYPE_LONG, (LONG) lv_notify->iItem,
                    -1);
            }
            if(lv_notify->uChanged & LVIF_STATE &&
               (lv_notify->uOldState & LVIS_STATEIMAGEMASK) != (lv_notify->uNewState & LVIS_STATEIMAGEMASK)) {
                /*
                 * (@)EVENT:ItemCheck(ITEM)
                 * Sent when the user changes the checkbox of an item in the ListView;
                 * ITEM specifies the zero-based index of the selected item.
                 * (@)APPLIES_TO:ListView
                 */
                PerlResult = DoEvent(NOTXSCALL perlud, PERLWIN32GUI_NEM_CONTROL4, "ItemCheck",
                    PERLWIN32GUI_ARGTYPE_LONG, (LONG) lv_notify->iItem,
                    -1);
            }

            break;

        // TODO : LVN_DELETEITEM :
        // TODO : LVN_ITEMACTIVATE
 
        case LVN_COLUMNCLICK:
            /*
             * (@)EVENT:ColumnClick(ITEM)
             * Sent when the user clicks on a column header in the
             * ListView; ITEM specifies the one-based index of the
             * selected column.
             * (@)APPLIES_TO:ListView
             */
            PerlResult = DoEvent(NOTXSCALL perlud, PERLWIN32GUI_NEM_CONTROL5, "ColumnClick",
                PERLWIN32GUI_ARGTYPE_LONG, (LONG) lv_notify->iSubItem,
                -1);

            break;

           /*
            * (@)EVENT:BeginLabelEdit(ITEM)
            * Sent when the user is about to edit the specified item of the ListView
            * The event should return 0 to prevent the action, 1 to allow it.
            *
            * For a ListView to receive this event, -editlabels need to be set to true.
            * (@)APPLIES_TO:ListView
            */        

        case LVN_BEGINLABELEDIT:
            pItem = &((LV_DISPINFO*)lParam)->item;
            PerlResult = DoEvent(NOTXSCALL perlud, PERLWIN32GUI_NEM_CONTROL6, "BeginLabelEdit",
                PERLWIN32GUI_ARGTYPE_LONG, (LONG) pItem->iItem,
                -1);

           // Force result if event is handle
           if (perlud->dwPlStyle & PERLWIN32GUI_EVENTHANDLING) {
               perlud->forceResult = (PerlResult == 0 ? TRUE : FALSE);
               PerlResult = 0; // MsgLoop return ForceResult
           }

            break;
 
            /*
             * (@)EVENT:EndLabelEdit(ITEM,TEXT)
             * Sent when the user has finished editing a label in the ListView control.
             * You have explicitly set the text of the item to reflect the new changes. 
             * If the user cancels the edit, the text is undef.
             * (@)APPLIES_TO:ListView
             */

        case LVN_ENDLABELEDIT: 

           pItem = &((LV_DISPINFO*)lParam)->item;
           if ( pItem->pszText != NULL) {
             PerlResult = DoEvent(NOTXSCALL perlud, PERLWIN32GUI_NEM_CONTROL7, "EndLabelEdit",
                PERLWIN32GUI_ARGTYPE_LONG,   (LONG) pItem->iItem,
                PERLWIN32GUI_ARGTYPE_STRING, pItem->pszText,
                -1);
             }
           else {
             //user has canceled the edit
             PerlResult = DoEvent(NOTXSCALL perlud, PERLWIN32GUI_NEM_CONTROL7, "EndLabelEdit",
                PERLWIN32GUI_ARGTYPE_LONG, (LONG) pItem->iItem,
                -1);           
           }
 
            break;

        case LVN_KEYDOWN:
            {
                LV_KEYDOWN FAR * lv_keydown = (LV_KEYDOWN FAR *) lParam;
                /*
                 * (@)EVENT:KeyDown(KEY)
                 * Sent when the user presses a key while the ListView
                 * control has focus; KEY is the ASCII code of the
                 * key being pressed.
                 * (@)APPLIES_TO:ListView
                 */
                PerlResult = DoEvent(NOTXSCALL perlud, PERLWIN32GUI_NEM_KEYDOWN, "KeyDown",
                    PERLWIN32GUI_ARGTYPE_LONG, (LONG) lv_keydown->wVKey,
                    -1);

            }
            break;
        // TODO : LVN_HOTTRACK
        }
    }

    return PerlResult;
}

MODULE = Win32::GUI::ListView       PACKAGE = Win32::GUI::ListView

PROTOTYPES: DISABLE

#pragma message( "*** PACKAGE Win32::GUI::ListView..." )


    ###########################################################################
    # (@)METHOD:ApproximateViewRect(cx,cy,icount=-1)
    # Calculates the approximate width and height required to display a given number of items.
DWORD
ApproximateViewRect(handle,cx,cy,icount=-1)
    HWND handle
    int cx
    int cy
    int icount
CODE:
    RETVAL = ListView_ApproximateViewRect(handle, cx, cy, icount);
OUTPUT:
    RETVAL

    ###########################################################################
    # (@)METHOD:Arrange([FLAG])
    #
    # LVA_ALIGNLEFT = Aligns items along the left edge of the window. 
    # LVA_ALIGNTOP = Aligns items along the top edge of the window. 
    # LVA_DEFAULT = Aligns items according to the ListView's current alignment styles (the default value). 
    # LVA_SNAPTOGRID = Snaps all icons to the nearest grid position. 

int
Arrange(handle,flag=LVA_DEFAULT)
    HWND handle
    UINT flag
CODE:
    RETVAL = ListView_Arrange(handle, flag);
OUTPUT:
    RETVAL

    ###########################################################################
    # (@)METHOD:CreateDragImage(index, xcor, ycor)
    # Creates a transparent version of an item image. The xcor and yxcor are the 
    # initial location of the  upper-left corner of the image.
HIMAGELIST
CreateDragImage(handle, index, xcor, ycor)
    HWND handle
    int index
    int xcor
    int ycor
PREINIT:
    POINT pt;
CODE:
    pt.x=xcor;
    pt.y=ycor;
    RETVAL = (HIMAGELIST) ListView_CreateDragImage(handle, index, &pt);
OUTPUT:
    RETVAL
    
    ###########################################################################
    # (@)METHOD:DeleteAllItems()
    # (@)METHOD:Clear()
    # Deletes all items from the ListView.
BOOL
DeleteAllItems(handle)
    HWND handle
ALIAS:
    Win32::GUI::ListView::Clear = 1
CODE:
    RETVAL = ListView_DeleteAllItems(handle);
OUTPUT:
    RETVAL

    ###########################################################################
    # (@)METHOD:DeleteColumn(INDEX)
    # Removes a column from a ListView.
BOOL
DeleteColumn(handle,index)
    HWND handle
    int index
CODE:
    RETVAL = ListView_DeleteColumn(handle, index);
OUTPUT:
    RETVAL

    ###########################################################################
    # (@)METHOD:DeleteItem(INDEX)
    # Removes the zero-based INDEX item from the ListView.
BOOL
DeleteItem(handle,index)
    HWND handle
    int index
CODE:
    RETVAL = ListView_DeleteItem(handle, index);
OUTPUT:
    RETVAL

    ###########################################################################
    # (@)METHOD:EditLabel(INDEX)
    # Begins in-place editing of the specified list view item's text.
HWND
EditLabel(handle,index)
    HWND handle
    int index
CODE:
    RETVAL = ListView_EditLabel(handle, index);
OUTPUT:
    RETVAL

    ###########################################################################
    # (@)METHOD:EnsureVisible(INDEX, [FLAG])
    # Ensures that a list view item is either entirely or partially visible, scrolling the ListView if necessary.
BOOL
EnsureVisible(handle,index,flag=TRUE)
    HWND handle
    int index
    BOOL flag
CODE:
    RETVAL = ListView_EnsureVisible(handle, index, flag);
OUTPUT:
    RETVAL
    
    ###########################################################################
    # (@)METHOD:FindItem(FROM, %OPTIONS)
    # Searches for a list view item with the specified characteristics.
    #
    # B<%OPTIONS> :
    #  -string => STRING
    #     Item must exactly match the string.
    #  -prefix => 0/1
    #     Find item text begins with the string.
    #  -wrap   => 0/1
    #     Continues the search at the beginning if no match is found.
int
FindItem(handle, ifrom, ...)
    HWND handle
    int ifrom
PREINIT :
    LVFINDINFO fi;
    int i, next_i;
    char * option;
CODE:
    ZeroMemory(&fi, sizeof(LVFINDINFO));
    next_i = -1;
    for(i = 2; i < items; i++) {
        if(next_i == -1) {
            option = SvPV_nolen(ST(i));
            if(strcmp(option, "-string") == 0) {
                next_i = i + 1;
                fi.psz  = SvPV_nolen(ST(next_i));
                fi.flags |= LVFI_STRING;
            } else if(strcmp(option, "-prefix") == 0) {
                next_i = i + 1;
                SwitchBit(fi.flags, LVFI_PARTIAL, SvIV(ST(next_i)));
            } else if(strcmp(option, "-wrap") == 0) {
               next_i = i + 1;
               SwitchBit(fi.flags, LVFI_WRAP, SvIV(ST(next_i)));
            }
        } else {
            next_i = -1;
        }
    }

    RETVAL = ListView_FindItem(handle, ifrom, &fi);
OUTPUT:
    RETVAL

    ###########################################################################
    # (@)METHOD:GetBkColor()
    # Retrieves the background color of a ListView.
COLORREF
GetBkColor(handle)
    HWND handle
CODE:
    RETVAL = ListView_GetBkColor(handle);
OUTPUT:
    RETVAL

    ###########################################################################
    # (@)METHOD:GetBkImage()
    # Retrieves the background image in a ListView.
void
GetBkImage (handle)
    HWND handle
PREINIT:
    LVBKIMAGE BkImage;
    char Text [1024];
CODE:
    ZeroMemory(&BkImage, sizeof(LVBKIMAGE));
    ZeroMemory(Text, 1024);
    BkImage.pszImage = Text;
    BkImage.cchImageMax = 1024;
    if (ListView_GetBkImage (handle, &BkImage)) {
        EXTEND(SP, 8);
        XST_mPV( 0, "-url");
        XST_mPV( 1, BkImage.pszImage);
        XST_mPV( 2, "-tiled");
        XST_mIV( 3, (BkImage.ulFlags & LVBKIF_STYLE_TILE));
        XST_mPV( 4, "-xOffsetPercent");
        XST_mIV( 5, BkImage.xOffsetPercent);
        XST_mPV( 6, "-yOffsetPercent");
        XST_mIV( 7, BkImage.yOffsetPercent);
        XSRETURN(8);
    }
    else {
        XSRETURN_UNDEF;
    }

    ###########################################################################
    # (@)METHOD:GetCallbackMask()
    # Retrieves the callback mask for a ListView.
UINT
GetCallbackMask(handle)
    HWND handle
CODE:
    RETVAL = ListView_GetCallbackMask(handle);
OUTPUT:
    RETVAL

    ###########################################################################
    # (@)METHOD:GetCheckState(INDEX)
    # Determines if an item in a ListView is selected. 
BOOL
GetCheckState(handle,index)
    HWND handle
    int index
CODE:
    RETVAL = ListView_GetCheckState(handle, index);
OUTPUT:
    RETVAL

    ###########################################################################
    # (@)METHOD:GetColumn(INDEX)
    # Retrieves the attributes of a ListView's column.
void
GetColumn(handle, iCol)
    HWND handle
    int  iCol
PREINIT:
    LVCOLUMN Column;
    char Text [1024];
CODE:
    ZeroMemory(&Column, sizeof(LVCOLUMN));
    Column.mask = LVCF_FMT | LVCF_IMAGE | LVCF_ORDER | LVCF_SUBITEM | LVCF_TEXT | LVCF_WIDTH;
    Column.pszText = Text;
    Column.cchTextMax = 1024;
    if (ListView_GetColumn(handle, iCol, &Column)) {
        EXTEND(SP, 14);
        XST_mPV( 0, "-text");
        XST_mPV( 1, Column.pszText);
        XST_mPV( 2, "-image");
        XST_mIV( 3, Column.iImage);
        XST_mPV( 4, "-bitmaponright");
        XST_mIV( 5, (Column.fmt & LVCFMT_BITMAP_ON_RIGHT));
        XST_mPV( 6, "-width");
        XST_mIV( 7, Column.cx);
        XST_mPV( 8, "-order");
        XST_mIV( 9, Column.iOrder);
        XST_mPV(10, "-align");
        if ( Column.fmt & LVCFMT_CENTER)
            XST_mPV(11, "center");
        else if (Column.fmt & LVCFMT_RIGHT)
            XST_mPV(11, "right");
        else
            XST_mPV(11, "left");
        XST_mPV(12, "-SubItem");
        XST_mIV(13, Column.iSubItem);
        XSRETURN(14);
    } else {
        XSRETURN_UNDEF;
    }

    ###########################################################################
    # (@)METHOD:GetColumnOrderArray()
    # Retrieves the current left-to-right order of columns in a ListView.
void
GetColumnOrderArray(handle)
    HWND handle
PREINIT:
    int iItems, *lpiArray;
CODE:
    iItems = Header_GetItemCount(ListView_GetHeader(handle));
    if (iItems >= 0) {
        lpiArray = (int*) safemalloc (iItems * sizeof(int));
        if(ListView_GetColumnOrderArray(handle, iItems, lpiArray)) {
            EXTEND(SP, iItems);
            for (int i = 0; i < iItems; i++)
                XST_mIV(i, lpiArray[i]);
            safefree (lpiArray);
            XSRETURN(iItems);
        }
        else {
            safefree (lpiArray);
            XSRETURN_UNDEF;
        }
    } else {
        XSRETURN_UNDEF;
    }

    ###########################################################################
    # (@)METHOD:GetColumnWidth(INDEX)
    # Retrieves the width of a column in report or list view.
UINT
GetColumnWidth(handle,index)
    HWND handle
    int index
CODE:
    RETVAL = ListView_GetColumnWidth(handle, index);
OUTPUT:
    RETVAL

    ###########################################################################
    # (@)METHOD:VisibleCount()
    # (@)METHOD:GetCountPerPage()
    # Calculates the number of items that can fit vertically in the visible area of a ListView when in list or report view. 
int
GetCountPerPage(handle)
    HWND handle
ALIAS:
    Win32::GUI::ListView::VisibleCount = 1
CODE:
    RETVAL = ListView_GetCountPerPage(handle);
OUTPUT:
    RETVAL

    ###########################################################################
    # (@)METHOD:GetEditControl()
    # Retrieves the handle to the edit control being used to edit a list view item's text. 
HWND
GetEditControl(handle)
    HWND handle
CODE:
    RETVAL = ListView_GetEditControl(handle);
OUTPUT:
    RETVAL

    ###########################################################################
    # (@)METHOD:GetExtendedListViewStyle()
    # Retrieves the extended styles that are currently in use for a given ListView.
DWORD
GetExtendedListViewStyle(handle)
    HWND handle
CODE:
    RETVAL = ListView_GetExtendedListViewStyle(handle);
OUTPUT:
    RETVAL

    ###########################################################################
    # (@)METHOD:GetHeader()
    # Retrieves the handle to the header control used by a ListView.
HWND
GetHeader(handle)
    HWND handle
CODE:
    RETVAL = ListView_GetHeader(handle);
OUTPUT:
    RETVAL

    ###########################################################################
    # (@)METHOD:GetHotCursor()
    # Retrieves the cursor used when the pointer is over an item while hot tracking is enabled.
HCURSOR
GetHotCursor(handle)
    HWND handle
CODE:
    RETVAL = ListView_GetHotCursor(handle);
OUTPUT:
    RETVAL

    ###########################################################################
    # (@)METHOD:GetHotItem()
    # Retrieves the index of the hot item. 
int
GetHotItem(handle)
    HWND handle
CODE:
    RETVAL = ListView_GetHotItem(handle);
OUTPUT:
    RETVAL

    ###########################################################################
    # (@)METHOD:GetHoverTime()
    # Retrieves the amount of time that the mouse cursor must hover over an item before it is selected.
DWORD
GetHoverTime(handle)
    HWND handle
CODE:
    RETVAL = ListView_GetHoverTime(handle);
OUTPUT:
    RETVAL

    ###########################################################################
    # (@)METHOD:GetImageList([TYPE=LVSIL_NORMAL])
    # Retrieves the handle to an image list used for drawing list view items.
    # Type : 
    #   LVSIL_NORMAL Image list with large icons. 
    #   LVSIL_SMALL  Image list with small icons. 
    #   LVSIL_STATE  Image list with state images. 
HIMAGELIST
GetImageList(handle,type=LVSIL_NORMAL)
    HWND handle
    int type
CODE:
    RETVAL = ListView_GetImageList(handle,type);
OUTPUT:
    RETVAL

    ###########################################################################
    # (@)METHOD:GetISearchString(STRING)
    # Retrieves the incremental search string of a ListView. 
BOOL 
GetISearchString(handle,lpsz)
    HWND handle
    LPTSTR lpsz
CODE:
    RETVAL = ListView_GetISearchString(handle, lpsz);
OUTPUT:
    RETVAL

    ###########################################################################
    # (@)METHOD:GetItem(INDEX, [SUBINDEX])
    # (@)METHOD:ItemInfo(INDEX, [SUBINDEX])
    # Returns an associative array of information about the given zero-based B<INDEX> item.
    #
    # Return Hash :
    #     -image
    #     -state
    #     -text
    # Optionally, a B<SUBINDEX> (one-based index) can be given, to get the text
    # for the specified column.

void
GetItem(handle,item, subitem=0)
    HWND handle
    int item
    int subitem
ALIAS:
    Win32::GUI::ListView::ItemInfo = 1
PREINIT:
    LV_ITEM lv_item;
    char pszText[1024];
PPCODE:
    ZeroMemory(&lv_item, sizeof(LV_ITEM));
    lv_item.iItem = item;
    lv_item.mask = LVIF_IMAGE
                 | LVIF_PARAM
                 | LVIF_TEXT | LVIF_STATE;
    lv_item.pszText = pszText;
    lv_item.cchTextMax = 1024;
    lv_item.iSubItem = subitem;
    if(ListView_GetItem(handle, &lv_item)) {
        EXTEND(SP, 6);
        XST_mPV(0, "-text");
        XST_mPV(1, lv_item.pszText);
        XST_mPV(2, "-image");
        XST_mIV(3, lv_item.iImage);
        XST_mPV(4, "-state");
        XST_mIV(5, lv_item.state);
        XSRETURN(6);
    } else {
        XSRETURN_UNDEF;
    }

    ###########################################################################
    # (@)METHOD:GetItemCount()
    # (@)METHOD:Count()
    # Returns the number of items in the ListView.
int
GetItemCount(handle)
    HWND handle
ALIAS:
    Win32::GUI::ListView::Count = 1
CODE:
    RETVAL = ListView_GetItemCount(handle);
OUTPUT:
    RETVAL

    ###########################################################################
    # (@)METHOD:GetItemPosition(index)
    # Retrieves the position of a list view item, in listview co-ordinates.
    # See GetOrigin() to convert to client co-ordinates.
void
GetItemPosition(handle,index)
    HWND handle
    int index
PREINIT:
    POINT pt;
PPCODE:
    if (ListView_GetItemPosition(handle,index,&pt) == TRUE) {
        EXTEND(SP, 2);
        XST_mIV(0, pt.x);
        XST_mIV(1, pt.y);
        XSRETURN(2);
    }
    else
        XSRETURN_UNDEF;

    ###########################################################################
    # (@)METHOD:GetItemRect(index,[code=LVIR_BOUNDS])
    # Retrieves the bounding rectangle for all or part of an item in the current view,
    # in client co-ordinates.
void
GetItemRect(handle,index,code=LVIR_BOUNDS)
    HWND handle
    int index
    int code
PREINIT:
    RECT rect;
PPCODE:
    if (ListView_GetItemRect(handle,index,&rect,code) == TRUE) {
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
    # (@)METHOD:GetItemSpacing([flag=FALSE])
    # Determines the spacing between items in a ListView. Flag is true to return the
    # item spacing for the small icon view, and false to return the icon spacing for large icon view.
DWORD
GetItemSpacing(handle,flag=FALSE)
    HWND handle
    BOOL flag
CODE:
    RETVAL = ListView_GetItemSpacing(handle,flag);
OUTPUT:
    RETVAL

    ###########################################################################
    # (@)METHOD:GetItemState(index,mask)
    # Determines the spacing between items in a ListView. Index is the listview item for which
    # to retrieve information.  mask is a combination of the fllowing flags:
    #  LVIS_CUT            The item is marked for a cut-and-paste operation.
    #  LVIS_DROPHILITED    The item is highlighted as a drag-and-drop target.
    #  LVIS_FOCUSED        The item has the focus, so it is surrounded by a standard
    #                      focus rectangle. Although more than one item may be selected,
    #                      only one item can have the focus.
    #  LVIS_SELECTED       The item is selected. The appearance of a selected item depends
    #                      on whether it has the focus and also on the system colors used for selection.
    #  LVIS_OVERLAYMASK    Use this mask to retrieve the item's overlay image index.
    #  LVIS_STATEIMAGEMASK Use this mask to retrieve the item's state image index.
    # The only valid its in the response are those bits that correspond to bits set in mask.

UINT
GetItemState(handle,index,mask)
    HWND handle
    int index
    UINT mask
CODE:
    RETVAL = ListView_GetItemState(handle, index, mask);
OUTPUT:
    RETVAL

    ###########################################################################
    # (@)METHOD:GetItemText(index,[subitem=0])
    # Retrieves the text of a ListView item or subitem
void
GetItemText(handle,index,subitem=0)
    HWND handle
    int index
    int subitem
PREINIT :
    char Text[1024];
PPCODE:
    ZeroMemory(Text, 1024);
    ListView_GetItemText(handle, index, subitem, Text, 1024);
    EXTEND(SP, 1);
    XST_mPV(0, Text);
    XSRETURN(1);

    ###########################################################################
    # (@)METHOD:GetNextItem(index,[mask=LVNI_ALL])
    # Searches for a list view item that has the specified properties and bears
    # the specified relationship to a specified item.
UINT
GetNextItem(handle,index,mask=LVNI_ALL)
    HWND handle
    int index
    UINT mask
CODE:
    RETVAL = ListView_GetNextItem(handle, index, mask);
OUTPUT:
    RETVAL

    ###########################################################################
    # (@)METHOD:GetNumberOfWorkAreas()
    # Retrieves the number of working areas in a ListView. 
UINT
GetNumberOfWorkAreas(handle,index,mask=LVNI_ALL)
    HWND handle
    int index
PREINIT:
    UINT value;
CODE:
    ListView_GetNumberOfWorkAreas(handle, &value);
    RETVAL = value;
OUTPUT:
    RETVAL

    ###########################################################################
    # (@)METHOD:GetOrigin()
    # Retrieves the current view origin for a ListView. Use the values returned
    # to convert between listview co-ordinates and client co-ordinates.
void
GetOrigin(handle)
    HWND handle
PREINIT:
    POINT pt;
PPCODE:
    if (ListView_GetOrigin(handle,&pt) == TRUE) {
        EXTEND(SP, 2);
        XST_mIV(0, pt.x);
        XST_mIV(1, pt.y);
        XSRETURN(2);
    }
    else
        XSRETURN_UNDEF;

    ###########################################################################
    # (@)METHOD:GetSelectedCount()
    # (@)METHOD:SelectCount()
    # Determines the number of selected items in a ListView.
UINT
GetSelectedCount(handle)
    HWND handle
ALIAS:
    Win32::GUI::ListView::SelectCount = 1
CODE:
    RETVAL = ListView_GetSelectedCount(handle);
OUTPUT:
    RETVAL

    ###########################################################################
    # (@)METHOD:GetSelectionMark()
    # Retrieves the selection mark from a ListView.
UINT
GetSelectionMark(handle)
    HWND handle
CODE:
    RETVAL = ListView_GetSelectionMark(handle);
OUTPUT:
    RETVAL

    ###########################################################################
    # (@)METHOD:GetStringWidth(STRING)
    # Determines the width of a specified string using the specified ListView's
    # current font. 
int
GetStringWidth(handle,string)
    HWND handle
    LPCSTR string
CODE:
    RETVAL = ListView_GetStringWidth(handle, string);
OUTPUT:
    RETVAL

    ###########################################################################
    # (@)METHOD:GetSubItemRect(iItem, iSubitem,[code=LVIR_BOUNDS])
    # Retrieves the bounding rectangle for all or part of an item in the current view,
    # in client co-oridinates.
void
GetSubItemRect(handle,index,index2,code=LVIR_BOUNDS)
    HWND handle
    int index
    int index2
    int code
PREINIT:
    RECT rect;
PPCODE:
    if (ListView_GetSubItemRect(handle,index,index2,code,&rect) == TRUE) {
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
    # (@)METHOD:GetTextBkColor()
    # Retrieves the text background color of a ListView.
COLORREF
GetTextBkColor(handle)
    HWND handle
CODE:
    RETVAL = ListView_GetTextBkColor(handle);
OUTPUT:
    RETVAL

    ###########################################################################
    # (@)METHOD:GetTextColor()
    # Retrieves the text color of a ListView.
COLORREF
GetTextColor(handle)
    HWND handle
CODE:
    RETVAL = ListView_GetTextColor(handle);
OUTPUT:
    RETVAL

    ###########################################################################
    # (@)METHOD:GetToolTips()
    # Retrieves the tooltip control that the ListView uses to display tooltips. 
HWND
GetToolTips(handle)
    HWND handle
CODE:
    RETVAL = ListView_GetToolTips(handle);
OUTPUT:
    RETVAL

    ###########################################################################
    # (@)METHOD:GetTopIndex()
    # Retrieves the index of the topmost visible item when in list or report view.
int
GetTopIndex(handle)
    HWND handle
ALIAS:
    Win32::GUI::ListView::GetFirstVisible = 1    
CODE:
    RETVAL = ListView_GetTopIndex(handle);
OUTPUT:
    RETVAL

    ###########################################################################
    # (@)METHOD:GetUnicodeFormat()
    # Retrieves the UNICODE character format flag for the control. 
BOOL
GetUnicodeFormat(handle)
    HWND handle
CODE:
    RETVAL = ListView_GetUnicodeFormat(handle);
OUTPUT:
    RETVAL

    ###########################################################################
    # (@)METHOD:GetViewRect()
    # Retrieves the bounding rectangle of all items in the ListView.
void
GetViewRect(handle)
    HWND handle
PREINIT:
    RECT rect;
PPCODE:
    if (ListView_GetViewRect(handle,&rect) == TRUE) {
        EXTEND(SP, 4);
        XST_mIV(0, rect.left);
        XST_mIV(1, rect.top);
        XST_mIV(2, rect.right);
        XST_mIV(3, rect.bottom);
        XSRETURN(4);
    }
    else
        XSRETURN_UNDEF;

    # TODO : ListView_GetWorkAreas

    ###########################################################################
    # (@)METHOD:HitTest(X, Y)
    # Determine the index of the listview item at X,Y.  X,Y are in client co-ordinates.
    # In list context, returns a 2 member list, the first member containing the item index
    # of the item under the tested position (or -1 of no such item), and the second member
    # containing flags giving information about the result of the test:
    #  LVHT_ABOVE           The position is above the control's client area.
    #  LVHT_BELOW           The position is below the control's client area.
    #  LVHT_NOWHERE         The position is inside the list-view control's client window,
    #                       but it is not over a list item.
    #  LVHT_ONITEMICON      The position is over a list-view item's icon.
    #  LVHT_ONITEMLABEL     The position is over a list-view item's text.
    #  LVHT_ONITEMSTATEICON The position is over the state image of a list-view item.
    #  LVHT_TOLEFT          The position is to the left of the list-view control's client area.
    #  LVHT_TORIGHT         The position is to the right of the list-view control's client area.
void
HitTest(handle,x,y)
    HWND handle
    LONG x
    LONG y
PREINIT:
    LV_HITTESTINFO ht;
PPCODE:
    ht.pt.x = x;
    ht.pt.y = y;
    ListView_HitTest(handle, &ht);
    if(GIMME == G_ARRAY) {
        EXTEND(SP, 2);
        XST_mIV(0, (long) ht.iItem);
        XST_mIV(1, ht.flags);
        XSRETURN(2);
    } else {
        XSRETURN_IV((long) ht.iItem);
    }

    ###########################################################################
    # (@)METHOD:InsertColumn(%OPTIONS)
    # Inserts a new column in a ListView.
    #
    # B<%OPTIONS> :
    #  -text => Column text
    #  -align => [right,left,center]
    #  -width => width
    #  -index | -item => column index
    #  -subitem => subitem number
    #  -image => image index
    #  -bitmaponright => 0/1
    #  -order => Column order
int
InsertColumn(handle,...)
    HWND handle
PREINIT:
    LV_COLUMN Column;
    int iCol = -1;
CODE:
    ZeroMemory(&Column, sizeof(LV_COLUMN));
    Column.fmt = LVCFMT_LEFT;
    Column.mask |= LVCF_FMT;
    ParseListViewColumnItemOptions(NOTXSCALL sp, mark, ax, items, 1, &Column, &iCol);
    if (iCol == -1)
      iCol = Header_GetItemCount(ListView_GetHeader(handle)) + 1;
    RETVAL = ListView_InsertColumn(handle, iCol, &Column);
OUTPUT:
    RETVAL

    ###########################################################################
    # (@)METHOD:InsertItem(%OPTIONS)
    # Inserts a new item in the control.
    #
    # B<%OPTIONS> :
    #  -image => NUMBER
    #    index of an image from the associated ImageList
    #  -indent => NUMBER
    #    how much the item must be indented; one unit is the width of an item image,
    #    so 2 is twice the width of the image, and so on.
    #  -item => NUMBER
    #    zero-based index for the new item; the default is to add the item at the end of the list.
    #  -selected => 0/1, default 0
    #  -text => STRING
    #    the text for the item.  If STRING an array refereence, then the array contains the text for
    #    item at position 0, and all other array members are treated as text for subitems.
int
InsertItem(handle,...)
    HWND handle
PREINIT:
    LV_ITEM Item;
    STRLEN tlen;
    int i, next_i;
    char * option;
    AV* texts;
    SV** t;
CODE:
    texts = NULL;
    ZeroMemory(&Item, sizeof(LV_ITEM));
    Item.iItem = ListView_GetItemCount(handle);
    next_i = -1;
    for(i = 1; i < items; i++) {
        if(next_i == -1) {
            option = SvPV_nolen(ST(i));
            if(strcmp(option, "-text") == 0) {
                next_i = i + 1;
                if(SvROK(ST(next_i)) && SvTYPE(SvRV(ST(next_i))) == SVt_PVAV) {
                    texts = (AV*)SvRV(ST(next_i));
                    t = av_fetch(texts, 0, 0);
                    if(t != NULL) {
                        Item.pszText = SvPV(*t, tlen);
                        Item.cchTextMax = tlen;
                        SwitchBit(Item.mask, LVIF_TEXT, 1);
                    }
                } else {
                    Item.pszText = SvPV(ST(next_i), tlen);
                    Item.cchTextMax = tlen;
                    SwitchBit(Item.mask, LVIF_TEXT, 1);
                }
            } else if(strcmp(option, "-item") == 0
            || strcmp(option, "-index") == 0) {
                next_i = i + 1;
                Item.iItem = (int)SvIV(ST(next_i));
            } else if(strcmp(option, "-image") == 0) {
                next_i = i + 1;
                Item.iImage = (int)SvIV(ST(next_i));
                SwitchBit(Item.mask, LVIF_IMAGE, 1);
            } else if(strcmp(option, "-selected") == 0) {
                next_i = i + 1;
                SwitchBit(Item.state, LVIS_SELECTED, SvIV(ST(next_i)));
                SwitchBit(Item.stateMask, LVIS_SELECTED, 1);
                SwitchBit(Item.mask, LVIF_STATE, 1);
            } else if(strcmp(option, "-indent") == 0) {
                next_i = i + 1;
                Item.iIndent = (int)SvIV(ST(next_i));
                SwitchBit(Item.mask, LVIF_INDENT, 1);
            }
        } else {
            next_i = -1;
        }
    }
    RETVAL = ListView_InsertItem(handle, &Item);
    if(texts != NULL) {
        for(i=1; i<=av_len(texts); i++) {
            t = av_fetch(texts, i, 0);
            if(t != NULL) {
                Item.pszText = SvPV(*t, tlen);
                Item.cchTextMax = tlen;
                SwitchBit(Item.mask, LVIF_TEXT, 1);
            }
            Item.iSubItem = i;
            ListView_SetItem(handle, &Item);
        }
    }
OUTPUT:
    RETVAL

    ###########################################################################
    # (@)METHOD:RedrawItems(first,last)
    # Forces a ListView to redraw a range of items.
BOOL
RedrawItems(handle,first,last)
    HWND handle
    int first
    int last
CODE:
    RETVAL = ListView_RedrawItems(handle, first, last);
OUTPUT:
    RETVAL

    ###########################################################################
    # (@)METHOD:Scroll(first,last)
    # Scrolls the content of a ListView.
BOOL
Scroll(handle,dx,dy)
    HWND handle
    int dx
    int dy
CODE:
    RETVAL = ListView_Scroll(handle, dx, dy);
OUTPUT:
    RETVAL

    ###########################################################################
    # (@)METHOD:SetBkColor(color)
    # Sets the background color of a ListView.
BOOL
SetBkColor(handle,color)
    HWND handle
    COLORREF color
CODE:
    RETVAL = ListView_SetBkColor(handle, color);
OUTPUT:
    RETVAL

    ###########################################################################
    # (@)METHOD:SetBkImage(%OPTIONS)
    # Sets the background image in a ListView.
    #
    # B<%OPTIONS> :
    #  -url => STRING
    #    URL of the background image. 
    #  -tiled => 0/1
    #    The background image will be tiled to fill the entire background.
    #  -xOffsetPercent => NUMBER
    #    Percentage of the control's client area that the image should be offset horizontally.
    #  -yOffsetPercent => NUMBER
    #    Percentage of the control's client area that the image should be offset vertically.
BOOL
SetBkImage(handle, ...)
    HWND handle
PREINIT:
    LVBKIMAGE BkImage;
    STRLEN tlen;
    int i, next_i;
    char * option;
CODE:
    ZeroMemory(&BkImage, sizeof(LVBKIMAGE));
    next_i = -1;
    for(i = 1; i < items; i++) {
        if(next_i == -1) {
            option = SvPV_nolen(ST(i));
            if(strcmp(option, "-url") == 0) {
                next_i = i + 1;
                BkImage.pszImage = SvPV(ST(next_i), tlen);
                BkImage.cchImageMax = tlen;
                BkImage.ulFlags |= LVBKIF_SOURCE_URL;
            } else if(strcmp(option, "-tiled") == 0) {
                next_i = i + 1;
                BkImage.ulFlags |= (SvIV(ST(next_i)) ? LVBKIF_STYLE_TILE : LVBKIF_STYLE_NORMAL);
            } else if(strcmp(option, "-xOffsetPercent") == 0) {
                next_i = i + 1;
                BkImage.xOffsetPercent = (int)SvIV(ST(next_i));
            } else if(strcmp(option, "-yOffsetPercent") == 0) {
                next_i = i + 1;
                BkImage.yOffsetPercent = (int)SvIV(ST(next_i));
            }
        } else {
            next_i = -1;
        }
    }
    RETVAL = ListView_SetBkImage(handle, &BkImage);
OUTPUT:
    RETVAL
    
    ###########################################################################
    # (@)METHOD:SetCallbackMask(MASK)
    # Changes the callback mask for a ListView.
BOOL
SetCallbackMask(handle,mask)
    HWND handle
    int mask
CODE:
    RETVAL = ListView_SetCallbackMask(handle, mask);
OUTPUT:
    RETVAL

    ###########################################################################
    # (@)METHOD:SetColumn(COLUMN, %OPTIONS)
    # Change column option in a ListView.
    # 
    # B<%OPTIONS> : See InsertColumn()
int
SetColumn(handle, iCol, ...)
    HWND handle
    int iCol
PREINIT:
    LV_COLUMN Column;
CODE:
    ZeroMemory(&Column, sizeof(LV_COLUMN));
    ParseListViewColumnItemOptions(NOTXSCALL sp, mark, ax, items, 2, &Column, &iCol);
    RETVAL = ListView_SetColumn(handle, iCol, &Column);
OUTPUT:
    RETVAL

    ###########################################################################
    # (@)METHOD:SetColumnOrderArray(...)
    # Sets the left-to-right order of columns in a ListView .
BOOL
SetColumnOrderArray(handle,...)
    HWND handle
PREINIT:
    int * lpiArray;
CODE:
    lpiArray = (int *) safemalloc (items * sizeof(int));
    for (int i = 1; i < items; i++)
        lpiArray[i] = (int)SvIV(ST(i));
    RETVAL = ListView_SetColumnOrderArray(handle, items-1, &lpiArray[1]);
    safefree (lpiArray);
OUTPUT:
    RETVAL

    ###########################################################################
    # (@)METHOD:SetColumnWidth(COLUMN, [WIDTH])
    # Sets the width of the specified COLUMN; WIDTH can be the desired
    # width in pixels or one of the following special values:
    #   -1 automatically size the column
    #   -2 automatically size the column to fit the header text
BOOL
SetColumnWidth(handle,column,width=-1)
    HWND handle
    int column
    int width
CODE:
    RETVAL = ListView_SetColumnWidth(handle, column, width);
OUTPUT:
    RETVAL

    ###########################################################################
    # (@)METHOD:SetExtendedListViewStyle(EXSTYLE)
    # Sets extended styles for ListViews. 
void
SetExtendedListViewStyle(handle,exstyle)
    HWND handle
    DWORD exstyle
CODE:
    ListView_SetExtendedListViewStyle(handle, exstyle);

    ###########################################################################
    # (@)METHOD:SetExtendedListViewStyleEx(MASK, EXSTYLE)
    # Sets extended styles for ListView using the style mask
void
SetExtendedListViewStyleEx(handle,mask,exstyle)
    HWND handle
    DWORD mask
    DWORD exstyle
CODE:
    ListView_SetExtendedListViewStyleEx(handle, mask, exstyle);

    ###########################################################################
    # (@)METHOD:SetHotCursor(CURSOR)
    # Sets the HCURSOR that the ListView uses when the pointer is over an item while hot tracking is enabled.
HCURSOR
SetHotCursor(handle,hCursor)
    HWND handle
    HCURSOR hCursor
CODE:
    RETVAL = ListView_SetHotCursor(handle, hCursor);
OUTPUT:
    RETVAL

    ###########################################################################
    # (@)METHOD:SetHotItem(index)
    # Sets the hot item in a ListView.
int
SetHotItem(handle,index)
    HWND handle
    int  index
CODE:
    RETVAL = ListView_SetHotItem(handle, index);
OUTPUT:
    RETVAL

    ###########################################################################
    # (@)METHOD:SetHoverTime(TIME)
    # Sets the amount of time that the mouse cursor must hover over an item before it is selected.
DWORD
SetHoverTime(handle,time)
    HWND handle
    DWORD time
CODE:
    RETVAL = ListView_SetHoverTime(handle, time);
OUTPUT:
    RETVAL

    ###########################################################################
    # (@)METHOD:SetIconSpacing(X,Y)
    # Sets the spacing between icons in ListView set to the LVS_ICON style. 
DWORD
SetIconSpacing(handle,x,y)
    HWND handle
    int x
    int y
CODE:
    RETVAL = ListView_SetIconSpacing(handle, x, y);
OUTPUT:
    RETVAL

    ###########################################################################
    # (@)METHOD:SetImageList(IMAGELIST, [TYPE=LVSIL_NORMAL])
    # Assigns an image list to a ListView.
    #
    #Type of image list. This parameter can be one of the following values: 
    #
    #  LVSIL_NORMAL (0) Image list with large icons.
    #  LVSIL_SMALL  (1) Image list with small icons.
    #  LVSIL_STATE  (2) Image list with state images.
    #
HIMAGELIST
SetImageList(handle,imagelist,type=LVSIL_NORMAL)
    HWND handle
    HIMAGELIST imagelist
    WPARAM type
CODE:
    RETVAL = ListView_SetImageList(handle, imagelist, type);
OUTPUT:
    RETVAL

    ###########################################################################
    # (@)METHOD:SetItem(%OPTIONS)
    # (@)METHOD:ChangeItem(%OPTIONS)
    # Change item options.
    #
    # B<%OPTIONS> : See InsertItem().
int
SetItem(handle,...)
    HWND handle
ALIAS:
    Win32::GUI::ListView::ChangeItem = 1
PREINIT:
    LV_ITEM Item;
    STRLEN tlen;
    int i, next_i;
    char * option;
CODE:
    ZeroMemory(&Item, sizeof(LV_ITEM));
    next_i = -1;
    for(i = 1; i < items; i++) {
        if(next_i == -1) {
            option = SvPV_nolen(ST(i));
            if(strcmp(option, "-text") == 0) {
                next_i = i + 1;
                Item.pszText = SvPV(ST(next_i), tlen);
                Item.cchTextMax = tlen;
                Item.mask = Item.mask | LVIF_TEXT;
            } else if(strcmp(option, "-item") == 0
            || strcmp(option, "-index") == 0) {
                next_i = i + 1;
                Item.iItem = (int)SvIV(ST(next_i));
            } else if(strcmp(option, "-subitem") == 0) {
                next_i = i + 1;
                Item.iSubItem = (int)SvIV(ST(next_i));
            } else if(strcmp(option, "-image") == 0) {
                next_i = i + 1;
                Item.iImage = (int)SvIV(ST(next_i));
                Item.mask = Item.mask | LVIF_IMAGE;
            }
        } else {
            next_i = -1;
        }
    }
    RETVAL = ListView_SetItem(handle, &Item);
OUTPUT:
    RETVAL

    ###########################################################################
    # (@)METHOD:SetItemCount(COUNT)
    # Sets the amount of time that the mouse cursor must hover over an item before it is selected.
void
SetItemCount(handle,count)
    HWND handle
    int count
CODE:
    ListView_SetItemCount(handle, count);

    ###########################################################################
    # (@)METHOD:SetItemCountEx(COUNT,FLAG)
    # Sets the virtual number of items in a virtual ListView.
void
SetItemCountEx(handle,count,flag)
    HWND handle
    int count
    DWORD flag
CODE:
    ListView_SetItemCountEx(handle, count, flag);

    ###########################################################################
    # (@)METHOD:SetItemPosition(INDEX, X, Y)
    # (@)METHOD:MoveItem(INDEX, X, Y)
    # Moves an item to a specified position in a ListView (in icon or small icon view).     
    # X,Y are in listview co-ordinates.
void
SetItemPosition(handle, index, x, y)
    HWND handle
    int index
    int x
    int y
ALIAS:
    Win32::GUI::ListView::MoveItem = 1
CODE:
    ListView_SetItemPosition32(handle, index, x, y);

    ###########################################################################
    # (@)METHOD:SetItemState(INDEX,STATE,MASK)
    # Changes the state of an item in a ListView.
void
SetItemState(handle,index,state,mask)
    HWND handle
    UINT index
    UINT state
    UINT mask 
CODE:
    ListView_SetItemState(handle, index, state, mask);

    ###########################################################################
    # (@)METHOD:SetItemText(INDEX,TEXT,[SUBITEM=0])
    # Changes the text of an item in a ListView.
void
SetItemText(handle,index,texte,subitem=0)
    HWND handle
    UINT index
    LPTSTR texte
    UINT subitem 
CODE:
    ListView_SetItemText(handle, index, subitem, texte);

    ###########################################################################
    # (@)METHOD:SetSelectionMark(index)
    # Sets the selection mark in a ListView. 
int
SetSelectionMark(handle,index)
    HWND handle
    int index
CODE:
    RETVAL = ListView_SetSelectionMark(handle, index);
OUTPUT:
    RETVAL

    ###########################################################################
    # (@)METHOD:SetTextBkColor(COLOR)
    # Sets the background color of text in a ListView. 
BOOL
SetTextBkColor(handle,color)
    HWND handle
    COLORREF color
CODE:
    RETVAL = ListView_SetTextBkColor(handle, color);
OUTPUT:
    RETVAL

    ###########################################################################
    # (@)METHOD:SetTextColor(COLOR)
    # Sets the text color of a ListView. 
BOOL
SetTextColor(handle,color)
    HWND handle
    COLORREF color
CODE:
    RETVAL = ListView_SetTextColor(handle, color);
OUTPUT:
    RETVAL

    ###########################################################################
    # (@)METHOD:SetToolTips(TOOLTIP)
    # Sets the tooltip control that the ListView will use to display tooltips. 
HWND
SetToolTips(handle,tooltip)
    HWND handle
    HWND tooltip
CODE:
    if (handle && tooltip) {
			RETVAL = ListView_SetToolTips(handle, (LPARAM)(tooltip));
		} else {
			RETVAL = NULL;
		}
OUTPUT:
    RETVAL

    ###########################################################################
    # (@)METHOD:SetUnicodeFormat(FLAG)
    # Sets the UNICODE character format flag for the control. 
BOOL
SetUnicodeFormat(handle,flag)
    HWND handle
    BOOL flag
CODE:
    RETVAL = ListView_SetUnicodeFormat(handle, flag);
OUTPUT:
    RETVAL

    # TODO : ListView_SetWorkAreas
    # TODO : ListView_SortItems

    ###########################################################################
    # (@)METHOD:SubItemHitTest(X, Y)
    # Test to find which sub-item is at the position X,Y.  X,Y are inclient-co-ordinates.
    # Returns a 3 memeber list, giving the item number, subitem number and flags related
    # to the test.  the item number is -1 if no item or subitem is under X,Y.
    # flags are a combination of:
    #  LVHT_ABOVE           The position is above the control's client area.
    #  LVHT_BELOW           The position is below the control's client area.
    #  LVHT_NOWHERE         The position is inside the list-view control's client window,
    #                       but it is not over a list item.
    #  LVHT_ONITEMICON      The position is over a list-view item's icon.
    #  LVHT_ONITEMLABEL     The position is over a list-view item's text.
    #  LVHT_ONITEMSTATEICON The position is over the state image of a list-view item.
    #  LVHT_TOLEFT          The position is to the left of the list-view control's client area.
    #  LVHT_TORIGHT         The position is to the right of the list-view control's client area.

void
SubItemHitTest(handle,x,y)
    HWND handle
    LONG x
    LONG y
PREINIT:
    LVHITTESTINFO ht;
PPCODE:
    ht.pt.x = x;
    ht.pt.y = y;
    if (ListView_SubItemHitTest(handle, &ht) != -1) { 
        EXTEND(SP, 3);
        XST_mIV(0, (long) ht.iItem);
        XST_mIV(1, (long) ht.iSubItem);
        XST_mIV(2, ht.flags);
        XSRETURN(3);
    } 
    else 
        XSRETURN_UNDEF;

    ###########################################################################
    # (@)METHOD:Update(INDEX)
    # Updates a list view item.
BOOL
Update(handle,index)
    HWND handle
    int index
CODE:
    RETVAL = ListView_Update(handle, index);
OUTPUT:
    RETVAL

    ###########################################################################
    ###########################################################################
    ###########################################################################

    ###########################################################################
    # (@)METHOD:Select(INDEX)
    # Selects and sets focus to the zero-based INDEX item from the ListView.
    # Use Select(-1) to select all items and set focus to item 0.
void
Select(handle,item)
    HWND handle
    int item
PREINIT:
    int iCount;
    DWORD dwStyle;
    UINT state;
    UINT mask;
CODE:
    iCount = ListView_GetItemCount(handle);
    if (item < -1 || item >= iCount) XSRETURN_UNDEF;
    if (item == -1) {  // All items
        // Get the current window style.
        dwStyle = (DWORD)GetWindowLongPtr(handle, GWL_STYLE);
        if (dwStyle & LVS_SINGLESEL) XSRETURN_UNDEF; // Not in singlesel mode
        mask = LVIS_SELECTED;
        state = 0xFFFFFFFF;    // Select all
        ListView_SetItemState(handle, (UINT) -1, state, mask);
        mask = LVIS_FOCUSED;
        state = 0;             // Remove focus from all
        ListView_SetItemState(handle, (UINT) -1, state, mask);
        state = 0xFFFFFFFF;    // Set focus to item 0
        ListView_SetItemState(handle, (UINT) 0, state, mask);
    } else {  // Specific item
        mask = LVIS_FOCUSED;
        state = 0;             // Remove focus from all
        ListView_SetItemState(handle, (UINT) -1, state, mask);
        mask = LVIS_FOCUSED | LVIS_SELECTED;
        state = 0xFFFFFFFF;    // Select and set focus to given item
        ListView_SetItemState(handle, item, state, mask);
    }

    ###########################################################################
    # (@)METHOD:SelectAll()
    # Alternate method to select all items. Sets focus to the zero-based
    # INDEX item from the ListView.
void
SelectAll(handle)
    HWND handle
PREINIT:
    DWORD dwStyle;
    UINT state;
    UINT mask;
CODE:
    // Get the current window style.
    dwStyle = (DWORD)GetWindowLongPtr(handle, GWL_STYLE);
    if (dwStyle & LVS_SINGLESEL) XSRETURN_UNDEF; // Not in singlesel mode
    mask = LVIS_SELECTED;
    state = 0xFFFFFFFF;    // Select all
    ListView_SetItemState(handle, (UINT) -1, state, mask);
    mask = LVIS_FOCUSED;
    state = 0;             // Remove focus from all
    ListView_SetItemState(handle, (UINT) -1, state, mask);
    state = 0xFFFFFFFF;    // Set focus to item 0
    ListView_SetItemState(handle, (UINT) 0, state, mask);

    ###########################################################################
    # (@)METHOD:Deselect(INDEX)
    # Deselects the zero-based INDEX item from the ListView.
    # Use Deselect(-1) to deselect all items.
    # Focus is unchanged.
void
Deselect(handle,item)
    HWND handle
    int item
PREINIT:
    int iCount;
    UINT state;
    UINT mask;
CODE:
    iCount = ListView_GetItemCount(handle);
    if (item < -1 || item >= iCount) XSRETURN_UNDEF;
    mask = LVIS_SELECTED;
    state = 0;                 // Deselect all
    ListView_SetItemState(handle, item, state, mask);

    ###########################################################################
    # (@)METHOD:DeselectAll()
    # Alternate method to deselect all items from the ListView.
    # Focus is unchanged.
void
DeselectAll(handle)
    HWND handle
PREINIT:
    UINT state;
    UINT mask;
CODE:
    mask = LVIS_SELECTED;
    state = 0;                 // Deselect all
    ListView_SetItemState(handle, (UINT) -1, state, mask);

    ###########################################################################
    # (@)METHOD:Add(ITEM, ITEM .. ITEM)
    # Inserts one or more items in the control; each item must be passed as
    # an hash reference. See InsertItem() for a list of the available
    # key/values of these hashes.
int
Add(handle,...)
    HWND handle
PREINIT:
    LV_ITEM Item;
    STRLEN tlen;
    int item_i, i;
    char * option;
    AV* texts;
    SV** t;
    HV* itemdata;
    SV* sv_value;
    I32 retlen;
    I32 nitems;
    int iir;
CODE:
    RETVAL = 0;
    for(item_i = 1; item_i < items; item_i++) {
        texts = NULL;
        if(SvROK(ST(item_i)) && SvTYPE(SvRV(ST(item_i))) == SVt_PVHV) {
            ZeroMemory(&Item, sizeof(LV_ITEM));
            Item.iItem = ListView_GetItemCount(handle);
            itemdata = (HV*)SvRV(ST(item_i));
            nitems = hv_iterinit(itemdata);
            while(nitems--) {
                sv_value = hv_iternextsv(itemdata, &option, &retlen);
                if(strcmp(option, "-text") == 0) {
                    if(SvROK(sv_value) && SvTYPE(SvRV(sv_value)) == SVt_PVAV) {
                        texts = (AV*)SvRV(sv_value);
                        t = av_fetch(texts, 0, 0);
                        if(t != NULL) {
                            Item.pszText = SvPV(*t, tlen);
                            Item.cchTextMax = tlen;
                            SwitchBit(Item.mask, LVIF_TEXT, 1);
                        }
                    } else {
                        Item.pszText = SvPV(sv_value, tlen);
                        Item.cchTextMax = tlen;
                        SwitchBit(Item.mask, LVIF_TEXT, 1);
                    }
                } else if(strcmp(option, "-item") == 0
                || strcmp(option, "-index") == 0) {
                    Item.iItem = (int)SvIV(sv_value);
                } else if(strcmp(option, "-image") == 0) {
                    Item.iImage = (int)SvIV(sv_value);
                    SwitchBit(Item.mask, LVIF_IMAGE, 1);
                } else if(strcmp(option, "-selected") == 0) {
                    SwitchBit(Item.state, LVIS_SELECTED, SvIV(sv_value));
                    SwitchBit(Item.stateMask, LVIS_SELECTED, 1);
                    SwitchBit(Item.mask, LVIF_STATE, 1);
                } else if(strcmp(option, "-indent") == 0) {
                    Item.iIndent = (int)SvIV(sv_value);
                    SwitchBit(Item.mask, LVIF_INDENT, 1);
                }
            }
        }
        iir = ListView_InsertItem(handle, &Item);
        if(iir != -1) RETVAL++;
        if(texts != NULL) {
            for(i=1; i<=av_len(texts); i++) {
                t = av_fetch(texts, i, 0);
                if(t != NULL) {
                    Item.pszText = SvPV(*t, tlen);
                    Item.cchTextMax = tlen;
                    SwitchBit(Item.mask, LVIF_TEXT, 1);
                }
                Item.iSubItem = i;
                ListView_SetItem(handle, &Item);
            }
        }
        Item.iItem = ListView_GetItemCount(handle);
    }
OUTPUT:
    RETVAL

    ###########################################################################
    # (@)METHOD:View([MODE])
long
View(handle,view=(DWORD) -1)
    HWND handle
    DWORD view
PREINIT:
    DWORD dwStyle;
CODE:
    // Get the current window style.
    dwStyle = (DWORD)GetWindowLongPtr(handle, GWL_STYLE);
    if(items == 2) {
        // Only set the window style if the view bits have changed.
        if ((dwStyle & LVS_TYPEMASK) != view)
            SetWindowLongPtr(handle, GWL_STYLE,  (dwStyle & ~LVS_TYPEMASK) | view);
        dwStyle = (DWORD)GetWindowLongPtr(handle, GWL_STYLE);
        RETVAL = (dwStyle & LVS_TYPEMASK);
    } else
        RETVAL = (dwStyle & LVS_TYPEMASK);
OUTPUT:
    RETVAL

    ###########################################################################
    # (@)METHOD:TextColor([COLOR])
    # Gets or sets the text color for the ListView.
COLORREF
TextColor(handle,color=(COLORREF) -1)
    HWND handle
    COLORREF color
CODE:
    if(items == 2) {
        if(ListView_SetTextColor(handle, color))
            RETVAL = ListView_GetTextColor(handle);
        else
            RETVAL = (COLORREF) -1;
    } else
        RETVAL = ListView_GetTextColor(handle);
OUTPUT:
    RETVAL

    ###########################################################################
    # (@)METHOD:TextBkColor([COLOR])
    # Gets or sets the background color for the text in the ListView.
COLORREF
TextBkColor(handle,color=(COLORREF) -1)
    HWND handle
    COLORREF color
CODE:
    if(items == 2) {
        if(ListView_SetTextBkColor(handle, color))
            RETVAL = ListView_GetTextBkColor(handle);
        else
            RETVAL = (COLORREF) -1;
    } else
        RETVAL = ListView_GetTextBkColor(handle);
OUTPUT:
    RETVAL

    ###########################################################################
    # (@)METHOD:ColumnWidth(COLUMN, [WIDTH])
    # Gets or sets the width of the specified COLUMN; WIDTH can be the desired
    # width in pixels or one of the following special values:
    #   -1 automatically size the column
    #   -2 automatically size the column to fit the header text
int
ColumnWidth(handle,column,width=-1)
    HWND handle
    int column
    int width
CODE:
    if(items == 2)
        RETVAL = ListView_GetColumnWidth(handle, column);
    else
        RETVAL = ListView_SetColumnWidth(handle, column, width);
OUTPUT:
    RETVAL

    ###########################################################################
    # (@)METHOD:ItemPosition(INDEX, [X, Y])
    # Get or set the position of an item in icon or small icon view.  X,Y are in
    # listview co-ordinates.
void
ItemPosition(handle, index, x=-1, y=-1)
    HWND handle
    int index
    int x
    int y
PREINIT:
    POINT p;
PPCODE:
    if(items == 2) {
        if(ListView_GetItemPosition(handle, index, &p)) {
            EXTEND(SP, 2);
            XST_mIV(0, p.x);
            XST_mIV(1, p.y);
            XSRETURN(2);
        } else {
            XSRETURN_UNDEF;
        }
    } else {
        XSRETURN_IV(ListView_SetItemPosition(handle, index, x, y));
    }

    ###########################################################################
    # (@)METHOD:ItemCheck(INDEX,[FLAG])
    # Set or Get item checked state.
BOOL
ItemCheck(handle,index,value=FALSE)
    HWND handle
    int index
    BOOL value
PREINIT:
    // LVITEM lvitem;
CODE:
    if(items == 3) {
        RETVAL = ListView_GetCheckState(handle, index);
        ListView_SetItemState(handle, index, INDEXTOSTATEIMAGEMASK((value ? 2 : 1)), LVIS_STATEIMAGEMASK);
    } else {
        RETVAL = ListView_GetCheckState(handle, index);
    }
OUTPUT:
    RETVAL

    ###########################################################################
    # (@)METHOD:SelectedItems()
    # Returns an array containing the zero-based indexes of selected items, or
    # an empty list if no items are selected.
void
SelectedItems(handle)
    HWND handle
PREINIT:
    UINT scount;
    UINT tcount;
    int index;
PPCODE:
    scount = ListView_GetSelectedCount(handle);
    if(scount > 0) {
        index = -1;
        tcount = 0;
        EXTEND(SP, scount);
        index = ListView_GetNextItem(handle, index, LVNI_SELECTED);
        while(tcount < scount && index != -1) {
            XST_mIV(tcount, (long) index);
            tcount++;
            index = ListView_GetNextItem(handle, index, LVNI_SELECTED);
        }
        XSRETURN(tcount);
    } else {
        XSRETURN_EMPTY;
    }

