/*
#######################################################################
#
# Win32::Clipboard - Interaction with the Windows clipboard
#
# Version: 0.58
# Created: 19 Nov 96
# Author: Aldo Calpini <dada@perl.it>
#
# Modified: 24 Jul 2004
# By: Hideyo Imazu <h@imazu.net>
#
#######################################################################
 */

/* uncomment next line for debug messages */
// #define WIN32__CLIPBOARD__DEBUG

#define  WIN32_LEAN_AND_MEAN
#include <windows.h>
#include <string.h>
#include <wchar.h>
#include <winuser.h>
#include <shellapi.h>

#define __TEMP_WORD  WORD   /* perl defines a WORD, yikes! */

#ifdef __cplusplus
#include <stdlib.h>
#include <math.h>
extern "C" {
#endif

#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#ifdef __cplusplus
}
#endif

#include "ppport.h"

#undef WORD
#define WORD __TEMP_WORD

// Section for the constant definitions.
#define CROAK croak
#define MAX_LENGTH 2048
#define TMPBUFSZ 1024

static HWND hwndThisViewer;
static HWND hwndNextViewer;
static HANDLE hEvt;
static HANDLE hThread;

/* DLL entry point */
BOOL WINAPI DllMain(HINSTANCE hDll, DWORD reason, LPVOID reserved) {
    //    BOOL ccb;
#ifdef WIN32__CLIPBOARD__DEBUG
    printf("!XS(DllMain): DLL entry point called with reason: %ld\n", reason);
    printf("!XS(DllMain): ClipboardViewer is: %ld\n", GetClipboardViewer());
#endif
    if((reason == DLL_THREAD_ATTACH ||
        reason == DLL_THREAD_DETACH) && hwndThisViewer) {
#ifdef WIN32__CLIPBOARD__DEBUG
        printf("!XS(DllMain): hwndThisViewer=%ld\n", hwndThisViewer);
        printf("!XS(DllMain): hwndNextViewer=%ld\n", hwndNextViewer);
        printf("!XS(DllMain): ClipboardViewer is: %ld\n", GetClipboardViewer());
#endif
        // Remove the window from the Clipboard viewers chain
        // ccb = ChangeClipboardChain(hwndThisViewer, hwndNextViewer);
        // printf("\tChangeClipboardChain(%ld,%ld).result = %d\n", hwndThisViewer, hwndNextViewer, ccb);
        // Inform the next window we're closing
        // SendMessage(hwndNextViewer,
        //             WM_CHANGECBCHAIN,
        //             (WPARAM) hwndThisViewer,
        //             (LPARAM) hwndNextViewer);

        // kill the window
        SendMessage(hwndThisViewer, WM_DESTROY, 0, 0);
        // DestroyWindow(hwndThisViewer);
        // SendMessage(hwndThisViewer, WM_QUIT, 0, 0);
#ifdef WIN32__CLIPBOARD__DEBUG
        printf("!XS(DllMain): ClipboardViewer is now: %ld\n", GetClipboardViewer());
#endif
    }
	return TRUE;
}

