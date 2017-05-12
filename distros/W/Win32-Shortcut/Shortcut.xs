/*
 * Shortcut.CPP
 * 15 Jan 97 by Aldo Calpini <dada@perl.it>
 *
 * XS interface to the Win32 IShellLink Interface
 * based on Registry.CPP written by Jesse Dougherty
 *
 * Version: 0.03 07 Apr 97
 *
 */

#define  WIN32_LEAN_AND_MEAN
#include <stdlib.h>
#include <math.h>
#include <windows.h>

#include <shlobj.h>
#include <shlguid.h>
#include <objbase.h>

#if defined(__cplusplus)
extern "C" {
#endif
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"
#if defined(__cplusplus)
}
#endif

#ifndef _WIN64
#  define DWORD_PTR	DWORD
#endif

// Section for the constant definitions.
#define CROAK croak
#define MAX_LENGTH 2048
#define TMPBUFSZ 1024


DWORD
constant(char *name, int arg)
{
    errno = 0;
    switch (*name) {
    case 'A':
		break;
    case 'B':
		break;
	case 'C':
		break;
    case 'D':
		break;
    case 'E':
		break;
    case 'F':
		break;
    case 'G':
		break;
    case 'H':
		break;
    case 'I':
		break;
    case 'J':
		break;
    case 'K':
		break;
    case 'L':
		break;
    case 'M':
		break;
    case 'N':
		break;
    case 'O':
		break;
    case 'P':
		break;
    case 'Q':
		break;
    case 'R':
		break;
    case 'S':
		if (strncmp(name, "SLGP_", 5) == 0)
			switch(name[5]) {	
			case 'S':
				if (strEQ(name, "SLGP_SHORTPATH"))
					#ifdef SLGP_SHORTPATH
						return SLGP_SHORTPATH;
					#else
						goto not_there;
					#endif
				break;
			case 'U':
				if (strEQ(name, "SLGP_UNCPRIORITY"))
					#ifdef SLGP_UNCPRIORITY
						return SLGP_UNCPRIORITY;
					#else
						goto not_there;
					#endif
				break;
			}
		if (strncmp(name, "SW_", 3) == 0)
			switch(name[3]) {	
			case 'H':
				if (strEQ(name, "SW_HIDE"))
					#ifdef SW_HIDE
						return SW_HIDE;
					#else
						goto not_there;
					#endif
				break;
			case 'M':
				if (strEQ(name, "SW_MINIMIZE"))
					#ifdef SW_MINIMIZE
						return SW_MINIMIZE;
					#else
						goto not_there;
					#endif
				break;
			case 'R':
				if (strEQ(name, "SW_RESTORE"))
					#ifdef SW_RESTORE
						return SW_RESTORE;
					#else
						goto not_there;
					#endif
				break;
			case 'S':
				if (strEQ(name, "SW_SHOW"))
					#ifdef SW_SHOW
						return SW_SHOW;
					#else
						goto not_there;
					#endif
				if (strEQ(name, "SW_SHOWMAXIMIZED"))
					#ifdef SW_SHOWMAXIMIZED
						return SW_SHOWMAXIMIZED;
					#else
						goto not_there;
					#endif
				if (strEQ(name, "SW_SHOWMINIMIZED"))
					#ifdef SW_SHOWMINIMIZED
						return SW_SHOWMINIMIZED;
					#else
						goto not_there;
					#endif
				if (strEQ(name, "SW_SHOWMINNOACTIVE"))
					#ifdef SW_SHOWMINNOACTIVE
						return SW_SHOWMINNOACTIVE;
					#else
						goto not_there;
					#endif
				if (strEQ(name, "SW_SHOWNA"))
					#ifdef SW_SHOWNA
						return SW_SHOWNA;
					#else
						goto not_there;
					#endif
				if (strEQ(name, "SW_SHOWNOACTIVE"))
					#ifdef SW_SHOWNOACTIVE
						return SW_SHOWNOACTIVE;
					#else
						goto not_there;
					#endif
				if (strEQ(name, "SW_SHOWNORMAL"))
					#ifdef SW_SHOWNORMAL
						return SW_SHOWNORMAL;
					#else
						goto not_there;
					#endif
				break;
			}
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

MODULE = Win32::Shortcut	PACKAGE = Win32::Shortcut

PROTOTYPES: DISABLE

BOOT:
    CoInitialize(NULL);

long
constant(name,arg)
    char *name
    int arg
CODE:
    RETVAL = constant(name, arg);
OUTPUT:
    RETVAL


void
_Instance(...)
PPCODE:
    HRESULT hres;
    IShellLink* ilink;

    hres = CoCreateInstance(CLSID_ShellLink, NULL, CLSCTX_INPROC_SERVER,
                              IID_IShellLink, (void **) &ilink);
    EXTEND(SP,2);
    if (SUCCEEDED(hres)) {
	IPersistFile* ifile;
	hres = ilink->QueryInterface(IID_IPersistFile, (void **) &ifile);
	if (SUCCEEDED(hres)) {
	    ST(0)=sv_2mortal(newSViv((DWORD_PTR) ilink));
	    ST(1)=sv_2mortal(newSViv((DWORD_PTR) ifile));
	    XSRETURN(2);
	}
	XSRETURN_NO;
    }
    XSRETURN_NO;


void
_Release(ilink,ifile)
    IShellLink * ilink
    IPersistFile * ifile
PPCODE:
    ifile->Release();
    ilink->Release();
    XSRETURN_YES;


void
_SetDescription(ilink,ifile,description)
    IShellLink * ilink
    IPersistFile * ifile
    LPCSTR description
PPCODE:
    HRESULT hres;
    hres = ilink->SetDescription(description);
    if (SUCCEEDED(hres))
	XSRETURN_YES;
    else
	XSRETURN_NO;


void
_GetDescription(ilink,ifile)
    IShellLink * ilink
    IPersistFile * ifile
PPCODE:
    HRESULT hres;
    char description[1024];
    hres = ilink->GetDescription(description, 1024);
    if (SUCCEEDED(hres))
	XSRETURN_PV(description);
    else
	XSRETURN_NO;


void
_SetPath(ilink,ifile,path)
    IShellLink * ilink
    IPersistFile * ifile
    LPCSTR path
PPCODE:
    HRESULT hres;
    hres = ilink->SetPath(path);
    if (SUCCEEDED(hres))
	XSRETURN_YES;
    else
	XSRETURN_NO;

void
_GetPath(ilink,ifile,flags)
    IShellLink * ilink
    IPersistFile * ifile
    DWORD flags
PPCODE:
    HRESULT hres;
    char path[MAX_PATH];
    WIN32_FIND_DATA file;

    hres = ilink->GetPath((LPSTR) path, MAX_PATH, &file, flags);
    if (SUCCEEDED(hres))
	XSRETURN_PV(path);
    else
	XSRETURN_NO;


void
_SetArguments(ilink,ifile,arguments)
    IShellLink * ilink
    IPersistFile * ifile
    LPCSTR arguments
PPCODE:
    HRESULT hres;
    hres=ilink->SetArguments(arguments);
    if (SUCCEEDED(hres))
	XSRETURN_YES;
    else
	XSRETURN_NO;


void
_GetArguments(ilink,ifile)
    IShellLink * ilink
    IPersistFile * ifile
PPCODE:
    HRESULT hres;
    char arguments[1024];
    hres = ilink->GetArguments((LPSTR) arguments, 1024);
    if (SUCCEEDED(hres))
	XSRETURN_PV(arguments);
    else
	XSRETURN_NO;


void
_SetWorkingDirectory(ilink,ifile,dir)
    IShellLink * ilink
    IPersistFile * ifile
    LPCSTR dir
PPCODE:
    HRESULT hres;
    hres = ilink->SetWorkingDirectory(dir);
    if (SUCCEEDED(hres))
	XSRETURN_YES;
    else
	XSRETURN_NO;


void
_GetWorkingDirectory(ilink,ifile)
    IShellLink * ilink
    IPersistFile * ifile
PPCODE:
    HRESULT hres;
    char dir[MAX_PATH];
    hres = ilink->GetWorkingDirectory((LPSTR) dir, MAX_PATH);
    if (SUCCEEDED(hres))
	XSRETURN_PV(dir);
    else
	XSRETURN_NO;


void
_SetShowCmd(ilink,ifile,flag)
    IShellLink * ilink
    IPersistFile * ifile
    int flag
PPCODE:
    HRESULT hres;
    hres = ilink->SetShowCmd(flag);
    if (SUCCEEDED(hres))
	XSRETURN_YES;
    else
	XSRETURN_NO;


void
_GetShowCmd(ilink,ifile)
    IShellLink * ilink
    IPersistFile * ifile
PPCODE:
    HRESULT hres;
    int show;
    hres = ilink->GetShowCmd(&show);
    if (SUCCEEDED(hres))
	XSRETURN_IV(show);
    else
	XSRETURN_NO;


void
_SetHotkey(ilink,ifile,hotkey)
    IShellLink * ilink
    IPersistFile * ifile
    unsigned short hotkey
PPCODE:
    HRESULT hres;
    hres = ilink->SetHotkey(hotkey);
    if (SUCCEEDED(hres))
	XSRETURN_YES;
    else
	XSRETURN_NO;


void
_GetHotkey(ilink,ifile)
    IShellLink * ilink
    IPersistFile * ifile
PPCODE:
    HRESULT hres;
    unsigned short hotkey;
    hres = ilink->GetHotkey(&hotkey);
    if (SUCCEEDED(hres))
	XSRETURN_IV(hotkey);
    else
	XSRETURN_NO;


void
_SetIconLocation(ilink,ifile,location,number)
    IShellLink * ilink
    IPersistFile * ifile
    char * location
    int number
PPCODE:
    HRESULT hres;
    hres=ilink->SetIconLocation(location,number);
    if (SUCCEEDED(hres))
	XSRETURN_YES;
    else
	XSRETURN_NO;


void
_GetIconLocation(ilink,ifile)
    IShellLink * ilink
    IPersistFile * ifile
PPCODE:
    HRESULT hres;
    int number;
    char location[MAX_PATH];
    hres = ilink->GetIconLocation((LPSTR)location, MAX_PATH, &number);
    if (SUCCEEDED(hres)) {
	// [dada] does actually returns nothing?
	// printf("_GetIconLocation: location=\"%s\",%d\n",location,number);
	XST_mPV(0,location);
	XST_mIV(1,number);
	XSRETURN(2);
    }
    else {
	XSRETURN_NO;
    }


void
_Resolve(ilink,ifile,flags)
    IShellLink * ilink
    IPersistFile * ifile
    long flags
PPCODE:
    HRESULT hres;
    // [dada] hwnd=NULL, not sure about it...
    hres = ilink->Resolve(NULL, flags);
    if (SUCCEEDED(hres)) {
	char path[MAX_PATH];
	WIN32_FIND_DATA file;
	hres = ilink->GetPath((LPSTR)path, MAX_PATH, &file, 0);
	if (SUCCEEDED(hres))
	    XSRETURN_PV(path);
	else
	    XSRETURN_NO;
    }
    else
	XSRETURN_NO;


void
_Save(ilink,ifile,filename)
    IShellLink * ilink
    IPersistFile * ifile
    LPSTR filename
PPCODE:
    HRESULT hres;
    unsigned short wfilename[MAX_PATH];
    MultiByteToWideChar(CP_ACP, 0, filename, -1, (wchar_t *)wfilename, MAX_PATH);
    hres = ifile->Save((wchar_t *)wfilename, TRUE);
    if (SUCCEEDED(hres))
	XSRETURN_YES;
    else
	XSRETURN_NO;


void
_Load(ilink,ifile,filename)
    IShellLink * ilink
    IPersistFile * ifile
    LPSTR filename
PPCODE:
    HRESULT hres;
    unsigned short wfilename[MAX_PATH];
    MultiByteToWideChar(CP_ACP, 0, filename, -1, (wchar_t *)wfilename, MAX_PATH);
    hres = ifile->Load((wchar_t *)wfilename, STGM_READ);
    if (SUCCEEDED(hres))
	XSRETURN_YES;
    else
	XSRETURN_NO;


void
_Exit(...)
PPCODE:
    CoUninitialize();
    XSRETURN_YES;
 

