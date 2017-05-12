        /*
    ###########################################################################
    # message loops
    #
    # $Id: GUI_MessageLoops.cpp,v 1.25 2010/04/08 21:26:48 jwgui Exp $
    #
    ###########################################################################
        */

#include "GUI.h"
// #pragma optimize( "", off )

    /*
    ###########################################################################
    # (@)INTERNAL:CommonMsgLoop(hwnd, uMsg, wParam, lParam)
    # this is the message loop (WndProc) that process common messages
    # (eventmodel independent)
    */
LRESULT CommonMsgLoop(NOTXSPROC HWND hwnd, UINT uMsg, WPARAM wParam, LPARAM lParam, WNDPROC wndprocOriginal)
{
    LPPERLWIN32GUI_USERDATA perlud;
#ifdef PERLWIN32GUI_STRONGDEBUG
    printf("!XS(CommonMsgLoop) got (0x%x, 0x%x, 0x%x, 0x%x)\n", hwnd, uMsg, wParam, lParam);
#endif
    switch(uMsg) {
    case WM_PAINT:
        // Create compatible DC for window.
        // WM_PRINT into new DC with PRF_ERASEBKGND .
        // BitBlt new DC into window DC.

        perlud = (LPPERLWIN32GUI_USERDATA) GetWindowLongPtr((HWND) hwnd, GWLP_USERDATA);
        if(perlud && (perlud->dwPlStyle & PERLWIN32GUI_FLICKERFREE)) {
            WINDOWINFO pwi;
            RECT cr;
            pwi.cbSize = sizeof(WINDOWINFO);

            GetWindowInfo(hwnd,&pwi);

            LONG width  = pwi.rcClient.right - pwi.rcClient.left;
            LONG height = pwi.rcClient.bottom - pwi.rcClient.top;
            cr.left = 0;
            cr.right = width;
            cr.top = 0;
            cr.bottom = height;

            LONG offsetx = pwi.rcClient.left - pwi.rcWindow.left;
            LONG offsety = pwi.rcClient.top - pwi.rcWindow.top;

            // Get window DC:
            HDC hdc = GetDC(hwnd);
            // Create compatible DC for window:
            HDC hdc2 = CreateCompatibleDC(hdc);

            HBITMAP hbmp = CreateCompatibleBitmap(hdc, width + offsetx, height + offsety);
            HBITMAP holdbmp = (HBITMAP) SelectObject(hdc2, hbmp);

            HBRUSH bgBrush    = (HBRUSH) GetClassLongPtr (hwnd, GCLP_HBRBACKGROUND);

            cr.right  += offsetx;
            cr.bottom += offsety;
            FillRect(hdc2, &cr, bgBrush);
            // Sent WM_PRINT message to draw into new DC .
            SendMessage(hwnd, WM_PRINT, (WPARAM) hdc2, PRF_CLIENT | PRF_NONCLIENT | PRF_CHILDREN);
            // BitBlt new DC into window DC.
            BitBlt(hdc, 0, 0, width, height, hdc2, offsetx, offsety, SRCCOPY);

            SelectObject(hdc2, holdbmp);
            ValidateRect(hwnd, NULL);
            DeleteObject(hbmp);
            DeleteDC(hdc2);
            ReleaseDC(hwnd, hdc);
            return (LRESULT) 0;
        }
        break;
    case WM_ERASEBKGND:
        perlud = (LPPERLWIN32GUI_USERDATA) GetWindowLongPtr((HWND) hwnd, GWLP_USERDATA);
        if(perlud && (perlud->dwPlStyle & PERLWIN32GUI_FLICKERFREE)) {
            return (LRESULT) 1;
        }
        // If we're a window and we have a background brush, then use it
        if(perlud && perlud->hBackgroundBrush && (perlud->iClass == WIN32__GUI__WINDOW ||
                                                  perlud->iClass == WIN32__GUI__DIALOG ||
						  perlud->iClass == WIN32__GUI__SPLITTER) ) {
            // Although this looks like we paint the whole of the background
            // the HDC passed in wParam is clipped to the update region
            RECT rc;
            GetClientRect(hwnd, &rc);
            FillRect((HDC)wParam, &rc, perlud->hBackgroundBrush);
            return (LRESULT) 1;
        }
        break;
    case WM_CTLCOLOREDIT:
    case WM_CTLCOLORSTATIC:
    case WM_CTLCOLORBTN:
    case WM_CTLCOLORLISTBOX:
        {
            perlud = (LPPERLWIN32GUI_USERDATA) GetWindowLongPtr((HWND) lParam, GWLP_USERDATA);
            if( ValidUserData(perlud) ) {
                if(uMsg == WM_CTLCOLORSTATIC) {
                    if(perlud->iClass == WIN32__GUI__EDIT) // Read-only Edit control
               	        SetBkColor((HDC) wParam, GetSysColor(COLOR_BTNFACE));
                    else
                        SetBkMode((HDC) wParam, TRANSPARENT);
                }
                if(perlud->clrForeground != CLR_INVALID)
                    SetTextColor((HDC) wParam, perlud->clrForeground);
                if(perlud->clrBackground != CLR_INVALID) {
                    SetBkColor((HDC) wParam, perlud->clrBackground);
                    return ((LRESULT) perlud->hBackgroundBrush);
                }
            }

            LONG_PTR hbrBackground;
            if(hbrBackground = GetClassLongPtr((HWND)lParam, GCLP_HBRBACKGROUND))
                return ((LRESULT) hbrBackground);

            switch(uMsg) {
            case WM_CTLCOLOREDIT:
            case WM_CTLCOLORLISTBOX:
                return ((LRESULT) GetSysColorBrush(COLOR_WINDOW));
                break;
            default:
                return ((LRESULT) GetSysColorBrush(COLOR_BTNFACE));
                break;
            }
        }
        break;

    case WM_GETMINMAXINFO:
        {
            LPMINMAXINFO minmax;
            LPPERLWIN32GUI_USERDATA perlud;
            perlud = (LPPERLWIN32GUI_USERDATA) GetWindowLongPtr(hwnd, GWLP_USERDATA);
            if( ValidUserData(perlud) && !(perlud->dwPlStyle & PERLWIN32GUI_MDICHILD) ) {
                minmax = (LPMINMAXINFO) lParam;
                if(perlud->iMinWidth  != -1) minmax->ptMinTrackSize.x = (LONG) perlud->iMinWidth;
                if(perlud->iMaxWidth  != -1) minmax->ptMaxTrackSize.x = (LONG) perlud->iMaxWidth;
                if(perlud->iMinHeight != -1) minmax->ptMinTrackSize.y = (LONG) perlud->iMinHeight;
                if(perlud->iMaxHeight != -1) minmax->ptMaxTrackSize.y = (LONG) perlud->iMaxHeight;
                return 0;
            }
        }
        break;

    case WM_SETCURSOR:
        {
            WORD nHitTest = LOWORD( lParam );
            if( nHitTest == HTCLIENT ) {  // only diddle cursor in client areas
                LPPERLWIN32GUI_USERDATA perlud;
                perlud = (LPPERLWIN32GUI_USERDATA) GetWindowLongPtr((HWND) wParam, GWLP_USERDATA);
                if( ValidUserData(perlud) && perlud->hCursor != NULL ) {
                    SetCursor( perlud->hCursor );
                    return TRUE;
                }
            }
            break;
        }

    case WM_NEXTDLGCTL:
        { 
            perlud = (LPPERLWIN32GUI_USERDATA) GetWindowLongPtr(hwnd, GWLP_USERDATA);
            if( ValidUserData(perlud) && (perlud->dwPlStyle & PERLWIN32GUI_DIALOGUI) ) {
		if(LOWORD(lParam))
			SetFocus((HWND)wParam);
		else
			SetFocus(GetNextDlgTabItem(hwnd, GetFocus(), (BOOL)wParam));

		return 0;
	    }
        }
    }
#ifdef PERLWIN32GUI_STRONGDEBUG
    printf("!XS(CommonMsgLoop) returning DefWindowProc\n");
#endif

    if (wndprocOriginal != NULL) {
        return CallWindowProc((WNDPROC_CAST) wndprocOriginal, hwnd, uMsg, wParam, lParam);
    } else {
        return DefWindowProc(hwnd, uMsg, wParam, lParam);
    }
}

    /*
    ###########################################################################
    # (@)INTERNAL:WindowMsgLoop(hwnd, uMsg, wParam, lParam)
    # message loop for Main Window
    */
