    /*
    ###########################################################################
    # (@)PACKAGE:Win32::GUI::Label
    #
    # $Id: Label.xs,v 1.7 2006/01/11 21:26:16 robertemay Exp $
    #
    ###########################################################################
    */

#include "GUI.h"

void Label_onPreCreate(NOTXSPROC LPPERLWIN32GUI_CREATESTRUCT perlcs) {

    perlcs->cs.lpszClass = "STATIC";
    perlcs->cs.style = WS_VISIBLE | WS_CHILD | SS_LEFT;
}

BOOL
Label_onParseOption(NOTXSPROC char *option, SV* value, LPPERLWIN32GUI_CREATESTRUCT perlcs) {

    BOOL retval = TRUE;
    
    if(strcmp(option, "-align") == 0) {
        if(strcmp(SvPV_nolen(value), "left") == 0) {
            SwitchBit(perlcs->cs.style, SS_LEFT, 1);
            SwitchBit(perlcs->cs.style, SS_CENTER, 0);
            SwitchBit(perlcs->cs.style, SS_RIGHT, 0);
        } else if(strcmp(SvPV_nolen(value), "center") == 0) {
            SwitchBit(perlcs->cs.style, SS_LEFT, 0);
            SwitchBit(perlcs->cs.style, SS_CENTER, 1);
            SwitchBit(perlcs->cs.style, SS_RIGHT, 0);
        } else if(strcmp(SvPV_nolen(value), "right") == 0) {
            SwitchBit(perlcs->cs.style, SS_LEFT, 0);
            SwitchBit(perlcs->cs.style, SS_CENTER, 0);
            SwitchBit(perlcs->cs.style, SS_RIGHT, 1);
        } else {
            W32G_WARN("Win32::GUI: Invalid value for -align!");
        }
    } else if(strcmp(option, "-bitmap") == 0 || strcmp(option, "-picture") == 0) {
        SwitchBit(perlcs->cs.style, SS_BITMAP, 1);
        perlcs->hImageList = (HIMAGELIST) handle_From(NOTXSCALL value);
    } else if(strcmp(option, "-icon") == 0 ) {
        SwitchBit(perlcs->cs.style, SS_ICON, 1);
        perlcs->hImageList = (HIMAGELIST) handle_From(NOTXSCALL value);
    } else if(strcmp(option, "-truncate") == 0) {
        if(strcmp(SvPV_nolen(value), "path") == 0) {
			perlcs->cs.style &= ~SS_ELLIPSISMASK;
			perlcs->cs.style |= SS_PATHELLIPSIS;
        } else if(strcmp(SvPV_nolen(value), "word") == 0) {
			perlcs->cs.style &= ~SS_ELLIPSISMASK;
			perlcs->cs.style |= SS_WORDELLIPSIS;
        } else if(SvIV(value)) {
			perlcs->cs.style &= ~SS_ELLIPSISMASK;
			perlcs->cs.style |= SS_ENDELLIPSIS;
        } else {
			perlcs->cs.style &= ~SS_ELLIPSISMASK;
        }
    } else if(strcmp(option, "-frame") == 0) {
        if(strcmp(SvPV_nolen(value), "black") == 0) {
            SwitchBit(perlcs->cs.style, SS_BLACKFRAME, 1);
            SwitchBit(perlcs->cs.style, SS_GRAYFRAME, 0);
            SwitchBit(perlcs->cs.style, SS_WHITEFRAME, 0);
            SwitchBit(perlcs->cs.style, SS_ETCHEDFRAME, 0);
        } else if(strcmp(SvPV_nolen(value), "gray") == 0) {
            SwitchBit(perlcs->cs.style, SS_BLACKFRAME, 0);
            SwitchBit(perlcs->cs.style, SS_GRAYFRAME, 1);
            SwitchBit(perlcs->cs.style, SS_WHITEFRAME, 0);
            SwitchBit(perlcs->cs.style, SS_ETCHEDFRAME, 0);
        } else if(strcmp(SvPV_nolen(value), "white") == 0) {
            SwitchBit(perlcs->cs.style, SS_BLACKFRAME, 0);
            SwitchBit(perlcs->cs.style, SS_GRAYFRAME, 0);
            SwitchBit(perlcs->cs.style, SS_WHITEFRAME, 1);
            SwitchBit(perlcs->cs.style, SS_ETCHEDFRAME, 0);
        } else if(strcmp(SvPV_nolen(value), "etched") == 0) {
            SwitchBit(perlcs->cs.style, SS_BLACKFRAME, 0);
            SwitchBit(perlcs->cs.style, SS_GRAYFRAME, 0);
            SwitchBit(perlcs->cs.style, SS_WHITEFRAME, 0);
            SwitchBit(perlcs->cs.style, SS_ETCHEDFRAME, 1);
        } else {
            SwitchBit(perlcs->cs.style, SS_BLACKFRAME, 0);
            SwitchBit(perlcs->cs.style, SS_GRAYFRAME, 0);
            SwitchBit(perlcs->cs.style, SS_WHITEFRAME, 0);
            SwitchBit(perlcs->cs.style, SS_ETCHEDFRAME, 0);
        }
    } else if(strcmp(option, "-fill") == 0) {
        if(strcmp(SvPV_nolen(value), "black") == 0) {
            SwitchBit(perlcs->cs.style, SS_BLACKRECT, 1);
            SwitchBit(perlcs->cs.style, SS_GRAYRECT, 0);
            SwitchBit(perlcs->cs.style, SS_WHITERECT, 0);
        } else if(strcmp(SvPV_nolen(value), "gray") == 0) {
            SwitchBit(perlcs->cs.style, SS_BLACKRECT, 0);
            SwitchBit(perlcs->cs.style, SS_GRAYRECT, 1);
            SwitchBit(perlcs->cs.style, SS_WHITERECT, 0);
        } else if(strcmp(SvPV_nolen(value), "white") == 0) {
            SwitchBit(perlcs->cs.style, SS_BLACKRECT, 0);
            SwitchBit(perlcs->cs.style, SS_GRAYRECT, 0);
            SwitchBit(perlcs->cs.style, SS_WHITERECT, 1);
        } else if(strcmp(SvPV_nolen(value), "etched") == 0) {
            SwitchBit(perlcs->cs.style, SS_BLACKRECT, 0);
            SwitchBit(perlcs->cs.style, SS_GRAYRECT, 0);
            SwitchBit(perlcs->cs.style, SS_WHITERECT, 0);
        } else {
            SwitchBit(perlcs->cs.style, SS_BLACKRECT, 0);
            SwitchBit(perlcs->cs.style, SS_GRAYRECT, 0);
            SwitchBit(perlcs->cs.style, SS_WHITERECT, 0);
        }
    } else if(strcmp(option, "-wrap") == 0) {
        if(SvIV(value)) {
            SwitchBit(perlcs->cs.style, SS_LEFTNOWORDWRAP, 0);
        } else {
            SwitchBit(perlcs->cs.style, SS_LEFTNOWORDWRAP, 1);
        }
    } else if BitmaskOptionValue("-sunken",   perlcs->cs.style, SS_SUNKEN)
    } else if BitmaskOptionValue("-notify",   perlcs->cs.style, SS_NOTIFY)
    } else if BitmaskOptionValue("-simple",   perlcs->cs.style, SS_SIMPLE)
    } else if BitmaskOptionValue("-noprefix", perlcs->cs.style, SS_NOPREFIX)
    } else retval = FALSE;

    return retval;
}

