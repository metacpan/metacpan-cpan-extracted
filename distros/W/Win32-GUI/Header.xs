    /*
    ###########################################################################
    # (@)PACKAGE:Win32::GUI::Header
    #
    # $Id: Header.xs,v 1.6 2010/04/08 21:26:48 jwgui Exp $
    #
    ###########################################################################
    */

#include "GUI.h"

void 
Header_onPreCreate(NOTXSPROC LPPERLWIN32GUI_CREATESTRUCT perlcs) {

    perlcs->cs.lpszClass = WC_HEADER;
    perlcs->cs.style = WS_VISIBLE | WS_CHILD | HDS_HORZ;
}

BOOL
Header_onParseOption(NOTXSPROC char *option, SV* value, LPPERLWIN32GUI_CREATESTRUCT perlcs) {

    BOOL retval = TRUE;

    if(strcmp(option, "-imagelist") == 0) {
        perlcs->hImageList = (HIMAGELIST) handle_From(NOTXSCALL value);
    } else if BitmaskOptionValue("-buttons",    perlcs->cs.style, HDS_BUTTONS)
    } else if BitmaskOptionValue("-dragdrop",   perlcs->cs.style, HDS_DRAGDROP)
    } else if BitmaskOptionValue("-fulldrag",   perlcs->cs.style, HDS_FULLDRAG)
    } else if BitmaskOptionValue("-hidden",     perlcs->cs.style, HDS_HIDDEN)
    } else if BitmaskOptionValue("-horizontal", perlcs->cs.style, HDS_HORZ)
    } else if BitmaskOptionValue("-hottrack",   perlcs->cs.style, HDS_HOTTRACK)
    } else if BitmaskOptionValue("-nodivider",  perlcs->cs.style, CCS_NODIVIDER)
    } else retval = FALSE;

    return retval;
}

void 
Header_onPostCreate(NOTXSPROC HWND myhandle, LPPERLWIN32GUI_CREATESTRUCT perlcs) {

    if(perlcs->hImageList != NULL)
        Header_SetImageList (myhandle, perlcs->hImageList);
}

BOOL
Header_onParseEvent(NOTXSPROC char *name, int* eventID) {

    BOOL retval = TRUE;

         if Parse_Event("BeginTrack",      PERLWIN32GUI_NEM_CONTROL1)
    else if Parse_Event("EndTrack",        PERLWIN32GUI_NEM_CONTROL2)
    else if Parse_Event("Track",           PERLWIN32GUI_NEM_CONTROL3)
    else if Parse_Event("DividerDblClick", PERLWIN32GUI_NEM_CONTROL4)
    else if Parse_Event("ItemClick",       PERLWIN32GUI_NEM_CONTROL5)
    else if Parse_Event("ItemDblClick",    PERLWIN32GUI_NEM_CONTROL6)
    else retval = FALSE;

    return retval;
}