LRESULT CALLBACK WindowMsgLoop(HWND hwnd, UINT uMsg, WPARAM wParam, LPARAM lParam)
{
    LPPERLWIN32GUI_USERDATA perlud;
    LPPERLWIN32GUI_USERDATA childud;
    int PerlResult = 1;

#ifdef PERLWIN32GUI_STRONGDEBUG
    printf("!XS(WindowMsgLoop) got (0x%x, 0x%x, 0x%x, 0x%x)\n", hwnd, uMsg, wParam, lParam);
#endif

    /*
     * WM_CREATE && WM_NCCREATE
     * If we handle this message we are using a custom control class (See RegisterClassEx).
     */
    if(uMsg == WM_CREATE || uMsg == WM_NCCREATE)
    {
        perlud = (LPPERLWIN32GUI_USERDATA) ((CREATESTRUCT *) lParam)->lpCreateParams;
        if(perlud != NULL) {
            PERLUD_FETCH;
            SetWindowLongPtr(hwnd, GWLP_USERDATA, (LONG_PTR) perlud);
            hv_store_mg(NOTXSCALL (HV*)SvRV(perlud->svSelf), "-handle", 7, newSViv(PTR2IV(hwnd)), 0);
            SwitchBit(perlud->dwPlStyle, PERLWIN32GUI_CUSTOMCLASS, 1);  // Set Custom class flag

            // Search for an extend MsgLoop procedure (-extends option in RegisterClassEx)
            perlud->WndProc = (LWNDPROC_CAST) GetDefClassProc (NOTXSCALL ((CREATESTRUCT *) lParam)->lpszClass);
            if (perlud->WndProc) {
                return CallWindowProc((WNDPROC_CAST) perlud->WndProc, hwnd, uMsg, wParam, lParam);
            }
        }

        return DefWindowProc(hwnd, uMsg, wParam, lParam);
    }

    perlud = (LPPERLWIN32GUI_USERDATA) GetWindowLongPtr(hwnd, GWLP_USERDATA);
    if(!ValidUserData(perlud)) {
        return DefWindowProc(hwnd, uMsg, wParam, lParam);
    }
    perlud->forceResult = 0;

    PERLUD_FETCH;

    switch(uMsg) {

    case WM_COMMAND:

        /*
         * Menu command
         */
        if(HIWORD(wParam) == 0 && lParam == 0) {
           /*
            * (@)EVENT:Click()
            * Sent when the users choose a menu point.
            * (@)APPLIES_TO:Menu
            */
            PerlResult = DoEvent_Menu(NOTXSCALL hwnd, LOWORD(wParam));
        }
        /*
         * Accelerator command
         */
        else if(HIWORD(wParam) == 1 && lParam == 0) {
            /*
            * (@)EVENT:Click()
            * Sent when the users triggers an Accelerator object.
            * (@)APPLIES_TO:AcceleratorTable
            */
            PerlResult = DoEvent_Accelerator(NOTXSCALL perlud, LOWORD(wParam));
        }
        /*
         * Control command
         */
        else {
            childud = (LPPERLWIN32GUI_USERDATA) GetWindowLongPtr((HWND) lParam, GWLP_USERDATA);
            if( ValidUserData(childud) ) {
                childud->forceResult = 0;

                PerlResult = OnEvent[childud->iClass](NOTXSCALL childud, uMsg, wParam, lParam);

                if (IsWindow((HWND)lParam) && childud->avHooks != NULL)
                    DoHook(NOTXSCALL childud, (UINT) HIWORD(wParam), wParam, lParam, &PerlResult, WM_COMMAND);

                if(IsWindow((HWND)lParam) && childud->forceResult != 0) {
                    perlud->forceResult  = childud->forceResult;
                    childud->forceResult = 0;
                }
            }
        }
        break;

     case WM_NOTIFY:

        childud = (LPPERLWIN32GUI_USERDATA) GetWindowLongPtr(((LPNMHDR) lParam)->hwndFrom, GWLP_USERDATA);
        if( ValidUserData(childud) ) {
            childud->forceResult = 0;

            /* Standard notification */
            switch(((LPNMHDR) lParam)->code) {
            case NM_CLICK:
                /*
                 * (@)EVENT:Click()
                 * (@)APPLIES_TO:*
                 */
                PerlResult = DoEvent(NOTXSCALL childud, PERLWIN32GUI_NEM_CLICK, "Click", -1 );
                break;
            case NM_RCLICK:
                /*
                 * (@)EVENT:RightClick()
                 * (@)APPLIES_TO:*
                 */
                 PerlResult = DoEvent(NOTXSCALL childud, PERLWIN32GUI_NEM_RIGHTCLICK, "RightClick", -1 );
                break;
            case NM_DBLCLK:
                /*
                 * (@)EVENT:DblClick()
                 * (@)APPLIES_TO:*
                 */
                PerlResult = DoEvent(NOTXSCALL childud, PERLWIN32GUI_NEM_DBLCLICK, "DblClick", -1 );
                break;
            case NM_RDBLCLK:
                /*
                 * (@)EVENT:DblRightClick()
                 * (@)APPLIES_TO:*
                 */
                PerlResult = DoEvent(NOTXSCALL childud, PERLWIN32GUI_NEM_DBLRIGHTCLICK, "DblRightClick", -1 );
                break;
            case NM_SETFOCUS:
                /*
                 * (@)EVENT:GotFocus()
                 * (@)APPLIES_TO:*
                 */
                PerlResult = DoEvent(NOTXSCALL childud, PERLWIN32GUI_NEM_GOTFOCUS, "GotFocus", -1 );
                break;
            case NM_KILLFOCUS:
                /*
                 * (@)EVENT:LostFocus()
                 * (@)APPLIES_TO:*
                 */
                PerlResult = DoEvent(NOTXSCALL childud, PERLWIN32GUI_NEM_LOSTFOCUS, "LostFocus", -1 );
                break;
            default :
                PerlResult = OnEvent[childud->iClass](NOTXSCALL childud, uMsg, wParam, lParam);
                break;
            }

            if (IsWindow(((LPNMHDR)lParam)->hwndFrom) && childud->avHooks != NULL)
                DoHook(NOTXSCALL childud, (UINT) (((LPNMHDR) lParam)->code), wParam, lParam, &PerlResult, WM_NOTIFY);

            if (IsWindow(((LPNMHDR)lParam)->hwndFrom) && childud->forceResult != 0) {
                perlud->forceResult  = childud->forceResult;
                childud->forceResult = 0;
            }
        }
        break;

    case WM_DESTROY:
        if (perlud->WndProc)
            PerlResult = CallWindowProc((WNDPROC_CAST) perlud->WndProc, hwnd, uMsg, wParam, lParam);
        else
            PerlResult = DefWindowProc(hwnd, uMsg, wParam, lParam);
        PERLUD_FREE;
        return PerlResult;

    case WM_MOUSEMOVE:
        /*
         * (@)EVENT:MouseMove()
         * (@)APPLIES_TO:*
         */
        PerlResult = DoEvent(NOTXSCALL perlud, PERLWIN32GUI_NEM_MOUSEMOVE, "MouseMove",
            PERLWIN32GUI_ARGTYPE_LONG, GET_X_LPARAM(lParam),
            PERLWIN32GUI_ARGTYPE_LONG, GET_Y_LPARAM(lParam),
            PERLWIN32GUI_ARGTYPE_LONG, wParam,
            -1);
        break;
    case WM_LBUTTONDOWN:
        /*
         * (@)EVENT:MouseDown()
         * (@)APPLIES_TO:*
         */
        PerlResult = DoEvent(NOTXSCALL perlud, PERLWIN32GUI_NEM_LMOUSEDOWN, "MouseDown",
            PERLWIN32GUI_ARGTYPE_LONG, GET_X_LPARAM(lParam),
            PERLWIN32GUI_ARGTYPE_LONG, GET_Y_LPARAM(lParam),
            PERLWIN32GUI_ARGTYPE_LONG, wParam,
            -1);
        break;
    case WM_LBUTTONUP:
        /*
         * (@)EVENT:MouseUp()
         * (@)APPLIES_TO:*
         */
        PerlResult = DoEvent(NOTXSCALL perlud, PERLWIN32GUI_NEM_LMOUSEUP, "MouseUp",
            PERLWIN32GUI_ARGTYPE_LONG, GET_X_LPARAM(lParam),
            PERLWIN32GUI_ARGTYPE_LONG, GET_Y_LPARAM(lParam),
            PERLWIN32GUI_ARGTYPE_LONG, wParam,
            -1);
        break;
    case WM_LBUTTONDBLCLK:
        /*
         * (@)EVENT:MouseDblClick()
         * (@)APPLIES_TO:*
         */
        PerlResult = DoEvent(NOTXSCALL perlud, PERLWIN32GUI_NEM_LMOUSEDBLCLK, "MouseDblClick",
            PERLWIN32GUI_ARGTYPE_LONG, GET_X_LPARAM(lParam),
            PERLWIN32GUI_ARGTYPE_LONG, GET_Y_LPARAM(lParam),
            PERLWIN32GUI_ARGTYPE_LONG, wParam,
            -1);
        break;
    case WM_RBUTTONDOWN:
        /*
         * (@)EVENT:MouseRightDown()
         * (@)APPLIES_TO:*
         */
        PerlResult = DoEvent(NOTXSCALL perlud, PERLWIN32GUI_NEM_RMOUSEDOWN, "MouseRightDown",
            PERLWIN32GUI_ARGTYPE_LONG, GET_X_LPARAM(lParam),
            PERLWIN32GUI_ARGTYPE_LONG, GET_Y_LPARAM(lParam),
            PERLWIN32GUI_ARGTYPE_LONG, wParam,
            -1);
        break;
    case WM_RBUTTONUP:
        /*
         * (@)EVENT:MouseRightUp()
         * (@)APPLIES_TO:*
         */
        PerlResult = DoEvent(NOTXSCALL perlud, PERLWIN32GUI_NEM_RMOUSEUP, "MouseRightUp",
            PERLWIN32GUI_ARGTYPE_LONG, GET_X_LPARAM(lParam),
            PERLWIN32GUI_ARGTYPE_LONG, GET_Y_LPARAM(lParam),
            PERLWIN32GUI_ARGTYPE_LONG, wParam,
            -1);
        break;
    case WM_RBUTTONDBLCLK:
        /*
         * (@)EVENT:MouseRightDblClick()
         * (@)APPLIES_TO:*
         */
        PerlResult = DoEvent(NOTXSCALL perlud, PERLWIN32GUI_NEM_RMOUSEDBLCLK, "MouseRightDblClick",
            PERLWIN32GUI_ARGTYPE_LONG, GET_X_LPARAM(lParam),
            PERLWIN32GUI_ARGTYPE_LONG, GET_Y_LPARAM(lParam),
            PERLWIN32GUI_ARGTYPE_LONG, wParam,
            -1);
        break;
    case WM_MBUTTONDOWN:
        /*
         * (@)EVENT:MouseMiddleDown()
         * (@)APPLIES_TO:*
         */
        PerlResult = DoEvent(NOTXSCALL perlud, PERLWIN32GUI_NEM_MMOUSEDOWN, "MouseMiddleDown",
            PERLWIN32GUI_ARGTYPE_LONG, GET_X_LPARAM(lParam),
            PERLWIN32GUI_ARGTYPE_LONG, GET_Y_LPARAM(lParam),
            PERLWIN32GUI_ARGTYPE_LONG, wParam,
            -1);
        break;
    case WM_MBUTTONUP:
        /*
         * (@)EVENT:MouseMiddleUp()
         * (@)APPLIES_TO:*
         */
        PerlResult = DoEvent(NOTXSCALL perlud, PERLWIN32GUI_NEM_MMOUSEUP, "MouseMiddleUp",
            PERLWIN32GUI_ARGTYPE_LONG, GET_X_LPARAM(lParam),
            PERLWIN32GUI_ARGTYPE_LONG, GET_Y_LPARAM(lParam),
            PERLWIN32GUI_ARGTYPE_LONG, wParam,
            -1);
        break;
    case WM_MBUTTONDBLCLK:
        /*
         * (@)EVENT:MouseMiddleDblClick()
         * (@)APPLIES_TO:*
         */
        PerlResult = DoEvent(NOTXSCALL perlud, PERLWIN32GUI_NEM_MMOUSEDBLCLK, "MouseMiddleDblClick",
            PERLWIN32GUI_ARGTYPE_LONG, GET_X_LPARAM(lParam),
            PERLWIN32GUI_ARGTYPE_LONG, GET_Y_LPARAM(lParam),
            PERLWIN32GUI_ARGTYPE_LONG, wParam,
            -1);
        break;
    case WM_KEYDOWN:
        /*
         * (@)EVENT:KeyDown()
         * (@)APPLIES_TO:*
         */
        PerlResult = DoEvent(NOTXSCALL perlud, PERLWIN32GUI_NEM_KEYDOWN, "KeyDown",
            PERLWIN32GUI_ARGTYPE_LONG, lParam,
            PERLWIN32GUI_ARGTYPE_LONG, wParam,
            -1);
        break;
        /*
         * (@)EVENT:KeyUp()
         * (@)APPLIES_TO:*
         */
    case WM_KEYUP:
        PerlResult = DoEvent(NOTXSCALL perlud, PERLWIN32GUI_NEM_KEYUP, "KeyUp",
            PERLWIN32GUI_ARGTYPE_LONG, lParam,
            PERLWIN32GUI_ARGTYPE_LONG, wParam,
            -1);
        break;
        /*
         * (@)EVENT:Char()
         * (@)APPLIES_TO:*
         */
    case WM_CHAR:
        PerlResult = DoEvent(NOTXSCALL perlud, PERLWIN32GUI_NEM_CHAR, "Char",
            PERLWIN32GUI_ARGTYPE_LONG, lParam,
            PERLWIN32GUI_ARGTYPE_LONG, wParam,
            -1);
        break;
    case WM_MOUSEHOVER :
        /*
         * (@)EVENT:MouseOver()
         * (@)APPLIES_TO:*
         */
        PerlResult = DoEvent(NOTXSCALL perlud, PERLWIN32GUI_NEM_MOUSEOVER, "MouseOver", -1);
        if(PerlResult) {
            TRACKMOUSEEVENT tme;
            tme.cbSize = sizeof(TRACKMOUSEEVENT);
            tme.hwndTrack = hwnd;
            tme.dwFlags = TME_QUERY;
            if(_TrackMouseEvent( &tme )) {
                _TrackMouseEvent( &tme );
            }
        }
        break;
    case WM_MOUSELEAVE :
        /*
         * (@)EVENT:MouseOut()
         * (@)APPLIES_TO:*
         */
        PerlResult = DoEvent(NOTXSCALL perlud, PERLWIN32GUI_NEM_MOUSEOUT, "MouseOut", -1);
        if(PerlResult) {
            TRACKMOUSEEVENT tme;
            tme.cbSize = sizeof(TRACKMOUSEEVENT);
            tme.hwndTrack = hwnd;
            tme.dwFlags = TME_QUERY;
            if(_TrackMouseEvent( &tme )) {
                _TrackMouseEvent( &tme );
            }
        }
        break;

    case WM_PAINT :
    case WM_ACTIVATE :
    case WM_SYSCOMMAND:
    case WM_SIZE:
    case WM_MDIACTIVATE:
    case WM_SETFOCUS:
    case WM_INITMENU:
        PerlResult = OnEvent[perlud->iClass](NOTXSCALL perlud, uMsg, wParam, lParam);
        break;

    case WM_HSCROLL:
    case WM_VSCROLL:
        childud = (LPPERLWIN32GUI_USERDATA) GetWindowLongPtr((HWND) lParam, GWLP_USERDATA);
        if (ValidUserData(childud))
            PerlResult = OnEvent[childud->iClass](NOTXSCALL childud, uMsg, wParam, lParam);
        else
            PerlResult = OnEvent[perlud->iClass](NOTXSCALL perlud, uMsg, wParam, lParam);
        break;

    case WM_TIMER:
        /*
         * (@)EVENT:Timer()
	 * Sent when a Win32::GUI::Timer object reaches its ELAPSEd time.
	 * For OEM the event is names $name_Timer.
	 * For NEM the subroutine called is set with the parent window's
	 * -onTimer option.  There are 2 arguments passed to the NEM event handler:
	 *  the first is the parent window object, and the second is the timer's
	 *  name.
         * (@)APPLIES_TO:*
         */
        PerlResult = DoEvent_Timer (NOTXSCALL perlud, (int) wParam, PERLWIN32GUI_NEM_TIMER, "Timer", -1);
        break;

    case WM_NOTIFYICON:

        switch(lParam) {
        case WM_LBUTTONDOWN:
            /*
             * (@)EVENT:Click()
             * Sent when the user clicks the left mouse button on
             * a NotifyIcon.
             * (@)APPLIES_TO:NotifyIcon
             */
            PerlResult = DoEvent_NotifyIcon (NOTXSCALL perlud, (int) wParam, "Click", -1);
            break;
        case WM_LBUTTONDBLCLK:
            /*
             * (@)EVENT:DblClick()
             * Sent when the user double clicks the left mouse button on
             * a NotifyIcon.
             * (@)APPLIES_TO:NotifyIcon
             */
            PerlResult = DoEvent_NotifyIcon (NOTXSCALL perlud, (int) wParam, "DblClick", -1);
            break;
        case WM_RBUTTONDOWN:
            /*
             * (@)EVENT:RightClick()
             * Sent when the user clicks the right mouse button on
             * a NotifyIcon.
             * (@)APPLIES_TO:NotifyIcon
             */
            PerlResult = DoEvent_NotifyIcon (NOTXSCALL perlud, (int) wParam, "RightClick", -1);
            break;
        case WM_RBUTTONDBLCLK:
            /*
             * (@)EVENT:RightDblClick()
             * Sent when the user double clicks the right mouse button on
             * a NotifyIcon.
             * (@)APPLIES_TO:NotifyIcon
             */
            PerlResult = DoEvent_NotifyIcon (NOTXSCALL perlud, (int) wParam, "RightDblClick", -1);
            break;
        case WM_MBUTTONDOWN:
            /*
             * (@)EVENT:MiddleClick()
             * Sent when the user clicks the middle mouse button on
             * a NotifyIcon.
             * (@)APPLIES_TO:NotifyIcon
             */
            PerlResult = DoEvent_NotifyIcon (NOTXSCALL perlud, (int) wParam, "MiddleClick", -1);
            break;
        case WM_MBUTTONDBLCLK:
            /*
             * (@)EVENT:MiddleDblClick()
             * Sent when the user double clicks the middle mouse button on
             * a NotifyIcon.
             * (@)APPLIES_TO:NotifyIcon
             */
            PerlResult = DoEvent_NotifyIcon (NOTXSCALL perlud, (int) wParam, "MiddleDblClick", -1);
            break;
        default:
            /*
             * (@)EVENT:MouseEvent(MSG)
             * Sent when the user performs any other mouse event on
             * a NotifyIcon; MSG is the message code.
	     * For shell.dll greater than V6 will also fire for balloon
	     * events.
             * (@)APPLIES_TO:NotifyIcon
             */
            PerlResult = DoEvent_NotifyIcon (NOTXSCALL perlud, (int) wParam, "MouseEvent",
                PERLWIN32GUI_ARGTYPE_LONG, lParam,
                -1);
            break;
        }
        break;

    case WM_DROPFILES:
        /*
         * (@)EVENT:DropFiles(DROP)
         * Sent when the window receives dropped files.  To enable a window to
         * be a target for files dragged from a shell window, you must set the
         * window's L<-acceptfiles|Win32::GUI::Reference::Options/acceptfiles>
         * option or call C<< $win->AcceptFiles(1) >> on the window (See
         * L<AcceptFiles()|Win32::GUI::Reference::Methods/AcceptFiles>). The
         * DROP parameter is either * a Win32 drop handle (see MSDN) or a
         * L<Win32::GUI::DropFiles|Win32::GUI::DropFiles> object if you have
         * done C<use Win32::GUI::DropFiles;> somewhere in your code.
         * (@)APPLIES_TO:*
         */
        { HV *dropfiles_stash = gv_stashpv("Win32::GUI::DropFiles", 0);
          if(dropfiles_stash) { /* Win32::GUI::DropFiles is available */
            PerlResult = DoEvent(NOTXSCALL perlud, PERLWIN32GUI_NEM_DROPFILE, "DropFiles",
                         PERLWIN32GUI_ARGTYPE_SV, CreateObjectWithHandle(NOTXSCALL "Win32::GUI::DropFiles", (HWND)wParam),
                        -1);
	  } else { /* Win32::GUI::DropFiles is not available */
            PerlResult = DoEvent(NOTXSCALL perlud, PERLWIN32GUI_NEM_DROPFILE, "DropFiles",
                         PERLWIN32GUI_ARGTYPE_LONG, wParam,
                        -1);
            DragFinish((HDROP)wParam);
	  }
	}
        break;
    }

    // Hook processing
    if(IsWindow(hwnd) && perlud->avHooks != NULL) {
        DoHook(NOTXSCALL perlud, uMsg, wParam, lParam, &PerlResult,0);
    }

    // Default processing
    if(PerlResult == -1) {
        if(IsWindow(hwnd)) {
            PostMessage(hwnd, WM_EXITLOOP, (WPARAM) -1, 0);
        } else {
            PostThreadMessage(GetCurrentThreadId(), WM_EXITLOOP, (WPARAM) -1, 0);
        }
        PerlResult = 0;
    } else if (IsWindow(hwnd) && PerlResult != 0) {
        PerlResult = CommonMsgLoop(NOTXSCALL hwnd, uMsg, wParam, lParam, perlud->WndProc);
    }
    else if (IsWindow(hwnd) && perlud->forceResult != 0) {
        return perlud->forceResult;
    }

    return PerlResult;
}

    /*
    ###########################################################################
    # (@)INTERNAL:DefMDIFrameLoop(hwnd, uMsg, wParam, lParam)
    # Default message loop for Frame MDI window
    */
