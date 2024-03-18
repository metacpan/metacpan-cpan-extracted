// Compile as this:		gcc -Wall dumper-msg-show.c -lcomctl32  -lgdi32

#include <wchar.h>
#include <windows.h>
#define ARRAY_LENGTH(x) (sizeof(x) / sizeof((x)[0]))

#define ID_EDIT_TOP	1
#define ID_EDIT_BOTTOM	2
#define ID_ACCEL_FAKE	0xeD94		// Random number; should not matter due to ignore_accel

struct {int lctrl_ralt_timestamp; wchar_t prev; signed char kllf; signed char real_lctrl; signed char tsmp_ctrl;} kbdState = {0, 0, -1, -1};

HFONT hFont;		// Global variable to store the font handle
int isUni = -1;
WNDPROC OldEditProc;	// Global variable
HWND hwndEdit2;
int ignore_accel = 0;		// Negative if our fake-accelerator code failed
int is_KLLFA = -1;		// Unknown
long msg_cnt = 0;
WPARAM wParam;

typedef enum {lCtrl_unknown = 0, lCtrl_up, lCtrl_first, lCtrl_maybefake, lCtrl_real, lCtrl_noKLLFA_any} lCtrl_STATE;
lCtrl_STATE lCtrl_state = lCtrl_unknown;	// Make global temporarily
typedef enum {KEY_unknown = 0, KEY_up, KEY_down} KEY_STATE;
KEY_STATE rCtrl_state = KEY_unknown, rAlt_state = KEY_unknown;		// Make global temporarily

DWORD ErrorShowW(HWND hwnd, wchar_t *Mess)	// hwnd = NULL allowed
{     // Show the system error message for the last-error code; based on https://learn.microsoft.com/en-us/windows/win32/Debug/retrieving-the-last-error-code
    wchar_t *lpMsgBuf;
    wchar_t *lpDisplayBuf;
    DWORD dw = GetLastError();
    int l;

    FormatMessageW(
        FORMAT_MESSAGE_ALLOCATE_BUFFER | 
        FORMAT_MESSAGE_FROM_SYSTEM |
        FORMAT_MESSAGE_IGNORE_INSERTS,
        NULL,
        dw,
        MAKELANGID(LANG_NEUTRAL, SUBLANG_DEFAULT),
        (LPWSTR)&lpMsgBuf,
        0, NULL );

    // Display the error message and exit the process

    lpDisplayBuf = (wchar_t *)LocalAlloc(LMEM_ZEROINIT, ((l = wcslen(lpMsgBuf) + wcslen(Mess) + 40)) * sizeof(wchar_t));
    swprintf(lpDisplayBuf, l, L"%lserror %d: %ls", Mess, dw, lpMsgBuf);
    MessageBoxW(hwnd, lpDisplayBuf, L"API call Error", MB_ICONEXCLAMATION | MB_OK); 

    LocalFree((LPVOID)lpMsgBuf);
    LocalFree((LPVOID)lpDisplayBuf);
    return dw;
}