/* Clipboard Viewer Window Procedure */
LRESULT CALLBACK ClipboardViewerWndProc(HWND hwnd, UINT uMsg, WPARAM wParam, LPARAM lParam) {

    BOOL ccb;

    // printf("!XS(ClipboardViewerWndProc): got uMsg=%d\n", uMsg);
    switch(uMsg) {
    case WM_CREATE:
#ifdef WIN32__CLIPBOARD__DEBUG
        printf("!XS(ClipboardViewerWndProc): got WM_CREATE\n");
#endif
        hwndNextViewer = SetClipboardViewer(hwnd);
#ifdef WIN32__CLIPBOARD__DEBUG
        printf("!XS(ClipboardViewerWndProc): hwndNextViewer=%ld\n", hwndNextViewer);
        printf("!XS(ClipboardViewerWndProc): ClipboardViewer is now: %ld\n", GetClipboardViewer());
#endif
        break;
    case WM_DRAWCLIPBOARD:
#ifdef WIN32__CLIPBOARD__DEBUG
        printf("!XS(ClipboardViewerWndProc): got WM_DRAWCLIPBOARD (my hwnd is %ld)\n", hwnd);
#endif
        // pass the message to the next viewer
        SendMessage(hwndNextViewer, uMsg, wParam, lParam);
        // stop waiting
        SetEvent(hEvt);
        break;
    case WM_CHANGECBCHAIN:
#ifdef WIN32__CLIPBOARD__DEBUG
        printf("!XS(ClipboardViewerWndProc): got WM_CHANGECBCHAIN\n");
#endif
        // If the next window is closing, repair the chain.
        if ((HWND) wParam == hwndNextViewer)
            hwndNextViewer = (HWND) lParam;
        // Otherwise, pass the message to the next link.
        else if (hwndNextViewer != NULL)
            SendMessage(hwndNextViewer, uMsg, wParam, lParam);
#ifdef WIN32__CLIPBOARD__DEBUG
        printf("!XS(ClipboardViewerWndProc): ClipboardViewer is now: %ld\n", GetClipboardViewer());
#endif
        break;
    case WM_DESTROY:
#ifdef WIN32__CLIPBOARD__DEBUG
        printf("!XS(ClipboardViewerWndProc): got WM_DESTROY\n");
        printf("!XS(ClipboardViewerWndProc): ClipboardViewer is: %ld\n", GetClipboardViewer());
#endif
        ccb = ChangeClipboardChain(hwnd, hwndNextViewer);
#ifdef WIN32__CLIPBOARD__DEBUG
        printf("!XS(ClipboardViewerWndProc): ChangeClipboardChain(%ld,%ld).result = %d\n", hwnd, hwndNextViewer, ccb);
        printf("!XS(ClipboardViewerWndProc): ClipboardViewer is now: %ld\n", GetClipboardViewer());
#endif
        // ChangeClipboardChain(hwnd, hwndNextViewer);
        CloseHandle(hEvt);
        // ExitThread(0);
        PostQuitMessage(0);
        break;
    case WM_QUIT:
#ifdef WIN32__CLIPBOARD__DEBUG
        printf("!XS(ClipboardViewerWndProc): got WM_QUIT\n");
        printf("!XS(ClipboardViewerWndProc): ClipboardViewer is now: %ld\n", GetClipboardViewer());
#endif
        break;
    default:
#ifdef WIN32__CLIPBOARD__DEBUG
        printf("!XS(ClipboardViewerWndProc): got %d\n", uMsg);
#endif
        return DefWindowProc(hwnd, uMsg, wParam, lParam);
    }
    return (LRESULT) NULL;
}

// msgs: 36, 129, 131, 1, 776
//       24,  81,  83, 1, 308


/* ClipboardViewer Thread Function */
DWORD WINAPI ClipboardViewer(LPVOID hEvt) {

    WNDCLASSEX wcx;
    MSG msg;
    HWND hwnd;
    int stayhere;

    ZeroMemory(&wcx, sizeof(WNDCLASSEX));
    wcx.cbSize = sizeof(WNDCLASSEX);
    wcx.lpfnWndProc = ClipboardViewerWndProc;
    wcx.lpszClassName = "PERL-CLIPBOARD-VIEWER";

    if(RegisterClassEx(&wcx)) {
        if(hwnd = CreateWindowEx(
			0,
            wcx.lpszClassName,
            "", 0,
            1, 1, 1, 1,
            NULL, // perl_hwnd,
            NULL, NULL, NULL)
        ) {
            hwndThisViewer = hwnd;

            // manage the window
            stayhere = 1;
            while (stayhere) {
                stayhere = GetMessage(&msg, hwnd, 0, 0);
                if(stayhere == -1) {
                    stayhere = 0;
                } else {
                    TranslateMessage(&msg);
                    DispatchMessage(&msg);
                }
            }
            return 1;
        } else {
#ifdef WIN32__CLIPBOARD__DEBUG
            printf("!XS(ClipboardViewer): CreateWindowEx FAILED (%d)\n", GetLastError());
#endif
        }
    } else {
#ifdef WIN32__CLIPBOARD__DEBUG
        printf("!XS(ClipboardViewer): RegisterClassEx FAILED (%d)\n", GetLastError());
#endif
    }
    return 0;
}

