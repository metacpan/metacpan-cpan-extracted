/*
###############################################################################
#
# Win32::GUI - Perl-Win32 Graphical User Interface Extension
#
# 29 Jan 1997 by Aldo Calpini <dada@perl.it>
#
# Version: 1.0 (12 Nov 2004)
#
# Copyright (c) 1997..2004 Aldo Calpini. All rights reserved.
# This program is free software; you can redistribute it and/or
# modify it under the same terms as Perl itself.
#
# $Id: GUI.xs,v 1.69 2011/07/16 14:51:03 acalpini Exp $
#
###############################################################################
 */

#include "GUI.h"
#ifdef __CYGWIN__
#include <cygwin/version.h>
#include <sys/cygwin.h>
#endif

    /*
    ###########################################################################
    # (@)PACKAGE:Win32::GUI
    ###########################################################################
     */

MODULE = Win32::GUI     PACKAGE = Win32::GUI

PROTOTYPES: DISABLE

     ##########################################################################
     # (@)INTERNAL:_constant(NAME)
DWORD
_constant(name)
    char *name
CODE:
    if (strEQ(name, "WIN32__GUI__WINDOW"))
        RETVAL = WIN32__GUI__WINDOW;
    else if (strEQ(name, "WIN32__GUI__DIALOG"))
        RETVAL = WIN32__GUI__DIALOG;
    else if (strEQ(name, "WIN32__GUI__STATIC"))
        RETVAL = WIN32__GUI__STATIC;
    else if (strEQ(name, "WIN32__GUI__BUTTON"))
        RETVAL = WIN32__GUI__BUTTON;
    else if (strEQ(name, "WIN32__GUI__EDIT"))
        RETVAL = WIN32__GUI__EDIT;
    else if (strEQ(name, "WIN32__GUI__LISTBOX"))
        RETVAL = WIN32__GUI__LISTBOX;
    else if (strEQ(name, "WIN32__GUI__COMBOBOX"))
        RETVAL = WIN32__GUI__COMBOBOX;
    else if (strEQ(name, "WIN32__GUI__CHECKBOX"))
        RETVAL = WIN32__GUI__CHECKBOX;
    else if (strEQ(name, "WIN32__GUI__RADIOBUTTON"))
        RETVAL = WIN32__GUI__RADIOBUTTON;
    else if (strEQ(name, "WIN32__GUI__TOOLBAR"))
        RETVAL = WIN32__GUI__TOOLBAR;
    else if (strEQ(name, "WIN32__GUI__PROGRESS"))
        RETVAL = WIN32__GUI__PROGRESS;
    else if (strEQ(name, "WIN32__GUI__STATUS"))
        RETVAL = WIN32__GUI__STATUS;
    else if (strEQ(name, "WIN32__GUI__TAB"))
        RETVAL = WIN32__GUI__TAB;
    else if (strEQ(name, "WIN32__GUI__RICHEDIT"))
        RETVAL = WIN32__GUI__RICHEDIT;
    else if (strEQ(name, "WIN32__GUI__LISTVIEW"))
        RETVAL = WIN32__GUI__LISTVIEW;
    else if (strEQ(name, "WIN32__GUI__TREEVIEW"))
        RETVAL = WIN32__GUI__TREEVIEW;
    else if (strEQ(name, "WIN32__GUI__TRACKBAR"))
        RETVAL = WIN32__GUI__TRACKBAR;
    else if (strEQ(name, "WIN32__GUI__UPDOWN"))
        RETVAL = WIN32__GUI__UPDOWN;
    else if (strEQ(name, "WIN32__GUI__TOOLTIP"))
        RETVAL = WIN32__GUI__TOOLTIP;
    else if (strEQ(name, "WIN32__GUI__ANIMATION"))
        RETVAL = WIN32__GUI__ANIMATION;
    else if (strEQ(name, "WIN32__GUI__REBAR"))
        RETVAL = WIN32__GUI__REBAR;
    else if (strEQ(name, "WIN32__GUI__HEADER"))
        RETVAL = WIN32__GUI__HEADER;
    else if (strEQ(name, "WIN32__GUI__COMBOBOXEX"))
        RETVAL = WIN32__GUI__COMBOBOXEX;
    else if (strEQ(name, "WIN32__GUI__DTPICK"))
        RETVAL = WIN32__GUI__DTPICK;
    else if (strEQ(name, "WIN32__GUI__GRAPHIC"))
        RETVAL = WIN32__GUI__GRAPHIC;
    else if (strEQ(name, "WIN32__GUI__GROUPBOX"))
        RETVAL = WIN32__GUI__GROUPBOX;
    else if (strEQ(name, "WIN32__GUI__SPLITTER"))
        RETVAL = WIN32__GUI__SPLITTER;
    else if (strEQ(name, "WIN32__GUI__MDIFRAME"))
        RETVAL = WIN32__GUI__MDIFRAME;
    else if (strEQ(name, "WIN32__GUI__MDICLIENT"))
        RETVAL = WIN32__GUI__MDICLIENT;
    else if (strEQ(name, "WIN32__GUI__MDICHILD"))
        RETVAL = WIN32__GUI__MDICHILD;
    else if (strEQ(name, "WIN32__GUI__MONTHCAL"))
        RETVAL = WIN32__GUI__MONTHCAL;
    else
        RETVAL = 0xFFFFFFFF;
OUTPUT:
    RETVAL


    ##########################################################################
    # (@)METHOD:GetAsyncKeyState(keyCode)
    # Retrieve the status of the specified virtual key at the time the function
    # is called. The status specifies whether the key is up or down.
    #
    # keyCode -- If A..Z0..9, use the ASCII code. Otherwise, use 
    # a virtual key code. Example: VK_SHIFT
    #
    # Return 1 if the key is depressed, 0 if it's not.
LONG
GetAsyncKeyState(key)
    int key
CODE:
    RETVAL = (GetAsyncKeyState(key) & 0x8000) >>15;
OUTPUT:
    RETVAL
   
    ##########################################################################
    # (@)METHOD:GetKeyState(keyCode)
    # Retrieve the status of the specified virtual key at the time the last
    # keyboard message was retrieved from the message queue.
    #
    # In scalar context returns a value specifying whether the key is up(0)
    # or down(1). In list context, returns a 2 element list with the first
    # element as in scalar context and the second member specifying whether
    # the key is toggled(1) or not(0) - this is only meaningful for keys that
    # have a toggled state: Caps Lock, Num Lock etc.
    #
    # keyCode -- If A..Z0..9, use the ASCII code. Otherwise, use 
    # a virtual key code. Example: VK_SHIFT
void
GetKeyState(key)
    int key
PREINIT:
    USHORT result;
PPCODE:
    result = (USHORT)GetKeyState(key);
    if(GIMME_V == G_ARRAY) {
        /* list context */
        EXTEND(SP, 2);
        XST_mIV(0, (UV) ((result & 0x8000) >> 15));
        XST_mIV(1, (UV) (result & 0x0001));
        XSRETURN(2);
    }
    else {
        /* scalar(and void) context */
        XSRETURN_IV((UV) ((result & 0x8000) >> 15));
    }

    ##########################################################################
    # (@)METHOD:GetKeyboardState()
    # Return array ref with the status of the 256 virtual keys. 
    #
    # The index in the array is the virtual key code. If the value 
    # is true, that key is depressed.
    #
    # Example: 
    #   $key=Win32::GUI::GetKeyboardState;
    #   print 'CTRL is down' if $key->[0x11];
    
AV*
GetKeyboardState()
PREINIT:
     AV   *array;
     BYTE keys[256];
     int  i;
CODE:
     GetKeyboardState(keys);
     array = (AV*)sv_2mortal((SV*)newAV());
     for(i = 0; i <= 256; i++) {
       av_push(array, newSViv(keys[i] & 128));
     }
     RETVAL = array;
OUTPUT:
     RETVAL

    ##########################################################################
    # (@)METHOD:LoadLibrary(NAME)
    # The LoadLibrary function maps the specified executable module into the
    # address space of the calling process.
    #
    # The return value is a handle to the module, or undef on failure.
    #
    # Directory seperators are normalised to windows seperators (C<\>).
    #
    # Under Cygwin, cygwin paths are converted to windows paths
HINSTANCE
LoadLibrary(name)
    char *name;
PREINIT:
    char buffer[MAX_PATH+1];
    int i;
CODE:
#ifdef __CYGWIN__
    /* Under Cygwin, convert paths to windows
     * paths. E.g. convert /usr/local... and /cygdrive/c/...
     */
#if CYGWIN_VERSION_API_MAJOR > 0 || CYGWIN_VERSION_API_MINOR >= 181
    i = cygwin_conv_path(CCP_POSIX_TO_WIN_A|CCP_RELATIVE,name,buffer,MAX_PATH+1);
    if (i < 0) XSRETURN_UNDEF;
#else
    /* old cygwin api */
    if(cygwin_conv_to_win32_path(name,buffer) != 0)
        XSRETURN_UNDEF;
#endif
#else
    /* LoadLibrary on Win98 (at least) doesn't like unix
     * path seperators, so normalise to windows path seperators
     */
    for(i=0; *name && (i<MAX_PATH); ++name,++i) {
        buffer[i] = (*name == '/' ? '\\' : *name);
    }
    if(*name) {
        /* XXX Path too long - although this appears to be what
         * LoadLibrary would return with such a path, it might be
         * better to find a more specific error code.  E.g.
         * ENAMETOOLONG?
         */
        SetLastError(ERROR_FILE_NOT_FOUND);
        errno = ENOENT;
        XSRETURN_UNDEF;
    }
    buffer[i] = 0;
#endif
    RETVAL = LoadLibrary(buffer);
    if(!RETVAL)
        XSRETURN_UNDEF;
OUTPUT:
    RETVAL 
     
     ##########################################################################
     # (@)METHOD:FreeLibrary(LIBRARY)
     # The FreeLibrary function decrements the reference count of the loaded dynamic-link library (DLL) module.
bool
FreeLibrary(library)
    HINSTANCE library;
CODE:
    RETVAL = FreeLibrary(library);
OUTPUT:
    RETVAL

     ##########################################################################
     # (@)METHOD:GetEvent(NAME)
     # Retrieves an event. If the New Event Model is being used, this will
     # return the code-reference of the event you named, otherwise it will
     # return undef.
void
GetEvent(handle,name)
    HWND handle
    char * name
PREINIT:
    SV** eventhandler;
    LPPERLWIN32GUI_USERDATA perlud;
PPCODE:
    perlud = (LPPERLWIN32GUI_USERDATA) GetWindowLongPtr((HWND) handle, GWLP_USERDATA);
    if(perlud == NULL || perlud->hvEvents == NULL) XSRETURN_UNDEF;
    eventhandler = hv_fetch(perlud->hvEvents,name,strlen(name),0);
    if(eventhandler != NULL) {
        SvREFCNT_inc(*eventhandler);
        XPUSHs(*eventhandler);
        XSRETURN(1);
    }
    XSRETURN_UNDEF;

     ##########################################################################
     # (@)METHOD:SetEvent(NAME,HANDLER)
     # Sets an event. If the New Event Model is being used, this will enable
     # the specified event and set it to be handled by the specified C<HANDLER>,
     # which should be a code-reference.
void
SetEvent(handle,name,event)
    HWND handle
    char * name
    SV* event
PREINIT:
    LPPERLWIN32GUI_USERDATA perlud;
    PERLWIN32GUI_CREATESTRUCT perlcs;
PPCODE:
    ZeroMemory(&perlcs, sizeof(PERLWIN32GUI_CREATESTRUCT));
    perlud = (LPPERLWIN32GUI_USERDATA) GetWindowLongPtr((HWND) handle, GWLP_USERDATA);
    if(perlud == NULL) XSRETURN_UNDEF;

    if ( perlud->hvEvents == NULL ) {
         perlud->hvEvents = newHV();
         perlud->dwEventMask = 0;
    }
    if(perlud->hvEvents == NULL) XSRETURN_UNDEF;

    perlcs.iClass = perlud->iClass;
    perlcs.hvEvents = perlud->hvEvents;
    perlcs.dwEventMask = perlud->dwEventMask;

    ParseNEMEvent(NOTXSCALL &perlcs, name, event);

    perlud->hvEvents = perlcs.hvEvents;
    perlud->dwEventMask = perlcs.dwEventMask;
    SwitchBit(perlud->dwPlStyle, PERLWIN32GUI_NEM, (perlud->dwEventMask != 0));

    XSRETURN_YES;

     ##########################################################################
     # (@)METHOD:LoadResource(NAME)
     # Loads a generic resource from the EXE file that your perl process is
     # running as. This is for use when distributing your application. Resources
     # can be packed into the EXE file using many tools including ResHacker.
     #
     # Note that packing resources into a PAR executable will not work. You must
     # first pack the resources into par.exe then use PAR to build your
     # executable.
     #
     # For this routine to work, any resources you wish to load with it must
     # be added to the executable with the RCDATA resource type.
     #
     # If the resource is not found in the EXE, this function will return NULL,
     # otherwise it will return a scalar containing the raw resource data.
void
LoadResource(filename)
    LPCSTR filename
PPCODE:
    HINSTANCE myInstance;
    HRSRC resInfo;
    HGLOBAL resHandle;
    char * resData;
    DWORD resSize;

    myInstance = GetModuleHandle(NULL);
    if(myInstance == NULL) XSRETURN_UNDEF;

    resInfo = FindResource(myInstance,filename,RT_RCDATA);
    if(resInfo == NULL) XSRETURN_UNDEF;

    resSize = SizeofResource(myInstance,resInfo);
    resHandle = LoadResource(myInstance,resInfo);
    if(resHandle == NULL) XSRETURN_UNDEF;

    resData = (char *) LockResource(resHandle);
    if(resData != NULL) {
        // Whew, we have a pointer to our resource data.
        // We would free here, but according to MSDN we don't have to (?!)
        XPUSHs(newSVpvn(resData, resSize));
        XSRETURN(1);
    }
    XSRETURN_UNDEF;


     ##########################################################################
     # (@)METHOD:GetPerlWindow()
     # Returns the handle of the command prompt window your perl script is
     # running in; if called in an array context, returns the handle and the
     # HINSTANCE of your perl process.
void
GetPerlWindow()
PPCODE:
    char OldPerlWindowTitle[1024];
    char NewPerlWindowTitle[1024];
    HWND hwndFound;
    HINSTANCE hinstanceFound;
    // this is an hack from M$'s Knowledge Base
    // to get the HWND of the console in which
    // Perl is running (and Hide() it :-).
    GetConsoleTitle(OldPerlWindowTitle, 1024);
    wsprintf(NewPerlWindowTitle,
             "PERL-%d-%d",
             GetTickCount(),
             GetCurrentProcessId());

    SetConsoleTitle(NewPerlWindowTitle);
    Sleep(40);
    hwndFound = FindWindow(NULL, NewPerlWindowTitle);

    // another hack to get the program's instance
#ifdef NT_BUILD_NUMBER
    hinstanceFound = GetModuleHandle("GUI.PLL");
#else
    hinstanceFound = GetModuleHandle("GUI.DLL");
#endif
    // hinstanceFound = (HINSTANCE) GetWindowLongPtr(hwndFound, GWL_HINSTANCE);
    // sv_hinstance = perl_get_sv("Win32::GUI::hinstance", TRUE);
    // sv_setiv(sv_hinstance, PTR2IV(hinstanceFound));
    SetConsoleTitle(OldPerlWindowTitle);
    if(GIMME == G_ARRAY) {
        EXTEND(SP, 2);
        XST_mIV(0, PTR2IV(hwndFound));
        XST_mIV(1, PTR2IV(hinstanceFound));
        XSRETURN(2);
    } else {
        XSRETURN_IV(PTR2IV(hwndFound));
    }


     ##########################################################################
     # (@)INTERNAL:RegisterClassEx(%OPTIONS)
     # used by new Win32::GUI::Class
void
RegisterClassEx(...)
PPCODE:
    WNDCLASSEX wcx;
    HINSTANCE hinstance;
    
    char * option;
    int i, next_i;

    WNDPROC DefClassProc = NULL;

    ZeroMemory(&wcx, sizeof(WNDCLASSEX));
    wcx.cbSize = sizeof(WNDCLASSEX);

    wcx.style = CS_HREDRAW | CS_VREDRAW; // TODO (default class style...)
    wcx.cbClsExtra = 0;
    wcx.cbWndExtra = 0;
    wcx.lpfnWndProc = WindowMsgLoop;
#ifdef NT_BUILD_NUMBER
    hinstance = GetModuleHandle("GUI.PLL");
#else
    hinstance = GetModuleHandle("GUI.DLL");
#endif
    wcx.hIcon = LoadIcon(hinstance, MAKEINTRESOURCE(IDI_DEFAULTICON));
    wcx.hIconSm = NULL;
    wcx.hCursor = LoadCursor(NULL, IDC_ARROW);
    wcx.lpszMenuName = NULL;

    for(i = 0; i < items; i++) {
        if(strcmp(SvPV_nolen(ST(i)), "-extends") == 0) {
            next_i = i + 1;
            if(!GetClassInfoEx((HINSTANCE) NULL, (LPCTSTR) SvPV_nolen(ST(next_i)), &wcx)) {
                W32G_WARN("Win32::GUI: Class '%s' not found!", SvPV_nolen(ST(next_i)));
                XSRETURN_NO;
            }
            DefClassProc = wcx.lpfnWndProc;
        }
    }

    next_i = -1;
    for(i = 0; i < items; i++) {
        if(next_i == -1) {
            option = SvPV_nolen(ST(i));
            if(strcmp(option, "-name") == 0) {
                next_i = i + 1;
                wcx.lpszClassName = (char *) SvPV_nolen(ST(next_i));
            } else if(strcmp(option, "-color") == 0) {
                next_i = i + 1;
                wcx.hbrBackground = (HBRUSH) SvCOLORREF(NOTXSCALL ST(next_i));
            } else if(strcmp(option, "-brush") == 0) {
                next_i = i + 1;
                wcx.hbrBackground = (HBRUSH) handle_From(NOTXSCALL ST(next_i));
            } else if(strcmp(option, "-visual") == 0) {
                next_i = i + 1;
                // -visual => 0 is obsolete
            } else if(strcmp(option, "-widget") == 0) {
                next_i = i + 1;
                if(strcmp(SvPV_nolen(ST(next_i)), "Container") == 0) {
                    wcx.lpfnWndProc = ContainerMsgLoop;
                } else if(strcmp(SvPV_nolen(ST(next_i)), "Graphic") == 0) {
                    wcx.lpfnWndProc = CustomMsgLoop;
                } else if(strcmp(SvPV_nolen(ST(next_i)), "Splitter") == 0) {
                    wcx.lpfnWndProc = CustomMsgLoop;
                    wcx.hCursor = LoadCursor(hinstance, MAKEINTRESOURCE(IDC_HSPLIT));
                } else if(strcmp(SvPV_nolen(ST(next_i)), "SplitterH") == 0) {
                    wcx.lpfnWndProc = CustomMsgLoop;
                    wcx.hCursor = LoadCursor(hinstance, MAKEINTRESOURCE(IDC_VSPLIT));
                } else if(strcmp(SvPV_nolen(ST(next_i)), "MDIFrame") == 0) {
                    wcx.lpfnWndProc = MDIFrameMsgLoop;
                } else if(strcmp(SvPV_nolen(ST(next_i)), "MDIChild") == 0) {
                    wcx.lpfnWndProc = MDIChildMsgLoop;
                } else {
                    wcx.lpfnWndProc = ControlMsgLoop;
                }
            } else if(strcmp(option, "-style") == 0) {
                next_i = i + 1;
                wcx.style = (UINT)SvIV(ST(next_i));
            } else if(strcmp(option, "-icon") == 0) {
                next_i = i + 1;
                wcx.hIcon = (HICON) handle_From(NOTXSCALL ST(next_i));
            } else if(strcmp(option, "-cursor") == 0) {
                next_i = i + 1;
                wcx.hCursor = (HCURSOR) handle_From(NOTXSCALL ST(next_i));
            } else if(strcmp(option, "-menu") == 0) {
                next_i = i + 1;
                wcx.lpszMenuName = (char *) SvPV_nolen(ST(next_i));
            }
        } else {
            next_i = -1;
        }
    }

    // Register the window class.
    if(RegisterClassEx(&wcx)) {
        
        if (DefClassProc != NULL && DefClassProc != wcx.lpfnWndProc)
            SetDefClassProc (NOTXSCALL wcx.lpszClassName, DefClassProc);

        XSRETURN_YES;
    // Try to reregister
    } else if ( UnregisterClass( wcx.lpszClassName, wcx.hInstance ) ) {
        if( RegisterClassEx(&wcx) ) {
            if (DefClassProc != NULL && DefClassProc != wcx.lpfnWndProc)
                SetDefClassProc (NOTXSCALL wcx.lpszClassName, DefClassProc);

            XSRETURN_YES;
        }
    }    
    XSRETURN_NO;

     ##########################################################################
     # (@)INTERNAL:CreateWindowEx(%OPTIONS)
     # obsoleted, use Create() instead
void
CreateWindowEx(...)
PPCODE:
    HWND myhandle;
    int i, next_i;
    HWND  hParent;
    HMENU hMenu;
    HINSTANCE hInstance;
    LPVOID pPointer;
    DWORD dwStyle;
    DWORD dwExStyle;
    LPCTSTR szClassname;
    LPCTSTR szText;
    int nX, nY, nWidth, nHeight;
    char * option;

    hParent = NULL;
    hMenu = NULL;
    hInstance = NULL;
    pPointer = NULL;
    dwStyle = 0;
    dwExStyle = 0;
    szText = NULL;

    next_i = -1;
    for(i = 0; i < items; i++) {
        if(next_i == -1) {
            option = SvPV_nolen(ST(i));
            if(strcmp(option, "-exstyle") == 0) {
                next_i = i + 1;
                dwExStyle = (DWORD) SvIV(ST(next_i));
            }
            if(strcmp(option, "-class") == 0) {
                next_i = i + 1;
                szClassname = (LPCTSTR) SvPV_nolen(ST(next_i));
            }
            if(strcmp(option, "-text") == 0
            || strcmp(option, "-title") == 0) {
                next_i = i + 1;
                szText = (LPCTSTR) SvPV_nolen(ST(next_i));
            }
            if(strcmp(option, "-style") == 0) {
                next_i = i + 1;
                dwStyle = (DWORD) SvIV(ST(next_i));
            }

            if(strcmp(option, "-left") == 0) {
                next_i = i + 1;
                nX = (int) SvIV(ST(next_i));
            }
            if(strcmp(option, "-top") == 0) {
                next_i = i + 1;
                nY = (int) SvIV(ST(next_i));
            }
            if(strcmp(option, "-height") == 0) {
                next_i = i + 1;
                nHeight = (int) SvIV(ST(next_i));
            }
            if(strcmp(option, "-width") == 0) {
                next_i = i + 1;
                nWidth = (int) SvIV(ST(next_i));
            }
            if(strcmp(option, "-parent") == 0) {
                next_i = i + 1;
                hParent = (HWND) handle_From(NOTXSCALL ST(next_i));
            }
            if(strcmp(option, "-menu") == 0) {
                next_i = i + 1;
                hMenu = (HMENU) handle_From(NOTXSCALL ST(next_i));
            }
            if(strcmp(option, "-instance") == 0) {
                next_i = i + 1;
                hInstance = INT2PTR(HINSTANCE,SvIV(ST(next_i)));
            }
            if(strcmp(option, "-data") == 0) {
                next_i = i + 1;
                pPointer = (LPVOID) SvPV_nolen(ST(next_i));
            }

        } else {
            next_i = -1;
        }
    }
#ifdef PERLWIN32GUI_DEBUG
    printf("XS(CreateWindowEx): Done parsing parameters...\n");
    printf("XS(CreateWindowEx): dwExStyle = 0x%x\n", dwExStyle);
    printf("XS(CreateWindowEx): szClassname = %s\n", szClassname);
    printf("XS(CreateWindowEx): szText = %s\n", szText);
    printf("XS(CreateWindowEx): dwStyle = 0x%x\n", dwStyle);
    printf("XS(CreateWindowEx): nX = %d\n", nX);
    printf("XS(CreateWindowEx): nY = %d\n", nY);
    printf("XS(CreateWindowEx): nWidth = %d\n", nWidth);
    printf("XS(CreateWindowEx): nHeight = %d\n", nHeight);
    printf("XS(CreateWindowEx): hParent = 0x%x\n", hParent);
    printf("XS(CreateWindowEx): hMenu = 0x%x\n", hMenu);
    printf("XS(CreateWindowEx): hInstance = 0x%x\n", hInstance);
    printf("XS(CreateWindowEx): pPointer = 0x%x\n", pPointer);
#endif
    if(myhandle = CreateWindowEx(dwExStyle,
                                 szClassname,
                                 szText,
                                 dwStyle,
                                 nX,
                                 nY,
                                 nWidth,
                                 nHeight,
                                 hParent,
                                 hMenu,
                                 hInstance,
                                 pPointer)) {
        XSRETURN_IV(PTR2IV(myhandle));
    } else {
        XSRETURN_NO;
    }


    ###########################################################################
    # (@)INTERNAL:Create(%OPTIONS)
    # this is where all the windows are created
void
Create(...)
PPCODE:
    HWND myhandle;
    int first_i;
    PERLWIN32GUI_CREATESTRUCT perlcs;
    LPVOID pPointer;
    SV* self;
    SV** stored;
    SV* storing;
    SV** font;
    LPPERLWIN32GUI_USERDATA perlud;

    ZeroMemory(&perlcs, sizeof(PERLWIN32GUI_CREATESTRUCT));

    self = newSVsv(ST(0));
    sv_rvweaken(self);

    perlcs.cs.hInstance = GetModuleHandle(NULL);
    perlcs.hvSelf = (HV*) SvRV(self);
    perlcs.iClass = (int)SvIV(ST(1));
    perlcs.clrForeground = CLR_INVALID;
    perlcs.clrBackground = CLR_INVALID;
    perlcs.iMinWidth = -1;
    perlcs.iMaxWidth = -1;
    perlcs.iMinHeight = -1;
    perlcs.iMaxHeight = -1;    

    // #### fill the default parameters for classes
    OnPreCreate[perlcs.iClass](NOTXSCALL &perlcs);

    first_i = 2;
    if(SvROK(ST(2))) {
        perlcs.cs.hwndParent = (HWND) handle_From(NOTXSCALL ST(2));
        perlcs.hvParent = (HV*) SvRV(ST(2));
        first_i = 3;
    }

    // #### options parsing loop
    ParseWindowOptions(NOTXSCALL sp, mark, ax, items, first_i, &perlcs);

    // No event model set, then force default event model.
    if ( !(perlcs.dwPlStyle & PERLWIN32GUI_OEM) & !(perlcs.dwPlStyle & PERLWIN32GUI_NEM)) {
        SwitchBit(perlcs.dwPlStyle, PERLWIN32GUI_OEM, 1);
    }

    // #### post-processing default parameters
    switch(perlcs.iClass) {
    case WIN32__GUI__BUTTON:
        CalcControlSize(NOTXSCALL &perlcs, 16, 8);
        break;
    case WIN32__GUI__CHECKBOX:
    case WIN32__GUI__RADIOBUTTON:
        CalcControlSize(NOTXSCALL &perlcs, 24, 8);
        break;
    case WIN32__GUI__STATIC:
        CalcControlSize(NOTXSCALL &perlcs, 0, 0);
        break;
    }

    // #### default styles for all controls
    if(perlcs.iClass != WIN32__GUI__WINDOW && 
       perlcs.iClass != WIN32__GUI__DIALOG &&
       perlcs.iClass != WIN32__GUI__MDIFRAME &&
       perlcs.iClass != WIN32__GUI__MDICHILD &&
       perlcs.iClass != WIN32__GUI__TOOLTIP ) {
        SwitchBit(perlcs.cs.style, WS_CHILD, 1);
    }
#ifdef PERLWIN32GUI_STRONGDEBUG
    printf("XS(Create): Done parsing parameters...\n");
    printf("XS(Create): dwExStyle = 0x%x\n", perlcs.cs.dwExStyle);
    printf("XS(Create): szClassname = '%s'\n", perlcs.cs.lpszClass);
    printf("XS(Create): szName = '%s'\n", perlcs.cs.lpszName);
    printf("XS(Create): dwStyle = 0x%x\n", perlcs.cs.style);
    printf("XS(Create): nX = %d\n", perlcs.cs.x);
    printf("XS(Create): nY = %d\n", perlcs.cs.y);
    printf("XS(Create): nWidth = %d\n", perlcs.cs.cx);
    printf("XS(Create): nHeight = %d\n", perlcs.cs.cy);
    printf("XS(Create): hParent = 0x%x\n", perlcs.cs.hwndParent);
    printf("XS(Create): hMenu = 0x%x\n", perlcs.cs.hMenu);
    printf("XS(Create): hInstance = 0x%x\n", perlcs.cs.hInstance);
    printf("XS(Create): dwPlStyle = 0x%x\n", perlcs.dwPlStyle);
