    /*
    ###########################################################################
    # (@)PACKAGE:Win32::GUI::MonthCal
    #
    # $Id: MonthCal.xs,v 1.2 2006/06/23 18:35:33 robertemay Exp $
    #
    ###########################################################################
    */

#include "GUI.h"


void 
MonthCal_onPreCreate(NOTXSPROC LPPERLWIN32GUI_CREATESTRUCT perlcs) {

    perlcs->cs.lpszClass = MONTHCAL_CLASS;
    perlcs->cs.style = WS_CHILD | WS_VISIBLE;
}

BOOL
MonthCal_onParseOption(NOTXSPROC char *option, SV* value, LPPERLWIN32GUI_CREATESTRUCT perlcs) {

    BOOL retval = TRUE;

           if BitmaskOptionValue("-daystate",      perlcs->cs.style, MCS_DAYSTATE)
    } else if BitmaskOptionValue("-multiselect",   perlcs->cs.style, MCS_MULTISELECT )
    } else if BitmaskOptionValue("-notoday",       perlcs->cs.style, MCS_NOTODAY )
    } else if BitmaskOptionValue("-notodaycircle", perlcs->cs.style, MCS_NOTODAYCIRCLE )
    } else if BitmaskOptionValue("-weeknumber",    perlcs->cs.style, MCS_WEEKNUMBERS )
    } else retval = FALSE;

    return retval;
}

void
MonthCal_onPostCreate(NOTXSPROC HWND myhandle, LPPERLWIN32GUI_CREATESTRUCT perlcs) {

    if(perlcs->clrBackground != CLR_INVALID) {
        MonthCal_SetColor(myhandle, MCSC_BACKGROUND, perlcs->clrBackground);
        perlcs->clrBackground = CLR_INVALID;  // Don't store  
    }
    if(perlcs->clrForeground != CLR_INVALID) {
        MonthCal_SetColor(myhandle, MCSC_TEXT, perlcs->clrForeground);
        perlcs->clrForeground = CLR_INVALID;  // Don't store  
    }
}

BOOL
MonthCal_onParseEvent(NOTXSPROC char *name, int* eventID) {

    BOOL retval = TRUE;

         if Parse_Event("SelChange",   PERLWIN32GUI_NEM_CONTROL1)
    else if Parse_Event("Select",      PERLWIN32GUI_NEM_CONTROL2)
    else if Parse_Event("DayState",    PERLWIN32GUI_NEM_CONTROL3)
    else retval = FALSE;

    return retval;
}

