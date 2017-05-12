    /*
    ###########################################################################
    # (@)PACKAGE:Win32::GUI::DateTime
    #
    # $Id: DateTime.xs,v 1.5 2005/08/03 21:45:56 robertemay Exp $
    #
    ###########################################################################
    */

#include "GUI.h"


void 
DateTime_onPreCreate(NOTXSPROC LPPERLWIN32GUI_CREATESTRUCT perlcs) {

    perlcs->cs.lpszClass = DATETIMEPICK_CLASS;
    perlcs->cs.style = WS_VISIBLE | WS_CHILD;
}

BOOL
DateTime_onParseOption(NOTXSPROC char *option, SV* value, LPPERLWIN32GUI_CREATESTRUCT perlcs) {

    BOOL retval = TRUE;

    if(strcmp(option, "-align") == 0) {
        if(strcmp(SvPV_nolen(value), "left") == 0) {
            SwitchBit(perlcs->cs.style, DTS_RIGHTALIGN, 0);
        } else if(strcmp(SvPV_nolen(value), "right") == 0) {
            SwitchBit(perlcs->cs.style, DTS_RIGHTALIGN, 1);
        } else {
            W32G_WARN("Win32::GUI: Invalid value for -align!");
        }
    } 
    else if(strcmp(option, "-format") == 0) {
        if(strcmp(SvPV_nolen(value), "shortdate") == 0) {
            SwitchBit(perlcs->cs.style, DTS_LONGDATEFORMAT,  0);
            SwitchBit(perlcs->cs.style, DTS_TIMEFORMAT,      0);
            SwitchBit(perlcs->cs.style, DTS_SHORTDATEFORMAT, 1);
        } else if(strcmp(SvPV_nolen(value), "longdate") == 0) {
            SwitchBit(perlcs->cs.style, DTS_TIMEFORMAT,      0);
            SwitchBit(perlcs->cs.style, DTS_SHORTDATEFORMAT, 0);
            SwitchBit(perlcs->cs.style, DTS_LONGDATEFORMAT,  1);
        } else if(strcmp(SvPV_nolen(value), "time") == 0) {
            SwitchBit(perlcs->cs.style, DTS_LONGDATEFORMAT,  0);
            SwitchBit(perlcs->cs.style, DTS_SHORTDATEFORMAT, 0);
            SwitchBit(perlcs->cs.style, DTS_TIMEFORMAT,      1);
        } else {
            W32G_WARN("Win32::GUI: Invalid value for -format!");
        }
    } else if BitmaskOptionValue("-shownone", perlcs->cs.style, DTS_SHOWNONE)
    } else if BitmaskOptionValue("-updown", perlcs->cs.style,   DTS_UPDOWN)
    } else retval = FALSE;

    return retval;
}

void
DateTime_onPostCreate(NOTXSPROC HWND myhandle, LPPERLWIN32GUI_CREATESTRUCT perlcs) {
}

BOOL
DateTime_onParseEvent(NOTXSPROC char *name, int* eventID) {

    BOOL retval = TRUE;

         if Parse_Event("GotFocus",   PERLWIN32GUI_NEM_GOTFOCUS)
    else if Parse_Event("LostFocus",  PERLWIN32GUI_NEM_LOSTFOCUS)
    else if Parse_Event("CloseUp",    PERLWIN32GUI_NEM_CONTROL1)
    else if Parse_Event("Change",     PERLWIN32GUI_NEM_CONTROL2)
    else if Parse_Event("DropDown",   PERLWIN32GUI_NEM_CONTROL3)
    else retval = FALSE;

    return retval;
}

int
DateTime_onEvent (NOTXSPROC LPPERLWIN32GUI_USERDATA perlud, UINT uMsg, WPARAM wParam, LPARAM lParam) {

    int PerlResult = 1;

    if ( uMsg == WM_NOTIFY ) {

        LPNMHDR notify = (LPNMHDR) lParam;
        switch(notify->code) {
        case DTN_CLOSEUP:
            /*
             * (@)EVENT:CloseUp()
             * Sent when the user closes the drop-down month calendar. .
             * (@)APPLIES_TO:DateTime
             */ 
            PerlResult = DoEvent(NOTXSCALL perlud, PERLWIN32GUI_NEM_CONTROL1, "CloseUp", -1 );
            break;
        case DTN_DATETIMECHANGE:
            /*
             * (@)EVENT:Change()
             * Sent when the datetime change. .
             * (@)APPLIES_TO:DateTime
             */ 
            PerlResult = DoEvent(NOTXSCALL perlud, PERLWIN32GUI_NEM_CONTROL2, "Change", -1 );
            break;
        case DTN_DROPDOWN:
            /*
             * (@)EVENT:DropDown()
             * Sent when the user activates the drop-down month calendar..
             * (@)APPLIES_TO:DateTime
             */ 
            PerlResult = DoEvent(NOTXSCALL perlud, PERLWIN32GUI_NEM_CONTROL3, "DropDown", -1 );
            break;
        }
    }

    return PerlResult;
}