#endif

    // #### prepare the ground for the window
    Newz(0, perlud, 1, PERLWIN32GUI_USERDATA);
    perlud->dwSize = sizeof(PERLWIN32GUI_USERDATA);
    PERLUD_STORE;
    perlud->svSelf = self;
    if (NULL != perlcs.szWindowName) {
        strcpy( perlud->szWindowName, perlcs.szWindowName);
    } else {
        sprintf(perlud->szWindowName, "#%x", perlud);
        perlcs.szWindowName = perlud->szWindowName;
    }
    perlud->iClass = perlcs.iClass;
    perlud->hAcc = perlcs.hAcc;
    perlud->hCursor = perlcs.hCursor;
    perlud->dwPlStyle = perlcs.dwPlStyle;
    perlud->iMinWidth = perlcs.iMinWidth;
    perlud->iMaxWidth = perlcs.iMaxWidth;
    perlud->iMinHeight = perlcs.iMinHeight;
    perlud->iMaxHeight = perlcs.iMaxHeight;
    perlud->clrForeground = perlcs.clrForeground;
    perlud->clrBackground = perlcs.clrBackground;
    perlud->hBackgroundBrush = perlcs.hBackgroundBrush;
    perlud->bDeleteBackgroundBrush = perlcs.bDeleteBackgroundBrush;
    perlud->hvEvents = perlcs.hvEvents;
    perlud->dwEventMask = perlcs.dwEventMask;
    perlud->dwData = PTR2IV(perlcs.cs.lpCreateParams);
    pPointer = perlud;

    // #### the following can be vital for the window
    // #### because as soon as it is created the message
    // #### loop is activated and data needs to be there
    storing = newSViv((IV) perlcs.iClass);
    stored = hv_store_mg(NOTXSCALL perlcs.hvSelf, "-type", 5, storing, 0);  // TODO : used ?
    storing = newSVpv((char *)perlcs.szWindowName, 0);
    stored = hv_store_mg(NOTXSCALL perlcs.hvSelf, "-name", 5, storing, 0);

    // Specific MDI_CLIENT : Send CLIENTCREATESTRUCT as LPARAM
    if(perlcs.iClass == WIN32__GUI__MDICLIENT ) {
        pPointer = perlcs.cs.lpCreateParams;
    }

    // #### and finally, creation of the window
#ifdef PERLWIN32GUI_STRONGDEBUG
    printf("XS(Create): Done initialization of USERDATA struct...\n");
#endif
    if(myhandle = CreateWindowEx(
        perlcs.cs.dwExStyle,
        perlcs.cs.lpszClass,
        perlcs.cs.lpszName,
        perlcs.cs.style,
        perlcs.cs.x,
        perlcs.cs.y,
        perlcs.cs.cx,
        perlcs.cs.cy,
        perlcs.cs.hwndParent,
        perlcs.cs.hMenu,
        perlcs.cs.hInstance,
        pPointer
    )) {
        // #### ok, we can fill this object's hash
#ifdef PERLWIN32GUI_STRONGDEBUG
        printf("XS(Create): storing -handle...\n");
#endif
        storing = newSViv(PTR2IV(myhandle));
        stored = hv_store_mg(NOTXSCALL perlcs.hvSelf, "-handle", 7, storing, 0);
        // #### set the font for the control
#ifdef PERLWIN32GUI_STRONGDEBUG
        printf("XS(Create): storing -font...\n");
#endif
        if(perlcs.hFont != NULL) {
            storing = newSViv(PTR2IV(perlcs.hFont));
            stored = hv_store_mg(NOTXSCALL perlcs.hvSelf, "-font", 5, storing, 0);
            SendMessage(myhandle, WM_SETFONT, (WPARAM) perlcs.hFont, 0);
        } else if(perlcs.cs.hwndParent != NULL && perlcs.hvParent != NULL) {
            font = hv_fetch_mg(NOTXSCALL perlcs.hvParent, "-font", 5, FALSE);
            if(font != NULL && SvOK(*font)) {
                perlcs.hFont = (HFONT) handle_From(NOTXSCALL *font);
                SendMessage(myhandle, WM_SETFONT, (WPARAM) perlcs.hFont, 0);
            } else {
                perlcs.hFont = (HFONT) GetStockObject(DEFAULT_GUI_FONT);
                SendMessage(myhandle, WM_SETFONT, (WPARAM) perlcs.hFont, 0);
            }
        }
        if(NULL == perlcs.hAcc) {
#ifdef PERLWIN32GUI_STRONGDEBUG
            printf("XS(Create): storing -accel...\n");
#endif
            stored = hv_store_mg(NOTXSCALL perlcs.hvSelf, "-accel", 6, newSViv(0), 0);
        }

        // #### add (or create) the tooltip
        if(perlcs.szTip != NULL) {
            if(perlcs.hvParent != NULL) {
                if(perlcs.hTooltip == NULL) {
                    SV** t;
                    t = hv_fetch_mg(NOTXSCALL perlcs.hvParent, "-tooltip", 8, 0);
                    if(t != NULL && SvOK( *t )) {
                        perlcs.hTooltip = INT2PTR(HWND,SvIV(*t));
                    }
                }
                if(perlcs.hTooltip == NULL) {
#ifdef PERLWIN32GUI_STRONGDEBUG
                    printf("XS(Create): creating -tooltip...\n");
#endif
                    perlcs.hTooltip = CreateTooltip(NOTXSCALL perlcs.hvParent);
                }
            }
#ifdef PERLWIN32GUI_STRONGDEBUG
            printf("XS(Create): adding -tooltip...\n");
#endif
            TOOLINFO ti;
            ZeroMemory(&ti, sizeof(TOOLINFO));
            ti.cbSize = sizeof(TOOLINFO);
            ti.uFlags = TTF_IDISHWND | TTF_CENTERTIP | TTF_SUBCLASS;
            ti.hwnd = perlcs.cs.hwndParent;
            ti.uId = (WPARAM) myhandle;
            ti.lpszText = perlcs.szTip;
            SendMessage(perlcs.hTooltip, TTM_ADDTOOL, 0, (LPARAM) &ti);
        }

        // #### store the child in the parent hash
#ifdef PERLWIN32GUI_STRONGDEBUG
        printf("XS(Create): storing child into parent...\n");
#endif
        if(perlcs.hvParent != NULL && perlcs.szWindowName != NULL) {
            // storing = newSVsv(ST(0));
            // sv_rvweaken(storing);
            storing = SvREFCNT_inc (self);
            stored = hv_store_mg(NOTXSCALL perlcs.hvParent, perlcs.szWindowName, strlen(perlcs.szWindowName), storing, 0);
        }

        // #### other post-creation class-specific initializations...
#ifdef PERLWIN32GUI_STRONGDEBUG
        printf("XS(Create): post-creation phase...\n");
#endif
        OnPostCreate[perlcs.iClass](NOTXSCALL myhandle, &perlcs);

        // #### store a pointer to the Perl object in the window's USERDATA
#ifdef PERLWIN32GUI_STRONGDEBUG
        printf("XS(Create): storing GWLP_USERDATA...\n");
#endif

        // Specific MDI_CLIENT : SubClass Window
        // We need subclass after window creation for IDFirstChild work.
        if(perlcs.iClass == WIN32__GUI__MDICLIENT ) {
            perlud->dwPlStyle |= PERLWIN32GUI_CUSTOMCLASS;           
            perlud->WndProc = (WNDPROC) SetWindowLongPtr(myhandle, GWLP_WNDPROC, (LONG_PTR) MDIClientMsgLoop);
            SetWindowLongPtr(myhandle, GWLP_USERDATA, (LONG_PTR) perlud);
        }

        // Sub class all standard window control as child control (no WM_CREATE or WN_NCCREATE catch)
        if( !(perlud->dwPlStyle & PERLWIN32GUI_CUSTOMCLASS) ) {
            LPPERLWIN32GUI_USERDATA testud;
            testud = (LPPERLWIN32GUI_USERDATA) GetWindowLongPtr(myhandle, GWLP_USERDATA);
            if (!ValidUserData(testud) ) {
                perlud->WndProc = (WNDPROC) SetWindowLongPtr(myhandle, GWLP_WNDPROC, (LONG_PTR) ControlMsgLoop);
                SetWindowLongPtr(myhandle, GWLP_USERDATA, (LONG_PTR) perlud);
            }
        }

        // #### (try to) figure out which MsgLoop procedure to use
        if (perlcs.hvParent != NULL) {
            LPPERLWIN32GUI_USERDATA parentud;
            parentud = (LPPERLWIN32GUI_USERDATA) GetWindowLongPtr(perlcs.cs.hwndParent, GWLP_USERDATA);
            if( ValidUserData(parentud) ) {
                if(parentud->iClass != WIN32__GUI__WINDOW && 
                   parentud->iClass != WIN32__GUI__DIALOG &&
                   parentud->iClass != WIN32__GUI__MDIFRAME &&
                   parentud->iClass != WIN32__GUI__MDICLIENT &&
                   !(parentud->dwPlStyle & PERLWIN32GUI_CONTAINER)) {
                    SwitchBit(parentud->dwPlStyle, PERLWIN32GUI_CONTAINER, 1);
                }
            }
        }
#ifdef PERLWIN32GUI_STRONGDEBUG
        printf("XS(Create): DONE!\n");
#endif
        XSRETURN_IV(PTR2IV(myhandle));
    } else {
#ifdef PERLWIN32GUI_STRONGDEBUG
        printf("XS(Create): CreateWindowEx failed, returning undef\n");
#endif
        XSRETURN_NO;
    }

    ###########################################################################
    # (@)METHOD:Change(HANDLE, %OPTIONS)
    # Change most of the options used when the object was created.
void
Change(...)
PPCODE:
    HWND handle;
    PERLWIN32GUI_CREATESTRUCT perlcs;
    LPPERLWIN32GUI_USERDATA perlud;

    handle = (HWND) handle_From(NOTXSCALL ST(0));
    perlud = (LPPERLWIN32GUI_USERDATA) GetWindowLongPtr(handle, GWLP_USERDATA);

    ZeroMemory(&perlcs, sizeof(PERLWIN32GUI_CREATESTRUCT));
    if( ! ValidUserData(perlud) ) {
        XSRETURN_UNDEF;
    }

    perlcs.hvSelf = (HV*) SvRV(perlud->svSelf);
    perlcs.cs.style = (LONG)GetWindowLongPtr(handle, GWL_STYLE);
    perlcs.cs.dwExStyle = (DWORD)GetWindowLongPtr(handle, GWL_EXSTYLE);
    if(perlcs.hvSelf != NULL) {
        // #### retrieve windows data
        perlcs.iClass = perlud->iClass;
        perlcs.hAcc = perlud->hAcc;
        perlcs.hCursor = perlud->hCursor;
        perlcs.dwPlStyle= perlud->dwPlStyle;
        perlcs.iMinWidth = perlud->iMinWidth;
        perlcs.iMaxWidth = perlud->iMaxWidth;
        perlcs.iMinHeight = perlud->iMinHeight;
        perlcs.iMaxHeight = perlud->iMaxHeight;
        perlcs.clrForeground = perlud->clrForeground;
        perlcs.clrBackground = perlud->clrBackground;
        perlcs.hBackgroundBrush = perlud->hBackgroundBrush;
        perlcs.bDeleteBackgroundBrush = perlud->bDeleteBackgroundBrush;
        perlcs.hvEvents    = perlud->hvEvents;
        perlcs.dwEventMask = perlud->dwEventMask;
#ifdef PERLWIN32GUI_STRONGDEBUG
        printf("XS(Change): BEFORE dwExStyle = 0x%x\n", perlcs.cs.dwExStyle);
        printf("XS(Change): BEFORE szClassname = %s\n", perlcs.cs.lpszClass);
        printf("XS(Change): BEFORE szName = %s\n", perlcs.cs.lpszName);
        printf("XS(Change): BEFORE dwStyle = 0x%x\n", perlcs.cs.style);
        printf("XS(Change): BEFORE nX = %d\n", perlcs.cs.x);
        printf("XS(Change): BEFORE nY = %d\n", perlcs.cs.y);
        printf("XS(Change): BEFORE nWidth = %d\n", perlcs.cs.cx);
        printf("XS(Change): BEFORE nHeight = %d\n", perlcs.cs.cy);
        printf("XS(Change): BEFORE hParent = 0x%x\n", perlcs.cs.hwndParent);
        printf("XS(Change): BEFORE hMenu = 0x%x\n", perlcs.cs.hMenu);
        printf("XS(Change): BEFORE hInstance = 0x%x\n", perlcs.cs.hInstance);
        printf("XS(Change): BEFORE clrForeground = 0x%x\n", perlcs.clrForeground);
        printf("XS(Change): BEFORE clrBackground = 0x%x\n", perlcs.clrBackground);
        printf("XS(Change): BEFORE hBackgroundBrush = 0x%x\n", perlcs.hBackgroundBrush);
        printf("XS(Change): BEFORE bDeleteBackgroundBrush = %d\n", perlcs.bDeleteBackgroundBrush);
#endif
        // #### parse new window options
        ParseWindowOptions(NOTXSCALL sp, mark, ax, items, 1, &perlcs);

        // #### default styles for all controls
        if(perlcs.iClass != WIN32__GUI__WINDOW && 
           perlcs.iClass != WIN32__GUI__DIALOG &&
           perlcs.iClass != WIN32__GUI__MDIFRAME &&
           perlcs.iClass != WIN32__GUI__MDICHILD) {
            SwitchBit(perlcs.cs.style, WS_CHILD, 1);
        }
#ifdef PERLWIN32GUI_STRONGDEBUG
        printf("XS(Change): AFTER dwExStyle = 0x%x\n", perlcs.cs.dwExStyle);
        printf("XS(Change): AFTER szClassname = %s\n", perlcs.cs.lpszClass);
        printf("XS(Change): AFTER szName = %s\n", perlcs.cs.lpszName);
        printf("XS(Change): AFTER dwStyle = 0x%x\n", perlcs.cs.style);
        printf("XS(Change): AFTER nX = %d\n", perlcs.cs.x);
        printf("XS(Change): AFTER nY = %d\n", perlcs.cs.y);
        printf("XS(Change): AFTER nWidth = %d\n", perlcs.cs.cx);
        printf("XS(Change): AFTER nHeight = %d\n", perlcs.cs.cy);
        printf("XS(Change): AFTER hParent = 0x%x\n", perlcs.cs.hwndParent);
        printf("XS(Change): AFTER hMenu = 0x%x\n", perlcs.cs.hMenu);
        printf("XS(Change): AFTER hInstance = 0x%x\n", perlcs.cs.hInstance);
        printf("XS(Change): AFTER clrForeground = 0x%x\n", perlcs.clrForeground);
        printf("XS(Change): AFTER clrBackground = 0x%x\n", perlcs.clrBackground);
        printf("XS(Change): AFTER hBackgroundBrush = 0x%x\n", perlcs.hBackgroundBrush);
        printf("XS(Change): AFTER bDeleteBackgroundBrush = %d\n", perlcs.bDeleteBackgroundBrush);
#endif
        // #### Perform changes
        if(NULL != perlcs.szWindowName) {
            strcpy(perlud->szWindowName, perlcs.szWindowName);
        }

        perlud->iClass = perlcs.iClass;
        perlud->hAcc = perlcs.hAcc;
        perlud->hCursor = perlcs.hCursor;
        perlud->dwPlStyle=  perlcs.dwPlStyle;
        perlud->iMinWidth = perlcs.iMinWidth;
        perlud->iMaxWidth = perlcs.iMaxWidth;
        perlud->iMinHeight = perlcs.iMinHeight;
        perlud->iMaxHeight = perlcs.iMaxHeight;
        perlud->clrForeground = perlcs.clrForeground;
        perlud->clrBackground = perlcs.clrBackground;
        perlud->hBackgroundBrush = perlcs.hBackgroundBrush;
        perlud->bDeleteBackgroundBrush = perlcs.bDeleteBackgroundBrush;
        perlud->hvEvents    = perlcs.hvEvents;
        perlud->dwEventMask = perlcs.dwEventMask;
       
        if(perlcs.cs.lpszName != NULL)
            SetWindowText(handle, perlcs.cs.lpszName);

        SetWindowLongPtr(handle, GWL_STYLE, perlcs.cs.style);
        SetWindowLongPtr(handle, GWL_EXSTYLE, perlcs.cs.dwExStyle);

        if(perlcs.cs.x != 0 || perlcs.cs.y != 0)
            SetWindowPos(handle, (HWND) NULL, perlcs.cs.x, perlcs.cs.y, 0, 0,
                                 SWP_NOZORDER | SWP_NOOWNERZORDER | SWP_NOSIZE);
        if(perlcs.cs.cx != 0 || perlcs.cs.cy != 0)
            SetWindowPos(handle, (HWND) NULL, 0, 0, perlcs.cs.cx, perlcs.cs.cy,
                                 SWP_NOZORDER | SWP_NOOWNERZORDER | SWP_NOMOVE);
        if(perlcs.cs.hMenu != NULL)
            SetMenu(handle, perlcs.cs.hMenu);

        if(perlcs.hFont != NULL) {
            hv_store_mg(NOTXSCALL perlcs.hvSelf, "-font", 5, newSViv(PTR2IV(perlcs.hFont)), 0);
            SendMessage(handle, WM_SETFONT, (WPARAM) perlcs.hFont, 0);
        }

        // ### Class Post creation
        OnPostCreate[perlcs.iClass](NOTXSCALL handle, &perlcs);

        /* TODO: change class ???
        if(perlcs.cs.iClass != NULL)
            SetWindowLong(handle, GWL_
        */

        XSRETURN_YES;
    } else {
        XSRETURN_NO;
    }

    ###########################################################################
    # (@)METHOD:Dialog()
    # Enter the GUI dialog phase: the script halts, the user can interact with
    # the created windows and events subroutines are triggered as necessary;
    # note that this function must be called without ANY parameter or
    # instantiation (eg. don't call it as method of a created object):
    #
    #   Win32::GUI::Dialog(); # correct
    #   $Window->Dialog();    # !!!WRONG!!!
    #
    # Win32::GUI::Dialog(); does a similar thing to
    #    while(Win32::GUI::DoEvents() != -1) {};
    #
    # See also DoEvents()
    # See also DoModal()
WPARAM
Dialog(hwnd=NULL)
    HWND hwnd
PREINIT:
    MSG msg;
    HWND phwnd;
    HWND thwnd;
    int stayhere;
    BOOL fIsDialog;
    BOOL fIsMDI;
    HACCEL acc;
    LPPERLWIN32GUI_USERDATA perlud;
    LPPERLWIN32GUI_USERDATA tperlud;
CODE:
    stayhere = 1;
    fIsDialog = FALSE;
    while (stayhere) {

        ENTER;
        SAVETMPS;

        stayhere = GetMessage(&msg, hwnd, 0, 0);

        if(msg.message == WM_EXITLOOP) {
            stayhere = 0;
            msg.wParam = (WPARAM) -1;
        } else if(stayhere == -1) {
            stayhere = 0;
            msg.wParam = (WPARAM) -2; // an error occurred...
        } else {
            // #### trace back to the window's parent
            phwnd = msg.hwnd;
            while((thwnd = GetParent(phwnd)) && IsChild(thwnd, phwnd) ) {
                phwnd = thwnd;
            }
            // #### now see if the parent window is a DialogBox
            fIsDialog = fIsMDI = FALSE;
            acc = NULL;
            perlud = (LPPERLWIN32GUI_USERDATA) GetWindowLongPtr(phwnd, GWLP_USERDATA);
            if( ValidUserData(perlud) ) {
                fIsDialog = perlud->dwPlStyle & PERLWIN32GUI_DIALOGUI;
                fIsMDI    = perlud->dwPlStyle & (PERLWIN32GUI_MDIFRAME | PERLWIN32GUI_HAVECHILDWINDOW);
                acc = perlud->hAcc;
            }
            // ### If the parent window is a MDIFrame the active MDIChild 
            // ### can be THE DialogBox
            if(fIsMDI
                && (thwnd = (HWND)SendMessage(INT2PTR(HWND, perlud->dwData), WM_MDIGETACTIVE, (WPARAM) 0, (LPARAM) NULL))
                && (tperlud = (LPPERLWIN32GUI_USERDATA) GetWindowLongPtr(thwnd, GWLP_USERDATA))
                && ValidUserData(tperlud))
            {
                fIsDialog = tperlud->dwPlStyle & PERLWIN32GUI_DIALOGUI;
            }
            else {
                thwnd = phwnd;
            }

            if( !( (fIsMDI && TranslateMDISysAccel(INT2PTR(HWND, perlud->dwData), &msg)) ||
                   (acc && TranslateAccelerator(phwnd, acc, &msg))              ||
                   (fIsDialog && IsDialogMessage(thwnd, &msg)) ) 
              ){
                TranslateMessage(&msg);
                DispatchMessage(&msg);
            }
        }

        FREETMPS;
        LEAVE;
    }

    RETVAL = msg.wParam;
OUTPUT:
    RETVAL


    ###########################################################################
    # (@)METHOD:DoEvents(hwnd=NULL,wMsgFilterMin=0,wMsgFilterMax=0,wRemoveMsg=PM_REMOVE)
    # Performs all pending GUI events and returns the status. If DoEvents()
    # returns -1, your GUI has normally terminated.
    #
    # You can call $window->DoEvents() to process pending events relating to a
    # specific window, or Win32::GUI::DoEvents() to process pending events for all
    # windows.
    #
    # see also Dialog()
WPARAM
DoEvents(hwnd=NULL,wMsgFilterMin=0,wMsgFilterMax=0,wRemoveMsg=PM_REMOVE)
    HWND hwnd
    UINT wMsgFilterMin
    UINT wMsgFilterMax
    UINT wRemoveMsg
PREINIT:
    MSG msg;
    HWND phwnd;
    HWND thwnd;
    int stayhere;
    BOOL fIsDialog;
    BOOL fIsMDI;
    HACCEL acc;
    LPPERLWIN32GUI_USERDATA perlud;
    LPPERLWIN32GUI_USERDATA tperlud;
CODE:
    stayhere = 1;
    fIsDialog = FALSE;
    while(stayhere) {
        stayhere = PeekMessage(&msg, hwnd, wMsgFilterMin, wMsgFilterMax, wRemoveMsg);
#ifdef PERLWIN32GUI_STRONGDEBUG
        printf("XS(DoEvents): PeekMessage returned %d\n", stayhere);
#endif
        if (stayhere) {
            if(msg.message == WM_EXITLOOP) {
                stayhere = 0;
                msg.wParam = (WPARAM) -1;
            } else  {
                // #### trace back to the window's parent
                phwnd = msg.hwnd;
                while((thwnd = GetParent(phwnd)) && IsChild(thwnd, phwnd) ) {
                    phwnd = thwnd;
                }
                // #### now see if the parent window is a DialogBox
                fIsDialog = fIsMDI = FALSE;
                acc = NULL;
                perlud = (LPPERLWIN32GUI_USERDATA) GetWindowLongPtr(phwnd, GWLP_USERDATA);
                if( ValidUserData(perlud) ) {
                    fIsDialog = perlud->dwPlStyle & PERLWIN32GUI_DIALOGUI;
                    fIsMDI    = perlud->dwPlStyle & (PERLWIN32GUI_MDIFRAME | PERLWIN32GUI_HAVECHILDWINDOW);
                    acc = perlud->hAcc;
                }
                // ### If the parent window is a MDIFrame the active MDIChild 
                // ### can be THE DialogBox
                if(fIsMDI
                    && (thwnd = (HWND)SendMessage(INT2PTR(HWND, perlud->dwData), WM_MDIGETACTIVE, (WPARAM) 0, (LPARAM) NULL))
                    && (tperlud = (LPPERLWIN32GUI_USERDATA) GetWindowLongPtr(thwnd, GWLP_USERDATA))
                    && ValidUserData(tperlud))
                {
                    fIsDialog = tperlud->dwPlStyle & PERLWIN32GUI_DIALOGUI;
                }
                else {
                    thwnd = phwnd;
                }

                if( !( (fIsMDI && TranslateMDISysAccel(INT2PTR(HWND, perlud->dwData), &msg)) ||
                       (acc && TranslateAccelerator(phwnd, acc, &msg))              ||
                       (fIsDialog && IsDialogMessage(thwnd, &msg)) ) 
                  ){
                    TranslateMessage(&msg);
                    DispatchMessage(&msg);
                }
            }
        }
        else
            msg.wParam = (WPARAM) 0;
    }
    RETVAL = msg.wParam;
OUTPUT:
    RETVAL


    ###########################################################################
    # (@)METHOD:DoModal([DISABLE_ALL=FALSE])
    # Enter the GUI dialog phase for a specific window: the script halts, the
    # user can interact with the window, events subroutines are triggered as
    # necessary, but no other windows in the application will accept input.
    # DoModal() also brings the window on top of all other windows.
    #
    # B<DISABLE_ALL> flag can set for deactivate all top window and not only parent/active window.
    #
    # The correct usage is:
    #   $window->DoModal(1);
    #
    # To exit from the GUI dialog phase of the modal window, return -1 from the event handler.
    #
    # See also Dialog()
    # See also DoEvents()
WPARAM
DoModal(handle, all=FALSE)
    HWND handle
    BOOL all
PREINIT:
    LPPERLWIN32GUI_USERDATA perlud;
    MSG msg;
    int stayhere;
    HWND phwnd;
    HWND thwnd;
    BOOL fIsDialog;
    BOOL fIsMDI;
    HACCEL acc;
    HWND parent;
CODE:
    // Set ISMODAL flag
    perlud = (LPPERLWIN32GUI_USERDATA) GetWindowLongPtr(handle, GWLP_USERDATA);
    if( !ValidUserData(perlud) || (perlud->dwPlStyle & PERLWIN32GUI_ISMODAL) )
        XSRETURN_NO;

    perlud->dwPlStyle |= PERLWIN32GUI_ISMODAL;

    // Find its owner window if any or use ActiveWindow
    parent = GetWindow(handle, GW_OWNER);
    if (parent == NULL) {
        parent = GetActiveWindow(); 
    }

    // Disable parent window or all top window
    if (all)
        EnumThreadWindows (GetWindowThreadProcessId(parent, NULL), (WNDENUMPROC) EnableWindowsProc, (LPARAM) FALSE);
    else
        EnableWindow (parent, FALSE);

    // Enable/Show Dialog
    EnableWindow (handle, TRUE);
    ShowWindow(handle, SW_SHOWNORMAL);
    SetActiveWindow(handle);

    // Go to message loop
    stayhere = 1;
    while (stayhere) {

        ENTER;
        SAVETMPS;

        stayhere = GetMessage(&msg, NULL, 0, 0);
 
        if(msg.message == WM_EXITLOOP || msg.message == WM_QUIT) {
            stayhere = 0;
            msg.wParam = (WPARAM) 0;  // Don't return -1 for a DoModal
        } else if(stayhere == -1) {
            stayhere = 0;
            msg.wParam = (WPARAM) -1; // an error occurred...
        } else {

            // #### trace back to the window's parent
            phwnd = msg.hwnd;
            while((thwnd = GetParent(phwnd)) && IsChild(thwnd, phwnd) ) {
                phwnd = thwnd;
            }
            // #### now see if the parent window is a DialogBox
            fIsDialog = fIsMDI = FALSE;
            acc = NULL;
            perlud = (LPPERLWIN32GUI_USERDATA) GetWindowLongPtr(phwnd, GWLP_USERDATA);
            if( ValidUserData(perlud) ) {
                fIsDialog = perlud->dwPlStyle & PERLWIN32GUI_DIALOGUI;
                fIsMDI    = perlud->dwPlStyle & (PERLWIN32GUI_MDIFRAME | PERLWIN32GUI_HAVECHILDWINDOW);
                acc = perlud->hAcc;
            }

            if( !( (fIsMDI && TranslateMDISysAccel(INT2PTR(HWND, perlud->dwData), &msg)) ||
                   (acc && TranslateAccelerator(phwnd, acc, &msg))              ||
                   (fIsDialog && IsDialogMessage(phwnd, &msg)) ) 
              ){
                TranslateMessage(&msg);
                DispatchMessage(&msg);
            }
        }

        FREETMPS;
        LEAVE;
    }

    // Enable parent or all active topwindow
    if (all)
        EnumThreadWindows (GetWindowThreadProcessId(parent, NULL), (WNDENUMPROC) EnableWindowsProc, (LPARAM) TRUE);
    else
        EnableWindow (parent, TRUE);

    // Hide DialogBox
    ShowWindow(handle, SW_HIDE);
    
    // Active parent
    SetActiveWindow(parent);
    // UnSet ISMODAL flag
    perlud = (LPPERLWIN32GUI_USERDATA) GetWindowLongPtr(handle, GWLP_USERDATA);
    if( ValidUserData(perlud))
       perlud->dwPlStyle &= ~PERLWIN32GUI_ISMODAL;

    RETVAL = msg.wParam;
