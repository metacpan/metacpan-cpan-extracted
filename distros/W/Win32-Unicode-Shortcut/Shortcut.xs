#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "ppport.h"

#define PERL_NO_GET_CONTEXT     /* we want efficiency */
#define COBJMACROS
#define WIN32_LEAN_AND_MEAN	/* Tell windows.h to skip much */
#include <windows.h>
#include <shlobj.h>
#include <shlguid.h>
#include <objbase.h>
#define null_arg(sv)	(  SvROK(sv)  &&  SVt_PVAV == SvTYPE(SvRV(sv))	\
			   &&  -1 == av_len((AV*)SvRV(sv))  )

#ifndef MAX_PATHW
#define	MAX_PATHW 32767
#endif

#define MY_MAX_PATHW MAX_PATHW

/* Copied from http://www.ooportal.com/basic-com-programming/module3/win32-apiFunction-formatMessage.php */
#define EBUF_SIZ 2048
static void
ComErrorMsg(int croak_on_error, char *from, HRESULT hr) {
  TCHAR ebuf[EBUF_SIZ];
  
  if (! croak_on_error) {
    return;
  }
  
  FormatMessage(FORMAT_MESSAGE_FROM_SYSTEM,
		NULL,
		hr,
		0,
		ebuf,
		EBUF_SIZ * sizeof(TCHAR),
		NULL);
  
  croak("%s, %s", from, ebuf);
}      

/* Convert SV to wide character string.  The return value must be
 * freed using Safefree().
 * (Taken from Win32.xs)
 */
static WCHAR*
sv_to_wstr(pTHX_ SV *sv)
{
  DWORD wlen;
  WCHAR *wstr;
  STRLEN len;
  char *str = SvPV(sv, len);
  UINT cp = SvUTF8(sv) ? CP_UTF8 : CP_ACP;
  
  wlen = MultiByteToWideChar(cp, 0, str, (int)(len+1), NULL, 0);
  New(0, wstr, wlen, WCHAR);
  MultiByteToWideChar(cp, 0, str, (int)(len+1), wstr, wlen);
  
  return wstr;
}

/* Convert wide character string to mortal SV.  Use UTF8 encoding
 * if the string cannot be represented in the system codepage.
 * (Taken from Win32.xs)
 */
static SV *
wstr_to_sv(pTHX_ WCHAR *wstr)
{
  int wlen = (int)wcslen(wstr)+1;
  BOOL use_default = FALSE;
  int len = WideCharToMultiByte(CP_ACP, WC_NO_BEST_FIT_CHARS, wstr, wlen, NULL, 0, NULL, NULL);
  SV *sv = sv_2mortal(newSV(len));
  
  len = WideCharToMultiByte(CP_ACP, WC_NO_BEST_FIT_CHARS, wstr, wlen, SvPVX(sv), len, NULL, &use_default);
  if (use_default) {
    len = WideCharToMultiByte(CP_UTF8, 0, wstr, wlen, NULL, 0, NULL, NULL);
    sv_grow(sv, len);
    len = WideCharToMultiByte(CP_UTF8, 0, wstr, wlen, SvPVX(sv), len, NULL, NULL);
    SvUTF8_on(sv);
  }
  /* Shouldn't really ever fail since we ask for the required length first, but who knows... */
  if (len) {
    SvPOK_on(sv);
    SvCUR_set(sv, len-1);
  }
  return sv;
}