void WM_chr_Dump(wchar_t* buffer, int length, LPARAM lParam, int isSYS)
{    // Extract the bitfields from lParam
//    unsigned repeatCount = lParam & 0xFFFF;
    unsigned scanCode = (lParam >> 16) & 0xFF;
    unsigned extended = (lParam >> 24) & 0x1;
    unsigned reserved = (lParam >> 25) & 0x7;
    unsigned contextCode = (lParam >> 29) & 0x1;
    unsigned previousState = (lParam >> 30) & 0x1;
    unsigned transitionState = (lParam >> 31) & 0x1;
    const char ctrl = (contextCode ? (isSYS ? '-' : 'C') : '?');
    const char *fk = (reserved & 0x01 ? " fake" : "");
    const char *oem = (reserved & 0x02 ? " oem(should not happen)" : "");	// should not happen: we are not a console handler
    wchar_t states[256*4+1] = L" [", *curStates = states+2;

    BYTE arr[256];
    if (GetKeyboardState(arr)) {
	wchar_t id[4];
	wchar_t state[2] = L"\0";

        for(int pass=0; pass<2; pass++) {	// Maybe do it in two steps, first for common modifiers (no spaces needed!), then the rest???
          for(int i=0; i<256; i++) {	// Maybe do it in two steps, first for common modifiers (no spaces needed!), then the rest???
            int isdown = arr[i] & 0x80, ch = 0, isLong = 0, reportLock = 0;

            state[0] = 0;

            if (!arr[i]) continue;
            switch (i) {		// Start with characters typically used as modifiers
              case VK_SHIFT:
                ch = 0x2475+'S' /* Ⓢ */;
                break;
              case VK_LSHIFT:
                ch = 's';
                break;
              case VK_RSHIFT:
                ch = 'S';
                break;
              case VK_CONTROL:
                ch = 0x2475+'C' /* Ⓒ */;
                break;
              case VK_LCONTROL:
                ch = 'c';
                break;
              case VK_RCONTROL:
                ch = 'C';
                break;
              case VK_MENU:
                ch = 0x2475+'A' /* Ⓐ */;
                break;
              case VK_LMENU:
                ch = 'a';
                break;
              case VK_RMENU:
                ch = 'A';
                break;
              case VK_LWIN:
                ch = 'w';
                break;
              case VK_RWIN:
                ch = 'W';
                break;
              case VK_KANA:
                ch = 'K';
                break;
              case VK_CAPITAL:
                ch = 'L';
                reportLock = 1;
                break;
              case VK_SCROLL:
                ch = 0x2195;  // ↕;
                reportLock = 1;
                break;
              case VK_NUMLOCK:
                ch = 'N';
                reportLock = 1;
                break;
              case VK_OEM_8:
                swprintf(id, ARRAY_LENGTH(id), L"%s", "_8");
                break;
              case VK_OEM_AX:
                swprintf(id, ARRAY_LENGTH(id), L"%s", "ax");
                break;
              default:
                isLong = 1;
                if (('A' <= i && 'Z' >= i) || ('0' <= i && '9' >= i))
                    swprintf(id, ARRAY_LENGTH(id), L"=%lc", i);
                else
                    swprintf(id, ARRAY_LENGTH(id), L"%02x", i);
            }
            if (!(isdown || reportLock)) continue;
            if ((arr[i] & 0x1) && reportLock)	// toggled
                state[0] = (!isdown ? 0x2191 /* up↑ */ : 0x2193 /* down↓ */);
            if (ch)
                swprintf(id, ARRAY_LENGTH(id), L"%lc", ch);

            if (pass != isLong)
                continue;
	    swprintf(curStates, ARRAY_LENGTH(states)-(curStates-states),
	    	L"%s%ls%ls", ((isLong && curStates != states + 2) ? " " : ""), id, state);
	    curStates += wcslen(curStates);	// %n does not seem to work
          }
        }
    }
    curStates[0] = L']';
    if (curStates == states+2)
      curStates = L"";
    else
      curStates = states;
//     Write the bitfields to the buffer
//    swprintf(buffer, length, L"Repeat Count: %u\nScan Code: %u\nExtended: %u\n"
//                             L"Reserved: %u\nContext Code: %u\nPrevious State: %u\n"
//                             L"Transition State: %u\n",
//             repeatCount, scanCode, extended, reserved, contextCode, previousState, transitionState);
    swprintf(buffer, length, L" %sSc=%02x Rsrvd=%u CtrlAlt=%c/%c wasDn=%u goUp=%u%ls%s%s %d/%d %ld,%lx",
             /*repeatCount,*/ (extended? "" : "  "), scanCode+0xe000*extended,
             reserved, ctrl, (contextCode? 'A' : '-'), previousState, transitionState, curStates, fk, oem, (int)lCtrl_state, is_KLLFA, msg_cnt, wParam);
}