OUTPUT:
    RETVAL

    ###########################################################################
    # (@)METHOD:Scroll(scrollbar,operation[,position, [thumbtrack_flag]])
    # Handles scrollbar scrolling if you don't want to do it yourself. This is
    # most useful in the Scroll event handler for a window or dialog box.
    #
    # B<scrollbar> can be:
    #   SB_HOR(0)  : Horizontal scrollbar
    #   SB_VERT(1) : Vertical scrollbar
    #
    # B<operation> is an identifier for the operation being performed on the
    # scrollbar, this can be:
    #   SB_LINEUP, SB_LINELEFT, SB_LINEDOWN, SB_LINERIGHT, SB_PAGEUP
    #   SB_PAGELEFT, SB_PAGEDOWN, SB_PAGERIGHT, SB_THUMBPOSITION,
    #   SB_THUMBTRACK, SB_TOP, SB_LEFT, SB_BOTTOM, SB_RIGHT, or SB_ENDSCROLL
    #
    # B<position> is ignored unless B<operation> is SB_THUMBPOSITION, or
    # B<operation> is SB_THUMBTRACK and B<thumbtrack_flag> is TRUE. If
    # B<position> is not provided (or provided and equal to -1), then
    # the position used is taken from the internal scrollbar structure:
    # this is the prefered method of operation.
    #
    # B<thumbtrack_flag> indicates whether SB_THUMBTRACK messages are
    # processed (TRUE) or not (FALSE).  It defaults to false.
    #
    # Returns the new position of the scrollbar, or undef on failure.
    #
int
Scroll(handle, scrollbar, operation, position = -1, thumbtrack_flag = 0)
    HWND handle
    int  scrollbar
    int  operation
    int  position
    BOOL thumbtrack_flag
PREINIT:
    SCROLLINFO si;
CODE:
    si.cbSize = sizeof(si);
    si.fMask = SIF_ALL;
    if(GetScrollInfo(handle,scrollbar,&si)) {
        si.fMask = SIF_POS;
        switch(operation) {
            case SB_THUMBTRACK:
                if(!thumbtrack_flag) {
                    /* No tracking */
                    break;
                }
                /* fall through */
            case SB_THUMBPOSITION:
                if(position == -1) {
                    si.nPos = si.nTrackPos;
                }
                else {
                    si.nPos = position;
                }
                break;
            case SB_LINEUP:
                si.nPos--;
                break;
            case SB_LINEDOWN:
                si.nPos++;
                break;
            case SB_PAGEUP:
                si.nPos -= si.nPage;
                break;
            case SB_PAGEDOWN:
                si.nPos += si.nPage;
                break;
            case SB_TOP:
                si.nPos = si.nMin;
                break;
            case SB_BOTTOM:
                si.nPos = si.nMax;
                break;
            default:
                XSRETURN_UNDEF;
                break;
        }
        RETVAL = SetScrollInfo(handle, scrollbar, &si, 1);
    }
    else {
        XSRETURN_UNDEF;
    }
OUTPUT:
    RETVAL


    ###########################################################################
    # (@)METHOD:ScrollRange(scrollbar,[min, max])
    # Sets / Gets range for a window scrollbar (if enabled). 
    # B<scrollbar> argument should be set as follows:
    #   0 : Horizontal scrollbar
    #   1 : Vertical scrollbar
    #
    # Returns the scrollbar range as an array, or undef on failure.
void
ScrollRange(handle, scrollbar,...)
    HWND handle
    int scrollbar
PREINIT:
    SCROLLINFO si;  // We use scrollinfo because SetScrollRange is deprecated.
CODE:
    si.cbSize = sizeof(SCROLLINFO);
    si.fMask = SIF_RANGE;
    if(scrollbar > 1) XSRETURN_UNDEF;
    if(items > 2) {
        si.nMin = (int)SvIV(ST(2));
        si.nMax = (int)SvIV(ST(3));
        SetScrollInfo(handle, scrollbar, &si, 1);
    }
    if(GetScrollInfo(handle,scrollbar,&si)) {
        EXTEND(SP, 2);
        XST_mIV(0, si.nMin);
        XST_mIV(1, si.nMax);
        XSRETURN(2);
    }
    else {
        XSRETURN_UNDEF;
    }

    ###########################################################################
    # (@)METHOD:ScrollPage(scrollbar,[pagesize])
    # Sets / Gets page size of a window scrollbar (if enabled). 
    # B<scrollbar> argument should be set as follows:
    #   0 : Horizontal scrollbar
    #   1 : Vertical scrollbar
    #
    # Returns the scrollbar page size or undef on failure.
DWORD
ScrollPage(handle, scrollbar,...)
    HWND handle
    int scrollbar
PREINIT:
    SCROLLINFO si;
CODE:
    si.cbSize = sizeof(SCROLLINFO);
    if(scrollbar > 1) XSRETURN_UNDEF;
    si.fMask = SIF_PAGE;
    if(items > 2) {
        si.nPage = (UINT)SvIV(ST(2));
        SetScrollInfo(handle, scrollbar, &si, 1);
    }
    if(GetScrollInfo(handle,scrollbar,&si)) {
        RETVAL = si.nPage;
    }
OUTPUT:
    RETVAL

    ###########################################################################
    # (@)METHOD:ScrollPos(scrollbar,[pos])
    # Sets / Gets position of a window scrollbar (if enabled). 
    # B<scrollbar> argument should be set as follows:
    #   0 : Horizontal scrollbar
    #   1 : Vertical scrollbar
    #
    # Returns the scrollbar position or undef on failure.
DWORD
ScrollPos(handle, scrollbar,...)
    HWND handle
    int scrollbar
PREINIT:
    SCROLLINFO si;
CODE:
    si.cbSize = sizeof(SCROLLINFO);
    if(scrollbar > 1) XSRETURN_UNDEF;
    if(items > 2) {
        si.fMask = SIF_POS;
        si.nPos = (int)SvIV(ST(2));
        SetScrollInfo(handle, scrollbar, &si, 1);
    }
    si.fMask = SIF_POS;
    if(GetScrollInfo(handle,scrollbar,&si)) {
        RETVAL = si.nPos;
    }
OUTPUT:
    RETVAL


    ###########################################################################
    # (@)INTERNAL:LoadCursorFromFile(FILENAME)
HCURSOR
LoadCursorFromFile(filename)
    LPCTSTR filename
CODE:
    RETVAL = LoadCursorFromFile(filename);
OUTPUT:
    RETVAL

    ###########################################################################
    # (@)METHOD:LoadCursor(ID)
    #This function loads one of the default cursors. ID can be one of:
    #
    #  32650 IDC_APPSTARTING  Standard arrow and small hourglass
    #  32512 IDC_ARROW        Standard arrow
    #  32515 IDC_CROSS        Crosshair
    #  32649 IDC_HAND         Windows 98/Me, Windows 2000/XP: Hand
    #  32651 IDC_HELP         Arrow and question mark
    #  32513 IDC_IBEAM        I-beam
    #  32641 IDC_ICON         Obsolete for applications marked version 4.0 or later.
    #  32648 IDC_NO           Slashed circle
    #  32640 IDC_SIZE         Obsolete for applications marked version 4.0 or later. Use IDC_SIZEALL.
    #  32646 IDC_SIZEALL      Four-pointed arrow pointing north, south, east, and west
    #  32643 IDC_SIZENESW     Double-pointed arrow pointing northeast and southwest
    #  32645 IDC_SIZENS       Double-pointed arrow pointing north and south
    #  32642 IDC_SIZENWSE     Double-pointed arrow pointing northwest and southeast
    #  32644 IDC_SIZEWE       Double-pointed arrow pointing west and east
    #  32516 IDC_UPARROW      Vertical arrow
    #  32514 IDC_WAIT         Hourglass
    # 
    #On success returns a Win32::GUI::Cursor object, on failure undef.
    #
    #Example:
    #
    #my $hourglass=Win32::GUI::LoadCursor(32514);
    #    
    #NOTE: it is better to use Win32::GUI::Cursor->new(ID);
void
LoadCursor(ID)
    long ID
PREINIT:
    HCURSOR cursor;
PPCODE:
    cursor = LoadCursor(NULL, MAKEINTRESOURCE(ID));
    if (cursor== NULL) XSRETURN_UNDEF;
    XPUSHs(CreateObjectWithHandle(NOTXSCALL "Win32::GUI::Cursor", (HWND) cursor));
    
     ##########################################################################
     # (@)METHOD:LoadString(ID)
     # The LoadString method loads a string resource from the executable file 
     
LPTSTR
LoadString(uID)
    UINT uID
PREINIT:
    char  lpBuffer[256];
    HINSTANCE moduleHandle;
CODE:
    moduleHandle = GetModuleHandle(NULL);
    if(LoadString(moduleHandle,uID,lpBuffer,256)) {
        RETVAL = (LPTSTR)  lpBuffer;
    } else {
        RETVAL = "";
    }
OUTPUT:
    RETVAL
    

    ###########################################################################
    # (@)INTERNAL:LoadImage(FILENAME, [TYPE, X, Y, FLAGS])
    # The return value is a handle to the bitmap, or 0 on failure.
    #
    # Directory seperators are normalised to windows seperators (C<\>).
    # Under Cygwin, cygwin paths are converted to windows paths
HBITMAP
LoadImage(filename,iType=IMAGE_BITMAP,iX=0,iY=0,iFlags=LR_DEFAULTCOLOR)
    SV *filename
    UINT iType
    int iX
    int iY
    UINT iFlags
PREINIT:
    HINSTANCE moduleHandle;
    HBITMAP bitmap = NULL;
    char buffer[MAX_PATH+1];
    char *name;
    int i;
CODE:
    /* Try to find the resource in the current EXE */
    moduleHandle = GetModuleHandle(NULL);

    /* If filename looks like a string, attempt to load from current EXE: */
    if((bitmap ==NULL) && SvPOK(filename) && !(iFlags & LR_LOADFROMFILE)) {
        bitmap = (HBITMAP) LoadImage((HINSTANCE) moduleHandle,
                SvPV_nolen(filename), iType, iX, iY, iFlags);
    }
    
    /* If filename looks like a number, try it as a resource id from the current EXE */
    if((bitmap == NULL) && SvIOK(filename) && !(iFlags & LR_LOADFROMFILE)) {
        bitmap = (HBITMAP) LoadImage((HINSTANCE) moduleHandle,
                MAKEINTRESOURCE(SvIV(filename)), iType, iX, iY, iFlags);
    }

    /* Try to find the resource from GUI.dll */
    moduleHandle = GetModuleHandle("GUI.dll");

    /* If filename looks like a string, try it as a resource name from GUI.dll */
    if((bitmap == NULL) && SvPOK(filename) && !(iFlags & LR_LOADFROMFILE)) {
        bitmap = (HBITMAP) LoadImage((HINSTANCE) moduleHandle,
                SvPV_nolen(filename), iType, iX, iY, iFlags);
    }

    /* If filename looks like a number, try it as a resource id from GUI.dll */
    if((bitmap == NULL) && SvIOK(filename) && !(iFlags & LR_LOADFROMFILE)) {
        bitmap = (HBITMAP) LoadImage((HINSTANCE) moduleHandle,
                MAKEINTRESOURCE(SvIV(filename)), iType, iX, iY, iFlags);
    }

    /* Try to load from file or as an OEM resource */
    moduleHandle = NULL;

    /* if filename looks like a string, try it as a file name */
    if((bitmap == NULL) && SvPOK(filename)) {
        name = SvPV_nolen(filename);
#ifdef __CYGWIN__
        /* Under Cygwin, convert paths to windows
         * paths. E.g. convert /usr/local... and /cygdrive/c/...
         */
#if CYGWIN_VERSION_API_MAJOR > 0 || CYGWIN_VERSION_API_MINOR >= 181
    i = cygwin_conv_path(CCP_POSIX_TO_WIN_A|CCP_RELATIVE,name,buffer,MAX_PATH+1);
    if (i < 0) XSRETURN_UNDEF;
#else
    /* old cygwin api */
    if(cygwin_conv_to_win32_path(name,buffer) != 0)
        XSRETURN_UNDEF;
#endif
#else
        /* LoadImage on Win98 (at least) doesn't like unix
         * path seperators, so normalise to windows path seperators
         */
        for(i=0; *name && (i<MAX_PATH); ++name,++i) {
            buffer[i] = (*name == '/' ? '\\' : *name);
        }
        if(*name) {
            /* XXX Path too long - although this appears to be what
             * LoadImage would return with such a path, it might be
             * better to find a more specific error code.  E.g.
             * ENAMETOOLONG?
             */
            SetLastError(ERROR_FILE_NOT_FOUND);
            errno = ENOENT;
            XSRETURN_UNDEF;
        }
        buffer[i] = 0;
#endif
        bitmap = (HBITMAP) LoadImage((HINSTANCE) moduleHandle,
                buffer, iType, iX, iY, iFlags|LR_LOADFROMFILE);
    }

    /* If filename looks like a number, try it as an OEM resource id */
    if((bitmap == NULL) && SvIOK(filename) && !(iFlags & LR_LOADFROMFILE)) {
        bitmap = (HBITMAP) LoadImage((HINSTANCE) moduleHandle,
                MAKEINTRESOURCE(SvIV(filename)), iType, iX, iY, iFlags);
    }

    /* Finally, if it looks like a number, try it as a pre-defined resource */
    if((bitmap == NULL) && SvIOK(filename)) {
        if(iType == IMAGE_BITMAP) {
            bitmap = (HBITMAP)LoadBitmap(NULL, MAKEINTRESOURCE(SvIV(filename)));
        }
        else if (iType == IMAGE_ICON) {
            bitmap = (HBITMAP)LoadIcon(NULL, MAKEINTRESOURCE(SvIV(filename)));
        }
        else if (iType == IMAGE_CURSOR) {
            bitmap = (HBITMAP)LoadCursor(NULL, MAKEINTRESOURCE(SvIV(filename)));
        }
    }

    RETVAL = bitmap;
OUTPUT:
    RETVAL

    ###########################################################################
    # (@)INTERNAL:DestroyCursor()
BOOL
DestroyCursor(cursor)
    HCURSOR cursor
CODE:
    RETVAL = DestroyCursor(cursor);
OUTPUT:
    RETVAL

    ###########################################################################
    # (@)METHOD:SetCursor(CURSOR)
    # Draws the specified B<CURSOR> (a Win32::GUI::Cursor object). Returns the
    # handle of the previously displayed cursor. Note that the cursor will
    # change back to the default one as soon as the mouse moves or a system
    # command is performed. To change the cursor stablily, use ChangeCursor().
    #
    # see also ChangeCursor()
HCURSOR
SetCursor(cursor)
    HCURSOR cursor
CODE:
    RETVAL = SetCursor(cursor);
OUTPUT:
    RETVAL

    ###########################################################################
    # (@)METHOD:GetCursor()
    # Returns the handle of the current cursor.
HCURSOR
GetCursor()
CODE:
    RETVAL = GetCursor();
OUTPUT:
    RETVAL

    ###########################################################################
    # (@)METHOD:ChangeCursor(CURSOR)
    # Changes the default cursor for a window to B<CURSOR> (a Win32::GUI::Cursor
    # object). Returns the handle of the previous default cursor.
    #
    # see also new Win32::GUI::Cursor
HCURSOR
ChangeCursor(handle, cursor)
    HWND handle
    HCURSOR cursor
CODE:
    RETVAL = (HCURSOR) SetClassLongPtr(handle, GCLP_HCURSOR, (LONG_PTR) cursor);
OUTPUT:
    RETVAL

    ###########################################################################
    # (@)METHOD:GetCursorPos()
    # Gets the absolute mouse cursor position. Returns an array containing
    # x and y co-ordinates.
    #
    # Usage:
    #   ($x, $y) = Win32::GUI::GetCursorPos;
    #
    # See also ScreenToClient()
    # See also SetCursorPos()
void
GetCursorPos()
PREINIT:
    POINT point;
PPCODE:
    if(GetCursorPos(&point)) {
        EXTEND(SP, 2);
        XST_mIV(0, point.x);
        XST_mIV(1, point.y);
        XSRETURN(2);
    } else {
        XSRETURN_UNDEF;
    }

    ###########################################################################
    # (@)METHOD:SetCursorPos(X, Y)
    # Moves the mouse cursor to the specified screen coordinates.
    #
    # see also GetCursorPos()
BOOL
SetCursorPos(x, y)
    int x
    int y
CODE:
    RETVAL = SetCursorPos(x, y);
OUTPUT:
    RETVAL

    ###########################################################################
    # (@)METHOD:ClipCursor([LEFT, TOP, RIGHT, BOTTOM])
    # Confines the cursor to the specified screen rectangle. Call it without
    # parameters to release the cursor. Returns nonzero on success
BOOL
ClipCursor(left=0, top=0, right=0, bottom=0)
    LONG left
    LONG top
    LONG right
    LONG bottom
PREINIT:
    RECT r;
CODE:
    if(items == 0) {
        RETVAL = ClipCursor(NULL);
    } else {
        r.left = left;
        r.top = top;
        r.right = right;
        r.bottom = bottom;
        RETVAL = ClipCursor(&r);
    }
OUTPUT:
    RETVAL

    ###########################################################################
    # (@)METHOD:ChangeIcon(ICON)
    # Changes the default icon for a window to B<ICON> (a Win32::GUI::Icon
    # object). Returns the handle of the previous default icon.
HICON
ChangeIcon(handle, icon)
    HWND handle
    HICON icon
CODE:
    SetClassLongPtr(handle, GCLP_HICONSM, (LONG_PTR) icon);
    RETVAL = (HICON) SetClassLongPtr(handle, GCLP_HICON, (LONG_PTR) icon);
OUTPUT:
    RETVAL


    ###########################################################################
    # (@)METHOD:ChangeSmallIcon(ICON)
    # Changes the default small icon for a window to B<ICON> (a Win32::GUI::Icon
    # object). Returns the handle of the previous default small icon.
HICON
ChangeSmallIcon(handle, icon)
    HWND handle
    HICON icon
CODE:
    RETVAL = (HICON) SetClassLongPtr(handle, GCLP_HICONSM, (LONG_PTR) icon);
OUTPUT:
    RETVAL

    ###########################################################################
    # (@)INTERNAL:DestroyIcon()
BOOL
DestroyIcon(icon)
    HICON icon
CODE:
    RETVAL = DestroyIcon(icon);
OUTPUT:
    RETVAL

    ###########################################################################
    # (@)METHOD:GetClassName()
    # Returns the class name for a window or control.
void
GetClassName(handle)
    HWND handle
PREINIT:
    LPTSTR lpClassName;
    int nMaxCount;
PPCODE:
    nMaxCount = 256;
    lpClassName = (LPTSTR) safemalloc(nMaxCount);
    if(GetClassName(handle, lpClassName, nMaxCount) > 0) {
        EXTEND(SP, 1);
        XST_mPV(0, lpClassName);
        safefree(lpClassName);
        XSRETURN(1);
    } else {
        safefree(lpClassName);
        XSRETURN_NO;
    }

    ###########################################################################
    # (@)METHOD:GetParent()
    # Returns the parent window for this child control/window. If there is no
    # parent window or there has been an error, undef is returned.
void
GetParent(handle)
    HWND handle
PREINIT:
  HWND parentHandle;
  SV* SvParent;
PPCODE:
  parentHandle=GetParent(handle);
  if (parentHandle!=NULL) {
    SvParent = SV_SELF_FROM_WINDOW(parentHandle);
    if (SvParent != NULL && SvROK(SvParent)) {
      XPUSHs(SvParent);
    }
    else {
      XSRETURN_UNDEF;
    }
  } 
  else {
    XSRETURN_UNDEF;
  }

    ###########################################################################
    # (@)INTERNAL:GetWindowObject()
    # Returns the perl window object from a window handle.  If the window handle
    # passed is a handle to a window created by Win32::GUI, returns the perl
    # object reference, else returns undef.
void
GetWindowObject(handle)
    HWND handle
PREINIT:
  SV* SvObject;
PPCODE:
  if (IsWindow(handle)) {
    SvObject = SV_SELF_FROM_WINDOW(handle);
    if (SvObject != NULL && SvROK(SvObject)) {
      XPUSHs(SvObject);
    }
    else {
      XSRETURN_UNDEF;
    }
  } 
  else {
    XSRETURN_UNDEF;
  }
  
    ###########################################################################
    # (@)INTERNAL:_UserData()
    # Return a reference to an HV, stored in the perlud.userData member
    # of the PERLWIN32GUI_USERDATA struct
HV *
_UserData(handle)
    HWND handle
PREINIT:
    LPPERLWIN32GUI_USERDATA perlud;
CODE:
    perlud = (LPPERLWIN32GUI_USERDATA) GetWindowLongPtr(handle, GWLP_USERDATA);
    if( ! ValidUserData(perlud) ) {
        XSRETURN_UNDEF;
    }

    if(perlud->userData == NULL)
        perlud->userData = (SV*)newHV();

    RETVAL = (HV*)perlud->userData;
OUTPUT:
    RETVAL

    ###########################################################################
    # (@)METHOD:FindWindow(CLASSNAME, WINDOWNAME)
    # Returns the handle of the window whose class name and window name match
    # the specified strings; both strings can be empty. Note that the function
    # does not search child windows, only top level windows.
    #
    # If no matching windows is found, the return value is zero.
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


    ###########################################################################
    # (@)METHOD:GetWindowLong(INDEX)
    # Retrieves a windows property; for more info consult the original API
    # documentation.
void
GetWindowLong(handle,index)
    HWND handle
    int index
PPCODE:
    XSRETURN_IV(PTR2IV(GetWindowLongPtr(handle, index)));

    ###########################################################################
    # (@)METHOD:SetWindowLong(INDEX, VALUE)
    # Sets a windows property; for more info consult the original API
    # documentation.
void
SetWindowLong(handle,index,value)
    HWND handle
    int  index
    LONG_PTR value
PPCODE:
    XSRETURN_IV(PTR2IV(SetWindowLongPtr(handle, index, value)));

    ###########################################################################
    # (@)METHOD:SetWindowPos(INSERTAFTER,X,Y,cx,cy,FLAGS)
    # The SetWindowPos function changes the size, position,
    # and Z order of a child, pop-up, or top-level
    # window. Child, pop-up, and top-level windows are
    # ordered according to their appearance on the
    # screen. The topmost window receives the highest rank
    # and is the first window in the Z order.
    #
    # INSERTAFTER - window to precede the positioned window
    # in the Z order. This parameter must be a window object,
    # a window handle or one of the following integer values.
    #   HWND_BOTTOM
    #     Places the window at the bottom of the Z order. If
    #     the WINDOW parameter identifies a topmost window,
    #     the window loses its topmost status and is placed
    #     at the bottom of all other windows.
    #   HWND_NOTOPMOST
    #     Places the window above all non-topmost windows
    #     (that is, behind all topmost windows). This flag
    #     has no effect if the window is already a
    #     non-topmost window.
    #   HWND_TOP
    #     Places the window at the top of the Z order.
    #   HWND_TOPMOST
    #     Places the window above all non-topmost
    #     windows. The window maintains its topmost position
    #     even when it is deactivated.
BOOL
SetWindowPos(handle,insertafter,X,Y,cx,cy,flags)
    HWND handle
    HWND insertafter
    int X
    int Y
    int cx
    int cy
    int flags
CODE:
    RETVAL = SetWindowPos(handle, insertafter, X, Y, cx, cy, flags);
OUTPUT:
    RETVAL


    ###########################################################################
    # (@)METHOD:GetWindow(COMMAND)
    # Returns handle of the window that has the specified
    # relationship (given by B<COMMAND>) with the specified window.
    #
    # Available B<COMMAND> are:
    #   GW_CHILD
    #   GW_HWNDFIRST
    #   GW_HWNDLAST
    #   GW_HWNDNEXT
    #   GW_HWNDPREV
    #   GW_OWNER
    #
    # Example:
    #     $Button->GetWindow(GW_OWNER);
HWND
GetWindow(handle,command)
    HWND handle
    UINT command
CODE:
    RETVAL = GetWindow(handle, command);
OUTPUT:
    RETVAL


    ###########################################################################
    # (@)METHOD:Show([COMMAND=SW_SHOWNORMAL])
    # Shows a window (or change its showing state to B<COMMAND>); 
    #
    # Available B<COMMAND> are:
    #
    #   0  : SW_HIDE
    #   1  : SW_SHOWNORMAL
    #   1  : SW_NORMAL
    #   2  : SW_SHOWMINIMIZED
    #   3  : SW_SHOWMAXIMIZED
    #   3  : SW_MAXIMIZE
    #   4  : SW_SHOWNOACTIVATE
    #   5  : SW_SHOW
    #   6  : SW_MINIMIZE
    #   7  : SW_SHOWMINNOACTIVE
    #   8  : SW_SHOWNA
    #   9  : SW_RESTORE
    #   10 : SW_SHOWDEFAULT
    #   11 : SW_FORCEMINIMIZE
    #   11 : SW_MAX
    #
BOOL
Show(handle,command=SW_SHOWNORMAL)
    HWND handle
    int command
CODE:
    RETVAL = ShowWindow(handle, command);
OUTPUT:
    RETVAL


    ###########################################################################
    # (@)INTERNAL:_Animate(HANDLE, TIME, FLAGS)
    # Wrapper for Win32 AnimateWindow call.  See Win32::GUI::Animate in GUI.pm
    # for more details.
BOOL
_Animate(handle, time, flags)
    HWND handle
    DWORD time
    DWORD flags
CODE:
    RETVAL = AnimateWindow(handle, time, flags);
OUTPUT:
    RETVAL
    

    ###########################################################################
    # (@)METHOD:Hide()
    # Hides a window or control.
BOOL
Hide(handle)
    HWND handle
CODE:
    RETVAL = ShowWindow(handle, SW_HIDE);
OUTPUT:
    RETVAL


    ###########################################################################
    # (@)METHOD:Maximize()
    # Maximizes a window.
BOOL
Maximize(handle)
    HWND handle
CODE:
    RETVAL = ShowWindow(handle, SW_SHOWMAXIMIZED);
OUTPUT:
    RETVAL

    ###########################################################################
    # (@)METHOD:SetWindowRgn(region,flag)
    # The SetWindowRgn method sets the window region of a window. The window region determines the area 
    # within the window where the system permits drawing. The system does not display any portion of a window 
    # that lies outside of the window region 
    #
    # flag : Specifies whether the system redraws the window after setting the window region. If flag is TRUE, 
    # the system does so; otherwise, it does not. 
    # Typically, you set flag to TRUE if the window is visible. 
BOOL
SetWindowRgn(handle, region, flag=1)
    HWND handle
    HRGN region
    BOOL flag
CODE:
    RETVAL = SetWindowRgn(handle, region, flag);
OUTPUT:
    RETVAL

    ###########################################################################
    # (@)METHOD:Update()
    # Repaints a window if it's update region is not empty.
    #
    # see also Redraw()
    # see also InvalidateRect()
BOOL
Update(handle)
    HWND handle
CODE:
    RETVAL = UpdateWindow(handle);
OUTPUT:
    RETVAL

    ###########################################################################
    # (@)METHOD:Redraw()
    # Repaints a window
    #
    # See also Update()
    # See also InvalidateRect()
BOOL
Redraw(handle, ...)
    HWND handle
PREINIT:
    RECT rect;
    LPRECT lpRect;
    UINT flags;
CODE:
    if(items != 2 && items != 6) {
        CROAK("Usage: Redraw(handle, flag);\n   or: Redraw(handle, left, top, right, bottom, flag);\n");
    }
    if(items == 2) {
        lpRect = (LPRECT) NULL;
        flags = (UINT) SvIV(ST(1));
    }
    else {
        rect.left = (LONG)SvIV(ST(1));
        rect.top = (LONG)SvIV(ST(2));
        rect.right = (LONG)SvIV(ST(3));
        rect.bottom = (LONG)SvIV(ST(4));
        flags = (UINT) SvIV(ST(5));
        lpRect = &rect;
    }
    RETVAL = RedrawWindow(handle,lpRect, (HRGN) NULL, flags);
OUTPUT:
    RETVAL

    ###########################################################################
    # (@)METHOD:LockWindowUpdate(flag)
    # The LockWindowUpdate method disables or enables drawing in the specified window. Only one window 
    # can be locked at a time. 
    #
    # If an application with a locked window (or any locked child windows) calls the GetDC function,
    # the called function returns a device context with a visible region that is empty. This will 
    # occur until the application unlocks the window by calling LockWindowUpdate method specifying a 
    # value for the flag.
    # Example:
    # $win->LockWindowUpdate;     #Locks window
    # $win->LockWindowUpdate(1);  #Unlocks window
BOOL
LockWindowUpdate(handle, flag=0)
    HWND handle
    int flag
CODE:
    RETVAL = LockWindowUpdate(flag == 0 ? handle : NULL);
OUTPUT:
    RETVAL
    

    ###########################################################################
    # (@)METHOD:InvalidateRect(...)
    # Forces a refresh of a window, or a rectangle of it. 
    #
    # The parameters can be B<(FLAG)> for the whole area of the window, or B<(LEFT, TOP, RIGHT, BOTTOM,
    # [FLAG])> to specify a rectangle. If the B<FLAG> parameter is set to TRUE, the
    # background is erased before the window is refreshed (this is the default).
    #
    # See also Redraw()
    # See also Update()
