/*
 * Console.CPP
 * 20 Jan 97 by Aldo Calpini <dada@perl.it>
 *
 * XS interface to the Win32 Console API
 * based on Registry.CPP written by Jesse Dougherty
 *
 * Version: 0.05 06 Jun 03
 *
 */

#define  WIN32_LEAN_AND_MEAN
#include <windows.h>

#define __TEMP_WORD  WORD	/* perl defines a WORD, yikes! */
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#undef Top			/* some devel version pollutes */
#undef WORD
#define WORD __TEMP_WORD

// Section for the constant definitions.
#define CROAK croak

/*------------------------------------------------------------------*/
#define SMALL_ICON_SIZE 16
#define TITLE_SIZE     128

static HANDLE  wndBigIcon   = NULL;
static HANDLE  wndSmallIcon = NULL;

/* Return a handle to the current console window */
static HWND GetConsoleHwnd(void)
{
  HWND hwnd;
  char tmpTitle[TITLE_SIZE];
  char oldTitle[TITLE_SIZE];

  sprintf(tmpTitle, "SeArChInG FoR WiNdOw %ld", GetCurrentThreadId());

  if (!GetConsoleTitle(oldTitle, TITLE_SIZE) ||
      !SetConsoleTitle(tmpTitle))
    return NULL;

  Sleep(40);                /* Ensure window title has been updated */

  hwnd = FindWindow("ConsoleWindowClass", tmpTitle);
  SetConsoleTitle(oldTitle);

  return hwnd;
} /* end GetConsoleHwnd */

/*------------------------------------------------------------------*/

