/*
 *  $Id: GuiTest.xs,v 1.6 2010/11/24 19:55:08 int32 Exp $
 *
 *  The SendKeys function is based on the Delphi sourcecode
 *  published by Al Williams <http://www.al-williams.com/awc/>
 *  in Dr.Dobbs <http://www.drdobbs.com/keys-to-the-kingdom/184410429>
 *
 *  Copyright (c) 1998-2002 by Ernesto Guisado <erngui@acm.org>
 *  Copyright (c) 2004 by Dennis K. Paulsen <ctrondlp@cpan.org>
 *
 *  You may distribute under the terms of either the GNU General Public
 *  License or the Artistic License.
 *
 */

#define WIN32_LEAN_AND_MEAN
#define _WIN32_IE 0x0500
#include <windows.h>
#include <commctrl.h>
#include "dibsect.h"
#include "RSNDMSG.h"


#ifdef __cplusplus
//extern "C" {
#endif
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"
#ifdef __cplusplus
//}
#endif

#define MAX_DATA_BUF 1024
#define NUL '\0'

#ifdef _MSC_VER
#define strncasecmp _strnicmp
#endif

HINSTANCE g_hDLL = NULL;

#if defined (__GNUC__)
	#define SHARED_ATTR __attribute__((section ("shared_seg"), shared))
#else
	#define SHARED_ATTR
#endif

#pragma data_seg(".shared")
// Used by hooking/injected routines
HWND g_hWnd SHARED_ATTR = 0;
HHOOK g_hHook SHARED_ATTR = NULL;
HWND g_popup SHARED_ATTR = 0;   //Hold's popup menu's handle
BOOL g_bRetVal SHARED_ATTR = 0;
char g_szBuffer[MAX_DATA_BUF+1] SHARED_ATTR = {NUL};
UINT WM_LV_GETTEXT SHARED_ATTR = 0;
UINT WM_LV_SELBYINDEX SHARED_ATTR = 0;
UINT WM_LV_SELBYTEXT SHARED_ATTR = 0;
UINT WM_LV_ISSEL SHARED_ATTR = 0;
UINT WM_TC_GETTEXT SHARED_ATTR = 0;
UINT WM_TC_SELBYINDEX SHARED_ATTR = 0;
UINT WM_TC_SELBYTEXT SHARED_ATTR = 0;
UINT WM_TC_ISSEL SHARED_ATTR = 0;
UINT WM_TV_SELBYPATH SHARED_ATTR = 0;
UINT WM_TV_GETSELPATH SHARED_ATTR = 0;
UINT WM_INITMENUPOPUPX SHARED_ATTR = WM_INITMENUPOPUP;  //Only needed to conform with SetHook()'s calling convention
BOOL unicode_semantics SHARED_ATTR = 0;
#pragma data_seg()
#pragma comment(linker, "/SECTION:.shared,RWS")

extern "C" BOOL WINAPI DllMain(HANDLE hModule, DWORD  ul_reason_for_call,
                      LPVOID lpReserved)
{
	switch (ul_reason_for_call)
	{
	case DLL_PROCESS_ATTACH:
		// Value used by SetWindowsHookEx, etc.
		g_hDLL = (HINSTANCE)hModule;
		break;
	case DLL_THREAD_ATTACH:
	case DLL_THREAD_DETACH:
	case DLL_PROCESS_DETACH:
		break;
	}

	return TRUE;
}

// Gets a treeview item handle by name
HTREEITEM GetTVItemByName(HWND hWnd, HTREEITEM hItem,
                         char *lpItemName)
{
    // If hItem is NULL, start search from root item.
    if (hItem == NULL)
        hItem = (HTREEITEM)SendMessage(hWnd, TVM_GETNEXTITEM, TVGN_ROOT, 0);

    while (hItem != NULL)
    {
        char szBuffer[MAX_DATA_BUF+1];
        TV_ITEM item;

        item.hItem = hItem;
        item.mask = TVIF_TEXT | TVIF_CHILDREN;
        item.pszText = szBuffer;
        item.cchTextMax = MAX_DATA_BUF;
        SendMessage(hWnd, TVM_GETITEM, 0, (LPARAM)&item);

        // Did we find it?
        if (lstrcmpi(szBuffer, lpItemName) == 0)
            return hItem;

        // Check whether we have child items.
        if (item.cChildren)
        {
            // Recursively traverse child items.
            HTREEITEM hItemFound, hItemChild;

            hItemChild = (HTREEITEM)SendMessage(hWnd, TVM_GETNEXTITEM,
                                                TVGN_CHILD, (LPARAM)hItem);
            hItemFound = GetTVItemByName(hWnd, hItemChild, lpItemName);

            // Did we find it?
            if (hItemFound != NULL)
                return hItemFound;
        }

        // Go to next sibling item.
        hItem = (HTREEITEM)SendMessage(hWnd, TVM_GETNEXTITEM,
                                       TVGN_NEXT, (LPARAM)hItem);
    }

    // Not found.
    return NULL;
}

int TabCtrl_GetItemText(HWND hwnd, int iItem, char *lpString, size_t sizeStr)
{
	TCITEM tcItem;
	tcItem.pszText = lpString;
	tcItem.cchTextMax = sizeStr;
	tcItem.mask = TCIF_TEXT;

	assert(lpString != NULL);
	*lpString = NUL;
	TabCtrl_GetItem(g_hWnd, iItem, &tcItem);

	return (int)strlen(lpString);
}