BOOL
InvalidateRect(handle, ...)
    HWND handle
PREINIT:
    RECT rect;
    LPRECT lpRect;
    BOOL bErase;
CODE:
    if(items != 2 && items && items != 6) {
        CROAK("Usage: InvalidateRect(handle, flag);\n   or: InvalidateRect(handle, left, top, right, bottom, [flag]);\n");
    }
    if(items == 2) {
        lpRect = (LPRECT) NULL;
        bErase = (BOOL) SvIV(ST(1));
    } else {
        rect.left   = (LONG)SvIV(ST(1));
        rect.top    = (LONG)SvIV(ST(2));
        rect.right  = (LONG)SvIV(ST(3));
        rect.bottom = (LONG)SvIV(ST(4));
        if(items == 5)
            bErase      = TRUE;
        else
            bErase      = (BOOL) SvIV(ST(5));
        lpRect      = &rect;
    }
    RETVAL = InvalidateRect(handle, lpRect, bErase);
OUTPUT:
    RETVAL


    ###########################################################################
    # (@)INTERNAL:DestroyWindow()
BOOL
DestroyWindow(handle)
    HWND handle
CODE:
    RETVAL = DestroyWindow(handle);
OUTPUT:
    RETVAL


    ###########################################################################
    # (@)METHOD:GetMessage([MIN=0, MAX=0])
    # Retrieves a message sent to the window, optionally considering only
    # messages identifiers in the range B<MIN..MAX>. 
    #
    # If a message is found, the function returns a 7 elements array containing:
    #
    #   - the result code of the message
    #   - the message identifier
    #   - the wParam argument
    #   - the lParam argument
    #   - the time when message occurred
    #   - the x coordinate at which message occurred
    #   - the y coordinate at which message occurred
    #
    # If the result code of the message was -1 the function returns undef. Note
    # that this function should not be normally used unless you know very well
    # what you're doing.
void
GetMessage(handle,min=0,max=0)
    HWND handle
    UINT min
    UINT max
PREINIT:
    MSG msg;
    BOOL result;
PPCODE:
    result = GetMessage(&msg, handle, min, max);
    if(result == -1) {
        XSRETURN_UNDEF;
    } else {
        EXTEND(SP, 7);
        XST_mIV(0, result);
        XST_mIV(1, msg.message);
        XST_mIV(2, msg.wParam);
        XST_mIV(3, msg.lParam);
        XST_mIV(4, msg.time);
        XST_mIV(5, msg.pt.x);
        XST_mIV(6, msg.pt.y);
        XSRETURN(7);
    }


    ###########################################################################
    # (@)METHOD:SendMessage(MSG, WPARAM, LPARAM)
    # Sends a message to a window.
LRESULT
SendMessage(handle,msg,wparam,lparam)
    HWND handle
    UINT msg
    WPARAM wparam
    LPARAM lparam
CODE:
    RETVAL = SendMessage(handle, msg, wparam, lparam);
OUTPUT:
    RETVAL

    ###########################################################################
    # (@)METHOD:PostMessage(MSG, WPARAM, LPARAM)
    # Posts a message to a window.
LRESULT
PostMessage(handle,msg,wparam,lparam)
    HWND handle
    UINT msg
    WPARAM wparam
    LPARAM lparam
CODE:
    RETVAL = PostMessage(handle, msg, wparam, lparam);
OUTPUT:
    RETVAL

    ###########################################################################
    # (@)METHOD:WaitMessage()
    # The WaitMessage function yields control to other threads when a thread 
    # has no other messages in its message queue. The WaitMessage function suspends 
    # the thread and does not return until a new message is placed in the thread's 
    # message queue.
BOOL
WaitMessage()
CODE:
  RETVAL = WaitMessage();
OUTPUT:
  RETVAL

    ###########################################################################
    # (@)METHOD:SendMessageTimeout(MSG, WPARAM, LPARAM, [FLAGS=SMTO_NORMAL], TIMEOUT)
    # Sends a message to a window and wait for it to be processed or until the
    # specified B<TIMEOUT> (number of milliseconds) elapses. 
    #
    # Returns the result code of the processed message or undef on errors.
    #
    # If undef is returned and a call to Win32::GetLastError() returns 0,
    # then the window timed out processing the message.
    #
    # The B<FLAGS> parameter is optional, possible values are:
    #  0 : SMTO_NORMAL 
    #      The calling thread can process other requests while waiting; this is the default setting.
    #  1 : SMTO_BLOCK
    #      The calling thread does not process other requests.
    #  2 : SMTO_ABORTIFHUNG
    #      Returns without waiting if the receiving process seems to be "hung".
void
SendMessageTimeout(handle,msg,wparam,lparam,flags=SMTO_NORMAL,timeout)
    HWND handle
    UINT msg
    WPARAM wparam
    LPARAM lparam
    UINT flags
    UINT timeout
PREINIT:
    PDWORD result;
PPCODE:
    if(SendMessageTimeout(handle, msg, wparam, lparam, flags, timeout, (PDWORD_PTR)&result) == 0) {
        XSRETURN_UNDEF;
    } else {
        XSRETURN_IV((IV)result);
    }


    ###########################################################################
    # (@)METHOD:PostQuitMessage([EXITCODE])
    # Sends a quit message to a window, optionally with an B<EXITCODE>;
    # if no B<EXITCODE> is given, it defaults to 0.
void
PostQuitMessage(...)
PPCODE:
    int exitcode;
    if(items > 0)
        exitcode = (int)SvIV(ST(items-1));
    else
        exitcode = 0;
    PostQuitMessage(exitcode);


    ###########################################################################
    # (@)METHOD:PeekMessage([MIN, MAX, MESSAGE])
    # Inspects the window's message queue and eventually returns data
    # about the message it contains; it can optionally check only for message
    # identifiers in the range B<MIN..MAX>; the last B<MESSAGE parameter>, if
    # specified, must be an array reference.
    #
    # If a message is found, the function puts in that array 7 elements
    # containing:
    #   - the handle of the window to which the message is addressed
    #   - the message identifier
    #   - the wParam argument
    #   - the lParam argument
    #   - the time when message occurs
    #   - the x coordinate at which message occurs
    #   - the y coordinate at which message occurs
    #
BOOL
PeekMessage(handle, min=0, max=0, message=&PL_sv_undef)
    HWND handle
    UINT min
    UINT max
    SV* message
PREINIT:
    MSG msg;
CODE:
    ZeroMemory(&msg, sizeof(msg));
    RETVAL = PeekMessage(&msg, handle, min, max, PM_NOREMOVE);
    if(message != &PL_sv_undef) {
        if(SvROK(message) && SvTYPE(SvRV(message)) == SVt_PVAV) {
            av_clear((AV*) SvRV(message));
            av_push((AV*) SvRV(message), newSViv(PTR2IV(msg.hwnd)));
            av_push((AV*) SvRV(message), newSViv(msg.message));
            av_push((AV*) SvRV(message), newSViv(msg.wParam));
            av_push((AV*) SvRV(message), newSViv(msg.lParam));
            av_push((AV*) SvRV(message), newSViv(msg.time));
            av_push((AV*) SvRV(message), newSViv(msg.pt.x));
            av_push((AV*) SvRV(message), newSViv(msg.pt.y));
        } else {
            W32G_WARN("Win32::GUI: fourth parameter to PeekMessage is not an array reference");
        }
    }
OUTPUT:
    RETVAL

    ###########################################################################
    # (@)METHOD:Hook(MSG,CODEREF)
    # Adds a new handler to the list of handlers for a particular window
    # message / command / notification.
    #
    # Hook() can be used with the New Event Model and the Old Event Model. You
    # can Hook() normal window messages, WM_COMMAND codes and WM_NOTIFY codes.
    # You can add as many hooks for one message as you like. To remove hooks
    # see UnHook().
    #
    # Here's an example Perl handler routine:
    #
    #  sub click_handler {
    #     ($object, $wParam, $lParam, $type, $msgcode) = @_;
    #     print "Click handler called!\n";
    #  }
    #
    # Here, $object is the Perl object for the widget, $wParam and $lParam are
    # the parameters received with the message, $type is the type of message
    # (0, WM_NOTIFY or WM_COMMAND, see below), and $msgcode is the original
    # numeric code for the message.
    #
    # If you call Hook() on a child widget, such as a button, the Hook will be
    # called if the parent window receives WM_COMMAND and the code given with
    # WM_COMMAND matches the MSG argument you passed to Hook(). Put simply,
    # what this means is that things like
    #
    #     $button->Hook(BN_CLICKED, \&button_clicked);
    #
    # will work. When your handler is called it will be passed a $type argument
    # of WM_COMMAND (numeric 273).
    #
    # The same is true for WM_NOTIFY messages, although handlers defined for
    # those are passed a $type argument of WM_NOTIFY (numeric 78).
    #
    # Any message that was not WM_NOTIFY or WM_COMMAND gets passed a $type of 0.
    # It is important to check your $type argument. Certain codes for WM_COMMAND
    # messages may conflict with codes for WM_NOTIFY messages or regular window
    # messages, meaning the handler you defined for a particular WM_NOTIFY code
    # may get triggered by a WM_COMMAND code. The $type argument is there to
    # allow you to check this. The rule is to just return immediately if $type
    # is not what you were expecting.
    #
    # If Hook() successfully added a hook for the event, it returns true. If
    # the hook already exists (the coderef you gave is already in the list of
    # hooks for the specified event), or if there was an error in creating the
    # new hook, it returns false.
    #

void
Hook(handle,msg,coderef)
    HWND handle
    I32 msg
    SV* coderef
PREINIT:
    LPPERLWIN32GUI_USERDATA perlud;
    SV** arrayref;
    AV* newarray;
    int i;
    SV** value;
PPCODE:
    if(msg < 0) { msg = 0 - msg; }; // Looks wrong but if hooks are used correctly this should be OK.
    if(SvOK(coderef) && SvROK(coderef) && SvTYPE(SvRV(coderef)) == SVt_PVCV) {
        // We have a code reference.
        perlud = (LPPERLWIN32GUI_USERDATA) GetWindowLongPtr(handle, GWLP_USERDATA);
        if(perlud->avHooks == NULL) {
            perlud->avHooks = newAV();
        }

        // Check if array value for this message exists already:
        arrayref = av_fetch(perlud->avHooks, msg, 0);
        if(arrayref == NULL) {
            // No array reference for this msg yet, so make one and insert our
            // handler ref:
            newarray = newAV();
            av_push(newarray, coderef);
            SvREFCNT_inc(coderef);
            if(av_store(perlud->avHooks, msg, newRV_noinc((SV*) newarray)) == NULL) {
                SvREFCNT_dec((SV*) newarray);
                CROAK("AddHook failed to store new array reference.\n");
                XSRETURN_NO;
            }
        }
        else {
            // There IS an array reference already, so add the handler.
            // First, check the handler isn't already there:
            for(i = 0; i <= (int) av_len((AV*) SvRV(*arrayref)); i++) {
                value = av_fetch((AV*) SvRV(*arrayref), i,0);
                if(sv_eq(*value,coderef)) {
                    XSRETURN_NO;
                }
            }
            // Add the coderef:
            av_push((AV*) SvRV(*arrayref), coderef);
            SvREFCNT_inc(coderef);
        }
        XSRETURN_YES;
    }
    else {
        CROAK("Usage: Hook(message, coderef)\n");
        XSRETURN_NO;
    }

    ###########################################################################
    # (@)METHOD:UnHook(MSG,[CODEREF])
    # Removes a specific code reference from the hooks listing for the given
    # message, or removes all code references for the given message if no
    # coderef is specified.
    #
    # Returns true on success, and false on failure (no such hook).
    #
    # See Hook() documentation for more information on hooks and their
    # usage.
    #

void
UnHook(handle,msg,coderef = NULL)
    HWND handle
    I32 msg
    SV* coderef
PREINIT:
    LPPERLWIN32GUI_USERDATA perlud;
    SV** arrayref;
    SV** removedvalue;
    int i;
    int count = 0;
PPCODE:
    if(msg < 0) { msg = 0 - msg; };
    if(coderef != NULL && !(SvOK(coderef) && SvROK(coderef) && SvTYPE(SvRV(coderef)) == SVt_PVCV)) {
        CROAK("Usage: UnHook(message,[coderef]). What you gave as a coderef was not a code reference\n");
        XSRETURN_NO;
    }
    else {
    perlud = (LPPERLWIN32GUI_USERDATA) GetWindowLongPtr(handle, GWLP_USERDATA);
        if(perlud->avHooks == NULL) {
            XSRETURN_NO;
        }
        else {
            arrayref = av_fetch(perlud->avHooks, msg, 0);
            if(arrayref == NULL) {
            XSRETURN_NO;
        }
            else {
                for(i = 0; i <= (int) av_len((AV*) SvRV(*arrayref)); i++) {
                    removedvalue = av_fetch((AV*) SvRV(*arrayref), i,0);
                    if(removedvalue != NULL && (coderef == NULL || sv_eq(*removedvalue,coderef)) ) {
                        /* SvREFCNT_dec(*removedvalue);
                        av_delete((AV*) SvRV(*arrayref), i, 0); */
                        av_delete((AV*) SvRV(*arrayref), i, G_DISCARD);
                        count++;
                    }
                }
                if(coderef == NULL || av_len((AV*) SvRV(*arrayref)) == -1) {
                    removedvalue = av_fetch(perlud->avHooks, msg, 0);
                    /* SvREFCNT_dec(*removedvalue);
                    av_delete(perlud->avHooks, msg, 0); */
                    av_delete(perlud->avHooks, msg, G_DISCARD);
                }
                XSRETURN_IV(count);
            }
        }
    }

    ###########################################################################
    # (@)METHOD:Result(HANDLE, RESULT)
    # Explicitly set the result to be returned from a handler. For safety and
    # backwards compatibility, results returned from Win32::GUI handlers are
    # discarded. You can use this method (with GREAT CARE) to explicitly force
    # a return value for your handler. Consult the API documentation for valid
    # return values as they vary from message to message.

void
Result(handle, result)
    HWND handle
    int result
PREINIT:
    LPPERLWIN32GUI_USERDATA perlud;
CODE:
    perlud = (LPPERLWIN32GUI_USERDATA) GetWindowLongPtr(handle, GWLP_USERDATA);
    if(ValidUserData(perlud)) {
        perlud->forceResult = (LRESULT) result;
        XSRETURN_YES;
    }
    else
        XSRETURN_NO;


    ###########################################################################
    # (@)METHOD:SetFont(FONT)
    # Sets the font of the window (FONT is a Win32::GUI::Font object).

LRESULT
SetFont(handle, font)
    HWND   handle
    HFONT  font
CODE:
    RETVAL = SendMessage(handle, WM_SETFONT, (WPARAM) font, 0);
OUTPUT:
    RETVAL


    ###########################################################################
    # (@)METHOD:GetFont(FONT)
    # Gets the font of the window (returns an handle; use to get font details).
    #
    #   $Font = $W->GetFont();
    #   %details = Win32::GUI::Font::Info( $Font );

LRESULT
GetFont(handle)
    HWND   handle
CODE:
    RETVAL = SendMessage(handle, WM_GETFONT, 0, 0);
OUTPUT:
    RETVAL


    ###########################################################################
    # (@)METHOD:SetRedraw(FLAG)
    # Determines if a window is automatically redrawn when its content changes.
    #
    # B<FLAG> can be a true value to allow redraw, false to prevent it.

LRESULT
SetRedraw(handle, value)
    HWND   handle
    WPARAM value
CODE:
    RETVAL = SendMessage(handle, WM_SETREDRAW, value, 0);
OUTPUT:
    RETVAL


    ###########################################################################
    # (@)METHOD:SetIcon(ICON, [TYPE])
    # Sets the icon of the window; B<TYPE> can be 0 for the small icon, 1 for
    # the big icon. Default is the same icon for small and big.
LRESULT
SetIcon(handle, icon, type=ICON_SMALL)
    HWND   handle
    HICON  icon
    WPARAM type    
CODE:
    if (items > 2)
        RETVAL = SendMessage(handle, WM_SETICON, type, (LPARAM) icon);
    else {
        SendMessage(handle, WM_SETICON, ICON_SMALL, (LPARAM) icon);
        RETVAL = SendMessage(handle, WM_SETICON, ICON_BIG, (LPARAM) icon);
    }
OUTPUT:
    RETVAL

    ###########################################################################
    # (@)METHOD:Text([TEXT])
    # (@)METHOD:Caption([TEXT])
    # Sets or gets the text associated with a window or control. For example,
    # for windows, this is the text in the titlebar of the window. For button
    # controls, it's the text on the button, and so on. Text() and Caption()
    # are synonymous with oneanother.
void
Text(handle,...)
    HWND handle
ALIAS:
    Win32::GUI::Caption = 1
PREINIT:
    char *myBuffer;
    int myLength;
PPCODE:
    if(items > 2) {
        CROAK("Usage: Text(handle, [value]);\n");
    }
    if(items == 1) {
        myLength = GetWindowTextLength(handle)+1;
        if(myLength) {
            myBuffer = (char *) safemalloc(myLength);
            if(GetWindowText(handle, myBuffer, myLength)) {
                EXTEND(SP, 1);
                XST_mPV(0, myBuffer);
                safefree(myBuffer);
                XSRETURN(1);
            }
            safefree(myBuffer);
        }
        XSRETURN_NO;
    } else {
        XSRETURN_IV((IV) SetWindowText(handle, (LPCTSTR) SvPV_nolen(ST(1))));
    }


    ###########################################################################
    # (@)METHOD:Move(X, Y)
    # Moves a window to the given B<X> and B<Y> co-ordinates.
BOOL
Move(handle,x,y)
    HWND handle
    int x
    int y
CODE:
    RETVAL = SetWindowPos(handle, (HWND) NULL, x, y, 0, 0,
                          SWP_NOZORDER | SWP_NOOWNERZORDER | SWP_NOSIZE);
OUTPUT:
    RETVAL


    ###########################################################################
    # (@)METHOD:Resize(WIDTH, HEIGHT)
    # Resizes a window to the given B<WIDTH> and B<HEIGHT>.
BOOL
Resize(handle,x,y)
    HWND handle
    int x
    int y
CODE:
    RETVAL = SetWindowPos(handle, (HWND) NULL, 0, 0, x, y,
                          SWP_NOZORDER | SWP_NOOWNERZORDER | SWP_NOMOVE);
OUTPUT:
    RETVAL


    ###########################################################################
    # (@)METHOD:GetClientRect()
    # Gets the client area rectangle and returns an array of left, top, right,
    # and bottom co-ordinates if successful. Left and top will always be 0,
    # right and bottom are equivalent to the width and height of the client
    # area.
void
GetClientRect(handle)
    HWND handle
PREINIT:
    RECT myRect;
