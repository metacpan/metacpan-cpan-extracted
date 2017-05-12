    /*
    ###########################################################################
    # (@)PACKAGE:Win32::GUI::Tooltip
    #
    # $Id: Tooltip.xs,v 1.11 2010/04/08 21:26:48 jwgui Exp $
    #
    ###########################################################################
    */

#include "GUI.h"

void 
Tooltip_onPreCreate(NOTXSPROC LPPERLWIN32GUI_CREATESTRUCT perlcs) {

    perlcs->cs.lpszClass = TOOLTIPS_CLASS;
    perlcs->cs.style = TTS_ALWAYSTIP;
    perlcs->cs.dwExStyle = WS_EX_TOPMOST;
}

BOOL
Tooltip_onParseOption(NOTXSPROC char *option, SV* value, LPPERLWIN32GUI_CREATESTRUCT perlcs) {
    BOOL retval = TRUE;

    if BitmaskOptionValue("-alwaystip", perlcs->cs.style, TTS_ALWAYSTIP)
    } else if BitmaskOptionValue("-noprefix", perlcs->cs.style, TTS_NOPREFIX )    
    } else if BitmaskOptionValue("-noanimate", perlcs->cs.style, TTS_NOANIMATE )    
    } else if BitmaskOptionValue("-noface", perlcs->cs.style, TTS_NOFADE )    
    } else if BitmaskOptionValue("-balloon", perlcs->cs.style, TTS_BALLOON )    
    } else retval= FALSE;

    return retval;
}

void 
Tooltip_onPostCreate(NOTXSPROC HWND myhandle, LPPERLWIN32GUI_CREATESTRUCT perlcs) {

    if(perlcs->clrForeground != CLR_INVALID) {
        SendMessage(myhandle, TTM_SETTIPTEXTCOLOR, (WPARAM) perlcs->clrForeground, (LPARAM) 0);
        perlcs->clrForeground = CLR_INVALID;  // Don't Store
    }
    if(perlcs->clrBackground != CLR_INVALID) {
        SendMessage(myhandle, TTM_SETTIPBKCOLOR, (WPARAM) perlcs->clrBackground, (LPARAM) 0);
        perlcs->clrBackground = CLR_INVALID;  // Don't Store
    }
}

BOOL
Tooltip_onParseEvent(NOTXSPROC char *name, int* eventID) {

    BOOL retval = TRUE;

         if Parse_Event("NeedText",    PERLWIN32GUI_NEM_CONTROL1)
    else if Parse_Event("Pop",         PERLWIN32GUI_NEM_CONTROL2)
    else if Parse_Event("Show",        PERLWIN32GUI_NEM_CONTROL3)
    else retval = FALSE;

    return retval;
}

int
Tooltip_onEvent (NOTXSPROC LPPERLWIN32GUI_USERDATA perlud, UINT uMsg, WPARAM wParam, LPARAM lParam) {

    int PerlResult = 1;

    if ( uMsg == WM_NOTIFY ) {

        LPNMHDR notify = (LPNMHDR) lParam;

        switch(notify->code) {

        case TTN_NEEDTEXT :
            /*
             * (@)EVENT:NeedText(TOOL,FLAG)
             * Sent when a tooltip window needs to get the text for a tool
             * created with C<< -needtext => 1 >>.
             *
             * TOOL is the identifier of the tool: it is the window handle
             * of the tool if FLAG is TRUE, otherwise it is the tool ID.
             *
             * Return a string from the event handler containing the text
             * to be displayed.
             * (@)APPLIES_TO:Tooltip
             */
            {
            LPTOOLTIPTEXT lptt = (LPTOOLTIPTEXT) lParam;
            lptt->lpszText = (LPTSTR) DoEvent_NeedText(NOTXSCALL perlud, PERLWIN32GUI_NEM_CONTROL1, "NeedText",
                    PERLWIN32GUI_ARGTYPE_LONG, (LONG)lptt->hdr.idFrom,
                    PERLWIN32GUI_ARGTYPE_LONG, (LONG)(lptt->uFlags & TTF_IDISHWND ? 1 : 0),
                    -1);

            PerlResult = 1;
            }
            break;
        case TTN_POP:
            /*
             * (@)EVENT:Pop(TOOL,FLAG)
             * Sent whenever a tooltip window has just been hidden
             *
             * TOOL is the identifier of the tool: it is the window handle
             * of the tool if FLAG is TRUE, otherwise it is the tool ID.
             * (@)APPLIES_TO:Tooltip
             */
            PerlResult = DoEvent(NOTXSCALL perlud, PERLWIN32GUI_NEM_CONTROL2, "Pop",
                    PERLWIN32GUI_ARGTYPE_LONG, (LONG) wParam,
                    PERLWIN32GUI_ARGTYPE_LONG, (LONG)(IsWindow((HWND)wParam) ? 1 : 0),
                    -1);
            break;
        case TTN_SHOW:
            /*
             * (@)EVENT:Show(TOOL,FLAG)
             * Sent whenever a tooltip window is just about to be displayed
             *
             * TOOL is the identifier of the tool: it is the window handle
             * of the tool if FLAG is TRUE, otherwise it is the tool ID.
             * (@)APPLIES_TO:Tooltip
             */
            PerlResult = DoEvent(NOTXSCALL perlud, PERLWIN32GUI_NEM_CONTROL3, "Show",
                    PERLWIN32GUI_ARGTYPE_LONG, (LONG) wParam,
                    PERLWIN32GUI_ARGTYPE_LONG, (LONG)(IsWindow((HWND)wParam) ? 1 : 0),
                    -1);
            break;
        }
    }

    return PerlResult;
}

/* Given an SV* that we expect to be a TOOL (see documentation)
 * populate the hwnd and uId members of the passed TOOLINFO
 * structure
 */