DWORD
constant(char *name, int arg)
{
    errno = 0;
    switch (*name) {
    case 'A':
        break;
    case 'B':
        if (strEQ(name, "BACKGROUND_BLUE"))
            #ifdef BACKGROUND_BLUE
                return BACKGROUND_BLUE;
            #else
                goto not_there;
            #endif
        if (strEQ(name, "BACKGROUND_GREEN"))
            #ifdef BACKGROUND_GREEN
                return BACKGROUND_GREEN;
            #else
                goto not_there;
            #endif
        if (strEQ(name, "BACKGROUND_INTENSITY"))
            #ifdef BACKGROUND_INTENSITY
                return BACKGROUND_INTENSITY;
            #else
                goto not_there;
            #endif
        if (strEQ(name, "BACKGROUND_RED"))
            #ifdef BACKGROUND_RED
                return BACKGROUND_RED;
            #else
                goto not_there;
            #endif
        break;
    case 'C':
		if (strEQ(name, "CAPSLOCK_ON"))
            #ifdef CAPSLOCK_ON
                return CAPSLOCK_ON;
            #else
                goto not_there;
            #endif
        if (strEQ(name, "CONSOLE_TEXTMODE_BUFFER"))
            #ifdef CONSOLE_TEXTMODE_BUFFER
                return CONSOLE_TEXTMODE_BUFFER;
            #else
                goto not_there;
            #endif
        if (strEQ(name, "CTRL_BREAK_EVENT"))
            #ifdef CTRL_BREAK_EVENT
                return CTRL_BREAK_EVENT;
            #else
                goto not_there;
            #endif
        if (strEQ(name, "CTRL_C_EVENT"))
            #ifdef CTRL_C_EVENT
                return CTRL_C_EVENT;
            #else
                goto not_there;
            #endif
		break;

    case 'D':
        break;
    case 'E':
        if (strEQ(name, "ENABLE_ECHO_INPUT"))
            #ifdef ENABLE_ECHO_INPUT
                return ENABLE_ECHO_INPUT;
            #else
                goto not_there;
            #endif
        if (strEQ(name, "ENABLE_LINE_INPUT"))
            #ifdef ENABLE_LINE_INPUT
                return ENABLE_LINE_INPUT;
            #else
                goto not_there;
            #endif
        if (strEQ(name, "ENABLE_MOUSE_INPUT"))
            #ifdef ENABLE_MOUSE_INPUT
                return ENABLE_MOUSE_INPUT;
            #else
                goto not_there;
            #endif
        if (strEQ(name, "ENABLE_PROCESSED_INPUT"))
            #ifdef ENABLE_PROCESSED_INPUT
                return ENABLE_PROCESSED_INPUT;
            #else
                goto not_there;
            #endif
        if (strEQ(name, "ENABLE_PROCESSED_OUTPUT"))
            #ifdef ENABLE_PROCESSED_OUTPUT
                return ENABLE_PROCESSED_OUTPUT;
            #else
                goto not_there;
            #endif
        if (strEQ(name, "ENABLE_WINDOW_INPUT"))
            #ifdef ENABLE_WINDOW_INPUT
                return ENABLE_WINDOW_INPUT;
            #else
                goto not_there;
            #endif
        if (strEQ(name, "ENABLE_WRAP_AT_EOL_OUTPUT"))
            #ifdef ENABLE_WRAP_AT_EOL_OUTPUT
                return ENABLE_WRAP_AT_EOL_OUTPUT;
            #else
                goto not_there;
            #endif
        if (strEQ(name, "ENHANCED_KEY"))
            #ifdef ENHANCED_KEY
                return ENHANCED_KEY;
            #else
                goto not_there;
            #endif
        break;
    case 'F':
        if (strEQ(name, "FILE_SHARE_READ"))
            #ifdef FILE_SHARE_READ
                return FILE_SHARE_READ;
            #else
                goto not_there;
            #endif
        if (strEQ(name, "FILE_SHARE_WRITE"))
            #ifdef FILE_SHARE_WRITE
                return FILE_SHARE_WRITE;
            #else
                goto not_there;
            #endif
        if (strEQ(name, "FOREGROUND_BLUE"))
            #ifdef FOREGROUND_BLUE
                return FOREGROUND_BLUE;
            #else
                goto not_there;
            #endif
        if (strEQ(name, "FOREGROUND_GREEN"))
            #ifdef FOREGROUND_GREEN
                return FOREGROUND_GREEN;
            #else
                goto not_there;
            #endif
        if (strEQ(name, "FOREGROUND_INTENSITY"))
            #ifdef FOREGROUND_INTENSITY
                return FOREGROUND_INTENSITY;
            #else
                goto not_there;
            #endif
        if (strEQ(name, "FOREGROUND_RED"))
            #ifdef FOREGROUND_RED
                return FOREGROUND_RED;
            #else
                goto not_there;
            #endif
        break;
    case 'G':
        if (strEQ(name, "GENERIC_READ"))
            #ifdef GENERIC_READ
                return GENERIC_READ;
            #else
                goto not_there;
            #endif
        if (strEQ(name, "GENERIC_WRITE"))
            #ifdef GENERIC_WRITE
                return GENERIC_WRITE;
            #else
                goto not_there;
            #endif
        break;
    case 'H':
        break;
    case 'I':
        break;
    case 'J':
        break;
    case 'K':
        if (strEQ(name, "KEY_EVENT"))
            #ifdef KEY_EVENT
                return KEY_EVENT;
            #else
                goto not_there;
            #endif
        break;
    case 'L':
        if (strEQ(name, "LEFT_ALT_PRESSED"))
            #ifdef LEFT_ALT_PRESSED
                return LEFT_ALT_PRESSED;
            #else
                goto not_there;
            #endif
        if (strEQ(name, "LEFT_CTRL_PRESSED"))
            #ifdef LEFT_CTRL_PRESSED
                return LEFT_CTRL_PRESSED;
            #else
                goto not_there;
            #endif
		break;
    case 'M':
        break;
    case 'N':
        if (strEQ(name, "NUMLOCK_ON"))
            #ifdef NUMLOCK_ON
                return NUMLOCK_ON;
            #else
                goto not_there;
            #endif
        break;
    case 'O':
        break;
    case 'P':
        break;
    case 'Q':
        break;
    case 'R':
        if (strEQ(name, "RIGHT_ALT_PRESSED"))
            #ifdef RIGHT_ALT_PRESSED
                return RIGHT_ALT_PRESSED;
            #else
                goto not_there;
            #endif
        if (strEQ(name, "RIGHT_CTRL_PRESSED"))
            #ifdef RIGHT_CTRL_PRESSED
                return RIGHT_CTRL_PRESSED;
            #else
                goto not_there;
            #endif
		break;
    case 'S':
		if (strEQ(name, "SCROLLLOCK_ON"))
			#ifdef SCROLLLOCK_ON
				return SCROLLLOCK_ON;
			#else
				goto not_there;
			#endif
		if (strEQ(name, "SHIFT_PRESSED"))
			#ifdef SHIFT_PRESSED
				return SHIFT_PRESSED;
			#else
				goto not_there;
			#endif
		if (strEQ(name, "STD_ERROR_HANDLE"))
			#ifdef STD_ERROR_HANDLE
				return STD_ERROR_HANDLE;
			#else
				goto not_there;
			#endif
		if (strEQ(name, "STD_INPUT_HANDLE"))
			#ifdef STD_INPUT_HANDLE
				return STD_INPUT_HANDLE;
			#else
				goto not_there;
			#endif
		if (strEQ(name, "STD_OUTPUT_HANDLE"))
			#ifdef STD_OUTPUT_HANDLE
				return STD_OUTPUT_HANDLE;
			#else
				goto not_there;
			#endif
        break;
    case 'T':
        break;
    case 'U':
        break;
    case 'V':
        break;
    case 'W':
        break;
    case 'X':
        break;
    case 'Y':
        break;
    case 'Z':
        break;
    }
    errno = EINVAL;
    return 0;

not_there:
    errno = ENOENT;
    return 0;
}