// Hook procedure, does most of the work for various 32bit custom control
// routines
#define pCW ((CWPSTRUCT*)lParam)
LRESULT HookProc (int code, WPARAM wParam, LPARAM lParam)
{
	//// List Views ////
	if (pCW->message == WM_LV_GETTEXT) {
		*g_szBuffer = NUL;
		int iItem = pCW->wParam;
		int iSubItem = pCW->lParam;
		ListView_GetItemText(g_hWnd, iItem, iSubItem, g_szBuffer, MAX_DATA_BUF);
		UnhookWindowsHookEx(g_hHook);
	} else if (pCW->message == WM_LV_SELBYINDEX) {
		int iCount = ListView_GetItemCount(g_hWnd);
		int iSel = pCW->wParam;
		BOOL bMulti = pCW->lParam;
		// Clear out any previous selections if needed
		if (!bMulti && ListView_GetSelectedCount(g_hWnd) > 0) {
			for (int i = 0; i < iCount; i++) {
				ListView_SetItemState(g_hWnd, i, 0, LVIS_SELECTED);
			}
		}
		// Select item
		ListView_SetItemState(g_hWnd, iSel, LVIS_SELECTED | LVIS_FOCUSED, LVIS_SELECTED | LVIS_FOCUSED);
		g_bRetVal = ListView_EnsureVisible(g_hWnd, iSel, FALSE);
		UnhookWindowsHookEx(g_hHook);
	} else if (pCW->message == WM_LV_SELBYTEXT) {
		char szItem[MAX_DATA_BUF+1] = "";
		int iCount = ListView_GetItemCount(g_hWnd);
		BOOL bMulti = pCW->lParam;
		// Clear out any previous selections if needed
		if (!bMulti && ListView_GetSelectedCount(g_hWnd) > 0) {
			for (int i = 0; i < iCount; i++) {
				ListView_SetItemState(g_hWnd, i, 0, LVIS_SELECTED);
			}
		}
		// Look for item
		for (int i = 0; i < iCount; i++) {
			ListView_GetItemText(g_hWnd, i, 0, szItem, MAX_DATA_BUF);
			if (lstrcmpi(g_szBuffer, szItem) == 0) {
				// Found it, select it
				ListView_SetItemState(g_hWnd, i, LVIS_SELECTED | LVIS_FOCUSED, LVIS_SELECTED | LVIS_FOCUSED);
				g_bRetVal = ListView_EnsureVisible(g_hWnd, i, FALSE);
				break;
			}
		}
		UnhookWindowsHookEx(g_hHook);
	} else if (pCW->message == WM_LV_ISSEL) {
		char szItem[MAX_DATA_BUF+1] = "";
		int iCount = ListView_GetItemCount(g_hWnd);
		g_bRetVal = FALSE; // Assume false
		// Are there any selected?
		if (ListView_GetSelectedCount(g_hWnd) > 0) {
			// Look for item
			for (int i = 0; i < iCount; i++) {
				ListView_GetItemText(g_hWnd, i, 0, szItem, MAX_DATA_BUF);
				if (lstrcmpi(g_szBuffer, szItem) == 0) {
					// Found it, determine if currently selected
					if (ListView_GetItemState(g_hWnd, i, LVIS_SELECTED) & LVIS_SELECTED) {
						g_bRetVal = TRUE;
					}
				}
			}
		}
		UnhookWindowsHookEx(g_hHook);
	} else if (pCW->message == WM_TV_SELBYPATH) {
	//// Tree Views ////
		char szName[MAX_DATA_BUF+1] = "";
		size_t pos = 0, len = 0;
		HTREEITEM hItem = NULL;

		g_bRetVal = FALSE; // Assume failure

		len = strlen(g_szBuffer);
		// Move through supplied tree view path, updating hItem appropriately
		for (size_t x = 0; x < len; x++) {
			if (g_szBuffer[x] == '|') {
				if (*szName) {
					hItem = GetTVItemByName(g_hWnd, hItem, szName);
					memset(&szName, 0, MAX_DATA_BUF);
					pos = 0;
				}
			} else {
				szName[pos++] = g_szBuffer[x];
			}
		}

		if (*szName) {
			// Just a root item, no path delimiters (|)
			// OR a trailing child item?
			hItem = GetTVItemByName(g_hWnd, hItem, szName);
		}

		// Select Item if handle obtained
		g_bRetVal = hItem ? (BOOL)TreeView_SelectItem(g_hWnd, hItem) : FALSE;
		TreeView_EnsureVisible(g_hWnd, hItem);

		UnhookWindowsHookEx(g_hHook);
	} else if (pCW->message == WM_TV_GETSELPATH) {
		char szText[MAX_DATA_BUF+1] = "";
		char szTmp[MAX_DATA_BUF+1] = "";
		TVITEM tvItem = {NUL};
		HTREEITEM hItem = TreeView_GetSelection(g_hWnd);
		*g_szBuffer = NUL;

		tvItem.mask = TVIF_TEXT;
		tvItem.pszText = szText;
		tvItem.cchTextMax = MAX_DATA_BUF;
		do {
			tvItem.hItem = hItem;
			TreeView_GetItem(g_hWnd, &tvItem);

			// Add in child path text if any
			if (*szTmp)
				lstrcat(szText, szTmp);

			hItem = TreeView_GetParent(g_hWnd, hItem);
			if (hItem) {
				// Has parent, so store delimiter and path text thus far
				sprintf(szTmp, "|%s", szText);
			} else {
				// No parent, so store complete path thus far
				lstrcpy(szTmp, szText);
			}
		} while (hItem);
		lstrcpy(g_szBuffer, szTmp);
		UnhookWindowsHookEx(g_hHook);
	} else if (pCW->message == WM_TC_GETTEXT) {
	//// Tab Control ////
		int iItem = pCW->wParam;
		g_bRetVal = (BOOL)TabCtrl_GetItemText(g_hWnd, iItem, g_szBuffer, MAX_DATA_BUF);
		UnhookWindowsHookEx(g_hHook);
	} else if (pCW->message == WM_TC_SELBYINDEX) {
		int iItem = pCW->wParam;
		g_bRetVal = FALSE; // Assume failure
		if (iItem < TabCtrl_GetItemCount(g_hWnd)) {
			TabCtrl_SetCurFocus(g_hWnd, iItem);
			g_bRetVal = TRUE;
		}
		UnhookWindowsHookEx(g_hHook);
	} else if (pCW->message == WM_TC_SELBYTEXT) {
		char szName[MAX_DATA_BUF+1] = "";
		int iCount = TabCtrl_GetItemCount(g_hWnd);
		for (int i = 0; i < iCount; i++) {
			TabCtrl_GetItemText(g_hWnd, i, szName, MAX_DATA_BUF);
			// Is Tab item we want?
			if (lstrcmpi(g_szBuffer, szName) == 0) {
				// ... then set focus to it
				TabCtrl_SetCurFocus(g_hWnd, i);
				break;
			}
		}
		UnhookWindowsHookEx(g_hHook);
	} else if (pCW->message == WM_TC_ISSEL) {
		char szName[MAX_DATA_BUF+1] = "";
		int iItem = TabCtrl_GetCurFocus(g_hWnd);
		g_bRetVal = FALSE; // Assume false
		TabCtrl_GetItemText(g_hWnd, iItem, szName, MAX_DATA_BUF);
		if (lstrcmpi(g_szBuffer, szName) == 0) {
			// Yes, selected
			g_bRetVal = TRUE;
		}
		UnhookWindowsHookEx(g_hHook);
    } else if (pCW->message == WM_INITMENUPOPUP) {
		g_popup = (HWND) pCW->wParam;
		UnhookWindowsHookEx(g_hHook);
    }

	return CallNextHookEx(g_hHook, code, wParam, lParam);
}

// Sets up the hook, global control/hook handles, and registers appropriate
// window message.
HHOOK SetHook(HWND hWnd, UINT &uMsg, const char *lpMsgId)
{
	g_hWnd = hWnd;
	if (! g_hDLL) {
		g_hDLL=GetModuleHandle("GuiTest.dll");
		fprintf(stderr,"had to get module handle: %x\n",g_hDLL);
	}

	// Give up rest of time slice, so g_hHook assignment and
	// SetWindowsHook will process.
	Sleep(0);

	// Hook the thread, that "owns" our control
	g_hHook = SetWindowsHookEx(WH_CALLWNDPROC, (HOOKPROC)HookProc,
				g_hDLL, GetWindowThreadProcessId(hWnd, NULL));

	if (uMsg == 0)
		uMsg = RegisterWindowMessage(lpMsgId);

	return g_hHook;
}

// The following several routines all inject "ourself" into a remote process
// and performs some work.

int GetLVItemText(HWND hWnd, int iItem, int iColumn, char *lpString)
{
	char szItem[MAX_DATA_BUF+1] = "";
	R_ListView_GetItemText(hWnd, iItem, iColumn, szItem, MAX_DATA_BUF);
	lstrcpyn( lpString, szItem , sizeof(szItem));
	return strlen(lpString);
}