void
formatMessage(wchar_t *buffer, int buflen, UINT msg, WPARAM wParam, LPARAM lParam)
{
    const char *msg_s;
    const char *sp12  = "            ";
    const char *sp12e = sp12 + 12;
    wchar_t extra[256];
    int isSYS = 0;

    extra[0] = 0;
    switch(msg)
    {
        case WM_SYSCHAR:	msg_s = "SYSCHAR";	isSYS = 1; goto fill_buff_char;
        case WM_SYSDEADCHAR:	msg_s = "SYSDEADCHAR";	isSYS = 1; goto fill_buff_char;
        case WM_CHAR:		msg_s = "CHAR";		goto fill_buff_char;
        case WM_DEADCHAR:	msg_s = "DEADCHAR";	goto fill_buff_char;
	case WM_UNICHAR:	msg_s = "UNICHAR";	goto fill_buff_char;
      fill_buff_char:
	    WM_chr_Dump(extra, ARRAY_LENGTH(extra), lParam, isSYS);
	    swprintf(buffer, buflen, L"WM_%s:%s <%lc> 0x%04X  0x%08X%ls\r\n",
	    	msg_s, sp12e-(11-strlen(msg_s)), wParam, wParam, lParam, extra);
            break;
        case WM_SYSKEYDOWN:	msg_s = "SYSKEYDOWN";	isSYS = 1; goto fill_buff_nonchar;
        case WM_SYSKEYUP:	msg_s = "SYSKEYUP";	isSYS = 1; goto fill_buff_nonchar;
        case WM_KEYDOWN:	msg_s = "KEYDOWN";	goto fill_buff_nonchar;
        case WM_KEYUP:		msg_s = "KEYUP";	goto fill_buff_nonchar;
      fill_buff_nonchar:
	    WM_chr_Dump(extra, ARRAY_LENGTH(extra), lParam, isSYS);
	    swprintf(buffer, buflen, L"WM_%s:%s     0x%04X  0x%08X%ls\r\n",
	    	msg_s, sp12e-(11-strlen(msg_s)), wParam, lParam, extra);
            break;
    }
}

// Subclass procedure
LRESULT CALLBACK EditProc(HWND hwnd, UINT msg, WPARAM wParam, LPARAM lParam)
{
    static wchar_t buffer[256];

    switch(msg)
    {
	case WM_UNICHAR:
	    if(wParam == UNICODE_NOCHAR)
	    {
	        return TRUE;
	    }
	    else
	    {
	        int ind = 0;
		wchar_t b[3];

	        if (wParam < 0x10000) {
	            b[ind++] = wParam;
	        } else {
	            b[ind++] = ((wParam - 0x10000)>>10) + 0xd800;
	            b[ind++] =  (wParam & 0x3ff)        + 0xdc00;
	        }
	        b[ind++] = 0;
	        swprintf(buffer, ARRAY_LENGTH(buffer), L"WM_UNICHAR:     <%ls> 0x%04X  0x%08X\r\n", b, wParam, wParam, lParam);
	        SendMessageW(hwndEdit2, EM_REPLACESEL, FALSE, (LPARAM)buffer);
	        return FALSE;
	    }
	    break;
        case WM_SYSCHAR:   case WM_CHAR:   case WM_SYSDEADCHAR:    case WM_DEADCHAR:
        case WM_SYSKEYDOWN:   case WM_KEYDOWN:    case WM_SYSKEYUP:    case WM_KEYUP:
	    formatMessage(buffer, ARRAY_LENGTH(buffer), msg, wParam, lParam);
	    SendMessageW(hwndEdit2, EM_REPLACESEL, FALSE, (LPARAM)buffer);
            break;
        case WM_COMMAND:  case WM_SYSCOMMAND:
            if (ignore_accel == 1) {	// fake accelerator may be triggered
                if (LOWORD(wParam) == ID_ACCEL_FAKE)
                    is_KLLFA = 0;
                else
                    SendMessageW(hwndEdit2, EM_REPLACESEL, FALSE, (LPARAM)L"     Unexpected ID of accelerator!!\r\n");                   
	        swprintf(buffer, ARRAY_LENGTH(buffer), L"   Accelerator received, hence no KLLF_ALTGR\r\n");
                SendMessageW(hwndEdit2, EM_REPLACESEL, FALSE, (LPARAM)buffer);
                return 0;
            } else if (LOWORD(wParam) == ID_ACCEL_FAKE)
                SendMessageW(hwndEdit2, EM_REPLACESEL, FALSE, (LPARAM)L"     Our fake accelerator arrived unexpectedly!!\r\n");
            // https://learn.microsoft.com/en-us/windows/win32/menurc/wm-syscommand
            else if ((LOWORD(wParam) & 0xFFF0) == SC_KEYMENU && msg == WM_SYSCOMMAND)
                (void)1;	// 0xF100; Seems to be send by (RichEdit???) on Alt-letters
            else {
                char *s = (((LOWORD(wParam) <= 0xf200) && (LOWORD(wParam) >= 0xf000)) ? "SC_-like-" : "");
                char *sys = ((msg == WM_SYSCOMMAND) ? "SYS-" : "");
	        swprintf(buffer, ARRAY_LENGTH(buffer), L"     Unexpected %s%saccelerator!! <%lc> 0x%04x\r\n", s, sys, LOWORD(wParam), LOWORD(wParam));
                SendMessageW(hwndEdit2, EM_REPLACESEL, FALSE, (LPARAM)buffer);
            }
            break;
        default:
    }
    return CallWindowProc(OldEditProc, hwnd, msg, wParam, lParam);
//    return 0;
}



