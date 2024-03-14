// Compile as this:		gcc -Wall dumper-msg-show.c -lcomctl32  -lgdi32

#include <wchar.h>
#include <windows.h>
#define ARRAY_LENGTH(x) (sizeof(x) / sizeof((x)[0]))

#define ID_EDIT_TOP	1
#define ID_EDIT_BOTTOM	2

HFONT hFont;		// Global variable to store the font handle
int isUni = -1;
WNDPROC OldEditProc;	// Global variable
HWND hwndEdit2;

void WM_chr_Dump(wchar_t* buffer, int length, LPARAM lParam, int isSYS)
{
    // Extract the bitfields from lParam
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

    // Write the bitfields to the buffer
//    swprintf(buffer, length, L"Repeat Count: %u\nScan Code: %u\nExtended: %u\n"
//                             L"Reserved: %u\nContext Code: %u\nPrevious State: %u\n"
//                             L"Transition State: %u\n",
//             repeatCount, scanCode, extended, reserved, contextCode, previousState, transitionState);
    swprintf(buffer, length, L" %sSc=%02x Rsrvd=%u CtrlAlt=%c/%c wasDn=%u goUp=%u%s%s",
             /*repeatCount,*/ (extended? "" : "  "), scanCode+0xe000*extended,
             reserved, ctrl, (contextCode? 'A' : '-'), previousState, transitionState, fk, oem);
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

	    // Create the second edit control
	    hwndEdit2 = CreateWindowExW(0, L"EDIT", NULL,
	        WS_CHILD | WS_VISIBLE | WS_VSCROLL | WS_BORDER | ES_MULTILINE | ES_AUTOVSCROLL,
	        0, 0, 0, 0, hwnd, (HMENU)ID_EDIT_BOTTOM, NULL, NULL);
            if(!(hwndEdit1 || hwndEdit2))
                MessageBoxW(hwnd, L"Could not create 2 edit boxes.", L"Error", MB_OK | MB_ICONERROR);

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

int WINAPI WinMain(HINSTANCE hInstance, HINSTANCE hPrevInstance,
    LPSTR lpCmdLine, int nCmdShow)
// int WINAPI wWinMain(HINSTANCE hInstance, HINSTANCE hPrevInstance,
//    PWSTR pCmdLine, int nCmdShow)
{
    const wchar_t g_szClassName[] = L"myWindowClass";
    WNDCLASSEXW wc;
    HWND hwnd;
    MSG Msg;

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
        MessageBoxW(NULL, L"Window Registration Failed!", L"Error!",
            MB_ICONEXCLAMATION | MB_OK);
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
        MessageBoxW(NULL, L"Window Creation Failed!", L"Error!",
            MB_ICONEXCLAMATION | MB_OK);
        return 0;
    }

    ShowWindow(hwnd, nCmdShow);
    UpdateWindow(hwnd);

    while(GetMessageW(&Msg, NULL, 0, 0) > 0)
    {
        TranslateMessage(&Msg);
        DispatchMessageW(&Msg);
    }
    return Msg.wParam;
}