LRESULT CALLBACK DefMDIFrameLoop(HWND hwnd, UINT uMsg, WPARAM wParam, LPARAM lParam) {
    LPPERLWIN32GUI_USERDATA perlud;

#ifdef PERLWIN32GUI_STRONGDEBUG
    printf("!XS(DefMDIFrameLoop) got (0x%x, 0x%x, 0x%x, 0x%x)\n", hwnd, uMsg, wParam, lParam);
#endif

    perlud = (LPPERLWIN32GUI_USERDATA) GetWindowLongPtr(hwnd, GWLP_USERDATA);
    if( !ValidUserData(perlud)) {
        return DefWindowProc(hwnd, uMsg, wParam, lParam);
    }
    return DefFrameProc(hwnd, INT2PTR(HWND, perlud->dwData), uMsg, wParam, lParam);
}

    /*
    ###########################################################################
    # (@)INTERNAL:MDIFrame(hwnd, uMsg, wParam, lParam)
    # message loop for container control class
    */
LRESULT CALLBACK MDIFrameMsgLoop(HWND hwnd, UINT uMsg, WPARAM wParam, LPARAM lParam)
{

#ifdef PERLWIN32GUI_STRONGDEBUG
    printf("!XS(MDIFrameMsgLoop) got (0x%x, 0x%x, 0x%x, 0x%x)\n", hwnd, uMsg, wParam, lParam);
#endif

    /*
     * WM_CREATE && WM_NCCREATE
     * If we handle this message we are using a custom control class (See RegisterClassEx).
     */
    if (uMsg == WM_CREATE || uMsg == WM_NCCREATE)
    {
        LPPERLWIN32GUI_USERDATA perlud = (LPPERLWIN32GUI_USERDATA) ((CREATESTRUCT *) lParam)->lpCreateParams;
        if(perlud != NULL) {
            PERLUD_FETCH;
            SetWindowLongPtr(hwnd, GWLP_USERDATA, (LONG_PTR) perlud);
            hv_store_mg(NOTXSCALL (HV*)SvRV(perlud->svSelf), "-handle", 7, newSViv(PTR2IV(hwnd)), 0);
            SwitchBit(perlud->dwPlStyle, PERLWIN32GUI_CUSTOMCLASS, 1);  // Set Custom class flag
            SwitchBit(perlud->dwPlStyle, PERLWIN32GUI_MDIFRAME   , 1);  // Set MDI Frame flag
            perlud->WndProc = (LWNDPROC_CAST) DefMDIFrameLoop;          // Set DefFrameProc

            if (perlud->WndProc) {
                return CallWindowProc((WNDPROC_CAST) perlud->WndProc, hwnd, uMsg, wParam, lParam);
            }
        }

        return DefWindowProc(hwnd, uMsg, wParam, lParam);
    }

    // Call WindowMsgLoop.
    return CallWindowProc((WNDPROC_CAST) WindowMsgLoop, hwnd, uMsg, wParam, lParam);
}

    /*
    ###########################################################################
    # (@)INTERNAL:MDIClientMsgLoop(hwnd, uMsg, wParam, lParam)
    # message loop for MDI Client class
    */