DWORD
constant(char *name)
{
  errno = 0;
  switch (*name) {
  case 'A':
    break;
  case 'B':
    break;
  case 'C':
    if (strEQ(name, "COINIT_APARTMENTTHREADED")) {
      return COINIT_APARTMENTTHREADED;
    } else if (strEQ(name, "COINIT_MULTITHREADED")) {
      return COINIT_MULTITHREADED;
    } else if (strEQ(name, "COINIT_DISABLE_OLE1DDE")) {
      return COINIT_DISABLE_OLE1DDE;
    } else if (strEQ(name, "COINIT_SPEED_OVER_MEMORY")) {
	    return COINIT_SPEED_OVER_MEMORY;
    }
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
    if (strncmp(name, "SLGP_", 5) == 0) {
      switch(name[5]) {
      case 'S':
	if (strEQ(name, "SLGP_SHORTPATH")) {
#ifdef SLGP_SHORTPATH
	  return SLGP_SHORTPATH;
#else
	  goto not_there;
#endif
	}
	break;
      case 'U':
	if (strEQ(name, "SLGP_UNCPRIORITY")) {
#ifdef SLGP_UNCPRIORITY
	  return SLGP_UNCPRIORITY;
#else
	  goto not_there;
#endif
	  break;
	}
      }
    }
    if (strncmp(name, "SW_", 3) == 0) {
      switch(name[3]) {
      case 'H':
	if (strEQ(name, "SW_HIDE")) {
#ifdef SW_HIDE
	  return SW_HIDE;
#else
	  goto not_there;
#endif
	}
	break;
      case 'M':
	if (strEQ(name, "SW_MINIMIZE")) {
#ifdef SW_MINIMIZE
	  return SW_MINIMIZE;
#else
	  goto not_there;
#endif
	}
	break;
      case 'R':
	if (strEQ(name, "SW_RESTORE")) {
#ifdef SW_RESTORE
	  return SW_RESTORE;
#else
	  goto not_there;
#endif
	}
	break;
      case 'S':
	if (strEQ(name, "SW_SHOW")) {
#ifdef SW_SHOW
	  return SW_SHOW;
#else
	  goto not_there;
#endif
	}
	else if (strEQ(name, "SW_SHOWMAXIMIZED")) {
#ifdef SW_SHOWMAXIMIZED
	  return SW_SHOWMAXIMIZED;
#else
	  goto not_there;
#endif
	} else if (strEQ(name, "SW_SHOWMINIMIZED")) {
#ifdef SW_SHOWMINIMIZED
	  return SW_SHOWMINIMIZED;
#else
	  goto not_there;
#endif
	} else if (strEQ(name, "SW_SHOWMINNOACTIVE")) {
#ifdef SW_SHOWMINNOACTIVE
	  return SW_SHOWMINNOACTIVE;
#else
	  goto not_there;
#endif
	} else if (strEQ(name, "SW_SHOWNA")) {
#ifdef SW_SHOWNA
	  return SW_SHOWNA;
#else
	  goto not_there;
#endif
	} else if (strEQ(name, "SW_SHOWNOACTIVE")) {
#ifdef SW_SHOWNOACTIVE
	  return SW_SHOWNOACTIVE;
#else
	  goto not_there;
#endif
	} else if (strEQ(name, "SW_SHOWNORMAL")) {
#ifdef SW_SHOWNORMAL
	  return SW_SHOWNORMAL;
#else
	  goto not_there;
#endif
	}
	break;
      }
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

MODULE = Win32::Unicode::Shortcut		PACKAGE = Win32::Unicode::Shortcut		

PROTOTYPES: DISABLE

long
constant(name)
    char *name
INIT:
  DWORD val = constant(name);
    if ((val <= 0) && (errno == EINVAL || errno == ENOENT)) {
      XSRETURN_UNDEF;
    }
CODE:
    RETVAL = val;
OUTPUT:
    RETVAL

void
_Instance(croak_on_error)
    int croak_on_error
PPCODE:
    HRESULT hres;
    IShellLinkW* ilink;

    hres = CoCreateInstance(&CLSID_ShellLink, NULL, CLSCTX_INPROC_SERVER,
			    &IID_IShellLinkW, (LPVOID *)&ilink);
    EXTEND(SP,2);
    if (SUCCEEDED(hres)) {
      IPersistFile* ifile;
      hres = IShellLinkW_QueryInterface(ilink, &IID_IPersistFile, (LPVOID *)&ifile);
      if (SUCCEEDED(hres)) {
	ST(0)=sv_2mortal(newSViv((DWORD_PTR) ilink));
	ST(1)=sv_2mortal(newSViv((DWORD_PTR) ifile));
	XSRETURN(2);
      } else {
	ComErrorMsg(croak_on_error, "IShellLinkW_QueryInterface", hres);
	XSRETURN_NO;
      }
    } else {
      ComErrorMsg(croak_on_error, "CoCreateInstance", hres);
    }

    XSRETURN_NO;

void
_Release(ilink,ifile)
     IShellLinkW * ilink
     IPersistFile * ifile
PPCODE:
     IPersistFile_Release(ifile);
     IShellLinkW_Release(ilink);
     XSRETURN_YES;

void
_SetDescription(ilink,ifile,description,croak_on_error)
     IShellLinkW * ilink
     IPersistFile * ifile
     SV * description
     int croak_on_error
PPCODE:
    {
      HRESULT hres;
      WCHAR *wdescription = sv_to_wstr(aTHX_ description);
      hres = IShellLinkW_SetDescription(ilink, wdescription);
      Safefree(wdescription);
      if (SUCCEEDED(hres)) {
	XSRETURN_YES;
      } else {
	ComErrorMsg(croak_on_error, "IShellLinkW_SetDescription", hres);
	XSRETURN_NO;
      }
    }

void
_GetDescription(ilink,ifile,croak_on_error)
     IShellLinkW * ilink
     IPersistFile * ifile
     int croak_on_error
PPCODE:
    {
      HRESULT hres;
      WCHAR wdescription[MY_MAX_PATHW];
      SV *sv = NULL;
      hres = IShellLinkW_GetDescription(ilink, wdescription, MY_MAX_PATHW);
      if (SUCCEEDED(hres)) {
	ST(0) = wstr_to_sv(aTHX_ wdescription);
	XSRETURN(1);
      } else {
	ComErrorMsg(croak_on_error, "IShellLinkW_GetDescription", hres);
	XSRETURN_NO;
      }
    }

void
_SetPath(ilink,ifile,path,croak_on_error)
     IShellLinkW * ilink
     IPersistFile * ifile
     SV * path
     int croak_on_error
PPCODE:
    {
      HRESULT hres;
      WCHAR *wpath = sv_to_wstr(aTHX_ path);
      hres = IShellLinkW_SetPath(ilink, wpath);
      Safefree(wpath);
      if (SUCCEEDED(hres)) {
	XSRETURN_YES;
      } else {
	ComErrorMsg(croak_on_error, "IShellLinkW_SetPath", hres);
	XSRETURN_NO;
      }
    }

void
_GetPath(ilink,ifile,flags,croak_on_error)
     IShellLinkW * ilink
     IPersistFile * ifile
     DWORD flags
     int croak_on_error
PPCODE:
    {
      HRESULT hres;
      WCHAR wpath[MY_MAX_PATHW];
      WIN32_FIND_DATAW file;

      hres = IShellLinkW_GetPath(ilink, wpath, MY_MAX_PATHW, &file, flags);
      if (SUCCEEDED(hres)) {
	ST(0) = wstr_to_sv(aTHX_ wpath);
	XSRETURN(1);
      } else {
	ComErrorMsg(croak_on_error, "IShellLinkW_GetPath", hres);
	XSRETURN_NO;
      }
    }

void
_SetArguments(ilink,ifile,arguments,croak_on_error)
     IShellLinkW * ilink
     IPersistFile * ifile
     SV * arguments
     int croak_on_error
PPCODE:
    {
      HRESULT hres;
      WCHAR *warguments = sv_to_wstr(aTHX_ arguments);
      hres = IShellLinkW_SetArguments(ilink, warguments);
      Safefree(warguments);
      if (SUCCEEDED(hres)) {
	XSRETURN_YES;
      } else {
	ComErrorMsg(croak_on_error, "IShellLinkW_SetArguments", hres);
	XSRETURN_NO;
      }
    }

void
_GetArguments(ilink,ifile,croak_on_error)
     IShellLinkW * ilink
     IPersistFile * ifile
     int croak_on_error
PPCODE:
    {
      HRESULT hres;
      WCHAR warguments[MY_MAX_PATHW];
      hres = IShellLinkW_GetArguments(ilink, warguments, MY_MAX_PATHW);
      if (SUCCEEDED(hres)) {
	ST(0) = wstr_to_sv(aTHX_ warguments);
	XSRETURN(1);
      } else {
	ComErrorMsg(croak_on_error, "IShellLinkW_GetArguments", hres);
	XSRETURN_NO;
      }
    }

void
_SetWorkingDirectory(ilink,ifile,dir,croak_on_error)
     IShellLinkW * ilink
     IPersistFile * ifile
     SV * dir
     int croak_on_error
PPCODE:
    {
      HRESULT hres;
      WCHAR *wdir = sv_to_wstr(aTHX_ dir);
      hres = IShellLinkW_SetWorkingDirectory(ilink, wdir);
      Safefree(wdir);
      if (SUCCEEDED(hres)) {
	XSRETURN_YES;
      } else {
	ComErrorMsg(croak_on_error, "IShellLinkW_SetWorkingDirectory", hres);
	XSRETURN_NO;
      }
    }

void
_GetWorkingDirectory(ilink,ifile,croak_on_error)
     IShellLinkW * ilink
     IPersistFile * ifile
     int croak_on_error
PPCODE:
    {
      HRESULT hres;
      WCHAR dir[MY_MAX_PATHW];
      hres = IShellLinkW_GetWorkingDirectory(ilink, dir, MY_MAX_PATHW);
      if (SUCCEEDED(hres)) {
	ST(0) = wstr_to_sv(aTHX_ dir);
	XSRETURN(1);
      } else {
	ComErrorMsg(croak_on_error, "IShellLinkW_GetWorkingDirectory", hres);
	XSRETURN_NO;
      }
    }

void
_SetShowCmd(ilink,ifile,flag,croak_on_error)
     IShellLinkW * ilink
     IPersistFile * ifile
     int flag
     int croak_on_error
PPCODE:
    {
      HRESULT hres;
      hres = IShellLinkW_SetShowCmd(ilink, flag);
      if (SUCCEEDED(hres)) {
	XSRETURN_YES;
      } else {
	ComErrorMsg(croak_on_error, "IShellLinkW_SetShowCmd", hres);
	XSRETURN_NO;
      }
    }

void
_GetShowCmd(ilink,ifile,croak_on_error)
     IShellLinkW * ilink
     IPersistFile * ifile
     int croak_on_error
PPCODE:
    {
      HRESULT hres;
      int show;
      hres = IShellLinkW_GetShowCmd(ilink, &show);
      if (SUCCEEDED(hres)) {
	XSRETURN_IV(show);
      } else {
	ComErrorMsg(croak_on_error, "IShellLinkW_GetShowCmd", hres);
	XSRETURN_NO;
      }
    }

void
_SetHotkey(ilink,ifile,hotkey,croak_on_error)
     IShellLinkW * ilink
     IPersistFile * ifile
     unsigned short hotkey
     int croak_on_error
PPCODE:
    {
      HRESULT hres;
      hres = IShellLinkW_SetHotkey(ilink, hotkey);
      if (SUCCEEDED(hres)) {
	XSRETURN_YES;
      } else {
	ComErrorMsg(croak_on_error, "IShellLinkW_SetHotkey", hres);
	XSRETURN_NO;
      }
    }

void
_GetHotkey(ilink,ifile,croak_on_error)
     IShellLinkW * ilink
     IPersistFile * ifile
     int croak_on_error
PPCODE:
    {
      HRESULT hres;
      unsigned short hotkey;
      hres = IShellLinkW_GetHotkey(ilink, &hotkey);
      if (SUCCEEDED(hres)) {
	XSRETURN_IV(hotkey);
      } else {
	ComErrorMsg(croak_on_error, "IShellLinkW_GetHotkey", hres);
	XSRETURN_NO;
      }
    }

void
_SetIconLocation(ilink,ifile,location,number,croak_on_error)
     IShellLinkW * ilink
     IPersistFile * ifile
     SV * location
     int number
     int croak_on_error
PPCODE:
    {
      HRESULT hres;
      WCHAR *wlocation = sv_to_wstr(aTHX_ location);
      hres = IShellLinkW_SetIconLocation(ilink, wlocation,number);
      Safefree(wlocation);
      if (SUCCEEDED(hres)) {
	XSRETURN_YES;
      } else {
        ComErrorMsg(croak_on_error, "IShellLinkW_SetIconLocation", hres);
	XSRETURN_NO;
      }
    }

void
_GetIconLocation(ilink,ifile,croak_on_error)
     IShellLinkW * ilink
     IPersistFile * ifile
     int croak_on_error
PPCODE:
    {
      HRESULT hres;
      int number;
      WCHAR wlocation[MY_MAX_PATHW];
      hres = IShellLinkW_GetIconLocation(ilink, wlocation, MY_MAX_PATHW, &number);
      if (SUCCEEDED(hres)) {
	ST(0) = wstr_to_sv(aTHX_ wlocation);
	XST_mIV(1,number);
	XSRETURN(2);
      } else {
	ComErrorMsg(croak_on_error, "IShellLinkW_GetIconLocation", hres);
	XSRETURN_NO;
      }
    }

void
_Resolve(ilink,ifile,flags,croak_on_error)
     IShellLinkW * ilink
     IPersistFile * ifile
     long flags
     int croak_on_error
PPCODE:
    {
      HRESULT hres;
      hres = IShellLinkW_Resolve(ilink, NULL, flags);
      if (SUCCEEDED(hres)) {
	WCHAR wpath[MY_MAX_PATHW];
	WIN32_FIND_DATAW file;
	hres = IShellLinkW_GetPath(ilink, wpath, MY_MAX_PATHW, &file, 0);
	if (SUCCEEDED(hres)) {
	  ST(0) = wstr_to_sv(aTHX_ wpath);
	  XSRETURN(1);
	} else {
	  ComErrorMsg(croak_on_error, "IShellLinkW_GetPath", hres);
	  XSRETURN_NO;
	}
      } else {
	ComErrorMsg(croak_on_error, "IShellLinkW_Resolve", hres);
	XSRETURN_NO;
      }
    }

void
_Save(ilink,ifile,filename,croak_on_error)
     IShellLinkW * ilink
     IPersistFile * ifile
     SV * filename
     int croak_on_error
PPCODE:
    {
      HRESULT hres;
      WCHAR *wfilename = sv_to_wstr(aTHX_ filename);
      hres = IPersistFile_Save(ifile, wfilename, TRUE);
      Safefree(wfilename);
      if (SUCCEEDED(hres)) {
	XSRETURN_YES;
      } else {
	ComErrorMsg(croak_on_error,"IPersistFile_Save", hres);
	XSRETURN_NO;
      }
    }

void
_Load(ilink,ifile,filename,croak_on_error)
     IShellLinkW * ilink
     IPersistFile * ifile
     SV * filename
     int croak_on_error
PPCODE:
    {
      HRESULT hres;
      WCHAR *wfilename = sv_to_wstr(aTHX_ filename);
      hres = IPersistFile_Load(ifile, wfilename, STGM_READ);
      Safefree(wfilename);
      if (SUCCEEDED(hres)) {
	XSRETURN_YES;
      } else {
	ComErrorMsg(croak_on_error, "IPersistFile_Load", hres);
	XSRETURN_NO;
      }
    }

void
_CoInitializeEx(dwCoInit,croak_on_error)
     DWORD dwCoInit
     int croak_on_error
PPCODE:
    {
      HRESULT hres = CoInitializeEx(NULL, dwCoInit);
      if (SUCCEEDED(hres)) {
	XSRETURN_YES;
      } else {
	ComErrorMsg(croak_on_error,"CoInitializeEx", hres);
	XSRETURN_NO;
      }
    }

void
_CoInitialize(croak_on_error)
     int croak_on_error
PPCODE:
    {
      HRESULT hres = CoInitialize(NULL);
      if (SUCCEEDED(hres)) {
	XSRETURN_YES;
      } else {
	ComErrorMsg(croak_on_error,"CoInitialize", hres);
	XSRETURN_NO;
      }
    }

void
_CoUninitialize(...)
PPCODE:
    CoUninitialize();
    XSRETURN_YES;