LRESULT CALLBACK WndProc(HWND hwnd, UINT msg, WPARAM wParam, LPARAM lParam)
{
    switch(msg)
    {
        case WM_CREATE:
	    // Create the first edit control
	    HWND hwndEdit1 = CreateWindowExW(0, L"EDIT", NULL,
	        WS_CHILD | WS_VISIBLE | WS_VSCROLL | WS_BORDER | ES_MULTILINE | ES_AUTOVSCROLL,
	        0, 0, 0, 0, hwnd, (HMENU)ID_EDIT_TOP, NULL, NULL);

            if(hwndEdit1) {
                // Create the second edit control
                hwndEdit2 = CreateWindowExW(0, L"EDIT", NULL,
                    WS_CHILD | WS_VISIBLE | WS_VSCROLL | WS_BORDER | ES_MULTILINE | ES_AUTOVSCROLL,
                    0, 0, 0, 0, hwnd, (HMENU)ID_EDIT_BOTTOM, NULL, NULL);
                if(!hwndEdit2)
                    ErrorShowW(hwnd, L"Could not create 2nd edit box: ");
	    } else
	        ErrorShowW(hwnd, L"Could not create 1st edit box: ");


	    // Create a LOGFONT structure and set the font name and size
	    LOGFONTW lf;
	    memset(&lf, 0, sizeof(LOGFONTW));
	    lf.lfHeight = 24;  // height of font
//	    wcscpy(lf.lfFaceName, L"Arial Unicode MS");  // name of font
//	    wcscpy(lf.lfFaceName, L"Segoe UI Symbol");  // name of font
//	    wcscpy(lf.lfFaceName, L"Segoe UI Symbol, Arial Unicode MS, Symbola, DejaVu Sans Mono Unifont");  // name of font
			// With Symbola exits silently
//	    wcscpy(lf.lfFaceName, L"Segoe UI Symbol, Arial Unicode MS, Symbola");  // name of font
//	    wcscpy(lf.lfFaceName, L"Segoe UI Symbol, Arial Unicode MS, DejaVu Sans Mono Unifont");  // name of font
//	    wcscpy(lf.lfFaceName, L"Segoe UI Symbol, DejaVu Sans Mono Unifont");  // name of font
	    wcscpy(lf.lfFaceName, L"DejaVu Sans Mono Unifont");  // name of font
//	    wcscpy(lf.lfFaceName, L"Unifont Smooth");  // name of font
//	    wcscpy(lf.lfFaceName, L"Segoe UI Emoji");  // name of font

	    // Create the font and send the WM_SETFONT message
	    hFont = CreateFontIndirectW(&lf);
	    SendMessage(hwndEdit1, WM_SETFONT, (WPARAM)hFont, MAKELPARAM(TRUE, 0));
	    SendMessage(hwndEdit2, WM_SETFONT, (WPARAM)hFont, MAKELPARAM(TRUE, 0));
	    OldEditProc = (WNDPROC)SetWindowLongPtrW(hwndEdit1, GWLP_WNDPROC, (LONG_PTR)EditProc);
            break;
        case WM_SIZE:
	{
	    // Get the new size of the client area
	    int width = LOWORD(lParam);
	    int height = HIWORD(lParam);

	    // Resize the first edit control to take up the top 1/4 of the client area
	    SetWindowPos(GetDlgItem(hwnd, ID_EDIT_TOP), NULL, 0, 0, width, height / 4, SWP_NOZORDER);

	    // Resize the second edit control to take up the rest of the client area
	    SetWindowPos(GetDlgItem(hwnd, ID_EDIT_BOTTOM), NULL, 0, height / 4, width, 3 * height / 4, SWP_NOZORDER);
	}
            break;
        case WM_SETFOCUS:
            SetFocus(GetDlgItem(hwnd, ID_EDIT_TOP));
            break;
        case WM_DESTROY:
	    // Delete the font
	    if(hFont)
	        DeleteObject(hFont);
            PostQuitMessage(0);
            break;
    }
    return DefWindowProcW(hwnd, msg, wParam, lParam);
}