BOOL SelLVItem(HWND hWnd, int iItem, BOOL bMulti)
{
	int iCount = ListView_GetItemCount(g_hWnd);
	// Clear out any previous selections if needed
	if (!bMulti && ListView_GetSelectedCount(hWnd) > 0) {
		for (int i = 0; i < iCount; i++) {
			R_ListView_SetItemState(hWnd, i, 0, LVIS_SELECTED);
		}
	}
	// Select item
	R_ListView_SetItemState(hWnd, iItem, LVIS_SELECTED | LVIS_FOCUSED, LVIS_SELECTED | LVIS_FOCUSED);
	g_bRetVal = ListView_EnsureVisible(g_hWnd, iItem, FALSE);

	return g_bRetVal;
}

BOOL SelLVItemText(HWND hWnd, char *lpItem, BOOL bMulti)
{
	BOOL RetVal=FALSE;
	char szItem[MAX_DATA_BUF+1] = "";
	int iCount = ListView_GetItemCount(hWnd);
	// Clear out any previous selections if needed
	if (!bMulti && ListView_GetSelectedCount(hWnd) > 0) {
		for (int i = 0; i < iCount; i++) {
			R_ListView_SetItemState(hWnd, i, 0, LVIS_SELECTED);
		}
	}
	// Look for item
	for (int i = 0; i < iCount; i++) {
		R_ListView_GetItemText(hWnd, i, 0, szItem, MAX_DATA_BUF);
		if (lstrcmpi(lpItem, szItem) == 0) {
			// Found it, select it
			R_ListView_SetItemState(hWnd, i, LVIS_SELECTED | LVIS_FOCUSED, LVIS_SELECTED | LVIS_FOCUSED);
			RetVal = ListView_EnsureVisible(hWnd, i, FALSE);
			break;
		}
	}
	lstrcpy(g_szBuffer, lpItem);

	return RetVal;
}

BOOL IsLVItemSel(HWND hWnd, char *lpItem)
{
	BOOL RetVal = FALSE; // Assume false
	char szItem[MAX_DATA_BUF+1] = "";
	int iCount = ListView_GetItemCount(hWnd);
	// Are there any selected?
	if (ListView_GetSelectedCount(hWnd) > 0) {
		// Look for item
		for (int i = 0; i < iCount; i++) {
			R_ListView_GetItemText(hWnd, i, 0, szItem, MAX_DATA_BUF);
			if (lstrcmpi(lpItem, szItem) == 0) {
				// Found it, determine if currently selected
				if (ListView_GetItemState(hWnd, i, LVIS_SELECTED) & LVIS_SELECTED) {
					RetVal = TRUE;
				}
			}
		}
	}

	return RetVal;
}

BOOL SelTVItemPath(HWND hWnd, char *lpPath)
{
	if (SetHook(hWnd, WM_TV_SELBYPATH, "WM_TV_SELBYPATH_RM") == NULL)
		return FALSE;

	lstrcpy(g_szBuffer, lpPath);
	SendMessage(hWnd, WM_TV_SELBYPATH, 0, 0);
	return g_bRetVal;
}

int GetTVSelPath(HWND hWnd, char *lpPath)
{
	if (SetHook(hWnd, WM_TV_GETSELPATH, "WM_TV_GETSELPATH_RM") == NULL)
		return FALSE;

	SendMessage(hWnd, WM_TV_GETSELPATH, 0, 0);
	lstrcpy(lpPath, g_szBuffer);

	return (int)strlen(lpPath);
}

int GetTCItemText(HWND hWnd, int iItem, char *lpString)
{
	if (SetHook(hWnd, WM_TC_GETTEXT, "WM_TC_GETTEXT_RM") == NULL) {
		*lpString = NUL;
		return 0;
	}

	SendMessage(hWnd, WM_TC_GETTEXT, iItem, 0);
	lstrcpy(lpString, g_szBuffer);

	return (int)strlen(lpString);
}

BOOL SelTCItem(HWND hWnd, int iItem)
{
	if (SetHook(hWnd, WM_TC_SELBYINDEX, "WM_TC_SELBYINDEX_RM") == NULL)
		return FALSE;

	SendMessage(hWnd, WM_TC_SELBYINDEX, iItem, 0);
	return g_bRetVal;
}

BOOL SelTCItemText(HWND hWnd, char *szText)
{
	if (SetHook(hWnd, WM_TC_SELBYTEXT, "WM_TC_SELBYTEXT_RM") == NULL)
		return FALSE;

	lstrcpy(g_szBuffer, szText);
	SendMessage(hWnd, WM_TC_SELBYTEXT, 0, 0);
	return g_bRetVal;
}


BOOL IsTCItemSel(HWND hWnd, char *lpItem)
{
	if (SetHook(hWnd, WM_TC_ISSEL, "WM_TC_ISSEL_RM") == NULL)
		return FALSE;

	lstrcpy(g_szBuffer, lpItem);
	SendMessage(hWnd, WM_TC_ISSEL, 0, 0);

	return g_bRetVal;
}

int GetTCItemCount(HWND hWnd)
{
	return TabCtrl_GetItemCount(hWnd);
}


/*
 * Piotr Kaluski <pkaluski@piotrkaluski.com>
 *
 * WaitForWindowInputIdle is a wrapper for WaitForInputIdle Win32 function.
 * The function waits until the application is ready to accept input
 * (keyboard keys, mouse clicks). It is useful, for actions, which take a long
 * time to complete. Instead of putting sleeps of arbitrary length, we can just
 * wait until the application is ready to respond. Original function takes
 * a process handle as an input. However, in GUI tests we more often operate
 * on windows then on applications.
 * NOTE: Unfortunatelly, this function not always works, so before using
 * it, check that is works in your environment
 *
 */
DWORD WaitForWindowInputIdle( HWND hwnd, DWORD milliseconds )
{
    DWORD pid = 0;
    DWORD dwThreadId = GetWindowThreadProcessId( hwnd, &pid );
    HANDLE hProcess = OpenProcess( PROCESS_ALL_ACCESS, TRUE, pid );
    if( hProcess == NULL ){
        LPVOID lpMsgBuf;
        DWORD dw = GetLastError();
        FormatMessage(
            FORMAT_MESSAGE_ALLOCATE_BUFFER |
            FORMAT_MESSAGE_FROM_SYSTEM,
            NULL,
            dw,
            MAKELANGID(LANG_NEUTRAL, SUBLANG_DEFAULT),
            (LPTSTR) &lpMsgBuf,
            0, NULL );
        warn( "OpenProcess failed with error %d: %s",
                dw, lpMsgBuf );
    }
    //printf( "Calling WaitForInputIdle for pid %ld\n", pid );
    DWORD result = WaitForInputIdle( hProcess, milliseconds );
    if( result == WAIT_FAILED ){
        LPVOID lpMsgBuf;
        DWORD dw = GetLastError();
        FormatMessage(
            FORMAT_MESSAGE_ALLOCATE_BUFFER |
            FORMAT_MESSAGE_FROM_SYSTEM,
            NULL,
            dw,
            MAKELANGID(LANG_NEUTRAL, SUBLANG_DEFAULT),
            (LPTSTR) &lpMsgBuf,
            0, NULL );
        warn( "WaitForInputIdle failed with error %d: %s",
                dw, lpMsgBuf );
    }else{
        if( result == WAIT_TIMEOUT ){
    //        printf( "WaitForInputIdle returned after TIME OUT" );
        }
        if( result == 0 ){
    //        printf( "WaitForInputIdle returned after wait was satisfied" );
        }
    }

    return result;
}


/* Wrapper around kebyd_event */
void KeyUp(UINT vk)
{
    BYTE scan = MapVirtualKey(vk, 0);
    keybd_event(vk, scan, KEYEVENTF_KEYUP, 0);
}

