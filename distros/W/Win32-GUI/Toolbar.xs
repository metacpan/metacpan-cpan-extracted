    /*
    ###########################################################################
    # (@)PACKAGE:Win32::GUI::Toolbar
    #
    # $Id: Toolbar.xs,v 1.10 2010/04/08 21:26:48 jwgui Exp $
    #
    ###########################################################################
    */

#include "GUI.h"

void 
Toolbar_onPreCreate(NOTXSPROC LPPERLWIN32GUI_CREATESTRUCT perlcs) {

    perlcs->cs.lpszClass = TOOLBARCLASSNAME;
    perlcs->cs.style = WS_VISIBLE | WS_CHILD;
}

BOOL
Toolbar_onParseOption(NOTXSPROC char *option, SV* value, LPPERLWIN32GUI_CREATESTRUCT perlcs) {

    BOOL retval = TRUE;

    if(strcmp(option, "-imagelist") == 0) {        
        perlcs->hImageList = (HIMAGELIST) handle_From(NOTXSCALL value);
    }
    else if(strcmp(option, "-tooltip") == 0) {
        perlcs->hTooltip = (HWND) handle_From(NOTXSCALL value);        
    } else if BitmaskOptionValue("-adjustable",  perlcs->cs.style, CCS_ADJUSTABLE)
    } else if BitmaskOptionValue("-altdrag",     perlcs->cs.style, TBSTYLE_ALTDRAG )
    } else if BitmaskOptionValue("-flat",        perlcs->cs.style, TBSTYLE_FLAT)
    } else if BitmaskOptionValue("-list",        perlcs->cs.style, TBSTYLE_LIST)
    } else if BitmaskOptionValue("-transparent", perlcs->cs.style, TBSTYLE_TRANSPARENT)
    } else if BitmaskOptionValue("-nodivider",   perlcs->cs.style, CCS_NODIVIDER)
    } else if BitmaskOptionValue("-multiline",   perlcs->cs.style, TBSTYLE_WRAPABLE)
    } else retval = FALSE;

    return retval;
}

void
Toolbar_onPostCreate(NOTXSPROC HWND myhandle, LPPERLWIN32GUI_CREATESTRUCT perlcs) {

    SendMessage(myhandle, TB_BUTTONSTRUCTSIZE, (WPARAM) sizeof(TBBUTTON), 0);
    if(perlcs->hImageList != NULL)
        SendMessage(myhandle, TB_SETIMAGELIST, 0, (LPARAM) perlcs->hImageList);
    if(perlcs->hTooltip != NULL)
        SendMessage(myhandle, TB_SETTOOLTIPS, (WPARAM) perlcs->hTooltip, (LPARAM) 0);
}

BOOL
Toolbar_onParseEvent(NOTXSPROC char *name, int* eventID) {

    BOOL retval = TRUE;

         if Parse_Event("ButtonClick",   PERLWIN32GUI_NEM_CONTROL1)
    else retval = FALSE;

    return retval;
}

int
Toolbar_onEvent (NOTXSPROC LPPERLWIN32GUI_USERDATA perlud, UINT uMsg, WPARAM wParam, LPARAM lParam) {

    int PerlResult = 1;

    switch (uMsg) {
    case WM_COMMAND :
        /*
         * (@)EVENT:ButtonClick(INDEX,[DROPDOWN = 1])
         * Sent when the user presses a button of the Toolbar
         * the INDEX argument identifies the zero-based index of
         * the pressed button. If the button clicked should expand a
         * dropdown menu, then there is a second argument that is
         * set to 1.
         * (@)APPLIES_TO:Toolbar
         */
        PerlResult = DoEvent(NOTXSCALL perlud, PERLWIN32GUI_NEM_CONTROL1, "ButtonClick",
            PERLWIN32GUI_ARGTYPE_LONG, (LONG) LOWORD(wParam),
            PERLWIN32GUI_ARGTYPE_LONG, 0,
            -1);

        break;

    case WM_NOTIFY :
        {        
            LPNMTOOLBAR tbn = (LPNMTOOLBAR) lParam;

            switch(tbn->hdr.code) {
            case TBN_DROPDOWN:
                PerlResult = DoEvent(NOTXSCALL perlud, PERLWIN32GUI_NEM_CONTROL1, "ButtonClick",
                    PERLWIN32GUI_ARGTYPE_LONG, (LONG) tbn->iItem,
                    PERLWIN32GUI_ARGTYPE_LONG, 1,
                    -1);
                break;
            }
        }
    }

    return PerlResult;
}

MODULE = Win32::GUI::Toolbar     PACKAGE = Win32::GUI::Toolbar

PROTOTYPES: DISABLE

#pragma message( "*** PACKAGE Win32::GUI::Toolbar..." )

    ###########################################################################
    # (@)METHOD:AddBitmap(BITMAP, NUMBUTTONS)
    # Adds a buttons-bitmap to the toolbar. BITMAP should be a handle to the
    # bitmap containing button images, and NUMBUTTONS should be a number
    # specifying the number of button images in the bitmap.
    #
    # Note that this function will CROAK an error if the toolbar already has an
    # imagelist assigned to it and will not perform the bitmap assignment, since
    # you should not use AddBitmap on a toolbar that has an imagelist assigned.
LRESULT
AddBitmap(handle,bitmap,numbuttons)
    HWND handle
    HBITMAP bitmap
    WPARAM numbuttons
PREINIT:
    TBADDBITMAP TbAddBitmap;
    HIMAGELIST imagelist;
    LPPERLWIN32GUI_USERDATA perlud;
    BOOL hasBitmaps = 0;
CODE:
    TbAddBitmap.hInst = (HINSTANCE) NULL;
    TbAddBitmap.nID = (UINT_PTR) bitmap;
    
    perlud = (LPPERLWIN32GUI_USERDATA) GetWindowLongPtr((HWND) handle, GWLP_USERDATA);
    if( ValidUserData(perlud) )  {
        hasBitmaps = (BOOL)(perlud->dwPlStyle & PERLWIN32GUI_TB_HASBITMAPS);
    }

    imagelist = (HIMAGELIST) SendMessage(handle, TB_GETIMAGELIST, 0, 0);
    if(imagelist && !hasBitmaps) {
        CROAK("AddBitmap() cannot be used when the toolbar has imagelist set");
        XSRETURN_UNDEF;
    }

    if( ValidUserData(perlud) )  {
        perlud->dwPlStyle |= PERLWIN32GUI_TB_HASBITMAPS;
    }

    RETVAL = SendMessage(handle, TB_ADDBITMAP, numbuttons,
                         (LPARAM) (LPTBADDBITMAP) &TbAddBitmap);