// returns -2, -3 on failure, -1 on not-now-OK-to-retry; 0 or 1: is KLLF_ALTGR found
int Check_KLLF_ALTGR(MSG *msg, BYTE vk, WORD acc) {   // msg should be directed to a window in question.  Assumes that lCtrl and rAlt are down
    // See https://metacpan.org/dist/UI-KeyboardLayout/view/lib/UI/KeyboardLayout.pm#A-convenient-assignment-of-KBD*-bitmaps-to-modifier-keys
    if ((GetKeyState(VK_RCONTROL) & 0x80) && (GetKeyState(VK_LMENU) & 0x80))
        return -1;		// Retry OK; with all 4 modifiers will be triggered even with KLLF_ALTGR

    int have_Shift = ((GetKeyState(VK_SHIFT) & 0x80) ? FSHIFT : 0);
    union {ACCEL acc; double d;} accel;	// force alignment (vs. error 998)
    HACCEL hAccel;

    accel.acc = (ACCEL){ have_Shift | FCONTROL | FALT | FVIRTKEY, vk, acc };
    if (!(hAccel = CreateAcceleratorTableW(&(accel.acc), 1)))
        return -2;		// Serious failure; do not retry

    MSG fakeMsg = *msg;

    fakeMsg.wParam = vk;	// With KLLF_ALTGR, a message with AltGr is considered a C-A-accelerator only if all 4 are down
    fakeMsg.message = WM_SYSKEYDOWN;	// Without, it is a C-A-accelerator if any-of-C and any-of-A are down
    int rc = TranslateAccelerator(msg->hwnd, hAccel, &fakeMsg);	    // Hence this fails with KLLF_ALTGR, and succeeds without

    if (DestroyAcceleratorTable(hAccel))
        return !rc;
    return -3;			// Serious failure; do not retry
}


int WINAPI WinMain(HINSTANCE hInstance, HINSTANCE hPrevInstance,
    LPSTR lpCmdLine, int nCmdShow)
