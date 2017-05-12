    /*
    ###########################################################################
    # (@)PACKAGE:Win32::GUI::Button
    #
    # $Id: Button.xs,v 1.8 2006/03/16 21:11:11 robertemay Exp $
    #
    ###########################################################################
    */

#include "GUI.h"

void 
Button_onPreCreate(NOTXSPROC LPPERLWIN32GUI_CREATESTRUCT perlcs) {

    perlcs->cs.lpszClass = "BUTTON";
    perlcs->cs.style = WS_VISIBLE | WS_CHILD | BS_PUSHBUTTON;
}

BOOL
Button_onParseOption(NOTXSPROC char *option, SV* value, LPPERLWIN32GUI_CREATESTRUCT perlcs) {

    BOOL retval = TRUE;

    if(strcmp(option, "-align") == 0) {
        // BS_CENTER is BS_LEFT | BS_RIGHT
        if(strcmp(SvPV_nolen(value), "left") == 0) {
            SwitchBit(perlcs->cs.style, BS_RIGHT, 0);
            SwitchBit(perlcs->cs.style, BS_LEFT, 1);
        } else if(strcmp(SvPV_nolen(value), "center") == 0) {
            SwitchBit(perlcs->cs.style, BS_LEFT,  1);
            SwitchBit(perlcs->cs.style, BS_RIGHT, 1);
        } else if(strcmp(SvPV_nolen(value), "right") == 0) {
            SwitchBit(perlcs->cs.style, BS_LEFT, 0);
            SwitchBit(perlcs->cs.style, BS_RIGHT, 1);
        } else {
            W32G_WARN("Win32::GUI: Invalid value for -align!");
        }
    } else if(strcmp(option, "-valign") == 0) {
        if(strcmp(SvPV_nolen(value), "top") == 0) {
            SwitchBit(perlcs->cs.style, BS_TOP, 1);
            SwitchBit(perlcs->cs.style, BS_BOTTOM, 0);
        } else if(strcmp(SvPV_nolen(value), "center") == 0) {
            SwitchBit(perlcs->cs.style, BS_TOP, 1);
            SwitchBit(perlcs->cs.style, BS_BOTTOM, 1);
        } else if(strcmp(SvPV_nolen(value), "bottom") == 0) {
            SwitchBit(perlcs->cs.style, BS_TOP, 0);
            SwitchBit(perlcs->cs.style, BS_BOTTOM, 1);
        } else {
            W32G_WARN("Win32::GUI: Invalid value for -valign!");
        }
    } else if(strcmp(option, "-ok") == 0) {
        if(SvIV(value) != 0) {
            perlcs->cs.hMenu = (HMENU) IDOK;
        }
    } else if(strcmp(option, "-cancel") == 0) {
        if(SvIV(value) != 0) {
            perlcs->cs.hMenu = (HMENU) IDCANCEL;
        }
    } else if BitmaskOptionValue("-3state",      perlcs->cs.style, BS_3STATE)
    } else if BitmaskOptionValue("-default",     perlcs->cs.style, BS_DEFPUSHBUTTON)
    } else if BitmaskOptionValue("-flat",        perlcs->cs.style, BS_FLAT)
    } else if BitmaskOptionValue("-multiline",   perlcs->cs.style, BS_MULTILINE)
    } else if BitmaskOptionValue("-notify",      perlcs->cs.style, BS_NOTIFY)
    } else if BitmaskOptionValue("-pushlike",    perlcs->cs.style, BS_PUSHLIKE)
    } else if BitmaskOptionValue("-rightbutton", perlcs->cs.style, BS_RIGHTBUTTON)
    } else if(strcmp(option, "-bitmap") == 0 || strcmp(option, "-picture") == 0) {
        SwitchBit(perlcs->cs.style, BS_BITMAP, 1);
        perlcs->hImageList = (HIMAGELIST) handle_From(NOTXSCALL value);
    } else if(strcmp(option, "-icon") == 0) {
        SwitchBit(perlcs->cs.style, BS_ICON, 1);
        perlcs->hImageList = (HIMAGELIST) handle_From(NOTXSCALL value);
    } else if BitmaskOptionValueMask("-checked", perlcs->dwFlags, PERLWIN32GUI_CHECKED )
    } else retval = FALSE;

    return retval;
}

void
Button_onPostCreate(NOTXSPROC HWND myhandle, LPPERLWIN32GUI_CREATESTRUCT perlcs) {

    if(perlcs->hImageList != NULL) {
        if(perlcs->cs.style & BS_ICON) 
            SendMessage( myhandle, BM_SETIMAGE, (WPARAM) IMAGE_ICON, (LPARAM) perlcs->hImageList);
        else 
            SendMessage( myhandle, BM_SETIMAGE, (WPARAM) IMAGE_BITMAP, (LPARAM) perlcs->hImageList);
    }
}