OUTPUT:
    RETVAL

    ###########################################################################
    # (@)METHOD:AddButtons(NUMBER, (BITMAP, COMMAND, STATE, STYLE, STRING) ...)
    # Adds buttons to the toolbar. Note that BITMAP, COMMAND, STATE, STYLE and

    # STRING are all integers. BITMAP specifies the bitmap index to use for the
    # button (see AddBitmap() or SetImageList()), COMMAND specifies the value
    # sent to the ButtonClick event when the button is clicked, STATE sets state
    # flags (see SetButtonState), STYLE sets style flags for the button (see
    # below), and STRING specifies the index of the string added by
    # SetString. You can repeat BITMAP, COMMAND, STATE, STYLE, STRING as many
    # times as you like for the number of buttons you want to add. NUMBER should
    # be set to the number of buttons you are adding.
    #
    # Button style flags (combine these with bitwise OR):
    #   BTNS_AUTOSIZE
    #       Specifies that the toolbar control should not assign the standard width to the button. Instead, the button's width will be calculated based on the width of the text plus the image of the button. Use the equivalent style flag, TBSTYLE_AUTOSIZE, for version 4.72 and earlier.
    #   BTNS_BUTTON
    #       Creates a standard button. Use the equivalent style flag, TBSTYLE_BUTTON, for version 4.72 and earlier.
    #   BTNS_CHECK
    #       Creates a dual-state push button that toggles between the pressed and nonpressed states each time the user clicks it. The button has a different background color when it is in the pressed state. Use the equivalent style flag, TBSTYLE_CHECK, for version 4.72 and earlier.
    #   BTNS_CHECKGROUP
    #       Creates a button that stays pressed until another button in the group is pressed, similar to option buttons (also known as radio buttons). It is equivalent to combining BTNS_CHECK and BTNS_GROUP. Use the equivalent style flag, TBSTYLE_CHECKGROUP, for version 4.72 and earlier.
    #   BTNS_DROPDOWN
    #       Creates a drop-down style button that can display a list when the button is clicked. Instead of the WM_COMMAND message used for normal buttons, drop-down buttons send a TBN_DROPDOWN notification. An application can then have the notification handler display a list of options. Use the equivalent style flag, TBSTYLE_DROPDOWN, for version 4.72 and earlier.
    #       If the toolbar has the TBSTYLE_EX_DRAWDDARROWS extended style, drop-down buttons will have a drop-down arrow displayed in a separate section to their right. If the arrow is clicked, a TBN_DROPDOWN notification will be sent. If the associated button is clicked, a WM_COMMAND message will be sent.
    #   BTNS_GROUP
    #       When combined with BTNS_CHECK, creates a button that stays pressed until another button in the group is pressed. Use the equivalent style flag, TBSTYLE_GROUP, for version 4.72 and earlier.
    #   BTNS_NOPREFIX
    #       Specifies that the button text will not have an accelerator prefix associated with it. Use the equivalent style flag, TBSTYLE_NOPREFIX, for version 4.72 and earlier.
    #   BTNS_SEP
    #       Creates a separator, providing a small gap between button groups. A button that has this style does not receive user input. Use the equivalent style flag, TBSTYLE_SEP, for version 4.72 and earlier.
    #   BTNS_SHOWTEXT
    #       Specifies that button text should be displayed. All buttons can have text, but only those buttons with the BTNS_SHOWTEXT button style will display it. This button style must be used with the TBSTYLE_LIST style and the TBSTYLE_EX_MIXEDBUTTONS extended style. If you set text for buttons that do not have the BTNS_SHOWTEXT style, the toolbar control will automatically display it as a ToolTip when the cursor hovers over the button. This feature allows your application to avoid handling the TBN_GETINFOTIP notification for the toolbar.
    #   BTNS_WHOLEDROPDOWN
    #       Specifies that the button will have a drop-down arrow, but not as a separate section. Buttons with this style behave the same, regardless of whether the TBSTYLE_EX_DRAWDDARROWS extended style is set.
LRESULT
AddButtons(handle,number,...)
    HWND handle
    int  number
PREINIT:
    LPTBBUTTON buttons;
    int i, q, b;
CODE:
    if(items != (2 + number * 5)) {
        CROAK("AddButtons: wrong number of parameters (expected %d, got %d)!\n", 2+number*5, items);
    }
    buttons = (LPTBBUTTON) safemalloc(sizeof(TBBUTTON)*number);
    q = 0;
    b = 0;
    for(i = 2; i < items; i++) {
        switch(q) {
        case 0:
            buttons[b].iBitmap = (int) SvIV(ST(i));
            break;
        case 1:
            buttons[b].idCommand = (int) SvIV(ST(i));
            break;
        case 2:
            buttons[b].fsState = (BYTE) SvIV(ST(i));
            break;
        case 3:
            buttons[b].fsStyle = (BYTE) SvIV(ST(i));
            break;
        case 4:
            buttons[b].iString = (int) SvIV(ST(i));
        }
        q++;
        if(q == 5) {
            buttons[b].dwData = 0;
            q = 0;
            b++;
        }
    }
    RETVAL = SendMessage(handle, TB_ADDBUTTONS,
                         (WPARAM) number,
                         (LPARAM) (LPTBBUTTON) buttons);
    safefree(buttons);
OUTPUT:
    RETVAL

    ###########################################################################
    # (@)METHOD:AddString(STRING)
LRESULT
AddString(handle,string)
    HWND handle
    char * string
PREINIT:
    char *Strings;
    STRLEN szLen, totLen;
CODE:
    totLen = 0;
    #    // the function should accept an array of strings,
    #    // but actually doesn't work...
    #
    #    for(i = 1; i < items; i++) {
    #        Strings = SvPV(ST(i), szLen);
    #        __DEBUG("AddString: szLen(%d) = %d\n", i, szLen);
    #        totLen += szLen+1;
    #    }
    #    totLen++;
    #    __DEBUG("AddString: totLen = %d\n", totLen);
    #    Strings = (char *) safemalloc(totLen);
    #
    #    totLen = 0;
    #    char *tmpStrings = Strings;
    #    for(i = 1; i < items; i++) {
    #        strcat(tmpStrings, SvPV(ST(i), szLen));
    #        totLen += szLen+1;
    #
    #    }
    #    Strings[totLen++] = '\0';
    // only one string allowed
    Strings = SvPV(ST(1), szLen);
    Strings = (char *) safemalloc(szLen+2);
    strcpy(Strings, string);
    Strings[szLen+1] = '\0';
#ifdef PERLWIN32GUI_DEBUG
        printf("XS(Toolbar::AddString): Strings='%s', len=%d\n", Strings, szLen);
#endif
    #   #ifdef PERLWIN32GUI_DEBUG
    #       for(i=0; i<=szLen+1; i++) {
    #           printf("XS(Toolbar::AddString): Strings[%d]='%d'\n", i, Strings[i]);
    #       }
    #   #endif
#ifdef PERLWIN32GUI_DEBUG
        printf("XS(Toolbar::AddString): handle=0x%x\n", handle);
        printf("XS(Toolbar::AddString): Strings=0x%x\n", Strings);
#endif
    RETVAL = SendMessage(handle, TB_ADDSTRING, 0, (LPARAM) Strings);
#ifdef PERLWIN32GUI_DEBUG
        printf("XS(Toolbar::AddString): SendMessage.result=%ld", RETVAL);
#endif
    safefree(Strings);
OUTPUT:
    RETVAL

    ###########################################################################
    # (@)METHOD:AutoSize()
    # causes the toolbar to be resized
LRESULT
AutoSize(handle)
    HWND handle
CODE:
    RETVAL = SendMessage(handle, TB_AUTOSIZE, 0, 0);
OUTPUT:
    RETVAL

    ###########################################################################
    # (@)METHOD:ButtonCount()
    # returns the number of buttons in the toolbar
LRESULT
ButtonCount(handle)
    HWND handle
CODE:
    RETVAL = SendMessage(handle, TB_BUTTONCOUNT, 0, 0);
OUTPUT:
    RETVAL

    ###########################################################################
    # (@)INTERNAL:ButtonStructSize()
    # initializes the toolbar button structure size
LRESULT
ButtonStructSize(handle)
    HWND handle
CODE:
    RETVAL = SendMessage(handle, TB_BUTTONSTRUCTSIZE, (WPARAM) sizeof(TBBUTTON), 0);
OUTPUT:
    RETVAL

    ###########################################################################
    # (@)METHOD:ChangeBitmap(BUTTON, BITMAP)
    # Changes the bitmap for a specific button. BITMAP should be a Win32::GUI::Bitmap
    # object. Will fail if toolbar currently has an imagelist assigned. Will
    # return nonzero on success, zero on failure.
LRESULT
ChangeBitmap(handle, button, bitmap)
    HWND handle
    int button
    HBITMAP bitmap
PREINIT:
    HIMAGELIST imagelist;
CODE:
    imagelist = (HIMAGELIST) SendMessage(handle, TB_GETIMAGELIST, 0, 0);
    if(imagelist != NULL) {
        CROAK("ChangeBitmap() should not be used when toolbar has imagelist set");
        XSRETURN_UNDEF;
    }
    RETVAL = SendMessage(handle, TB_CHANGEBITMAP, (WPARAM) button, (LPARAM) bitmap);
OUTPUT:
    RETVAL

    ###########################################################################
    # (@)METHOD:CheckButton(BUTTON, CHECKED)
    # Checks or unchecks a given button on the toolbar. BUTTON is the index of
    # the button to check, CHECKED is 0 to uncheck the button, 1 to check the
    # button. When a button is checked, it is displayed in the pressed state.
LRESULT
CheckButton(handle, button, checked)
    HWND handle
    int button
    BOOL checked
CODE:
    RETVAL = SendMessage(handle, TB_CHECKBUTTON, (WPARAM) button, (LPARAM) MAKELONG(checked,0));
OUTPUT:
    RETVAL

    ###########################################################################
    # (@)METHOD:CommandToIndex(COMMAND)
    # Retrieves the zero-based index for the button associated with the specified command identifier.
LRESULT
CommandToIndex(handle, value)
    HWND   handle
    WPARAM value
CODE:
    RETVAL = SendMessage(handle, TB_COMMANDTOINDEX, value, 0);