MODULE = Win32::GUI::DateTime     PACKAGE = Win32::GUI::DateTime

PROTOTYPES: DISABLE

#pragma message( "*** PACKAGE Win32::GUI::DateTime..." )

    ###########################################################################
    # (@)METHOD:GetMonthCal()
    # Retrieves the handle to a date and time picker's (DTP) child month calendar control. 

HWND
GetMonthCal(handle)
    HWND handle
CODE:
    RETVAL = (HWND) DateTime_GetMonthCal(handle);
OUTPUT:
    RETVAL

    ###########################################################################
    # (@)METHOD:GetMonthCalColor(icolor)
    # Retrieves the color for a given portion of the month calendar within a date and time picker (DTP) control.
    # icolor :
    #   MCSC_BACKGROUND = Retrieve the background color displayed between months. 
    #   MCSC_MONTHBK = Retrieve the background color displayed within the month. 
    #   MCSC_TEXT = Retrieve the color used to display text within a month. 
    #   MCSC_TITLEBK = Retrieve the background color displayed in the calendar's title. 
    #   MCSC_TITLETEXT = Retrieve the color used to display text within the calendar's title. 
    #   MCSC_TRAILINGTEXT = Retrieve the color used to display header day and trailing day
    #                 text. Header and trailing days are the days from the previous and following
    #                 months that appear on the current month calendar. 
COLORREF
GetMonthCalColor(handle,icolor)
    HWND handle
    int  icolor
CODE:
    RETVAL = (COLORREF)DateTime_GetMonthCalColor(handle, icolor);
OUTPUT:
    RETVAL

    ###########################################################################
    # (@)METHOD:GetMonthCalFont(icolor)
    # Retrieves the font that the date and time picker (DTP) control's child month calendar control is currently using.
HFONT
GetMonthCalFont(handle)
    HWND handle
CODE:
    RETVAL = (HFONT) DateTime_GetMonthCalFont(handle);
OUTPUT:
    RETVAL

    # TODO : DateTime_GetRange

    ###########################################################################
    # (@)METHOD:GetSystemTime()
    # (@)METHOD:GetDateTime()
    # Returns the date and time in the DateTime control in a eight
    # elements array (year, month, day, dayofweek, hour, minute, second, millisecond).
void
GetSystemTime(handle)
    HWND handle
ALIAS:
    Win32::GUI::DateTime::GetDateTime = 1
PREINIT:
    SYSTEMTIME st;
PPCODE:
    if(DateTime_GetSystemtime(handle, &st) == GDT_VALID) {
        EXTEND(SP, 8);
        XST_mIV(0, st.wYear);
        XST_mIV(1, st.wMonth);
        XST_mIV(2, st.wDay);
        XST_mIV(3, st.wDayOfWeek);
        XST_mIV(4, st.wHour);
        XST_mIV(5, st.wMinute);
        XST_mIV(6, st.wSecond);
        XST_mIV(7, st.wMilliseconds);
        XSRETURN(8);
    } else {
        XSRETURN_UNDEF;
    }

    ###########################################################################
    # (@)METHOD:SetFormat(FORMAT)
    # (@)METHOD:Format(FORMAT)
    # Sets the format for the DateTime control to the specified string.
BOOL
SetFormat(handle, format = NULL)
    HWND handle
    LPCTSTR format
ALIAS:
    Win32::GUI::DateTime::Format = 1
CODE:
    RETVAL = DateTime_SetFormat(handle, format);
OUTPUT:
    RETVAL

    ###########################################################################
    # (@)METHOD:SetMonthCalColor(icolor,color)
    # Sets the color for a given portion of the month calendar within a date and time picker (DTP) control.
HFONT
SetMonthCalColor(handle,icolor,color)
    HWND handle
    int  icolor
    COLORREF color
CODE:
    RETVAL = (HFONT) DateTime_SetMonthCalColor(handle,icolor,color);
OUTPUT:
    RETVAL

    ###########################################################################
    # (@)METHOD:SetMonthCalFont(font,flag)
    # Sets the font to be used by the date and time picker (DTP) control's child month calendar control.
HFONT
SetMonthCalFont(handle,font,flag)
    HWND  handle
    HFONT font
    BOOL  flag