void
ToolInfoFromTool(NOTXSPROC HWND handle, SV* tool, TOOLINFO *ti) {
    AV*  array;
    I32  alen;
    SV** value;

    if(SvROK(tool) && SvTYPE(SvRV(tool)) == SVt_PVAV) {
        /* Tool is an array reference */
        array = (AV*)SvRV(tool);
        alen  = av_len(array);
        if(alen > -1) {
            value = av_fetch(array, 0, 0);
            if(value) {
                ti->hwnd = handle_From(NOTXSCALL *value);
            } else {
                CROAK("Problem with TOOL array reference, index 0");
            }
            if(alen > 0) {
                value = av_fetch(array, 1, 0);
                if(value) {
                    ti->uId = INT2PTR(UINT_PTR, SvIV(*value));
                } else {
                    CROAK("Problem with TOOL array reference, index 1");
                }
            } else {
                ti->uId = (UINT_PTR)(ti->hwnd);
            }
        } else {
            CROAK("TOOL array refence is empty");
        }
    } else {
        /* Tool is Window or ID */
        /* This is broken, as there is nothing stopping IDs and window
         * handles clashing, but kept for
         * (1) backwards compatability
         * (2) allowing the most common simple case of WINDOW */
        ti->uId  = (UINT_PTR)(handle_From(NOTXSCALL tool));
        if(IsWindow((HWND)ti->uId)) {
            ti->hwnd = (HWND)ti->uId;
        } else {
            ti->hwnd = (HWND)GetWindowLongPtr(handle, GWLP_HWNDPARENT);
        }
    }

    return;
}

MODULE = Win32::GUI::Tooltip        PACKAGE = Win32::GUI::Tooltip

PROTOTYPES: DISABLE

#pragma message( "*** PACKAGE Win32::GUI::Tooltip..." )

    ###########################################################################
    # (@)METHOD:Activate([FLAG=TRUE])
    # Activates or deactivates a tooltip control. A deactivated tooltip does
    # not show it's window when the mouse hovers over a tool.
LRESULT
Activate(handle, value=TRUE)
    HWND handle
    WPARAM value
CODE:
    RETVAL = SendMessage(handle, TTM_ACTIVATE, value, 0);
OUTPUT:
    RETVAL

    ###########################################################################
    # (@)METHOD:AddTool(@OPTIONS)
    # (@)METHOD:Add(@OPTIONS)
    # Registers a tool with a Tooltip. When the house hovers over a tool, the
    # tooltip window is displayed.  A tool is identified either by a window
    # (handle) alone, or by a window (handle) and an application defined id.
    # If identified by a window (handle) alone, then the associated area for
    # the mouse to hover is the whole client area of the window, and adjusts
    # automatically if the window changes size.  Otherwise the rect
    # is fixed, as provided by the C<-rect> options (in client co-ordinates of
    # the window it is associated with) and must be adjusted manually if
    # necessary - See NewToolRect().
    #
    # B<@OPTIONS>:
    #  -window => HANDLE (default: owner window of tooltip control)
    #     Window object or window handle for the tool.
    #  -id => ID
    #     application set ID for the tool.
    #
    #  -rect => [LEFT,TOP,RIGHT,BOTTOM] (defult: client rect of -window)
    #     Area of the tool (ignored unless ID is provided)
    #  -text   => STRING or ID
    #    String containd the Tool text, or a resource ID (see -hinst)
    #  -hinst  => HINSTANCE
    #    If -text contains a resource ID, then -hinst gives the instance
    #    handle from which the string resource is loaded.  Ignored otherwise.
    #  -needtext => 0/1 (default: 0)
    #     Use NeedText Event. Don't mix this and -text.
    #
    #  -flags  => FLAGS
    #     Set of TTF_ bit flags.  Better set using these options:
    #       -absolute => 0/1 (default: 0)
    #          Use with -track.  Position the window at the co_ordinates
    #          set using the TrackPosition() method.
    #       -centertip => 0/1 (default: 0)
    #          Center the window below the tool.
    #       -idishwnd => 0/1 (default: 0 if -id used, 1 otherwise)
    #          indicates that the tool applies to the whole window.
    #       -rtlreading => 0/1 (default: 0)
    #          indicates that text will be rendered in the opposite direction
    #          to text in the parent window
    #       -subclass => 0/1 (default: 0 if -track is used, 1 otherwise)
    #          the tooltip control will arrange to get mouse messages from the
    #          winodw containing the tool automatically.  If this option is not
    #          set then the application must relay mouse messages itself.
    #       -track => 0/1 (default: 0)
    #          Positions the ToolTip window next to the tool to which it
    #          corresponds and moves the window according to coordinates
    #          supplied by the TrackPosition() method. You must activate
    #          this type of tool using the TrackActivate() method. 
    #       -transparent => 0/1 (default: 0)
    #          Causes the ToolTip control to forward mouse event messages to the
    #          parent window. This is limited to mouse events that occur within
    #          the bounds of the ToolTip window.
    #
    # Returns true on success, false on failure.
BOOL
AddTool(handle,...)
    HWND handle
ALIAS:
    Win32::GUI::Tooltip::Add = 1
PREINIT:
    TOOLINFO ti;
CODE:
    ZeroMemory(&ti, sizeof(TOOLINFO));
    ti.cbSize = sizeof(TOOLINFO);
    ti.hwnd = (HWND) GetWindowLongPtr(handle, GWLP_HWNDPARENT);
    ParseTooltipOptions(NOTXSCALL sp, mark, ax, items, 1, &ti);
    RETVAL = SendMessage(handle, TTM_ADDTOOL, 0, (LPARAM) &ti);
OUTPUT:
    RETVAL

    ###########################################################################
    # (@)METHOD:AdjustRect(LEFT, TOP, RIGHT, BOTTOM, [LARGER=1])
    # Adjust either a wanted text rect to a window rect (if C<LARGER = 1>) or
    # a window rect to a text rect (if C<LARGER = 0>).
    #
    # C<LEFT>, C<TOP>, C<RIGHT>, C<BOTTOM> identify the corners to the rect to
    # convert.
    #
    # C<LARGER> identifies whether the provided rect is a text rect (to be made
    # larger) if true, or a window rect otherwise.
    #
    # Returns a 4-element list containing the adjusted left, top, right and
    # bottom co-ordinates of the window on success, or an empty list on failure.
void Adjustrect(handle, left, top, right, bottom, larger=1)
    HWND handle
    LONG left
    LONG top
    LONG right
    LONG bottom
    BOOL larger
PREINIT:
    RECT r;