int
Header_onEvent (NOTXSPROC LPPERLWIN32GUI_USERDATA perlud, UINT uMsg, WPARAM wParam, LPARAM lParam) {

    int PerlResult = 1;

    if ( uMsg == WM_NOTIFY ) {

        LPNMHEADER nmh = (LPNMHEADER) lParam;

        switch (nmh->hdr.code) {

        case HDN_BEGINTRACK :

            /*
             * (@)EVENT:BeginTrack(INDEX, WIDTH)
             * Sent when a divider of the Header control
             * is being moved; the event must return 0 to
             * prevent moving the divider, 1 to allow it.
             * Passes the zero-based INDEX
             * of the item being resized and its current
             * WIDTH.
             * (@)APPLIES_TO:Header
             */
            PerlResult = DoEvent(NOTXSCALL perlud, PERLWIN32GUI_NEM_CONTROL1, "BeginTrack",
                    PERLWIN32GUI_ARGTYPE_LONG, (LONG) nmh->iItem,
                    PERLWIN32GUI_ARGTYPE_LONG, (LONG) nmh->pitem->cxy,
                    -1);

            // Force result if event is handle
            if (perlud->dwPlStyle & PERLWIN32GUI_EVENTHANDLING) {
                perlud->forceResult = (PerlResult == 0 ? TRUE : FALSE);
                PerlResult = 0; // MsgLoop return ForceResult 
            }
            break;

        case HDN_ENDTRACK :

            /*
             * (@)EVENT:EndTrack(INDEX, WIDTH)
             * Sent when a divider of the Header control
             * has been moved. Passes the zero-based INDEX
             * of the item being resized and its current
             * WIDTH.
             * (@)APPLIES_TO:Header
             */
            PerlResult = DoEvent(NOTXSCALL perlud, PERLWIN32GUI_NEM_CONTROL2, "EndTrack",
                    PERLWIN32GUI_ARGTYPE_LONG, (LONG) nmh->iItem,
                    PERLWIN32GUI_ARGTYPE_LONG, (LONG) nmh->pitem->cxy,
                    -1);
            break;

        case HDN_TRACK :

            /*
             * (@)EVENT:Track(INDEX, WIDTH)
             * Sent while a divider of the Header control
             * is being moved; the event must return 1 to
             * continue moving the divider, 0 to end its
             * movement.
             * Passes the zero-based INDEX
             * of the item being resized and its current
             * WIDTH.
             * (@)APPLIES_TO:Header
             */
            PerlResult = DoEvent(NOTXSCALL perlud, PERLWIN32GUI_NEM_CONTROL3, "Track",
                    PERLWIN32GUI_ARGTYPE_LONG, (LONG) nmh->iItem,
                    PERLWIN32GUI_ARGTYPE_LONG, (LONG) nmh->pitem->cxy,
                    -1);

            // Force result if event is handle
            if (perlud->dwPlStyle & PERLWIN32GUI_EVENTHANDLING) {
                perlud->forceResult = (PerlResult == 0 ? TRUE : FALSE);
                PerlResult = 0; // MsgLoop return ForceResult 
            }
            break;

        case HDN_DIVIDERDBLCLICK :

            /*
             * (@)EVENT:DividerDblClick(INDEX)
             * Sent when the user double-clicked on a
             * divider of the Header control.
             * (@)APPLIES_TO:Header
             */
            PerlResult = DoEvent(NOTXSCALL perlud, PERLWIN32GUI_NEM_CONTROL4, "DividerDblClick",
                    PERLWIN32GUI_ARGTYPE_LONG, (LONG) nmh->iItem,
                    -1);
            break;

        case HDN_ITEMCLICK :

            /*
             * (@)EVENT:ItemClick(INDEX)
             * Sent when the user clicked on a Header
             * item.
             * (@)APPLIES_TO:Header
             */
            PerlResult = DoEvent(NOTXSCALL perlud, PERLWIN32GUI_NEM_CONTROL5, "ItemClick",
                    PERLWIN32GUI_ARGTYPE_LONG, (LONG) nmh->iItem,
                    -1);
            break;

        case HDN_ITEMDBLCLICK :

            /*
             * (@)EVENT:ItemDblClick(INDEX)
             * Sent when the user double-clicked on a Header
             * item.
             * (@)APPLIES_TO:Header
             */
            PerlResult = DoEvent(NOTXSCALL perlud, PERLWIN32GUI_NEM_CONTROL6, "ItemDblClick",
                    PERLWIN32GUI_ARGTYPE_LONG, (LONG) nmh->iItem,
                    -1);
            break;
        }
    }

    return PerlResult;
}


MODULE = Win32::GUI::Header     PACKAGE = Win32::GUI::Header

PROTOTYPES: DISABLE

#pragma message( "*** PACKAGE Win32::GUI::Header..." )

    ###########################################################################
    # (@)METHOD:CreateDragImage(INDEX)
    # Creates a transparent version of an item image within an existing Header.
HIMAGELIST
CreateDragImage(handle, index)
    HWND handle
    int index
CODE:
    RETVAL = (HIMAGELIST) Header_CreateDragImage(handle, index);
OUTPUT:
    RETVAL

    ###########################################################################
    # (@)METHOD:DeleteItem(INDEX)
    # Deletes the zero-based B<INDEX> item from the Header.
LRESULT
DeleteItem(handle,index)
    HWND handle
    int index
CODE:
    RETVAL = Header_DeleteItem(handle, index);
OUTPUT:
    RETVAL

    ###########################################################################
    # (@)METHOD:GetImageList()
    # Retrieves the handle to the image list that has been set for an existing header control.
HIMAGELIST
GetImageList(handle)
    HWND handle
CODE:
    RETVAL = (HIMAGELIST) Header_GetImageList(handle);
OUTPUT:
    RETVAL

    ###########################################################################
    # (@)METHOD:GetItem(INDEX)
    # Retrieves information about an item in a Header control.
void
GetItem(handle,index)
    HWND handle
    int index
PREINIT:
    HDITEM Item;