void KeyDown(UINT vk)
{
    BYTE scan=MapVirtualKey(vk, 0);
    keybd_event(vk, scan, 0, 0);
}


typedef struct windowtable {
    int size;
    HWND* windows/*[1024]*/;
} windowtable;


BOOL CALLBACK AddWindowChild(
    HWND hwnd,    // handle to child window
    LPARAM lParam // application-defined value
    )
{
    HWND* grow;
    windowtable* children = (windowtable*)lParam;
    /* Need to grow the table to make space for the next entry */
    if (children->windows)
        grow = (HWND*)saferealloc(children->windows, (children->size+1)*sizeof(HWND));
    else
        grow = (HWND*)safemalloc((children->size+1)*sizeof(HWND));
    if (grow == 0)
        return FALSE;
    children->windows = grow;
    children->size++;
    children->windows[children->size-1] = hwnd;
    return TRUE;
}

/*

Phill Wolf <pbwolf@bellatlantic.net>

Although mouse_event is documented to take a unit of "pixels" when moving
to an absolute location, and "mickeys" when moving relatively, on my
system I can see that it takes "mickeys" in both cases.  Giving
mouse_event an absolute (x,y) position in pixels results in the cursor
going much closer to the top-left of the screen than is intended.

Here is the function I have used in my own Perl modules to convert from screen coordinates to mickeys.

*/

#define SCREEN_TO_MICKEY(COORD,val) MulDiv((val)+1, 0x10000, GetSystemMetrics(SM_C ## COORD ## SCREEN))-1

void ScreenToMouseplane(POINT *p)
{
    p->x = SCREEN_TO_MICKEY(X,p->x);
    p->y = SCREEN_TO_MICKEY(Y,p->y);
}


/*  Same as mouse_event but without wheel and with time-out.
 */
VOID simple_mouse(
  DWORD dwFlags, // flags specifying various motion/click variants
  DWORD dx,      // horizontal mouse position or position change
  DWORD dy      // vertical mouse position or position change
 )
{
    char dstr[256];
    sprintf(dstr, "simple_mouse(%d, %d, %d)\n", dwFlags, dx, dy);
    OutputDebugString(dstr);
    mouse_event(dwFlags, dx, dy, 0, 0);
    Sleep (10);
}

/* JJ Utilities for thread-specific window functions */

BOOL AttachWin(HWND hwnd, BOOL fAttach)
{
  DWORD dwThreadId = GetWindowThreadProcessId(hwnd, NULL);
  DWORD dwMyThread = GetCurrentThreadId();
  return AttachThreadInput(dwMyThread, dwThreadId, fAttach);
}


SV*
GetTextHelper(HWND hwnd, int index, UINT lenmsg, UINT textmsg)
{
    SV* sv = 0;
    int len = SendMessage(hwnd, lenmsg, index, 0L);
    char* text = (char*)safemalloc(len+1);
    if (text != 0) {
        SendMessage(hwnd, textmsg, index, (LPARAM)text);
        sv = newSVpv(text, len);
        safefree(text);
    }
    return sv;
}

/*
 * Piotr Kaluski <pkaluski@piotrkaluski.com>
 *
 * OpenProcessForWindow opens a process, which is an owner of a window
 * identified by hWnd.
 *
 */
HANDLE OpenProcessForWindow( HWND hWnd )
{
    DWORD pid = 0;
    DWORD dwThreadId = GetWindowThreadProcessId( hWnd, &pid );
    HANDLE hProcess = OpenProcess( PROCESS_ALL_ACCESS, TRUE, pid );
    if( hProcess == NULL ){
        LPVOID lpMsgBuf;
        DWORD dw = GetLastError();
        FormatMessage(
            FORMAT_MESSAGE_ALLOCATE_BUFFER |
            FORMAT_MESSAGE_FROM_SYSTEM,
            NULL,
            dw,
            MAKELANGID(LANG_NEUTRAL, SUBLANG_DEFAULT),
            (LPTSTR) &lpMsgBuf,
            0, NULL );
        warn( "OpenProcess failed with error %d: %s",
                dw, lpMsgBuf );
    }
    return hProcess;
}

////////////////////////////////////////////////////////////////////////////
HWND PopupHandleGet(HWND hWnd, int x, int y, int wait) {
    g_popup = 0;
    if (SetHook(hWnd, WM_INITMENUPOPUPX, "WM_INITMENUPOPUP_RM") == NULL)
        return 0;
    int mickey_x = SCREEN_TO_MICKEY(X,x);
    int mickey_y = SCREEN_TO_MICKEY(Y,y);
    simple_mouse(MOUSEEVENTF_MOVE|MOUSEEVENTF_ABSOLUTE, mickey_x, mickey_y);
    simple_mouse(MOUSEEVENTF_RIGHTDOWN, 0, 0);
    simple_mouse(MOUSEEVENTF_RIGHTUP,   0, 0);
    Sleep(wait);
    if (g_popup == 0)
        UnhookWindowsHookEx(g_hHook);
    return g_popup;
}


MODULE = Win32::GuiTest		PACKAGE = Win32::GuiTest

PROTOTYPES: DISABLE

######################################################################
# Allocates memory in address space of a process, which owns window
# hWnd.
#
######################################################################

void
AllocateVirtualBufferImp( hWnd, memSize )
    HWND hWnd
    SIZE_T memSize
PPCODE:
    HANDLE hProcess = OpenProcessForWindow( hWnd );
	LPVOID pBuffer = VirtualAllocEx( hProcess, NULL, memSize,
		           MEM_RESERVE | MEM_COMMIT, PAGE_READWRITE);
    if( pBuffer == NULL ){
        LPVOID lpMsgBuf;
        DWORD dw = GetLastError();
        FormatMessage(
            FORMAT_MESSAGE_ALLOCATE_BUFFER |
            FORMAT_MESSAGE_FROM_SYSTEM,
            NULL,
            dw,
            MAKELANGID(LANG_NEUTRAL, SUBLANG_DEFAULT),
            (LPTSTR) &lpMsgBuf,
            0, NULL );
        die( "VirtualAllocEx failed with error %d: %s",
                dw, lpMsgBuf );
    }else{
        XPUSHs( sv_2mortal( newSVuv( ( UV )pBuffer ) ) );
        XPUSHs( sv_2mortal( newSVuv( ( UV )hProcess ) ) );
    }


######################################################################
# Frees memory allocated by AllocateVirtualBuffer.
#
######################################################################

void
FreeVirtualBufferImp( hProcess, pBuffer )
    HANDLE hProcess
    LPVOID pBuffer
    PPCODE:
	    BOOL result = VirtualFreeEx( hProcess,
                                     pBuffer,
                                       0,
                                       0x8000 );
        if( !result ){
            LPVOID lpMsgBuf;
            DWORD dw = GetLastError();
            FormatMessage(
                FORMAT_MESSAGE_ALLOCATE_BUFFER |
                FORMAT_MESSAGE_FROM_SYSTEM,
                NULL,
                dw,
                MAKELANGID(LANG_NEUTRAL, SUBLANG_DEFAULT),
                (LPTSTR) &lpMsgBuf,
                0, NULL );
            die( "VirtualFreeEx failed with error %d: %s",
                    dw, lpMsgBuf );
        }


######################################################################
# Read from memory allocated by AllocateVirtualBuffer.
#
######################################################################