CODE:
    r.left   = left;
    r.top    = top;
    r.right  = right;
    r.bottom = bottom;

    if(SendMessage(handle,TTM_ADJUSTRECT,(WPARAM)larger,(LPARAM)&r)) {
        EXTEND(SP, 4);
        XST_mIV(0, r.left);
        XST_mIV(1, r.top);
        XST_mIV(2, r.right);
        XST_mIV(3, r.bottom);
        XSRETURN(4);
    }
    XSRETURN_EMPTY;

    ###########################################################################
    # (@)METHOD:DelTool(TOOL)
    # (@)METHOD:Del(TOOL)
    # Removes a tool from a Tooltip.
    #
    # C<TOOL> identifies the tool to use to calculate the window size.
    # C<TOOL> may be one of the following:
    #
    #   ID           - only for backwards compatibility with Win32::GUI v1.03
    #                  and earlier. A tool id identifying a tool that occupies
    #                  part of a window. The associated window defaults to the
    #                  owner window of the tooltip control, as for the default
    #                  for the -window option of the AddTool() method.
    #                  See AddTool().
    #   WINDOW       - a window object or window handle, identifying a tool
    #                  that occupies the whole window.
    #   [WINDOW]     - an array reference containing a window object or window
    #                  handle, identifying a tool that occupies the whole
    #                  window.
    #   [WINDOW, ID] - an array reference containing a window object or window
    #                  handle and a tool id, identifying a tool that occupies
    #                  part of a window.
    #
    # C<WINDOW> and/or C<ID> are the values used for the C<-window> and/or <-id>
    # options used with the AddTool() method.  See AddTool().
BOOL
DelTool(handle,tool)
    HWND handle
    SV*  tool
ALIAS:
    Win32::GUI::Tooltip::Del = 1
PREINIT:
    TOOLINFO ti;
CODE:
    ZeroMemory(&ti, sizeof(TOOLINFO));
    ti.cbSize = sizeof(TOOLINFO);
    ToolInfoFromTool(NOTXSCALL handle, tool, &ti);
    RETVAL = SendMessage(handle, TTM_DELTOOL, 0, (LPARAM) &ti);
OUTPUT:
    RETVAL

    ###########################################################################
    # (@)METHOD:EnumTools(ENUM_ID, [BUFSIZE=0])
    # Retrieves the information for a tool in a tooltip control, identified by
    # an enumerated number C<ENUM_ID>, starting at 0. 
    #
    # Returns a list of options and values on success, or an empty list on
    # failure (if C<ENUM_ID> > GetToolCount()-1).  For details of the possible
    # options see AddTool().
    #
    # B<BUFSIZE> sets the size of the buffer for retrieving the text associated
    # with the tool.  By default this is zero, and the text is not retrieved.
    # As there is no way to automatically determine the size of the buffer
    # required, this is a potential security hole, as the text may overrun
    # the size of the buffer provided.  B<Only use this if you really need to
    # find out the text, and are prepared to live with the consequences>.
    #
    # Example:
    #
    #    my $tt = Win32::GUI::Tooltip->new( ... );
    #    ....
    #    require Data::Dump;
    #    my $i=0;
    #    while(my %h = $tt->EnumTools($i)) {
    #      print "TOOL:$i\n";
    #      print Data::Dump::dump(\%h), "\n";
    #      ++$i;
    #    }
    #    my $j = $tt->GetToolCount()-1;
    #
    # Or:
    #
    #    for my $k (0 .. $j) {
    #      my %h = $tt->EnumTools($k);
    #      print "TOOL:$k\n";
    #      print Data::Dump::dump(\%h), "\n";
    #    }
void
EnumTools(handle, enum_id, bufsize=0)
    HWND handle
    HWND enum_id
    int  bufsize
PREINIT:
    TOOLINFO ti;
    int count = 0;
    LPSTR tip = NULL;
    AV* rect;
CODE:
    ZeroMemory(&ti, sizeof(TOOLINFO));
    ti.cbSize = sizeof(TOOLINFO);
    if (bufsize > 0) {
        Newz(0, tip, bufsize, CHAR);
        ti.lpszText = tip;
    }
    if (SendMessage(handle, TTM_ENUMTOOLS, (WPARAM) enum_id, (LPARAM) &ti)) {
        if(tip) {
            /* ensure tip is NULL terminated, even if we overran the buffer
             * to minimise damage - of course it may already be too late
             */
            tip[bufsize-1] = 0;
        }
        EXTEND(SP, 12);
        XST_mPV(count++, "-window");
        if(ti.uFlags & TTF_IDISHWND) {
            XST_mIV(count++, PTR2IV(ti.uId));
        } else {
            XST_mIV(count++, PTR2IV(ti.hwnd));
            XST_mPV(count++, "-id");
            XST_mIV(count++, ti.uId);
            XST_mPV(count++, "-rect");
            rect = newAV();
            av_push(rect,newSViv(ti.rect.left));
            av_push(rect,newSViv(ti.rect.top));
            av_push(rect,newSViv(ti.rect.right));
            av_push(rect,newSViv(ti.rect.bottom));
            ST(count++) = sv_2mortal(newRV_noinc((SV*)rect));
        }
        if (ti.lpszText != NULL) {
            if (ti.lpszText == LPSTR_TEXTCALLBACK) {
                XST_mPV(count++, "-needtext");
                XST_mIV(count++, 1);
            } else if (IS_INTRESOURCE(ti.lpszText)) {
                XST_mPV(count++, "-text");
                XST_mIV(count++, PTR2IV(ti.lpszText));
                XST_mPV(count++, "-hinst");
                XST_mIV(count++, PTR2IV(ti.hinst));
            } else {
                XST_mPV(count++, "-text");
                XST_mPV(count++, ti.lpszText);
            }
        }
        XST_mPV(count++, "-flag");  /* TODO: Decode flags? */
        XST_mIV(count++, ti.uFlags);
    }
    if(tip)
        Safefree(tip);
    XSRETURN(count);

    ###########################################################################
    # (@)METHOD:GetBubbleSize(TOOL)
    # Retrieves the width and height of a tooltip control for a given tool.
    #
    # C<TOOL> identifies the tool to use to calculate the window size.
    # C<TOOL> may be one of the following:
    #
    #   ID           - only for backwards compatibility with Win32::GUI v1.03
    #                  and earlier. A tool id identifying a tool that occupies
    #                  part of a window. The associated window defaults to the
    #                  owner window of the tooltip control, as for the default
    #                  for the -window option of the AddTool() method.
    #                  See AddTool().
    #   WINDOW       - a window object or window handle, identifying a tool
    #                  that occupies the whole window.
    #   [WINDOW]     - an array reference containing a window object or window
    #                  handle, identifying a tool that occupies the whole
    #                  window.
    #   [WINDOW, ID] - an array reference containing a window object or window
    #                  handle and a tool id, identifying a tool that occupies
    #                  part of a window.
    #
    # C<WINDOW> and/or C<ID> are the values used for the C<-window> and/or <-id>
    # options used with the AddTool() method.  See AddTool().
    #
    # Returns a 2-element list containing the width and height of the tooltip
    # window on success, or an empty list on failure.