// int WINAPI wWinMain(HINSTANCE hInstance, HINSTANCE hPrevInstance,
//    PWSTR pCmdLine, int nCmdShow)
{
    const wchar_t g_szClassName[] = L"myWindowClass";
    WNDCLASSEXW wc;
    HWND hwnd;
    MSG Msg;
    DWORD prMsgTime;
//    lCtrl_STATE lCtrl_state = lCtrl_unknown;

    wc.cbSize        = sizeof(WNDCLASSEXW);
    wc.style         = 0;
    wc.lpfnWndProc   = WndProc;
    wc.cbClsExtra    = 0;
    wc.cbWndExtra    = 0;
    wc.hInstance     = hInstance;
    wc.hIcon         = LoadIcon(NULL, IDI_APPLICATION);
    wc.hCursor       = LoadCursor(NULL, IDC_ARROW);
    wc.hbrBackground = (HBRUSH)(COLOR_WINDOW+1);
    wc.lpszMenuName  = NULL;
    wc.lpszClassName = g_szClassName;
    wc.hIconSm       = LoadIcon(NULL, IDI_APPLICATION);

    if(!RegisterClassExW(&wc))
    {
        ErrorShowW(NULL, L"Window Registration Failed! ");
        return 0;
    }

    hwnd = CreateWindowExW(
        WS_EX_CLIENTEDGE,
        g_szClassName,
        L"The title of my window",
        WS_OVERLAPPEDWINDOW,
        CW_USEDEFAULT, CW_USEDEFAULT, 240, 120,
        NULL, NULL, hInstance, NULL);

    if(hwnd == NULL)
    {
        ErrorShowW(NULL, L"Window Creation Failed! ");
        return 0;
    }

    ShowWindow(hwnd, nCmdShow);
    UpdateWindow(hwnd);

    lCtrl_state = lCtrl_unknown;
    rAlt_state = rCtrl_state = KEY_unknown;
    while(GetMessageW(&Msg, NULL, 0, 0) > 0)
    {
	// keyrepeat of AltGr leads to pairs  lCtrl + rAlt with the same timestamp; try to find lCtrl which do not look like this
	wParam = Msg.wParam;
	if (is_KLLFA) {		// KLLF_ALTGR set, or unknown  The kernel removed the FAKE_KEYSTROKE flag; try to restore
	    int vk, vk_orig, vk1, vk2;

	    /* The kernel translated the handed codes to unhanded ones “for our convenience”.  Translate back */
            switch (Msg.message) {	// https://stackoverflow.com/questions/5681284/how-do-i-distinguish-between-left-and-right-keys-ctrl-and-alt/77281559#77281559
              case WM_KEYDOWN: case WM_SYSKEYDOWN:  case WM_KEYUP: case WM_SYSKEYUP:
                switch ((vk = vk_orig = LOWORD(wParam))) {
                  case VK_SHIFT:   // converts to VK_LSHIFT or VK_RSHIFT
                  case VK_CONTROL: // converts to VK_LCONTROL or VK_RCONTROL
                  case VK_MENU:    // converts to VK_LMENU or VK_RMENU
                  {
                      WORD keyFlags = HIWORD(Msg.lParam);
                      WORD scanCode = LOBYTE(keyFlags);
                      BOOL isExtendedKey = (keyFlags & KF_EXTENDED) == KF_EXTENDED;
    
                      if (isExtendedKey)
                          scanCode = MAKEWORD(scanCode, 0xE0);
                      switch (vk)	 // if we want to distinguish these keys:
                      {
                        case VK_SHIFT:   // converts to VK_LSHIFT or VK_RSHIFT
                          vk1 = VK_LSHIFT;  vk2 = VK_RSHIFT;
                          goto do_map;
                        case VK_CONTROL: // converts to VK_LCONTROL or VK_RCONTROL
                          vk1 = VK_LCONTROL;  vk2 = VK_RCONTROL;
                          goto do_map;
                        case VK_MENU:    // converts to VK_LMENU or VK_RMENU
                          vk1 = VK_LMENU;  vk2 = VK_RMENU;
                        	do_map:
                          vk = LOWORD(MapVirtualKeyW(scanCode, MAPVK_VSC_TO_VK_EX));
                          if ((vk != vk1) && (vk != vk2))
                              vk = vk_orig;			// XXXX Should not happen!  (Same for the code below as -1)
                          break;
                      }
                  }
                }
                break;
              default:
                vk = -1;
            }

            // With KLLF_ALTGR, a press (or keyrepeat) of rAlt is preceded by a fake press of lCtrl with the same timestamp — unless
            // any Ctrl is “really down”.  This finite automaton tries to detect when rAlt arrives differently (and then we know it
            // is not KLLF_ALTGR (without doing the accelerator-trick; we write this to is_KLLFA); also, we detect when rCtrl
            // arrives differently (and then it is a real Ctrl-modifier for a keybinding).
            //     Additionally, if rAlt and lCtrl are down (and is_KLLFA is “unknown”), we use the accelerator-trick
//            if (lCtrl_state == lCtrl_first) {
//                lCtrl_state = lCtrl_real;
//            } else
            if (vk == VK_LCONTROL) {
                    msg_cnt++;
                if (Msg.message == WM_KEYDOWN || Msg.message == WM_SYSKEYDOWN) {
                    if (rCtrl_state == KEY_down)		// No “fakes” generated
                        lCtrl_state = lCtrl_real;		// Sticky state, until up/reset
                    else if (lCtrl_state == lCtrl_unknown || lCtrl_state == lCtrl_up || lCtrl_state == lCtrl_maybefake)
                        lCtrl_state = lCtrl_first;		// Is it keypress/keyrepeat of rAlt?
                    else					// first/real/noKLLFA
	                goto unrelated;
                    if (rAlt_state == KEY_down && ignore_accel >= 0 && is_KLLFA < 0)
                        goto check_KLLFA;			// ??? may be UNREACHED!!! How to order w.r.t. the top?
                } else if (Msg.message == WM_KEYUP || Msg.message == WM_SYSKEYUP) {
                    if (lCtrl_state != lCtrl_noKLLFA_any)	// Sticky state, until reset
                        lCtrl_state = lCtrl_up;
                } else
                    goto unrelated;
            } else if (vk == VK_RCONTROL) {
                if (Msg.message == WM_KEYDOWN || Msg.message == WM_SYSKEYDOWN) {
                    rCtrl_state = KEY_down;
                } else if (Msg.message == WM_KEYUP || Msg.message == WM_SYSKEYUP) {
                    rCtrl_state = KEY_up;
                }
                goto unrelated;
            } else if (vk == VK_RMENU) {
                if (Msg.message == WM_KEYDOWN || Msg.message == WM_SYSKEYDOWN) {
                    rAlt_state = KEY_down;
                    if (lCtrl_state == lCtrl_first) {		// The MOST IMPORTANT check (this is what all this is about…)
                        if (prMsgTime == Msg.time)
                            lCtrl_state = lCtrl_maybefake;
                        else
                            lCtrl_state = lCtrl_real;
                    } else if (lCtrl_state == lCtrl_maybefake) { // lCtrl down would be faked, unless rCtrl is down ???
                        if (rCtrl_state == KEY_up)
                            lCtrl_state = lCtrl_real;
                    } else if ((lCtrl_state == lCtrl_up) && (rCtrl_state == KEY_up)) { // Must have been faked if is_KLLFA
                        lCtrl_state = lCtrl_noKLLFA_any;	// Sticky state, until reset
                        is_KLLFA = 0;
                    }
                    if (ignore_accel >= 0 && is_KLLFA < 0 && (lCtrl_state == lCtrl_maybefake || lCtrl_state == lCtrl_real)) {
                      check_KLLFA:
//			MessageBoxW(hwnd, L"Before Check_KLLF_ALTGR()", L"Warning", MB_ICONEXCLAMATION | MB_OK); 
			ignore_accel = 1;		// Warn the message handler that we are faking it

			int rc = Check_KLLF_ALTGR(&Msg, 0xE8 /* Unassigned VK_-code */, ID_ACCEL_FAKE);

			ignore_accel = -1;		// preliminary; will give up unless reset to 0
                        if (rc >= 0) {
                            if (rc ? is_KLLFA >= 0 : is_KLLFA)
                                MessageBoxW(NULL, L"Bug in detection of KLLF_ALTGR!", L"Error!",
                                    MB_ICONEXCLAMATION | MB_OK);
                            else {
                                if ((is_KLLFA = rc))
                                    MessageBoxW(NULL, L"KLLF_ALTGR detected!", L"Success", MB_OK);
                                ignore_accel = 0;	// Switch processing of (SYS)COMMANDS back to normal
                            }
                        } else if (rc == -2)		// These two should not happen
                            (void)ErrorShowW(Msg.hwnd, L"Acceleration Table creation Failed: ");
                        else if (rc == -3)
                            ErrorShowW(Msg.hwnd, L"Acceleration Table destruction Failed: ");
                        else if (rc == -1)
			    ignore_accel = 0;		// May retry later
                    }
                } else if (Msg.message == WM_KEYUP || Msg.message == WM_SYSKEYUP) {
                        rAlt_state = KEY_up;
                        if (lCtrl_state == lCtrl_maybefake)		// If “fake”, lCtrl-up would be generated first
                            lCtrl_state = lCtrl_real;
                        else
	                    goto unrelated;
                } else
                        goto unrelated;
            } else {
              unrelated:
                if (lCtrl_state == lCtrl_first)
                    lCtrl_state = lCtrl_real;
            }
        }
        switch (Msg.message) {		// May omit these; These are sent, so should be processed in the window procedure anyway
          case WM_KILLFOCUS:  case WM_SETFOCUS:  
            if (lCtrl_state == lCtrl_noKLLFA_any)	// Sticky state, until reset
                break;
          case WM_INPUTLANGCHANGE:
                lCtrl_state = lCtrl_unknown;
		rAlt_state = rCtrl_state = KEY_unknown;
        }
        if (Msg.message == WM_INPUTLANGCHANGE)
            is_KLLFA = -1;
        prMsgTime = Msg.time;

//        if (Msg.message == WM_KEYDOWN || Msg.message == WM_SYSKEYDOWN)
//            msg_cnt++;
        TranslateMessage(&Msg);
        DispatchMessageW(&Msg);
    }
    return Msg.wParam;
}