int
MonthCal_onEvent (NOTXSPROC LPPERLWIN32GUI_USERDATA perlud, UINT uMsg, WPARAM wParam, LPARAM lParam) {

    int PerlResult = 1;

    if ( uMsg == WM_NOTIFY ) {

        LPNMSELCHANGE sel = (LPNMSELCHANGE) lParam;
        switch(sel->nmhdr.code) {

        case MCN_SELCHANGE:
            /*
             * (@)EVENT:SelChange(YEARMIN,MONTMIN,DAYMIN,YEARMAX,MONTMAX,DAYMAX)
             * Sent by a month calendar control when the currently selected date or range of dates changes.
             * (@)APPLIES_TO:MonthCal
             */
            PerlResult = DoEvent(NOTXSCALL perlud, PERLWIN32GUI_NEM_CONTROL1, "SelChange",
                                 PERLWIN32GUI_ARGTYPE_INT, sel->stSelStart.wYear,
                                 PERLWIN32GUI_ARGTYPE_INT, sel->stSelStart.wMonth,
                                 PERLWIN32GUI_ARGTYPE_INT, sel->stSelStart.wDay,
                                 PERLWIN32GUI_ARGTYPE_INT, sel->stSelEnd.wYear,
                                 PERLWIN32GUI_ARGTYPE_INT, sel->stSelEnd.wMonth,
                                 PERLWIN32GUI_ARGTYPE_INT, sel->stSelEnd.wDay,
                                 -1 );
            break;

        case MCN_SELECT:
            /*
             * (@)EVENT:Select(YEARMIN,MONTMIN,DAYMIN,YEARMAX,MONTMAX,DAYMAX)
             * Sent by a month calendar control when the user makes an explicit date selection within a month calendar control.
             * (@)APPLIES_TO:MonthCal
             */
            PerlResult = DoEvent(NOTXSCALL perlud, PERLWIN32GUI_NEM_CONTROL2, "Select",
                                 PERLWIN32GUI_ARGTYPE_INT, sel->stSelStart.wYear,
                                 PERLWIN32GUI_ARGTYPE_INT, sel->stSelStart.wMonth,
                                 PERLWIN32GUI_ARGTYPE_INT, sel->stSelStart.wDay,
                                 PERLWIN32GUI_ARGTYPE_INT, sel->stSelEnd.wYear,
                                 PERLWIN32GUI_ARGTYPE_INT, sel->stSelEnd.wMonth,
                                 PERLWIN32GUI_ARGTYPE_INT, sel->stSelEnd.wDay,
                                 -1 );
            break;

        case MCN_GETDAYSTATE:
            /*
             * (@)EVENT:DayState(YEAR,MONTH,DAY,MAXMONTH,MONTHDAYSTATELIST)
             * Sent by a month calendar control to request information about how individual days should be displayed.
             *
             * MONTHDAYSTATELIST is array reference.
             * Each MONTHDAYSTATELIST items are an MONTHDAYSTATE.
             * The MONTHDAYSTATE type is a bit field, where each bit (1 through 31) 
             * represents the state of a day in a month. If a bit is on, the corresponding
             * day will be displayed in bold; otherwise it will be displayed with no emphasis.
             * (@)APPLIES_TO:MonthCal
             */
            {
                #define lpnmDS ((NMDAYSTATE *)lParam)

                AV* av = newAV();
                av_fill(av, lpnmDS->cDayState); 

                MONTHDAYSTATE mds[12];
                ZeroMemory(mds, sizeof(MONTHDAYSTATE) * 12);
                lpnmDS->prgDayState = mds;

                PerlResult = DoEvent(NOTXSCALL perlud, PERLWIN32GUI_NEM_CONTROL3, "DayState",
                                     PERLWIN32GUI_ARGTYPE_INT, lpnmDS->stStart.wYear,
                                     PERLWIN32GUI_ARGTYPE_INT, lpnmDS->stStart.wMonth,
                                     PERLWIN32GUI_ARGTYPE_INT, lpnmDS->stStart.wDay,
                                     PERLWIN32GUI_ARGTYPE_INT, lpnmDS->cDayState,
                                     PERLWIN32GUI_ARGTYPE_SV,  sv_2mortal(newRV((SV*) av)),
                                     -1 );            

                for (int i = 0; i < av_len(av); i++) {
                    SV** sv = av_fetch(av, i, 0);
                    if (sv && SvIOK(*sv))
                        lpnmDS->prgDayState[i] = SvIV(*sv);
                }
                SvREFCNT_dec(av);
            }
            break;
        }
    }

    return PerlResult;
}



MODULE = Win32::GUI::MonthCal     PACKAGE = Win32::GUI::MonthCal

PROTOTYPES: DISABLE

#pragma message( "*** PACKAGE Win32::GUI::MonthCal..." )

    ###########################################################################
    # (@)METHOD:GetColor(ICOLOR)
    # Retrieves the color for a given portion of a month calendar control.
    #
    # B<ICOLOR> :
    #  MCSC_BACKGROUND   = 0 : the background color (between months)
    #  MCSC_TEXT         = 1 : the dates
    #  MCSC_TITLEBK      = 2 : background of the title
    #  MCSC_TITLETEXT    = 3 : text color of the title
    #  MCSC_MONTHBK      = 4 : background within the month cal
    #  MCSC_TRAILINGTEXT = 5 : the text color of header & trailing days

COLORREF
GetColor(handle, iColor)
    HWND handle
    int  iColor
CODE:
    RETVAL = MonthCal_GetColor(handle, iColor);
OUTPUT:
    RETVAL

    ###########################################################################
    # (@)METHOD:GetCurSel()
    # Retrieves the currently selected date in a four
    # elements array (year, month, day, dayofweek).