void GetBubbleSize(handle, tool)
    HWND handle
    SV* tool
PREINIT:
    TOOLINFO ti;
    LRESULT r;
CODE:
    ZeroMemory(&ti, sizeof(TOOLINFO));
    ti.cbSize = sizeof(TOOLINFO);
    ToolInfoFromTool(NOTXSCALL handle, tool, &ti);

    if(SendMessage(handle,TTM_GETTOOLINFO,0,(LPARAM)&ti)) {
        if(r = SendMessage(handle,TTM_GETBUBBLESIZE,0,(LPARAM)&ti)) {  /* TODO: why crash? */
            EXTEND(SP, 2);
            XST_mIV(0, LOWORD(r));  /* width */
            XST_mIV(1, HIWORD(r));  /* height */
            XSRETURN(2);
        }
    }
    XSRETURN_EMPTY;

    ###########################################################################
    # (@)METHOD:GetCurrentTool([BUFSIZE=0])
    # Retrieves the information for the current tool (the one being displayed)
    # in a tooltip control.
    #
    # Returns a list of options and values on success, or an empty list on
    # failure (if there is no current tool).  For details of the possible
    # options see AddTool().
    #
    # B<BUFSIZE> sets the size of the buffer for retrieving the text associated
    # with the tool.  By default this is zero, and the text is not retrieved.
    # As there is no way to automatically determine the size of the buffer
    # required, this is a potential security hole, as the text may overrun
    # the size of the buffer provided.  B<Only use this if you really need to
    # find out the text, and are prepared to live with the consequences>.
void
GetCurrentTool(handle, bufsize=0)
    HWND handle
    int  bufsize
PREINIT:
    TOOLINFO ti;
    int count = 0;
    LPSTR tip = NULL;
    AV* rect;
CODE:
    ZeroMemory(&ti, sizeof(TOOLINFO));
    ti.cbSize = sizeof(TOOLINFO);
    if (bufsize > 0) {
        Newz(0, tip, bufsize, CHAR);
        ti.lpszText = tip;
    }
    if (SendMessage(handle, TTM_GETCURRENTTOOL, (WPARAM) 0, (LPARAM) &ti)) {
        if(tip) {
            /* ensure tip is NULL terminated, even if we overran the buffer
             * to minimise damage - of course it may already be too late
             */
            tip[bufsize-1] = 0;
        }
        EXTEND(SP, 12);
        XST_mPV(count++, "-window");
        if(ti.uFlags & TTF_IDISHWND) {
            XST_mIV(count++, PTR2IV(ti.uId));
        } else {
            XST_mIV(count++, PTR2IV(ti.hwnd));
            XST_mPV(count++, "-id");
            XST_mIV(count++, ti.uId);
            XST_mPV(count++, "-rect");
            rect = newAV();
            av_push(rect,newSViv(ti.rect.left));
            av_push(rect,newSViv(ti.rect.top));
            av_push(rect,newSViv(ti.rect.right));
            av_push(rect,newSViv(ti.rect.bottom));
            ST(count++) = sv_2mortal(newRV_noinc((SV*)rect));
        }
        if (ti.lpszText != NULL) {
            if (ti.lpszText == LPSTR_TEXTCALLBACK) {
                XST_mPV(count++, "-needtext");
                XST_mIV(count++, 1);
            } else if (IS_INTRESOURCE(ti.lpszText)) {
                XST_mPV(count++, "-text");
                XST_mIV(count++, PTR2IV(ti.lpszText));
                XST_mPV(count++, "-hinst");
                XST_mIV(count++, PTR2IV(ti.hinst));
            } else {
                XST_mPV(count++, "-text");
                XST_mPV(count++, ti.lpszText);
            }
        }
        XST_mPV(count++, "-flag");  /* TODO: Decode flags? */
        XST_mIV(count++, ti.uFlags);
    }
    if(tip)
        Safefree(tip);
    XSRETURN(count);

    ###########################################################################
    # (@)METHOD:GetDelayTime([FLAG=TTDT_INITIAL])
    # Retrieves the initial, pop-up, and reshow durations currently set for a
    # tooltip control.
    #
    # B<FLAG> : Which duration value to retrieve.
    #
    #   TTDT_RESHOW  = 1 : Length of time it takes for subsequent tooltip
    #                      windows to appear as the pointer moves from one
    #                      tool to another.
    #   TTDT_AUTOPOP = 2 : Length of time the tooltip window remains visible
    #                      if the pointer is stationary within a tool's
    #                      bounding rectangle.
    #   TTDT_INITIAL = 3 : Length of time the pointer must remain stationary
    #                      within a tool's bounding rectangle before the
    #                      tooltip window appears.
    #
    # Return value is the requested duration in milliseconds.
LRESULT
GetDelayTime(handle,flag=TTDT_INITIAL)
    HWND handle
    WPARAM flag
CODE:
    RETVAL = SendMessage(handle, TTM_GETDELAYTIME, flag, 0);
OUTPUT:
    RETVAL

    ###########################################################################
    # (@)METHOD:GetMargin()
    # Retrieves the top, left, bottom, and right margins set for a tooltip
    # window. A margin is the distance, in pixels, between the tooltip window
    # border and the text contained within the tooltip window. 
    #
    # Returns a 4-element list containing the left, top, right and bottom
    # marign values in pixels.
void
GetMargin(handle)
    HWND handle
PREINIT:
    RECT rect;
CODE:
    SendMessage(handle, TTM_GETMARGIN, 0, (LPARAM) &rect);
    EXTEND(SP, 4);
    XST_mIV(0, rect.left);
    XST_mIV(1, rect.top);
    XST_mIV(2, rect.right);
    XST_mIV(3, rect.bottom);
    XSRETURN(4);

    ###########################################################################
    # (@)METHOD:GetMaxTipWidth()
    # Retrieves the maximum width for a tooltip window.
    #
    # Returns the maximum width in pixels, or -1 if no maximum width has been
    # set.
INT
GetMaxTipWidth(handle)
    HWND handle
CODE:
    RETVAL = (INT)SendMessage(handle, TTM_GETMAXTIPWIDTH, 0, 0);