LRESULT CALLBACK MDIClientMsgLoop(HWND hwnd, UINT uMsg, WPARAM wParam, LPARAM lParam)
{
    LPPERLWIN32GUI_USERDATA perlud;
    int PerlResult = 1;

#ifdef PERLWIN32GUI_STRONGDEBUG
    printf("!XS(MDIClientMsgLoop) got (0x%x, 0x%x, 0x%x, 0x%x)\n", hwnd, uMsg, wParam, lParam);
#endif

    /* Fetch perlud */
    perlud = (LPPERLWIN32GUI_USERDATA) GetWindowLongPtr(hwnd, GWLP_USERDATA);
    if( !ValidUserData(perlud)) {
        return DefWindowProc(hwnd, uMsg, wParam, lParam);
    }

    if (perlud->WndProc)
        PerlResult = CallWindowProc((WNDPROC_CAST) perlud->WndProc, hwnd, uMsg, wParam, lParam);
    else
        PerlResult = DefWindowProc(hwnd, uMsg, wParam, lParam);

    if (uMsg == WM_DESTROY) {
        PERLUD_FETCH;
        PERLUD_FREE;
    }

    return PerlResult;
}

    /*
    ###########################################################################
    # (@)INTERNAL:DefMDIChildLoop(hwnd, uMsg, wParam, lParam)
    # Default message loop for Child MDI window
    */