PPCODE:
    if(GetClientRect(handle, &myRect)) {
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
    # (@)METHOD:GetAbsClientRect()
    # Gets the absolute screen co-ordinates of the client rectangle and returns
    # an array of left, top, right, and bottom co-ordinates.
void
GetAbsClientRect(handle)
    HWND handle
PREINIT:
    WINDOWINFO pwi;
PPCODE:
    pwi.cbSize = sizeof(WINDOWINFO);
    if(GetWindowInfo(handle, &pwi)) {
        EXTEND(SP, 4);
        XST_mIV(0, pwi.rcClient.left);
        XST_mIV(1, pwi.rcClient.top);
        XST_mIV(2, pwi.rcClient.right);
        XST_mIV(3, pwi.rcClient.bottom);
        XSRETURN(4);
    }
    else {
        XSRETURN_UNDEF;
    }

    ###########################################################################
    # (@)METHOD:GetWindowRect()
    # Returns a four elements array defining the windows rectangle (left, top,
    # right, bottom) in screen co-ordinates or undef on errors.
void
GetWindowRect(handle)
    HWND handle
PREINIT:
    RECT myRect;
PPCODE:
    if(GetWindowRect(handle, &myRect)) {
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
    # (@)METHOD:Width([WIDTH])
    # Sets or retrieves the width of a window.
    #
    # See also Resize()
void
Width(handle,...)
    HWND handle
PREINIT:
    RECT myRect;
PPCODE:
    if(items > 2) {
        croak("Usage: Width(handle, [value]);\n");
    }

    if(!GetWindowRect(handle, &myRect)) XSRETURN_NO;

    if(items == 1) {
        EXTEND(SP, 1);
        XST_mIV(0, (myRect.right-myRect.left));
        XSRETURN(1);
    } else {
        if(SetWindowPos(handle, (HWND) NULL, 0, 0,
                        (int) SvIV(ST(1)),
                        (int) (myRect.bottom-myRect.top),
                        SWP_NOZORDER | SWP_NOOWNERZORDER | SWP_NOMOVE | SWP_DEFERERASE)) {
            XSRETURN_YES;
        } else {
            XSRETURN_NO;
        }
    }


    ###########################################################################
    # (@)METHOD:Height([HEIGHT])
    # Sets or retrieves the height of a window.
    #
    # See also Resize()
void
Height(handle,...)
    HWND handle
PREINIT:
    RECT myRect;
PPCODE:
    if(items > 2) {
        croak("Usage: Height(handle, [value]);\n");
    }

    if(!GetWindowRect(handle, &myRect)) XSRETURN_NO;

    if(items == 1) {
        EXTEND(SP, 1);
        XST_mIV(0, (myRect.bottom-myRect.top));
        XSRETURN(1);
    } else {
        if(SetWindowPos(handle, (HWND) NULL, 0, 0,
                        (int) (myRect.right-myRect.left),
                        (int) SvIV(ST(1)),
                        SWP_NOZORDER | SWP_NOOWNERZORDER | SWP_NOMOVE | SWP_DEFERERASE)) {
            XSRETURN_YES;
        } else {
            XSRETURN_NO;
        }
    }


    ###########################################################################
    # (@)METHOD:Left([LEFT])
    # Gets or sets the left co-ordinate of an object, relative to the object's
    # parent if it has one, or absolute screen co-ordinate if it doesn't.
    #
    # See also AbsLeft()
    # See also Move()
void
Left(handle,...)
    HWND handle
PREINIT:
    RECT myRect;
    HWND parent;
    POINT myPt;
PPCODE:
    if(items > 2) {
        croak("Usage: Left(handle, [value]);\n");
    }
    if(!GetWindowRect(handle, &myRect)) XSRETURN_NO;
    myPt.x = myRect.left;
    myPt.y = myRect.top;

    parent = GetParent(handle);
    if (parent && IsChild(parent, handle)) ScreenToClient(parent, &myPt);

    if(items == 1) {
        EXTEND(SP, 1);
        XST_mIV(0, myPt.x);
        XSRETURN(1);
    } else {
        if(SetWindowPos(
            handle, (HWND) NULL,
            (int) SvIV(ST(1)), (int) myPt.y,
            0, 0,
            SWP_NOZORDER | SWP_NOOWNERZORDER | SWP_NOSIZE | SWP_DEFERERASE
        )) {
            XSRETURN_YES;
        } else {
            XSRETURN_NO;
        }
    }


    ###########################################################################
    # (@)METHOD:Top([TOP])
    # Gets or sets the top co-ordinate of an object, relative to the object's
    # parent if it has one, or absolute screen co-ordinate if it doesn't.
    #
    # See also AbsTop()
    # See also Move()
void
Top(handle,...)
    HWND handle
PREINIT:
    RECT myRect;
    HWND parent;
    POINT myPt;
PPCODE:
    if(items > 2) {
        croak("Usage: Top(handle, [value]);\n");
    }
    if(!GetWindowRect(handle, &myRect)) XSRETURN_NO;
    myPt.x = myRect.left;
    myPt.y = myRect.top;

    parent = GetParent(handle);
    if (parent && IsChild(parent, handle)) ScreenToClient(parent, &myPt);

    if(items == 1) {
        EXTEND(SP, 1);
        XST_mIV(0, myPt.y);
        XSRETURN(1);
    } else {
        if(SetWindowPos(
            handle, (HWND) NULL,
            (int) myPt.x, (int) SvIV(ST(1)),
            0, 0,
            SWP_NOZORDER | SWP_NOOWNERZORDER | SWP_NOSIZE | SWP_DEFERERASE
        )) {
            XSRETURN_YES;
        } else {
            XSRETURN_NO;
        }
    }

    ###########################################################################
    # (@)METHOD:AbsLeft([LEFT])
    # Gets or sets the absolute left (screen) co-ordinate of a window.
    #
    # See also Left()
    # See also Move()
void
AbsLeft(handle,...)
    HWND handle
PREINIT:
    RECT myRect;
    HWND parent;
PPCODE:
    if(!GetWindowRect(handle, &myRect)) {
        XSRETURN_UNDEF;
    }

    /* Set */
    if(items > 1) {
        myRect.left = (LONG)SvIV(ST(1));

        /* If we're a child window convert to parent's client co-ordinates */
        if(parent = GetAncestor(handle, GA_PARENT)) {
            ScreenToClient(parent, (LPPOINT)&myRect);
        }

        if(SetWindowPos(handle, NULL, (int)myRect.left, (int)myRect.top,
                         0, 0, SWP_NOZORDER | SWP_NOSIZE)) {
            XSRETURN_YES;
        }
        else {
            XSRETURN_NO;
        }
    }

    /* Get */
    EXTEND(SP, 1);
    XST_mIV(0, myRect.left);
    XSRETURN(1);

    ###########################################################################
    # (@)METHOD:AbsTop([TOP])
    # Gets or sets the absolute top (screen) co-ordinate of a window.
    #
    # See also Top()
    # See also Move()
void
AbsTop(handle,...)
    HWND handle
PREINIT:
    RECT myRect;
    HWND parent;
PPCODE:
    if(!GetWindowRect(handle, &myRect)) {
        XSRETURN_UNDEF;
    }

    /* Set */
    if(items > 1) {
        myRect.top = (LONG)SvIV(ST(1));

        /* If we're a child window convert to parent's client co-ordinates */
        if(parent = GetAncestor(handle, GA_PARENT)) {
            ScreenToClient(parent, (LPPOINT)&myRect);
        }

        if(SetWindowPos(handle, NULL, (int)myRect.left, (int)myRect.top,
                         0, 0, SWP_NOZORDER | SWP_NOSIZE)) {
            XSRETURN_YES;
        }
        else {
            XSRETURN_NO;
        }
    }

    /* Get */
    EXTEND(SP, 1);
    XST_mIV(0, myRect.top);
    XSRETURN(1);

    ###########################################################################
    # (@)METHOD:ScreenToClient(X, Y)
    # Converts screen co-ordinates to client-area co-ordinates.
void
ScreenToClient(handle,x,y)
    HWND handle
    int x
    int y
PREINIT:
    POINT myPt;
PPCODE:
    myPt.x = x;
    myPt.y = y;
    ScreenToClient(handle, &myPt);
    EXTEND(SP, 2);
    XST_mIV(0, myPt.x);
    XST_mIV(1, myPt.y);
    XSRETURN(2);


    ###########################################################################
    # (@)METHOD:ClientToScreen(X, Y)
    # Converts client-area co-ordinates to screen co-ordinates.
void
ClientToScreen(handle,x,y)
    HWND handle
    int x
    int y
PREINIT:
    POINT myPt;
PPCODE:
    myPt.x = x;
    myPt.y = y;
    ClientToScreen(handle, &myPt);
    EXTEND(SP, 2);
    XST_mIV(0, myPt.x);
    XST_mIV(1, myPt.y);
    XSRETURN(2);
    
    ###########################################################################
    # (@)METHOD:ScaleWidth()
    # Returns the windows client area width.
DWORD
ScaleWidth(handle)
    HWND handle
PREINIT:
    RECT myRect;
CODE:
    if(GetClientRect(handle, &myRect)) {
        RETVAL = myRect.right;
    } else {
        RETVAL = 0;
    }
OUTPUT:
    RETVAL


    ###########################################################################
    # (@)METHOD:ScaleHeight()
    # Returns the windows client area height.
DWORD
ScaleHeight(handle)
    HWND handle
PREINIT:
    RECT myRect;
CODE:
    if(GetClientRect(handle, &myRect)) {
        RETVAL = myRect.bottom;
    } else {
        RETVAL = 0;
    }
OUTPUT:
    RETVAL


    ###########################################################################
    # (@)METHOD:BringWindowToTop()
    # Brings a window to the foreground (on top of other windows). This does
    # not make the window "always on top". If the window is already on top,
    # it is activated. If the window is a child window, the top-level
    # parent window associated with the child window is activated.
BOOL
BringWindowToTop(handle)
    HWND handle
CODE:
    RETVAL = BringWindowToTop(handle);
OUTPUT:
    RETVAL


    ###########################################################################
    # (@)METHOD:ArrangeIconicWindows()
    # Arranges all the minimized child windows of the specified parent window.
UINT
ArrangeIconicWindows(handle)
    HWND handle
CODE:
    RETVAL = ArrangeIconicWindows(handle);
OUTPUT:
    RETVAL


    ###########################################################################
    # (@)METHOD:GetDesktopWindow()
    # Returns the handle of the desktop window.
HWND
GetDesktopWindow(...)
CODE:
   RETVAL = GetDesktopWindow();
OUTPUT:
   RETVAL


    ###########################################################################
    # (@)METHOD:GetForegroundWindow()
    # Returns the handle of the foreground window.
HWND
GetForegroundWindow(...)
CODE:
   RETVAL = GetForegroundWindow();
OUTPUT:
   RETVAL


    ###########################################################################
    # (@)METHOD:SetForegroundWindow()
    # Brings the window to the foreground.
BOOL
SetForegroundWindow(handle)
    HWND handle
CODE:
    RETVAL = SetForegroundWindow(handle);
OUTPUT:
    RETVAL


    ###########################################################################
    # (@)METHOD:IsZoomed()
    # Returns TRUE if the window is maximized, FALSE otherwise.
BOOL
IsZoomed(handle)
    HWND handle
CODE:
    RETVAL = IsZoomed(handle);
OUTPUT:
    RETVAL


    ###########################################################################
    # (@)METHOD:IsIconic()
    # Returns TRUE if the window is minimized, FALSE otherwise.
BOOL
IsIconic(handle)
    HWND handle
CODE:
    RETVAL = IsIconic(handle);
OUTPUT:
    RETVAL


    ###########################################################################
    # (@)METHOD:IsWindow()
    # Returns TRUE if the window is a window, FALSE otherwise.
BOOL
IsWindow(handle)
    HWND handle
CODE:
    RETVAL = IsWindow(handle);
OUTPUT:
    RETVAL


    ###########################################################################
    # (@)METHOD:IsVisible()
    # Returns TRUE if the window is visible, FALSE otherwise.
BOOL
IsVisible(handle)
    HWND handle
CODE:
    RETVAL = IsWindowVisible(handle);
OUTPUT:
    RETVAL


    ###########################################################################
    # (@)METHOD:IsEnabled()
    # Returns TRUE if the window is enabled, FALSE otherwise.
BOOL
IsEnabled(handle)
    HWND handle
CODE:
    RETVAL = IsWindowEnabled(handle);
OUTPUT:
    RETVAL


    ###########################################################################
    # (@)METHOD:Enable([FLAG])
    # Enables (or disables) a window or control. Controls do not accept input
    # when they are disabled.
    #
    # B<FLAG> should be 0 to disable the control (the same as calling Disable() on
    # a control), or 1 to enable it.
    #
    # See also Disable()
BOOL
Enable(handle,flag=TRUE)
    HWND handle
    BOOL flag
CODE:
    RETVAL = EnableWindow(handle, flag);
OUTPUT:
    RETVAL


    ###########################################################################
    # (@)METHOD:Disable()
    # Disables a window or control. Disabled widgets cannot be interacted with,
    # and often change appearance to indicate that they are disabled. This is
    # the same as Enable(0).
    #
    # See also Enable()
BOOL
Disable(handle)
    HWND handle
CODE:
    RETVAL = EnableWindow(handle, FALSE);
OUTPUT:
    RETVAL


    ###########################################################################
    # (@)METHOD:OpenIcon()
    # (@)METHOD:Restore()
    # Restores a minimized window.
BOOL
OpenIcon(handle)
    HWND handle
ALIAS:
    Win32::GUI::Restore = 1
CODE:
    RETVAL = OpenIcon(handle);
OUTPUT:
    RETVAL


    ###########################################################################
    # (@)METHOD:CloseWindow()
    # (@)METHOD:Minimize()
    # Minimizes a window.
BOOL
CloseWindow(handle)
    HWND handle
ALIAS:
    Win32::GUI::Minimize = 1
CODE:
    RETVAL = CloseWindow(handle);
OUTPUT:
    RETVAL


    ###########################################################################
    # (@)METHOD:WindowFromPoint(X, Y)
    # Returns the handle of the window at the specified screen position.
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


    ###########################################################################
    # (@)METHOD:GetTopWindow()
    # Returns the handle of the foreground window.
HWND
GetTopWindow(handle)
    HWND handle
CODE:
    RETVAL = GetTopWindow(handle);
OUTPUT:
    RETVAL


    ###########################################################################
    # (@)METHOD:GetActiveWindow()
    # Returns the handle of the active window.
HWND
GetActiveWindow(...)
CODE:
    RETVAL = GetActiveWindow();
OUTPUT:
    RETVAL

    ###########################################################################
    # (@)METHOD:SetActiveWindow()
    # Activates a window.
    # Returns the handle of the previously active window or 0.
HWND
SetActiveWindow(handle)
    HWND handle
CODE:
    RETVAL = SetActiveWindow(handle);
OUTPUT:
    RETVAL

    ###########################################################################
    # (@)METHOD:GetDlgItem(ID)
    # Returns the handle of a control in the dialog box given its B<ID>.
HWND
GetDlgItem(handle,identifier)
    HWND handle
    int identifier
CODE:
    RETVAL = GetDlgItem(handle, identifier);
OUTPUT:
    RETVAL


    ###########################################################################
    # (@)METHOD:GetFocus()
    # Returns the handle of the window that has the keyboard focus.
HWND
GetFocus(...)
CODE:
    RETVAL = GetFocus();
OUTPUT:
    RETVAL


    ###########################################################################
    # (@)METHOD:SetFocus()
    # Set focus to a window.
HWND
SetFocus(handle)
    HWND handle
CODE:
    RETVAL = SetFocus(handle);
OUTPUT:
    RETVAL


    ###########################################################################
    # (@)METHOD:SetCapture()
    # Assigns the mouse capture to a window.
HWND
SetCapture(handle)
    HWND handle
CODE:
    RETVAL = SetCapture(handle);
OUTPUT:
    RETVAL


    ###########################################################################
    # (@)METHOD:GetCapture()
    # Returns the handle of the window that has the captured the mouse. 
    # If no window has captured the mouse zero is returned.
HWND
GetCapture()
CODE:
    RETVAL = GetCapture();
OUTPUT:
    RETVAL
    
    ###########################################################################
    # (@)METHOD:ReleaseCapture()
    # Releases the mouse capture.
BOOL
ReleaseCapture(...)
CODE:
    RETVAL = ReleaseCapture();
OUTPUT:
    RETVAL

    ###########################################################################
    # (@)METHOD:ShellExecute(window,operation,file,parameters,directory,showcmd)
    #
    # Performs an operation on a file.
    #
    # B<Operation>. A string that specifies the action to be performed. The set of available action verbs depends
    # on the particular file or folder. Generally, the actions available from an object's shortcut menu are
    # available verbs. 
    #   edit     - Launches an editor and opens the document for editing. If File is not a document file,
    #              the function will fail.
    #   explore  - Explores the folder specified by File.
    #   find     - Initiates a search starting from the specified directory.
    #   open     - Opens the file specified by the File parameter. The file can be an executable file,
    #              a document file, or a folder.
    #   print    - Prints the document file specified by lpFile. If lpFile is not a document file,
    #              the function will fail.
    #   ""(NULL) - For systems prior to Microsoft Windows 2000, the default verb is used if it is valid
    #              and available in the registry. If not, the "open" verb is used. For Windows 2000 and
    #              later systems, the default verb is used if available. If not, the "open" verb is used.
    #              If neither verb is available, the system uses the first verb listed in the registry.
    #
    # B<File>. A string that specifies the file or object on which to execute the specified verb. To specify
    # a Shell namespace object, pass the fully qualified parse name. Note that not all verbs are supported on
    # all objects. For example, not all document types support the "print" verb.
    #
    # B<Parameters>. If the File parameter specifies an executable file, Parameters is a string that specifies
    # the parameters to be passed to the application. The format of this string is determined by the verb that
    # is to be invoked. If File specifies a document file, Parameters should be NULL.
    #
    # B<Directory>. A string that specifies the default directory.
    #
    # B<ShowCmd>. Flags that speciow an application is to be displayed when it is opened. If File specifies a
    # document file, the flag is simply passed to the associated application. It is up to the application to
    # decide how to handle it.   
    #
    #   0  SW_HIDE            Hides the window and activates another window.
    #   3  SW_MAXIMIZE        Maximizes the specified window.
    #   6  SW_MINIMIZE        Minimizes the specified window and activates the next top-level window in the z-order.
    #   9  SW_RESTORE         Activates and displays the window. If the window is minimized or maximized,
    #                         Windows restores it to its original size and position. An application should specify
    #                         this flag when restoring a minimized window.
    #   5  SW_SHOW            Activates the window and displays it in its current size and position.
    #   10 SW_SHOWDEFAULT     Sets the show state based on the SW_ flag specified in the STARTUPINFO structure
    #                         passed to the CreateProcess function by the program that started the application.
    #                         An application should call ShowWindow with this flag to set the initial show state of
    #                         its main window.
    #   2  SW_SHOWMINIMIZED   Activates the window and displays it as a minimized window.
    #   7  SW_SHOWMINNOACTIVE Displays the window as a minimized window. The active window remains active.
    #   8  SW_SHOWNA          Displays the window in its current state. The active window remains active.
    #   4  SW_SHOWNOACTIVATE  Displays a window in its most recent size and position. The active window remains active.
    #   1  SW_SHOWNORMAL      Activates and displays a window. If the window is minimized or maximized, Windows
    #                         restores it to its original size and position. An application should specify this flag
    #                         when displaying the window for the first time.
    #
    # Returns a value greater than 32 if successful, or an error value that is less than or equal to 32 otherwise.
    # The following table lists the error values. 
    #
    #   0  The operating system is out of memory or resources. 
    #   3  ERROR_PATH_NOT_FOUND   The specified path was not found. 
    #   11 ERROR_BAD_FORMAT       The .exe file is invalid (non-Microsoft Win32 .exe or error in .exe image). 
    #   5  SE_ERR_ACCESSDENIED    The operating system denied access to the specified file. 
    #   27 SE_ERR_ASSOCINCOMPLETE The file name association is incomplete or invalid. 
    #   30 SE_ERR_DDEBUSY         The Dynamic Data Exchange (DDE) transaction could not be completed because
    #                             other DDE transactions were being processed. 
    #   29 SE_ERR_DDEFAIL         The DDE transaction failed. 
    #   28 SE_ERR_DDETIMEOUT      The DDE transaction could not be completed because the request timed out. 
    #   32 SE_ERR_DLLNOTFOUND     The specified dynamic-link library (DLL) was not found. 
    #   2  SE_ERR_FNF             The specified file was not found. 
    #   31 SE_ERR_NOASSOC         There is no application associated with the given file name extension. This
    #                             error will also be returned if you attempt to print a file that is not printable. 
    #   8  SE_ERR_OOM             There was not enough memory to complete the operation. 
    #   3  SE_ERR_PNF             The specified path was not found. 
    #   26 SE_ERR_SHARE           A sharing violation occurred. 
    #
    # Examples:
    #
    # Open a web page in the default browser
    #   my $exitval = $win->ShellExecute('open','http://www.perl.org','','',1);
    #
    # Open a text file in nodepad
    #   my $exitval = $win->ShellExecute('open','notepad.exe','readme.txt','',1) ;
IV
ShellExecute(window,operation,file,parameters,directory,showcmd)
    HWND window
    LPCTSTR operation
    LPCTSTR file
    LPCTSTR parameters
    LPCTSTR directory
    INT showcmd
CODE:
    RETVAL = (IV) ShellExecute(window,operation,file,parameters,directory,showcmd);
OUTPUT:
    RETVAL
    
    ###########################################################################
    # (@)METHOD:GetWindowThreadProcessId()
    # Returns a two elements array containing the thread and the process
    # identifier for the specified window.
void
GetWindowThreadProcessId(handle)
    HWND handle
PREINIT:
    DWORD tid;
    DWORD pid;
PPCODE:
    tid = GetWindowThreadProcessId(handle, &pid);
    EXTEND(SP, 2);
    XST_mIV(0, tid);
    XST_mIV(1, pid);
    XSRETURN(2);


    ###########################################################################
    # (@)METHOD:AttachThreadInput(FROM, TO, [FLAG])
    # If you have multiple windows running in different threads, this function
    # allows you to attach one thread's input processor to a different thread.
    #
    # For example, you can redirect thread A's input to thread B, and then
    # call SetFocus on an object running in thread B to set the keyboard focus
    # to that object. You would not normally be able to do this.
    #
    # B<FROM> and B<TO> should be thread IDs. B<FLAG> should be non-zero to attach the
    # threads (the default operation if B<FLAG> is not specified), or zero to
    # detach the threads.
    #
    # see also GetWindowThreadProcessId()
BOOL
AttachThreadInput(from,to,flag=TRUE)
    DWORD from
    DWORD to
    BOOL flag
CODE:
    RETVAL = AttachThreadInput(from, to, flag);
OUTPUT:
    RETVAL


    ###########################################################################
    # (@)METHOD:GetTextExtentPoint32(STRING, [FONT])
    # Returns a two elements array containing the x and y size of the
    # specified B<STRING> in the window (eventually with the speficied B<FONT>), or
    # undef on errors.
void
GetTextExtentPoint32(handle,string,font=NULL)
    HWND handle
    char * string
    HFONT font
PREINIT:
    STRLEN cbString;
    char *szString;
    HDC hdc;
    SIZE mySize;
PPCODE:
    szString = SvPV(ST(1), cbString);
    hdc = GetDC(handle);
#ifdef PERLWIN32GUI_DEBUG
    printf("XS(GetTextExtentPoint32).font=0x%x\n", font);
    printf("XS(GetTextExtentPoint32).string='%s'\n", string);
#endif
    if(font) SelectObject(hdc, (HGDIOBJ) font);
    if(GetTextExtentPoint32(hdc, szString, (int)cbString, &mySize)) {
        EXTEND(SP, 2);
        XST_mIV(0, mySize.cx);
        XST_mIV(1, mySize.cy);
        ReleaseDC(handle, hdc);
        XSRETURN(2);
    } else {
        ReleaseDC(handle, hdc);
        XSRETURN_UNDEF;
    }


    ###########################################################################
    # (@)METHOD:TrackPopupMenu(MENU [, X, Y [, LEFT, TOP, RIGHT, BOTTOM] [, FLAGS [, CODEREF]]])
    # Displays the menu B<MENU> at the specified co-ordinates (X,Y) and tracks the
    # selection of items on the menu. X and Y are absolute screen co-ordinates.
    #
    # If X and Y are not provided, uses the current cursor position.
    #
    # If LEFT, TOP, RIGHT and BOTTOM are provided they describe a rectangle in absolute screen
    # co-ordinates over which the menu will not be drawn (the excluded rectangle).
    #
    # The following flags can be set (combine flags with bitwise OR (|) )
    #   0x0000 TPM_LEFTBUTTON      Menu items can only be selected with left mouse button
    #   0x0002 TPM_RIGHTBUTTON     Menu items can be selected with either left or right mouse button
    #   0x0000 TPM_LEFTALIGN       Menu is aligned to the left of the given X co-ordinate
    #   0x0004 TPM_CENTERALIGN     Menu is centered on the given X co-ordinate
    #   0x0008 TPM_RIGHTALIGN      Menu is aligned to the right of the given X co-ordinate
    #   0x0000 TPM_TOPALIGN        Menu is aligned above the given Y co-ordinate
    #   0x0010 TPM_VCENTERALIGN    Menu is centered on the given Y co-ordinate
    #   0x0020 TPM_BOTTOMALIGN     Menu is aligned below the given Y co-ordinate
    #   0x0100 TPM_RETURNCMD       TrackPopupMenu returns the selected menu item identifier in the return value
    #   0x0400 TPM_HORPOSANIMATION Menu will be animated from left to right (ignored if menu fading is on)
    #   0x0800 TPM_HORNEGANIMATION Menu will be animated from right to left (ignored if menu fading is on)
    #   0x1000 TPM_VERPOSANIMATION Menu will be animated from top to bottom (ignored if menu fading is on)
    #   0x2000 TPM_VERNEGANIMATION Menu will be animated from bottom to top (ignored if menu fading is on)
    #   0x4000 TPM_NOANIMATION     Menu will not be animated and will not "fade" in and out even if menu
    #                              fading is enabled
    #   0x0001 TPM_RECURSE         Allows you to display a menu when another menu is already displayed.
    #                              This is intended to support context menus within a menu. (Windows 2000/XP only)
    #
    # The default flags are C<TPM_LEFTALIGN | TPM_TOPALIGN | TPM_LEFTBUTTON>
    #
    # If an excluded rectangle is spefified then the following flags may also be used, and TPM_VERTICAL is added to
    # the default flags:
    #   0x0000 TPM_HORIZONTAL      If the menu cannot be shown at the specified location without overlapping
    #                              the excluded rectangle, the system tries to accommodate the requested
    #                              horizontal alignment before the requested vertical alignment.
    #   0x0040 TPM_VERTICAL        If the menu cannot be shown at the specified location without overlapping
    #                              the excluded rectangle, the system tries to accommodate the requested
    #                              vertical alignment before the requested horizontal alignment.
    #
    # If you specify C<TPM_RETURNCMD>, then the menu item ID of the selected item is returned. If an error
    # occurs or the user does not select an item, zero is returned.
    # If you do not specify C<TPM_RETURNCMD>, the return value will be nonzero on success or zero on failure.
    #
    # If B<CODEREF> is provided, then it is a code reference to a callback procedure that will be called for windows
    # events that occur while the menu is displayed (normally such events are not available, as TrackPopupMenu has
    # its own internal event loop).  The callback will recieve a reference to the Win32::GUI object used to call
    # TrackPopupMenu on, and the message code, wParam and lParam of the event that occured. The callback should
    # return nothing or 1 to allow the event to be processed normally, or 0 to prevent the event being passed to the
    # default event handler.  See MSDN documentation for SetWindowsHookEx with idHook set to WH_MSGFILTER for
    # the full gore.
    #
    # The callback prototype is:
    #
    #     sub callback {
    #         my ($self, $message, $wParam, $lParam) = @_;
    #
    #         # Process messages you are interested in
    #         
    #         return;
    #     }
    #

BOOL
TrackPopupMenu(handle,hmenu, ... )
    HWND handle
    HMENU hmenu
PREINIT:
    int x = 0;
    int y = 0;
    UINT flags = TPM_LEFTALIGN|TPM_TOPALIGN|TPM_LEFTBUTTON;
    LPTPMPARAMS lptpm = (LPTPMPARAMS) NULL;
    TPMPARAMS tpm;
    SV* coderef = (SV*) NULL;
    HHOOK hhook = NULL;
    LPPERLWIN32GUI_USERDATA perlud;
    AV* newarray;
    POINT pt;
CODE:

    switch (items) {
      case 10: coderef              = ST(9);
      case  9: flags                = (UINT)SvIV(ST(8));
      case  8: tpm.rcExclude.bottom = (LONG)SvIV(ST(7));
               tpm.rcExclude.right  = (LONG)SvIV(ST(6));
               tpm.rcExclude.top    = (LONG)SvIV(ST(5));
               tpm.rcExclude.left   = (LONG)SvIV(ST(4));
               tpm.cbSize           = sizeof(TPMPARAMS);
               y                    = (int)SvIV(ST(3));
               x                    = (int)SvIV(ST(2));
           break;

      case  6: coderef              = ST(5);
      case  5: flags                = (UINT)SvIV(ST(4));
      case  4: y                    = (int)SvIV(ST(3));
               x                    = (int)SvIV(ST(2));
           break;

      case  2: if(GetCursorPos(&pt)) {
               y                  = pt.y;
               x                  = pt.x;
             }
          break;

      default:
        CROAK("Usage: TrackPopupMenu(handle, menu, [x, y, [left, top, right, bottom], [flag, [coderef]]])\n");
      break;
    }

    // if given a coderef, check that it actually is one
    if(coderef != NULL && !(SvOK(coderef) && SvROK(coderef) && SvTYPE(SvRV(coderef)) == SVt_PVCV)) {
      W32G_WARN("TrackPopupMenu argument 'coderef' must be a code reference - callback not applied");
      coderef = NULL;  // don't set up the hook
    }

    // if we have a coderef, then store it temporarily in the hooks array so that we can access
    // it in the callback, and if successful, register the callback hook handler
    if(coderef != NULL) {

      perlud = (LPPERLWIN32GUI_USERDATA) GetWindowLongPtr(handle, GWLP_USERDATA);
      if(ValidUserData(perlud)) {
        if(perlud->avHooks == NULL) {
          perlud->avHooks = newAV();
        }

        // Check if there is already a handler for this message (there shouldn't be)
        if(av_fetch(perlud->avHooks, WM_TRACKPOPUP_MSGHOOK, 0) == NULL) {
          // No array reference for this msg yet, so make one and insert our
          // handler ref:
          newarray = newAV();
          av_push(newarray, coderef);
          SvREFCNT_inc(coderef);  // needed so that the ref count remains the same after we free
          if(av_store(perlud->avHooks, WM_TRACKPOPUP_MSGHOOK, newRV_noinc((SV*) newarray)) == NULL) {
            // Failed to store new array
            SvREFCNT_dec((SV*) newarray);
            W32G_WARN("TrackPopupMenu failed to store 'coderef' - callback not applied");
            coderef = NULL;  // don't set up the hook
          }
        }
        else {
          // there's an existing hook for the message value we've chosen to use.
          // this means someone called hook() with the message code 0xBFFF !!
          W32G_WARN("TrackPopupMenu found an existing 'coderef' - callback not applied");
          coderef = NULL;  // don't set up the hook
        }
      }
      else {
        coderef = NULL;  // don't set up the hook
      }

      // only set up the hook if we installed the callback
      if(coderef != NULL) {
        hhook = SetWindowsHookEx(WH_MSGFILTER, (HOOKPROC)WindowsHookMsgProc, (HINSTANCE)NULL, GetWindowThreadProcessId(handle, (LPDWORD)NULL));
      }
    }

    // Display the menu
    SetForegroundWindow(handle);
    RETVAL = TrackPopupMenuEx(hmenu, flags, x, y, handle, lptpm);
    SetForegroundWindow(handle);

    if(coderef != NULL) {
      if(hhook != NULL) {
        UnhookWindowsHookEx(hhook); // release the windows hook
      }
      // remove the temporary value stored in the hooks array
      av_delete(perlud->avHooks, WM_TRACKPOPUP_MSGHOOK, G_DISCARD);
    }
OUTPUT:
    RETVAL


    ###########################################################################
    # (@)INTERNAL:SetTimer(HANDLE, ID, ELAPSE)
UINT_PTR
SetTimer(handle,id,elapse)
    HWND handle
    UINT_PTR id
    UINT elapse
CODE:
    RETVAL = SetTimer(handle, id, elapse, NULL);
OUTPUT:
    RETVAL


    ###########################################################################
    # (@)INTERNAL:KillTimer(HANDLE, ID)
UINT
KillTimer(handle,id)
    HWND handle
    UINT_PTR id
CODE:
    RETVAL = KillTimer(handle, id);
OUTPUT:
    RETVAL

    ###########################################################################
    # (@)METHOD:GetEffectiveClientRect(HANDLE, @CONTROLS)
    # Returns the left, top, right and bottom co-ordinates of a rectangle that
    # can accommodate all the controls specified. The elements of B<@CONTROLS>
    # should be control identifiers.
void
GetEffectiveClientRect(handle,...)
    HWND handle
PREINIT:
    LPINT controls;
    int i, c;
    RECT r;
PPCODE:
    c = 0;
    controls = (LPINT) safemalloc(sizeof(INT)*items*2);
    for(i=1;i<items;i++) {
        controls[c++] = 1;
        controls[c++] = (INT) SvIV(ST(i));
    }
    controls[c++] = 0;
    controls[c++] = 0;
    GetEffectiveClientRect(handle, &r, controls);
    EXTEND(SP, 4);
    XST_mIV(0, r.left);
    XST_mIV(1, r.top);
    XST_mIV(2, r.right);
    XST_mIV(3, r.bottom);
    XSRETURN(4);


    ###########################################################################
    # (@)METHOD:DialogUI(HANDLE, [FLAG])
    # Gets or sets whether a window accepts dialog-box style input (tab between
    # fields, accelerator keys etc). B<FLAG> should be 1 to enable this functionality,
    # or 0 to disable it.
    #
    # See also new Win32::GUI::DialogBox()
void
DialogUI(handle,...)
    HWND handle
PREINIT:
    LPPERLWIN32GUI_USERDATA perlud;
PPCODE:
    if(items > 2) {
        CROAK("Usage: DialogUI(handle, [value]);\n");
    }

    perlud = (LPPERLWIN32GUI_USERDATA) GetWindowLongPtr(handle, GWLP_USERDATA);
    if( ! ValidUserData(perlud) ) {
        XSRETURN_UNDEF;
    } else {
        if(items == 1) {
            XSRETURN_IV( (IV) perlud->dwPlStyle & PERLWIN32GUI_DIALOGUI );
        } else {
            SwitchBit(perlud->dwPlStyle, PERLWIN32GUI_DIALOGUI, SvIV(ST(1)));
            XSRETURN_IV( (IV) perlud->dwPlStyle & PERLWIN32GUI_DIALOGUI );
        }
    }


    ###########################################################################
    # (@)METHOD:TrackMouse([TIMEOUT=HOVER_DEFAULT, EVENTS=TME_HOVER|TME_LEAVE])
    # Causes the window to receive messages when the mouse pointer leaves a
    # window or hovers over a window for a specified amount of time (B<TIMEOUT>, in
    # milliseconds).
    #
    # B<EVENTS> can be set to one or more of the following values (ORed together):
    #
    #  0x0001 TME_HOVER     Makes the window receive WM_MOUSEHOVER messages when the mouse hovers over it.
    #  0x0002 TME_LEAVE     Makes the window receive a WM_MOUSELEAVE message when the mouse leaves it.
    #  0x0010 TME_NONCLIENT Specifies that the non-client area should be included when tracking the mouse.
    #                       The window will receive WM_NCMOUSEHOVER and WM_NCMOUSELEAVE messages depending
    #                       on whether TME_HOVER and/or TME_LEAVE are set.
    #
    # See also UntrackMouse()
BOOL
TrackMouse(handle, timeout=HOVER_DEFAULT, events=TME_HOVER|TME_LEAVE)
    HWND handle
    DWORD timeout
    DWORD events
PREINIT:
    TRACKMOUSEEVENT tme;
CODE:
    tme.cbSize = sizeof(TRACKMOUSEEVENT);
    tme.hwndTrack = handle;
    tme.dwFlags = events;
    tme.dwHoverTime = timeout;
    RETVAL = _TrackMouseEvent( &tme );
OUTPUT:
    RETVAL


    ###########################################################################
    # (@)METHOD:UntrackMouse()
    # Disables the tracking of mouse hover or leave events for a window.
    #
    # See also TrackMouse()
BOOL
UntrackMouse(handle)
    HWND handle
PREINIT:
    TRACKMOUSEEVENT tme;
CODE:
    tme.cbSize = sizeof(TRACKMOUSEEVENT);
    tme.hwndTrack = handle;
    tme.dwFlags = TME_QUERY;
    tme.dwHoverTime = 0;
    if(_TrackMouseEvent( &tme )) {
        tme.dwFlags = tme.dwFlags | TME_CANCEL;
        RETVAL = _TrackMouseEvent( &tme );
    } else {
        RETVAL = FALSE;
    }
OUTPUT:
    RETVAL

    # TODO: GetIconInfo

    ###########################################################################
    # DC-related functions (2D window graphic...)
    ###########################################################################


    ###########################################################################
    # (@)METHOD:PlayEnhMetaFile(FILENAME)
    # Displays the picture stored in the specified enhanced-format metafile.
    # This function use current window device context (-DC).
int
PlayEnhMetaFile(handle,filename)
    HWND handle
    LPCTSTR filename
PREINIT:
    HV* self;
    HDC hdc;
    SV** tmp;
    HENHMETAFILE hmeta;
    RECT rect;
CODE:
    self = (HV*) SvRV(ST(0));
    tmp = hv_fetch_mg(NOTXSCALL self, "-DC", 3, 0);
    if(tmp == NULL) {
        RETVAL = -1;
    } else {
        hdc = INT2PTR(HDC,SvIV(*tmp));
        if(hmeta = GetEnhMetaFile(filename)) {
            GetClientRect(handle, &rect);
            RETVAL = PlayEnhMetaFile(hdc, hmeta, &rect);
            DeleteEnhMetaFile(hmeta);
        } else {
#ifdef PERLWIN32GUI_DEBUG
                printf("XS(PlayEnhMetaFile): GetEnhMetaFile failed, error = %d\n", GetLastError());
#endif
            RETVAL = 0;
        }
    }
OUTPUT:
    RETVAL


    ###########################################################################
    # (@)METHOD:PlayWinMetaFile(FILENAME)
    # Displays the picture stored in the specified enhanced-format metafile. 
int
PlayWinMetaFile(handle,filename)
    HWND handle
    LPCTSTR filename
PREINIT:
    HDC hdc;
    HMETAFILE hwinmeta;
    HENHMETAFILE hmeta;
    RECT rect;
    UINT size;
    LPVOID data;
CODE:
#ifdef PERLWIN32GUI_DEBUG
    printf("XS(PlayWinMetaFile): filename = '%s'\n", filename);
#endif
    SetLastError(0);
    hwinmeta = GetMetaFile(filename);
#ifdef PERLWIN32GUI_DEBUG
    printf("XS(PlayWinMetaFile): hwinmeta = 0x%x\n", hwinmeta);
    printf("XS(PlayWinMetaFile): GetLastError = %ld\n", GetLastError());
#endif
    size = GetMetaFileBitsEx(hwinmeta, 0, NULL);
#ifdef PERLWIN32GUI_DEBUG
    printf("XS(PlayWinMetaFile): size = %d\n", size);
#endif
    data = (LPVOID) safemalloc(size);
    GetMetaFileBitsEx(hwinmeta, size, data);
    hmeta = SetWinMetaFileBits(size, (CONST BYTE *) data, NULL, NULL);
#ifdef PERLWIN32GUI_DEBUG
    printf("XS(PlayWinMetaFile): hmeta = 0x%x\n", hmeta);
#endif
    hdc = GetDC(handle);
    GetClientRect(handle, &rect);
    SetLastError(0);
    RETVAL = PlayEnhMetaFile(hdc, hmeta, &rect);
#ifdef PERLWIN32GUI_DEBUG
    printf("XS(PlayWinMetaFile): GetLastError after PlayEnhMetaFile = %d\n", GetLastError());
#endif
    DeleteEnhMetaFile(hmeta);
    ReleaseDC(handle, hdc);
    safefree(data);
OUTPUT:
    RETVAL


    ###########################################################################
    # (@)METHOD:CreateEnhMetaFile(FILENAME, [DESCRIPTION])
    # Creates a device context for an enhanced-format metafile.
HDC
CreateEnhMetaFile(handle, filename, description=NULL)
    HWND handle
    LPCTSTR filename
    LPCTSTR description
PREINIT:
    HV* self;
    HDC hdc;
    SV** tmp;
    RECT rect;
    int iWidthMM, iHeightMM, iWidthPels, iHeightPels;
CODE:
    self = (HV*) SvRV(ST(0));
    tmp = hv_fetch_mg(NOTXSCALL self, "-DC", 3, 0);
    if(tmp == NULL) {
        RETVAL = 0;
    } else {
        hdc = INT2PTR(HDC,SvIV(*tmp));
        iWidthMM = GetDeviceCaps(hdc, HORZSIZE);
        iHeightMM = GetDeviceCaps(hdc, VERTSIZE);
        iWidthPels = GetDeviceCaps(hdc, HORZRES);
        iHeightPels = GetDeviceCaps(hdc, VERTRES);
        GetClientRect(handle, &rect);
        rect.left = (rect.left * iWidthMM * 100)/iWidthPels;
        rect.top = (rect.top * iHeightMM * 100)/iHeightPels;
        rect.right = (rect.right * iWidthMM * 100)/iWidthPels;
        rect.bottom = (rect.bottom * iHeightMM * 100)/iHeightPels;
        RETVAL = CreateEnhMetaFile(hdc, filename, &rect, description);
    }
OUTPUT:
    RETVAL


    ###########################################################################
    # (@)METHOD:CloseEnhMetaFile(HANDLE)
    # Closes an enhanced-metafile device context and returns a handle that identifies an enhanced-format metafile. 
HENHMETAFILE
CloseEnhMetaFile(hdc)
    HDC hdc
CODE:
    RETVAL = CloseEnhMetaFile(hdc);
OUTPUT:
    RETVAL


    ###########################################################################
    # (@)METHOD:DeleteEnhMetaFile(HANDLE)
    # Deletes an enhanced-format metafile or an enhanced-format metafile handle. 
BOOL
DeleteEnhMetaFile(hmeta)
    HENHMETAFILE hmeta
CODE:
    RETVAL = DeleteEnhMetaFile(hmeta);
OUTPUT:
    RETVAL


    #HDC GetOrInitDC(SV* obj) {
    #    CPerl *pPerl;
    #    HDC hdc;
    #    HWND hwnd;
    #    SV** obj_dc;
    #    SV** obj_hwnd;
    #
    #    pPerl = theperl;
    #
    #    obj_dc = hv_fetch((HV*)SvRV(obj), "dc", 2, 0);
    #    if(obj_dc != NULL) {
    #        __DEBUG("!XS(GetOrInitDC): obj{dc} = %ld\n", SvIV(*obj_dc));
    #        return (HDC) SvIV(*obj_dc);
    #    } else {
    #        obj_hwnd = hv_fetch((HV*)SvRV(obj), "handle", 6, 0);
    #        hwnd = (HWND) SvIV(*obj_hwnd);
    #        hdc = GetDC(hwnd);
    #        __DEBUG("!XS(GetOrInitDC): GetDC = %ld\n", hdc);
    #        hv_store((HV*) SvRV(obj), "dc", 2, newSViv(PTR2IV(hdc)), 0);
    #        return hdc;
    #    }
    #}
    #
    #
    #XS(XS_Win32__GUI_DrawText) {
    #
    #    dXSARGS;
    #    if(items < 4 || items > 7) {
    #        CROAK("usage: DrawText($handle, $text, $left, $top, [$width, $height, $format]);\n");
    #    }
    #
    #    HDC hdc = GetOrInitDC(ST(0));
    #    RECT myRect;
    #
    #    strlen cbString;
    #    char *szString = SvPV(ST(1), cbString);
    #
    #    myRect.left   = (LONG) SvIV(ST(2));
    #    myRect.top    = (LONG) SvIV(ST(3));
    #
    #    if(items >4) {
    #        myRect.right  = (LONG) SvIV(ST(4));
    #        myRect.bottom = (LONG) SvIV(ST(5));
    #    } else {
    #        SIZE mySize;
    #        GetTextExtentPoint(hdc, szString, (int)cbString, &mySize);
    #        myRect.right  = myRect.left + (UINT) mySize.cx;
    #        myRect.bottom = myRect.top  + (UINT) mySize.cy;
    #    }
    #
    #    UINT uFormat = DT_LEFT;
    #
    #    if(items == 7) {
    #        uFormat = (UINT) SvIV(ST(6));
    #    }
    #
    #    BOOL result = DrawText(hdc,
    #                           szString,
    #                           cbString,
    #                           &myRect,
    #                           uFormat);
    #    XSRETURN_IV((IV) result);
    #}
    #
    #
    #
    #
    #XS(XS_Win32__GUI_ReleaseDC) {
    #
    #    dXSARGS;
    #    if(items != 1) {
    #        CROAK("usage: ReleaseDC($handle);\n");
    #    }
    #
    #    HWND hwnd = (HWND) handle_From(NOTXSCALL ST(0));
    #    HDC hdc = GetOrInitDC(ST(0));
    #
    #    ReleaseDC(hwnd, hdc);
    #    hv_delete((HV*) SvRV(ST(0)), "dc", 2, 0);
    #
    #    XSRETURN_NO;
    #}
    #
    #

long
TextOut(handle, x, y, text)
    HWND handle
    int x
    int y
    char * text
PREINIT:
    HV* self;
    HDC hdc;
    SV** tmp;
    STRLEN textlen;
CODE:
    self = (HV*) SvRV(ST(0));
    tmp = hv_fetch_mg(NOTXSCALL self, "-DC", 3, 0);
    if(tmp == NULL) {
        RETVAL = -1;
    } else {
        hdc = INT2PTR(HDC,SvIV(*tmp));
        textlen = strlen(text);
        RETVAL = (long) TextOut(hdc, x, y, text, textlen);
    }
OUTPUT:
    RETVAL

long
SetTextColor(handle, color)
    HWND handle
    COLORREF color
PREINIT:
    HV* self;
    HDC hdc;
    SV** tmp;
CODE:
    self = (HV*) SvRV(ST(0));
    tmp = hv_fetch_mg(NOTXSCALL self, "-DC", 3, 0);
    if(tmp == NULL) {
        RETVAL = -1;
    } else {
        hdc = INT2PTR(HDC,SvIV(*tmp));
        RETVAL = SetTextColor(hdc, color);
    }
OUTPUT:
    RETVAL

long
GetTextColor(handle)
    HWND handle
PREINIT:
    HV* self;
    HDC hdc;
    SV** tmp;
CODE:
    self = (HV*) SvRV(ST(0));
    tmp = hv_fetch_mg(NOTXSCALL self, "-DC", 3, 0);
    if(tmp == NULL) {
        RETVAL = -1;
    } else {
        hdc = INT2PTR(HDC,SvIV(*tmp));
        RETVAL = GetTextColor(hdc);
    }
OUTPUT:
    RETVAL

long
SetBkMode(handle, mode)
    HWND handle
    int mode
PREINIT:
    HV* self;
    HDC hdc;
    SV** tmp;
CODE:
    self = (HV*) SvRV(ST(0));
    tmp = hv_fetch_mg(NOTXSCALL self, "-DC", 3, 0);
    if(tmp == NULL) {
        RETVAL = -1;
    } else {
        hdc = INT2PTR(HDC,SvIV(*tmp));
        RETVAL = (long) SetBkMode(hdc, mode);
    }
OUTPUT:
    RETVAL

int
GetBkMode(handle)
    HWND handle
PREINIT:
    HV* self;
    HDC hdc;
    SV** tmp;
CODE:
    self = (HV*) SvRV(ST(0));
    tmp = hv_fetch_mg(NOTXSCALL self, "-DC", 3, 0);
    if(tmp == NULL) {
        RETVAL = -1;
    } else {
        hdc = INT2PTR(HDC,SvIV(*tmp));
        RETVAL = GetBkMode(hdc);
    }
OUTPUT:
    RETVAL

long
MoveTo(handle, x, y)
    HWND handle
    int x
    int y
PREINIT:
    HV* self;
    HDC hdc;
    SV** tmp;
CODE:
    self = (HV*) SvRV(ST(0));
    tmp = hv_fetch_mg(NOTXSCALL self, "-DC", 3, 0);
    if(tmp == NULL) {
        RETVAL = -1;
    } else {
        hdc = INT2PTR(HDC,SvIV(*tmp));
        RETVAL = MoveToEx(hdc, x, y, NULL);
    }
OUTPUT:
    RETVAL

long
Circle(handle, x, y, width, height=-1)
    HWND handle
    int x
    int y
    int width
    int height
PREINIT:
    HV* self;
    HDC hdc;
    SV** tmp;
CODE:
    self = (HV*) SvRV(ST(0));
    tmp = hv_fetch_mg(NOTXSCALL self, "-DC", 3, 0);
    if(tmp == NULL) {
        RETVAL = -1;
    } else {
        hdc = INT2PTR(HDC,SvIV(*tmp));
        if(height == -1) {
            width *= 2;
            height = width;
        }
        RETVAL = (long) Arc(hdc, x, y, width-x, height-y, 0, 0, 0, 0);
    }
OUTPUT:
    RETVAL


long
LineTo(handle, x, y)
    HWND handle
    int x
    int y
PREINIT:
    HV* self;
    HDC hdc;
    SV** tmp;
CODE:
    self = (HV*) SvRV(ST(0));
    tmp = hv_fetch_mg(NOTXSCALL self, "-DC", 3, 0);
    if(tmp == NULL) {
        RETVAL = -1;
    } else {
        hdc = INT2PTR(HDC,SvIV(*tmp));
        RETVAL = LineTo(hdc, x, y);
    }
OUTPUT:
    RETVAL

    #}
    #
    #XS(XS_Win32__GUI_DrawEdge) {
    #
    #    dXSARGS;
    #    if(items != 7) {
    #        CROAK("usage: DrawEdge($handle, $left, $top, $width, $height, $edge, $flags);\n");
    #    }
    #
    #    HDC hdc = GetOrInitDC(ST(0));
    #    RECT myRect;
    #    myRect.left   = (LONG) SvIV(ST(1));
    #    myRect.top    = (LONG) SvIV(ST(2));
    #    myRect.right  = (LONG) SvIV(ST(3));
    #    myRect.bottom = (LONG) SvIV(ST(4));
    #
    #    XSRETURN_IV((long) DrawEdge(hdc,
    #                           &myRect,
    #                           (UINT) SvIV(ST(5)),
    #                           (UINT) SvIV(ST(6))));
    #}

void
BeginPaint(...)
PPCODE:
    HV* self;
    HWND hwnd;
    HDC hdc;
    int i;
    PAINTSTRUCT ps;
    char tmprgb[16];
    self = (HV*) SvRV(ST(0));
    hwnd = INT2PTR(HWND,SvIV(*hv_fetch(self, "-handle", 7, 0)));
    if(hwnd) {
        if(hdc = BeginPaint(hwnd, &ps)) {
            hv_store(self, "-DC", 3, newSViv(PTR2IV(hdc)), 0);
            hv_store(self, "-ps.hdc", 7, newSViv(PTR2IV(ps.hdc)), 0);
            hv_store(self, "-ps.fErase", 10, newSViv((IV) ps.fErase), 0);
            hv_store(self, "-ps.rcPaint.left", 16, newSViv((IV) ps.rcPaint.left), 0);
            hv_store(self, "-ps.rcPaint.top", 15, newSViv((IV) ps.rcPaint.top), 0);
            hv_store(self, "-ps.rcPaint.right", 17, newSViv((IV) ps.rcPaint.right), 0);
            hv_store(self, "-ps.rcPaint.bottom", 18, newSViv((IV) ps.rcPaint.bottom), 0);
            hv_store(self, "-ps.fRestore", 12, newSViv((IV) ps.fRestore), 0);
            hv_store(self, "-ps.fIncUpdate", 14, newSViv((IV) ps.fIncUpdate), 0);
            for(i=0;i<=31;i++) {
                sprintf(tmprgb, "-ps.rgbReserved%02d", i);
                hv_store(self, tmprgb, 17, newSViv((IV) ps.rgbReserved[i]), 0);
            }
            XSRETURN_YES;
        } else {
            XSRETURN_NO;
        }
    } else {
        XSRETURN_NO;
    }

void
EndPaint(...)
PPCODE:
    HV* self;
    HWND hwnd;
    SV** tmp;
    int i;
    PAINTSTRUCT ps;
    char tmprgb[16];
    BOOL result;

    self = (HV*) SvRV(ST(0));
    if(self) {
        tmp = hv_fetch(self, "-handle", 7, 0);
        if(tmp == NULL) XSRETURN_NO;
        hwnd = INT2PTR(HWND,SvIV(*tmp));
        tmp = hv_fetch(self, "-ps.hdc", 7, 0);
        if(tmp == NULL) XSRETURN_NO;
        ps.hdc = INT2PTR(HDC,SvIV(*tmp));
        tmp = hv_fetch(self, "-ps.fErase", 10, 0);
        if(tmp == NULL) XSRETURN_NO;
        ps.fErase = (BOOL) SvIV(*tmp);
        tmp = hv_fetch(self, "-ps.rcPaint.left", 16, 0);
        if(tmp == NULL) XSRETURN_NO;
        ps.rcPaint.left = (LONG) SvIV(*tmp);
        tmp = hv_fetch(self, "-ps.rcPaint.top", 15, 0);
        if(tmp == NULL) XSRETURN_NO;
        ps.rcPaint.top = (LONG) SvIV(*tmp);
        tmp = hv_fetch(self, "-ps.rcPaint.right", 17, 0);
        if(tmp == NULL) XSRETURN_NO;
        ps.rcPaint.right = (LONG) SvIV(*tmp);
        tmp = hv_fetch(self, "-ps.rcPaint.bottom", 18, 0);
        if(tmp == NULL) XSRETURN_NO;
        ps.rcPaint.bottom = (LONG) SvIV(*tmp);
        tmp = hv_fetch(self, "-ps.fRestore", 12, 0);
        if(tmp == NULL) XSRETURN_NO;
        ps.fRestore = (BOOL) SvIV(*tmp);
        tmp = hv_fetch(self, "-ps.fIncUpdate", 14, 0);
        if(tmp == NULL) XSRETURN_NO;
        ps.fIncUpdate = (BOOL) SvIV(*tmp);
        for(i=0;i<=31;i++) {
            sprintf(tmprgb, "-ps.rgbReserved%02d", i);
            tmp = hv_fetch(self, tmprgb, 17, 0);
            if(tmp == NULL) XSRETURN_NO;
            ps.rgbReserved[i] = (BYTE) SvIV(*tmp);
        }
        result = EndPaint(hwnd, &ps);
        hv_delete(self, "-DC", 3, 0);
        hv_delete(self, "-ps.hdc", 7, 0);
        hv_delete(self, "-ps.fErase", 10, 0);
        hv_delete(self, "-ps.rcPaint.left", 16, 0);
        hv_delete(self, "-ps.rcPaint.top", 15, 0);
        hv_delete(self, "-ps.rcPaint.right", 17, 0);
        hv_delete(self, "-ps.rcPaint.bottom", 18, 0);
        hv_delete(self, "-ps.fRestore", 12, 0);
        hv_delete(self, "-ps.fIncUpdate", 14, 0);
        for(i=0;i<=31;i++) {
            sprintf(tmprgb, "-ps.rgbReserved%02d", i);
            hv_delete(self, tmprgb, 17, 0);
        }
        XSRETURN_IV((IV) result);
    } else {
        XSRETURN_NO;
    }


    ###########################################################################
    # (@)METHOD:SaveBMP(handle)
    # Saves the window content to a BMP file.
void
SaveBMP(handle)
    HWND handle
PREINIT:
    HDC hdc;
    HDC hdc2;
    RECT cr;
    HANDLE hf;
    BITMAP bmp;
    HBITMAP hbmp;
    PBITMAPINFO pbmi;
    PBITMAPINFOHEADER pbih;
    BITMAPFILEHEADER hdr;
    WORD cClrBits;
    LONG width, height;
    LPBYTE lpBits;
    BYTE *hp;
    DWORD cb;
    DWORD dwTmp;
    DWORD dwTotal;
    DWORD MAXWRITE;
PPCODE:
    hdc = GetDC(handle);
    GetClientRect(handle, &cr);
    width = cr.right - cr.left;
    height = cr.bottom - cr.top;
    MAXWRITE = 2048;

    hdc2 = CreateCompatibleDC(hdc);
    hbmp = CreateCompatibleBitmap(hdc, width, height);
    SelectObject(hdc2, hbmp);
    BitBlt(hdc2, 0, 0, width, height, hdc, 0, 0, SRCCOPY);
    if (!GetObject(hbmp, sizeof(BITMAP), (LPSTR)&bmp)) {
        XSRETURN_NO;
    }

    cClrBits = (WORD)(bmp.bmPlanes * bmp.bmBitsPixel);
    if (cClrBits == 1)       cClrBits = 1;
    else if (cClrBits <= 4)  cClrBits = 4;
    else if (cClrBits <= 8)  cClrBits = 8;
    else if (cClrBits <= 16) cClrBits = 16;
    else if (cClrBits <= 24) cClrBits = 24;
    else                     cClrBits = 32;

    if (cClrBits != 24)
        pbmi = (PBITMAPINFO) LocalAlloc(LPTR, sizeof(BITMAPINFOHEADER) + sizeof(RGBQUAD) * (2^cClrBits));
    else
        pbmi = (PBITMAPINFO) LocalAlloc(LPTR, sizeof(BITMAPINFOHEADER));

    pbmi->bmiHeader.biSize = sizeof(BITMAPINFOHEADER);
    pbmi->bmiHeader.biWidth = bmp.bmWidth;
    pbmi->bmiHeader.biHeight = bmp.bmHeight;
    pbmi->bmiHeader.biPlanes = bmp.bmPlanes;
    pbmi->bmiHeader.biBitCount = bmp.bmBitsPixel;
    if (cClrBits < 24) pbmi->bmiHeader.biClrUsed = 2^cClrBits;
    pbmi->bmiHeader.biCompression = BI_RGB;
    pbmi->bmiHeader.biSizeImage = (pbmi->bmiHeader.biWidth + 7) /8
                                  * pbmi->bmiHeader.biHeight
                                  * cClrBits;
    pbmi->bmiHeader.biClrImportant = 0;

    pbih = (PBITMAPINFOHEADER) pbmi;

    lpBits = (LPBYTE) GlobalAlloc(GMEM_FIXED, pbih->biSizeImage);

    if (!GetDIBits(hdc2, hbmp, 0, (WORD) pbih->biHeight, lpBits, pbmi, DIB_RGB_COLORS)) {
        XSRETURN_NO;
    }

    hf = CreateFile("SaveBMP.bmp",
                    GENERIC_READ | GENERIC_WRITE,
                    (DWORD) 0,
                    (LPSECURITY_ATTRIBUTES) NULL,
                    CREATE_ALWAYS,
                    FILE_ATTRIBUTE_NORMAL,
                    (HANDLE) NULL);
    if(hf == INVALID_HANDLE_VALUE) {
        XSRETURN_NO;
    }
    hdr.bfType = 0x4d42;        // #### 0x42 = "B" 0x4d = "M"

    // #### Compute the size of the entire file
    hdr.bfSize = (DWORD) (sizeof(BITMAPFILEHEADER) +
                 pbih->biSize + pbih->biClrUsed
                 * sizeof(RGBQUAD) + pbih->biSizeImage);
    hdr.bfReserved1 = 0;
    hdr.bfReserved2 = 0;

    // #### Compute the offset to the array of color indices
    hdr.bfOffBits = (DWORD) sizeof(BITMAPFILEHEADER) +
                    pbih->biSize + pbih->biClrUsed
                    * sizeof (RGBQUAD);
    // #### Copy the BITMAPFILEHEADER into the .BMP file
    if (!WriteFile(hf, (LPVOID) &hdr, sizeof(BITMAPFILEHEADER),
       (LPDWORD) &dwTmp, (LPOVERLAPPED) NULL)) {
       XSRETURN_NO;
    }
    // #### Copy the BITMAPINFOHEADER and RGBQUAD array into the file
    if (!WriteFile(hf, (LPVOID) pbih, sizeof(BITMAPINFOHEADER)
                  + pbih->biClrUsed * sizeof (RGBQUAD),
                  (LPDWORD) &dwTmp, (LPOVERLAPPED) NULL)) {
        XSRETURN_NO;
    }
    // #### Copy the array of color indices into the .BMP file
    dwTotal = cb = pbih->biSizeImage;     hp = lpBits;
    while (cb > MAXWRITE)  {
        if (!WriteFile(hf, (LPSTR) hp, MAXWRITE,
                          (LPDWORD) &dwTmp, (LPOVERLAPPED) NULL)) {
            XSRETURN_NO;
        }
        cb -= MAXWRITE;
        hp += MAXWRITE;
    }
    if (!WriteFile(hf, (LPSTR) hp, (int) cb,
        (LPDWORD) &dwTmp, (LPOVERLAPPED) NULL)) {
        XSRETURN_NO;
    }
    if (!CloseHandle(hf)) {
        XSRETURN_NO;
    }

    // #### Free memory
    GlobalFree((HGLOBAL)lpBits);
    DeleteDC(hdc2);
    ReleaseDC(handle, hdc);
    DeleteObject(hbmp);
    XSRETURN_YES;


    ###########################################################################
    # (@)METHOD:GetFontName()
    # Returns the name of the font that is currently assigned to a window or
    # control
LPTSTR
GetFontName(handle)
    HWND handle
PREINIT:
    HDC hdc;
    char facename[256];
CODE:
    hdc = GetDC(handle);
    if(GetTextFace(hdc, 256, facename)) {
        RETVAL = (LPTSTR) facename;
    } else {
        RETVAL = "";
    }
    ReleaseDC(handle, hdc);
OUTPUT:
    RETVAL


    # void
    # EnumChilds(handle)
    #     HWND handle
    # PREINIT:
    #     UINT number;
    # PPCODE:
    #     if(EnumChildWindows(handle, EnumChildsProc, (LPARAM) &number))
    #         XSRETURN(number);
    #     else
    #         XSRETURN_NO;

    ###########################################################################
    # (@)METHOD:EnumMyWindows()
    # Returns a list of top-level window handles created by your application.
    #
    # Usage:
    #    @windows = Win32::GUI::EnumMyWindows();
    #
void
EnumMyWindows()
PREINIT:
    AV* ary;
    int i;
PPCODE:
    ary = newAV();
    EnumWindows( (WNDENUMPROC) EnumMyWindowsProc, (LPARAM) ary);
    for(i=0; i<av_len(ary)+1; i++) {
        //printf("XS(EnumMyWindows): ary[%d] = %ld\n", i, SvIV(*(av_fetch(ary, i, 0))));
        XST_mIV(i, SvIV(*(av_fetch(ary, i, 0))));
    }
    SvREFCNT_dec((SV*)ary);
    XSRETURN(i);
  
    ###########################################################################
    # (@)METHOD:GetSystemMetrics(INDEX)
    # Retrieves various system metrics (dimensions of display elements) and
    # configuration settings. Too numerous to list here. See WinUser.h for
    # a complete list of SM_* constants that you can use for INDEX.
int
GetSystemMetrics(index)
    int index
CODE:
    RETVAL = GetSystemMetrics(index);
OUTPUT:
    RETVAL

    ###########################################################################
    # Common Dialog Boxes
    ###########################################################################


    ###########################################################################
    # (@)METHOD:MessageBox([HANDLE], TEXT, [CAPTION], [TYPE])
    # Shows a standard Windows message box and waits for the user to dismiss it.
    # You can set the window that the message box corresponds to by passing
    # a specific B<HANDLE> (window handle or object). The given B<TEXT> will appear
    # in the message box client area, and the given B<CAPTION> text will appear
    # in the message box titlebar. B<TYPE> specifies various flags that change
    # the appearance of the message box. These are:
    #
    # To set which buttons appear on the message box, specify one of the following values:
    #  0x0000 MB_OK show an OK button
    #  0x0001 MB_OKCANCEL show an OK button and a Cancel button
    #  0x0002 MB_ABORTRETRYIGNORE show Abort, Retry and Ignore buttons
    #  0x0003 MB_YESNOCANCEL show Yes, No and Cancel buttons
    #  0x0004 MB_YESNO show Yes and No buttons
    #  0x0005 MB_RETRYCANCEL show Retry and Cancel buttons
    #  0x0006 MB_CANCELTRYCONTINUE show Cancel, Try Again and Continue buttons (2000/XP only)
    #
    # To add a help button to the message box, specify the following value:
    #  0x4000 MB_HELP
    #
    # To show an icon in the message box, specify one of these values:
    #  0x0010 MB_ICONHAND show a stop-sign icon (used for errors)
    #  0x0020 MB_ICONQUESTION show a question mark icon
    #  0x0030 MB_ICONEXCLAMATION show an exclamation mark icon (used for warnings)
    #  0x0040 MB_ICONASTERISK show an asterisk icon (the letter "i" in a circle) (used for information)
    #
    # To set a default button, specify one of these values (if none of these are specified, the first
    # button will be the default button):
    #  0x0100 MB_DEFBUTTON2 The second button is default
    #  0x0200 MB_DEFBUTTON3 The third button is default
    #  0x0300 MB_DEFBUTTON4 The fourth button is default
    #
    # To specify how the message box affects other windows and various other flags, use one or
    # more of the following values:
    #  0x0000   MB_APPLMODAL The user must dismiss the message box before continuing work in
    #              the window specified by HANDLE (this is the default)
    #  0x1000   MB_SYSTEMMODAL Same as MB_APPLMODAL but the window appears on top of all other
    #              windows on the desktop.
    #  0x2000   MB_TASKMODAL Same as MB_APPLMODAL except that all the top-level windows belonging
    #              to the current thread are disabled if no HANDLE is specified
    #  0x8000   MB_NOFOCUS Does not give the message box input focus
    #  0x10000  MB_SETFOREGROUND Makes the message box become the foreground window
    #  0x20000  MB_DEFAULT_DESKTOP_ONLY If the current desktop is not the default
    #              desktop, MessageBox will not return until the user switches to the default desktop
    #  0x40000  MB_TOPMOST Makes the message box become the topmost window
    #  0x80000  MB_RIGHT Makes text in the message box right-aligned
    #  0x100000 MB_RTLREADING Displays message and caption text using right-to-left reading
    #              order on Hebrew and Arabic systems.
    #  0x200000 MB_SERVICE_NOTIFICATION Displays the message box even if no user is logged
    #              in on Windows NT/2000/XP. You should not specify a HANDLE when using this.
    #
    # To combine several values together, use a bitwise OR operator (|).
    #
    # MessageBox will return one of the following values depending on the user's action:
    #   1 IDOK       The user clicked the OK button.
    #   2 IDCANCEL   The user clicked the Cancel button.
    #   3 IDABORT    The user clicked the Abort button.
    #   4 IDRETRY    The user clicked the Retry button.
    #   5 IDIGNORE   The user clicked the Ignore button.
    #   6 IDYES      The user clicked the Yes button.
    #   7 IDNO       The user clicked the No button.
    #   8 IDCLOSE    The user closed the message box.
    #   9 IDHELP     The user clicked the Help button.
    #  10 IDTRYAGAIN The user clicked the Try Again button.
    #  11 IDCONTINUE The user clicked the Continue button.
    #
    # The default B<TYPE> value is a warning icon with an OK button (MB_ICONEXCLAMATION|MB_OK).
int
MessageBox(handle=NULL, text, caption=NULL, type=MB_ICONEXCLAMATION|MB_OK)
    HWND handle
    LPCTSTR text
    LPCTSTR caption
    UINT type
CODE:
    RETVAL = MessageBox(handle, text, caption, type);
OUTPUT:
    RETVAL

    ###########################################################################
    # (@)METHOD:MessageBeep([TYPE=MB_OK])
    # Plays a sound.
    # 
    # B<TYPE> specifies the sound type :
    #  MB_OK : Play SystemDefault sound.
    #  MB_ICONASTERISK : Play SystemAsterisk sound.
    #  MB_ICONEXCLAMATION : Play SystemExclamation sound.
    #  MB_ICONHAND : Play SystemHand sound.
    #  MB_ICONQUESTION : Play SystemQuestion sound.
    #  0xFFFFFFFF Play Standard beep using the computer speaker 

BOOL 
MessageBeep(type=MB_OK)
    UINT type
CODE:
    RETVAL = MessageBeep(type);
OUTPUT:
    RETVAL

    ###########################################################################
    # (@)METHOD:GetOpenFileName(%OPTIONS)
    # Allowed B<%OPTIONS> are:
    #  -owner => WINDOW
    #      Identifies the window that owns the dialog box.
    #  -title => STRING
    #      The title for the dialog
    #  -directory => STRING
    #      Specifies the initial directory
    #  -file => STRING
    #      Specifies a name that will appear on the dialog's edit field
    #  -filter => ARRAY REFERENCE
    #      Specifies an array containing pairs of filter strings.
    #      The first string in each pair is a display string that describes the filter
    #      (for example, "Text Files"), and the second string specifies the filter pattern
    #      (for example, "*.TXT"). To specify multiple filter patterns for a single display
    #      string, use a semicolon to separate the patterns (for example, "*.TXT;*.DOC;*.BAK").
    #      A pattern string can be a combination of valid filename characters and the
    #      asterisk (*) wildcard character. Do not include spaces in the pattern string.
    #  -defaultextension => STRING
    #      Contains the default extension. GetOpenFileName append this extension to the
    #      filename if the user fails to type an extension. This string can be any length,
    #      but only the first three characters are appended. The string should not contain a
    #      period (.).
    #  -defaultfilter => NUMBER
    #      Specifies the index of the currently selected filter in the File Types control.
    #      The first pair of strings has an index value of 0, the second pair 1, and so on.    
    #  -createprompt => 0/1 (default 0)
    #      If the user specifies a file that does not exist, this flag causes the dialog box
    #      to prompt the user for permission to create the file. If the user chooses to create
    #      the file, the dialog box closes and the function returns the specified name; otherwise,
    #      the dialog box remains open. If you use this flag with the -multisel flag, the dialog
    #      box allows the user to specify only one nonexistent file.
    #  -multisel => 0/1 (default 0)
    #      Allow multiple file selection
    #      If the user selects more than one file then return filename with full path.
    #      If the user selects more than one file then return an array with the path
    #      to the current directory followed by the filenames of the selected files.
    #  -explorer => 0/1 (default 1)
    #      Explorer look.
    #  -extensiondifferent => 0/1 (default 0)
    #      Specifies that the user can typed a filename extension that differs from the extension
    #      specified by -defaultextension.
    #  -filemustexist => 0/1 (default 0)
    #      Specifies that the user can type only names of existing files in the File Name entry
    #      field. If this flag is specified and the user enters an invalid name, the dialog box
    #      procedure displays a warning in a message box.
    #  -hidereadonly => 0/1 (default 1)
    #      Hides the Read Only check box. If -hidereadonly is set to 0, the read only status is
    #      return only in array context as last value.
    #  -nochangedir => 0/1 (default 0)
    #      Restores the current directory to its original value if the user changed the directory
    #      while searching for files.
    #  -nodeferencelinks => 0/1 (default 0)
    #      Directs the dialog box to return the path and filename of the selected
    #      shortcut (.LNK) file. If this value is not given, the dialog box returns the
    #      path and filename of the file referenced by the shortcut.
    #  -nonetwork  => 0/1 (default 0)
    #      Hides and disables the Network button
    #  -noreadonlyreturn => 0/1 (default 0)
    #      Specifies that the returned file does not have the Read Only check box checked and is
    #      not in a write-protected directory.
    #  -pathmustexist => 0/1 (default 0)
    #      Specifies that the user can type only valid paths and filenames.
    #      If this flag is used and the user types an invalid path and filename in the File Name
    #      entry field, the dialog box function displays a warning in a message box.
    #  -readonly => 0/1 (default 0)
    #      Causes the Read Only check box to be checked initially when the dialog box is created.
    #
void
GetOpenFileName(...)
PPCODE:
    OPENFILENAME ofn;
    BOOL retval;
    int i, next_i;
    unsigned int fnlen = MAX_PATH;
    char *fname_in = NULL;
    char *fname;
    char *option;
    char *filter;

    ZeroMemory(&ofn, sizeof(OPENFILENAME));
    ofn.lStructSize = sizeof(OPENFILENAME);
    ofn.hwndOwner = NULL;
    ofn.lpstrFilter = NULL;
    ofn.lpstrCustomFilter = NULL;
    ofn.nFilterIndex = 0;
    ofn.lpstrFileTitle = NULL;
    ofn.lpstrInitialDir = NULL;
    ofn.lpstrTitle = NULL;
    ofn.lpstrDefExt = NULL;
    ofn.lpTemplateName = NULL;
    ofn.Flags = OFN_HIDEREADONLY | OFN_EXPLORER;

    next_i = -1;
    for(i = 0; i < items; i++) {
        if(next_i == -1) {
            option = SvPV_nolen(ST(i));
            if(strcmp(option, "-owner") == 0) {
                next_i = i + 1;
                ofn.hwndOwner = (HWND) handle_From(NOTXSCALL ST(next_i));
            } else if(strcmp(option, "-title") == 0) {
                next_i = i + 1;
                ofn.lpstrTitle = SvPV_nolen(ST(next_i));
            } else if(strcmp(option, "-directory") == 0) {
                next_i = i + 1;
                ofn.lpstrInitialDir = SvPV_nolen(ST(next_i));
            } else if(strcmp(option, "-defaultextension") == 0
                      # leave misspelling below for compatibility...
                  ||  strcmp(option, "-defaultextention") == 0 ) {
                next_i = i + 1;
                ofn.lpstrDefExt = SvPV_nolen(ST(next_i));
            } else if(strcmp(option, "-file") == 0) {
                next_i = i + 1;
                fname_in = SvPV_nolen(ST(next_i));
            } else if(strcmp(option, "-filter") == 0) {
                next_i = i + 1;
                if(SvROK(ST(next_i)) && SvTYPE(SvRV(ST(next_i))) == SVt_PVAV) {
                    AV* filters;
                    SV** t;
                    int i, filterlen = 0;
                    char *fpointer;
                    filters = (AV*)SvRV(ST(next_i));
                    for(i=0; i<=av_len(filters); i++) {
                        t = av_fetch(filters, i, 0);
                        if(t != NULL) {
                            filterlen += SvCUR(*t) + 1;
                        }
                    }
                    filterlen += 2;
                    filter = (char *) safemalloc(filterlen);
                    fpointer = filter;
                    for(i=0; i<=av_len(filters); i++) {
                        t = av_fetch(filters, i, 0);
                        if(t != NULL) {
                            strcpy(fpointer, SvPV_nolen(*t));
                            fpointer += SvCUR(*t);
                            *fpointer++ = 0;
                        }
                    }
                    *fpointer = 0;
                    ofn.lpstrFilter = (LPCTSTR) filter;
                } else {
                    W32G_WARN("Win32::GUI: argument to -filter is not an array reference!");
                }
            } else if(strcmp(option, "-defaultfilter") == 0 ) {
                next_i = i + 1;
                ofn.nFilterIndex = (DWORD)SvIV(ST(next_i)) + 1;
            } else if(strcmp(option, "-flags") == 0) {
                next_i = i + 1;
                ofn.Flags = (DWORD)SvIV(ST(next_i));
            } else BitmaskOption( "-multisel", ofn.Flags, OFN_ALLOWMULTISELECT )
                if(fnlen < 4000 * (unsigned)SvIV(ST(next_i))) {
                  fnlen = 4000 * (unsigned)SvIV(ST(next_i));
                }
            } else BitmaskOption( "-createprompt", ofn.Flags, OFN_CREATEPROMPT )
            } else BitmaskOption( "-explorer", ofn.Flags, OFN_EXPLORER )
            } else BitmaskOption( "-extensiondifferent", ofn.Flags, OFN_EXTENSIONDIFFERENT )
            } else BitmaskOption( "-filemustexist", ofn.Flags, OFN_FILEMUSTEXIST )
            } else BitmaskOption( "-hidereadonly", ofn.Flags, OFN_HIDEREADONLY )
            } else BitmaskOption( "-nochangedir", ofn.Flags, OFN_NOCHANGEDIR )
            } else BitmaskOption( "-nodeferencelinks", ofn.Flags, OFN_NODEREFERENCELINKS )
            } else BitmaskOption( "-nonetwork", ofn.Flags, OFN_NONETWORKBUTTON )
            } else BitmaskOption( "-noreadonlyreturn", ofn.Flags, OFN_NOREADONLYRETURN )
            } else BitmaskOption( "-pathmustexist", ofn.Flags, OFN_PATHMUSTEXIST )
            } else BitmaskOption( "-readonly", ofn.Flags, OFN_READONLY )
            }
        } else {
            next_i = -1;
        }
    }

    
    fname = (char *) safemalloc(fnlen);
    fname[0] = 0;
    if(fname_in  &&  fnlen > strlen(fname_in)) {
      strcpy(fname, fname_in);
    }
    ofn.lpstrFile = fname;
    ofn.nMaxFile = fnlen;

    retval = GetOpenFileName(&ofn);

    if(ofn.lpstrFilter != NULL) safefree((void *)filter);

    if(retval) {
      if (ofn.Flags & OFN_ALLOWMULTISELECT) {
         i = 0;
         char * ptr = (char *) ofn.lpstrFile;

         // Count files
         while (*ptr) {
           i ++;
           ptr += strlen(ptr) + 1;
         }

         if ( !(ofn.Flags & OFN_HIDEREADONLY) )
            i++;

         EXTEND(SP, i);

         i = 0;
         ptr = (char *) ofn.lpstrFile;
         while (*ptr) {
            XST_mPV(i, ptr);
            i ++;
            ptr += strlen(ptr) + 1;
         }

         if ( !(ofn.Flags & OFN_HIDEREADONLY) ) {
            XST_mIV( i, (ofn.Flags & OFN_READONLY) );
            i ++;
         }

         safefree((void *)fname);
         XSRETURN(i);
      }
      else {
        if ((ofn.Flags & OFN_HIDEREADONLY) || GIMME_V == G_SCALAR) {
            EXTEND(SP, 1);
            XST_mPV( 0, ofn.lpstrFile);
            safefree((void *)fname);
            XSRETURN(1);
        }
        else {
            EXTEND(SP, 2);
            XST_mPV( 0, ofn.lpstrFile);
            XST_mIV( 1, (ofn.Flags & OFN_READONLY) );
            safefree((void *)fname);
            XSRETURN(2);
        }
      }
    } else {
        safefree((void *)fname);
        XSRETURN_UNDEF;
    }


    ###########################################################################
    # (@)METHOD:GetSaveFileName(%OPTIONS)
    # Allowed B<%OPTIONS> are:
    #  -owner => WINDOW
    #      Identifies the window that owns the dialog box.
    #  -title => STRING
    #      The title for the dialog
    #  -directory => STRING
    #      Specifies the initial directory
    #  -file => STRING
    #      Specifies a name that will appear on the dialog's edit field
    #  -filter => ARRAY REFERENCE
    #      Specifies an array containing pairs of filter strings.
    #      The first string in each pair is a display string that describes the filter
    #      (for example, "Text Files"), and the second string specifies the filter pattern
    #      (for example, "*.TXT"). To specify multiple filter patterns for a single display
    #      string, use a semicolon to separate the patterns (for example, "*.TXT;*.DOC;*.BAK").
    #      A pattern string can be a combination of valid filename characters and the asterisk (*)
    #      wildcard character. Do not include spaces in the pattern string.
    #  -defaultextension => STRING
    #      Contains the default extension. GetSaveFileName append this extension to the filename if the user
    #      fails to type an extension. This string can be any length, but only the first three characters are
    #      appended. The string should not contain a period (.).
    #  -defaultfilter => NUMBER
    #      Specifies the index of the currently selected filter in the File Types control.
    #      The first pair of strings has an index value of 0, the second pair 1, and so on.
    #  -createprompt => 0/1 (default 0)
    #      If the user specifies a file that does not exist, this flag causes the dialog box to prompt
    #      the user for permission to create the file. If the user chooses to create the file, the dialog box
    #      closes and the function returns the specified name; otherwise, the dialog box remains open.
    #      If you use this flag with the -multisel flag, the dialog box allows the user to specify
    #      only one nonexistent file.
    #  -explorer => 0/1 (default 1)
    #      Explorer look.
    #  -extensiondifferent => 0/1 (default 0)
    #      Specifies that the user can typed a filename extension that differs from the extension
    #      specified by -defaultextension.
    #  -filemustexist => 0/1 (default 0)
    #      Specifies that the user can type only names of existing files in the File Name entry field.
    #      If this flag is specified and the user enters an invalid name, the dialog box procedure displays
    #      a warning in a message box.
    #  -nochangedir => 0/1 (default 0)
    #      Restores the current directory to its original value if the user changed the directory
    #      while searching for files.
    #  -nodeferencelinks => 0/1 (default 0)
    #      Directs the dialog box to return the path and filename of the selected shortcut (.LNK) file.
    #      If this value is not given, the dialog box returns the path and filename of the file
    #      referenced by the shortcut.
    #  -nonetwork  => 0/1 (default 0)
    #      Hides and disables the Network button
    #  -noreadonlyreturn => 0/1 (default 0)
    #      Specifies that the returned file is not in a write-protected directory.
    #  -pathmustexist => 0/1 (default 1)
    #      Specifies that the user can type only valid paths and filenames.
    #      If this flag is used and the user types an invalid path and filename in the File Name
    #      entry field, the dialog box function displays a warning in a message box.
    #  -overwriteprompt => 0/1 (default 1)
    #      Generate a message box if the selected file already exists. The user must confirm8
    #      whether to overwrite the file.