OUTPUT:
    RETVAL

    ###########################################################################
    # (@)METHOD:GetText(TOOL, [BUFSIZE=0])
    # Retrieves the text associated with a tool.
    #
    # C<TOOL> identifies the tool whose text is retrieved.
    # C<TOOL> may be one of the following:
    #
    #   ID           - only for backwards compatibility with Win32::GUI v1.03
    #                  and earlier. A tool id identifying a tool that occupies
    #                  part of a window. The associated window defaults to the
    #                  owner window of the tooltip control, as for the default
    #                  for the -window option of the AddTool() method.
    #                  See AddTool().
    #   WINDOW       - a window object or window handle, identifying a tool
    #                  that occupies the whole window.
    #   [WINDOW]     - an array reference containing a window object or window
    #                  handle, identifying a tool that occupies the whole
    #                  window.
    #   [WINDOW, ID] - an array reference containing a window object or window
    #                  handle and a tool id, identifying a tool that occupies
    #                  part of a window.
    #
    # C<WINDOW> and/or C<ID> are the values used for the C<-window> and/or <-id>
    # options used with the AddTool() method.  See AddTool().
    #
    # B<BUFSIZE> sets the size of the buffer for retrieving the text associated
    # with the tool.  By default this is zero, and the text is not retrieved.
    # As there is no way to automatically determine the size of the buffer
    # required, this is a potential security hole, as the text may overrun
    # the size of the buffer provided.  B<Only use this if you really need to
    # find out the text, and are prepared to live with the consequences>.
    # Returns the text associated with the tooltip (if any, and
    # C<BUFSIZE> > 0), otherwise FALSE.
void
GetText(handle, tool, bufsize=0)
    HWND handle
    SV*  tool
    int  bufsize
PREINIT:
    TOOLINFO ti;
    LPSTR tip = NULL;
CODE:
    ZeroMemory(&ti, sizeof(TOOLINFO));
    ti.cbSize = sizeof(TOOLINFO);
    ToolInfoFromTool(NOTXSCALL handle, tool, &ti);

    if (bufsize > 0) {
        Newz(0, tip, bufsize, CHAR);
        ti.lpszText = tip;
    } else {
        W32G_WARN("Calling GetText with a zero buffersize won't do anything useful");
    }

    SendMessage(handle, TTM_GETTEXT, 0, (LPARAM) &ti);

    if(tip) {
        /* ensure tip is NULL terminated, even if we overran the buffer
         * to minimise damage - of course it may already be too late
         */
        tip[bufsize-1] = 0;
    }

    EXTEND(SP, 1);
    if (ti.lpszText != NULL) {
        if (ti.lpszText == LPSTR_TEXTCALLBACK) {
            /* Don't get here: needtext is called and string returned */
        } else if (IS_INTRESOURCE(ti.lpszText)) {
            /* TODO: handle resource id, if necessary */
            W32G_WARN("Resource identifiers not handled - please report this");
        } else {
            XST_mPV(0, ti.lpszText);
        }
    } else {
        XST_mNO(0); /* 0 in numeric context, empty string in string context */
    }
    if(tip)
        Safefree(tip);
    XSRETURN(1);

    ###########################################################################
    # (@)METHOD:GetTipBkColor()
    # Retrieves the background color in a tooltip window.
COLORREF
GetTipBkColor(handle)
    HWND handle
CODE:
    RETVAL = (COLORREF) SendMessage(handle, TTM_GETTIPBKCOLOR, 0, 0);
OUTPUT:
    RETVAL

    ###########################################################################
    # (@)METHOD:GetTipTextColor()
    # Retrieves the text color in a tooltip window.
COLORREF
GetTipTextColor(handle)
    HWND handle
CODE:
    RETVAL = (COLORREF) SendMessage(handle, TTM_GETTIPTEXTCOLOR, 0, 0);
OUTPUT:
    RETVAL

    ###########################################################################
    # (@)METHOD:Count()
    # (@)METHOD:GetToolCount()
    # Returns the number of tools in the Tooltip.
LRESULT
GetToolCount(handle)
    HWND handle
ALIAS:
    Win32::GUI::Tooltip::Count = 1
CODE:
    RETVAL = SendMessage(handle, TTM_GETTOOLCOUNT, 0, 0);
OUTPUT:
    RETVAL

    ###########################################################################
    # (@)METHOD:GetToolInfo(TOOL, [BUFSIZE=0])
    # Retrieves the information that a tooltip control maintains about a tool.
    #
    # C<TOOL> identifies the tool whose info is retrieved.
    # C<TOOL> may be one of the following:
    #
    #   ID           - only for backwards compatibility with Win32::GUI v1.03
    #                  and earlier. A tool id identifying a tool that occupies
    #                  part of a window. The associated window defaults to the
    #                  owner window of the tooltip control, as for the default
    #                  for the -window option of the AddTool() method.
    #                  See AddTool().
    #   WINDOW       - a window object or window handle, identifying a tool
    #                  that occupies the whole window.
    #   [WINDOW]     - an array reference containing a window object or window
    #                  handle, identifying a tool that occupies the whole
    #                  window.
    #   [WINDOW, ID] - an array reference containing a window object or window
    #                  handle and a tool id, identifying a tool that occupies
    #                  part of a window.
    #
    # C<WINDOW> and/or C<ID> are the values used for the C<-window> and/or <-id>
    # options used with the AddTool() method.  See AddTool().
    #
    # B<BUFSIZE> sets the size of the buffer for retrieving the text associated
    # with the tool.  By default this is zero, and the text is not retrieved.
    # As there is no way to automatically determine the size of the buffer
    # required, this is a potential security hole, as the text may overrun
    # the size of the buffer provided.  B<Only use this if you really need to
    # find out the text, and are prepared to live with the consequences>.
    #
    # Returns a list of options and values on success, or an empty list on
    # failure.  For details of the possible options see AddTool().
void
GetToolInfo(handle,tool, bufsize=0)
    HWND handle
    SV*  tool
    int  bufsize
PREINIT:
    TOOLINFO ti;
    int count = 0;
    LPSTR tip = NULL;
    AV* rect;