CODE:
    ZeroMemory(&Item, sizeof(HDITEM));
    Item.mask = HDI_BITMAP | HDI_FORMAT | HDI_HEIGHT | HDI_IMAGE  | HDI_ORDER  | HDI_TEXT | HDI_WIDTH;
    if(Header_GetItem(handle, index, &Item)) {
        EXTEND(SP, 14);
        XST_mPV( 0, "-text");
        XST_mPV( 1, Item.pszText);
        XST_mPV( 2, "-image");
        XST_mIV( 3, Item.iImage);
        XST_mPV( 4, "-bitmap");
        XST_mIV( 5, PTR2IV(Item.hbm));
        XST_mPV( 6, "-bitmaponright");
        XST_mIV( 7, (Item.fmt & HDF_BITMAP_ON_RIGHT));
        XST_mPV( 8, "-cxy");
        XST_mIV( 9, Item.cxy);
        XST_mPV(10, "-order");
        XST_mIV(11, Item.iOrder);
        XST_mPV(12, "-align");
        if ( Item.fmt & HDF_CENTER)
            XST_mPV(13, "center");
        else if (Item.fmt & HDF_RIGHT)
            XST_mPV(13, "right");
        else
            XST_mPV(13, "left");
        XSRETURN(14);
    } else {
        XSRETURN_UNDEF;
    }

    ###########################################################################
    # (@)METHOD:GetItemCount()
    # (@)METHOD:Count()
    # Returns the number of items in the Header control.
int
GetItemCount(handle)
    HWND handle
ALIAS:
    Win32::GUI::Header::Count = 1
CODE:
    RETVAL = Header_GetItemCount(handle);
OUTPUT:
    RETVAL

    ###########################################################################
    # (@)METHOD:GetItemRect(INDEX)
    # (@)METHOD:ItemRect(INDEX)
    # Returns a four element array defining the rectangle of the specified
    # zero-based B<INDEX> item; the array contains (left, top, right, bottom).
    # If not succesful returns undef.
void
GetItemRect(handle,index)
    HWND handle
    int index
ALIAS:
    Win32::GUI::Header::ItemRect = 1
PREINIT:
    RECT rect;
CODE:
    if(Header_GetItemRect(handle, index, &rect)) {
        EXTEND(SP, 4);
        XST_mIV(0, rect.left);
        XST_mIV(1, rect.top);
        XST_mIV(2, rect.right);
        XST_mIV(3, rect.bottom);
        XSRETURN(4);
    } else {
        XSRETURN_UNDEF;
    }

    ###########################################################################
    # (@)METHOD:GetOrderArray()
    # Returns an array defining left-to-right of items.
void
GetOrderArray(handle)
    HWND handle
PREINIT:
    int iItems, *lpiArray;