/*
BOOL HandlerRoutine(DWORD dwCtrlType) {
	int count;
	int result;

	// printf("HandlerRoutine: CtrlType=%d\n", dwCtrlType);
	dSP;
	ENTER;
	SAVETMPS;
	PUSHMARK(sp);
	XPUSHs(sv_2mortal(newSViv(dwCtrlType)));
	PUTBACK;
	count = perl_call_pv("Win32::Console::CtrlHandler", G_EVAL|G_SCALAR);
	SPAGAIN;
    // Check the eval first
    //if (SvTRUE(GvSV(lerrgv))) {
    //    POPs ;
	//	PUTBACK ;
	//	FREETMPS ;
	//	LEAVE ;
	//	// ExitProcess(0);
	//	return(TRUE);
	//} else {
		if (count < 1) {
			result = 0;
		} else {
			result = POPi;
		}
		PUTBACK ;
		FREETMPS ;
		LEAVE ;
		printf("HandlerRoutine: result=%d\n", result);
		if (result == 0) {
			printf("HandlerRoutine: returning FALSE\n");
			return(FALSE);
		} else {
			printf("HandlerRoutine: returning TRUE\n");
			// ExitProcess(0);
			return(TRUE);
		}
	//}
}

void
_SetConsoleCtrlHandler(...)
PPCODE:
    if (SetConsoleCtrlHandler((PHANDLER_ROUTINE)HandlerRoutine,(BOOL)TRUE))
	XSRETURN_YES;
    else
	XSRETURN_NO;

*/



MODULE = Win32::Console		PACKAGE = Win32::Console

PROTOTYPES: DISABLE


DWORD
constant(name,arg)
    char *name
    int arg
CODE:
    RETVAL = constant(name, arg);
OUTPUT:
    RETVAL


void
_GetStdHandle(fd)
    DWORD fd
PPCODE:
#ifdef _WIN64
    XSRETURN_IV((DWORD_PTR)GetStdHandle(fd));
#else
    XSRETURN_IV((DWORD)GetStdHandle(fd));
#endif

void
_SetStdHandle(fd,handle)
    DWORD fd
    HANDLE handle
PPCODE:
    if (SetStdHandle(fd, handle))
	XSRETURN_YES;
    else
	XSRETURN_NO;


void
MouseButtons(...)
PPCODE:
    DWORD buttons;
    if (GetNumberOfConsoleMouseButtons(&buttons))
	XSRETURN_IV(buttons);
    else
	XSRETURN_NO;


