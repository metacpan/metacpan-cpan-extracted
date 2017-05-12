    /*
    ###########################################################################
    # (@)PACKAGE:Win32::GUI::NotifyIcon
    #
    # $Id: NotifyIcon.xs,v 1.6 2006/03/16 21:11:12 robertemay Exp $
    #
    ###########################################################################
    */

#include "GUI.h"

MODULE = Win32::GUI::NotifyIcon     PACKAGE = Win32::GUI::NotifyIcon

PROTOTYPES: DISABLE

#pragma message( "*** PACKAGE Win32::GUI::NotifyIcon..." )

    ###########################################################################
    # (@)INTERNAL:Add(PARENT, %OPTIONS)
BOOL
_Add(parent,...)
    HWND parent
PREINIT:
    NOTIFYICONDATA nid;
CODE:
    ZeroMemory(&nid, sizeof(NOTIFYICONDATA));
    nid.cbSize = NOTIFYICONDATA_V1_SIZE;
    nid.hWnd = parent;
    nid.uCallbackMessage = WM_NOTIFYICON;
    SwitchBit(nid.uFlags, NIF_MESSAGE, 1);
    SwitchBit(nid.uFlags, NIF_INFO, 1);
    nid.uTimeout = 10000;

    ParseNotifyIconOptions(NOTXSCALL sp, mark, ax, items, 1, &nid);

    RETVAL = Shell_NotifyIcon(NIM_ADD, &nid);
OUTPUT:
    RETVAL


    ###########################################################################
    # (@)INTERNAL:Modify(PARENT, %OPTIONS)
BOOL
_Modify(parent,...)
    HWND parent
PREINIT:
    NOTIFYICONDATA nid;
CODE:
    ZeroMemory(&nid, sizeof(NOTIFYICONDATA));
    nid.cbSize = NOTIFYICONDATA_V1_SIZE;
    nid.hWnd = parent;
    nid.uTimeout = 10000;

    ParseNotifyIconOptions(NOTXSCALL sp, mark, ax, items, 1, &nid);

    RETVAL = Shell_NotifyIcon(NIM_MODIFY, &nid);
OUTPUT:
    RETVAL


    ###########################################################################
    # (@)INTERNAL:Delete(PARENT, %OPTIONS)
BOOL
_Delete(parent,...)
    HWND parent
PREINIT:
    NOTIFYICONDATA nid;
CODE:
    ZeroMemory(&nid, sizeof(NOTIFYICONDATA));
    nid.cbSize = NOTIFYICONDATA_V1_SIZE;
    nid.hWnd = parent;

    ParseNotifyIconOptions(NOTXSCALL sp, mark, ax, items, 1, &nid);

    RETVAL = Shell_NotifyIcon(NIM_DELETE, &nid);
OUTPUT:
    RETVAL

    ###########################################################################
    # (@)INTERNAL:SetFocus(PARENT, %OPTIONS)
BOOL
_SetFocus(parent,...)
    HWND parent
PREINIT:
    NOTIFYICONDATA nid;
CODE:
    ZeroMemory(&nid, sizeof(NOTIFYICONDATA));
    nid.cbSize = NOTIFYICONDATA_V1_SIZE;
    nid.hWnd = parent;

    ParseNotifyIconOptions(NOTXSCALL sp, mark, ax, items, 1, &nid);

    RETVAL = Shell_NotifyIcon(NIM_SETFOCUS, &nid);
OUTPUT:
    RETVAL

    ###########################################################################
    # (@)INTERNAL:SetVersion(PARENT, %OPTIONS)
BOOL
_SetVersion(parent,...)
    HWND parent
PREINIT:
    NOTIFYICONDATA nid;
CODE:
    ZeroMemory(&nid, sizeof(NOTIFYICONDATA));
    nid.cbSize = NOTIFYICONDATA_V1_SIZE;
    nid.hWnd = parent;

    ParseNotifyIconOptions(NOTXSCALL sp, mark, ax, items, 1, &nid);

    RETVAL = Shell_NotifyIcon(NIM_SETVERSION, &nid);
OUTPUT:
    RETVAL