void
GetSaveFileName(...)
PPCODE:
    OPENFILENAME ofn;
    BOOL retval;
    int i, next_i;
    char filename[MAX_PATH];
    char *option;
    char *filter;

    ZeroMemory(&ofn, sizeof(OPENFILENAME));
    ofn.lStructSize = sizeof(OPENFILENAME);
    ofn.hwndOwner = NULL;
    ofn.lpstrFilter = NULL;
    ofn.lpstrCustomFilter = NULL;
    ofn.nFilterIndex = 0;
    ofn.lpstrFileTitle = NULL;
    ofn.lpstrInitialDir = NULL;
    ofn.lpstrTitle = NULL;
    ofn.lpstrDefExt = NULL;
    ofn.lpTemplateName = NULL;
    ofn.Flags = OFN_HIDEREADONLY | OFN_OVERWRITEPROMPT | OFN_PATHMUSTEXIST | OFN_EXPLORER;
    filename[0] = 0;
    ofn.lpstrFile = filename;
    ofn.nMaxFile = MAX_PATH;

    next_i = -1;
    for(i = 0; i < items; i++) {
        if(next_i == -1) {
            option = SvPV_nolen(ST(i));
            if(strcmp(option, "-owner") == 0) {
                next_i = i + 1;
                ofn.hwndOwner = (HWND) handle_From(NOTXSCALL ST(next_i));
            } else if(strcmp(option, "-title") == 0) {
                next_i = i + 1;
                ofn.lpstrTitle = SvPV_nolen(ST(next_i));
            } else if(strcmp(option, "-directory") == 0) {
                next_i = i + 1;
                ofn.lpstrInitialDir = SvPV_nolen(ST(next_i));
            } else if(strcmp(option, "-defaultextension") == 0
                      # leave misspelling below for compatibility...
                  ||  strcmp(option, "-defaultextention") == 0 ) {
                next_i = i + 1;
                ofn.lpstrDefExt = SvPV_nolen(ST(next_i));
            } else if(strcmp(option, "-file") == 0) {
                next_i = i + 1;
                strcpy(filename, SvPV_nolen(ST(next_i)));
            } else if(strcmp(option, "-filter") == 0) {
                next_i = i + 1;
                if(SvROK(ST(next_i)) && SvTYPE(SvRV(ST(next_i))) == SVt_PVAV) {
                    AV* filters;
                    SV** t;
                    int i, filterlen = 0;
                    char *fpointer;
                    filters = (AV*)SvRV(ST(next_i));
                    for(i=0; i<=av_len(filters); i++) {
                        t = av_fetch(filters, i, 0);
                        if(t != NULL) {
                            filterlen += SvCUR(*t) + 1;
                        }
                    }
                    filterlen += 2;
                    filter = (char *) safemalloc(filterlen);
                    fpointer = filter;
                    for(i=0; i<=av_len(filters); i++) {
                        t = av_fetch(filters, i, 0);
                        if(t != NULL) {
                            strcpy(fpointer, SvPV_nolen(*t));
                            fpointer += SvCUR(*t);
                            *fpointer++ = 0;
                        }
                    }
                    *fpointer = 0;
                    ofn.lpstrFilter = (LPCTSTR) filter;
                } else {
                    W32G_WARN("Win32::GUI: argument to -filter is not an array reference!");
                }
            } else if(strcmp(option, "-defaultfilter") == 0 ) {
                next_i = i + 1;
                ofn.nFilterIndex = (DWORD)SvIV(ST(next_i)) + 1;
            } else if(strcmp(option, "-flags") == 0) {
                next_i = i + 1;
                ofn.Flags = (DWORD)SvIV(ST(next_i));
            } else BitmaskOption( "-createprompt", ofn.Flags, OFN_CREATEPROMPT )
            } else BitmaskOption( "-explorer", ofn.Flags, OFN_EXPLORER )
            } else BitmaskOption( "-extensiondifferent", ofn.Flags, OFN_EXTENSIONDIFFERENT )
            } else BitmaskOption( "-filemustexist", ofn.Flags, OFN_FILEMUSTEXIST )
            } else BitmaskOption( "-nochangedir", ofn.Flags, OFN_NOCHANGEDIR )
            } else BitmaskOption( "-nodeferencelinks", ofn.Flags, OFN_NODEREFERENCELINKS )
            } else BitmaskOption( "-nonetwork", ofn.Flags, OFN_NONETWORKBUTTON )
            } else BitmaskOption( "-noreadonlyreturn", ofn.Flags, OFN_NOREADONLYRETURN )
            } else BitmaskOption( "-pathmustexist", ofn.Flags, OFN_PATHMUSTEXIST )
            } else BitmaskOption( "-overwriteprompt", ofn.Flags, OFN_OVERWRITEPROMPT )
            } else BitmaskOption( "-overdriveprompt", ofn.Flags, OFN_OVERWRITEPROMPT ) // deprecated, but retained for compatibility
            }
        } else {
            next_i = -1;
        }
    }
    retval = GetSaveFileName(&ofn);
    if(retval) {
        EXTEND(SP, 1);
        XST_mPV( 0, ofn.lpstrFile);
        if(ofn.lpstrFilter != NULL) safefree((void *)filter);
        XSRETURN(1);
    } else {
        if(ofn.lpstrFilter != NULL) safefree((void *)filter);
        XSRETURN_UNDEF;
    }


    ###########################################################################
    # (@)METHOD:BrowseForFolder(%OPTIONS)
    # Displays the standard "Browse For Folder" dialog box. Returns the
    # selected item's name, or undef if no item was selected or an error
    # occurred.
    #
    # Allowed B<%OPTIONS> are:
    #  -title => STRING
    #      the title for the dialog
    #  -computeronly => 0/1 (default 0)
    #      only enable computers to be selected
    #  -domainonly => 0/1 (default 0)
    #      only enable computers in the current domain or workgroup
    #  -driveonly => 0/1 (default 0)
    #      only enable drives to be selected
    #  -editbox => 0/1 (default 0)
    #      if 1, the dialog will include an edit field in which
    #      the user can type the name of an item
    #  -folderonly => 0/1 (default 0)
    #      only enable folders to be selected
    #  -includefiles => 0/1 (default 0)
    #      the list will include files as well folders
    #  -newui => 0/1 (default 0)
    #      use the "new" user interface (which has a "New folder" button)
    #  -nonewfolder => 0/1 (default 0)
    #      hides the "New folder" button (only meaningful with -newui => 1)
    #  -owner => WINDOW
    #      A Win32::GUI::Window or Win32::GUI::DialogBox object specifiying the
    #      owner window for the dialog box
    #  -printeronly => 0/1 (default 0)
    #      only enable printers to be selected
    #  -directory => PATH
    #      the default start directory for browsing
    #  -root => PATH or CONSTANT
    #      the root directory for browsing; this can be either a
    #      path or one of the following constants (minimum operating systems or
    #      Internet Explorer versions that support the constant are shown in
    #      square brackets. NT denotes Windows NT 4.0, Windows 2000, XP, etc.):
    #
    #       CSIDL_FLAG_CREATE (0x8000)
    #           [2000/ME] Combining this with any of the constants below will create the folder if it does not already exist.
    #       CSIDL_ADMINTOOLS (0x0030)
    #           [2000/ME] Administrative Tools directory for current user
    #       CSIDL_ALTSTARTUP (0x001d)
    #           [All] Non-localized Startup directory in the Start menu for current user
    #       CSIDL_APPDATA (0x001a)
    #           [IE4] Application data directory for current user
    #       CSIDL_BITBUCKET (0x000a)
    #           [All] Recycle Bin
    #       CSIDL_CDBURN_AREA (0x003b)
    #           [XP] Windows XP directory for files that will be burned to CD
    #       CSIDL_COMMON_ADMINTOOLS (0x002f)
    #           [2000/ME] Administrative Tools directory for all users
    #       CSIDL_COMMON_ALTSTARTUP (0x001e)
    #           [All] Non-localized Startup directory in the Start menu for all users
    #       CSIDL_COMMON_APPDATA (0x0023)
    #           [2000/ME] Application data directory for all users
    #       CSIDL_COMMON_DESKTOPDIRECTORY (0x0019)
    #           [NT] Desktop directory for all users
    #       CSIDL_COMMON_DOCUMENTS (0x002e)
    #           [IE4] My Documents directory for all users
    #       CSIDL_COMMON_FAVORITES (0x001f)
    #           [NT] Favorites directory for all users
    #       CSIDL_COMMON_MUSIC (0x0035)
    #           [XP] Music directory for all users
    #       CSIDL_COMMON_PICTURES (0x0036)
    #           [XP] Image directory for all users
    #       CSIDL_COMMON_PROGRAMS (0x0017)
    #           [NT] Start menu "Programs" directory for all users
    #       CSIDL_COMMON_STARTMENU (0x0016)
    #           [NT] Start menu root directory for all users
    #       CSIDL_COMMON_STARTUP (0x0018)
    #           [NT] Start menu Startup directory for all users
    #       CSIDL_COMMON_TEMPLATES (0x002d)
    #           [NT] Document templates directory for all users
    #       CSIDL_COMMON_VIDEO (0x0037)
    #           [XP] Video directory for all users
    #       CSIDL_CONTROLS (0x0003)
    #           [All] Control Panel applets
    #       CSIDL_COOKIES (0x0021)
    #           [All] Cookies directory
    #       CSIDL_DESKTOP (0x0000)
    #           [All] Namespace root (shown as "Desktop", but is parent to my computer, control panel, my documents, etc.)
    #       CSIDL_DESKTOPDIRECTORY (0x0010)
    #           [All] Desktop directory (for desktop icons, folders, etc.) for the current user
    #       CSIDL_DRIVES (0x0011)
    #           [All] My Computer (drives and mapped network drives)
    #       CSIDL_FAVORITES (0x0006)
    #           [All] Favorites directory for the current user
    #       CSIDL_FONTS (0x0014)
    #           [All] Fonts directory
    #       CSIDL_HISTORY (0x0022)
    #           [All] Internet Explorer history items for the current user
    #       CSIDL_INTERNET (0x0001)
    #           [All] Internet root
    #       CSIDL_INTERNET_CACHE (0x0020)
    #           [IE4] Temporary Internet Files directory for the current user
    #       CSIDL_LOCAL_APPDATA (0x001c)
    #           [2000/ME] Local (non-roaming) application data directory for the current user
    #       CSIDL_MYMUSIC (0x000d)
    #           [All] My Music directory for the current user
    #       CSIDL_MYPICTURES (0x0027)
    #           [2000/ME] Image directory for the current user
    #       CSIDL_MYVIDEO (0x000e)
    #           [XP] Video directory for the current user
    #       CSIDL_NETHOOD (0x0013)
    #           [All] My Network Places directory for the current user
    #       CSIDL_NETWORK (0x0012)
    #           [All] Root of network namespace (Network Neighbourhood)
    #       CSIDL_PERSONAL (0x0005)
    #           [All] My Documents directory for the current user
    #       CSIDL_PRINTERS (0x0004)
    #           [All] List of installed printers
    #       CSIDL_PRINTHOOD (0x001b)
    #           [All] Network printers directory for the current user
    #       CSIDL_PROFILE (0x0028)
    #           [2000/ME] The current user's profile directory
    #       CSIDL_PROFILES (0x003e)
    #           [XP] The directory that holds user profiles (see CSDIL_PROFILE)
    #       CSIDL_PROGRAM_FILES (0x0026)
    #           [2000/ME] Program Files directory
    #       CSIDL_PROGRAM_FILES_COMMON (0x002b)
    #           [2000] Directory for files that are used by several applications. Usually Program Files\Common
    #       CSIDL_PROGRAMS (0x0002)
    #           [All] Start menu "Programs" directory for the current user
    #       CSIDL_RECENT (0x0008)
    #           [All] Recent Documents directory for the current user
    #       CSIDL_SENDTO (0x0009)
    #           [All] "Send To" directory for the current user
    #       CSIDL_STARTMENU (0x000b)
    #           [All] Start Menu root for the current user
    #       CSIDL_STARTUP (0x0007)
    #           [All] Start Menu "Startup" folder for the current user
    #       CSIDL_SYSTEM (0x0025)
    #           [2000/ME] System directory. Usually \Windows\System32
    #       CSIDL_TEMPLATES (0x0015)
    #           [All] Document templates directory for the current user
    #       CSIDL_WINDOWS (0x0024)
    #           [2000/ME] Windows root directory, can also be accessed via the environment variables %windir% or %SYSTEMROOT%.
    #
