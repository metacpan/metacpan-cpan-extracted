    /*
    ###########################################################################
    # (@)PACKAGE:Win32::GUI::TreeView
    #
    # $Id: TreeView.xs,v 1.11 2010/04/08 21:26:48 jwgui Exp $
    #
    ###########################################################################
    */

#include "GUI.h"

void 
TreeView_onPreCreate(NOTXSPROC LPPERLWIN32GUI_CREATESTRUCT perlcs) {

    perlcs->cs.lpszClass = WC_TREEVIEW;
    perlcs->cs.style = WS_VISIBLE | WS_CHILD | WS_BORDER | TVS_SHOWSELALWAYS;
    perlcs->cs.dwExStyle = WS_EX_CLIENTEDGE;
}

BOOL
TreeView_onParseOption(NOTXSPROC char *option, SV* value, LPPERLWIN32GUI_CREATESTRUCT perlcs) {

    BOOL retval = TRUE;
    
    if(strcmp(option, "-imagelist") == 0) {
        perlcs->hImageList = (HIMAGELIST) handle_From(NOTXSCALL value);
    } else if(strcmp(option, "-tooltip") == 0) {
        perlcs->hTooltip = (HWND) handle_From(NOTXSCALL value);
        SwitchBit(perlcs->cs.style, TVS_NOTOOLTIPS, 0);        
    } else if BitmaskOptionValue("-lines",           perlcs->cs.style, TVS_HASLINES)
    } else if BitmaskOptionValue("-rootlines",       perlcs->cs.style, TVS_LINESATROOT)
    } else if BitmaskOptionValue("-buttons",         perlcs->cs.style, TVS_HASBUTTONS)
    } else if BitmaskOptionValue("-showselalways",   perlcs->cs.style, TVS_SHOWSELALWAYS)
    } else if BitmaskOptionValue("-checkboxes",      perlcs->cs.style, TVS_CHECKBOXES)
    } else if BitmaskOptionValue("-trackselect",     perlcs->cs.style, TVS_TRACKSELECT)
    } else if BitmaskOptionValue("-disabledragdrop", perlcs->cs.style, TVS_DISABLEDRAGDROP)
    } else if BitmaskOptionValue("-editlabels",      perlcs->cs.style, TVS_EDITLABELS)
    } else if BitmaskOptionValue("-fullrowselect",   perlcs->cs.style, TVS_FULLROWSELECT)
    } else if BitmaskOptionValue("-nonevenheight",   perlcs->cs.style, TVS_NONEVENHEIGHT)
    } else if BitmaskOptionValue("-noscroll",        perlcs->cs.style, TVS_NOSCROLL)
    } else if BitmaskOptionValue("-notooltips",      perlcs->cs.style, TVS_NOTOOLTIPS)
    } else if BitmaskOptionValue("-rtlreading",      perlcs->cs.style, TVS_RTLREADING)
    } else if BitmaskOptionValue("-singleexpand",    perlcs->cs.style, TVS_SINGLEEXPAND)
    } else retval = FALSE;

    return retval;
}

void
TreeView_onPostCreate(NOTXSPROC HWND myhandle, LPPERLWIN32GUI_CREATESTRUCT perlcs) {

    if(perlcs->hImageList != NULL)
        TreeView_SetImageList(myhandle, perlcs->hImageList, TVSIL_NORMAL);
   
    if (perlcs->hTooltip != NULL) 
        TreeView_SetToolTips (myhandle, perlcs->hTooltip);

    if(perlcs->clrForeground != CLR_INVALID) {
        TreeView_SetTextColor (myhandle, perlcs->clrForeground);
        perlcs->clrForeground = CLR_INVALID;  // Don't Store
    }

    if(perlcs->clrBackground != CLR_INVALID) {
        TreeView_SetBkColor (myhandle, perlcs->clrBackground);
        perlcs->clrBackground = CLR_INVALID;  // Don't Store
    }
}

BOOL
TreeView_onParseEvent(NOTXSPROC char *name, int* eventID) {

    BOOL retval = TRUE;

         if Parse_Event("NodeClick",      PERLWIN32GUI_NEM_CONTROL1)
    else if Parse_Event("Collapse",       PERLWIN32GUI_NEM_CONTROL2)
    else if Parse_Event("Expand",         PERLWIN32GUI_NEM_CONTROL3)
    else if Parse_Event("Collapsing",     PERLWIN32GUI_NEM_CONTROL4)
    else if Parse_Event("Expanding",      PERLWIN32GUI_NEM_CONTROL5)
    else if Parse_Event("BeginLabelEdit", PERLWIN32GUI_NEM_CONTROL6)
    else if Parse_Event("EndLabelEdit",   PERLWIN32GUI_NEM_CONTROL7)
    else if Parse_Event("KeyDown",        PERLWIN32GUI_NEM_KEYDOWN)
    else retval = FALSE;

    return retval;
}