HANDLE StartClipboardViewer() {

    DWORD CBVid;
    HANDLE CBVhandle;

    hEvt = CreateEvent(NULL, TRUE, TRUE, "PERL_CLIPBOARD_VIEWER");
#ifdef WIN32__CLIPBOARD__DEBUG
    // printf("!XS(StartClipboardViewer): hEvt=%ld\n", hEvt);
#endif
    CBVhandle = CreateThread(
        NULL, 0,
        (LPTHREAD_START_ROUTINE) ClipboardViewer,
        NULL,
        0,
        &CBVid
    );
    if(CBVhandle == NULL) {
#ifdef WIN32__CLIPBOARD__DEBUG
        printf("!XS(StartClipboardViewer): CreateThread FAILED (%d)\n", GetLastError());
#endif
        return NULL;
    } else {
#ifdef WIN32__CLIPBOARD__DEBUG
        printf("!XS(StartClipboardViewer): Thread created (%ld)\n", CBVhandle);
#endif
        return CBVhandle;
    }
}

long
constant(char *name, int arg)
{
    errno = 0;
	if (strEQ(name, "CF_TEXT"))
#ifdef CF_TEXT
			return CF_TEXT;
#else
			goto not_there;
#endif
	if (strEQ(name, "CF_BITMAP"))
#ifdef CF_BITMAP
			return CF_BITMAP;
#else
			goto not_there;
#endif
	if (strEQ(name, "CF_METAFILEPICT"))
#ifdef CF_METAFILEPICT
			return CF_METAFILEPICT;
#else
			goto not_there;
#endif
	if (strEQ(name, "CF_SYLK"))
#ifdef CF_SYLK
			return CF_SYLK;
#else
			goto not_there;
#endif
	if (strEQ(name, "CF_DIF"))
#ifdef CF_DIF
			return CF_DIF;
#else
			goto not_there;
#endif
	if (strEQ(name, "CF_TIFF"))
#ifdef CF_TIFF
			return CF_TIFF;
#else
			goto not_there;
#endif
	if (strEQ(name, "CF_OEMTEXT"))
#ifdef CF_OEMTEXT
			return CF_OEMTEXT;
#else
			goto not_there;
#endif
	if (strEQ(name, "CF_DIB"))
#ifdef CF_DIB
			return CF_DIB;
#else
			goto not_there;
#endif
	if (strEQ(name, "CF_PALETTE"))
#ifdef CF_PALETTE
			return CF_PALETTE;
#else
			goto not_there;
#endif
	if (strEQ(name, "CF_PENDATA"))
#ifdef CF_PENDATA
			return CF_PENDATA;
#else
			goto not_there;
#endif
	if (strEQ(name, "CF_RIFF"))
#ifdef CF_RIFF
			return CF_RIFF;
#else
			goto not_there;
#endif
	if (strEQ(name, "CF_WAVE"))
#ifdef CF_WAVE
			return CF_WAVE;
#else
			goto not_there;
#endif
	if (strEQ(name, "CF_UNICODETEXT"))
#ifdef CF_UNICODETEXT
			return CF_UNICODETEXT;
#else
			goto not_there;
#endif
	if (strEQ(name, "CF_ENHMETAFILE"))
#ifdef CF_ENHMETAFILE
			return CF_ENHMETAFILE;
#else
			goto not_there;
#endif
	if (strEQ(name, "CF_HDROP"))
#ifdef CF_HDROP
			return CF_HDROP;
#else
			goto not_there;
#endif
	if (strEQ(name, "CF_LOCALE"))
#ifdef CF_LOCALE
			return CF_LOCALE;
#else
			goto not_there;
#endif
    errno = EINVAL;
    return 0;

not_there:
    errno = ENOENT;
    return 0;
}