void
ReadFromVirtualBufferImp( hProcess, pVirtBuffer, memSize )
    HANDLE hProcess
    LPVOID pVirtBuffer
    SIZE_T memSize
PPCODE:
    SIZE_T copied = 0;
    char *pLocBuff = ( char *)safemalloc( memSize + 1 );
    if( !ReadProcessMemory( hProcess,
                            pVirtBuffer,
                            pLocBuff,
                            memSize,
                            &copied ) )
    {
        LPVOID lpMsgBuf;
        DWORD dw = GetLastError();
        FormatMessage(
            FORMAT_MESSAGE_ALLOCATE_BUFFER |
            FORMAT_MESSAGE_FROM_SYSTEM,
            NULL,
            dw,
            MAKELANGID(LANG_NEUTRAL, SUBLANG_DEFAULT),
            (LPTSTR) &lpMsgBuf,
            0, NULL );
        die( "ReadProcessMemory failed with error %d: %s",
                dw, lpMsgBuf );
    }else{
        XPUSHs( sv_2mortal( newSVpv( pLocBuff, memSize ) ) );
        safefree( pLocBuff );
    }


######################################################################
# Write to memory allocated by AllocateVirtualBuffer.
#
######################################################################

void
WriteToVirtualBufferImp( hProcess, pVirtBuffer, value )
    HANDLE hProcess
    LPVOID pVirtBuffer
    SV* value
PPCODE:
    SIZE_T copied = 0;
    STRLEN memSize = 0;
    char* pLocBuffer = SvPV( value, memSize );
    if( !WriteProcessMemory( hProcess,
                             pVirtBuffer,
                             pLocBuffer,
                             memSize,
                             &copied ) )
    {
        LPVOID lpMsgBuf;
        DWORD dw = GetLastError();
        FormatMessage(
            FORMAT_MESSAGE_ALLOCATE_BUFFER |
            FORMAT_MESSAGE_FROM_SYSTEM,
            NULL,
            dw,
            MAKELANGID(LANG_NEUTRAL, SUBLANG_DEFAULT),
            (LPTSTR) &lpMsgBuf,
            0, NULL );
        die( "WriteProcessMemory failed with error %d: %s",
                dw, lpMsgBuf );
    }


SV*
GetListViewItem(hWnd, iItem, iSubItem )
	HWND hWnd
	int iItem
    int iSubItem
CODE:
	char szItem[MAX_DATA_BUF+1] = "";
	GetLVItemText(hWnd, iItem, iSubItem, szItem);
	RETVAL = newSVpv(szItem, 0);
OUTPUT:
	RETVAL

int
GetListViewItemCount(hWnd)
	HWND hWnd
CODE:
	RETVAL = ListView_GetItemCount(hWnd);
OUTPUT:
	RETVAL

BOOL
SelListViewItem(hWnd, iItem, bMulti=FALSE)
	HWND hWnd
	int iItem
	BOOL bMulti
CODE:
	RETVAL = SelLVItem(hWnd, iItem, bMulti);
OUTPUT:
	RETVAL

BOOL
SelListViewItemText(hWnd, lpItem, bMulti=FALSE)
	HWND hWnd
	char *lpItem
	BOOL bMulti
CODE:
	RETVAL = SelLVItemText(hWnd, lpItem, bMulti);
OUTPUT:
	RETVAL

BOOL
IsListViewItemSel(hWnd, lpItem)
	HWND hWnd
	char *lpItem
CODE:
	RETVAL = IsLVItemSel(hWnd, lpItem);
OUTPUT:
	RETVAL

HWND
GetListViewHeader(hWnd)
	HWND hWnd
CODE:
	RETVAL = ListView_GetHeader(hWnd);
OUTPUT:
	RETVAL

int
GetHeaderColumnCount(hWnd)
	HWND hWnd
CODE:
	RETVAL = Header_GetItemCount(hWnd);
OUTPUT:
	RETVAL

void
GetTabItems(hWnd)
	HWND hWnd
PPCODE:
	char szItem[MAX_DATA_BUF+1] = "";
	int iCount = GetTCItemCount(hWnd);
	for (int i = 0; i < iCount; i++) {
		GetTCItemText(hWnd, i, szItem);
	        XPUSHs(sv_2mortal(newSVpv(szItem, 0)));
	}

BOOL
SelTabItem(hWnd, iItem)
	HWND hWnd
	int iItem
CODE:
	RETVAL = SelTCItem(hWnd, iItem);
OUTPUT:
	RETVAL

BOOL
SelTabItemText(hWnd, lpItem)
	HWND hWnd
	char *lpItem
CODE:
	RETVAL = SelTCItemText(hWnd, lpItem);
OUTPUT:
	RETVAL

BOOL
IsTabItemSel(hWnd, lpItem)
	HWND hWnd
	char *lpItem
CODE:
	RETVAL = IsTCItemSel(hWnd, lpItem);
OUTPUT:
	RETVAL

SV*
GetTreeViewSelPath(hWnd)
	HWND hWnd
CODE:
	char szPath[MAX_DATA_BUF+1] = "";
	int len = GetTVSelPath(hWnd, szPath);
	RETVAL = newSVpv(szPath, len);
OUTPUT:
	RETVAL

void
GetCursorPos()
INIT:
  POINT pt;
PPCODE:
  pt.x = pt.y = -1;
  GetCursorPos(&pt);
  XPUSHs(sv_2mortal(newSVnv(pt.x)));
  XPUSHs(sv_2mortal(newSVnv(pt.y)));


void
SendLButtonUp()
    CODE:
    simple_mouse(MOUSEEVENTF_LEFTUP, 0, 0);

void
SendLButtonDown()
	CODE:
        simple_mouse(MOUSEEVENTF_LEFTDOWN, 0, 0);

void
SendMButtonUp()
	CODE:
        simple_mouse(MOUSEEVENTF_MIDDLEUP, 0, 0);

void
SendMButtonDown()
	CODE:
        simple_mouse(MOUSEEVENTF_MIDDLEDOWN, 0, 0);

void
SendRButtonUp()
	CODE:
        simple_mouse(MOUSEEVENTF_RIGHTUP, 0, 0);

void
SendRButtonDown()
	CODE:
        simple_mouse(MOUSEEVENTF_RIGHTDOWN, 0, 0);

void
SendMouseMoveRel(x,y)
    int x;
    int y;
	CODE:
        simple_mouse(MOUSEEVENTF_MOVE, x, y);

void
SendMouseMoveAbs(x,y)
	int x;
    int y;
	CODE:
        simple_mouse(MOUSEEVENTF_MOVE|MOUSEEVENTF_ABSOLUTE, x, y);

void
MouseMoveAbsPix(x,y)
    int x;
    int y;
PREINIT:
    int mickey_x = SCREEN_TO_MICKEY(X,x);
    int mickey_y = SCREEN_TO_MICKEY(Y,y);
CODE:
    simple_mouse(MOUSEEVENTF_MOVE|MOUSEEVENTF_ABSOLUTE, mickey_x, mickey_y);


#ifndef WHEEL_DELTA
#define WHEEL_DELTA 120
#endif
void
MouseMoveWheel(dwChange)
    DWORD dwChange
CODE:
    mouse_event(MOUSEEVENTF_WHEEL, 0, 0, (dwChange*WHEEL_DELTA), 0);

HWND
GetDesktopWindow()
    CODE:
        RETVAL = GetDesktopWindow();
    OUTPUT:
        RETVAL