void
_SetConsoleCursorPosition(handle,x,y)
    HANDLE handle
    SHORT x
    SHORT y
PPCODE:
    COORD coords;
    coords.X=x;
    coords.Y=y;
    if (SetConsoleCursorPosition(handle, coords))
        XSRETURN_YES;
    else
        XSRETURN_NO;


void
_WriteConsoleOutputAttribute(handle, string,x,y)
    HANDLE handle
    char * string
    SHORT x
    SHORT y
PPCODE:
    DWORD i;
    COORD coords;
    DWORD written;
    unsigned short buffer[80*999*sizeof(unsigned short)];
    DWORD towrite = (DWORD)strlen(string);

    for(i=0; i<towrite; i++) {
        buffer[i] = (unsigned short)(string[i]);
    }
    coords.X=x;
    coords.Y=y;
    if (WriteConsoleOutputAttribute(handle,
                                   (const unsigned short *)&buffer,
                                   towrite,
                                   coords,
                                   &written))
        XSRETURN_IV(written);
    else
        XSRETURN_NO;


void
_WriteConsoleOutputCharacter(handle,string,x,y)
    HANDLE handle
    char * string
    SHORT x
    SHORT y
PPCODE:
    COORD coords;
    DWORD written;
    coords.X=x;
    coords.Y=y;
    if (WriteConsoleOutputCharacter(handle,
                                   (LPCTSTR)string,
                                   (DWORD)strlen(string),
                                   coords,
                                   &written))
        XSRETURN_IV(written);
    else
        XSRETURN_NO;


void
_ReadConsoleOutputCharacter(handle,charbuf,len,x,y)
    HANDLE handle
    char * charbuf
    DWORD len
    SHORT x
    SHORT y
PPCODE:
    COORD coords;
    DWORD nofread;
    coords.X=x;
    coords.Y=y;
    if (ReadConsoleOutputCharacter(handle,charbuf,len,coords,&nofread))
        XSRETURN_YES;
    else
        XSRETURN_NO;


void
_ReadConsoleOutputAttribute(handle,len,x,y)
    HANDLE handle
    DWORD len
    SHORT x
    SHORT y
PPCODE:
    DWORD i;
    COORD coords;
    DWORD nofread;
    unsigned short abuffer[80*999*sizeof(unsigned short)];
    char cbuffer[80*999];

    coords.X=x;
    coords.Y=y;
    if (ReadConsoleOutputAttribute(handle,abuffer,len,coords,&nofread)) {
        for(i=0;i<nofread;i++) {
            cbuffer[i]=(char)abuffer[i];
        }
        ST(0)=sv_2mortal(newSVpv(cbuffer,nofread));
        XSRETURN(1);
    }
    else
        XSRETURN_NO;


void
_WriteConsole(handle,buffer)
    HANDLE handle
    char * buffer
PPCODE:
    DWORD written;
    if (WriteConsole(handle,(VOID *)buffer,(DWORD)strlen(buffer),&written,NULL))
        XSRETURN_IV(written);
    else
        XSRETURN_NO;


void
_ScrollConsoleScreenBuffer(handle,l1,t1,r1,b1,col,row,chr,attr,l2,t2,r2,b2)
    HANDLE handle
    SHORT l1
    SHORT t1
    SHORT r1
    SHORT b1
    SHORT col
    SHORT row
    WCHAR chr
    unsigned short attr
    SHORT l2
    SHORT t2
    SHORT r2
    SHORT b2
PPCODE:
    COORD dest;
    SMALL_RECT area;
    SMALL_RECT clip;
    CHAR_INFO fill;
    area.Left   = l1;
    area.Top    = t1;
    area.Right  = r1;
    area.Bottom = b1;
    dest.X=col;
    dest.Y=row;
#ifdef UNICODE
    fill.Char.UnicodeChar=chr;
#else
    fill.Char.AsciiChar=(CHAR)chr;