int
TreeView_onEvent (NOTXSPROC LPPERLWIN32GUI_USERDATA perlud, UINT uMsg, WPARAM wParam, LPARAM lParam) {

    int PerlResult = 1;
    TV_ITEM *pItem;
    
    if ( uMsg == WM_NOTIFY ) {

        LPNM_TREEVIEW tv_notify = (LPNM_TREEVIEW) lParam;
        switch(tv_notify->hdr.code) {
        
        case TVN_BEGINLABELEDIT:
           /*
            * (@)EVENT:BeginLabelEdit(NODE)
            * Sent when the user is about to edit the specified NODE of the TreeView
            * The event should return 0 to prevent the  action, 1 to allow it.
            *
            * For a treeview to receive this event, -editlabels need to be set to true.
            * (@)APPLIES_TO:TreeView
            */        
           pItem = &((TV_DISPINFO*)lParam)->item;
           PerlResult = DoEvent(NOTXSCALL perlud, PERLWIN32GUI_NEM_CONTROL6, "BeginLabelEdit",
                PERLWIN32GUI_ARGTYPE_LONG, (IV) pItem->hItem,
                -1);
           
           // Force result if event is handle
           if (perlud->dwPlStyle & PERLWIN32GUI_EVENTHANDLING) {
               perlud->forceResult = (PerlResult == 0 ? TRUE : FALSE);
               PerlResult = 0; // MsgLoop return ForceResult
           }
           break;

        case TVN_ENDLABELEDIT: 
            /*
             * (@)EVENT:EndLabelEdit(NODE,TEXT)
             * Sent when the user has finished editing a label in the TreeView control.
             * You have explicitly set the text of the node to reflect the new changes. 
             * If the user cancels the edit, the text is undef.
             * (@)APPLIES_TO:TreeView
             */
           pItem = &((TV_DISPINFO*)lParam)->item;
           if ( pItem->pszText != NULL) {
             PerlResult = DoEvent(NOTXSCALL perlud, PERLWIN32GUI_NEM_CONTROL7, "EndLabelEdit",
                PERLWIN32GUI_ARGTYPE_LONG, (IV) pItem->hItem,PERLWIN32GUI_ARGTYPE_STRING,pItem->pszText,
                -1);
             }
           else {
             //user has canceled the edit
             PerlResult = DoEvent(NOTXSCALL perlud, PERLWIN32GUI_NEM_CONTROL7, "EndLabelEdit",
                PERLWIN32GUI_ARGTYPE_LONG, (IV) pItem->hItem,
                -1);           
           }
           
           break;
            
        case TVN_SELCHANGED:
            /*
             * (@)EVENT:NodeClick(NODE)
             * Sent when the user clicks on the specified NODE of the TreeView.
             * (@)APPLIES_TO:TreeView
             */
            PerlResult = DoEvent(NOTXSCALL perlud, PERLWIN32GUI_NEM_CONTROL1, "NodeClick",
                PERLWIN32GUI_ARGTYPE_LONG, (IV) tv_notify->itemNew.hItem,
                -1);
            break;

        case TVN_ITEMEXPANDED:
            if(tv_notify->action == TVE_COLLAPSE) {
                /*
                 * (@)EVENT:Collapse(NODE)
                 * Sent when the user closes the specified NODE of the TreeView.
                 * (@)APPLIES_TO:TreeView
                 */
                PerlResult = DoEvent(NOTXSCALL perlud, PERLWIN32GUI_NEM_CONTROL2, "Collapse",
                    PERLWIN32GUI_ARGTYPE_LONG, (IV) tv_notify->itemNew.hItem,
                    -1);
            } else {
                /*
                 * (@)EVENT:Expand(NODE)
                 * Sent when the user opens the specified NODE of the TreeView.
                 * (@)APPLIES_TO:TreeView
                 */
                PerlResult = DoEvent(NOTXSCALL perlud, PERLWIN32GUI_NEM_CONTROL3, "Expand",
                    PERLWIN32GUI_ARGTYPE_LONG, (IV) tv_notify->itemNew.hItem,
                    -1);
            }
            break;

        case TVN_ITEMEXPANDING:

            if(tv_notify->action == TVE_COLLAPSE) {
                /*
                 * (@)EVENT:Collapsing(NODE)
                 * Sent when the user is about to close the
                 * specified NODE of the TreeView.
                 * The event should return 0 to prevent the
                 * action, 1 to allow it.
                 * (@)APPLIES_TO:TreeView
                 */
                PerlResult = DoEvent(NOTXSCALL perlud, PERLWIN32GUI_NEM_CONTROL4, "Collapsing",
                    PERLWIN32GUI_ARGTYPE_LONG, (IV) tv_notify->itemNew.hItem,
                    -1);
            } else {
                /*
                 * (@)EVENT:Expanding(NODE)
                 * Sent when the user is about to open the
                 * specified NODE of the TreeView
                 * The event should return 0 to prevent the
                 * action, 1 to allow it.
                 * (@)APPLIES_TO:TreeView
                 */
                PerlResult = DoEvent(NOTXSCALL perlud, PERLWIN32GUI_NEM_CONTROL5, "Expanding",
                    PERLWIN32GUI_ARGTYPE_LONG, (IV) tv_notify->itemNew.hItem,
                    -1);
            }

            // Force result if event is handle
            if (perlud->dwPlStyle & PERLWIN32GUI_EVENTHANDLING) {
                perlud->forceResult = (PerlResult == 0 ? TRUE : FALSE);
                PerlResult = 0; // MsgLoop return ForceResult 
            }
            break;

        case TVN_KEYDOWN:

            /*
             * (@)EVENT:KeyDown(KEY)
             * Sent when the user presses a key while the TreeView
             * control has focus; KEY is the ASCII code of the
             * key being pressed.
             * (@)APPLIES_TO:TreeView
             */
            TV_KEYDOWN FAR * tv_keydown = (TV_KEYDOWN FAR *) lParam;
            PerlResult = DoEvent(NOTXSCALL perlud, PERLWIN32GUI_NEM_CONTROL1, "KeyDown",
                PERLWIN32GUI_ARGTYPE_LONG, (LONG) tv_keydown->wVKey,
                -1);

            break;
        } 
    }

    return PerlResult;
}