HWND
GetWindow(hwnd, uCmd)
    HWND hwnd
    UINT uCmd
    CODE:
        RETVAL = GetWindow(hwnd, uCmd);
    OUTPUT:
	RETVAL

SV*
GetWindowText(hwnd)
    HWND hwnd
    CODE:
        char text[512];
        int r;
	if ( unicode_semantics) {
		WCHAR buf[256];
        	r = GetWindowTextW(hwnd, buf, 255);
        	r = WideCharToMultiByte(CP_UTF8, 0, buf, r, text, 511, NULL, NULL);
        	RETVAL = newSVpvn(text, r);
		SvUTF8_on( RETVAL);
	} else {
        	r = GetWindowText(hwnd, text, 255);
        	RETVAL = newSVpvn(text, r);
	}
    OUTPUT:
        RETVAL

SV*
GetClassName(hwnd)
    HWND hwnd
    CODE:
//        SV* sv;
        char text[255];
        int r;
        r = GetClassName(hwnd, text, 255);
        RETVAL = newSVpv(text, r);
    OUTPUT:
        RETVAL

HWND
GetParent(hwnd)
    HWND hwnd
    CODE:
        RETVAL = GetParent(hwnd);
    OUTPUT:
        RETVAL

long
GetWindowLong(hwnd, index)
    HWND hwnd
    int index
    CODE:
        RETVAL = GetWindowLong(hwnd, index);
    OUTPUT:
        RETVAL


BOOL
SetForegroundWindow(hWnd)
    HWND hWnd
    CODE:
        RETVAL = SetForegroundWindow(hWnd);
    OUTPUT:
        RETVAL

HWND
SetFocus(hWnd)
    HWND hWnd
    CODE:
  		AttachWin(hWnd, TRUE);
        RETVAL = SetFocus(hWnd);
		AttachWin(hWnd, FALSE);
    OUTPUT:
        RETVAL

void
GetChildWindows(hWnd)
    HWND hWnd;
    PREINIT:
        windowtable children;
        int i;
    PPCODE:
        children.size    = 0;
        children.windows = 0;
        EnumChildWindows(hWnd, (WNDENUMPROC)AddWindowChild, (LPARAM)&children);
        for (i = 0; i < children.size; i++) {
            XPUSHs(sv_2mortal(newSViv((IV)children.windows[i])));
        }
	safefree(children.windows);


SV*
WMGetText(hwnd)
    HWND hwnd
    CODE:
//        SV* sv;
        char* text;
        int len = SendMessage(hwnd, WM_GETTEXTLENGTH, 0, 0L);
        text = (char*)safemalloc(len+1);
        if (text != 0) {
            SendMessage(hwnd, WM_GETTEXT, (WPARAM)len + 1, (LPARAM)text);
            RETVAL = newSVpv(text, len);
            safefree(text);
        } else {
            RETVAL = 0;
        }
    OUTPUT:
        RETVAL

int
WMSetText(hwnd, text)
  HWND hwnd
  char * text
CODE:
  RETVAL = SendMessage(hwnd, WM_SETTEXT, 0, (LPARAM) text);
OUTPUT:
  RETVAL

BOOL
IsChild(hWndParent, hWnd)
    HWND hWndParent
    HWND hWnd
    CODE:
        RETVAL = IsChild(hWndParent, hWnd);
    OUTPUT:
        RETVAL

DWORD
GetChildDepth(hAncestor, hChild)
    HWND hAncestor
    HWND hChild
    PREINIT:
        DWORD depth = 1;
    CODE:
        while ((hChild = GetParent(hChild)) != 0) {
            depth++;
            if (hChild == hAncestor) {
                break;
            }
        }
        RETVAL = depth;
    OUTPUT:
        RETVAL

IV
SendMessage(hwnd, msg, wParam, lParam)
  HWND hwnd
  UINT msg
  WPARAM wParam
  LPARAM lParam
CODE:
  RETVAL = SendMessage(hwnd, msg, wParam, lParam);
OUTPUT:
  RETVAL

int
PostMessage(hwnd, msg, wParam, lParam)
  HWND hwnd
  UINT msg
  WPARAM wParam
  LPARAM lParam
CODE:
  RETVAL = PostMessage(hwnd, msg, wParam, lParam);
OUTPUT:
  RETVAL

void
CheckButton(hwnd)
    HWND hwnd
CODE:
    SendMessage(hwnd, BM_SETCHECK, BST_CHECKED, 0);

void
UnCheckButton(hwnd)
    HWND hwnd
CODE:
    SendMessage(hwnd, BM_SETCHECK, BST_UNCHECKED, 0);

void
GrayOutButton(hwnd)
    HWND hwnd
CODE:
    SendMessage(hwnd, BM_SETCHECK, BST_INDETERMINATE, 0);

BOOL
IsCheckedButton(hwnd)
    HWND hwnd
CODE:
    RETVAL = SendMessage(hwnd, BM_GETCHECK, 0, 0) == BST_CHECKED;
OUTPUT:
    RETVAL

BOOL
IsGrayedButton(hwnd)
    HWND hwnd
CODE:
    RETVAL = SendMessage(hwnd, BM_GETCHECK, 0, 0) == BST_INDETERMINATE;
OUTPUT:
    RETVAL

BOOL
IsWindow(hwnd)
    HWND hwnd
CODE:
    RETVAL = IsWindow(hwnd);
OUTPUT:
    RETVAL

void
ScreenToClient(hwnd, x, y)
    HWND hwnd
    int x
    int y
INIT:
    POINT pt;
PPCODE:
    pt.x = x;
    pt.y = y;
    if (ScreenToClient(hwnd, &pt)) {
        XPUSHs(sv_2mortal(newSViv((IV)pt.x)));
        XPUSHs(sv_2mortal(newSViv((IV)pt.y)));
    }

void
ClientToScreen(hwnd, x, y)
    HWND hwnd
    int x
    int y
INIT:
    POINT pt;
PPCODE:
    pt.x = x;
    pt.y = y;
    if (ClientToScreen(hwnd, &pt)) {
        XPUSHs(sv_2mortal(newSViv((IV)pt.x)));
        XPUSHs(sv_2mortal(newSViv((IV)pt.y)));
    }

void
GetCaretPos(hwnd)
  HWND hwnd
INIT:
  POINT pt;
PPCODE:
  AttachWin(hwnd, TRUE);
  pt.x = pt.y = -1;
  if (GetCaretPos(&pt))
  {
    XPUSHs(sv_2mortal(newSVnv(pt.x)));
    XPUSHs(sv_2mortal(newSVnv(pt.y)));
  }
  AttachWin(hwnd, FALSE);

HWND
GetFocus(hwnd)
  HWND hwnd;
CODE:
  AttachWin(hwnd, TRUE);
  RETVAL = GetFocus();
  AttachWin(hwnd, FALSE);
OUTPUT:
  RETVAL

HWND
GetActiveWindow(hwnd)
  HWND hwnd;
CODE:
  AttachWin(hwnd, TRUE);
  RETVAL = GetActiveWindow();
  AttachWin(hwnd, FALSE);
OUTPUT:
  RETVAL

HWND
GetForegroundWindow()
CODE:
  RETVAL = GetForegroundWindow();
OUTPUT:
  RETVAL

HWND
SetActiveWindow(hwnd)
  HWND hwnd;