LRESULT CALLBACK DefMDIChildLoop (HWND hwnd, UINT uMsg, WPARAM wParam, LPARAM lParam) {

#ifdef PERLWIN32GUI_STRONGDEBUG
    printf("!XS(DefMDIChildLoop) got (0x%x, 0x%x, 0x%x, 0x%x)\n", hwnd, uMsg, wParam, lParam);
#endif
    return DefMDIChildProc(hwnd, uMsg, wParam, lParam);
}

    /*
    ###########################################################################
    # (@)INTERNAL:MDIChildMsgLoop(hwnd, uMsg, wParam, lParam)
    # message loop for MDI Child window class
    */
LRESULT CALLBACK MDIChildMsgLoop(HWND hwnd, UINT uMsg, WPARAM wParam, LPARAM lParam)
{
    /*
     * WM_CREATE && WM_NCCREATE
     * If we handle this message we are using a custom control class (See RegisterClassEx).
     */
    if (uMsg == WM_CREATE || uMsg == WM_NCCREATE)
    {
        LPMDICREATESTRUCT lpMdiCreate = (LPMDICREATESTRUCT) ((CREATESTRUCT *) lParam)->lpCreateParams;
        LPPERLWIN32GUI_USERDATA perlud = (LPPERLWIN32GUI_USERDATA) lpMdiCreate->lParam;
        if(perlud != NULL) {
            PERLUD_FETCH;
            SetWindowLongPtr(hwnd, GWLP_USERDATA, (LONG_PTR) perlud);
            hv_store_mg(NOTXSCALL (HV*)SvRV(perlud->svSelf), "-handle", 7, newSViv(PTR2IV(hwnd)), 0);
            SwitchBit(perlud->dwPlStyle, PERLWIN32GUI_CUSTOMCLASS, 1);  // Set Custom class flag
            SwitchBit(perlud->dwPlStyle, PERLWIN32GUI_MDICHILD   , 1);  // Set MDI Frame flag
            perlud->WndProc = (LWNDPROC_CAST) DefMDIChildLoop;          // Set DefMDIChildProc
            perlud->dwData = PTR2IV(hwnd);                              // For fast hwnd acces (Activate/Deactivate)
            if (perlud->WndProc) {
                return CallWindowProc((WNDPROC_CAST) perlud->WndProc, hwnd, uMsg, wParam, lParam);
            }
        }

        return DefWindowProc(hwnd, uMsg, wParam, lParam);
    }

    // Call WindowMsgLoop.
    return CallWindowProc((WNDPROC_CAST) WindowMsgLoop, hwnd, uMsg, wParam, lParam);
}

    /*
    ###########################################################################
    # (@)INTERNAL:ControlMsgLoop(hwnd, uMsg, wParam, lParam)
    # ControlMsgLoop for subclassing base control and default WNDPROC control class.
    */