BOOL
Button_onParseEvent(NOTXSPROC char *name, int* eventID) {

    BOOL retval = TRUE;

         if Parse_Event("GotFocus",   PERLWIN32GUI_NEM_GOTFOCUS)
    else if Parse_Event("LostFocus",  PERLWIN32GUI_NEM_LOSTFOCUS)
    else if Parse_Event("DblClick",   PERLWIN32GUI_NEM_DBLCLICK)
    else if Parse_Event("Click",      PERLWIN32GUI_NEM_CLICK)
    else if Parse_Event("Anonymous",  PERLWIN32GUI_NEM_CONTROL1)
    else if Parse_Event("Disable",    PERLWIN32GUI_NEM_CONTROL2)
    else if Parse_Event("Push",       PERLWIN32GUI_NEM_CONTROL3)
    else retval = FALSE;

    return retval;
}

int
Button_onEvent (NOTXSPROC LPPERLWIN32GUI_USERDATA perlud, UINT uMsg, WPARAM wParam, LPARAM lParam) {

    int PerlResult = 1;

    if ( uMsg == WM_COMMAND ) {

        switch(HIWORD(wParam)) {
        case BN_SETFOCUS:
            /*
             * (@)EVENT:GotFocus()
             * Sent when the control is activated.
             * (@)APPLIES_TO:Button, Checkbox, RadioButton
             */
            PerlResult = DoEvent(NOTXSCALL perlud, PERLWIN32GUI_NEM_GOTFOCUS, "GotFocus", -1 );
            break;
        case BN_KILLFOCUS:
            /*
             * (@)EVENT:LostFocus()
             * Sent when the control is deactivated.
             * (@)APPLIES_TO:Button, Checkbox, RadioButton
             */ 
            PerlResult = DoEvent(NOTXSCALL perlud, PERLWIN32GUI_NEM_LOSTFOCUS, "LostFocus", -1 );
            break;
        case BN_CLICKED:
            /*
             * (@)EVENT:Click()
             * Sent when the control is selected (eg.
             * the button pushed, the checkbox checked, etc.).
             * (@)APPLIES_TO:Button, Checkbox, RadioButton
             */ 
            PerlResult = DoEvent(NOTXSCALL perlud, PERLWIN32GUI_NEM_CLICK, "Click", -1 );
            break;
        case BN_DBLCLK:
            /*
             * (@)EVENT:DblClick()
             * Sent when the user double clicks on the control.
             * (@)APPLIES_TO:Button, Checkbox, RadioButton
             */ 
            PerlResult = DoEvent(NOTXSCALL perlud, PERLWIN32GUI_NEM_DBLCLICK, "DblClick", -1 );
            break;
        case BN_DISABLE:
            /*
             * (@)EVENT:Disable()
             * Sent when the button is disabled
             * (@)APPLIES_TO:Button, Checkbox, RadioButton
             */ 
            PerlResult = DoEvent(NOTXSCALL perlud, PERLWIN32GUI_NEM_CONTROL2, "Disable", -1 );
            break;
        case BN_PUSHED:
        case BN_UNPUSHED:
            /*
             * (@)EVENT:Push(State)
             * Sent when the state button change.
             * (@)APPLIES_TO:Button, Checkbox, RadioButton
             */ 
            PerlResult = DoEvent(NOTXSCALL perlud, PERLWIN32GUI_NEM_CONTROL3, "Push", 
                                 PERLWIN32GUI_ARGTYPE_INT, (HIWORD(wParam) == BN_PUSHED),
                                 -1 );
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


    /*
    ###########################################################################
    # (@)PACKAGE:Win32::GUI::Checkbox
    ###########################################################################
    */

void 
Checkbox_onPreCreate(NOTXSPROC LPPERLWIN32GUI_CREATESTRUCT perlcs) {

    perlcs->cs.lpszClass = "BUTTON";
    perlcs->cs.style = WS_VISIBLE | WS_CHILD | BS_AUTOCHECKBOX;
}

BOOL
Checkbox_onParseOption(NOTXSPROC char *option, SV* value, LPPERLWIN32GUI_CREATESTRUCT perlcs) {
    return Button_onParseOption (NOTXSCALL option, value, perlcs);
}

void
Checkbox_onPostCreate(NOTXSPROC HWND myhandle, LPPERLWIN32GUI_CREATESTRUCT perlcs) {

    if(perlcs->dwFlagsMask & PERLWIN32GUI_CHECKED) {
        if(perlcs->dwFlags & PERLWIN32GUI_CHECKED) 
            SendMessage(myhandle, BM_SETCHECK, (WPARAM) BST_CHECKED, (LPARAM) 0);
        else 
            SendMessage(myhandle, BM_SETCHECK, (WPARAM) BST_UNCHECKED, (LPARAM) 0);
    }
}

BOOL
Checkbox_onParseEvent(NOTXSPROC char *name, int* eventID) {
    
    return Button_onParseEvent(NOTXSCALL name, eventID);
}

int
Checkbox_onEvent (NOTXSPROC LPPERLWIN32GUI_USERDATA perlud, UINT uMsg, WPARAM wParam, LPARAM lParam) {

    return Button_onEvent (NOTXSCALL perlud, uMsg, wParam, lParam);
}

    /*
    ###########################################################################
    # (@)PACKAGE:Win32::GUI::RadioButton
    ###########################################################################
    */

void 
RadioButton_onPreCreate(NOTXSPROC LPPERLWIN32GUI_CREATESTRUCT perlcs) {

    perlcs->cs.lpszClass = "BUTTON";
    perlcs->cs.style = WS_VISIBLE | WS_CHILD | BS_AUTORADIOBUTTON;
}

BOOL
RadioButton_onParseOption(NOTXSPROC char *option, SV* value, LPPERLWIN32GUI_CREATESTRUCT perlcs) {
    return Button_onParseOption (NOTXSCALL option, value, perlcs);
}

void
RadioButton_onPostCreate(NOTXSPROC HWND myhandle, LPPERLWIN32GUI_CREATESTRUCT perlcs) {

    Checkbox_onPostCreate (NOTXSCALL myhandle, perlcs);
}

BOOL
RadioButton_onParseEvent(NOTXSPROC char *name, int* eventID) {

    return Button_onParseEvent(NOTXSCALL name, eventID);
}

int
RadioButton_onEvent (NOTXSPROC LPPERLWIN32GUI_USERDATA perlud, UINT uMsg, WPARAM wParam, LPARAM lParam) {

    return Button_onEvent (NOTXSCALL perlud, uMsg, wParam, lParam);
}

    /*
    ###########################################################################
    # (@)PACKAGE:Win32::GUI::Groupbox
    ###########################################################################
    */

void 
Groupbox_onPreCreate(NOTXSPROC LPPERLWIN32GUI_CREATESTRUCT perlcs) {

    perlcs->cs.lpszClass = "BUTTON";
    perlcs->cs.style = WS_VISIBLE | WS_CHILD | BS_GROUPBOX;
}

BOOL
Groupbox_onParseOption(NOTXSPROC char *option, SV* value, LPPERLWIN32GUI_CREATESTRUCT perlcs) {
    return FALSE;
}

void
Groupbox_onPostCreate(NOTXSPROC HWND myhandle, LPPERLWIN32GUI_CREATESTRUCT perlcs) {

}

BOOL
Groupbox_onParseEvent(NOTXSPROC char *name, int* eventID) {
    return FALSE;
}

int
Groupbox_onEvent (NOTXSPROC LPPERLWIN32GUI_USERDATA perlud, UINT uMsg, WPARAM wParam, LPARAM lParam) {

    int PerlResult = 1;

    return PerlResult;
}

    /*
    ###########################################################################
    # (@)PACKAGE:Win32::GUI::Button
    ###########################################################################
    */

MODULE = Win32::GUI::Button     PACKAGE = Win32::GUI::Button

PROTOTYPES: DISABLE

#pragma message( "*** PACKAGE Win32::GUI::Button..." )

    ###########################################################################
    # (@)METHOD:Click()
    # Simulate the user clicking a button.

LRESULT
Click(handle)
    HWND   handle
ALIAS:
    Win32::GUI::RadioButton::Click = 1
    Win32::GUI::Checkbox::Click    = 2
CODE:
    RETVAL = SendMessage(handle, BM_CLICK, 0, 0);
OUTPUT:
    RETVAL


    ###########################################################################
    # (@)METHOD:GetImage(TYPE)
    # Retrieve a handle to the image (icon or bitmap) associated with the button.
    #  TYPE = IMAGE_BITMAP | IMAGE_ICON 

LRESULT
GetImage(handle, type)
    HWND   handle
    WPARAM type
CODE:
    RETVAL = SendMessage(handle, BM_GETIMAGE, type, 0);
OUTPUT:
    RETVAL

    ###########################################################################
    # (@)METHOD:SetImage(BITMAP)
    # Draws the specified B<BITMAP>, a Win32::GUI::Bitmap or Win32::GUI::Icon
    # object, in the Button.

LRESULT
SetImage(handle, icon)
    HWND   handle
    HICON  icon
CODE:
    WPARAM type = (sv_isobject(ST(1)) && sv_derived_from(ST(1), "Win32::GUI::Icon") ? IMAGE_ICON : IMAGE_BITMAP);
    RETVAL = SendMessage(handle, BM_SETIMAGE, type, (LPARAM) icon);
OUTPUT:
    RETVAL

    ###########################################################################
    # (@)PACKAGE:Win32::GUI::RadioButton
    ###########################################################################

MODULE = Win32::GUI::Button     PACKAGE = Win32::GUI::RadioButton

#pragma message( "*** PACKAGE Win32::GUI::RadioButton..." )
 

    ###########################################################################
    # (@)METHOD:Click()
    # Simulate the user clicking a button.

  # ALIAS in Win32::GUI::Button::Click

    ###########################################################################
    # (@)METHOD:GetCheck()
    # Returns the check state of the RadioButton:
    #   0 not checked
    #   1 checked

LRESULT
GetCheck(handle)
    HWND   handle
ALIAS:
    Win32::GUI::Checkbox::GetCheck = 1
CODE:
    RETVAL = SendMessage(handle, BM_GETCHECK, 0, 0);
OUTPUT:
    RETVAL

    ###########################################################################
    # (@)METHOD:SetCheck([VALUE=1])
    # Sets the check state of the RadioButton; for a list of possible values,
    # see GetCheck().
    # If called without arguments, it checks the Checkbox (eg. STATE = 1).

LRESULT
SetCheck(handle, value=1)
    HWND   handle
    WPARAM value
ALIAS:
    Win32::GUI::Checkbox::SetCheck = 1
CODE:
    RETVAL = SendMessage(handle, BM_SETCHECK, value, 0);
OUTPUT:
    RETVAL

    ###########################################################################
    # (@)METHOD:Checked([VALUE])
    # Gets or sets the checked state of the RadioButton; if called without
    # arguments, returns the current state:
    #   0 not checked
    #   1 checked
    # If a B<VALUE> is specified, it can be one of these (eg. 0 to uncheck the
    # RadioButton, 1 to check it).

LRESULT
Checked(handle, value=0)
    HWND   handle
    WPARAM value
ALIAS:
    Win32::GUI::Checkbox::Checked = 1
CODE:
    if(items > 1)         
        RETVAL = SendMessage(handle, BM_SETCHECK, value, 0);
    else
        RETVAL = SendMessage(handle, BM_GETCHECK, 0, 0);
OUTPUT:
    RETVAL

    ###########################################################################
    # (@)PACKAGE:Win32::GUI::Checkbox
    ###########################################################################

MODULE = Win32::GUI::Button     PACKAGE = Win32::GUI::Checkbox

#pragma message( "*** PACKAGE Win32::GUI::Checkbox..." )

    ###########################################################################
    # (@)METHOD:Click()
    # Simulate the user clicking a button.

  # ALIAS in Win32::GUI::Button::Click

    ###########################################################################
    # (@)METHOD:GetCheck()
    # Returns the check state of the Checkbox:
    #   0 not checked
    #   1 checked
    #   2 indeterminate (grayed)

  # ALIAS in Win32::GUI::RadioButton::GetCheck

    ###########################################################################
    # (@)METHOD:SetCheck([VALUE=1])
    # Sets the check state of the Checkbox; for a list of possible values,
    # see GetCheck().
    # If called without arguments, it checks the Checkbox (eg. state = 1).

  # ALIAS in Win32::GUI::RadioButton::SetCheck

    ###########################################################################
    # (@)METHOD:Checked([VALUE])
    # Gets or sets the check state of the Checkbox; if called without
    # arguments, returns the current state:
    #   0 not checked
    #   1 checked
    #   2 indeterminate (grayed)
    # If a B<VALUE> is specified, it can be one of these (eg. 0 to uncheck the
    # Checkbox, 1 to check it).

  # ALIAS in Win32::GUI::RadioButton::Checked

    ###########################################################################
    # (@)PACKAGE:Win32::GUI::Groupbox
    ###########################################################################

MODULE = Win32::GUI::Button     PACKAGE = Win32::GUI::Groupbox


#pragma message( "*** PACKAGE Win32::GUI::Groupbox..." )