void
GetCurSel(handle)
    HWND handle
PREINIT:
    SYSTEMTIME st;
PPCODE:
    if(MonthCal_GetCurSel(handle, &st)) {
        EXTEND(SP, 4);
        XST_mIV(0, st.wYear);
        XST_mIV(1, st.wMonth);
        XST_mIV(2, st.wDay);
        XST_mIV(3, st.wDayOfWeek);
        XSRETURN(4);
    } else {
        XSRETURN_UNDEF;
    }

    ###########################################################################
    # (@)METHOD:GetFirstDayOfWeek()
    # Retrieves the first day of the week for a month calendar control.
DWORD
GetFirstDayOfWeek(handle)
    HWND handle
CODE:
    RETVAL = MonthCal_GetFirstDayOfWeek(handle);
OUTPUT:
    RETVAL

    ###########################################################################
    # (@)METHOD:GetMaxSelCount()
    # Retrieves the maximum date range that can be selected in a month calendar control.
DWORD
GetMaxSelCount(handle)
    HWND handle
CODE:
    RETVAL =  MonthCal_GetMaxSelCount(handle);
OUTPUT:
    RETVAL

    ###########################################################################
    # (@)METHOD:GetMaxTodayWidth()
    # Retrieves the maximum width of the "today" string in a month calendar control.
DWORD
GetMaxTodayWidth(handle)
    HWND handle
CODE:
    RETVAL =  MonthCal_GetMaxTodayWidth(handle);
OUTPUT:
    RETVAL

    ###########################################################################
    # (@)METHOD:GetMinReqRect()
    # Retrieves the minimum size required to display a full month in a month calendar control
void
GetMinReqRect(handle)
    HWND handle
PREINIT:
    RECT myRect;