#endif
    fill.Attributes=attr;

    if (items > 9) {
	clip.Left   = l2;
	clip.Top    = t2;
	clip.Right  = r2;
	clip.Bottom = b2;
	if (ScrollConsoleScreenBuffer(handle,&area,&clip,dest,&fill))
	    XSRETURN_YES;
	else
	    XSRETURN_NO;
    }
    else {
	if (ScrollConsoleScreenBuffer(handle,&area,NULL,dest,&fill))
	    XSRETURN_YES;
	else
	    XSRETURN_NO;
    }


void
_WriteConsoleOutput(handle,buffer,srcwid,srcht,startx,starty,l,t,r,b)
    HANDLE handle
    char * buffer
    SHORT srcwid
    SHORT srcht
    SHORT startx
    SHORT starty
    SHORT l
    SHORT t
    SHORT r
    SHORT b
PPCODE:
    COORD coords;
    COORD size;
    SMALL_RECT to;

    size.X=srcwid;
    size.Y=srcht;
    coords.X=startx;
    coords.Y=starty;
    to.Left   = l;
    to.Top    = t;
    to.Right  = r;
    to.Bottom = b;
    if (WriteConsoleOutput(handle,(CHAR_INFO *)buffer,size,coords,&to)) {
        XST_mIV(0,to.Left);
        XST_mIV(1,to.Top);
        XST_mIV(2,to.Right);
        XST_mIV(3,to.Bottom);
        XSRETURN(4);
    }
    else
        XSRETURN_NO;


void
_ReadConsoleOutput(handle,buffer,srcwid,srcht,startx,starty,l,t,r,b)
    HANDLE handle
    char * buffer
    SHORT srcwid
    SHORT srcht
    SHORT startx
    SHORT starty
    SHORT l
    SHORT t
    SHORT r
    SHORT b
PPCODE:
    COORD coords;
    COORD size;
    SMALL_RECT from;
    size.X=srcwid;
    size.Y=srcht;
    coords.X=startx;
    coords.Y=starty;
    from.Left   = l;
    from.Top    = t;
    from.Right  = r;
    from.Bottom = b;
    if (ReadConsoleOutput(handle,(CHAR_INFO *)buffer,size,coords,&from)) {
        XST_mIV(0,from.Left);
        XST_mIV(1,from.Top);
        XST_mIV(2,from.Right);
        XST_mIV(3,from.Bottom);
        XSRETURN(4);
    }
    else
        XSRETURN_NO;


void
_SetConsoleWindowInfo(handle,flag,l,t,r,b)
    HANDLE handle
    BOOL flag
    SHORT l
    SHORT t
    SHORT r
    SHORT b
PPCODE:
    SMALL_RECT newwin;
    newwin.Left   = l;
    newwin.Top    = t;
    newwin.Right  = r;
    newwin.Bottom = b;
    if (SetConsoleWindowInfo(handle,flag,&newwin))
        XSRETURN_YES;
    else
        XSRETURN_NO;


void
_GetNumberOfConsoleInputEvents(handle)
    HANDLE handle
PPCODE:
    DWORD nofevents;
    if (GetNumberOfConsoleInputEvents(handle, &nofevents))
        XSRETURN_IV(nofevents);
    else
        XSRETURN_NO;


void
_FlushConsoleInputBuffer(handle)
    HANDLE handle
PPCODE:
    if (FlushConsoleInputBuffer(handle))
        XSRETURN_YES;
    else
        XSRETURN_NO;


void
_ReadConsole(handle,buffer,numread)
    HANDLE handle
    char * buffer
    DWORD numread
PPCODE:
    DWORD nofread;
    if (ReadConsole(handle,(void *)buffer,numread,&nofread,NULL))
        XSRETURN_IV(nofread);
    else
        XSRETURN_NO;


void
_ReadConsoleInput(handle)
    HANDLE handle