void
Label_onPostCreate(NOTXSPROC HWND myhandle, LPPERLWIN32GUI_CREATESTRUCT perlcs) {

    if(perlcs->hImageList != NULL) {
        if((perlcs->cs.style & SS_ICON) == SS_ICON)
            SendMessage(myhandle, STM_SETIMAGE, (WPARAM) IMAGE_ICON, (LPARAM) perlcs->hImageList);
        else
            SendMessage(myhandle, STM_SETIMAGE, (WPARAM) IMAGE_BITMAP, (LPARAM) perlcs->hImageList);
    }
}

BOOL
Label_onParseEvent(NOTXSPROC char *name, int* eventID) {

    BOOL retval = TRUE;

         if Parse_Event("DblClick",   PERLWIN32GUI_NEM_DBLCLICK)
    else if Parse_Event("Click",      PERLWIN32GUI_NEM_CLICK)
    else if Parse_Event("Anonymous",  PERLWIN32GUI_NEM_CONTROL1)
    else if Parse_Event("Enable",     PERLWIN32GUI_NEM_CONTROL2)
    else retval = FALSE;

    return retval;
}

int
Label_onEvent (NOTXSPROC LPPERLWIN32GUI_USERDATA perlud, UINT uMsg, WPARAM wParam, LPARAM lParam) {

    int PerlResult = 1;

    if ( uMsg == WM_COMMAND ) {
        switch(HIWORD(wParam)) {
        case STN_CLICKED:
            /*
             * (@)EVENT:Click()
             * (@)APPLIES_TO:Label
             */
            PerlResult = DoEvent(NOTXSCALL perlud, PERLWIN32GUI_NEM_CLICK, "Click", -1 );
            break;
        case STN_DBLCLK:
            /*
             * (@)EVENT:DblClick()
             * (@)APPLIES_TO:Label
             */
            PerlResult = DoEvent(NOTXSCALL perlud, PERLWIN32GUI_NEM_DBLCLICK, "DblClick", -1 );
            break;
        case STN_DISABLE:
        case STN_ENABLE:
            /*
             * (@)EVENT:Enable(State)
             * Sent when the enable state Label change.
             * (@)APPLIES_TO:Label
             */ 
            PerlResult = DoEvent(NOTXSCALL perlud, PERLWIN32GUI_NEM_CONTROL2, "Enable", 
                                 PERLWIN32GUI_ARGTYPE_INT, (HIWORD(wParam) == STN_ENABLE),
                                 -1 );
        default:
            PerlResult = DoEvent(NOTXSCALL perlud, PERLWIN32GUI_NEM_CONTROL1, "Anonymous", 
                PERLWIN32GUI_ARGTYPE_INT, HIWORD(wParam),
                -1 );
            break;
        }  
    }    
    return PerlResult;
}