OUTPUT:
    RETVAL

    ###########################################################################
    # (@)METHOD:Customize()
    # Displays the Customize Toolbar dialog box.
LRESULT
Customize(handle)
    HWND   handle
CODE:
    RETVAL = SendMessage(handle, TB_CUSTOMIZE, 0, 0);
OUTPUT:
    RETVAL

    ###########################################################################
    # (@)METHOD:DeleteButton(BUTTON)
    # Removes a button from the toolbar. BUTTON is the index of the button to
    # remove. Returns nonzero if successful, zero on failure.
LRESULT
DeleteButton(handle, button)
    HWND handle
    int button
CODE:
    RETVAL = SendMessage(handle, TB_DELETEBUTTON, (WPARAM) button, (LPARAM) 0);
OUTPUT:
    RETVAL

    ###########################################################################
    # (@)METHOD:EnableButton(BUTTON, ENABLE)
    # Enables or disables the specified button in a toolbar. 
LRESULT
EnableButton(handle, button, enable)
    HWND handle
    int button
    BOOL enable
CODE:
    RETVAL = SendMessage(handle, TB_ENABLEBUTTON, (WPARAM) button, (LPARAM) MAKELONG(enable,0));
OUTPUT:
    RETVAL

    ###########################################################################
    # (@)METHOD:GetAnchorHighlight()
    # Retrieves the anchor highlight setting for a toolbar. 
LRESULT
GetAnchorHighlight(handle)
    HWND   handle
CODE:
    RETVAL = SendMessage(handle, TB_GETANCHORHIGHLIGHT, 0, 0);
OUTPUT:
    RETVAL

    ###########################################################################
    # (@)METHOD:GetBitmap(COMMAND)
    # Retrieves the index of the bitmap associated with the specified command identifier.
LRESULT
GetBitmap(handle, button)
    HWND  handle
    int   button
CODE:
    RETVAL = SendMessage(handle, TB_GETBITMAP, (WPARAM) button, 0);
OUTPUT:
    RETVAL

    ###########################################################################
    # (@)METHOD:GetBitmapFlags()
    # Retrieves the flags for the current bitmap. 
    # If this value is zero, the toolbar is using a small bitmap. If the TBBF_LARGE flag is set, the toolbar is using a large bitmap.
LRESULT
GetBitmapFlags(handle)
    HWND   handle
CODE:
    RETVAL = SendMessage(handle, TB_GETBITMAPFLAGS, 0, 0);
OUTPUT:
    RETVAL

    ###########################################################################
    # (@)METHOD:GetButton(BUTTON)
    # Retrieves information about the specified button in a toolbar.
    # Return an array (BITMAP, COMMAND, STATE, STYLE, STRING).
void
GetButton(handle, index)
    HWND handle
    int  index
PREINIT:
    TBBUTTON button;
PPCODE:
    ZeroMemory(&button, sizeof(TBBUTTON));
    if (SendMessage(handle, TB_GETBUTTON, (WPARAM) index, (LPARAM) &button)) {
        EXTEND(SP, 5);   
        XST_mIV(0, button.iBitmap);
        XST_mIV(1, button.idCommand);
        XST_mIV(2, button.fsState);
        XST_mIV(3, button.fsStyle);
        XST_mIV(4, button.iString);
        XSRETURN(5);
    }
    else
        XSRETURN_UNDEF;

    ###########################################################################
    # (@)METHOD:GetButtonInfo(COMMAND)
    # Retrieves information about the button associated with the specified command identifier.
void
GetButtonInfo(handle, index)
    HWND handle
    int  index
PREINIT:
    TBBUTTONINFO button;
    char Text[1024];
PPCODE:
    ZeroMemory(&button, sizeof(TBBUTTONINFO));
    ZeroMemory(Text, 1024);
    button.cbSize = sizeof(TBBUTTONINFO);
    button.dwMask = TBIF_COMMAND | TBIF_IMAGE | TBIF_LPARAM | TBIF_SIZE | TBIF_STATE | TBIF_STYLE | TBIF_TEXT;
    button.pszText = Text;
    button.cchText = 1024;
    if (SendMessage(handle, TB_GETBUTTONINFO, (WPARAM) index, (LPARAM) &button) != -1) {
        EXTEND(SP, 28);   
        XST_mPV( 0, "-command");
        XST_mIV( 1, button.idCommand);
        XST_mPV( 2, "-image");
        XST_mIV( 3, button.iImage);
        XST_mPV( 4, "-state");
        XST_mIV( 5, button.fsState);
        XST_mPV( 6, "-style");
        XST_mIV( 7, button.fsStyle);
        XST_mPV( 8, "-text");
        XST_mPV( 9, button.pszText);
        XST_mPV(10, "-width");
        XST_mIV(11, button.cx);
        XST_mPV(12, "-checked");
        XST_mIV(13, (button.fsState & TBSTATE_CHECKED)==TBSTATE_CHECKED);
        XST_mPV(14, "-ellipses");
        XST_mIV(15, (button.fsState & TBSTATE_ELLIPSES)==TBSTATE_ELLIPSES);
        XST_mPV(16, "-enabled");
        XST_mIV(17, (button.fsState & TBSTATE_ENABLED)==TBSTATE_ENABLED);
        XST_mPV(18, "-hidden");
        XST_mIV(19, (button.fsState & TBSTATE_HIDDEN)==TBSTATE_HIDDEN);
        XST_mPV(20, "-grayed");
        XST_mIV(21, (button.fsState & TBSTATE_INDETERMINATE)==TBSTATE_INDETERMINATE);
        XST_mPV(22, "-marked");
        XST_mIV(23, (button.fsState & TBSTATE_MARKED)==TBSTATE_MARKED);
        XST_mPV(24, "-pressed");
        XST_mIV(25, (button.fsState & TBSTATE_PRESSED)==TBSTATE_PRESSED);
        XST_mPV(26, "-wrap");
        XST_mIV(27, (button.fsState & TBSTATE_WRAP)==TBSTATE_WRAP);
        XSRETURN(28);
    }
    else
        XSRETURN_UNDEF;

    ###########################################################################
    # (@)METHOD:GetButtonSize()
    # Retrieves the current width and height of toolbar buttons, in pixels. 
void
GetButtonSize(handle)
    HWND   handle
PREINIT:
    LRESULT res;
PPCODE:
    res = SendMessage(handle, TB_GETBUTTONSIZE, 0, 0);
    EXTEND(SP, 2);
    XST_mIV(0, LOWORD(res));
    XST_mIV(1, HIWORD(res));    
    XSRETURN(2);

    ###########################################################################
    # (@)METHOD:GetButtonText(button)
    # Retrieves the text of a button in a toolbar. 
void
GetButtonText(handle, button)
    HWND   handle
    WPARAM button
PPCODE:
    int res = (int) SendMessage(handle, TB_GETBUTTONTEXT, button, (LPARAM) NULL);
    if (res > 0) {
        char * szString = (char *) safemalloc (res+1);
        res = (int) SendMessage(handle, TB_GETBUTTONTEXT, button, (LPARAM) szString);
        szString[res] = '\0';
        EXTEND(SP, 1);
        XST_mPV(0, szString);
        safefree(szString);
        XSRETURN(1);
    }
    else
        XSRETURN_UNDEF;

    ###########################################################################
    # (@)METHOD:GetColorScheme()
    # Retrieves Toolbar color scheme hash information.
    #  -clrBtnHighlight => COLOR
    #    the highlight color of the buttons.
    #  -clrBtnShadow => COLOR
    #    the shadow color of the buttons. 
void
GetColorScheme(handle)
    HWND handle
PREINIT:
    COLORSCHEME colorscheme;
PPCODE:
    ZeroMemory(&colorscheme, sizeof(COLORSCHEME));
    colorscheme.dwSize = sizeof(COLORSCHEME);
    if (SendMessage(handle, TB_GETCOLORSCHEME , (WPARAM) 0, (LPARAM) &colorscheme) ) {
        EXTEND(SP, 4);
        XST_mPV( 0, "-clrBtnHighlight");
        XST_mIV( 1, (LONG) colorscheme.clrBtnHighlight);
        XST_mPV( 2, "-clrBtnShadow");
        XST_mIV( 3, (LONG) colorscheme.clrBtnShadow );
        XSRETURN(4);
    }
    else {
        XSRETURN_UNDEF;
    }

    ###########################################################################
    # (@)METHOD:GetDisabledImageList()
    # Returns the handle to the disabled imagelist currently used by the toolbar,
    # or 0 if no disabled imagelist is currently assigned. Note that this
    # does not return a blessed imagelist object, just a handle.