MODULE = Win32::GUI::TreeView       PACKAGE = Win32::GUI::TreeView

PROTOTYPES: DISABLE

#pragma message( "*** PACKAGE Win32::GUI::TreeView..." )



    ###########################################################################
    # (@)METHOD:CreateDragImage(NODE)
    # Creates a dragging bitmap for the specified item in a tree view control.
HIMAGELIST
CreateDragImage(handle,hitem)
    HWND handle
    HTREEITEM hitem
CODE:
    RETVAL = TreeView_CreateDragImage(handle, hitem);
OUTPUT:
    RETVAL

    ###########################################################################
    # (@)METHOD:DeleteAllItems()
    # (@)METHOD:Reset()
    # Deletes all nodes from the TreeView.
BOOL
DeleteAllItems(handle)
    HWND handle
ALIAS:
     Win32::GUI::TreeView::Reset = 1
CODE:
    RETVAL = TreeView_DeleteAllItems(handle);
OUTPUT:
    RETVAL

    ###########################################################################
    # (@)METHOD:DeleteItem(NODE)
    # Removes the specified B<NODE> from the TreeView.
BOOL
DeleteItem(handle,item)
    HWND handle
    HTREEITEM item
CODE:
    RETVAL = TreeView_DeleteItem(handle,item);
OUTPUT:
    RETVAL

    ###########################################################################
    # (@)METHOD:EditLabel(NODE)
    # Begins in-place editing of the specified item's text, replacing the text of the item with a single-line edit control containing the text.
HWND
EditLabel(handle,item)
    HWND handle
    HTREEITEM item
CODE:
    RETVAL = TreeView_EditLabel(handle,item);
OUTPUT:
    RETVAL

    ###########################################################################
    # (@)METHOD:EndEditLabelNow([FLAG_CANCEL=TRUE])
    # Ends the editing of a tree view item's label. 
BOOL 
EndEditLabelNow(handle,flag=TRUE)
    HWND handle
    BOOL flag
CODE:
    RETVAL = TreeView_EndEditLabelNow(handle,flag);
OUTPUT:
    RETVAL

    ###########################################################################
    # (@)METHOD:EnsureVisible(NODE)
    # Ensures that a tree view item is visible, expanding the parent item or scrolling the tree view control, if necessary.
BOOL
EnsureVisible(handle,item)
    HWND handle
    HTREEITEM item
CODE:
    RETVAL = TreeView_EnsureVisible(handle, item);
OUTPUT:
    RETVAL

    ###########################################################################
    # (@)METHOD:Expand(NODE, [FLAG])
    # Expands or collapses the list of child items associated with the specified parent item.
BOOL
Expand(handle,item,flag=TVE_EXPAND)
    HWND handle
    HTREEITEM item
    UINT flag
CODE:
    RETVAL = TreeView_Expand(handle, item, flag);
OUTPUT:
    RETVAL

    ###########################################################################
    # (@)METHOD:GetBkColor()
    # Retrieves the current background color of the TreeView
COLORREF
GetBkColor(handle)
    HWND handle
CODE:
    RETVAL = TreeView_GetBkColor(handle);
OUTPUT:
    RETVAL

    ###########################################################################
    # (@)METHOD:GetChild(NODE)
    # Returns the handle of the first child node for the given NODE.
HTREEITEM
GetChild(handle,item)
    HWND handle
    HTREEITEM item
CODE:
    RETVAL = TreeView_GetChild(handle, item);
OUTPUT:
    RETVAL

    ###########################################################################
    # (@)METHOD:GetCount()
    # (@)METHOD:Count()
    # Returns the number of nodes in the TreeView.
UINT
GetCount(handle)
    HWND handle
ALIAS:
    Win32::GUI::TreeView::Count = 1
CODE:
    RETVAL = TreeView_GetCount(handle);
OUTPUT:
    RETVAL

    ###########################################################################
    # (@)METHOD:GetDropHilight()
    # Retrieves the tree view item that is the target of a drag-and-drop operation.
HTREEITEM
GetDropHilight(handle)
    HWND handle
CODE:
    RETVAL = TreeView_GetDropHilight(handle);
OUTPUT:
    RETVAL

    ###########################################################################
    # (@)METHOD:GetEditControl()
    # Retrieves the handle to the edit control being used to edit a tree view item's text.
HWND
GetEditControl(handle)
    HWND handle
CODE:
    RETVAL = TreeView_GetEditControl(handle);
OUTPUT:
    RETVAL

    ###########################################################################
    # (@)METHOD:GetFirstVisible()
    # Retrieves the first visible item in a TreeView. 
HTREEITEM
GetFirstVisible(handle)
    HWND handle
CODE:
    RETVAL = TreeView_GetFirstVisible(handle);
OUTPUT:
    RETVAL

    ###########################################################################
    # (@)METHOD:GetImageList([TYPE=TVSIL_NORMAL])
    # Retrieves the handle to the normal or state image list associated with a TreeView.
    # B<TYPE> = TVSIL_NORMAL | TVSIL_STATE 
HIMAGELIST
GetImageList(handle,type=TVSIL_NORMAL )
    HWND handle
    int type
CODE:
    RETVAL = TreeView_GetImageList(handle,type);
OUTPUT:
    RETVAL

    ###########################################################################
    # (@)METHOD:GetIndent()
    # Retrieves the amount, in pixels, that child items are indented relative to their parent items.  