CODE:
    ZeroMemory(&ti, sizeof(TOOLINFO));
    ti.cbSize = sizeof(TOOLINFO);
    ToolInfoFromTool(NOTXSCALL handle, tool, &ti);
    if (bufsize > 0) {
        Newz(0, tip, bufsize, CHAR);
        ti.lpszText = tip;
    }
    if (SendMessage(handle, TTM_GETTOOLINFO, (WPARAM) 0, (LPARAM) &ti)) {
        if(tip) {
            /* ensure tip is NULL terminated, even if we overran the buffer
             * to minimise damage - of course it may already be too late
             */
            tip[bufsize-1] = 0;
        }
        EXTEND(SP, 12);
        XST_mPV(count++, "-window");
        if(ti.uFlags & TTF_IDISHWND) {
            XST_mIV(count++, PTR2IV(ti.uId));
        } else {
            XST_mIV(count++, PTR2IV(ti.hwnd));
            XST_mPV(count++, "-id");
            XST_mIV(count++, ti.uId);
            XST_mPV(count++, "-rect");
            rect = newAV();
            av_push(rect,newSViv(ti.rect.left));
            av_push(rect,newSViv(ti.rect.top));
            av_push(rect,newSViv(ti.rect.right));
            av_push(rect,newSViv(ti.rect.bottom));
            ST(count++) = sv_2mortal(newRV_noinc((SV*)rect));
        }
        if (ti.lpszText != NULL) {
            if (ti.lpszText == LPSTR_TEXTCALLBACK) {
                XST_mPV(count++, "-needtext");
                XST_mIV(count++, 1);
            } else if (IS_INTRESOURCE(ti.lpszText)) {
                XST_mPV(count++, "-text");
                XST_mIV(count++, PTR2IV(ti.lpszText));
                XST_mPV(count++, "-hinst");
                XST_mIV(count++, PTR2IV(ti.hinst));
            } else {
                XST_mPV(count++, "-text");
                XST_mPV(count++, ti.lpszText);
            }
        }
        XST_mPV(count++, "-flag");  /* TODO: Decode flags? */
        XST_mIV(count++, ti.uFlags);
    }
    if(tip)
        Safefree(tip);
    XSRETURN(count);

    ###########################################################################
    # (@)METHOD:HitTest(WINDOW, X, Y, [BUFSIZE=0])
    # Retrieves the information about the tool at C<X,Y> in window C<WINDOW>
    #
    # C<X> and C<Y> are in client co-ordinates of the C<WINDOW>.
    # C<WINDOW> is a window object or window handle
    #
    # B<BUFSIZE> sets the size of the buffer for retrieving the text associated
    # with the tool.  By default this is zero, and the text is not retrieved.
    # As there is no way to automatically determine the size of the buffer
    # required, this is a potential security hole, as the text may overrun
    # the size of the buffer provided.  B<Only use this if you really need to
    # find out the text, and are prepared to live with the consequences>.
    #
    # Returns a list of options and values on success, or an empty list on
    # failure (no tool at C<X,Y>).  For details of the possible options see
    # AddTool().
void
HitTest(handle,window,x,y,bufsize=0)
    HWND handle
    HWND window
    LONG x
    LONG y
    int bufsize
PREINIT:
    TTHITTESTINFO hti;
    int count = 0;
    LPSTR tip = NULL;
    AV* rect;
CODE:    
    ZeroMemory(&hti, sizeof(TTHITTESTINFO));
    hti.pt.x = x; hti.pt.y = y;
    hti.ti.cbSize = sizeof(TOOLINFO);
    hti.hwnd = window;
    if (bufsize > 0) {
        Newz(0, tip, bufsize, CHAR);
        hti.ti.lpszText = tip;
    }
    if (SendMessage(handle, TTM_HITTEST, (WPARAM) 0, (LPARAM) &hti)) {
        if(tip) {
            /* ensure tip is NULL terminated, even if we overran the buffer
             * to minimise damage - of course it may already be too late
             */
            tip[bufsize-1] = 0;
        }
        EXTEND(SP, 12);
        XST_mPV(count++, "-window");
        if(hti.ti.uFlags & TTF_IDISHWND) {
            XST_mIV(count++, PTR2IV(hti.ti.uId));
        } else {
            XST_mIV(count++, PTR2IV(hti.ti.hwnd));
            XST_mPV(count++, "-id");
            XST_mIV(count++, hti.ti.uId);
            XST_mPV(count++, "-rect");
            rect = newAV();
            av_push(rect,newSViv(hti.ti.rect.left));
            av_push(rect,newSViv(hti.ti.rect.top));
            av_push(rect,newSViv(hti.ti.rect.right));
            av_push(rect,newSViv(hti.ti.rect.bottom));
            ST(count++) = sv_2mortal(newRV_noinc((SV*)rect));
        }
        if (hti.ti.lpszText != NULL) {
            if (hti.ti.lpszText == LPSTR_TEXTCALLBACK) {
                XST_mPV(count++, "-needtext");
                XST_mIV(count++, 1);
            } else if (IS_INTRESOURCE(hti.ti.lpszText)) {
                XST_mPV(count++, "-text");
                XST_mIV(count++, PTR2IV(hti.ti.lpszText));
                XST_mPV(count++, "-hinst");
                XST_mIV(count++, PTR2IV(hti.ti.hinst));
            } else {
                XST_mPV(count++, "-text");
                XST_mPV(count++, hti.ti.lpszText);
            }
        }
        XST_mPV(count++, "-flag");  /* TODO: Decode flags? */
        XST_mIV(count++, hti.ti.uFlags);
    }
    if(tip)
        Safefree(tip);
    XSRETURN(count);

    ###########################################################################
    # (@)METHOD:NewToolRect(TOOL, LEFT, TOP, RIGHT, BOTTOM)
    # Sets a new bounding rectangle for a tool. 
    #
    # C<TOOL> identifies the tool to use to calculate the window size.
    # C<TOOL> may be one of the following:
    #
    #   ID           - only for backwards compatibility with Win32::GUI v1.03
    #                  and earlier. A tool id identifying a tool that occupies
    #                  part of a window. The associated window defaults to the
    #                  owner window of the tooltip control, as for the default
    #                  for the -window option of the AddTool() method.
    #                  See AddTool().
    #   WINDOW       - a window object or window handle, identifying a tool
    #                  that occupies the whole window.
    #   [WINDOW]     - an array reference containing a window object or window
    #                  handle, identifying a tool that occupies the whole
    #                  window.
    #   [WINDOW, ID] - an array reference containing a window object or window
    #                  handle and a tool id, identifying a tool that occupies
    #                  part of a window.
    #
    # C<WINDOW> and/or C<ID> are the values used for the C<-window> and/or <-id>
    # options used with the AddTool() method.  See AddTool().
    #
    # C<LEFT,TOP,RIGHT,BOTTOM> identifies the new tool rect.