HIMAGELIST
GetDisabledImageList(handle)
    HWND handle
CODE:
    RETVAL = (HIMAGELIST) SendMessage(handle, TB_GETDISABLEDIMAGELIST, 0, 0);
OUTPUT:
    RETVAL

    ###########################################################################
    # (@)METHOD:GetHotImageList()
    # Returns the handle to the "hot" (rollover) imagelist currently used by
    # the toolbar, or 0 if no hot imagelist is currently assigned. Note that this
    # does not return a blessed imagelist object, just a handle.
HIMAGELIST
GetHotImageList(handle)
    HWND handle
CODE:
    RETVAL = (HIMAGELIST) SendMessage(handle, TB_GETHOTIMAGELIST, 0, 0);
OUTPUT:
    RETVAL

    ###########################################################################
    # (@)METHOD:GetHotItem()
    # Retrieves the index of the hot item in a toolbar. 
LRESULT
GetHotItem(handle)
    HWND handle
CODE:
    RETVAL = SendMessage(handle, TB_GETHOTITEM, 0, 0);
OUTPUT:
    RETVAL

    ###########################################################################
    # (@)METHOD:GetImageList()
    # Returns the handle to the imagelist currently used by the toolbar, or 0
    # if no imagelist is currently assigned. Note that this does not return a
    # blessed imagelist object, just a handle.
HIMAGELIST
GetImageList(handle)
    HWND handle
CODE:
    RETVAL = (HIMAGELIST) SendMessage(handle, TB_GETIMAGELIST, 0, 0);
OUTPUT:
    RETVAL

    ###########################################################################
    # (@)METHOD:GetInsertMark()
    # Retrieves the current insertion mark for the toolbar. Return an array (BUTTON,FLAGS).
void
GetInsertMark(handle)
    HWND handle
PREINIT:
    TBINSERTMARK im;
PPCODE:
    if (SendMessage(handle, TB_GETINSERTMARK, 0, (LPARAM) &im)) {
        EXTEND(SP, 2);
        XST_mIV(0, im.iButton);
        XST_mIV(1, im.dwFlags);
        XSRETURN(2);
    }
    else
        XSRETURN_UNDEF;


    ###########################################################################
    # (@)METHOD:GetInsertMarkColor()
    # Retrieves the color used to draw the insertion mark for the toolbar. 
COLORREF
GetInsertMarkColor(handle)
    HWND   handle
CODE:
    RETVAL = (COLORREF) SendMessage(handle, TB_GETINSERTMARKCOLOR, 0, 0);
OUTPUT:
    RETVAL

    ###########################################################################
    # (@)METHOD:GetItemRect(BUTTON)
    # Retrieves the bounding rectangle of a button in a toolbar.
void
GetItemRect(handle,button)
    HWND handle
    WPARAM button
PREINIT:
    RECT myRect;