int
study_dib(HANDLE h, PBITMAPFILEHEADER p_hdr)
{
    LPBITMAPINFO bmi;
    int bitCount;
    int clrUsed;
    int mask_bytes = 0;
    int rgbquad_array_length;
    int dib_offset, dib_size;
    bmi = (LPBITMAPINFO) h;
    bitCount = bmi->bmiHeader.biBitCount;
    clrUsed = bmi->bmiHeader.biClrUsed;
    if ( bitCount == 16 || bitCount == 32 ) mask_bytes = 12;
    if ( bitCount < 16 && clrUsed == 0 )
	rgbquad_array_length = 1 << bitCount;
    else
	rgbquad_array_length = clrUsed;
    dib_offset = bmi->bmiHeader.biSize + mask_bytes +
	rgbquad_array_length * sizeof(RGBQUAD);
    dib_size = dib_offset + bmi->bmiHeader.biSizeImage;
    p_hdr->bfType = 0x4d42;        /* 0x42 = "B" 0x4d = "M" */
    p_hdr->bfSize = (DWORD) (sizeof(BITMAPFILEHEADER) + dib_size);
    p_hdr->bfReserved1 = 0;
    p_hdr->bfReserved2 = 0;
    p_hdr->bfOffBits = (DWORD) (sizeof(BITMAPFILEHEADER) + dib_offset);
    return dib_size;
}

MODULE = Win32::Clipboard   PACKAGE = Win32::Clipboard

PROTOTYPES: DISABLE

long
constant(name, arg)
    char *name
    int arg
CODE:
    RETVAL = constant(name, arg);
OUTPUT:
    RETVAL

void
StartClipboardViewer(...)
PPCODE:
    if(hThread == NULL)
        hThread = StartClipboardViewer();

void
StopClipboardViewer(...)
PPCODE:
    char NextText[1024];
    if(hwndThisViewer) {
#ifdef WIN32__CLIPBOARD__DEBUG
        printf("XS(StartClipboardViewer): hwndThisViewer=%ld\n", hwndThisViewer);
        printf("XS(StartClipboardViewer): hwndNextViewer=%ld\n", hwndNextViewer);
#endif
        GetWindowText(hwndNextViewer, NextText, 1024);
        // DestroyWindow(hwndThisViewer);
        SendMessage(hwndThisViewer, WM_DESTROY, 0, 0);
        SendMessage(hwndThisViewer, WM_QUIT, 0, 0);
        // PostQuitMessage(0);
        // ChangeClipboardChain(hwndThisViewer, hwndNextViewer);
        if(IsWindow(hwndThisViewer)) {
            XSRETURN_IV((long) -1);
        } else {
            hwndThisViewer = NULL;
            XSRETURN_YES;
        }
    } else {
        XSRETURN_NO;
    }


void
WaitForChange(...)
PPCODE:
    DWORD cause;
	DWORD timeout;

    if(hThread == NULL) {
#ifdef WIN32__CLIPBOARD__DEBUG
        printf("XS(WaitForChange): Starting the clipboard viewer...\n");
#endif
        hThread = StartClipboardViewer();
    }

    // set the event to be waited for
    ResetEvent(hEvt);

	timeout = INFINITE;

	if(items == 1 && !SvROK(ST(0))) { timeout = (DWORD)SvIV(ST(0)); }
	if(items == 2) { timeout = (DWORD)SvIV(ST(1)); }

    cause = WaitForSingleObject(hEvt, timeout);
    EXTEND(SP,1);
    if(cause == WAIT_OBJECT_0)
        XST_mIV(0, 1);
    else if ( cause == WAIT_TIMEOUT )
        XST_mIV(0, 0);
	else
        XST_mNO(0);
    XSRETURN(1);

void
GetText(...)
PPCODE:
    HANDLE myhandle;
    if(OpenClipboard(NULL)) {
		EXTEND(SP,1);
		if(myhandle = GetClipboardData(CF_TEXT))
			XST_mPV(0, (char *) myhandle);
		else
			XST_mNO(0);
		CloseClipboard();
		XSRETURN(1);
	} else {
		XSRETURN_NO;
	}