UINT
GetIndent(handle)
    HWND handle
CODE:
    RETVAL = TreeView_GetIndent(handle);
OUTPUT:
    RETVAL

    ###########################################################################
    # (@)METHOD:GetInsertMarkColor()
    # Retrieves the color used to draw the insertion mark for the tree view.
COLORREF
GetInsertMarkColor(handle)
    HWND handle
CODE:
    RETVAL = TreeView_GetInsertMarkColor(handle);
OUTPUT:
    RETVAL

    ###########################################################################
    # (@)METHOD:GetISearchString(STRING)
    # Retrieves the incremental search string for a tree view control.
BOOL
GetISearchString(handle,lpsz)
    HWND handle
    LPTSTR lpsz
CODE:
    RETVAL = TreeView_GetISearchString(handle,lpsz);
OUTPUT:
    RETVAL

    ###########################################################################
    # (@)METHOD:GetItem(NODE)
    # (@)METHOD:ItemInfo(NODE)
    # Returns an associative array of information about the given NODE:
    #     -children
    #     -image
    #     -parent
    #     -selectedimage
    #     -state
    #     -text
void
GetItem(handle,item)
    HWND handle
    HTREEITEM item
ALIAS:
    Win32::GUI::TreeView::ItemInfo = 1
PREINIT:
    TV_ITEM tv_item;
    char pszText[1024];
PPCODE:
    ZeroMemory(&tv_item, sizeof(TV_ITEM));
    tv_item.hItem = item;
    tv_item.mask = TVIF_CHILDREN | TVIF_HANDLE | TVIF_IMAGE
                 | TVIF_PARAM | TVIF_SELECTEDIMAGE
                 | TVIF_TEXT | TVIF_STATE;
    tv_item.pszText = pszText;
    tv_item.cchTextMax = 1024;
    if(TreeView_GetItem(handle, &tv_item)) {
        EXTEND(SP, 12);
        XST_mPV(0, "-text");
        XST_mPV(1, tv_item.pszText);
        XST_mPV(2, "-image");
        XST_mIV(3, tv_item.iImage);
        XST_mPV(4, "-selectedimage");
        XST_mIV(5, tv_item.iSelectedImage);
        XST_mPV(6, "-children");
        XST_mIV(7, tv_item.cChildren);
        XST_mPV(8, "-parent");
        XST_mIV(9, (IV) TreeView_GetParent(handle, item));
        XST_mPV(10, "-state");
        XST_mIV(11, tv_item.state);
        XSRETURN(12);
    } else {
        XSRETURN_EMPTY;
    }

    ###########################################################################
    # (@)METHOD:GetItemHeight()
    # Retrieves the current height of the tree view items.
int
GetItemHeight(handle)
    HWND handle
CODE:
    RETVAL = TreeView_GetItemHeight(handle);
OUTPUT:
    RETVAL

    ###########################################################################
    # (@)METHOD:GetItemRect(NODE,[FLAG=FALSE])
    # Retrieves the bounding rectangle for a tree view item and indicates whether the item is visible.
    # If B<FLAG> is TRUE, the bounding rectangle includes only the text of the item. Otherwise, it includes the entire line that the item occupies in the tree view control. 
void
GetItemRect(handle,item,flag=FALSE)
    HWND handle
    HTREEITEM item
    BOOL flag
PREINIT:
    RECT    myRect;
PPCODE:
    if (TreeView_GetItemRect (handle, item, &myRect, flag)) {
        EXTEND(SP, 4);
        XST_mIV(0, myRect.left);
        XST_mIV(1, myRect.top);
        XST_mIV(2, myRect.right);
        XST_mIV(3, myRect.bottom);
        XSRETURN(4);
    }
    else
        XSRETURN_UNDEF;

    ###########################################################################
    # (@)METHOD:GetLastVisible()
    # Retrieves the last expanded item in a tree view control. 
HTREEITEM
GetLastVisible(handle)
    HWND handle
CODE:
    RETVAL = TreeView_GetLastVisible(handle);
OUTPUT:
    RETVAL

    ###########################################################################
    # (@)METHOD:GetNextItem(ITEM,FLAG)
    # Retrieves the tree view item that bears the specified relationship to a specified item.
    #
    # B<FLAG> specifying the item to retrieve : 
    #  TVGN_CARET           = Retrieves the currently selected item.
    #  TVGN_CHILD           = Retrieves the first child item of the item specified by the hitem parameter. 
    #  TVGN_DROPHILITE      = Retrieves the item that is the target of a drag-and-drop operation.
    #  TVGN_FIRSTVISIBLE    = Retrieves the first visible item. 
    #  TVGN_NEXT            = Retrieves the next sibling item.
    #  TVGN_NEXTVISIBLE     = Retrieves the next visible item that follows the specified item. The specified item must be visible.
    #  TVGN_PARENT          = Retrieves the parent of the specified item. 
    #  TVGN_PREVIOUS        = Retrieves the previous sibling item. 
    #  TVGN_PREVIOUSVISIBLE = Retrieves the first visible item that precedes the specified item. The specified item must be visible.
    #  TVGN_ROOT            = Retrieves the topmost or very first item of the tree view control.

HTREEITEM
GetNextItem(handle,item,flag)
    HWND handle
    HTREEITEM item
    UINT flag
CODE:
    RETVAL = TreeView_GetNextItem(handle,item,flag);
OUTPUT:
    RETVAL

    ###########################################################################
    # (@)METHOD:GetNextSibling(NODE)
    # Returns the handle of the next sibling node for the given B<NODE>.