PPCODE:
    if (SendMessage(handle, TB_GETITEMRECT, button, (LPARAM) &myRect)) {
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
    # (@)METHOD:GetMaxSize()
    # (@)METHOD:MaxSize()
    # returns the total size of all the visible buttons and separators in the
    # toolbar (or undef on errors)
void
GetMaxSize(handle)
    HWND handle
ALIAS:
    Win32::GUI::Toolbar::MaxSize = 1
PREINIT:
        SIZE size;
PPCODE:
    if( SendMessage(handle, TB_GETMAXSIZE, 0, (LPARAM) &size) ) {
        EXTEND(SP, 2);
        XST_mIV(0, size.cx);
        XST_mIV(1, size.cy);
        XSRETURN(2);
    } 
    else 
        XSRETURN_UNDEF;

    # TODO ; TB_GETOBJECT

    ###########################################################################
    # (@)METHOD:GetPadding()
    # Retrieves the padding for a toolbar control. 
LRESULT
GetPadding(handle)
    HWND   handle
CODE:
    RETVAL = SendMessage(handle, TB_GETPADDING, 0, 0);
OUTPUT:
    RETVAL

    ###########################################################################
    # (@)METHOD:GetRect(BUTTON)
    # Retrieves the bounding rectangle for a specified toolbar button.
void
GetRect(handle,button)
    HWND handle
    WPARAM button
PREINIT:
    RECT myRect;
PPCODE:
    if (SendMessage(handle, TB_GETRECT, button, (LPARAM) &myRect)) {
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
    # (@)METHOD:GetRows()
    # Retrieves the number of rows of buttons in a toolbar with the TBSTYLE_WRAPABLE style.  
LRESULT
GetRows(handle)
    HWND   handle
CODE:
    RETVAL = SendMessage(handle, TB_GETROWS, 0, 0);
OUTPUT:
    RETVAL

    ###########################################################################
    # (@)METHOD:GetState(BUTTON)
    # Retrieves information about the state of the specified button in a toolbar, such as whether it is enabled, pressed, or checked.
LRESULT
GetState(handle, button)
    HWND   handle
    WPARAM button
CODE:
    RETVAL = SendMessage(handle, TB_GETSTATE, button, 0);
OUTPUT:
    RETVAL

    ###########################################################################
    # (@)METHOD:GetString(INDEX)
    # Retrieves the string from the toolbar's string pool identified by the zero based INDEX
void
GetString(handle, index)
    HWND handle
    int  index
PPCODE:
    char * szString = (char *) safemalloc (1024);
    int res = (int) SendMessage(handle, TB_GETSTRING, (WPARAM) MAKEWPARAM (1024, index), (LPARAM) (LPTSTR) (szString));
    if(res != -1) {
      szString[1024-1] = '\0';
      EXTEND(SP, 1);
      XST_mPV(0, szString);
      safefree(szString);
      XSRETURN(1);
    } else {
      safefree(szString);
      XSRETURN_UNDEF;
    }

    ###########################################################################
    # (@)METHOD:GetStyle(STYLE)
    # Gets the current style for the toolbar.
LRESULT
GetStyle(handle)
    HWND handle
CODE:
    RETVAL = SendMessage(handle, TB_GETSTYLE, (WPARAM) 0, (LPARAM) 0);
OUTPUT:
    RETVAL

    ###########################################################################
    # (@)METHOD:GetTextRows()
    # Retrieves the maximum number of text rows that can be displayed on a toolbar button.
LRESULT
GetTextRows(handle)
    HWND   handle
CODE:
    RETVAL = SendMessage(handle, TB_GETTEXTROWS, 0, 0);
OUTPUT:
    RETVAL

    ###########################################################################
    # (@)METHOD:GetTooltips()
    # Retrieves the handle to the tooltip control, if any, associated with the toolbar. 
HWND
GetTooltips(handle)
    HWND   handle
CODE:
    RETVAL = (HWND) SendMessage(handle, TB_GETTOOLTIPS, 0, 0);
OUTPUT:
    RETVAL

    ###########################################################################
    # (@)METHOD:GetUnicodeFormat()
    # Retrieves the UNICODE character format flag for the control. 
BOOL
GetUnicodeFormat(handle)
    HWND   handle
CODE:
    RETVAL = (BOOL) SendMessage(handle, TB_GETUNICODEFORMAT, 0, 0);
OUTPUT:
    RETVAL

    ###########################################################################
    # (@)METHOD:HideButton(BUTTON, SHOW)
    # Hides or shows the specified button in a toolbar. 
LRESULT
HideButton(handle, button, flag)
    HWND handle
    int button
    BOOL flag
CODE:
    RETVAL = SendMessage(handle, TB_HIDEBUTTON, (WPARAM) button, (LPARAM) MAKELONG(flag,0));
OUTPUT:
    RETVAL

    ###########################################################################
    # (@)METHOD:HitTest(X, Y)
    # Determines where a point lies in a toolbar control. 
BOOL
HitTest(handle,x,y)
    HWND handle
    LONG x
    LONG y
PREINIT:
    POINT pt;
CODE:
    pt.x = x; pt.y = y;
    RETVAL = SendMessage(handle, TB_HITTEST, 0, (LPARAM) &pt);
OUTPUT:
    RETVAL

    ###########################################################################
    # (@)METHOD:Indeterminate(BUTTON, FLAG)
    # Sets or clears the indeterminate state of the specified button in a toolbar. 
LRESULT
Indeterminate(handle, button, flag)
    HWND handle
    int button
    BOOL flag
CODE:
    RETVAL = SendMessage(handle, TB_INDETERMINATE, (WPARAM) button, (LPARAM) MAKELONG(flag,0));
OUTPUT:
    RETVAL

    ###########################################################################
    # (@)METHOD:InsertButton(BUTTON, BITMAP, COMMAND, STATE, STYLE, ISTRING)     
    # Insert a new button.
LRESULT
InsertButton(handle,number,iBitmap,idCommand,fsState,fsStyle,iString)
    HWND handle
    int  number
    int  iBitmap
    int  idCommand
    int  fsState
    int  fsStyle
    int  iString
PREINIT:
    TBBUTTON button;
CODE:
    button.iBitmap   = iBitmap;
    button.idCommand = idCommand;
    button.fsState   = fsState;
    button.fsStyle   = fsStyle;    
    button.iString   = iString;
    button.dwData    = 0;

    RETVAL = SendMessage(handle, TB_INSERTBUTTON, (WPARAM) number, (LPARAM) &button);
OUTPUT:
    RETVAL

    ###########################################################################
    # (@)METHOD:InsertMarkHitTest(X,Y)
    # Retrieves the insertion mark information for a point in a toolbar.
    # If (X,Y) point is an insertion mark, return an array (BUTTON,FLAGS).
void
InsertMarkHitTest(handle,x,y)
    HWND handle
    int x
    int y
PREINIT:
    POINT pt;
    TBINSERTMARK im;
PPCODE:
    pt.x = x; pt.y = y;
    if (SendMessage(handle, TB_INSERTMARKHITTEST, (WPARAM) &pt, (LPARAM) &im)) {
        EXTEND(SP, 2);
        XST_mIV(0, im.iButton);
        XST_mIV(1, im.dwFlags);
        XSRETURN(2);
    }
    else
        XSRETURN_UNDEF;

    ###########################################################################
    # (@)METHOD:IsButtonChecked(BUTTON)
    # Determines whether the specified button in a toolbar is checked. 
LRESULT
IsButtonChecked(handle, button)
    HWND handle
    int button
CODE:
    RETVAL = SendMessage(handle, TB_ISBUTTONCHECKED, (WPARAM) button, 0);
OUTPUT:
    RETVAL

    ###########################################################################
    # (@)METHOD:IsButtonEnabled(BUTTON)
    # Determines whether the specified button in a toolbar is enabled.  
LRESULT
IsButtonEnabled(handle, button)
    HWND handle
    int button
CODE:
    RETVAL = SendMessage(handle, TB_ISBUTTONENABLED, (WPARAM) button, 0);
OUTPUT:
    RETVAL

    ###########################################################################
    # (@)METHOD:IsButtonHidden(BUTTON)
    # Determines whether the specified button in a toolbar is hidden.
LRESULT
IsButtonHidden(handle, button)
    HWND handle
    int button
CODE:
    RETVAL = SendMessage(handle, TB_ISBUTTONHIDDEN, (WPARAM) button, 0);
OUTPUT:
    RETVAL

    ###########################################################################
    # (@)METHOD:IsButtonHighlighted(BUTTON)
    # Determines whether the specified button in a toolbar is highlighted.
LRESULT
IsButtonHighlighted(handle, button)
    HWND handle
    int button
CODE:
    RETVAL = SendMessage(handle, TB_ISBUTTONHIGHLIGHTED, (WPARAM) button, 0);
OUTPUT:
    RETVAL

    ###########################################################################
    # (@)METHOD:IsButtonIndeterminate(BUTTON)
    # Determines whether the specified button in a toolbar is indeterminate.
LRESULT
IsButtonIndeterminate(handle, button)
    HWND handle
    int button
CODE:
    RETVAL = SendMessage(handle, TB_ISBUTTONINDETERMINATE, (WPARAM) button, 0);
OUTPUT:
    RETVAL

    ###########################################################################
    # (@)METHOD:IsButtonPressed(BUTTON)
    # Determines whether the specified button in a toolbar is pressed. 
LRESULT
IsButtonPressed(handle, button)
    HWND handle
    int button
CODE:
    RETVAL = SendMessage(handle, TB_ISBUTTONPRESSED, (WPARAM) button, 0);
OUTPUT:
    RETVAL

    ###########################################################################
    # (@)METHOD:LoadImages([IDBITMAP=IDB_HIST_LARGE_COLOR],[HINSTANCE=HINST_COMMCTRL])
    # Loads bitmaps into a toolbar control's image list.  
    # 
    # IDBITMAP when HINSTANCE == HINST_COMMCTRL,
    #   IDB_HIST_LARGE_COLOR = Explorer bitmaps in large size. 
    #   IDB_HIST_SMALL_COLOR = Explorer bitmaps in small size.  
    #   IDB_STD_LARGE_COLOR  = Standard bitmaps in large size.  
    #   IDB_STD_SMALL_COLOR  = Standard bitmaps in small size. 
    #   IDB_VIEW_LARGE_COLOR = View bitmaps in large size. 
    #   IDB_VIEW_SMALL_COLOR = View bitmaps in small size.  
    #
LRESULT
LoadImages(handle, bitmap=IDB_HIST_LARGE_COLOR, hinst=HINST_COMMCTRL)
    HWND handle
    int bitmap
    HINSTANCE hinst
CODE:
    RETVAL = SendMessage(handle, TB_LOADIMAGES, (WPARAM) bitmap, (LPARAM) hinst);
OUTPUT:
    RETVAL

    ###########################################################################
    # (@)METHOD:MapAccelerator(CHARACTER)
    # Maps an accelerator character to a toolbar button. 
void
MapAccelerator(handle, acc)
    HWND   handle
    WPARAM acc
PREINIT:
    int button;
PPCODE:
    if(SendMessage(handle, TB_MAPACCELERATOR, acc, (LPARAM) &button)) {
        EXTEND(SP, 1);
        XST_mIV(0, button);
        XSRETURN(1);        
    }
    else
        XSRETURN_UNDEF;

    ###########################################################################
    # (@)METHOD:MarkButton(BUTTON, FLAG)
    # Sets the highlight state of a given button in a toolbar control.  
LRESULT
MarkButton(handle, button, flag)
    HWND handle
    int button
    BOOL flag
CODE:
    RETVAL = SendMessage(handle, TB_MARKBUTTON, (WPARAM) button, (LPARAM) MAKELONG(flag,0));
OUTPUT:
    RETVAL

    ###########################################################################
    # (@)METHOD:MoveButton(BUTTON, TARGET)
    # Moves the button specified by BUTTON to the new position TARGET. Returns
    # non-zero if successful, or zero on failure.
LRESULT
MoveButton(handle, oldbutton, newbutton)
    HWND handle
    int oldbutton
    int newbutton
CODE:
    RETVAL = SendMessage(handle, TB_MOVEBUTTON, oldbutton, newbutton);
OUTPUT:
    RETVAL

    ###########################################################################
    # (@)METHOD:PressButton(BUTTON, FLAG)
    # Presses or releases the specified button in a toolbar.  
LRESULT
PressButton(handle, button, flag)
    HWND handle
    int button
    BOOL flag
CODE:
    RETVAL = SendMessage(handle, TB_PRESSBUTTON, (WPARAM) button, (LPARAM) MAKELONG(flag,0));
OUTPUT:
    RETVAL

    # TODO : TBREPLACEBITMAP

    ###########################################################################
    # (@)METHOD:SaveRestore(FLAG, SUBKEY, VALUENAME)
    # Saves or restores the state of the toolbar in registry (Use HKEY_CURRENT_USER).  
    #
    # B<FLAG> : 
    #   Save or restore flag. If this parameter is TRUE, the information is saved. If it is FALSE, it is restored. 
    # B<SUBKEY> : 
    #   Subkey registry name.
    # B<VALUENAME> : 
    #   Value registry name. 

LRESULT
SaveRestore(handle, flag, SubKey, ValueName)
    HWND handle
    BOOL flag
    LPCTSTR SubKey 
    LPCTSTR ValueName
PREINIT:
    TBSAVEPARAMS tbsp;
CODE:
    tbsp.hkr = HKEY_CURRENT_USER;
    tbsp.pszSubKey    = SubKey;
    tbsp.pszValueName = ValueName;
    RETVAL = SendMessage(handle, TB_SAVERESTORE, (WPARAM) flag, (LPARAM) &tbsp);
OUTPUT:
    RETVAL

    ###########################################################################
    # (@)METHOD:SetAnchorHighlight(FLAG)
    # Determines whether the specified button in a toolbar is pressed. 
LRESULT
SetAnchorHighlight(handle, flag)
    HWND handle
    BOOL flag
CODE:
    RETVAL = SendMessage(handle, TB_SETANCHORHIGHLIGHT, (WPARAM) flag, 0);
OUTPUT:
    RETVAL

    ###########################################################################
    # (@)METHOD:SetBitmapSize([X=16, Y=15])
    # Sets the size of the bitmapped images to be added to a toolbar.
    # The size can be set only before adding any bitmaps to the toolbar.
    # If an application does not explicitly set the bitmap size, the size defaults to 16 by 15 pixels. 
LRESULT
SetBitmapSize(handle, x=16, y=15)
    HWND handle
    int x
    int y
CODE:
    RETVAL = SendMessage(handle, TB_SETBITMAPSIZE, 0, (LPARAM) MAKELONG (x, y));
OUTPUT:
    RETVAL

    ###########################################################################
    # (@)METHOD:SetButtonInfo(COMMAND, %OPTIONS)
    # Sets the information for the button associated with the specified command identifier.
    #
    # B<%OPTIONS> :
    #  -command => ID
    #     Command identifier of the button.
    #  -image => INDEX
    #     Image index of the button
    #  -state => STATE
    #     State flags of the button. You can also use : 
    #     -checked => 0/1
    #     -ellipses => 0/1
    #     -enabled => 0/1
    #     -hidden => 0/1
    #     -grayed => 0/1
    #     -marked => 0/1
    #     -pressed => 0/1
    #     -wrapped => 0/1
    #  -style => STYLE
    #     Style flags of the button. You can also use : 
    #     -autosize => 0/1
    #     -check => 0/1
    #     -checkgroup => 0/1
    #     -dropdown => 0/1
    #     -group => 0/1
    #     -noprefix => 0/1
    #     -separator => 0/1
    #  -width => WIDTH
    #     Width of the button, in pixels. 
    #  -text => STRING
    #     Text of the button.

LRESULT
SetButtonInfo(handle, index, ...)
    HWND handle
    int  index
PREINIT:
    TBBUTTONINFO button;
    int i, next_i;
    char * option;
    STRLEN tlen;
CODE:
    ZeroMemory(&button, sizeof(TBBUTTONINFO));
    button.cbSize = sizeof(TBBUTTONINFO);
    next_i = -1;
    for(i = 2; i < items; i++) {
        if(next_i == -1) {
            option = SvPV_nolen(ST(i));
            if(strcmp(option, "-command") == 0) {
                next_i = i + 1;
                button.idCommand = (int)SvIV(ST(next_i));
                button.dwMask |= TBIF_COMMAND;
            } else if (strcmp(option, "-image") == 0) {
                next_i = i + 1;
                button.iImage = (int)SvIV(ST(next_i));
                button.dwMask |= TBIF_IMAGE;
            } else if (strcmp(option, "-state") == 0) {
                next_i = i + 1;
                button.fsState = (BYTE) SvIV(ST(next_i));
                button.dwMask |= TBIF_STATE;
            } else if (strcmp(option, "-style") == 0) {
                next_i = i + 1;
                button.fsStyle = (BYTE) SvIV(ST(next_i));
                button.dwMask |= TBIF_STYLE;
            } else if (strcmp(option, "-width") == 0) {
                next_i = i + 1;
                button.cx = (WORD) SvIV(ST(next_i));
                button.dwMask |= TBIF_SIZE;
            } else if (strcmp(option, "-text") == 0) {
                next_i = i + 1;
                button.pszText = SvPV(ST(next_i), tlen);
                button.cchText = tlen;
                button.dwMask |= TBIF_TEXT;
            } else if (strcmp(option, "-checked") == 0) {
                next_i = i + 1;
                SwitchBit(button.fsState, TBSTATE_CHECKED, SvIV(ST(next_i)));
                button.dwMask |= TBIF_STATE;
            } else if (strcmp(option, "-ellipses") == 0) {
                next_i = i + 1;
                SwitchBit(button.fsState, TBSTATE_ELLIPSES, SvIV(ST(next_i)));
                button.dwMask |= TBIF_STATE;
            } else if (strcmp(option, "-enabled") == 0) {
                next_i = i + 1;
                SwitchBit(button.fsState, TBSTATE_ENABLED, SvIV(ST(next_i)));
                button.dwMask |= TBIF_STATE;
            } else if (strcmp(option, "-hidden") == 0) {
                next_i = i + 1;
                SwitchBit(button.fsState, TBSTATE_HIDDEN, SvIV(ST(next_i)));
                button.dwMask |= TBIF_STATE;
            } else if (strcmp(option, "-grayed") == 0) {
                next_i = i + 1;
                SwitchBit(button.fsState, TBSTATE_INDETERMINATE, SvIV(ST(next_i)));
                button.dwMask |= TBIF_STATE;
            } else if (strcmp(option, "-marked") == 0) {
                next_i = i + 1;
                SwitchBit(button.fsState, TBSTATE_MARKED, SvIV(ST(next_i)));
                button.dwMask |= TBIF_STATE;
            } else if (strcmp(option, "-pressed") == 0) {
                next_i = i + 1;
                SwitchBit(button.fsState, TBSTATE_PRESSED, SvIV(ST(next_i)));
                button.dwMask |= TBIF_STATE;
            } else if (strcmp(option, "-wrapped") == 0) {
                next_i = i + 1;
                SwitchBit(button.fsState, TBSTATE_WRAP, SvIV(ST(next_i)));
                button.dwMask |= TBIF_STATE;
            } else if (strcmp(option, "-autosize") == 0) {
                next_i = i + 1;
                SwitchBit(button.fsStyle, TBSTYLE_AUTOSIZE, SvIV(ST(next_i)));
                button.dwMask |= TBIF_STYLE;
            } else if (strcmp(option, "-check") == 0) {
                next_i = i + 1;
                SwitchBit(button.fsStyle, TBSTYLE_CHECK, SvIV(ST(next_i)));
                button.dwMask |= TBIF_STYLE;
            } else if (strcmp(option, "-checkgroup") == 0) {
                next_i = i + 1;
                SwitchBit(button.fsStyle, TBSTYLE_CHECKGROUP, SvIV(ST(next_i)));
                button.dwMask |= TBIF_STYLE;
            } else if (strcmp(option, "-dropdown") == 0) {
                next_i = i + 1;
                SwitchBit(button.fsStyle, TBSTYLE_DROPDOWN, SvIV(ST(next_i)));
                button.dwMask |= TBIF_STYLE;
            } else if (strcmp(option, "-group") == 0) {
                next_i = i + 1;
                SwitchBit(button.fsStyle, TBSTYLE_GROUP, SvIV(ST(next_i)));
                button.dwMask |= TBIF_STYLE;
            } else if (strcmp(option, "-noprefix") == 0) {
                next_i = i + 1;
                SwitchBit(button.fsStyle, TBSTYLE_NOPREFIX, SvIV(ST(next_i)));
                button.dwMask |= TBIF_STYLE;
            } else if (strcmp(option, "-separator") == 0) {
                next_i = i + 1;
                SwitchBit(button.fsStyle, TBSTYLE_SEP , SvIV(ST(next_i)));
                button.dwMask |= TBIF_STYLE;
            }
        } else {
            next_i = -1;
        }
    }

    RETVAL = SendMessage(handle, TB_SETBUTTONINFO, (WPARAM) index, (LPARAM) &button);
OUTPUT:
    RETVAL

    ###########################################################################
    # (@)METHOD:SetButtonSize([X=24, Y=22])
    # Sets the size of the buttons to be added to a toolbar.
    # The size can be set only before adding any bitmaps to the toolbar.
    # If an application does not explicitly set the buttons size, the size defaults to 24 by 22 pixels. 
LRESULT
SetButtonSize(handle, x=24, y=22)
    HWND handle
    int x
    int y
CODE:
    RETVAL = SendMessage(handle, TB_SETBUTTONSIZE, 0, (LPARAM) MAKELONG (x, y));
OUTPUT:
    RETVAL

    ###########################################################################
    # (@)METHOD:SetButtonWidth(XMIN, XMAX)
    # Sets the minimum and maximum button widths in the toolbar control. 
LRESULT
SetButtonWidth(handle, x, y)
    HWND handle
    int x
    int y
CODE:
    RETVAL = SendMessage(handle, TB_SETBUTTONWIDTH, 0, (LPARAM) MAKELONG (x, y));
OUTPUT:
    RETVAL

    ###########################################################################
    # (@)METHOD:SetCmdId(BUTTON, CMD)
    # Sets the command identifier of a toolbar button.
LRESULT
SetCmdId(handle, button, cmd)
    HWND handle
    UINT button
    UINT cmd
CODE:
    RETVAL = SendMessage(handle, TB_SETCMDID, (WPARAM) button, (LPARAM) cmd);
OUTPUT:
    RETVAL

    ###########################################################################
    # (@)METHOD:SetColorScheme(%OPTIONS)
    # Sets Toolbar color scheme.
    #
    # B<%OPTIONS> :
    #  -clrBtnHighlight => COLOR.
    #     the highlight color of the buttons. 
    #  -clrBtnShadow => COLOR.
    #     the shadow color of the buttons. 
LRESULT
SetColorScheme(handle,...)
    HWND handle
PREINIT:
    COLORSCHEME colorscheme;
    int i, next_i;
CODE:
    ZeroMemory(&colorscheme, sizeof(COLORSCHEME));
    colorscheme.dwSize = sizeof(COLORSCHEME);
    next_i = -1;
    for(i = 1; i < items; i++) {
        if(next_i == -1) {
            if(strcmp(SvPV_nolen(ST(i)), "-clrBtnHighlight") == 0) {
                next_i = i + 1;
                colorscheme.clrBtnHighlight = SvCOLORREF(NOTXSCALL ST(next_i));
            }
            else if(strcmp(SvPV_nolen(ST(i)), "-clrBtnShadow") == 0) {
                next_i = i + 1;
                colorscheme.clrBtnShadow = SvCOLORREF(NOTXSCALL ST(next_i));
            }
        } else {
            next_i = -1;
        }
    }
    RETVAL = SendMessage(handle, TB_SETCOLORSCHEME, (WPARAM) 0, (LPARAM) &colorscheme);
OUTPUT:
    RETVAL

    ###########################################################################
    # (@)METHOD:SetDisabledImageList(IMAGELIST)
    # Sets the image list for disabled button images. Returns a handle
    # to the previous disabled imagelist associated with the toolbar.
LRESULT
SetDisabledImageList(handle, imagelist)
    HWND handle
    HIMAGELIST imagelist
CODE:
    RETVAL = SendMessage(handle, TB_SETDISABLEDIMAGELIST, (WPARAM) 0, (LPARAM) imagelist);
OUTPUT:
    RETVAL

    ###########################################################################
    # (@)METHOD:SetDrawTextFlags(MASK, FLAG)
    # Sets the text drawing flags for the toolbar. 
LRESULT
SetDrawTextFlags(handle, mask, flag)
    HWND handle
    UINT mask
    UINT flag
CODE:
    RETVAL = SendMessage(handle, TB_SETDRAWTEXTFLAGS, (WPARAM) mask, (LPARAM) flag);
OUTPUT:
    RETVAL

    ###########################################################################
    # (@)METHOD:SetExtendedStyle(STYLE)
    # Sets the extended style for the toolbar. STYLE should be one or more
    # style flags bitwise-ORed together.
    #
    # Extended style flag constants are as follows:
    #
    #  TBSTYLE_EX_DRAWDDARROWS
    #    This style allows buttons to have a separate dropdown arrow. Buttons
    #    that have the BTNS_DROPDOWN style will be drawn with a drop-down
    #    arrow in a separate section, to the right of the button. If the
    #    arrow is clicked, only the arrow portion of the button will depress,
    #    and the toolbar control will send a TBN_DROPDOWN notification to
    #    prompt the application to display the dropdown menu. If the main
    #    part of the button is clicked, the toolbar control sends a
    #    WM_COMMAND message with the button's ID. The application normally
    #    responds by launching the first command on the menu.
    #
    #    There are many situations where you may want to have only some of the
    #    dropdown buttons on a toolbar with separated arrows. To do so, set the
    #    TBSTYLE_EX_DRAWDDARROWS extended style. Give those buttons that will
    #    not have separated arrows the BTNS_WHOLEDROPDOWN style. Buttons with
    #    this style will have an arrow displayed next to the image. However, the
    #    arrow will not be separate and when any part of the button is clicked,
    #    the toolbar control will send a TBN_DROPDOWN notification. To prevent
    #    repainting problems, this style should be set before the toolbar control
    #    becomes visible.
    #
    #  TBSTYLE_EX_HIDECLIPPEDBUTTONS
    #    This style hides partially clipped buttons. The most common use of this
    #    style is for toolbars that are part of a rebar control. If an adjacent
    #    band covers part of a button, the button will not be displayed. However,
    #    if the rebar band has the RBBS_USECHEVRON style, the button will be
    #    displayed on the chevron's dropdown menu.
    #
    #  TBSTYLE_EX_MIXEDBUTTONS
    #    This style allows you to set text for all buttons, but only display it
    #    for those buttons with the BTNS_SHOWTEXT button style. The TBSTYLE_LIST
    #    style must also be set. Normally, when a button does not display text,
    #    your application must handle TBN_GETINFOTIP to display a ToolTip. With
    #    the TBSTYLE_EX_MIXEDBUTTONS extended style, text that is set but not
    #    displayed on a button will automatically be used as the button's ToolTip
    #    text. Your application only needs to handle TBN_GETINFOTIP if it needs
    #    more flexibility in specifying the ToolTip text.
LRESULT
SetExtendedStyle(handle, style)
    HWND handle
    DWORD style
CODE:
    RETVAL = SendMessage(handle, TB_SETEXTENDEDSTYLE, (WPARAM) 0,(LPARAM) style);
OUTPUT:
    RETVAL

    ###########################################################################
    # (@)METHOD:SetHotImageList(IMAGELIST)
    # Sets the image list for "hot" (rollover) button images. Returns a handle
    # to the previous hot image list associated with the toolbar.
    #
    # Toolbars must have the TBSTYLE_FLAT or TBSTYLE_LIST style to have
    # hot items.
    #
    # see also Win32::GUI::Toolbar::SetStyle
LRESULT
SetHotImageList(handle, hotimagelist)
    HWND handle
    HIMAGELIST hotimagelist
CODE:
    RETVAL = SendMessage(handle, TB_SETHOTIMAGELIST, (WPARAM) 0, (LPARAM) hotimagelist);
OUTPUT:
    RETVAL

    ###########################################################################
    # (@)METHOD:SetHotItem(BUTTON)
    # Sets the hot item in a toolbar. This message is ignored for toolbar controls that do not have the TBSTYLE_FLAT style.
LRESULT
SetHotItem(handle, button)
    HWND handle
    UINT button
CODE:
    RETVAL = SendMessage(handle, TB_SETHOTITEM, (WPARAM) button, 0);
OUTPUT:
    RETVAL

    ###########################################################################
    # (@)METHOD:SetImageList(IMAGELIST)
    # Sets the image list for regular button images. Returns a handle
    # to the previous image list associated with the toolbar. Note that this
    # will CROAK an error if you have previously called AddBitmap() on the
    # toolbar - you cannot use SetImageList and AddBitmap on the same toolbar.
LRESULT
SetImageList(handle, imagelist)
    HWND handle
    HIMAGELIST imagelist
PREINIT:
    LPPERLWIN32GUI_USERDATA perlud;
CODE:
    perlud = (LPPERLWIN32GUI_USERDATA) GetWindowLongPtr((HWND) handle, GWLP_USERDATA);
    if(perlud->dwPlStyle & PERLWIN32GUI_TB_HASBITMAPS) {
        CROAK("Cannot add imagelist to a toolbar that has already had AddBitmap() called");
        XSRETURN_UNDEF;
    }
    RETVAL = SendMessage(handle, TB_SETIMAGELIST, (WPARAM) 0, (LPARAM) imagelist);
OUTPUT:
    RETVAL

    ###########################################################################
    # (@)METHOD:SetIndent(VALUE)
    # (@)METHOD:Indent(VALUE)
    # sets the indentation value for the toolbar
LRESULT
SetIndent(handle,value)
    HWND handle
    int value
ALIAS:
    Win32::GUI::Toolbar::Indent = 1
CODE:
    RETVAL = SendMessage(handle, TB_SETINDENT, (WPARAM) value, 0);
OUTPUT:
    RETVAL

    ###########################################################################
    # (@)METHOD:SetInsertMark(BUTTON,[FLAG=0])
    # Sets the current insertion mark for the toolbar.
LRESULT
SetInsertMark(handle, iButton, dwFlags=0)
    HWND handle
    int iButton
    int dwFlags
PREINIT:
    TBINSERTMARK im;
CODE:
    im.iButton = iButton;
    im.dwFlags = dwFlags;
    RETVAL = SendMessage(handle, TB_SETINSERTMARK, 0, (LPARAM) &im);
OUTPUT:
    RETVAL

    ###########################################################################
    # (@)METHOD:SetInsertMarkColor(COLOR)
    # sets the indentation value for the toolbar
COLORREF
SetInsertMarkColor(handle,color)
    HWND handle
    COLORREF color
CODE:
    RETVAL = (COLORREF) SendMessage(handle, TB_SETINSERTMARKCOLOR, 0, (LPARAM) color);
OUTPUT:
    RETVAL

    ###########################################################################
    # (@)METHOD:SetMaxTextRows(VALUE)
    # Sets the maximum number of text rows displayed on a toolbar button.
LRESULT
SetMaxTextRows(handle,value)
    HWND handle
    int value
CODE:
    RETVAL = SendMessage(handle, TB_SETMAXTEXTROWS, (WPARAM) value, 0);
OUTPUT:
    RETVAL

    ###########################################################################
    # (@)METHOD:SetPadding(CX,CY)
    # Sets the padding for a toolbar control. 
LRESULT
SetPadding(handle,cx,cy)
    HWND handle
    int cx
    int cy
CODE:
    RETVAL = SendMessage(handle, TB_SETPADDING, 0, MAKELPARAM(cx, cy));
OUTPUT:
    RETVAL

    ###########################################################################
    # (@)METHOD:SetParent(PARENT)
    # Sets the window to which the toolbar control sends notification messages.  
LRESULT
SetParent(handle,parent)
    HWND handle
    HWND parent
CODE:
    RETVAL = SendMessage(handle, TB_SETPARENT, (WPARAM) parent, 0);
OUTPUT:
    RETVAL

    ###########################################################################
    # (@)METHOD:SetRows(ROWS,[FLAG=TRUE])
    # Sets the number of rows of buttons in a toolbar. 
    # Flag that indicates whether to create more rows than requested when the system cannot create the number of rows specified.
    # Return the bounding rectangle of the toolbar after the rows are set. 
void
SetRows(handle,rows,flag=TRUE)
    HWND handle
    UINT rows
    BOOL flag
PREINIT:
    RECT myRect;
PPCODE:
    SendMessage(handle, TB_SETROWS, (WPARAM) MAKEWPARAM(rows, flag), (LPARAM) &myRect);
    EXTEND(SP, 4);
    XST_mIV(0, myRect.left);
    XST_mIV(1, myRect.top);
    XST_mIV(2, myRect.right);
    XST_mIV(3, myRect.bottom);
    XSRETURN(4);

    ###########################################################################
    # (@)METHOD:SetButtonState(BUTTON, STATE)
    # Sets the state for the specified toolbar button. STATE should be one or
    # more state flags bitwise-ORed together.
    #
    # State flag constants are as follows:
    #   TBSTATE_CHECKED
    #       The button has the TBSTYLE_CHECK style and is being clicked.
    #   TBSTATE_ELLIPSES
    #       The button's text is cut off and an ellipsis is displayed.
    #   TBSTATE_ENABLED
    #       The button accepts user input. A button that doesn't have this state is grayed.
    #   TBSTATE_HIDDEN
    #       The button is not visible and cannot receive user input.
    #   TBSTATE_INDETERMINATE
    #       The button is grayed.
    #   TBSTATE_MARKED
    #       The button is marked. The interpretation of a marked item is dependent upon the application.
    #   TBSTATE_PRESSED
    #       The button is being clicked.
    #   TBSTATE_WRAP
    #       The button is followed by a line break. The button must also have the TBSTATE_ENABLED state.
LRESULT
SetButtonState(handle, button, state)
    HWND handle
    int button
    int state
CODE:
    RETVAL = SendMessage(handle, TB_SETSTATE, (WPARAM) button, (LPARAM) MAKELONG (state, 0));
OUTPUT:
    RETVAL

    ###########################################################################
    # (@)METHOD:SetStyle(STYLE)
    # Sets the style for the toolbar. STYLE should be one or more style flags
    # bitwise-ORed together.
    #
    # Style flag constants are as follows:
    #
    #   TBSTYLE_ALTDRAG
    #       Allows users to change a toolbar button's position by dragging it
    #       while holding down the ALT key. If this style is not specified, the
    #       user must hold down the SHIFT key while dragging a button. Note that
    #       the CCS_ADJUSTABLE style must be specified to enable toolbar buttons
    #       to be dragged.
    #   TBSTYLE_CUSTOMERASE
    #       Generates NM_CUSTOMDRAW notification messages when the toolbar
    #       processes WM_ERASEBKGND messages.
    #   TBSTYLE_FLAT
    #       Creates a flat toolbar. In a flat toolbar, both the toolbar and the
    #       buttons are transparent and hot-tracking is enabled. Button text
    #       appears under button bitmaps. To prevent repainting problems, this
    #       style should be set before the toolbar control becomes visible.
    #   TBSTYLE_LIST
    #       Creates a flat toolbar with button text to the right of the bitmap.
    #       Otherwise, this style is identical to TBSTYLE_FLAT. To prevent
    #       repainting problems, this style should be set before the toolbar
    #       control becomes visible.
    #   TBSTYLE_REGISTERDROP
    #       Generates TBN_GETOBJECT notification messages to request drop
    #       target objects when the cursor passes over toolbar buttons.
    #   TBSTYLE_TOOLTIPS
    #       Creates a ToolTip control that an application can use to display
    #       descriptive text for the buttons in the toolbar.
    #   TBSTYLE_TRANSPARENT
    #       Creates a transparent toolbar. In a transparent toolbar, the toolbar
    #       is transparent but the buttons are not. Button text appears under
    #       button bitmaps. To prevent repainting problems, this style should
    #       be set before the toolbar control becomes visible.
    #   TBSTYLE_WRAPABLE
    #       Creates a toolbar that can have multiple lines of buttons. Toolbar
    #       buttons can "wrap" to the next line when the toolbar becomes too
    #       narrow to include all buttons on the same line. When the toolbar is
    #       wrapped, the break will occur on either the rightmost separator or
    #       the rightmost button if there are no separators on the bar. This
    #       style must be set to display a vertical toolbar control when the
    #       toolbar is part of a vertical rebar control.
LRESULT
SetStyle(handle, style)
    HWND handle
    DWORD style
CODE:
    RETVAL = SendMessage(handle, TB_SETSTYLE, (WPARAM) 0,(LPARAM) style);
OUTPUT:
    RETVAL

    ###########################################################################
    # (@)METHOD:SetToolTips(TOOLTIP)
    # Sets the tooltip object for the toolbar. TOOLTIP should be a Win32::GUI::Tooltip
    # object. Note that this should be called before adding buttons, otherwise
    # tooltips will not be registered. You can set a tooltips object for the
    # toolbar on creation with the -tooltip option.
LRESULT
SetToolTips(handle, tooltips)
    HWND handle
    HWND tooltips
CODE:
    RETVAL = SendMessage(handle, TB_SETTOOLTIPS, (WPARAM) tooltips, (LPARAM) 0);
OUTPUT:
    RETVAL


    ###########################################################################
    # (@)METHOD:SetUnicodeFormat(FLAG)
    # Sets the UNICODE character format flag for the control. 
LRESULT
SetUnicodeFormat(handle, flag)
    HWND handle
    BOOL flag
CODE:
    RETVAL = SendMessage(handle, TB_SETUNICODEFORMAT, (WPARAM) flag, (LPARAM) 0);
OUTPUT:
    RETVAL

    ###########################################################################
    ###########################################################################
    ###########################################################################

    ###########################################################################
    # (@)METHOD:Padding([X], [Y])
    # gets or sets the padding for the toolbar;
    # if no value is passed, returns a list containing the current x and y
    # padding value, in pixels.
void
Padding(handle,x=-1,y=-1)
    HWND handle
    int x
    int y
PREINIT:
        LRESULT pad;
PPCODE:
    if(items == 1) {
        pad = SendMessage(handle, TB_GETPADDING, 0, 0);
        EXTEND(SP, 2);
        XST_mIV(0, LOWORD(pad));
        XST_mIV(1, HIWORD(pad));
        XSRETURN(2);
    } else {
        if(items == 2) y = x;
        XSRETURN_IV( SendMessage(handle, TB_SETPADDING, 0, MAKELPARAM(x, y)) );
    }