void
GetFiles(...)
PPCODE:
    HANDLE myhandle;
	LPTSTR filename;
	UINT namelength;
	UINT i, toreturn;
	UINT count;
    if ( OpenClipboard(NULL) ) {
		if ( myhandle = GetClipboardData(CF_HDROP) ) {
			count = DragQueryFile((HDROP) myhandle, 0xFFFFFFFF, NULL, 0);
			EXTEND(SP, count);
			for ( i = 0 ; i < count ; i++ ) {
				namelength = DragQueryFile((HDROP) myhandle, i, NULL, 0);
				filename = (LPTSTR) safemalloc(namelength+1);
				DragQueryFile((HDROP) myhandle, i, filename, namelength+1);
				XST_mPV(i, (char *)filename);
				safefree(filename);
			}
			toreturn = count;
		}
                else {
			EXTEND(SP, 1);
			XST_mNO(0);
			toreturn = 1;
		}
		CloseClipboard();
		XSRETURN(toreturn);
	}
    else {
		XSRETURN_NO;
	}

void
GetBitmap(...)
PPCODE:
    HANDLE myhandle;
    BITMAPFILEHEADER hdr;
    SV* buffer;
    int dib_size;
    if ( OpenClipboard(NULL) ) {
	if( myhandle = GetClipboardData(CF_DIB) ) {
	    dib_size = study_dib(myhandle, &hdr);
	    /* Copy the BITMAPFILEHEADER */
	    buffer = sv_2mortal(newSVpvn((char *) &hdr,
					 sizeof(BITMAPFILEHEADER)));
	    /* Copy the DIB data */
	    sv_catpvn(buffer, (char *) myhandle, dib_size);
	    CloseClipboard();
	    EXTEND(SP, 1);
	    XPUSHs(buffer);
	    XSRETURN(1);
	} else {
	    CloseClipboard();
	    XSRETURN_NO;
	}
    } else {
	XSRETURN_NO;
    }

void
GetAs(self=NULL, format)
    SV* self;
    int format;
PPCODE:
    HANDLE myhandle;
    LPTSTR filename;
    UINT namelength;
    UINT toret;
    UINT count;
    UINT i;
    BITMAPFILEHEADER hdr;
    int dib_size;
    SV* buffer;
    if(items == 1) format = (int)SvIV(ST(0));
    if ( OpenClipboard(NULL) ) {
	switch ( format ) {
	case CF_HDROP:
	    if(myhandle = GetClipboardData(CF_HDROP)) {
		count = DragQueryFile((HDROP) myhandle, 0xFFFFFFFF, NULL, 0);
		EXTEND(SP, count);
		for ( i = 0 ; i < count ; i++ ) {
		    namelength = DragQueryFile((HDROP) myhandle, i, NULL, 0);
		    filename = (LPTSTR) safemalloc(namelength+1);
		    DragQueryFile((HDROP) myhandle, i, filename, namelength+1);
		    XST_mPV(i, (char *)filename);
		    safefree(filename);
		}
		toret = count;
	    }
	    else {
		EXTEND(SP, 1);
		XST_mNO(0);
		toret = 1;
	    }
	    break;
	case CF_DIB:
	    if ( myhandle = GetClipboardData(CF_DIB) ) {
		dib_size = study_dib(myhandle, &hdr);
		/* Copy the BITMAPFILEHEADER */
		buffer = sv_2mortal(newSVpvn((char *) &hdr,
					     sizeof(BITMAPFILEHEADER)));
		/* Copy the DIB data */
		sv_catpvn(buffer, (char *) myhandle, dib_size);
		CloseClipboard();
		EXTEND(SP, 1);
		XPUSHs(buffer);
		XSRETURN(1);
	    } else {
		CloseClipboard();
	    }
	    break;
        case CF_UNICODETEXT:
            EXTEND(SP, 1);
            if (myhandle = GetClipboardData(CF_UNICODETEXT))
                XST_mPVN(0, (char*)myhandle, wcslen((wchar_t*)myhandle) * sizeof(wchar_t));
            else
                XST_mNO(0);
            toret = 1;
            break;
	default:
	    EXTEND(SP, 1);
	    if(myhandle = GetClipboardData((UINT) format))
		XST_mPV(0,(char *) myhandle);
	    else
		XST_mNO(0);
	    toret = 1;
	    break;
	}
        CloseClipboard();
        XSRETURN(toret);
    }
    XSRETURN_NO;