CODE:
  AttachWin(hwnd, TRUE);
  RETVAL = SetActiveWindow(hwnd);
  AttachWin(hwnd, FALSE);
OUTPUT:
  RETVAL

BOOL
EnableWindow(hwnd, fEnable)
  HWND hwnd
  BOOL fEnable
CODE:
  RETVAL = EnableWindow(hwnd, fEnable);
OUTPUT:
  RETVAL

BOOL
IsWindowEnabled(hwnd)
  HWND hwnd
CODE:
  RETVAL = IsWindowEnabled(hwnd);
OUTPUT:
  RETVAL

BOOL
IsWindowVisible(hwnd)
  HWND hwnd
CODE:
  RETVAL = IsWindowVisible(hwnd);
OUTPUT:
  RETVAL

BOOL
ShowWindow(hwnd, nCmdShow)
  HWND hwnd
  int nCmdShow
CODE:
  AttachWin(hwnd, TRUE);
  RETVAL = ShowWindow(hwnd, nCmdShow);
  AttachWin(hwnd, FALSE);
OUTPUT:
  RETVAL

BOOL
UnicodeSemantics(...)
CODE:
  switch( items) {
  case 0:
    break;
  case 1:
    unicode_semantics = SvTRUE( ST( 0));
    break;
  default:
    croak("Format: UnicodeSemantics() or UnicodeSemantics(BOOL)");
  }
  RETVAL = unicode_semantics;
OUTPUT:
  RETVAL

void
ScreenToNorm(x,y)
    int x;
    int y;
    PPCODE:
        x = SCREEN_TO_MICKEY(X,x);
        y = SCREEN_TO_MICKEY(Y,y);
        XPUSHs(sv_2mortal(newSViv((IV)x)));
        XPUSHs(sv_2mortal(newSViv((IV)y)));


void
NormToScreen(x,y)
    int x;
    int y;
    PPCODE:
        x = MulDiv(x + 1, GetSystemMetrics(SM_CXSCREEN), 65536) - 1;
        y = MulDiv(y + 1, GetSystemMetrics(SM_CYSCREEN), 65536) - 1;
        XPUSHs(sv_2mortal(newSViv((IV)x)));
        XPUSHs(sv_2mortal(newSViv((IV)y)));

void
GetScreenRes()
    PREINIT:
        int hor,ver;
    PPCODE:
        hor = GetSystemMetrics(SM_CXSCREEN);
        ver = GetSystemMetrics(SM_CYSCREEN);
        XPUSHs(sv_2mortal(newSViv((IV)hor)));
        XPUSHs(sv_2mortal(newSViv((IV)ver)));

void
GetWindowRect(hWnd)
    HWND hWnd;
    PREINIT:
        RECT rect;
    PPCODE:
        GetWindowRect(hWnd,&rect);
        XPUSHs(sv_2mortal(newSViv((IV)rect.left)));
        XPUSHs(sv_2mortal(newSViv((IV)rect.top)));
        XPUSHs(sv_2mortal(newSViv((IV)rect.right)));
        XPUSHs(sv_2mortal(newSViv((IV)rect.bottom)));



SV*
GetComboText(hwnd, index)
    HWND hwnd;
    int index
    CODE:
        RETVAL = GetTextHelper(hwnd, index, CB_GETLBTEXTLEN, CB_GETLBTEXT);
    OUTPUT:
        RETVAL

SV*
GetListText(hwnd, index)
    HWND hwnd;
    int index
    CODE:
        RETVAL = GetTextHelper(hwnd, index, LB_GETTEXTLEN, LB_GETTEXT);
    OUTPUT:
        RETVAL

void
GetComboContents(hWnd)
    HWND hWnd;
PPCODE:
    int nelems = SendMessage(hWnd, CB_GETCOUNT, 0, 0);
    int i;
    for (i = 0; i < nelems; i++) {
        XPUSHs(sv_2mortal(GetTextHelper(hWnd, i, CB_GETLBTEXTLEN, CB_GETLBTEXT)));
    }

BOOL
SelComboItem(hWnd, iItem)
	HWND hWnd;
	int iItem;
CODE:
	RETVAL = (SendMessage(hWnd, CB_SETCURSEL, iItem, 0) != CB_ERR);
OUTPUT:
	RETVAL

BOOL
SelComboItemText(hWnd, lpItem)
	HWND hWnd;
	char *lpItem;
CODE:
    int nelems = SendMessage(hWnd, CB_GETCOUNT, 0, 0);
	int i;
	RETVAL = FALSE;
	for (i = 0; i < nelems; i++) {
		SV *sv = GetTextHelper(hWnd, i, CB_GETLBTEXTLEN, CB_GETLBTEXT);
		char *txt = sv_2pvbyte_nolen(sv);
		if (lstrcmpi(txt, lpItem) == 0) {
			RETVAL = (SendMessage(hWnd, CB_SETCURSEL, i, 0) != CB_ERR);
			break;
		}
	}
OUTPUT:
	RETVAL


#########################################################################
# Selects combo item, which starts with a given string
#
#########################################################################

DWORD
SelComboString( hWnd, lpItem, start_idx = 0 )
    HWND hWnd;
    char *lpItem;
    DWORD start_idx;
CODE:
    int result = 0;
    result = SendMessage(hWnd,
                         CB_SELECTSTRING,
                         start_idx,
                         LPARAM( lpItem ) );
    if( result == CB_ERR ){
        RETVAL = -1;
    }else{
        RETVAL = result;
    }
OUTPUT:
    RETVAL

void
GetListContents(hWnd)
    HWND hWnd;
PPCODE:
    int nelems = SendMessage(hWnd, LB_GETCOUNT, 0, 0);
    int i;
    for (i = 0; i < nelems; i++) {
        XPUSHs(sv_2mortal(GetTextHelper(hWnd, i, LB_GETTEXTLEN, LB_GETTEXT)));
    }


HMENU
GetSubMenu(hMenu, nPos)
    HMENU hMenu;
    int nPos;
CODE:
    RETVAL = GetSubMenu(hMenu, nPos);
OUTPUT:
    RETVAL

# experimental code by SZABGAB

void
GetMenuItemInfo(hMenu, uItem)
    HMENU hMenu;
    UINT uItem;
INIT:
    MENUITEMINFO minfo;
    char buff[256] = "";   /* Menu Data Buffer */
PPCODE:
    memset(buff, 0, sizeof(buff));
    minfo.cbSize = sizeof(MENUITEMINFO);
    minfo.fMask = MIIM_CHECKMARKS | MIIM_DATA | MIIM_TYPE | MIIM_STATE;
    minfo.dwTypeData = buff;
    minfo.cch = sizeof(buff);

    if (GetMenuItemInfo(hMenu, uItem, TRUE, &minfo)) {
        XPUSHs(sv_2mortal(newSVpv("type", 4)));
       	if (minfo.fType == MFT_STRING) {
            XPUSHs(sv_2mortal(newSVpv("string", 6)));
    	    int r;
    	    r = strlen(minfo.dwTypeData);
            XPUSHs(sv_2mortal(newSVpv("text", 4)));
            XPUSHs(sv_2mortal(newSVpv(minfo.dwTypeData, r)));
	} else if (minfo.fType == MFT_SEPARATOR) {
            XPUSHs(sv_2mortal(newSVpv("separator", 9)));
	} else {
            XPUSHs(sv_2mortal(newSVpv("unknown", 7)));
	}
        XPUSHs(sv_2mortal(newSVpv("fstate", 6)));
        XPUSHs(sv_2mortal(newSViv(minfo.fState)));
        XPUSHs(sv_2mortal(newSVpv("ftype", 5)));
        XPUSHs(sv_2mortal(newSViv(minfo.fType)));
    }