PPCODE:
    DWORD nofread;
    INPUT_RECORD event;
    KEY_EVENT_RECORD * kevent;
    MOUSE_EVENT_RECORD * mevent;
    if (ReadConsoleInput(handle,&event,1,&nofread)) {
	switch(event.EventType) {
	case KEY_EVENT:
	    EXTEND(SP,7);
	    kevent=(KEY_EVENT_RECORD *)&(event.Event);
	    XST_mIV(0,KEY_EVENT);
	    XST_mIV(1,kevent->bKeyDown);
	    XST_mIV(2,kevent->wRepeatCount);
	    XST_mIV(3,kevent->wVirtualKeyCode);
	    XST_mIV(4,kevent->wVirtualScanCode);
#ifdef UNICODE
	    XST_mIV(5,kevent->uChar.UnicodeChar);
#else
	    XST_mIV(5,kevent->uChar.AsciiChar);
#endif
	    XST_mIV(6,kevent->dwControlKeyState);
	    XSRETURN(7);
	    break;
	case MOUSE_EVENT:
	    EXTEND(SP,6);
	    mevent=(MOUSE_EVENT_RECORD *)&(event.Event);
	    XST_mIV(0,MOUSE_EVENT);
	    XST_mIV(1,mevent->dwMousePosition.X);
	    XST_mIV(2,mevent->dwMousePosition.Y);
	    XST_mIV(3,mevent->dwButtonState);
	    XST_mIV(4,mevent->dwControlKeyState);
	    XST_mIV(5,mevent->dwEventFlags);
	    XSRETURN(6);
	    break;
	}
    }
    else {
        XSRETURN_NO;
    }


void
_WriteConsoleInput(handle,type,...)
    HANDLE handle
    int type
PPCODE:
    DWORD written;
    INPUT_RECORD event;
    KEY_EVENT_RECORD * kevent;
    MOUSE_EVENT_RECORD * mevent;
    event.EventType = type;
    switch(event.EventType) {
    case KEY_EVENT:
	kevent = (KEY_EVENT_RECORD *)&(event.Event);
        kevent->bKeyDown          = (BOOL)SvIV(ST(2));
        kevent->wRepeatCount      = (WORD)SvIV(ST(3));
        kevent->wVirtualKeyCode   = (WORD)SvIV(ST(4));
        kevent->wVirtualScanCode  = (WORD)SvIV(ST(5));
#ifdef UNICODE
        kevent->uChar.UnicodeChar = (WCHAR)SvIV(ST(6));
#else
        kevent->uChar.AsciiChar   = (CHAR)SvIV(ST(7));
#endif
	break;
    case MOUSE_EVENT:
	mevent = (MOUSE_EVENT_RECORD *)&(event.Event);
        mevent->dwMousePosition.X = (SHORT)SvIV(ST(2));
        mevent->dwMousePosition.Y = (SHORT)SvIV(ST(3));
        mevent->dwButtonState     = (DWORD)SvIV(ST(4));
        mevent->dwControlKeyState = (DWORD)SvIV(ST(5));
        mevent->dwEventFlags      = (DWORD)SvIV(ST(6));
	break;
    default:
	XSRETURN_NO;
	break;
    }
    if (WriteConsoleInput(handle,&event,1,&written))
	XSRETURN_YES;
    else
	XSRETURN_NO;


void
_PeekConsoleInput(handle)
    HANDLE handle
PPCODE:
    DWORD nofread;
    INPUT_RECORD event;
    KEY_EVENT_RECORD * kevent;
    MOUSE_EVENT_RECORD * mevent;
    if (PeekConsoleInput(handle,&event,1,&nofread)) {
	switch(event.EventType) {
	case KEY_EVENT:
	    EXTEND(SP,7);
	    kevent=(KEY_EVENT_RECORD *)&(event.Event);
	    XST_mIV(0,KEY_EVENT);
	    XST_mIV(1,kevent->bKeyDown);
	    XST_mIV(2,kevent->wRepeatCount);
	    XST_mIV(3,kevent->wVirtualKeyCode);
	    XST_mIV(4,kevent->wVirtualScanCode);
#ifdef UNICODE
	    XST_mIV(5,kevent->uChar.UnicodeChar);
#else
	    XST_mIV(5,kevent->uChar.AsciiChar);
#endif
	    XST_mIV(6,kevent->dwControlKeyState);
	    XSRETURN(7);
	    break;
	case MOUSE_EVENT:
	    EXTEND(SP,6);
	    mevent=(MOUSE_EVENT_RECORD *)&(event.Event);
	    XST_mIV(0,MOUSE_EVENT);
	    XST_mIV(1,mevent->dwMousePosition.X);
	    XST_mIV(2,mevent->dwMousePosition.Y);
	    XST_mIV(3,mevent->dwButtonState);
	    XST_mIV(4,mevent->dwControlKeyState);
	    XST_mIV(5,mevent->dwEventFlags);
	    XSRETURN(6);
	    break;
	}
    }
    else
        XSRETURN_NO;