HTREEITEM
GetNextSibling(handle,item)
    HWND handle
    HTREEITEM item
CODE:
    RETVAL = TreeView_GetNextSibling(handle, item);
OUTPUT:
    RETVAL

    ###########################################################################
    # (@)METHOD:GetNextVisible(NODE)
    # Retrieves the next visible item that follows a specified item in a tree view control.
HTREEITEM
GetNextVisible(handle,item)
    HWND handle
    HTREEITEM item
CODE:
    RETVAL = TreeView_GetNextVisible(handle, item);
OUTPUT:
    RETVAL

    ###########################################################################
    # (@)METHOD:GetParent(NODE)
    # Returns the handle of the parent node for the given B<NODE>.
    #
    # NOTE: With no B<NODE> parameter this is the standard
    # L<GetParent()|Win32::GUI::Reference::Methods/GetParent>
    # method, returning the parent window. 
HTREEITEM
GetParent(handle,item = NULL)
    HWND handle
    HTREEITEM item
CODE:
    if(items == 1) { /* NOTE this is the XS defined 'items' var, not 'item' */
        SV   *SvParent;
        HWND parentHandle = GetParent(handle);

        if (parentHandle && (SvParent = SV_SELF_FROM_WINDOW(parentHandle)) && SvROK(SvParent)) {
            XPUSHs(SvParent);
            XSRETURN(1);
        }
        else {
            XSRETURN_UNDEF;
        }
    }
    else {
        RETVAL = TreeView_GetParent(handle, item);
    }
OUTPUT:
    RETVAL

    ###########################################################################
    # (@)METHOD:GetPrevSibling(NODE)
    # Returns the handle of the previous sibling node for the given B<NODE>.
HTREEITEM
GetPrevSibling(handle,item)
    HWND handle
    HTREEITEM item
CODE:
    RETVAL = TreeView_GetPrevSibling(handle, item);
OUTPUT:
    RETVAL

    ###########################################################################
    # (@)METHOD:GetPrevVisible(NODE)
    # Retrieves the first visible item that precedes a specified item in a TreeView.
HTREEITEM
GetPrevVisible(handle,item)
    HWND handle
    HTREEITEM item
CODE:
    RETVAL = TreeView_GetPrevVisible(handle, item);
OUTPUT:
    RETVAL

    ###########################################################################
    # (@)METHOD:GetRoot()
    # Returns the handle of the TreeView root node.
HTREEITEM
GetRoot(handle)
    HWND handle
CODE:
    RETVAL = TreeView_GetRoot(handle);
OUTPUT:
    RETVAL

    ###########################################################################
    # (@)METHOD:GetScrollTime()
    # Retrieves the maximum scroll time for the TreeView.
UINT
GetScrollTime(handle)
    HWND handle
CODE:
    RETVAL = TreeView_GetScrollTime(handle);
OUTPUT:
    RETVAL

    ###########################################################################
    # (@)METHOD:GetSelection()
    # (@)METHOD:SelectedItem()
    # Returns the handle of the currently selected node.
HTREEITEM
GetSelection(handle)
    HWND handle
ALIAS:
    Win32::GUI::TreeView::SelectedItem = 1
CODE:
    RETVAL = TreeView_GetSelection(handle);
OUTPUT:
    RETVAL

    ###########################################################################
    # (@)METHOD:GetTextColor()
    # Retrieves the current text color of the control.
COLORREF
GetTextColor(handle)
    HWND handle
CODE:
    RETVAL = TreeView_GetTextColor(handle);
OUTPUT:
    RETVAL

    ###########################################################################
    # (@)METHOD:GetToolTips()
    # Retrieves the handle to the child tooltip control used by a TreeView.
HWND
GetToolTips(handle)
    HWND handle
CODE:
    RETVAL = TreeView_GetToolTips(handle);
OUTPUT:
    RETVAL

    ###########################################################################
    # (@)METHOD:GetUnicodeFormat()
    # Retrieves the UNICODE character format flag for the control.
BOOL
GetUnicodeFormat(handle)
    HWND handle
CODE:
    RETVAL = TreeView_GetUnicodeFormat(handle);
OUTPUT:
    RETVAL

    ###########################################################################
    # (@)METHOD:GetVisibleCount()
    # (@)METHOD:VisibleCount()
    # Obtains the number of items that can be fully visible in the client window of a TreeView.
UINT
GetVisibleCount(handle)
    HWND handle
ALIAS:
    Win32::GUI::TreeView::VisibleCount = 1
CODE:
    RETVAL = TreeView_GetVisibleCount(handle);
OUTPUT:
    RETVAL

    ###########################################################################
    # (@)METHOD:HitTest(X, Y)
    # Determines the location of the specified point relative to the client area of a TreeView.
void
HitTest(handle,x,y)
    HWND handle
    LONG x
    LONG y
PREINIT:
    TV_HITTESTINFO ht;