CODE:
    iItems = Header_GetItemCount(handle);
    if (iItems >= 0) {
        lpiArray = (int*) safemalloc (iItems * sizeof(int));
        if(Header_GetOrderArray(handle, iItems, lpiArray)) {
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
    # (@)METHOD:GetUnicodeFormat()
    # Retrieves the UNICODE character format flag for the control.
BOOL
GetUnicodeFormat(handle)
    HWND handle
CODE:
    RETVAL = Header_GetUnicodeFormat(handle);
OUTPUT:
    RETVAL

    ###########################################################################
    # (@)METHOD:HitTest(X, Y)
    # Checks if the specified point is on an Header item;
    # it returns the index of the found item or -1 if none was found.
    # If called in an array context, it returns an additional value containing
    # more info about the position of the specified point.
void
HitTest(handle,x,y)
    HWND handle
    LONG x
    LONG y
PREINIT:
    HDHITTESTINFO ht;
PPCODE:
    ZeroMemory(&ht, sizeof(HDHITTESTINFO));
    ht.pt.x = x;
    ht.pt.y = y;
    if(SendMessage(handle, HDM_HITTEST, 0, (LPARAM) &ht) == -1) {
        XSRETURN_IV(-1);
    } else {
        if(GIMME == G_ARRAY) {
            EXTEND(SP, 2);
            XST_mIV(0, (long) ht.iItem);
            XST_mIV(1, (long) ht.flags);
            XSRETURN(2);
        } else {
            XSRETURN_IV((long) ht.iItem);
        }
    }

    ###########################################################################
    # (@)METHOD:InsertItem(%OPTIONS)
    # Inserts a new item in the Header control. Returns the newly created
    # item zero-based index or -1 on errors.
    # %OPTIONS can be:
    #   -index => position
    #   -image => index of an image from the associated ImageList
    #   -bitmap => Win32::GUI::Bitmap object
    #   -width => pixels
    #   -height => pixels
    #   -text => string
    #   -align => left|center|right
LRESULT
InsertItem(handle,...)
    HWND handle
PREINIT:
    HDITEM Item;
    int index;
CODE:
    ZeroMemory(&Item, sizeof(HDITEM));
    index = Header_GetItemCount(handle) + 1;
    Item.fmt = HDF_LEFT;
    SwitchBit(Item.mask, HDI_FORMAT, 1);
    ParseHeaderItemOptions(NOTXSCALL sp, mark, ax, items, 1, &Item, &index);
    RETVAL = Header_InsertItem(handle, index, &Item);
OUTPUT:
    RETVAL

    # TODO : Header_Layout

    ###########################################################################
    # (@)METHOD:OrderToIndex()
    # Retrieves an index value for an item based on its order in the Header.
int
OrderToIndex(handle,order)
    HWND handle
    int order
CODE:
    RETVAL = Header_OrderToIndex(handle,order);
OUTPUT:
    RETVAL

    # TODO : Header_SetHotDivider

    ###########################################################################
    # (@)METHOD:SetImageList(flag)
    # Assigns an image list to an Header.

HIMAGELIST 
SetImageList(handle, himl)
    HWND handle
    HIMAGELIST himl
CODE:
    RETVAL = (HIMAGELIST) Header_SetImageList(handle, himl);
OUTPUT:
    RETVAL

    ###########################################################################
    # (@)METHOD:SetItem(INDEX, %OPTIONS)
    # Set the options for an item in the Header control. Returns nonzero
    # if successful, zero otherwise.
    # For a list of the available options see InsertItem().
BOOL
SetItem(handle,index,...)
    HWND handle
    int index
PREINIT:
    HDITEM Item;
CODE:
    ZeroMemory(&Item, sizeof(HDITEM));
    ParseHeaderItemOptions(NOTXSCALL sp, mark, ax, items, 1, &Item, &index);
    RETVAL = Header_SetItem(handle, index, &Item);
OUTPUT:
    RETVAL

    ###########################################################################
    # (@)METHOD:SetOrderArray(...)
    # Sets the left-to-right order of Header items.
BOOL
SetOrderArray(handle,...)
    HWND handle
PREINIT:
    int * lpiArray;
CODE:
    lpiArray = (int *) safemalloc (items * sizeof(int));
    for (int i = 1; i < items; i++)
        lpiArray[i] = (int)SvIV(ST(i));
    RETVAL = Header_SetOrderArray(handle, items-1, &lpiArray[1]);
    safefree (lpiArray);
OUTPUT:
    RETVAL

    ###########################################################################
    # (@)METHOD:SetUnicodeFormat(flag)
    # Sets the UNICODE character format flag for the control.
BOOL
SetUnicodeFormat(handle, flag)
    HWND handle
    BOOL flag
CODE:
    RETVAL = Header_SetUnicodeFormat(handle, flag);
OUTPUT:
    RETVAL

    ###########################################################################
    ###########################################################################
    ###########################################################################

    ###########################################################################
    # (@)METHOD:ChangeItem(INDEX, %OPTIONS)
    # Changes the options for an item in the Header control. Returns nonzero
    # if successful, zero otherwise.
    # For a list of the available options see InsertItem().
BOOL
ChangeItem(handle,index,...)
    HWND handle
    int index
PREINIT:
    HDITEM Item;
CODE:
    ZeroMemory(&Item, sizeof(HDITEM));
    if(Header_GetItem(handle, index, &Item)) {
        ParseHeaderItemOptions(NOTXSCALL sp, mark, ax, items, 1, &Item, &index);
        SwitchBit(Item.mask, HDI_FORMAT, 1);
        RETVAL = Header_SetItem(handle, index, &Item);
    } else {
        RETVAL = 0;
    }
OUTPUT:
    RETVAL

    ###########################################################################
    # (@)METHOD:Clear()
    # Deletes all items from the control.

    ###########################################################################
    # (@)METHOD:Reset()
    # See Clear().
BOOL
Clear(handle)
    HWND handle
ALIAS:
    Win32::GUI::Header::Reset = 1
PREINIT:
    int i;
CODE:
    RETVAL = TRUE;
    for(i = Header_GetItemCount(handle); i > 0; i--) {
        if(!Header_DeleteItem(handle, i)) RETVAL = FALSE;
    }
OUTPUT:
    RETVAL
