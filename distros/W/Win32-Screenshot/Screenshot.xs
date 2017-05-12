#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "ppport.h"

#include <windows.h>

#include "const-c.inc"

MODULE = Win32::Screenshot		PACKAGE = Win32::Screenshot

INCLUDE: const-xs.inc

############################################################################

HWND
WindowFromPoint(x,y)
    LONG x
    LONG y
PREINIT:
    POINT myPoint;
CODE:
    myPoint.x = x;
    myPoint.y = y;
    RETVAL = WindowFromPoint(myPoint);
OUTPUT:
    RETVAL

############################################################################

HWND
GetForegroundWindow()
CODE:
   RETVAL = GetForegroundWindow();
OUTPUT:
   RETVAL

############################################################################

HWND
GetDesktopWindow()
CODE:
   RETVAL = GetDesktopWindow();
OUTPUT:
   RETVAL

############################################################################

HWND
GetActiveWindow()
CODE:
    RETVAL = GetActiveWindow();
OUTPUT:
    RETVAL

############################################################################

HWND
GetWindow(handle,command)
    HWND handle
    UINT command
CODE:
    RETVAL = GetWindow(handle, command);
OUTPUT:
    RETVAL

############################################################################

HWND
FindWindow(classname,windowname)
    LPCTSTR classname
    LPCTSTR windowname
CODE:
    if(strlen(classname) == 0) classname = NULL;
    if(strlen(windowname) == 0) windowname = NULL;
    RETVAL = FindWindow(classname, windowname);
OUTPUT:
    RETVAL

############################################################################

BOOL
ShowWindow(handle,command=SW_SHOWNORMAL)
    HWND handle
    int command
CODE:
    RETVAL = ShowWindow(handle, command);
OUTPUT:
    RETVAL

############################################################################

void
GetCursorPos()
PREINIT:
    POINT point;
PPCODE:
    if(GetCursorPos(&point)) {
        EXTEND(SP, 2);
        PUSHs(sv_2mortal(newSViv(point.x)));
        PUSHs(sv_2mortal(newSViv(point.y)));
        XSRETURN(2);
    } else {
        XSRETURN_NO;
    }

############################################################################

BOOL
SetCursorPos(x,y)
    int x
    int y
CODE:
    RETVAL = SetCursorPos(x, y);
OUTPUT:
    RETVAL

############################################################################

void
GetClientRect(handle)
    HWND handle
PREINIT:
    RECT myRect;
PPCODE:
    if(GetClientRect(handle, &myRect)) {
        EXTEND(SP, 4);
        PUSHs(sv_2mortal(newSViv(myRect.left  )));
        PUSHs(sv_2mortal(newSViv(myRect.top   )));
        PUSHs(sv_2mortal(newSViv(myRect.right )));
        PUSHs(sv_2mortal(newSViv(myRect.bottom)));
        XSRETURN(4);
    } else {
        XSRETURN_NO;
    }

############################################################################

void
GetWindowRect(handle)
    HWND handle
PREINIT:
    RECT myRect;
PPCODE:
    if(GetWindowRect(handle, &myRect)) {
        EXTEND(SP, 4);
        PUSHs(sv_2mortal(newSViv(myRect.left  )));
        PUSHs(sv_2mortal(newSViv(myRect.top   )));
        PUSHs(sv_2mortal(newSViv(myRect.right )));
        PUSHs(sv_2mortal(newSViv(myRect.bottom)));
        XSRETURN(4);
    } else {
        XSRETURN_NO;
    }

############################################################################

BOOL
BringWindowToTop(handle)
    HWND handle
CODE:
    RETVAL = BringWindowToTop(handle);
OUTPUT:
    RETVAL

############################################################################

void
GetWindowText(handle)
    HWND handle
PREINIT:
    char *myBuffer;
    int myLength;
PPCODE:
    myLength = GetWindowTextLength(handle)+1;
    if(myLength) {
      myBuffer = (char *) safemalloc(myLength);
      if(GetWindowText(handle, myBuffer, myLength)) {
        EXTEND(SP, 1);
        PUSHs(sv_2mortal(newSVpvn((char*) myBuffer, myLength)));
        safefree(myBuffer);
        XSRETURN(1);
      }
      safefree(myBuffer);
    }
    XSRETURN_NO;

############################################################################

BOOL
Restore(handle)
    HWND handle
CODE:
    RETVAL = OpenIcon(handle);
OUTPUT:
    RETVAL

############################################################################

BOOL
Minimize(handle)
    HWND handle
CODE:
    RETVAL = CloseWindow(handle);
OUTPUT:
    RETVAL

############################################################################

BOOL
IsVisible(handle)
    HWND handle
CODE:
    RETVAL = IsWindowVisible(handle);