CODE:
    RETVAL = (HFONT) DateTime_SetMonthCalFont(handle,font,MAKELONG(flag,0));
OUTPUT:
    RETVAL

    # TODO : DateTime_SetRange

    ###########################################################################
    # (@)METHOD:SetSystemTime(YEAR,MON, DAY, HOUR, MIN, SEC, [MSEC=0])
    # (@)METHOD:SetDateTime(YEAR,MON, DAY, HOUR, MIN, SEC, [MSEC=0])
    # Sets the date time in the DateTime control
BOOL
SetSystemTime(handle, year, mon, day, hour, min, sec, msec=0)
    HWND handle
    int year
    int mon
    int day
    int hour
    int min
    int sec
    int msec
ALIAS:
    Win32::GUI::DateTime::SetDateTime = 1
PREINIT:
    SYSTEMTIME st;
CODE:
    ZeroMemory(&st, sizeof(SYSTEMTIME));
    st.wYear   = year;
    st.wDay    = day;
    st.wMonth  = mon;
    st.wHour   = hour;
    st.wMinute = min;
    st.wSecond = sec;
    st.wMilliseconds = msec;

    RETVAL = DateTime_SetSystemtime(handle, GDT_VALID, &st);
OUTPUT:
    RETVAL

    ###########################################################################
    ###########################################################################
    ###########################################################################

    ###########################################################################
    # (@)METHOD:GetDate()
    # Returns the date in the DateTime control in a three elements array (day, month, year).
void
GetDate(handle)
    HWND handle
PREINIT:
    SYSTEMTIME st;
PPCODE:
    if(DateTime_GetSystemtime(handle, &st) == GDT_VALID) {
        EXTEND(SP, 3);
        XST_mIV(0, st.wDay);
        XST_mIV(1, st.wMonth);
        XST_mIV(2, st.wYear);
        XSRETURN(3);
    } else {
        XSRETURN_UNDEF;
    }

    ###########################################################################
    # (@)METHOD:SetDate(DAY, MONTH, YEAR)
    # Sets the date in the DateTime control in a three elements array (day, month, year).
BOOL
SetDate(handle, day, mon, year)
    HWND handle
    int day
    int mon
    int year
PREINIT:
    SYSTEMTIME st;
CODE:
    ZeroMemory(&st, sizeof(SYSTEMTIME));
    st.wDay   = day;
    st.wMonth = mon;
    st.wYear  = year;
    RETVAL = DateTime_SetSystemtime(handle, GDT_VALID, &st);
OUTPUT:
    RETVAL

    ###########################################################################
    # (@)METHOD:GetTime()
    # Returns the time in the DateTime control in a four
    # elements array (hour, min, sec, msec).
void
GetTime(handle)
    HWND handle
PREINIT:
    SYSTEMTIME st;
PPCODE:
    if(DateTime_GetSystemtime(handle, &st) == GDT_VALID) {
        EXTEND(SP, 4);
        XST_mIV(0, st.wHour);
        XST_mIV(1, st.wMinute);
        XST_mIV(2, st.wSecond);
        XST_mIV(3, st.wMilliseconds);
        XSRETURN(4);
    } else {
        XSRETURN_UNDEF;
    }

    ###########################################################################
    # (@)METHOD:SetTime(HOUR, MIN, SEC, [MSEC=0])
    # Sets the time in the DateTime control in a four
    # elements array (hour, min, sec, [msec=0]).
BOOL
SetTime(handle, hour, min, sec, msec=0)
    HWND handle
    int hour
    int min
    int sec
    int msec
PREINIT:
    SYSTEMTIME st;
CODE:
    ZeroMemory(&st, sizeof(SYSTEMTIME));
    st.wHour   = hour;
    st.wMinute = min;
    st.wSecond = sec;
    st.wMilliseconds = msec;
    RETVAL = DateTime_SetSystemtime(handle, GDT_VALID, &st);
OUTPUT:
    RETVAL

    ###########################################################################
    # (@)METHOD:SetNone(handle)
    # Set none state in the DateTime control (control check box was selected).
void
SetNone(handle)
    HWND handle
PPCODE:
    DateTime_SetSystemtime(handle, GDT_NONE, NULL);

    ###########################################################################
    # (@)METHOD:IsNone()
    # Test if the DateTime control is None (control check box was not selected).
BOOL
IsNone(handle)
    HWND handle
PREINIT:
    SYSTEMTIME st;
CODE:
    RETVAL = (DateTime_GetSystemtime(handle, &st) == GDT_NONE);
OUTPUT:
    RETVAL