void
_SetConsoleMode(handle,mode)
    HANDLE handle
    DWORD mode
PPCODE:
    if (SetConsoleMode(handle, mode))
        XSRETURN_YES;
    else
        XSRETURN_NO;


void
_GetConsoleMode(handle)
    HANDLE handle
PPCODE:
    DWORD flags;
    if (GetConsoleMode(handle, &flags))
        XSRETURN_IV(flags);
    else
        XSRETURN_NO;


void
_SetConsoleTextAttribute(handle,attr)
    HANDLE handle
    WORD attr
PPCODE:
    if (SetConsoleTextAttribute(handle,attr))
        XSRETURN_YES;
    else
        XSRETURN_NO;

void
_GetConsoleScreenBufferInfo(handle)
    HANDLE handle
PPCODE:
    CONSOLE_SCREEN_BUFFER_INFO info;
    if (GetConsoleScreenBufferInfo(handle,&info)) {
	EXTEND(SP,11);
        XST_mIV( 0,info.dwSize.X);
        XST_mIV( 1,info.dwSize.Y);
        XST_mIV( 2,info.dwCursorPosition.X);
        XST_mIV( 3,info.dwCursorPosition.Y);
        XST_mIV( 4,info.wAttributes);
        XST_mIV( 5,info.srWindow.Left);
        XST_mIV( 6,info.srWindow.Top);
        XST_mIV( 7,info.srWindow.Right);
        XST_mIV( 8,info.srWindow.Bottom);
        XST_mIV( 9,info.dwMaximumWindowSize.X);
        XST_mIV(10,info.dwMaximumWindowSize.Y);
        XSRETURN(11);
    }
    else
        XSRETURN_NO;

void
_SetConsoleScreenBufferSize(handle,x,y)
    HANDLE handle
    SHORT x
    SHORT y
PPCODE:
    COORD size;
    size.X=x;
    size.Y=y;
    if (SetConsoleScreenBufferSize(handle, size))
        XSRETURN_YES;
    else
        XSRETURN_NO;


void
_GetConsoleCursorInfo(handle)
    HANDLE handle
PPCODE:
    CONSOLE_CURSOR_INFO info;
    if (GetConsoleCursorInfo(handle, &info)) {
	EXTEND(SP,2);
        XST_mIV(0,info.dwSize);
        XST_mIV(1,info.bVisible);
        XSRETURN(2);
    }
    else
        XSRETURN_NO;


void
_SetConsoleCursorInfo(handle,size,visible)
    HANDLE handle
    DWORD size
    BOOL visible
PPCODE:
    CONSOLE_CURSOR_INFO info;
    info.dwSize=size;
    info.bVisible=visible;
    if (SetConsoleCursorInfo(handle, &info))
        XSRETURN_YES;
    else
        XSRETURN_NO;


void
_FillConsoleOutputAttribute(handle,attr,len,x,y)
    HANDLE handle
    WORD attr
    DWORD len
    SHORT x
    SHORT y
PPCODE:
    COORD coords;
    DWORD written;
    coords.X=x;
    coords.Y=y;
    if (FillConsoleOutputAttribute(handle,attr,len,coords,&written))
        XSRETURN_IV(written);
    else
        XSRETURN_NO;


void
_FillConsoleOutputCharacter(handle,chr,len,x,y)
    HANDLE handle
    char * chr
    DWORD len
    SHORT x
    SHORT y