void
BrowseForFolder(...)
PPCODE:
    BROWSEINFO bi;
    LPITEMIDLIST retval;
    LPITEMIDLIST pidl;
    LPSHELLFOLDER pDesktopFolder;
    OLECHAR olePath[MAX_PATH];
    ULONG chEaten;
    HRESULT hr;
    int i, next_i;
    char folder[MAX_PATH];
    char *option;
    ZeroMemory(&bi, sizeof(BROWSEINFO));
    bi.pszDisplayName = folder;
    next_i = -1;
    for(i = 0; i < items; i++) {
        if(next_i == -1) {
            option = SvPV_nolen(ST(i));
            if(strcmp(option, "-owner") == 0) {
                next_i = i + 1;
                bi.hwndOwner = (HWND) handle_From(NOTXSCALL ST(next_i));
            } else if(strcmp(option, "-title") == 0) {
                next_i = i + 1;
                bi.lpszTitle = SvPV_nolen(ST(next_i));
            } else BitmaskOption("-computeronly", bi.ulFlags, BIF_BROWSEFORCOMPUTER)
            } else BitmaskOption("-domainonly", bi.ulFlags, BIF_DONTGOBELOWDOMAIN)
            } else BitmaskOption("-driveonly", bi.ulFlags, BIF_RETURNFSANCESTORS)
            } else BitmaskOption("-editbox", bi.ulFlags, BIF_EDITBOX)
            } else BitmaskOption("-folderonly", bi.ulFlags, BIF_RETURNONLYFSDIRS)
            } else BitmaskOption("-includefiles", bi.ulFlags, BIF_BROWSEINCLUDEFILES)
            } else BitmaskOption("-printeronly", bi.ulFlags, BIF_BROWSEFORPRINTER)
            } else BitmaskOption("-newui", bi.ulFlags, BIF_NEWDIALOGSTYLE)
#ifdef BIF_NONEWFOLDERBUTTON
            /* not defined on old cygwin */
            } else BitmaskOption("-nonewfolder", bi.ulFlags, BIF_NONEWFOLDERBUTTON)