LRESULT CALLBACK ControlMsgLoop(HWND hwnd, UINT uMsg, WPARAM wParam, LPARAM lParam)
{
    LPPERLWIN32GUI_USERDATA perlud;
    int PerlResult = 1;

    /*
     * WM_CREATE && WM_NCCREATE
     * If we handle this message we are using a custom control class (See RegisterClassEx).
     */
    if(uMsg == WM_CREATE || uMsg == WM_NCCREATE)
    {
        perlud = (LPPERLWIN32GUI_USERDATA) ((CREATESTRUCT *) lParam)->lpCreateParams;
        if(perlud != NULL) {
            PERLUD_FETCH;
            SetWindowLongPtr(hwnd, GWLP_USERDATA, (LONG_PTR) perlud);
            hv_store_mg(NOTXSCALL (HV*)SvRV(perlud->svSelf), "-handle", 7, newSViv(PTR2IV(hwnd)), 0);
            SwitchBit(perlud->dwPlStyle, PERLWIN32GUI_CUSTOMCLASS, 1);  // Set Custom class flag

            // Search for an extend MsgLoop procedure (-extends option in RegisterClassEx)
            perlud->WndProc = (LWNDPROC_CAST) GetDefClassProc (NOTXSCALL ((CREATESTRUCT *) lParam)->lpszClass);
            if (perlud->WndProc) {
                return CallWindowProc((WNDPROC_CAST) perlud->WndProc, hwnd, uMsg, wParam, lParam);
            }
        }

        return DefWindowProc(hwnd, uMsg, wParam, lParam);
    }

    perlud = (LPPERLWIN32GUI_USERDATA) GetWindowLongPtr(hwnd, GWLP_USERDATA);
    if( !ValidUserData(perlud)) {
        return DefWindowProc(hwnd, uMsg, wParam, lParam);
    }
    perlud->forceResult = 0;

    PERLUD_FETCH;

    switch(uMsg) {
    case WM_DESTROY :
        if (perlud->WndProc)
            PerlResult = CallWindowProc((WNDPROC_CAST) perlud->WndProc, hwnd, uMsg, wParam, lParam);
        else
            PerlResult = DefWindowProc(hwnd, uMsg, wParam, lParam);
         PERLUD_FREE;
         return PerlResult;
    case WM_TIMER:
        PerlResult = DoEvent_Timer (NOTXSCALL perlud, wParam, PERLWIN32GUI_NEM_TIMER, "Timer", -1);
        break;
    case WM_MOUSEMOVE:
        PerlResult = DoEvent(NOTXSCALL perlud, PERLWIN32GUI_NEM_MOUSEMOVE, "MouseMove",
            PERLWIN32GUI_ARGTYPE_LONG, GET_X_LPARAM(lParam),
            PERLWIN32GUI_ARGTYPE_LONG, GET_Y_LPARAM(lParam),
            PERLWIN32GUI_ARGTYPE_LONG, wParam,
            -1);
        break;
    case WM_LBUTTONDOWN:
        PerlResult = DoEvent(NOTXSCALL perlud, PERLWIN32GUI_NEM_LMOUSEDOWN, "MouseDown",
            PERLWIN32GUI_ARGTYPE_LONG, GET_X_LPARAM(lParam),
            PERLWIN32GUI_ARGTYPE_LONG, GET_Y_LPARAM(lParam),
            PERLWIN32GUI_ARGTYPE_LONG, wParam,
            -1);
        break;
    case WM_LBUTTONUP:
        PerlResult = DoEvent(NOTXSCALL perlud, PERLWIN32GUI_NEM_LMOUSEUP, "MouseUp",
            PERLWIN32GUI_ARGTYPE_LONG, GET_X_LPARAM(lParam),
            PERLWIN32GUI_ARGTYPE_LONG, GET_Y_LPARAM(lParam),
            PERLWIN32GUI_ARGTYPE_LONG, wParam,
            -1);
        break;
    case WM_LBUTTONDBLCLK:
        PerlResult = DoEvent(NOTXSCALL perlud, PERLWIN32GUI_NEM_LMOUSEDBLCLK, "MouseDblClick",
            PERLWIN32GUI_ARGTYPE_LONG, GET_X_LPARAM(lParam),
            PERLWIN32GUI_ARGTYPE_LONG, GET_Y_LPARAM(lParam),
            PERLWIN32GUI_ARGTYPE_LONG, wParam,
            -1);
        break;
    case WM_RBUTTONDOWN:
        PerlResult = DoEvent(NOTXSCALL perlud, PERLWIN32GUI_NEM_RMOUSEDOWN, "MouseRightDown",
            PERLWIN32GUI_ARGTYPE_LONG, GET_X_LPARAM(lParam),
            PERLWIN32GUI_ARGTYPE_LONG, GET_Y_LPARAM(lParam),
            PERLWIN32GUI_ARGTYPE_LONG, wParam,
            -1);
        break;
    case WM_RBUTTONUP:
        PerlResult = DoEvent(NOTXSCALL perlud, PERLWIN32GUI_NEM_RMOUSEUP, "MouseRightUp",
            PERLWIN32GUI_ARGTYPE_LONG, GET_X_LPARAM(lParam),
            PERLWIN32GUI_ARGTYPE_LONG, GET_Y_LPARAM(lParam),
            PERLWIN32GUI_ARGTYPE_LONG, wParam,
            -1);
        break;
    case WM_RBUTTONDBLCLK:
        PerlResult = DoEvent(NOTXSCALL perlud, PERLWIN32GUI_NEM_RMOUSEDBLCLK, "MouseRightDblClick",
            PERLWIN32GUI_ARGTYPE_LONG, GET_X_LPARAM(lParam),
            PERLWIN32GUI_ARGTYPE_LONG, GET_Y_LPARAM(lParam),
            PERLWIN32GUI_ARGTYPE_LONG, wParam,
            -1);
        break;
    case WM_MBUTTONDOWN:
        PerlResult = DoEvent(NOTXSCALL perlud, PERLWIN32GUI_NEM_MMOUSEDOWN, "MouseMiddleDown",
            PERLWIN32GUI_ARGTYPE_LONG, GET_X_LPARAM(lParam),
            PERLWIN32GUI_ARGTYPE_LONG, GET_Y_LPARAM(lParam),
            PERLWIN32GUI_ARGTYPE_LONG, wParam,
            -1);
        break;
    case WM_MBUTTONUP:
        PerlResult = DoEvent(NOTXSCALL perlud, PERLWIN32GUI_NEM_MMOUSEUP, "MouseMiddleUp",
            PERLWIN32GUI_ARGTYPE_LONG, GET_X_LPARAM(lParam),
            PERLWIN32GUI_ARGTYPE_LONG, GET_Y_LPARAM(lParam),
            PERLWIN32GUI_ARGTYPE_LONG, wParam,
            -1);
        break;
    case WM_MBUTTONDBLCLK:
        PerlResult = DoEvent(NOTXSCALL perlud, PERLWIN32GUI_NEM_MMOUSEDBLCLK, "MouseMiddleDblClick",
            PERLWIN32GUI_ARGTYPE_LONG, GET_X_LPARAM(lParam),
            PERLWIN32GUI_ARGTYPE_LONG, GET_Y_LPARAM(lParam),
            PERLWIN32GUI_ARGTYPE_LONG, wParam,
            -1);
        break;

    case WM_KEYDOWN:
        PerlResult = DoEvent(NOTXSCALL perlud, PERLWIN32GUI_NEM_KEYDOWN, "KeyDown",
            PERLWIN32GUI_ARGTYPE_LONG, lParam,
            PERLWIN32GUI_ARGTYPE_LONG, wParam,
            -1);
        break;
    case WM_KEYUP:
        PerlResult = DoEvent(NOTXSCALL perlud, PERLWIN32GUI_NEM_KEYUP, "KeyUp",
            PERLWIN32GUI_ARGTYPE_LONG, lParam,
            PERLWIN32GUI_ARGTYPE_LONG, wParam,
            -1);
        break;
    case WM_CHAR:
        PerlResult = DoEvent(NOTXSCALL perlud, PERLWIN32GUI_NEM_CHAR, "Char",
            PERLWIN32GUI_ARGTYPE_LONG, lParam,
            PERLWIN32GUI_ARGTYPE_LONG, wParam,
            -1);
        break;
    case WM_COMMAND:
    case WM_NOTIFY :
        if (perlud->dwPlStyle & PERLWIN32GUI_CONTAINER) {
            HWND hwndParent = (HWND) GetWindowLongPtr(hwnd, GWLP_HWNDPARENT);
            SendMessage(hwndParent, uMsg, wParam, lParam);
            return 0;
        }
    case WM_MOUSEHOVER :
        PerlResult = DoEvent(NOTXSCALL perlud, PERLWIN32GUI_NEM_MOUSEOVER, "MouseOver", -1);
        if(PerlResult) {
            TRACKMOUSEEVENT tme;
            tme.cbSize = sizeof(TRACKMOUSEEVENT);
            tme.hwndTrack = hwnd;
            tme.dwFlags = TME_QUERY;
            if(_TrackMouseEvent( &tme )) {
                _TrackMouseEvent( &tme );
            }
        }
        break;
    case WM_MOUSELEAVE :
        PerlResult = DoEvent(NOTXSCALL perlud, PERLWIN32GUI_NEM_MOUSEOUT, "MouseOut", -1);
        if(PerlResult) {
            TRACKMOUSEEVENT tme;
            tme.cbSize = sizeof(TRACKMOUSEEVENT);
            tme.hwndTrack = hwnd;
            tme.dwFlags = TME_QUERY;
            if(_TrackMouseEvent( &tme )) {
                _TrackMouseEvent( &tme );
            }
        }
        break;
    case WM_DROPFILES:
        { HV *dropfiles_stash = gv_stashpv("Win32::GUI::DropFiles", 0);
          if(dropfiles_stash) { /* Win32::GUI::DropFiles is available */
            PerlResult = DoEvent(NOTXSCALL perlud, PERLWIN32GUI_NEM_DROPFILE, "DropFiles",
                         PERLWIN32GUI_ARGTYPE_SV, CreateObjectWithHandle(NOTXSCALL "Win32::GUI::DropFiles", (HWND)wParam),
                        -1);
	  } else { /* Win32::GUI::DropFiles is not available */
            PerlResult = DoEvent(NOTXSCALL perlud, PERLWIN32GUI_NEM_DROPFILE, "DropFiles",
                         PERLWIN32GUI_ARGTYPE_LONG, wParam,
                        -1);
            DragFinish((HDROP)wParam);
	  }
	}
    }

    if (IsWindow(hwnd) && perlud->avHooks != NULL)
        DoHook(NOTXSCALL perlud, uMsg,wParam,lParam,&PerlResult,0);

    if (IsWindow(hwnd) && PerlResult != 0) {
        PerlResult = CommonMsgLoop(NOTXSCALL hwnd, uMsg, wParam, lParam, perlud->WndProc);
    }
    else if (IsWindow(hwnd) && perlud->forceResult != 0) {
        return perlud->forceResult;
    }

    return PerlResult;
}

    /*
    ###########################################################################
    # (@)INTERNAL:ContainerMsgLoop(hwnd, uMsg, wParam, lParam)
    # message loop for container control class
    # Only Set CONTAINER flag at creation and call ControlMsgLoop.
    */