#void
#getLW(hWnd)
#    HWND hWnd;
#INIT:
#   CWnd myWnd;
#PPCODE:
#    myWnd = CWnd::FromHandle(hWnd);
#    XPUSHs(sv_2mortal(newSVpv("type", 4)));


int
GetMenuItemCount(hMenu)
    HMENU hMenu;
CODE:
    RETVAL = GetMenuItemCount(hMenu);
OUTPUT:
    RETVAL


int
GetMenuItemIndex(hm, sitem)
    HMENU hm;
    char *sitem;
CODE:
    int mi = 0;
    int mic = 0;
    MENUITEMINFO minfo;
    char buff[256] = ""; /* Menu Data Buffer */
    BOOL found = FALSE;

    RETVAL = -1;

    mic = GetMenuItemCount(hm);
    if (mic != -1) {
        /* Look at each item to determine if it is the one we want */
        for (mi = 0; mi < mic; mi++) {
	    /* Refresh menu item info structure */
	    memset(buff, 0, sizeof(buff));
	    minfo.cbSize = sizeof(MENUITEMINFO);
	    minfo.fMask = MIIM_DATA | MIIM_TYPE;
	    minfo.dwTypeData = buff;
	    minfo.cch = sizeof(buff);
	    if (GetMenuItemInfo(hm, mi, TRUE, &minfo) &&
                minfo.fType == MFT_STRING &&
                minfo.dwTypeData != NULL &&
                strncasecmp(minfo.dwTypeData, sitem, strlen(sitem)) == 0) {
                /* Got what we came for, so return index. */
                RETVAL = mi;
                break;
            }
	}
    }
OUTPUT:
    RETVAL

HMENU
GetSystemMenu(hWnd, bRevert)
    HWND hWnd;
    BOOL bRevert;
CODE:
    RETVAL = GetSystemMenu(hWnd, bRevert);
OUTPUT:
    RETVAL

UINT
GetMenuItemID(hMenu, nPos)
    HMENU hMenu;
    int nPos;
CODE:
    RETVAL = GetMenuItemID(hMenu, nPos);
OUTPUT:
    RETVAL

HMENU
GetMenu(hWnd)
    HWND hWnd;
CODE:
    RETVAL = GetMenu(hWnd);
OUTPUT:
    RETVAL


BOOL
SetWindowPos(hWnd, hWndInsertAfter, X, Y, cx, cy, uFlags)
  HWND hWnd;
  HWND hWndInsertAfter;
  int X;
  int Y;
  int cx;
  int cy;
  UINT uFlags;
CODE:
    RETVAL = SetWindowPos(hWnd, hWndInsertAfter, X, Y, cx, cy, uFlags);
OUTPUT:
    RETVAL

void
TabCtrl_SetCurFocus(hWnd, item)
    HWND hWnd
    int item
    CODE:
       TabCtrl_SetCurFocus(hWnd, item);

int
TabCtrl_GetCurFocus(hWnd)
    HWND hWnd
    CODE:
        RETVAL = TabCtrl_GetCurFocus(hWnd);
    OUTPUT:
        RETVAL

int
TabCtrl_SetCurSel(hWnd, item)
    HWND hWnd
    int item
    CODE:
        RETVAL = TabCtrl_SetCurSel(hWnd, item);
    OUTPUT:
        RETVAL

int
TabCtrl_GetItemCount(hWnd)
    HWND hWnd
    CODE:
        RETVAL = TabCtrl_GetItemCount(hWnd);
    OUTPUT:
        RETVAL

void
SendRawKey(vk, flags)
    UINT vk;
    DWORD flags;
CODE:
    BYTE scan = MapVirtualKey(vk, 0);
    keybd_event(vk, scan, flags, 0);

int
VkKeyScan(c)
	int c;
CODE:
	RETVAL = VkKeyScan((char) c);
OUTPUT:
	RETVAL

int
GetAsyncKeyState(c)
	int c;
CODE:
	RETVAL = GetAsyncKeyState(c);
OUTPUT:
	RETVAL

HWND
WindowFromPoint(x, y)
    int x;
    int y;
PREINIT:
    POINT pt;
CODE:
    pt.x = x;
    pt.y = y;
    RETVAL = WindowFromPoint(pt);
OUTPUT:
    RETVAL


#####################################################################
# Waits for input idle for the application, which owns the window
# hWnd. It is a wrapper around WaitForInputIdle Win32 API.
# Does not always work as expected, seams to be not that reliable
# mechanism. But it's better then nothing and there are still some
# cases when it works
#
######################################################################

DWORD
WaitForReady( hWnd, dwMilliseconds = 30000 )
    HWND hWnd;
    DWORD dwMilliseconds;
CODE:
    RETVAL = WaitForWindowInputIdle( hWnd, dwMilliseconds );
OUTPUT:
    RETVAL

############################################################################
HWND
GetPopupHandle(hWnd, x, y, wait=50)
    HWND hWnd;
    int x;
    int y;
    int wait;
CODE:
    RETVAL = PopupHandleGet(hWnd, x, y, wait);
OUTPUT:
    RETVAL
############################################################################


MODULE = Win32::GuiTest		PACKAGE = Win32::GuiTest::DibSect

PROTOTYPES: DISABLE

DibSect *
DibSect::new()

void
DibSect::DESTROY()

bool
DibSect::CopyClient(hwnd, rect=0)
  HWND hwnd
  SV  *rect
CODE:
  RECT r, *pr = 0;
  if (rect)
  {
    if (!(SvROK(rect) &&  (rect = SvRV(rect)) && SvTYPE(rect) == SVt_PVAV))
	    croak("Second argument to CopyClient() must be a reference to array");
    AV * av = (AV*) rect;
    int len = av_len(av) + 1;
    if (len != 4)
      croak("Rectangle requires 4 elements, not %d", len);
    pr = &r;
    SetRectEmpty(pr);
    LONG * p = (LONG *) pr;
    for(int i = 0 ; i < len; i++, p++)
    {
      SV ** psv = av_fetch(av, i, 0);
      if (psv)
        *p = SvIV(*psv);
    }
  }
  RETVAL = THIS->CopyWndClient(hwnd, pr) != 0;
OUTPUT:
  RETVAL

bool
DibSect::CopyWindow(hwnd)
  HWND hwnd
CODE:
  RECT r;
  GetWindowRect(hwnd, &r);
  RETVAL = THIS->CopyWndClient(GetDesktopWindow(), &r) != 0;
OUTPUT:
  RETVAL


bool
DibSect::SaveAs(szFile)
	char *	szFile
CODE:
	RETVAL = THIS->SaveAs(szFile);
OUTPUT:
RETVAL

bool
DibSect::Invert()
CODE:
	RETVAL = THIS->Invert();
OUTPUT:
RETVAL


bool
DibSect::ToGrayScale()
CODE:
	RETVAL = THIS->ToGrayScale();
OUTPUT:
RETVAL

bool
DibSect::Destroy()
CODE:
	RETVAL = THIS->Destroy();
OUTPUT:
RETVAL

bool
DibSect::ToClipboard()
CODE:
	RETVAL = THIS->ToClipboard();
OUTPUT:
RETVAL