#endif
            } else if(strcmp(option, "-directory") == 0) {
                next_i = i + 1;
                bi.lParam = (LPARAM) SvPV_nolen(ST(next_i));
                bi.lpfn = BrowseForFolderProc;
            } else if(strcmp(option, "-root") == 0) {
                next_i = i + 1;
                if(SvIOK(ST(next_i))) {
                    bi.pidlRoot = INT2PTR(LPCITEMIDLIST,SvIV(ST(next_i)));
                } else {
                    SHGetDesktopFolder(&pDesktopFolder);
                    MultiByteToWideChar(
                        CP_ACP,
                        MB_PRECOMPOSED,
                        SvPV_nolen(ST(next_i)), -1,
                        olePath, MAX_PATH
                    );
                    hr = pDesktopFolder->ParseDisplayName(
                    // hr = IShellFolder::ParseDisplayName(
                        NULL,
                        NULL,
                        olePath,
                        &chEaten,
                        &pidl,
                        NULL
                    );
                    if(FAILED(hr)) {
                        W32G_WARN("Win32::GUI::BrowseForFolder: can't get ITEMIDLIST for -root!");
                        pDesktopFolder->Release();
                        XSRETURN_UNDEF;
                    } else {
                        bi.pidlRoot = pidl;
                        pDesktopFolder->Release();
                    }
                }
            }
        } else {
            next_i = -1;
        }
    }
    retval = SHBrowseForFolder(&bi);
    if(retval != NULL) {
        if(SHGetPathFromIDList(retval, folder)) {
            EXTEND(SP, 1);
            XST_mPV( 0, folder);
            XSRETURN(1);
        } else {
            XSRETURN_UNDEF;
        }
    } else {
        XSRETURN_UNDEF;
    }


    ###########################################################################
    # (@)METHOD:ChooseColor(%OPTIONS)
    # Allowed B<%OPTIONS> are:
    #  -owner => WINDOW
    #      Identifies the window that owns the dialog box.
    #  -color => COLOR
    #      Initial color selected.
void
ChooseColor(...)
PPCODE:
    CHOOSECOLOR cc;
    COLORREF lpCustColors[16];
    BOOL retval;
    int i, next_i;
    char * option;

    ZeroMemory(&cc, sizeof(CHOOSECOLOR));
    cc.lStructSize = sizeof(CHOOSECOLOR);
    cc.hwndOwner = NULL;
    cc.lpCustColors = lpCustColors;
    cc.lpTemplateName = NULL;
    cc.Flags = 0;
    cc.rgbResult = 0;

    next_i = -1;
    for(i = 0; i < items; i++) {
        if(next_i == -1) {
            option = SvPV_nolen(ST(i));
            if(strcmp(option, "-owner") == 0) {
                next_i = i + 1;
                cc.hwndOwner = (HWND) handle_From(NOTXSCALL ST(next_i));
            } else if(strcmp(option, "-color") == 0) {
                next_i = i + 1;
                cc.rgbResult = (COLORREF) SvCOLORREF(NOTXSCALL ST(next_i));
                cc.Flags = cc.Flags | CC_RGBINIT;
            }
        } else {
            next_i = -1;
        }
    }

    retval = ChooseColor(&cc);

    if(retval) {
        EXTEND(SP, 1);
        XST_mIV(0, cc.rgbResult);
        XSRETURN(1);
    } else {
        XSRETURN_UNDEF;
    }


    ###########################################################################
    # (@)METHOD:ChooseFont(%OPTIONS)
    # Allowed B<%OPTIONS> are:
    #  -owner => WINDOW
    #      Identifies the window that owns the dialog box.
    #  -pointsize
    #  -height
    #  -width
    #  -escapement
    #  -orientation
    #  -weight
    #  -bold
    #  -italic
    #  -underline
    #  -strikeout
    #  -charset
    #  -outputprecision
    #  -clipprecision
    #  -quality
    #  -family
    #  -name
    #  -face (== -name)
    #  -color
    #  -ttonly
    #  -fixedonly
    #  -effects
    #  -script
    #  -minsize
    #  -maxsize
void
ChooseFont(...)
PPCODE:
    CHOOSEFONT cf;
    static LOGFONT lf;
    BOOL retval;
    int i, next_i;
    char *option;

    ZeroMemory(&cf, sizeof(CHOOSEFONT));
    cf.lStructSize = sizeof(CHOOSEFONT);
    cf.hwndOwner = NULL;
    cf.lpLogFont = &lf;
    cf.lpTemplateName = NULL;
    cf.Flags = CF_SCREENFONTS;

    next_i = -1;
    for(i = 0; i < items; i++) {
        if(next_i == -1) {
            option = SvPV_nolen(ST(i));
            if(strcmp(option, "-owner") == 0) {
                next_i = i + 1;
                cf.hwndOwner = (HWND) handle_From(NOTXSCALL ST(next_i));
            }
            if(strcmp(option, "-pointsize") == 0) {
                next_i = i + 1;
                cf.iPointSize = (INT)SvIV(ST(next_i));
            }
            if(strcmp(option, "-height") == 0) {
                HDC hDisplay;
                hDisplay = CreateDC("DISPLAY", NULL, NULL, NULL);
                next_i = i + 1;
                lf.lfHeight = -MulDiv((int)SvIV(ST(next_i)), GetDeviceCaps(hDisplay, LOGPIXELSY), 72);
                DeleteDC(hDisplay);
                SwitchBit(cf.Flags, CF_INITTOLOGFONTSTRUCT, 1);

            }
            if(strcmp(option, "-width") == 0) {
                next_i = i + 1;
                lf.lfWidth = (LONG)SvIV(ST(next_i));
                SwitchBit(cf.Flags, CF_INITTOLOGFONTSTRUCT, 1);
            }
            if(strcmp(option, "-escapement") == 0) {
                next_i = i + 1;
                lf.lfEscapement = (LONG)SvIV(ST(next_i));
                SwitchBit(cf.Flags, CF_INITTOLOGFONTSTRUCT, 1);
            }
            if(strcmp(option, "-orientation") == 0) {
                next_i = i + 1;
                lf.lfOrientation = (LONG)SvIV(ST(next_i));
                SwitchBit(cf.Flags, CF_INITTOLOGFONTSTRUCT, 1);
            }
            if(strcmp(option, "-weight") == 0) {
                next_i = i + 1;
                lf.lfWeight = (int) SvIV(ST(next_i));
                SwitchBit(cf.Flags, CF_INITTOLOGFONTSTRUCT, 1);
            }
            if(strcmp(option, "-bold") == 0) {
                next_i = i + 1;
                if(SvIV(ST(next_i)) != 0) lf.lfWeight = 700;
                SwitchBit(cf.Flags, CF_INITTOLOGFONTSTRUCT, 1);
            }
            if(strcmp(option, "-italic") == 0) {
                next_i = i + 1;
                lf.lfItalic = (BYTE) SvIV(ST(next_i));
                SwitchBit(cf.Flags, CF_INITTOLOGFONTSTRUCT, 1);
            }
            if(strcmp(option, "-underline") == 0) {
                next_i = i + 1;
                lf.lfUnderline = (BYTE) SvIV(ST(next_i));
                SwitchBit(cf.Flags, CF_INITTOLOGFONTSTRUCT, 1);
            }
            if(strcmp(option, "-strikeout") == 0) {
                next_i = i + 1;
                lf.lfStrikeOut = (BYTE) SvIV(ST(next_i));
                SwitchBit(cf.Flags, CF_INITTOLOGFONTSTRUCT, 1);
            }
            if(strcmp(option, "-charset") == 0) {
                next_i = i + 1;
                lf.lfCharSet = (BYTE) SvIV(ST(next_i));
                SwitchBit(cf.Flags, CF_INITTOLOGFONTSTRUCT, 1);
            }
            if(strcmp(option, "-outputprecision") == 0) {
                next_i = i + 1;
                lf.lfOutPrecision = (BYTE) SvIV(ST(next_i));
                SwitchBit(cf.Flags, CF_INITTOLOGFONTSTRUCT, 1);
            }
            if(strcmp(option, "-clipprecision") == 0) {
                next_i = i + 1;
                lf.lfClipPrecision = (BYTE) SvIV(ST(next_i));
                SwitchBit(cf.Flags, CF_INITTOLOGFONTSTRUCT, 1);
            }
            if(strcmp(option, "-quality") == 0) {
                next_i = i + 1;
                lf.lfQuality = (BYTE) SvIV(ST(next_i));
                SwitchBit(cf.Flags, CF_INITTOLOGFONTSTRUCT, 1);
            }
            if(strcmp(option, "-family") == 0) {
                next_i = i + 1;
                lf.lfPitchAndFamily = (BYTE) SvIV(ST(next_i));
                SwitchBit(cf.Flags, CF_INITTOLOGFONTSTRUCT, 1);
            }
            if(strcmp(option, "-name") == 0
            || strcmp(option, "-face") == 0) {
                next_i = i + 1;
                strncpy(lf.lfFaceName, SvPV_nolen(ST(next_i)), 32);
                SwitchBit(cf.Flags, CF_INITTOLOGFONTSTRUCT, 1);
            }
            if(strcmp(option, "-color") == 0) {
                next_i = i + 1;
                cf.rgbColors = (DWORD) SvCOLORREF(NOTXSCALL ST(next_i));
                SwitchBit(cf.Flags, CF_EFFECTS, 1);
            }
            if(strcmp(option, "-ttonly") == 0) {
                next_i = i + 1;
                SwitchBit(cf.Flags, CF_TTONLY, SvIV(ST(next_i)));
            }
            if(strcmp(option, "-fixedonly") == 0) {
                next_i = i + 1;
                SwitchBit(cf.Flags, CF_FIXEDPITCHONLY, SvIV(ST(next_i)));
            }
            if(strcmp(option, "-effects") == 0) {
                next_i = i + 1;
                SwitchBit(cf.Flags, CF_EFFECTS, SvIV(ST(next_i)));
            }
            if(strcmp(option, "-script") == 0) {
                next_i = i + 1;
                if(SvIV(ST(next_i)) == 0) {
                    SwitchBit(cf.Flags, CF_NOSCRIPTSEL, 1);
                } else {
                    SwitchBit(cf.Flags, CF_NOSCRIPTSEL, 0);
                }
            }
            if(strcmp(option, "-minsize") == 0) {
                next_i = i + 1;
                cf.nSizeMin = (INT)SvIV(ST(next_i));
                SwitchBit(cf.Flags, CF_LIMITSIZE, 1);
            }
            if(strcmp(option, "-maxsize") == 0) {
                next_i = i + 1;
                cf.nSizeMax = (INT)SvIV(ST(next_i));
                SwitchBit(cf.Flags, CF_LIMITSIZE, 1);
            }


        } else {
            next_i = -1;
        }
    }
    retval = ChooseFont(&cf);
    if(retval) {

        HDC hDisplay;
        hDisplay = CreateDC("DISPLAY", NULL, NULL, NULL);
        lf.lfHeight = -MulDiv(lf.lfHeight, 72, GetDeviceCaps(hDisplay, LOGPIXELSY));
        DeleteDC(hDisplay);
 
        EXTEND(SP, 18);
        XST_mPV( 0, "-name");
        XST_mPV( 1, lf.lfFaceName);
        XST_mPV( 2, "-height");
        XST_mIV( 3, lf.lfHeight);
        XST_mPV( 4, "-width");
        XST_mIV( 5, lf.lfWidth);
        XST_mPV( 6, "-weight");
        XST_mIV( 7, lf.lfWeight);
        XST_mPV( 8, "-pointsize");
        XST_mIV( 9, cf.iPointSize);
        XST_mPV(10, "-italic");
        XST_mIV(11, lf.lfItalic);
        XST_mPV(12, "-underline");
        XST_mIV(13, lf.lfUnderline);
        XST_mPV(14, "-strikeout");
        XST_mIV(15, lf.lfStrikeOut);
        XST_mPV(16, "-color");
        XST_mIV(17, cf.rgbColors);
        // XST_mPV(18, "-style");
        // XST_mPV(19, cf.lpszStyle);
        // XSRETURN(20);
        XSRETURN(18);
    } else
        XSRETURN_UNDEF;


    ###########################################################################
    # (@)METHOD:CommDlgExtendedError()
    # Returns the common dialog library error code.
DWORD
CommDlgExtendedError(...)
CODE:
    RETVAL = CommDlgExtendedError();
OUTPUT:
    RETVAL


HGDIOBJ
SelectObject(handle,hgdiobj)
    HDC handle
    HGDIOBJ hgdiobj
CODE:
    RETVAL = SelectObject(handle, hgdiobj);
OUTPUT:
    RETVAL

BOOL
DeleteObject(hgdiobj)
    HGDIOBJ hgdiobj
CODE:
    RETVAL = DeleteObject(hgdiobj);
OUTPUT:
    RETVAL


    ###########################################################################
    # (@)METHOD:GetStockObject(OBJECT)
    # Returns the handle of the specified predefined system object (pen, brush
    # or font). 
    #
    # B<OBJECT> can have one of the following values:
    #   0 WHITE_BRUSH
    #   1 GRAY_BRUSH
    #   2 LTGRAY_BRUSH
    #   3 DKGRAY_BRUSH
    #   4 BLACK_BRUSH
    #   5 NULL_BRUSH (also HOLLOW_BRUSH)
    #   6 WHITE_PEN
    #   7 BLACK_PEN
    #   8 NULL_PEN
    #  10 OEM_FIXED_FONT
    #  11 ANSI_FIXED_FONT
    #  12 ANSI_VAR_FONT
    #  13 SYSTEM_FONT
    #  14 DEVICE_DEFAULT_FONT
    #  15 DEFAULT_PALETTE
    #  16 SYSTEM_FIXED_FONT
    #  17 DEFAULT_GUI_FONT
    #  18 DC_BRUSH (Windows 2000/XP only)
    #  19 DC_PEN (Windows 2000/XP only)
    #
    # The returned handle can be referenced as if it was a Win32::GUI object
    # (eg. a Win32::GUI::Brush or Win32::GUI::Font), but note that it is not
    # blessed, so you can't directly invoke methods on it:
    #
    #    $Font = Win32::GUI::GetStockObject(17);    # DEFAULT_GUI_FONT
    #    print $Font->GetMetrics();                 # !!!WRONG!!!
    #    print Win32::GUI::Font::GetMetrics($Font); # correct
    #    $Window->SetFont($Font);                   # correct
HGDIOBJ
GetStockObject(object)
    int object
CODE:
    RETVAL = GetStockObject(object);
OUTPUT:
    RETVAL

    ###########################################################################
    # Accelerator
    ###########################################################################

    ###########################################################################
    # (@)INTERNAL:CreateAcceleratorTable(ID, KEY, FLAG, ...)
HACCEL
CreateAcceleratorTable(...)
PREINIT:
    LPACCEL acc;
    int a, c, i;
CODE:
    a = items/3;
    acc = (LPACCEL) safemalloc(a * sizeof(ACCEL));
    c = 0;
    for(i=0; i<items; i+=3) {
        acc[c].cmd   = (WORD) SvIV(ST(i));
        acc[c].key   = (WORD) SvIV(ST(i+1));
        acc[c].fVirt = (BYTE) SvIV(ST(i+2));
        c++;
    }
    RETVAL = CreateAcceleratorTable(acc, a);
OUTPUT:
    RETVAL


    ###########################################################################
    # (@)INTERNAL:DestroyAcceleratorTable(HANDLE)
BOOL
DestroyAcceleratorTable(handle)
    HACCEL handle;
CODE:
    RETVAL = DestroyAcceleratorTable(handle);
OUTPUT:
    RETVAL


    ###########################################################################
    # Menu
    ###########################################################################


    ###########################################################################
    # (@)INTERNAL:CreateMenu()
HMENU
CreateMenu(...)
CODE:
    RETVAL = CreateMenu();
OUTPUT:
    RETVAL


    ###########################################################################
    # (@)INTERNAL:CreatePopupMenu()
HMENU
CreatePopupMenu(...)
CODE:
    RETVAL = CreatePopupMenu();
OUTPUT:
    RETVAL


    ###########################################################################
    # (@)METHOD:SetMenu(MENU)
    # Associates the specified MENU to a window.
BOOL
SetMenu(handle,menu)
    HWND handle
    HMENU menu
CODE:
    RETVAL = SetMenu(handle, menu);
OUTPUT:
    RETVAL


    ###########################################################################
    # (@)METHOD:GetMenu()
    # Returns the handle of the menu associated with the window.
HMENU
GetMenu(handle)
    HWND handle
CODE:
    RETVAL = GetMenu(handle);
OUTPUT:
    RETVAL


    ###########################################################################
    # (@)METHOD:DrawMenuBar()
    # Forces redrawing of the menu bar.
BOOL
DrawMenuBar(handle)
    HWND handle
CODE:
    RETVAL = DrawMenuBar(handle);
OUTPUT:
    RETVAL


    ###########################################################################
    # (@)INTERNAL:DestroyMenu(HANDLE)
BOOL
DestroyMenu(hmenu)
    HMENU hmenu
CODE:
    RETVAL = DestroyMenu(hmenu);
OUTPUT:
    RETVAL


    ###########################################################################
    # (@)INTERNAL:GetDllVersion(DLLNAME)
    # Replacement for Win32::GetFileVersion, which doesn't exist in perl 5.6 or
    # cygwin perl 5.8
    # In scalar contect returns dotted string of dll version
    # In list context returns major version, minor version, build
void
GetDllVersion(filename)
    LPTSTR filename
PREINIT:
    HINSTANCE hinstDll;
    DWORD major = 0xFFFFFFFF;
    DWORD minor = 0xFFFFFFFF;
    DWORD build = 0xFFFFFFFF;
PPCODE:
    hinstDll = LoadLibrary(filename);

    if(hinstDll) {
        DLLGETVERSIONPROC pDllGetVersion;
        pDllGetVersion = (DLLGETVERSIONPROC)GetProcAddress(hinstDll,"DllGetVersion");

        if(pDllGetVersion) {
            DLLVERSIONINFO dvi;
            HRESULT hr;

            ZeroMemory(&dvi, sizeof(dvi));
            dvi.cbSize = sizeof(dvi);

            hr = (*pDllGetVersion)(&dvi);
    
            if(SUCCEEDED(hr)) {
                major = dvi.dwMajorVersion;
                minor = dvi.dwMinorVersion;
                build = dvi.dwBuildNumber;
            }
        }

        FreeLibrary(hinstDll);
    }

    if(major == 0xFFFFFFFF) {
        DWORD size;
        DWORD handle;
        char *data;

        size = GetFileVersionInfoSize(filename, &handle);
        if(size) {
            New(0, data, size, char);
            if(data) {
                if(GetFileVersionInfo(filename, handle, size, data)) {
                    VS_FIXEDFILEINFO *info;
                    UINT len;
                    if(VerQueryValue(data, "\\", (void**)&info, &len)) {
                        major = (info->dwFileVersionMS>>16);
                        minor = (info->dwFileVersionMS&0xffff);
                        build = (info->dwFileVersionLS>>16);
		    }
		}

                Safefree(data);
	    }
	}
    }

    if(major == 0xFFFFFFFF) {
	    XSRETURN_UNDEF;
    }

    if (GIMME_V == G_ARRAY) {
        EXTEND(SP, 3);
        XST_mIV(0, major);
        XST_mIV(1, minor);
        XST_mIV(2, build);
	items = 3;
    }
    else {
       char version[50];
       sprintf(version, "%d.%d.%d", major, minor, build);
       XST_mPV(0, version);
       items = 1;
    }
    XSRETURN(items);


    ###########################################################################
    # (@)PACKAGE:Win32::GUI::Menu
    ###########################################################################

MODULE = Win32::GUI     PACKAGE = Win32::GUI::Menu


#pragma message( "*** PACKAGE Win32::GUI::Menu..." )

    ###########################################################################
    # (@)METHOD:RemoveMenu(position, [flags=MF_BYPOSITION])
    # The RemoveMenu function deletes a menu item or detaches a submenu from the
    # specified menu. If the menu item opens a drop-down menu or submenu, RemoveMenu
    # does not destroy the menu or its handle, allowing the menu to be reused
    #
    # position specifies the menu item to be removed, as determined by the flags field.
    #
    # flags specifies how the position field is interpreted, and can take one of the
    # following values:
    #   MF_BYCOMMAND  (0x0000): Indicates that position gives the identifier of the menu item
    #   MF_BYPOSITION (0x0400): Indicates that position gives the zero-based relative position of the menu item.
    # If flags is not supplied, then MF_BYPOSITION is used as the default
BOOL
RemoveMenu(menu, position, flags=MF_BYPOSITION)
  HMENU menu
  UINT position
  UINT flags
CODE:
    RETVAL = RemoveMenu(menu, position, flags);
OUTPUT:
    RETVAL

    ###########################################################################
    # (@)INTERNAL:DESTROY(HANDLE)
BOOL
DESTROY(handle)
    HMENU handle
CODE:
    RETVAL = DestroyMenu(handle);
OUTPUT:
    RETVAL


    ###########################################################################
    # (@)PACKAGE:Win32::GUI::MenuButton
    ###########################################################################

MODULE = Win32::GUI     PACKAGE = Win32::GUI::MenuButton

#pragma message( "*** PACKAGE Win32::GUI::MenuButton..." )

    ###########################################################################
    # (@)INTERNAL:InsertMenuItem(HANDLE, %OPTIONS)
void
InsertMenuItem(...)
PREINIT:
    MENUITEMINFO mii;
    LPPERLWIN32GUI_MENUITEMDATA perlmid;
    UINT myItem;
    BOOL RETVAL;
PPCODE:
    ZeroMemory(&mii, sizeof(MENUITEMINFO));
    mii.cbSize = sizeof(MENUITEMINFO);
    myItem = 0;
    Newz(0, perlmid, 1, PERLWIN32GUI_MENUITEMDATA);
    perlmid->dwSize = sizeof(PERLWIN32GUI_MENUITEMDATA);
    perlmid->svCode = newSVsv(&PL_sv_undef);
    ParseMenuItemOptions(NOTXSCALL sp, mark, ax, items, 1, &mii, perlmid, &myItem);
    mii.hbmpChecked = NULL;
    mii.hbmpUnchecked = NULL;
#ifdef PERLWIN32GUI_STRONGDEBUG
    printf("XS(InsertMenuItem) doing InsertMenuItem (HMENU=0x%x)...\n", handle_From(NOTXSCALL ST(0)));
#endif
    RETVAL = InsertMenuItem(
        (HMENU) handle_From(NOTXSCALL ST(0)),
        myItem,
        FALSE,
        &mii
    );
#ifdef PERLWIN32GUI_STRONGDEBUG
    printf("XS(InsertMenuItem) done InsertMenuItem (RETVAL=%d)\n", RETVAL);
#endif
    XSRETURN_IV(RETVAL);


    ###########################################################################
    # (@)PACKAGE:Win32::GUI::MenuItem
    ###########################################################################

MODULE = Win32::GUI     PACKAGE = Win32::GUI::MenuItem

#pragma message( "*** PACKAGE Win32::GUI::MenuItem..." )

    ###########################################################################
    # (@)METHOD:Change(%OPTIONS)
    # Change most of the options used when the object was created.
void
Change(...)
PPCODE:
    MENUITEMINFO myMII;
    LPPERLWIN32GUI_MENUITEMDATA perlmid;
    UINT myItem;
    HMENU hMenu;
    SV** parentmenu;
    char tmpmenutext[1024];
    if(SvROK(ST(0))) {
        parentmenu = hv_fetch((HV*)SvRV((ST(0))), "-menu", 5, 0);
        if(parentmenu != NULL) {
            hMenu = INT2PTR(HMENU,SvIV(*parentmenu));
            myItem = (UINT)SvIV(*(hv_fetch((HV*)SvRV(ST(0)), "-id", 3, 0)));
        } else {
            hMenu = (HMENU) handle_From(NOTXSCALL ST(0));
        }
    }
#ifdef PERLWIN32GUI_DEBUG
        printf("XS(MenuItem::Change): hMenu=0x%x, myItem=%d\n", hMenu, myItem);
#endif
    ZeroMemory(&myMII, sizeof(MENUITEMINFO));
    myMII.cbSize = sizeof(MENUITEMINFO);
    myMII.fMask = MIIM_STATE | MIIM_SUBMENU | MIIM_TYPE | MIIM_DATA;
    myMII.dwTypeData = tmpmenutext;
    myMII.cch = 1024;
    if(GetMenuItemInfo(hMenu, myItem, FALSE, &myMII)) {
        perlmid = (LPPERLWIN32GUI_MENUITEMDATA) myMII.dwItemData;
        myMII.fMask = 0;
        ParseMenuItemOptions(NOTXSCALL sp, mark, ax, items, 1, &myMII, perlmid, &myItem);
        myMII.hbmpChecked = NULL;
        myMII.hbmpUnchecked = NULL;
        XSRETURN_IV(
            SetMenuItemInfo(hMenu, myItem, FALSE, &myMII)
        );
    } else
        XSRETURN_UNDEF;


    ###########################################################################
    # (@)METHOD:Checked(...)
    # Set or Retrieve Checked state of a menu item.
void
Checked(...)
PPCODE:
    MENUITEMINFO myMII;
    int i;
    UINT myItem;
    HMENU hMenu;
    SV** parentmenu;

    if(SvROK(ST(0))) {
        parentmenu = hv_fetch((HV*)SvRV((ST(0))), "-menu", 5, 0);
        if(parentmenu != NULL) {
            hMenu = INT2PTR(HMENU,SvIV(*parentmenu));
            myItem = (UINT)SvIV(*(hv_fetch((HV*)SvRV(ST(0)), "-id", 3, 0)));
            i = 1;
        } else {
            hMenu = (HMENU) handle_From(NOTXSCALL ST(0));
            myItem = (UINT)SvIV(ST(1));
            i = 2;
        }
    }
    ZeroMemory(&myMII, sizeof(MENUITEMINFO));
    myMII.cbSize = sizeof(MENUITEMINFO);
    myMII.fMask = MIIM_STATE;
    if(GetMenuItemInfo(hMenu, myItem, FALSE, &myMII)) {
        if(items > i) {
            myMII.fMask = MIIM_STATE;
            SwitchBit(myMII.fState, MFS_CHECKED, SvIV(ST(i)));
            XSRETURN_IV(
                SetMenuItemInfo(hMenu, myItem, FALSE, &myMII)
            );
        } else {
            XSRETURN_IV((myMII.fState & MFS_CHECKED) ? 1 : 0);
        }
    } else {
        XSRETURN_UNDEF;
    }


    ###########################################################################
    # (@)METHOD:Enabled([FLAG])
    # Set or Retrieve Enabled state of a menu item.
    #
    # B<FLAG> is a boolean.  If supplied sets the state of the menu item
    # (0 = Disabled, 1 = Eabled).  If not supplied, retrieves the enabled
    # state if the menu item.
    #
void
Enabled(...)
PPCODE:
    MENUITEMINFO myMII;
    int i, x;
    UINT myItem;
    HMENU hMenu;
    SV** parentmenu;

    if(SvROK(ST(0))) {
        parentmenu = hv_fetch((HV*)SvRV((ST(0))), "-menu", 5, 0);
        if(parentmenu != NULL) {
            hMenu = INT2PTR(HMENU,SvIV(*parentmenu));
            myItem = (UINT)SvIV(*(hv_fetch((HV*)SvRV(ST(0)), "-id", 3, 0)));
            i = 1;
        } else {
            hMenu = (HMENU) handle_From(NOTXSCALL ST(0));
            myItem = (UINT)SvIV(ST(1));
            i = 2;
        }
    }
    ZeroMemory(&myMII, sizeof(MENUITEMINFO));
    myMII.cbSize = sizeof(MENUITEMINFO);
    myMII.fMask = MIIM_STATE;
    if(GetMenuItemInfo(hMenu, myItem, FALSE, &myMII)) {
        if(items > i) {
            myMII.fMask = MIIM_STATE;
            x = (SvIV(ST(i))) ? 0 : 1;
            SwitchBit(myMII.fState, MFS_DISABLED, x);
            XSRETURN_IV(
                SetMenuItemInfo(hMenu, myItem, FALSE, &myMII)
            );
        } else {
            XSRETURN_IV((myMII.fState & MFS_DISABLED) ? 0 : 1);
        }
    } else {
        XSRETURN_UNDEF;
    }



BOOT:
    {
        INITCOMMONCONTROLSEX icce;
        icce.dwSize = sizeof(INITCOMMONCONTROLSEX);
        icce.dwICC = ICC_ANIMATE_CLASS | ICC_BAR_CLASSES | ICC_COOL_CLASSES
                   | ICC_LISTVIEW_CLASSES | ICC_PROGRESS_CLASS
                   | ICC_TAB_CLASSES | ICC_TREEVIEW_CLASSES
                   | ICC_UPDOWN_CLASS | ICC_USEREX_CLASSES
                   | ICC_DATE_CLASSES;
        if(!InitCommonControlsEx(&icce)) {
            warn("Win32::GUI: Unable to init common controls!\n");
        }
    }