LRESULT CALLBACK ContainerMsgLoop(HWND hwnd, UINT uMsg, WPARAM wParam, LPARAM lParam)
{
    /*
     * WM_CREATE && WM_NCCREATE
     * If we handle this message we are using a custom control class (See RegisterClassEx).
     */
    if(uMsg == WM_CREATE || uMsg == WM_NCCREATE)
    {
        LPPERLWIN32GUI_USERDATA perlud = (LPPERLWIN32GUI_USERDATA) ((CREATESTRUCT *) lParam)->lpCreateParams;
        if(perlud != NULL) {
            PERLUD_FETCH;
            SetWindowLongPtr(hwnd, GWLP_USERDATA, (LONG_PTR) perlud);
            hv_store_mg(NOTXSCALL (HV*)SvRV(perlud->svSelf), "-handle", 7, newSViv(PTR2IV(hwnd)), 0);
            SwitchBit(perlud->dwPlStyle, PERLWIN32GUI_CUSTOMCLASS, 1);  // Set Custom class flag
            SwitchBit(perlud->dwPlStyle, PERLWIN32GUI_CONTAINER  , 1);  // Set Container flag

            // Search for an extend MsgLoop procedure (-extends option in RegisterClassEx)
            perlud->WndProc = (LWNDPROC_CAST) GetDefClassProc (NOTXSCALL ((CREATESTRUCT *) lParam)->lpszClass);
            if (perlud->WndProc) {
                return CallWindowProc((WNDPROC_CAST) perlud->WndProc, hwnd, uMsg, wParam, lParam);
            }
        }

        return DefWindowProc(hwnd, uMsg, wParam, lParam);
    }

    // Call ControlMsgLoop.
    return CallWindowProc((WNDPROC_CAST) ControlMsgLoop, hwnd, uMsg, wParam, lParam);
}

    /*
    ###########################################################################
    # (@)INTERNAL:CustomMsgLoop(hwnd, uMsg, wParam, lParam)
    # Special message loop (for Win32::GUI::Splitter objects)
    # All event are handle in OnEvent function
    */