PPCODE:
    ht.pt.x = x;
    ht.pt.y = y;
    TreeView_HitTest(handle, &ht);
    if(GIMME == G_ARRAY) {
        EXTEND(SP, 2);
        XST_mIV(0, (IV) ht.hItem);
        XST_mIV(1, ht.flags);
        XSRETURN(2);
    } else {
        XSRETURN_IV((IV) ht.hItem);
    }

    ###########################################################################
    # (@)METHOD:InsertItem(%OPTIONS)
    # Inserts a new node in the TreeView.
    #
    # Allowed B<%OPTIONS> are:
    #     -bold => 0/1, default 0
    #     -image => NUMBER
    #         index of an image from the associated ImageList
    #     -item => NUMBER
    #         handle of the node after which the new node is to be inserted,
    #         or one of the following special values:
    #             0xFFFF0001: at the beginning of the list
    #             0xFFFF0002: at the end of the list
    #             0xFFFF0003: in alphabetical order
    #         the default value is at the end of the list
    #     -parent => NUMBER
    #         handle of the parent node for the new node
    #     -selected => 0/1, default 0
    #     -selectedimage => NUMBER
    #         index of an image from the associated ImageList
    #     -text => STRING
    #         the text for the node
HTREEITEM
InsertItem(handle,...)
    HWND handle
PREINIT:
    TV_ITEM Item;
    TV_INSERTSTRUCT Insert;
    unsigned int tlen;
    int i, next_i;
    int imageSeen, selectedImageSeen;
    LPSTR pszText;
    char * option;
CODE:
    ZeroMemory(&Item, sizeof(TV_ITEM));
    ZeroMemory(&Insert, sizeof(TV_INSERTSTRUCT));
    Insert.hParent = NULL;
    Insert.hInsertAfter = TVI_LAST;

    imageSeen = 0;
    selectedImageSeen = 0;
    pszText = NULL;

    next_i = -1;
    for(i = 1; i < items; i++) {
        if(next_i == -1) {
            option = SvPV_nolen(ST(i));
            if(strcmp(option, "-text") == 0) {
                next_i = i + 1;
                tlen = SvCUR(ST(next_i));
                pszText = (LPSTR) safemalloc(tlen + 1);
                strcpy(pszText, SvPV_nolen(ST(next_i)));
                Item.pszText = pszText;
                Item.cchTextMax = tlen;
                SwitchBit(Item.mask, TVIF_TEXT, 1);
            } else if(strcmp(option, "-image") == 0) {
                next_i = i + 1;
                imageSeen = 1;
                Item.iImage = (int)SvIV(ST(next_i));
                SwitchBit(Item.mask, TVIF_IMAGE, 1);
            } else if(strcmp(option, "-selectedimage") == 0) {
                next_i = i + 1;
                selectedImageSeen = 1;
                Item.iSelectedImage = (int)SvIV(ST(next_i));
                SwitchBit(Item.mask, TVIF_SELECTEDIMAGE, 1);
            } else if(strcmp(option, "-parent") == 0) {
                next_i = i + 1;
                Insert.hParent = (HTREEITEM) handle_From(NOTXSCALL ST(next_i));
            } else if(strcmp(option, "-item") == 0
                   || strcmp(option, "-index") == 0) {
                next_i = i + 1;
                Insert.hInsertAfter = (HTREEITEM) handle_From(NOTXSCALL ST(next_i));
            } else if(strcmp(option, "-bold") == 0) {
                next_i = i + 1;
                SwitchBit(Item.state, TVIS_BOLD, SvIV(ST(next_i)));
                SwitchBit(Item.stateMask, TVIS_BOLD, 1);
                SwitchBit(Item.mask, TVIF_STATE, 1);
            } else if(strcmp(option, "-selected") == 0) {
                next_i = i + 1;
                SwitchBit(Item.state, TVIS_SELECTED, SvIV(ST(next_i)));
                SwitchBit(Item.stateMask, TVIS_SELECTED, 1);
                SwitchBit(Item.mask, TVIF_STATE, 1);
            }
        } else {
            next_i = -1;
        }
    }
    if(selectedImageSeen == 0 && imageSeen != 0) {
        Item.iSelectedImage = Item.iImage;
        SwitchBit(Item.mask, TVIF_SELECTEDIMAGE, 1);
    }
    Insert.item = Item;
    RETVAL = TreeView_InsertItem(handle, &Insert);
    if (pszText) safefree(pszText);
OUTPUT:
    RETVAL

    ###########################################################################
    # (@)METHOD:Select(NODE, [FLAG=TVGN_CARET])
    # Selects the given B<NODE >in the TreeView. 
    # If B<NODE> is 0 (zero), the selected item, if any, is deselected.
    #
    # Optional B<FLAG> parameter
    #  TVGN_CARET        = Sets the selection to the given item. 
    #  TVGN_DROPHILITE   = Redraws the given item in the style used to indicate the target of a drag-and-drop operation. 
    #  TVGN_FIRSTVISIBLE = Ensures that the specified item is visible, and, if possible, displays it at the top of the control's window.
BOOL
Select(handle,item,flag=TVGN_CARET)
    HWND handle
    HTREEITEM item
    WPARAM flag
CODE:
    RETVAL = (BOOL) TreeView_Select(handle, item, flag);
OUTPUT:
    RETVAL

    ###########################################################################
    # (@)METHOD:SelectDropTarget(NODE)
    # Redraws a specified tree view control item in the style used to indicate the target of a drag-and-drop operation.
BOOL
SelectDropTarget(handle,item)
    HWND handle
    HTREEITEM item
CODE:
    RETVAL = TreeView_SelectDropTarget(handle, item);
OUTPUT:
    RETVAL

    ###########################################################################
    # (@)METHOD:SelectItem(NODE)
    # Selects the specified tree view item.
BOOL
SelectItem(handle,item)
    HWND handle
    HTREEITEM item
CODE:
    RETVAL = TreeView_SelectItem(handle, item);