OUTPUT:
    RETVAL

############################################################################

HWND
GetTopWindow(handle)
    HWND handle
CODE:
    RETVAL = GetTopWindow(handle);
OUTPUT:
    RETVAL

############################################################################

BOOL
ScrollWindow(handle, delta_x, delta_y)
    HWND handle
    int	delta_x
    int	delta_y
CODE:
    RETVAL = ScrollWindowEx(handle, delta_x, delta_y, NULL, NULL, NULL, NULL, SW_INVALIDATE);
OUTPUT:
    RETVAL

############################################################################

void
JoinRawData(ww1, ww2, hh, raw1, raw2)
    LONG ww1
    LONG ww2
    LONG hh
    LPVOID raw1
    LPVOID raw2
PREINIT:
    long	i;
    long	bufferlen;
    char *	buffer;
    char *	ptr_dest;
    char *	ptr_raw1;
    char *	ptr_raw2;
PPCODE:
    /* allocate output buffer */
    bufferlen = hh * ww1 * 4 + hh * ww2 * 4;
    buffer = (LPVOID) safemalloc(bufferlen);

    /* copy the scan lines */
    ptr_dest = buffer;
    ptr_raw1 = raw1;
    ptr_raw2 = raw2;
    for ( i=0 ; i<hh ; i++ ) {
      memcpy( ptr_dest, ptr_raw1, ww1 * 4 );
      ptr_dest += ww1 * 4;
      ptr_raw1 += ww1 * 4;
      memcpy( ptr_dest, ptr_raw2, ww2 * 4 );
      ptr_dest += ww2 * 4;
      ptr_raw2 += ww2 * 4;
    }

    /* output */
    EXTEND(SP, 1);
    PUSHs(sv_2mortal(newSVpvn((char*) buffer, bufferlen)));
    safefree(buffer);
    XSRETURN(1);


############################################################################

void
CaptureHwndRect(handle, xx, yy, ww, hh)
    HWND handle
    LONG xx
    LONG yy
    LONG ww
    LONG hh
PREINIT:
    HDC		hdc;
    HDC		my_hdc;
    HBITMAP	my_hbmp;
    BITMAPINFO  my_binfo;
    long	bufferlen;
    LPVOID	buffer;
    int		out;
    long	i;
    long	*p;
PPCODE:

    hdc = GetDC(handle);

    /* create in-memory bitmap for storing the copy of the screen */
    my_hdc  = CreateCompatibleDC(hdc);
    my_hbmp = CreateCompatibleBitmap(hdc, ww, hh);
    SelectObject(my_hdc, my_hbmp);

    /* copy the part of screen to our in-memory place */
    BitBlt(my_hdc, 0, 0, ww, hh, hdc, xx, yy, SRCCOPY);

    /* now get a 32bit device independent bitmap */
    ZeroMemory(&my_binfo, sizeof(BITMAPINFO));

    /* prepare a buffer to hold the screen data */
    bufferlen = hh * ww * 4;
    buffer = (LPVOID) safemalloc(bufferlen);

    /* prepare directions for GetDIBits */
    my_binfo.bmiHeader.biSize 	     = sizeof(BITMAPINFOHEADER);
    my_binfo.bmiHeader.biWidth       = ww;
    my_binfo.bmiHeader.biHeight      = -hh; /* negative because we want top-down bitmap */
    my_binfo.bmiHeader.biPlanes      = 1;
    my_binfo.bmiHeader.biBitCount    = 32; /* we want RGBQUAD data */
    my_binfo.bmiHeader.biCompression = BI_RGB;

    if(GetDIBits(my_hdc, my_hbmp, 0, hh, buffer, &my_binfo, DIB_RGB_COLORS)) {

        /* Convert RGBQUADs to format expected by Image::Magick .rgba file (BGRX -> RGBX) */
        p = buffer;
        for( i = 0 ; i < bufferlen/4 ; i++  ) {
          *p = ((*p & 0x000000ff) << 16) | ((*p & 0x00ff0000) >> 16) | (*p & 0x0000ff00) | 0xff000000;
          p++;
        }

        EXTEND(SP, 3);
        PUSHs(sv_2mortal(newSViv(my_binfo.bmiHeader.biWidth)));
        PUSHs(sv_2mortal(newSViv(abs(my_binfo.bmiHeader.biHeight))));
        PUSHs(sv_2mortal(newSVpvn((char*) buffer, bufferlen)));
        out = 1;
    } else {
      out = 0;
    }

    safefree(buffer);
    DeleteDC(my_hdc);
    ReleaseDC(handle, hdc);
    DeleteObject(my_hbmp);

    if ( out == 1 ) { XSRETURN(3); } else { XSRETURN_NO; }

############################################################################