LRESULT CALLBACK CustomMsgLoop(HWND hwnd, UINT uMsg, WPARAM wParam, LPARAM lParam)
{
    LPPERLWIN32GUI_USERDATA perlud;
    int PerlResult = 1;

    /*
     * WM_CREATE && WM_NCCREATE
     * If we handle this message we are using a custom control class (See RegisterClassEx).
     */
    if(uMsg == WM_CREATE || uMsg == WM_NCCREATE)
    {
        perlud = (LPPERLWIN32GUI_USERDATA) ((CREATESTRUCT *) lParam)->lpCreateParams;
        if(perlud != NULL) {
            PERLUD_FETCH;
            SetWindowLongPtr(hwnd, GWLP_USERDATA, (LONG_PTR) perlud);
            hv_store_mg(NOTXSCALL (HV*)SvRV(perlud->svSelf), "-handle", 7, newSViv(PTR2IV(hwnd)), 0);
            SwitchBit(perlud->dwPlStyle, PERLWIN32GUI_CUSTOMCLASS, 1);  // Set Custom class flag

            // Search for an extend MsgLoop procedure (-extends option in RegisterClassEx)
            perlud->WndProc = (LWNDPROC_CAST) GetDefClassProc (NOTXSCALL ((CREATESTRUCT *) lParam)->lpszClass);
            if (perlud->WndProc) {
                return CallWindowProc((WNDPROC_CAST) perlud->WndProc, hwnd, uMsg, wParam, lParam);
            }
        }

        return DefWindowProc(hwnd, uMsg, wParam, lParam);
    }

    perlud = (LPPERLWIN32GUI_USERDATA) GetWindowLongPtr(hwnd, GWLP_USERDATA);
    if( !ValidUserData(perlud)) {
        return DefWindowProc(hwnd, uMsg, wParam, lParam);
    }
    perlud->forceResult = 0;

    PERLUD_FETCH;

    /*
     * WM_DESTROY
     */
    if(uMsg == WM_DESTROY) {
        if (perlud->WndProc)
            PerlResult = CallWindowProc((WNDPROC_CAST) perlud->WndProc, hwnd, uMsg, wParam, lParam);
        else
            PerlResult = DefWindowProc(hwnd, uMsg, wParam, lParam);
        PERLUD_FREE;
        return PerlResult;
    }

    // Call class event Handler
    PerlResult = OnEvent[perlud->iClass](NOTXSCALL perlud, uMsg, wParam, lParam);

    // Hook for non interactive control
    if (IsWindow(hwnd) && perlud->avHooks != NULL && !(perlud->dwPlStyle & PERLWIN32GUI_INTERACTIVE))
        DoHook(NOTXSCALL perlud, uMsg,wParam,lParam,&PerlResult,0);

    if (IsWindow(hwnd) && PerlResult != 0) {
        // If interactive control, call ControlMsgLoop
        if (perlud->dwPlStyle & PERLWIN32GUI_INTERACTIVE)
            PerlResult = CallWindowProc((WNDPROC_CAST) ControlMsgLoop, hwnd, uMsg, wParam, lParam);
        else
            PerlResult = CommonMsgLoop(NOTXSCALL hwnd, uMsg, wParam, lParam, perlud->WndProc);
    }
    else if (IsWindow(hwnd) && perlud->forceResult != 0) {
        return perlud->forceResult;
    }

    return PerlResult;
}