OUTPUT:
    RETVAL

    ###########################################################################
    # (@)METHOD:SetBkColor(COLOR)
    # Sets the background color for the control.
COLORREF
SetBkColor(handle,color)
    HWND handle
    COLORREF color
CODE:
    RETVAL = TreeView_SetBkColor(handle, color);
OUTPUT:
    RETVAL

    ###########################################################################
    # (@)METHOD:SelectSetFirstVisible(NODE)
    # Scrolls the tree view control vertically to ensure that the specified item is visible. If possible, the specified item becomes the first visible item at the top of the control's window.
BOOL
SelectSetFirstVisible(handle,item)
    HWND handle
    HTREEITEM item
CODE:
    RETVAL= TreeView_SelectSetFirstVisible(handle, item);
OUTPUT:
    RETVAL

    ###########################################################################
    # (@)METHOD:SetImageList(IMAGELIST, [TYPE])
    # Sets the normal or state image list for a tree view control and redraws the control using the new images.
HIMAGELIST
SetImageList(handle,imagelist,type=TVSIL_NORMAL)
    HWND handle
    HIMAGELIST imagelist
    WPARAM type
CODE:
    RETVAL = TreeView_SetImageList(handle, imagelist, type);
OUTPUT:
    RETVAL

    ###########################################################################
    # (@)METHOD:SetIndent(VALUE)
    # Sets the width of indentation for a tree view control and redraws the control to reflect the new width.
BOOL
SetIndent(handle,value)
    HWND handle
    UINT value
CODE:
    RETVAL = TreeView_SetIndent(handle, value);
OUTPUT:
    RETVAL

    ###########################################################################
    # (@)METHOD:SetInsertMark(NODE,[FLAG_AFTER=FALSE])
    # Sets the insertion mark in a tree view control.
BOOL
SetInsertMark(handle,item,flag=FALSE)
    HWND handle
    HTREEITEM item
    BOOL flag
CODE:
    RETVAL = TreeView_SetInsertMark(handle,item,flag);
OUTPUT:
    RETVAL

    ###########################################################################
    # (@)METHOD:SetInsertMarkColor(COLOR)
    # Sets the color used to draw the insertion mark for the tree view.
COLORREF
SetInsertMarkColor(handle,color)
    HWND handle
    COLORREF color
CODE:
    RETVAL = TreeView_SetInsertMarkColor(handle, color);
OUTPUT:
    RETVAL

    ###########################################################################
    # (@)METHOD:SetItem(NODE, %OPTIONS)
    # (@)METHOD:ChangeItem(NODE, %OPTIONS)
    # Change most of the options used when the item was created (see InsertItem()).
    # Allowed B<%OPTIONS> are:
    #     -bold
    #     -image
    #     -selected
    #     -selectedimage
    #     -text
BOOL
SetItem(handle,item,...)
    HWND handle
    HTREEITEM item
ALIAS:
    Win32::GUI::TreeView::ChangeItem = 1
PREINIT:
    int i, next_i, imageSeen, selectedImageSeen;
    STRLEN tlen;
    TV_ITEM Item;
    char * option;
CODE:
    ZeroMemory(&Item, sizeof(TV_ITEM));
    Item.hItem = item;
    imageSeen = 0;
    selectedImageSeen = 0;
    next_i = -1;
    for(i = 2; i < items; i++) {
        if(next_i == -1) {
            option = SvPV_nolen(ST(i));
            if(strcmp(option, "-text") == 0) {
                next_i = i + 1;
                Item.pszText = SvPV(ST(next_i), tlen);
                Item.cchTextMax = tlen;
                SwitchBit(Item.mask, TVIF_TEXT, 1);
            } else if(strcmp(option, "-image") == 0) {
                next_i = i + 1;
                imageSeen = 1;
                Item.iImage = (int)SvIV(ST(next_i));
                SwitchBit(Item.mask, TVIF_IMAGE, 1);
            } else if(strcmp(option, "-selectedimage") == 0) {
                next_i = i + 1;
                selectedImageSeen = 1;
                Item.iSelectedImage = (int)SvIV(ST(next_i));
                SwitchBit(Item.mask, TVIF_SELECTEDIMAGE, 1);
            } else if(strcmp(option, "-bold") == 0) {
                next_i = i + 1;
                SwitchBit(Item.state, TVIS_BOLD, SvIV(ST(next_i)));
                SwitchBit(Item.stateMask, TVIS_BOLD, 1);
                SwitchBit(Item.mask, TVIF_STATE, 1);
            } else if(strcmp(option, "-selected") == 0) {
                next_i = i + 1;
                SwitchBit(Item.state, TVIS_SELECTED, SvIV(ST(next_i)));
                SwitchBit(Item.stateMask, TVIS_SELECTED, 1);
                SwitchBit(Item.mask, TVIF_STATE, 1);
            }
        } else {
            next_i = -1;
        }
    }
    if(selectedImageSeen == 0 && imageSeen != 0) {
        Item.iSelectedImage = Item.iImage;
        SwitchBit(Item.mask, TVIF_SELECTEDIMAGE, 1);
    }
    RETVAL = TreeView_SetItem(handle, &Item);
OUTPUT:
    RETVAL

    ###########################################################################
    # (@)METHOD:SetItemHeight(HEIGHT)
    # Sets the height of the tree view items.
int
SetItemHeight(handle,cy)
    HWND  handle
    short cy
CODE:
    RETVAL = TreeView_SetItemHeight(handle, cy);