LRESULT
NewToolRect(handle,tool,left,top,right,bottom)
    HWND handle
    SV*  tool
    LONG left
    LONG top
    LONG right
    LONG bottom
PREINIT:
    TOOLINFO ti;
CODE:
    ZeroMemory(&ti, sizeof(TOOLINFO));
    ti.cbSize = sizeof(TOOLINFO);
    ToolInfoFromTool(NOTXSCALL handle, tool, &ti);
    ti.rect.left   = left;
    ti.rect.top    = top;
    ti.rect.right  = right;
    ti.rect.bottom = bottom;
    RETVAL = SendMessage(handle, TTM_NEWTOOLRECT, (WPARAM) 0, (LPARAM) &ti);
OUTPUT:
    RETVAL

    ###########################################################################
    # (@)METHOD:Pop()
    # Removes a displayed tooltip window from view.
LRESULT
Pop(handle)
    HWND handle
CODE:
    RETVAL = SendMessage(handle, TTM_POP, 0, 0);
OUTPUT:
    RETVAL

    # TODO : TTM_RELAYEVENT (???)

    ###########################################################################
    # (@)METHOD:SetDelayTime(TIME,[FLAG=TTDT_INITIAL])
    # Sets the initial, pop-up, and reshow durations for a tooltip control. 
    #
    # B<FLAG> :
    #   TTDT_RESHOW    = 1 : Length of time it takes for subsequent tooltip
    #                        windows to appear as the pointer moves from one
    #                        tool to another. To reset the reshow duration to
    #                        it's default value set TIME to -1.
    #   TTDT_AUTOPOP   = 2 : Length of time the tooltip window remains visible
    #                        if the pointer is stationary within a tool's
    #                        bounding rectangle. To reset the pop-up duration to
    #                        it's default value set TIME to -1. 
    #   TTDT_INITIAL   = 3 : Length of time the pointer must remain stationary
    #                        within a tool's bounding rectangle before the
    #                        tooltip window appears. To reset the initial duration
    #                        to it's default value set TIME to -1. 
    #   TTDT_AUTOMATIC = 0 : Set all three delay times to default proportions. The
    #                        autopop time will be ten times the initial time and
    #                        the reshow time will be one fifth the initial time. If
    #                        this flag is set, use a positive value of TIME to
    #                        specify the initial time, in milliseconds. Set TIME to
    #                        a negative value to return all three delay times to
    #                        their default values.
LRESULT
SetDelayTime(handle,time,flag=TTDT_INITIAL)
    HWND handle
    WPARAM time
    WPARAM flag
CODE:
    RETVAL = SendMessage(handle, TTM_SETDELAYTIME, flag, (LPARAM) MAKELONG(time,0));
OUTPUT:
    RETVAL

    ###########################################################################
    # (@)METHOD:SetMargin(LEFT, TOP, RIGHT, BOTTOM)
    # Sets the left, top, right, and bottom margins for a tooltip window.
    # A margin is the distance, in pixels, between the tooltip window border
    # and the text contained within the tooltip window. 
LRESULT
SetMargin(handle,left,top,right,bottom)
    HWND handle
    int left
    int top
    int right
    int bottom
PREINIT:
    RECT myRect;
CODE:
    myRect.left   = left;
    myRect.top    = top;
    myRect.right  = right;
    myRect.bottom = bottom;
    RETVAL = SendMessage(handle, TTM_SETMARGIN, (WPARAM) 0, (LPARAM) &myRect);
OUTPUT:
    RETVAL

    ###########################################################################
    # (@)METHOD:SetMaxTipWidth(WIDTH)
    # Sets the maximum width for a tooltip window.
    #
    # The maximum ToolTip width value does not indicate a ToolTip window's
    # actual width. Rather, if a ToolTip string exceeds the maximum width, the
    # control breaks the text into multiple lines, using spaces to determine
    # line breaks. If the text cannot be segmented into multiple lines, it will
    # be displayed on a single line. The length of this line may exceed the
    # maximum ToolTip width. 
    #
    # Returns the previous maximum width (-1 if no previous maximum width
    # has been set)
INT
SetMaxTipWidth(handle,width)
    HWND handle
    WPARAM width
CODE:
    RETVAL = (INT)SendMessage(handle, TTM_SETMAXTIPWIDTH, 0, (LPARAM) width);
OUTPUT:
    RETVAL

    ###########################################################################
    # (@)METHOD:SetTipBkColor(COLOR)
    # Sets the background color in a tooltip window.
LRESULT
SetTipBkColor(handle,color)
    HWND handle
    COLORREF color
CODE:
    RETVAL = SendMessage(handle, TTM_SETTIPBKCOLOR, (WPARAM) color, 0);
OUTPUT:
    RETVAL

    ###########################################################################
    # (@)METHOD:SetTipTextColor(COLOR)
    # Sets the text color in a tooltip window.
LRESULT
SetTipTextColor(handle,color)
    HWND handle
    COLORREF color
CODE:
    RETVAL = SendMessage(handle, TTM_SETTIPTEXTCOLOR, (WPARAM) color, 0);
OUTPUT:
    RETVAL

    ###########################################################################
    # (@)METHOD:SetTitle(TITLE, [ICON])
    # Sets the title and icon for a balloon tooltip.
	#
    # Allowed values for ICON are: error, info, warning, none.
    # Defaults to 'none'.
    #
    # Returns a true value on success, a false value on failure
LRESULT
SetTitle(handle, title, icon="none")
	HWND handle
	LPCSTR title
	LPCSTR icon
PREINIT:
	UINT i;
CODE:
	if(strcmp(icon, "error") == 0) {
		i = 3;
	} else if(strcmp(icon, "warning") == 0) {
		i = 2;
	} else if(strcmp(icon, "info") == 0) {
		i = 1;
	} else if(strcmp(icon, "none") == 0) {
		i = 0;
	} else {
		W32G_WARN("Invalid icon specification (%s): using 'none'",icon);
		i = 0;
	}
	RETVAL = SendMessage(handle, TTM_SETTITLE, (WPARAM)i, (LPARAM)title);