MODULE = Win32::GUI::Label      PACKAGE = Win32::GUI::Label

PROTOTYPES: DISABLE

#pragma message( "*** PACKAGE Win32::GUI::Label..." )


    ###########################################################################
    # (@)METHOD:GetIcon()
    # Retrieve a handle to the icon associated with a LABEL that has the SS_ICON style

LRESULT
GetIcon(handle)
    HWND   handle
CODE:
    RETVAL = SendMessage(handle, STM_GETICON, 0, 0);
OUTPUT:
    RETVAL

    ###########################################################################
    # (@)METHOD:SetIcon(ICON)
    # Associate an icon with a LABEL that has the SS_ICON style

LRESULT
SetIcon(handle, icon)
    HWND   handle
    HICON  icon
CODE:
    RETVAL = SendMessage(handle, STM_SETICON, (WPARAM) icon, 0);
OUTPUT:
    RETVAL

    ###########################################################################
    # (@)METHOD:GetImage(type)
    # Retrieve a handle to the image (icon or bitmap) associated with the button
    # type = IMAGE_BITMAP | IMAGE_ICON | IMAGE_CURSOR

LRESULT
GetImage(handle, type)
    HWND   handle
    WPARAM type
CODE:
    RETVAL = SendMessage(handle, STM_GETIMAGE, type, 0);
OUTPUT:
    RETVAL

    ###########################################################################
    # (@)METHOD:SetImage(BITMAP)
    # Draws the specified BITMAP in the Label.
    # BITMAP is assumed a Win32::GUI::Bitmap object by default.

LRESULT
SetImage(handle, icon)
    HWND   handle
    HICON  icon
CODE:
    WPARAM type = IMAGE_BITMAP;
    if (sv_isobject(ST(1))) {
        if (sv_derived_from(ST(1), "Win32::GUI::Icon"))
            type = IMAGE_ICON;
        else if (sv_derived_from(ST(1), "Win32::GUI::Cursor"))
            type = IMAGE_CURSOR;
    }    
    RETVAL = SendMessage(handle, STM_SETIMAGE, type, (LPARAM) icon);
OUTPUT:
    RETVAL