PPCODE:
    if(MonthCal_GetMinReqRect(handle, &myRect)) {
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
    # (@)METHOD:GetMonthDelta()
    # Retrieves the scroll rate for a month calendar control. 
    # The scroll rate is the number of months that the control moves its display
    # when the user clicks a scroll button.
int
GetMonthDelta(handle)
    HWND handle
CODE:
    RETVAL =  MonthCal_GetMonthDelta(handle);
OUTPUT:
    RETVAL

    ###########################################################################
    # (@)METHOD:GetMonthRange([FLAG=GMR_DAYSTATE])
    # Retrieves date information that represents the high and low limits of a
    # month calendar control's display.
    # Return an array (yearmin, monthmin, daymin, dayofweekmin, yearmax, monthmax, daymax, dayofweekmax).
void
GetMonthRange(handle, flag=GMR_DAYSTATE)
    HWND handle
    DWORD flag
PREINIT:
    SYSTEMTIME st[2];
PPCODE:
    MonthCal_GetMonthRange(handle, flag, &st);
    EXTEND(SP, 8);
    XST_mIV(0, st[0].wYear);
    XST_mIV(1, st[0].wMonth);
    XST_mIV(2, st[0].wDay);
    XST_mIV(3, st[0].wDayOfWeek);
    XST_mIV(4, st[1].wYear);
    XST_mIV(5, st[1].wMonth);
    XST_mIV(6, st[1].wDay);
    XST_mIV(7, st[1].wDayOfWeek);
    XSRETURN(8);

    ###########################################################################
    # (@)METHOD:GetRange()
    # Retrieves the minimum and maximum allowable dates set for a month calendar control
void
GetRange(handle)
    HWND handle
PREINIT:
    SYSTEMTIME st[2];
    DWORD ret;
PPCODE:
    ret = MonthCal_GetRange(handle, &st);
    if (GIMME == G_ARRAY) {
        EXTEND(SP, 8);
        XST_mIV(0, st[0].wYear);
        XST_mIV(1, st[0].wMonth);
        XST_mIV(2, st[0].wDay);
        XST_mIV(3, st[0].wDayOfWeek);
        XST_mIV(4, st[1].wYear);
        XST_mIV(5, st[1].wMonth);
        XST_mIV(6, st[1].wDay);
        XST_mIV(7, st[1].wDayOfWeek);
        XSRETURN(8);
    } else {
        EXTEND(SP, 1);
        XST_mIV(0, ret);
        XSRETURN(1);
    }

    ###########################################################################
    # (@)METHOD:GetSelRange()
    # Retrieves date information that represents the upper and lower limits of
    # the date range currently selected by the user. 
    # Return an array (yearmin, monthmin, daymin, dayofweekmin, yearmax, monthmax, daymax, dayofweekmax).
void
GetSelRange(handle)
    HWND handle
PREINIT:
    SYSTEMTIME st[2];
PPCODE:
    if (MonthCal_GetSelRange(handle, &st) ) {
        EXTEND(SP, 8);
        XST_mIV(0, st[0].wYear);
        XST_mIV(1, st[0].wMonth);
        XST_mIV(2, st[0].wDay);
        XST_mIV(3, st[0].wDayOfWeek);
        XST_mIV(4, st[1].wYear);
        XST_mIV(5, st[1].wMonth);
        XST_mIV(6, st[1].wDay);
        XST_mIV(7, st[1].wDayOfWeek);
        XSRETURN(8);
    } else {
        XSRETURN_UNDEF;
    }

    ###########################################################################
    # (@)METHOD:GetToday()
    # Retrieves the date information for the date specified as "today" for a month calendar control. 
    # Return an array (year, month, day, dayofweek).
void
GetToday(handle)
    HWND handle
PREINIT:
    SYSTEMTIME st;
PPCODE:
    if(MonthCal_GetToday(handle, &st)) {
        EXTEND(SP, 4);
        XST_mIV(0, st.wYear);
        XST_mIV(1, st.wMonth);
        XST_mIV(2, st.wDay);
        XST_mIV(3, st.wDayOfWeek);
        XSRETURN(4);
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
    RETVAL =  MonthCal_GetUnicodeFormat(handle);
OUTPUT:
    RETVAL

    ###########################################################################
    # (@)METHOD:HitTest(X,Y)
    # Determines which portion of a month calendar control is at a given point on the screen.
void
HitTest(handle, x, y)
    HWND handle
    int x
    int y
PREINIT:
    MCHITTESTINFO ht;
    DWORD flag;
PPCODE:
    ZeroMemory(&ht, sizeof(MCHITTESTINFO));
    ht.cbSize = sizeof(MCHITTESTINFO);
    ht.pt.x = x;
    ht.pt.y = y;
    flag = MonthCal_HitTest(handle, &ht);

    if(GIMME == G_ARRAY) {
        EXTEND(SP, 10);
        XST_mPV(0, "-flag");
        XST_mIV(1, flag);
        XST_mPV(2, "-year");
        XST_mIV(3, ht.st.wYear);
        XST_mPV(4, "-month");
        XST_mIV(5, ht.st.wMonth);
        XST_mPV(6, "-day");
        XST_mIV(7, ht.st.wDay);
        XST_mPV(8, "-dayofweek");
        XST_mIV(9, ht.st.wDayOfWeek);
        XSRETURN(10);
    } else {
        EXTEND(SP, 1);
        XST_mIV(0, flag);
        XSRETURN(1);
    }

    ###########################################################################
    # (@)METHOD:SetColor(ICOLOR, COLOR)
    # Sets the color for a given portion of a month calendar control.
    #
    # B<ICOLOR> :
    #  MCSC_BACKGROUND   = 0 : the background color (between months)
    #  MCSC_TEXT         = 1 : the dates
    #  MCSC_TITLEBK      = 2 : background of the title
    #  MCSC_TITLETEXT    = 3 : text color of the title
    #  MCSC_MONTHBK      = 4 : background within the month cal
    #  MCSC_TRAILINGTEXT = 5 : the text color of header & trailing days

COLORREF
SetColor(handle, iColor, Color)
    HWND handle
    int  iColor
    COLORREF Color
CODE:
    RETVAL = MonthCal_SetColor(handle, iColor, Color);
OUTPUT:
    RETVAL

    ###########################################################################
    # (@)METHOD:SetCurSel(YEAR, MON, DAY)
    # Sets the currently selected date for a month calendar control.
BOOL
SetCurSel(handle, year, mon, day)
    HWND handle
    int year
    int mon
    int day
PREINIT:
    SYSTEMTIME st;
CODE:
    ZeroMemory(&st, sizeof(SYSTEMTIME));
    st.wYear   = year;
    st.wDay    = day;
    st.wMonth  = mon;

    RETVAL = MonthCal_SetCurSel(handle, &st);
OUTPUT:
    RETVAL

    ###########################################################################
    # (@)METHOD:SetDayState([MONTHDAYSTATELIST])
    # Sets the day states for all months that are currently visible within a 
    # month calendar control.
    # Each MONTHDAYSTATELIST items are an MONTHDAYSTATE.
    # The MONTHDAYSTATE type is a bit field, where each bit (1 through 31) 
    # represents the state of a day in a month. If a bit is on, the corresponding
    # day will be displayed in bold; otherwise it will be displayed with no emphasis. 
BOOL
SetDayState(handle, ...)
    HWND handle
PREINIT:
    MONTHDAYSTATE mds[12];
    int iMax;
CODE:
    ZeroMemory(mds, sizeof(MONTHDAYSTATE)*12);    
    iMax = MonthCal_GetMonthRange(handle, GMR_DAYSTATE, NULL);

    if (items > 1) {
        for (int i = 1; i < iMax; i++) {
            if (i < items)
                mds[i-1] = (MONTHDAYSTATE) SvIV(ST(i));
            else
                mds[i-1] = (MONTHDAYSTATE) SvIV(ST(items-1));
        }
    }
        
    RETVAL = MonthCal_SetDayState(handle, iMax, mds);
OUTPUT:
    RETVAL

    ###########################################################################
    # (@)METHOD:SetFirstDayOfWeek(IDAY)
    # Sets the first day of the week for a month calendar control.
DWORD
SetFirstDayOfWeek(handle, iDay)
    HWND handle
    int iDay
CODE:
    RETVAL = MonthCal_SetFirstDayOfWeek(handle, iDay);
OUTPUT:
    RETVAL

    ###########################################################################
    # (@)METHOD:SetMaxSelCount(MAX)
    # Sets the maximum number of days that can be selected in a month calendar control.
DWORD
SetMaxSelCount(handle, iMax)
    HWND handle
    int iMax
CODE:
    RETVAL =  MonthCal_SetMaxSelCount(handle, iMax);
OUTPUT:
    RETVAL

    ###########################################################################
    # (@)METHOD:SetMonthDelta(DELTA)
    # Sets the scroll rate for a month calendar control.
    # The scroll rate is the number of months that the control moves its display
    # when the user clicks a scroll button.
DWORD
SetMonthDelta(handle, iDelta)
    HWND handle
    int iDelta
CODE:
    RETVAL =  MonthCal_SetMonthDelta(handle, iDelta);
OUTPUT:
    RETVAL

    ###########################################################################
    # (@)METHOD:SetRange(YEARMIN,MONTHMIN,DAYMIN,YEARMAX,MONTHMAX,DAYMAX)
    # Sets the minimum and maximum allowable dates for a month calendar control.
BOOL
SetRange(handle, yearmin, monmin, daymin, yearmax, monmax, daymax)
    HWND handle
    int yearmin
    int monmin
    int daymin
    int yearmax
    int monmax
    int daymax
PREINIT:
    SYSTEMTIME st[2];
CODE:
    ZeroMemory(&st, sizeof(SYSTEMTIME) * 2);
    st[0].wYear   = yearmin;
    st[0].wDay    = daymin;
    st[0].wMonth  = monmin;
    st[1].wYear   = yearmax;
    st[1].wDay    = daymax;
    st[1].wMonth  = monmax;

    RETVAL = MonthCal_SetRange(handle, GDTR_MIN|GDTR_MAX, &st);
OUTPUT:
    RETVAL

    ###########################################################################
    # (@)METHOD:SetSelRange(YEARMIN,MONTHMIN,DAYMIN,YEARMAX,MONTHMAX,DAYMAX)
    # Sets the selection for a month calendar control to a given date range.
BOOL
SetSelRange(handle, yearmin, monmin, daymin, yearmax, monmax, daymax)
    HWND handle
    int yearmin
    int monmin
    int daymin
    int yearmax
    int monmax
    int daymax
PREINIT:
    SYSTEMTIME st[2];
CODE:
    ZeroMemory(&st, sizeof(SYSTEMTIME) * 2);
    st[0].wYear   = yearmin;
    st[0].wDay    = daymin;
    st[0].wMonth  = monmin;
    st[1].wYear   = yearmax;
    st[1].wDay    = daymax;
    st[1].wMonth  = monmax;

    RETVAL = MonthCal_SetSelRange(handle, &st);
OUTPUT:
    RETVAL

    ###########################################################################
    # (@)METHOD:SetToday(YEAR, MON, DAY)
    # Sets the "today" selection for a month calendar control.
BOOL
SetToday(handle, year, mon, day)
    HWND handle
    int year
    int mon
    int day
PREINIT:
    SYSTEMTIME st;
CODE:
    ZeroMemory(&st, sizeof(SYSTEMTIME));
    st.wYear   = year;
    st.wDay    = day;
    st.wMonth  = mon;

    RETVAL = MonthCal_SetToday(handle, &st);
OUTPUT:
    RETVAL

    ###########################################################################
    # (@)METHOD:SetUnicodeFormat(FLAG)
    # Sets the UNICODE character format flag for the control.
BOOL
SetUnicodeFormat(handle, fUnicode)
    HWND handle
    BOOL fUnicode
CODE:
    RETVAL =  MonthCal_SetUnicodeFormat(handle, fUnicode);
OUTPUT:
    RETVAL

    ###########################################################################
    ###########################################################################
    ###########################################################################

    ###########################################################################
    # (@)METHOD:BackColor([COLOR])
    # Gets or sets the background color displayed between months.
COLORREF
BackColor(handle,color=(COLORREF) -1)
    HWND handle
    COLORREF color
CODE:
    if(items == 2) {
        RETVAL = MonthCal_SetColor(handle, MCSC_BACKGROUND, color);
    } else
        RETVAL = MonthCal_GetColor(handle, MCSC_BACKGROUND);
OUTPUT:
    RETVAL

    ###########################################################################
    # (@)METHOD:BackMonthColor([COLOR])
    # Gets or sets the background color displayed within the month.
COLORREF
BackMonthColor(handle,color=(COLORREF) -1)
    HWND handle
    COLORREF color
CODE:
    if(items == 2) {
        RETVAL = MonthCal_SetColor(handle, MCSC_MONTHBK, color);
    } else
        RETVAL = MonthCal_GetColor(handle, MCSC_MONTHBK);
OUTPUT:
    RETVAL

    ###########################################################################
    # (@)METHOD:BackTitleColor([COLOR])
    # Gets or sets the background color displayed in the calendar's title.
COLORREF
BackTitleColor(handle,color=(COLORREF) -1)
    HWND handle
    COLORREF color
CODE:
    if(items == 2) {
        RETVAL = MonthCal_SetColor(handle, MCSC_TITLEBK, color);
    } else
        RETVAL = MonthCal_GetColor(handle, MCSC_TITLEBK);
OUTPUT:
    RETVAL

    ###########################################################################
    # (@)METHOD:TextColor([COLOR])
    # Gets or sets the color used to display text within a month..
COLORREF
TextColor(handle,color=(COLORREF) -1)
    HWND handle
    COLORREF color
CODE:
    if(items == 2) {
        RETVAL = MonthCal_SetColor(handle, MCSC_TEXT, color);
    } else
        RETVAL = MonthCal_GetColor(handle, MCSC_TEXT);
OUTPUT:
    RETVAL

    ###########################################################################
    # (@)METHOD:TitleTextColor([COLOR])
    # Gets or sets the color used to display text within the calendar's title.
COLORREF
TitleTextColor(handle,color=(COLORREF) -1)
    HWND handle
    COLORREF color
CODE:
    if(items == 2) {
        RETVAL = MonthCal_SetColor(handle, MCSC_TITLETEXT, color);
    } else
        RETVAL = MonthCal_GetColor(handle, MCSC_TITLETEXT);
OUTPUT:
    RETVAL

    ###########################################################################
    # (@)METHOD:TrailingTextColor([COLOR])
    # Gets or sets the color used to display header day and trailing day text.
    # Header and trailing days are the days from the previous and following 
    # months that appear on the current month calendar.
COLORREF
TrailingTextColor(handle,color=(COLORREF) -1)
    HWND handle
    COLORREF color
CODE:
    if(items == 2) {
        RETVAL = MonthCal_SetColor(handle, MCSC_TRAILINGTEXT, color);
    } else
        RETVAL = MonthCal_GetColor(handle, MCSC_TRAILINGTEXT);
OUTPUT:
    RETVAL

    ###########################################################################
    # (@)METHOD:GetRangeMin()
    # Retrieves the minimum allowable date set for a month calendar control
void
GetRangeMin(handle)
    HWND handle
PREINIT:
    SYSTEMTIME st[2];
    DWORD ret;
PPCODE:
    ret = MonthCal_GetRange(handle, &st);
    if(GIMME == G_ARRAY) {
        if (ret & GDTR_MIN) {
            EXTEND(SP, 4);
            XST_mIV(0, st[0].wYear);
            XST_mIV(1, st[0].wMonth);
            XST_mIV(2, st[0].wDay);
            XST_mIV(3, st[0].wDayOfWeek);
            XSRETURN(4);
        }
        else {
            XSRETURN_UNDEF;
        }
    } else {
        EXTEND(SP, 1);
        XST_mIV(0, ret & GDTR_MIN);
        XSRETURN(1);
    }

    ###########################################################################
    # (@)METHOD:GetRangeMax()
    # Retrieves the maximum allowable date set for a month calendar control
void
GetRangeMax(handle)
    HWND handle
PREINIT:
    SYSTEMTIME st[2];
    DWORD ret;
PPCODE:
    ret = MonthCal_GetRange(handle, &st);
    if(GIMME == G_ARRAY) {
        if (ret & GDTR_MAX) {
            EXTEND(SP, 4);
            XST_mIV(0, st[1].wYear);
            XST_mIV(1, st[1].wMonth);
            XST_mIV(2, st[1].wDay);
            XST_mIV(3, st[1].wDayOfWeek);
            XSRETURN(4);
        }
        else {
            XSRETURN_UNDEF;
        }
    } else {
        EXTEND(SP, 1);
        XST_mIV(0, ret & GDTR_MAX);
        XSRETURN(1);
    }

    ###########################################################################
    # (@)METHOD:SetRangeMin(YEAR, MONTH, DAY)
    # Sets the minimum allowable date for a month calendar control.
BOOL
SetRangeMin(handle, yearmin, monmin, daymin)
    HWND handle
    int yearmin
    int monmin
    int daymin
PREINIT:
    SYSTEMTIME st[2];
CODE:
    ZeroMemory(&st, sizeof(SYSTEMTIME) * 2);
    st[0].wYear   = yearmin;
    st[0].wDay    = daymin;
    st[0].wMonth  = monmin;
    RETVAL = MonthCal_SetRange(handle, GDTR_MIN, &st);
OUTPUT:
    RETVAL

    ###########################################################################
    # (@)METHOD:SetRangeMax(YEAR, MONTH, DAY)
    # Sets the maximum allowable date for a month calendar control.
BOOL
SetRangeMax(handle, yearmax, monmax, daymax)
    HWND handle
    int yearmax
    int monmax
    int daymax
PREINIT:
    SYSTEMTIME st[2];
CODE:
    ZeroMemory(&st, sizeof(SYSTEMTIME) * 2);
    st[1].wYear   = yearmax;
    st[1].wDay    = daymax;
    st[1].wMonth  = monmax;

    RETVAL = MonthCal_SetRange(handle, GDTR_MAX, &st);
OUTPUT:
    RETVAL