void
Set(text, ...)
    SV *text
PPCODE:
    HANDLE myhandle;
    HGLOBAL hGlobal;
    LPTSTR szString;
    char *str;
    STRLEN leng;
    if (items > 1)
        text = ST(1);

    str = SvPV(text, leng);
    if ( hGlobal = GlobalAlloc(GMEM_DDESHARE, (leng+1)*sizeof(char)) ) {
        szString = (char *) GlobalLock(hGlobal);
        memcpy(szString, str, leng*sizeof(char));
        szString[leng] = (char) 0;
        GlobalUnlock(hGlobal);

        if ( OpenClipboard(NULL) ) {
            EmptyClipboard();
            myhandle = SetClipboardData(CF_TEXT, (HANDLE) hGlobal);
            CloseClipboard();

            if ( myhandle ) {
                XSRETURN_YES;
            } else {
#ifdef WIN32__CLIPBOARD__DEBUG
                printf("XS(Set): SetClipboardData failed (%d)\n",
                       GetLastError());
#endif
                XSRETURN_NO;
            }
        }
        else {
#ifdef WIN32__CLIPBOARD__DEBUG
            printf("XS(Set): OpenClipboard failed (%d)\n", GetLastError());
#endif
            GlobalFree(hGlobal);
            XSRETURN_NO;
        }
    }
    else {
#ifdef WIN32__CLIPBOARD__DEBUG
        printf("XS(Set): GlobalAlloc failed (%d)\n", GetLastError());
#endif
        XSRETURN_NO;
    }

void
Empty(...)
PPCODE:
    if(OpenClipboard(NULL)) {
        if(EmptyClipboard()) {
            CloseClipboard();
            XSRETURN_YES;
        } else {
            CloseClipboard();
            XSRETURN_NO;
        }
    }


void
EnumFormats(...)
PPCODE:
	UINT format;
	int count;
    if ( OpenClipboard(NULL) ) {
		format = EnumClipboardFormats(0);
		count = 0;
		while ( format != 0 ) {
			XST_mIV(count++, (long) format);
			format = EnumClipboardFormats(format);
		}
		CloseClipboard();
    }
    else {
        XSRETURN_NO;
    }
	XSRETURN(count);

void
IsFormatAvailable(svformat, ...)
    SV *svformat
PPCODE:
    if (items > 1)
        svformat = ST(1);
	XST_mIV(0, (long) IsClipboardFormatAvailable((UINT) SvIV(svformat)));
    XSRETURN(1);

long
IsText(...)
CODE:
	RETVAL = (long) IsClipboardFormatAvailable(CF_TEXT);
OUTPUT:
	RETVAL

long
IsBitmap(...)
CODE:
	RETVAL = (long) IsClipboardFormatAvailable(CF_DIB);
OUTPUT:
	RETVAL

long
IsFiles(...)
CODE:
	RETVAL = (long) IsClipboardFormatAvailable(CF_HDROP);
OUTPUT:
	RETVAL

void
GetFormatName(svformat, ...)
    SV *svformat
PPCODE:
	char * name[1024];
    if (items > 1)
        svformat = ST(1);
	if ( GetClipboardFormatName((UINT) SvIV(svformat), (LPTSTR) name, 1024) ) {
		EXTEND(SP, 1);
		XST_mPV(0, (char *) name);
		XSRETURN(1);
	}
    else {
		XSRETURN_NO;
	}