OUTPUT:
	RETVAL

    ###########################################################################
    # (@)METHOD:SetToolInfo(@OPTIONS)
    # Sets the information that a tooltip control maintains for a tool.
    #
    # B<@OPTIONS>: See Add().
    #
    # Some internal properties of a tool are established when the tool is
    # created, and are not recomputed when the SetToolInfo() method is used.
    # If you simply using SetToolInfo(), setting the required values
    # these properties may be lost. Instead, your application should first
    # request the tool's current properties using the GetToolInfo() method,
    # then, modify the options as needed and pass them back to the ToolTip
    # control with SetToolInfo().
LRESULT
SetToolInfo(handle,...)
    HWND handle
PREINIT:
    TOOLINFO ti;
CODE:
    ZeroMemory(&ti, sizeof(TOOLINFO));
    ti.cbSize = sizeof(TOOLINFO);
    ti.hwnd = (HWND) GetWindowLongPtr(handle, GWLP_HWNDPARENT);
    ParseTooltipOptions(NOTXSCALL sp, mark, ax, items, 1, &ti);
    RETVAL = SendMessage(handle, TTM_SETTOOLINFO, 0, (LPARAM) &ti);
OUTPUT:
    RETVAL

    ###########################################################################
    # (@)METHOD:TrackActivate(TOOL, [FLAG=1])
    # Activates or deactivates a tracking tooltip. 
    # See AddTool(), C<-track> option.
    #
    # C<TOOL> identifies the tool to use to calculate the window size.
    # C<TOOL> may be one of the following:
    #
    #   ID           - only for backwards compatibility with Win32::GUI v1.03
    #                  and earlier. A tool id identifying a tool that occupies
    #                  part of a window. The associated window defaults to the
    #                  owner window of the tooltip control, as for the default
    #                  for the -window option of the AddTool() method.
    #                  See AddTool().
    #   WINDOW       - a window object or window handle, identifying a tool
    #                  that occupies the whole window.
    #   [WINDOW]     - an array reference containing a window object or window
    #                  handle, identifying a tool that occupies the whole
    #                  window.
    #   [WINDOW, ID] - an array reference containing a window object or window
    #                  handle and a tool id, identifying a tool that occupies
    #                  part of a window.
    #
    # C<WINDOW> and/or C<ID> are the values used for the C<-window> and/or <-id>
    # options used with the AddTool() method.  See AddTool().
    #
    # C<FLAG> identifies whether tracking is activated (1) or deactivated (0)
LRESULT
TrackActivate(handle,tool,flag=1)
    HWND handle
    SV*  tool
    BOOL flag
PREINIT:
    TOOLINFO ti;
CODE:
    ZeroMemory(&ti, sizeof(TOOLINFO));
    ti.cbSize = sizeof(TOOLINFO);
    ToolInfoFromTool(NOTXSCALL handle, tool, &ti);
    RETVAL = SendMessage(handle, TTM_TRACKACTIVATE, (WPARAM) flag, (LPARAM) &ti);
OUTPUT:
    RETVAL

    ###########################################################################
    # (@)METHOD:TrackPosition(X,Y)
    # Sets the position of a tracking tooltip.
    # C<X> and C<Y> are in screen co-ordinates.
    # See AddTool(), C<-track> and C<-absolute> options.
LRESULT
TrackPosition(handle,x,y)
    HWND handle
    UINT x
    UINT y
CODE:
    RETVAL = SendMessage(handle, TTM_TRACKPOSITION, 0, (LPARAM) MAKELONG(x, y));
OUTPUT:
    RETVAL

    ###########################################################################
    # (@)METHOD:Update()
    # Forces the current tool to be redrawn.
LRESULT
Update(handle)
    HWND handle
CODE:
    RETVAL = SendMessage(handle, TTM_UPDATE, 0, 0);
OUTPUT:
    RETVAL

    ###########################################################################
    # (@)METHOD:UpdateTipText(TOOL, STRING_OR_RESID, [HINSTANCE=NULL])
    # Sets the tooltip text for a tool.
    #
    # C<TOOL> identifies the tool whose text is set.
    # C<TOOL> may be one of the following:
    #
    #   ID           - only for backwards compatibility with Win32::GUI v1.03
    #                  and earlier. A tool id identifying a tool that occupies
    #                  part of a window. The associated window defaults to the
    #                  owner window of the tooltip control, as for the default
    #                  for the -window option of the AddTool() method.
    #                  See AddTool().
    #   WINDOW       - a window object or window handle, identifying a tool
    #                  that occupies the whole window.
    #   [WINDOW]     - an array reference containing a window object or window
    #                  handle, identifying a tool that occupies the whole
    #                  window.
    #   [WINDOW, ID] - an array reference containing a window object or window
    #                  handle and a tool id, identifying a tool that occupies
    #                  part of a window.
    #
    # C<WINDOW> and/or C<ID> are the values used for the C<-window> and/or <-id>
    # options used with the AddTool() method.  See AddTool().
LRESULT
UpdateTipText(handle, tool, string_or_resid, instance=NULL)
    HWND      handle
    SV*       tool
    SV*       string_or_resid
    HINSTANCE instance
PREINIT:
    TOOLINFO ti;
CODE:
    ZeroMemory(&ti, sizeof(TOOLINFO));
    ti.cbSize = sizeof(TOOLINFO);
    ToolInfoFromTool(NOTXSCALL handle, tool, &ti);
    ti.lpszText = SvIOK(string_or_resid) ?
            MAKEINTRESOURCE(SvIV(string_or_resid)) : SvPV_nolen(string_or_resid);
    ti.hinst    = instance;
    RETVAL = SendMessage(handle, TTM_UPDATETIPTEXT, 0, (LPARAM) &ti);
OUTPUT:
    RETVAL

    ###########################################################################
    # (@)INTERNAL:WindowFromPoint(X, Y)
    # Allows a subclass procedure to cause a tooltip to display text for a window
    # other than the one beneath the mouse cursor. 
    #
    # TTM_WINDOWFROMPOINT is supposed to be processed by a sub-class, not ever
    # sent: The tooltip class sends this to itself to determine the window under
    # the mouse (default implementation is simly WindowFromPoint().  A subclass
    # might (for example) want to use ChildWindowFromPoint(), so that disabled
    # windows aren't ignored, or something more complex so that a tool
    # belonging to another region is used.
    #
    # This documentation left here, to record that this message is purposely
    # not implemented as a mechanism to send this message.