PPCODE:
    COORD coords;
    DWORD written;
    coords.X=x;
    coords.Y=y;
    if (FillConsoleOutputCharacter(handle, *chr, len, coords, &written))
        XSRETURN_IV(written);
    else
        XSRETURN_NO;


void
_CreateConsoleScreenBuffer(access,sharemode,flags)
    DWORD access
    DWORD sharemode
    DWORD flags
PPCODE:
    HANDLE handle;
    handle=CreateConsoleScreenBuffer(access,sharemode,NULL,flags,NULL);
#ifdef _WIN64
    XSRETURN_IV((DWORD_PTR)handle);
#else
    XSRETURN_IV((DWORD)handle);
#endif

void
_SetConsoleActiveScreenBuffer(handle)
    HANDLE handle
PPCODE:
    if (SetConsoleActiveScreenBuffer(handle))
        XSRETURN_YES;
    else
        XSRETURN_NO;


void
Alloc(...)
PPCODE:
    if (AllocConsole())
        XSRETURN_YES;
    else
        XSRETURN_NO;


void
Free(...)
PPCODE:
    if (FreeConsole())
        XSRETURN_YES;
    else
        XSRETURN_NO;


void
_GetConsoleTitle(...)
PPCODE:
    char title[1024];
    if (GetConsoleTitle((char *)&title,1024)) {
        ST(0)=sv_2mortal(newSVpv((char *)title,strlen(title)));
        XSRETURN(1);
    }
    else
        XSRETURN_NO;


void
_SetConsoleTitle(title)
    char *title
PPCODE:
    if (SetConsoleTitle(title))
        XSRETURN_YES;
    else
        XSRETURN_NO;


void
_GetLargestConsoleWindowSize(handle)
    HANDLE handle
PPCODE:
    COORD size;
    size=GetLargestConsoleWindowSize(handle);
    EXTEND(SP,2);
    XST_mIV(0,size.X);
    XST_mIV(1,size.Y);
    XSRETURN(2);


void
_GetConsoleCP(...)
PPCODE:
    XSRETURN_IV((long)GetConsoleCP());


void
_SetConsoleCP(cp)
    UINT cp
PPCODE:
    XSRETURN_IV((long)SetConsoleCP(cp));


void
_GetConsoleOutputCP(...)
PPCODE:
    XSRETURN_IV((long)GetConsoleOutputCP());


void
_SetConsoleOutputCP(cp)
    UINT cp
PPCODE:
    XSRETURN_IV((long)SetConsoleOutputCP(cp));


void
_CloseHandle(handle)
    HANDLE handle
PPCODE:
    XSRETURN_IV((long)CloseHandle(handle));


void
_GenerateConsoleCtrlEvent(event,pgid)
    DWORD event
    DWORD pgid
PPCODE:
    if (GenerateConsoleCtrlEvent(event,pgid))
	XSRETURN_YES;
    else
	XSRETURN_NO;


void
_SetConsoleIcon(iconfile)
    LPCSTR  iconfile
PPCODE:
    HANDLE  oldBigIcon   = wndBigIcon;
    HANDLE  oldSmallIcon = wndSmallIcon;
    HWND    wnd = GetConsoleHwnd();

    if (!wnd) XSRETURN_NO;

    wndBigIcon = LoadImage(NULL, iconfile, IMAGE_ICON,
                           0,0, LR_DEFAULTSIZE | LR_LOADFROMFILE);
    if (!wndBigIcon) XSRETURN_NO;
    wndSmallIcon = LoadImage(NULL, iconfile, IMAGE_ICON,
                             SMALL_ICON_SIZE, SMALL_ICON_SIZE,
                             LR_LOADFROMFILE);
    if (!wndSmallIcon) XSRETURN_NO;

    SendMessage(wnd, WM_SETICON, (WPARAM) ICON_BIG, (LPARAM) wndBigIcon);
    SendMessage(wnd, WM_SETICON, (WPARAM) ICON_SMALL, (LPARAM) wndSmallIcon);

    if (oldBigIcon)   DestroyIcon(oldBigIcon);
    if (oldSmallIcon) DestroyIcon(oldSmallIcon);

    XSRETURN_YES;