OUTPUT:
    RETVAL

    ###########################################################################
    # (@)METHOD:SetScrollTime(TIME)
    # Sets the maximum scroll time for the tree view control. 
int
SetScrollTime(handle,time)
    HWND  handle
    UINT time
CODE:
    RETVAL = TreeView_SetScrollTime(handle, time);
OUTPUT:
    RETVAL

    ###########################################################################
    # (@)METHOD:SetTextColor(COLOR)
    # Sets the text color of the control.
COLORREF
SetTextColor(handle,color)
    HWND handle
    COLORREF color
CODE:
    RETVAL = TreeView_SetTextColor(handle, color);
OUTPUT:
    RETVAL

    ###########################################################################
    # (@)METHOD:SetToolTips(TOOLTIP)
    # Sets a tree view control's child tooltip control.
HWND
SetToolTips(handle,tooltip)
    HWND handle
    HWND tooltip
CODE:
    RETVAL = TreeView_SetToolTips(handle, tooltip);
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
    RETVAL = TreeView_SetUnicodeFormat(handle, flag);
OUTPUT:
    RETVAL

    ###########################################################################
    # (@)METHOD:SortChildren(NODE)
    # (@)METHOD:Sort(NODE)
    # Sorts the childs of the specified NODE in the TreeView.
BOOL
SortChildren(handle,item)
    HWND handle
    HTREEITEM item
ALIAS:
    Win32::GUI::TreeView::Sort = 1
CODE:
    RETVAL = TreeView_SortChildren(handle, item, 0);
OUTPUT:
    RETVAL

    # TreeView_SortChildrenCB

    ###########################################################################
    ###########################################################################
    ###########################################################################

    ###########################################################################
    # (@)METHOD:Clear([NODE])
    # Deletes all nodes from the TreeView if no argument is given;
    # otherwise, delete all nodes under the given B<NODE>.
BOOL
Clear(handle,...)
    HWND handle
CODE:
    if(items != 1 && items != 2)
        croak("Usage: Clear(handle, [item]);\n");
    if(items == 1)
        RETVAL = TreeView_DeleteAllItems(handle);
    else
        RETVAL = TreeView_Expand(handle,
                                 INT2PTR(HTREEITEM,SvIV(ST(1))),
                                 TVE_COLLAPSE | TVE_COLLAPSERESET);
OUTPUT:
    RETVAL

    ###########################################################################
    # (@)METHOD:Collapse(NODE)
    # Closes a B<NODE> of the TreeView.
BOOL
Collapse(handle,item)
    HWND handle
    HTREEITEM item
CODE:
    RETVAL = TreeView_Expand(handle, item, TVE_COLLAPSE);
OUTPUT:
    RETVAL

    ###########################################################################
    # (@)METHOD:Indent([VALUE])
    # Set or Get Indent value.
UINT
Indent(handle,value=(UINT) -1)
    HWND handle
    UINT value
CODE:
    if(items == 2)
        RETVAL = TreeView_SetIndent(handle, value);
    else
        RETVAL = TreeView_GetIndent(handle);
OUTPUT:
    RETVAL

    ###########################################################################
    # (@)METHOD:FirstVisible([NODE])
    # Set or Get first visible node.
HTREEITEM
FirstVisible(handle,item=0)
    HWND handle
    HTREEITEM item
CODE:
    RETVAL = TreeView_GetFirstVisible(handle);
    if(items == 2)
        TreeView_SelectSetFirstVisible(handle, item);
OUTPUT:
    RETVAL

    ###########################################################################
    # (@)METHOD:ItemCheck(NODE, [VALUE])
    # Set or Get node checked state.
BOOL
ItemCheck(handle,item,value=FALSE)
    HWND handle
    HTREEITEM item
    BOOL value
PREINIT:
    TVITEM tvitem;
CODE:
    if(items == 3) {
        tvitem.mask = TVIF_HANDLE | TVIF_STATE;
        tvitem.hItem = item;
        tvitem.stateMask = TVIS_STATEIMAGEMASK;
        tvitem.state = INDEXTOSTATEIMAGEMASK((value ? 2 : 1));
        RETVAL = TreeView_SetItem(handle, &tvitem);
    } else {
        tvitem.mask = TVIF_HANDLE | TVIF_STATE;
        tvitem.hItem = item;
        tvitem.stateMask = TVIS_STATEIMAGEMASK;
        TreeView_GetItem(handle, &tvitem);
        RETVAL = ((BOOL)(tvitem.state >> 12) -1);
    }
OUTPUT:
    RETVAL

    ###########################################################################
    # (@)METHOD:TextColor([COLOR])
    # Gets or sets the text color for the control.
COLORREF
TextColor(handle,color=(COLORREF) -1)
    HWND handle
    COLORREF color
CODE:
    if(items == 2) {
        if(TreeView_SetTextColor(handle, color))
            RETVAL = TreeView_GetTextColor(handle);
        else
            RETVAL = (COLORREF) -1;
    } else
        RETVAL = TreeView_GetTextColor(handle);
OUTPUT:
    RETVAL

    ###########################################################################
    # (@)METHOD:BackColor([COLOR])
    # Gets or sets the background color for the control.
COLORREF
BackColor(handle,color=(COLORREF) -1)
    HWND handle
    COLORREF color
CODE:
    if(items == 2) {
        if(TreeView_SetBkColor(handle, color))
            RETVAL = TreeView_GetBkColor(handle);
        else
            RETVAL = (COLORREF) -1;
    } else
        RETVAL = TreeView_GetBkColor(handle);
OUTPUT:
    RETVAL

