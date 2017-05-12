/* Copyright 2001-2004, Phill Wolf.  See README. -*-Mode: c;-*-  */

/* Win32::ActAcc (Active Accessibility) C-extension source file */

#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"
// WORD is defined in old perly.h and conflicts with a Windows typedef.
// undef Perl's WORD before #includ'ing Windows' definition.
#undef WORD
#include <wtypes.h>
#define COBJMACROS
#define CINTERFACE
#include <oleauto.h>
#include <OleAcc.h>
#include <WinAble.h>
#include "AAEvtMon.h"
#include "ActAccEL.h"

// VC98 doesn't define OBJID_NATIVEOM
#ifndef OBJID_NATIVEOM
#define     OBJID_NATIVEOM      0xFFFFFFF0
#endif

// We don't want to require much runtime library support.
//#pragma check_stack(off)
#pragma intrinsic(memset)
#pragma intrinsic(memcpy)
#pragma intrinsic(strcpy)
#pragma intrinsic(memcmp)
#pragma intrinsic(strcmp)
#pragma intrinsic(strlen)

#ifndef __FUNCTION__
#define __FUNCTION__ "UnknownFunction"
#endif

#define GUITEST_XS__DO_UNICODE

HINSTANCE g_hinstDLL = 0;

BOOL WINAPI DllMain
(
 HINSTANCE hinstDLL,  // handle to the DLL module
 DWORD fdwReason,     // reason for calling function
 LPVOID lpvReserved   // reserved
 )
{
  if (DLL_PROCESS_ATTACH == fdwReason)
	{
      g_hinstDLL = hinstDLL;
	}
  return TRUE;
}



/*
// todo: get_accHelpTopic
// todo: get_accSelection
// todo: accHitTest
*/
#ifdef PERL_OBJECT
#define USEGUID(X) X
#else
#define USEGUID(X) &X
#endif

/* ----------------------------------------- */

static int
not_here(char *s)
{
  croak("%s not implemented on this architecture", s);
  return -1;
}

// Populate an uninitialized Variant with a 4-byte signed int.
void VariantInit_VT_I4(VARIANT *v, LONG i)
{
  VariantInit(v);
  v->vt = VT_I4;
  v->lVal = i;
}

//  croak("WinError=%08lx in %s", le, f);

void warnAboutWinError(char const *file, char const *func, int line)
{
  DWORD winerror = GetLastError();
  if (winerror && 
      (PL_dowarn & G_WARN_ON)) // = if($^W)
    {
      warn("Windows error 0x%08lx in function %s on line %d of file %s",
           winerror, func, line, file);
      SetLastError(winerror); // just in case "warn" clobbered it
    }
}
#define WARN_ABOUT_WINERROR() warnAboutWinError(__FILE__, __FUNCTION__, __LINE__)
#define WARN_ABOUT_WINERROR_2(FUNCTION) warnAboutWinError(__FILE__, FUNCTION, __LINE__)

/* ----------------------------------------- */

// A Perl "Win32::ActAcc::AO" object is an ActAcc_ struct.
struct ActAcc_
{
  IAccessible *ia;
  DWORD id; // child ID
  SV *bag;  // "baggage" - null until needed
};

typedef struct ActAcc_ ActAcc;
typedef struct ActAcc_* ActAccPtr;

// Allocate an ActAcc struct and transfer an IAccessible* to it.
// Caller must release the IAccessible.
// Might return NULL if the memory allocation fails.
ActAcc *ActAcc_from_IAccessible(IAccessible *ia, DWORD id)
{
  ActAcc *rv = 0;
  New(7, rv, 1, ActAcc); 
  if (rv != NULL)
    {
      rv->ia = ia;
      IAccessible_AddRef(ia);
      rv->id = id;
      rv->bag = 0;
    }
  return rv;
}

// caller always responsible for freeing the IDispatch
ActAcc *ActAcc_from_IDispatch(IDispatch *pDispatch)
{
	ActAcc *rv = 0;
	IAccessible *pAccessible = 0;
	HRESULT hr = IDispatch_QueryInterface(
                                          pDispatch, 
                                          USEGUID(IID_IAccessible), 
                                          (void**)&pAccessible);
    if (E_NOINTERFACE == hr)
      SetLastError(hr);
    if (SUCCEEDED(hr))
      {
      rv = ActAcc_from_IAccessible(pAccessible, CHILDID_SELF);
      IAccessible_Release(pAccessible);
      SetLastError(0);
      }
    else
      {
        WARN_ABOUT_WINERROR();
      }
	return rv;
}

// If the variant contains VT_DISPATCH, populates pOut, returns TRUE.
// If the variant contains VT_I4, takes it as a child ID relative
//     to the AO "base"; populates pOut and returns TRUE.
// If the variant contains VT_UNKNOWN and it happens to expose
//     IAccessible, populates pOut, returns TRUE.
// Else returns FALSE and leaves pOut and the variant untouched.
// If returns TRUE, also clears the variant.
BOOL ActAcc_from_VARIANT(ActAcc *base, VARIANT *v, ActAcc **pOut)
{
  IAccessible *ia=0;
  HRESULT hr=S_OK;
  switch (v->vt)
    {
    case VT_EMPTY:
      return FALSE;
    case VT_DISPATCH:
      *pOut = ActAcc_from_IDispatch(v->pdispVal);
      VariantClear(v);
      return TRUE;
    case VT_I4:
      *pOut = ActAcc_from_IAccessible(base->ia, v->lVal);
      VariantClear(v);
      return TRUE;
    case VT_UNKNOWN:
      hr = IUnknown_QueryInterface(v->punkVal, USEGUID(IID_IAccessible), (void**)&ia);
      if (E_NOINTERFACE == hr)
        SetLastError(hr);
      if (S_OK == hr)
        {
          VariantClear(v);
          *pOut = ActAcc_from_IAccessible(ia, CHILDID_SELF);
          SetLastError(0);
          return TRUE;
        }
      else
        {
          WARN_ABOUT_WINERROR();
        }
    }
  return FALSE;
}

/* ----------------------------------------- */

struct EventConsolidator_
{
  HWINEVENTHOOK hhook;
  int refcount; // number of times this hook has been dispensed to Perl
};

typedef struct EventConsolidator_ EventConsolidator;

// Caller should check GetLastError if returns null.
EventConsolidator *EventConsolidator_new()
{
  HMODULE hDll = 0;
  EventConsolidator *rv = 0;
    
  // Load ActAccEM.dll from directory that contains ActAcc.dll.
  {
    // Get pathname of ActAcc.dll
    TCHAR *dllNameBuf;
    int capy = 50;
    int dllNameChars;
    for (;;)
      {
        New(7, dllNameBuf, capy, TCHAR);
        if (!dllNameBuf)
          {
            SetLastError(ERROR_WRONG_DISK);
            return NULL; // let caller check GetLastError
          }
        dllNameChars =
          dllNameChars = GetModuleFileName(
                                           g_hinstDLL,
                                           dllNameBuf,
                                           capy-1
                                           );
        if (0 == dllNameChars)
          {
            WARN_ABOUT_WINERROR();
            return NULL; // let caller check GetLastError
          }
        else
          SetLastError(0);

        if (dllNameChars < capy-5) // need fudge to expand name
          break;

        Safefree(dllNameBuf);
        capy += 50;
      }

    // Modify file name, giving complete path to ActAccEM.DLL
    strcpy(dllNameBuf + dllNameChars - 4, "EM.dll");
      
    // Load ActAccEM.dll.       
    hDll = LoadLibrary(dllNameBuf);
    Safefree(dllNameBuf);
    if (!hDll)
      {
        WARN_ABOUT_WINERROR();
        return NULL;
      }
    else
      SetLastError(0);
  }

  // Set event hook
  New(7, rv, 1, EventConsolidator); 
  if (rv)
    {
      enum { EVENTS_FROM_ALL_PROCESSES = 0 };
      WINEVENTPROC pfWinEventProc;
      rv->refcount = 1;
      rv->hhook = 0;
        
      pfWinEventProc = 
        (WINEVENTPROC) GetProcAddress(hDll, "_WinEventProc@28");
      if (pfWinEventProc)
        {
          rv->hhook = SetWinEventHook
            (EVENT_MIN, 
             EVENT_MAX,
             hDll, 
             pfWinEventProc, 
             EVENTS_FROM_ALL_PROCESSES,
             0,
             WINEVENT_INCONTEXT);
          if (rv->hhook)
            {
              SetLastError(0);
              return rv;  // <--- successful return
            }
          else
            {
              WARN_ABOUT_WINERROR();
            }
        }
      else
        {
          WARN_ABOUT_WINERROR();
        }
    }

  // Unload DLL and free memory (preserving last-error code)
  {
    DWORD le = GetLastError(); 
    FreeLibrary(hDll);
    if (rv)
      Safefree(rv);
    SetLastError(le);
  }
  return NULL;
}

void EventConsolidator_addref(EventConsolidator *self)
{
  self->refcount++;
}

int EventConsolidator_release(EventConsolidator *self)
{
  int new_refcount = --self->refcount;
  if (!new_refcount)
	{
      if (UnhookWinEvent(self->hhook))
        SetLastError(0);
      else
        {
          WARN_ABOUT_WINERROR();
        }
      Safefree(self);
	}
  return new_refcount;
}

EventConsolidator *g_eventConsolidator = 0;

EventConsolidator *getConsolidator()
{
  if (!g_eventConsolidator)
	{
      g_eventConsolidator = EventConsolidator_new();
	}
  else
	{
      EventConsolidator_addref(g_eventConsolidator);
	}
  return g_eventConsolidator;
}

void releaseConsolidator()
{
  if (!EventConsolidator_release(g_eventConsolidator))
    g_eventConsolidator = 0;
}

/* ----------------------------------------- */

struct EventMonitor_
{
  EventConsolidator *cons;
  long readCursorQume;
};

typedef struct EventMonitor_ EventMonitor;
typedef struct EventMonitor_* EventMonitorPtr;

EventMonitor *EventMonitor_new()
{
  EventMonitor *rv = 0;
  New(7, rv, 1, EventMonitor); 
  rv->cons = 0;
  rv->readCursorQume = 0;
  return rv;
}

void EventMonitor_activate(EventMonitor *em)
{
  if (!em->cons)
	{
      em->cons = getConsolidator();
	}
}

void EventMonitor_deactivate(EventMonitor *em)
{
  if (em->cons)
	{
      releaseConsolidator();
      em->cons = 0;
	}
}

EventMonitor *EventMonitor_synch(EventMonitor *em)
{
  if (emLock())
	{
      em->readCursorQume = emSynch();
      emUnlock();
	}
  return em;
}


/* ----------------------------------------- */

void croakIfNullIAccessible(ActAcc *p)
{
  if (!p->ia)
	{
      croak("Null ActAcc (perhaps it has already been Release'd)");
	}
}

/* ----------------------------------------- */

void baggage_alloc(ActAcc *p, SV *nbag)
{
  p->bag = nbag;
  SvREFCNT_inc(nbag);
}

SV* baggage_return(ActAcc *p)
{
  return p->bag;
}

void baggage_free(ActAcc *p)
{
  if (p->bag)
	{
      SvREFCNT_dec(p->bag);
      p->bag = 0;
	}
}


void ActAcc_free_incl_hash(ActAcc *p)
{
  if (p->ia) 
	{
      IAccessible_Release(p->ia);
	}
  baggage_free(p);
  ZeroMemory(p, sizeof(ActAcc));
  Safefree(p);
}

#ifdef GUITEST_XS__DO_UNICODE

// Return Perl string (SV*) containing UTF-8 representation of a
// Windows wide-character (UCS2-LE) string. Set the Perl-string's UTF-8 flag
// optimally, i.e., only in case the resulting string actually contains
// at least one character whose UTF-8 representation takes more
// than one byte. 
// cch=-1 means figure it out with strlen.
// cch does not include the \0 terminal.
// ucs2le may or may not have a \0 terminal after the counted characters.
// ucs2le may be NULL, in which case the return value is an empty-string SV.
// The returned SV is always mortal.
/*
This version works, but uses Windows' very-very-slow WideCharToMultiByte
in all cases.  It's commented-out, in favor of another version,
which merely compresses the bytes of the wide string unless it
finds that the string really actually contains stuff that needs 
more-cerebral conversion. 

SV*
ucs2le_to_sv_x(LPWSTR ucs2le, int cch)
{
int u8_baggy_buffer_size;
U8 *u8_baggy_buffer;
  int u8cb;
  int multibyte_chars;
  SV *rv;

  if (ucs2le==NULL)
	return sv_2mortal(newSVpv("",0));

  // Allocate UTF-8 buffer. 
  // It might take up to 6 bytes per character.
  // Include room for terminal \0 character.
  if (cch == -1)
    cch = wcslen(ucs2le); 
  // if cch erroneously included the \0, exclude it.
  if (cch > 0 && (ucs2le[cch-1]==0))
    cch--;
  u8_baggy_buffer_size = cch*6+1; // worst case; incl room for \0
  u8_baggy_buffer = (U8*)safemalloc(u8_baggy_buffer_size);

  // Translate UCS2LE to UTF8 using Windows API
  // note: CP_UTF8 support in Win 98, ME, NT4SP3(?) and later.
  u8cb = WideCharToMultiByte(
  CP_UTF8, 0, ucs2le, cch, u8_baggy_buffer, 
  u8_baggy_buffer_size, NULL, NULL);
  // u8cb excludes \0 terminal
  multibyte_chars = (u8cb != cch);
  
  // Copy the result to a Perl string.
  rv = sv_2mortal(newSVpv(u8_baggy_buffer, u8cb));
  
  // Set Perl-string's UTF8 flag iff there are actually
  // any multibyte characters in the UTF8 representation.
  // Leave flag off if UTF8 coincides with 7-bit ASCII.
  if (multibyte_chars) {
  SvUTF8_on(rv);
  }
  
  safefree(u8_baggy_buffer);
  
  return rv;
  }

*/

SV*
ucs2le_to_sv(LPWSTR ucs2le, int cch)
{
  SV *ipl;
  int iw;
  char *o;
  int cbr = 0;
  UV wch;

  // Bail out with empty-string if input is null.
  if (NULL==ucs2le)
	return sv_2mortal(newSVpv("",0));
  
  // Compute cch if it is -1.
  if (-1==cch)
    cch = wcslen(ucs2le); 

  // if cch erroneously included the \0, exclude it.
  if (cch > 0 && (ucs2le[cch-1]==0))
    cch--;

  // Bail out with empty-string if input is empty.
  if (0==cch)
	return sv_2mortal(newSVpv("",0));

  // allocate a buffer
  ipl = newSV(cch); // Perl allocates 1 extra byte for the \0 
  o = SvPVX(ipl);
  
  // Copy characters one-by-one. 
  // Upon 1st 8-bit character, switch modes and count
  // the necessary additional space instead.
  for (iw = 0;  iw < cch;  iw++)
    {
      wch = ucs2le[iw];
      if (wch < 0x80U)
        *o++ = (char)(wch & 0x7fU);
      else
        {
          for ( ; iw < cch ; iw++)
            cbr += 1 + 5*(ucs2le[iw] > 0x7fU); // sloppy/safe
          break;
        }
    }

  // If no extra space is required, we're done.
  // Otherwise start over with enough room.
  if (cbr == 0)
    {
      *o = '\0';
      SvPOK_on(ipl); // it is a good string
      SvUTF8_off(ipl);
      SvCUR_set(ipl, cch); // update the length
    }
  else
    {
      o = SvGROW(ipl, 
                 (unsigned)(cch + cbr + 1)); // baggy; plus room for \0
      cbr = WideCharToMultiByte
        (CP_UTF8, 0, ucs2le, cch, o, cch+cbr, NULL, NULL);
      if (cbr)
        SetLastError(0);
      else
        {
          WARN_ABOUT_WINERROR();
        }
      // cbr excludes \0 terminal
      o[cbr] = '\0';
      SvPOK_on(ipl); // it is a good string
      SvCUR_set(ipl, cbr); // update the length
      SvUTF8_on(ipl);
    }

  return sv_2mortal(ipl);
}

// If returns null, caller should check GetLastError.
SV* getDesktopName_()
{
  wchar_t dsknam[100];
  DWORD thid;
  DWORD out_cbNeeded;
  HDESK hdesk;
  thid = GetCurrentThreadId();
  if (thid == 0)
    {
      WARN_ABOUT_WINERROR();
      return NULL;
    }
  hdesk = GetThreadDesktop(thid);
  if (hdesk == 0)
    {
      WARN_ABOUT_WINERROR();
      return NULL;
    }
  if (GetUserObjectInformationW
      (hdesk, UOI_NAME, dsknam, sizeof(dsknam), &out_cbNeeded))
    {
      SetLastError(0);
      return ucs2le_to_sv(dsknam, -1);
    }
  WARN_ABOUT_WINERROR();
  return NULL;
}

// If returns null, caller should check GetLastError.
SV* getInputDesktopName_()
{
  wchar_t dsknam[100];
  DWORD out_cbNeeded;
  HDESK hdesk;
  BOOL b;
  hdesk = OpenInputDesktop(0, FALSE, DESKTOP_READOBJECTS);
  if (hdesk == 0)
    {
      WARN_ABOUT_WINERROR();
      return NULL;
    }
  b = GetUserObjectInformationW
    (hdesk, UOI_NAME, dsknam, sizeof(dsknam), &out_cbNeeded);
  if (!b)
    {
      WARN_ABOUT_WINERROR();
    }
  if (!CloseDesktop(hdesk))
    {
      WARN_ABOUT_WINERROR();
    }
  if (b)
    {
      SetLastError(0);
      return ucs2le_to_sv(dsknam, -1);
    }
  return NULL;
}

#else

SV* getDesktopName_()
{
  char dsknam[100];
  DWORD thid;
  DWORD out_cbNeeded;
  HDESK hdesk;
  thid = GetCurrentThreadId();
  if (thid == 0)
    {
      WARN_ABOUT_WINERROR();
      return NULL;
    }
  hdesk = GetThreadDesktop(thid);
  if (hdesk == 0)
    {
      WARN_ABOUT_WINERROR();
      return NULL;
    }
  if (GetUserObjectInformationA
      (hdesk, UOI_NAME, dsknam, sizeof(dsknam), &out_cbNeeded))
    {
      SetLastError(0);
      return newSVpv(dsknam, out_cbNeeded);
    }
  WARN_ABOUT_WINERROR();
  return NULL;
}

SV* getInputDesktopName_()
{
  char dsknam[100];
  DWORD out_cbNeeded;
  HDESK hdesk;
  BOOL b;
  hdesk = OpenInputDesktop(0, FALSE, DESKTOP_READOBJECTS);
  if (hdesk == 0)
    {
      WARN_ABOUT_WINERROR();
      return NULL;
    }
  b = GetUserObjectInformationA
    (hdesk, UOI_NAME, dsknam, sizeof(dsknam), &out_cbNeeded);
  if (!b)
    {
      WARN_ABOUT_WINERROR();
    }
  if (!CloseDesktop(hdesk))
    {
      WARN_ABOUT_WINERROR();
    }
  if (b)
    {
      SetLastError(0);
      return newSVpv(dsknam, out_cbNeeded);
    }
  return NULL;
}

#endif


/* ----------------------------------------- */

#ifdef GUITEST_XS__DO_UNICODE

SV *textAccessor(ActAcc *p, 
                 HRESULT 
                 ( STDMETHODCALLTYPE __RPC_FAR *pfn )
                 (IAccessible __RPC_FAR * This,
                  VARIANT varChild,
                  BSTR __RPC_FAR *pszName),
                 char const *funcname)
{
  HRESULT hr = S_OK;
  BSTR bs = 0;
  int cch = 0;
  SV *rv = &PL_sv_undef;
  VARIANT childid;
  SetLastError(0);
  croakIfNullIAccessible(p);
  VariantInit_VT_I4(&childid, p->id);
  hr = (*pfn)(p->ia, childid, &bs);
  if (SUCCEEDED(hr) || DISP_E_MEMBERNOTFOUND==hr)
    SetLastError(0);
  else
    {
      WARN_ABOUT_WINERROR_2(funcname);
    }
  VariantClear(&childid);
  if (S_OK == hr)
	{
      // bs may be NULL. SysStringLen will return 0 in such case.
      cch = SysStringLen(bs);
      rv = ucs2le_to_sv(bs, cch);
	}
  SysFreeString(bs);
  return rv;
}

#else

SV *textAccessor(ActAcc *p, 
			HRESULT ( STDMETHODCALLTYPE __RPC_FAR *pfn )( 
				IAccessible __RPC_FAR * This,
				VARIANT varChild,
				BSTR __RPC_FAR *pszName),
                 char const *funcname)
{
  HRESULT hr = S_OK;
  BSTR bs = 0;
  int cch = 0;
  SV *rv = &PL_sv_undef;
  VARIANT childid;
  SetLastError(0);
  croakIfNullIAccessible(p);
  VariantInit_VT_I4(&childid, p->id);
  hr = (*pfn)(p->ia, childid, &bs);
  if (SUCCEEDED(hr) || DISP_E_MEMBERNOTFOUND==hr)
    SetLastError(0);
  else    
    {
      WARN_ABOUT_WINERROR_2(funcname);
    }
  VariantClear(&childid);
  if (S_OK == hr)
	{
      char *a = 0;
      int wctmb = 0;
      // bs may be NULL. SysStringLen will return 0 in such case.
      cch = SysStringLen(bs);
      New(7, a, 1 + cch, char); 
      ZeroMemory(a, 1 + cch);
      wctmb = WideCharToMultiByte(CP_ACP,0,bs,1+cch,a,cch,0,0);
      if (wctmb)
        SetLastError(0);
      else
        {
          WARN_ABOUT_WINERROR_2(funcname);
        }
      rv = sv_2mortal(newSVpv(a,0));
      Safefree(a);
	}
  SysFreeString(bs);
  return rv;
}

#endif

SV *uintAccessor(ActAcc *p, 
			HRESULT ( STDMETHODCALLTYPE __RPC_FAR *pfn )( 
				IAccessible __RPC_FAR * This,
				VARIANT varChild,
				VARIANT __RPC_FAR *pvar),
                 char const *funcname)
{
  HRESULT hr = S_OK;
  SV *rv = &PL_sv_undef; // pessimistic
  VARIANT childid;
  VARIANT result;
  SetLastError(0);
  croakIfNullIAccessible(p);
  VariantInit_VT_I4(&childid, p->id);
  VariantInit(&result);
  hr = (*pfn)(p->ia, childid, &result);
  if (SUCCEEDED(hr))
    SetLastError(0);
  else
    {
      WARN_ABOUT_WINERROR_2(funcname);
    }
  VariantClear(&childid);
  if ((S_OK == hr) && (result.vt==VT_I4))
	{
      rv = sv_2mortal(newSVuv(result.lVal));
	}
  VariantClear(&result);
  return rv;
}

// Returns -1 in case of error. Check GetLastError.
int getAccChildCount(IAccessible *iaParent)
{
  HWND hwnd = 0;
  long nChildren = 0;
  HRESULT hrCount = IAccessible_get_accChildCount(iaParent, &nChildren);
  if (SUCCEEDED(hrCount))
    SetLastError(0);
  else
    {
      WARN_ABOUT_WINERROR();
      nChildren = -1;
    }
  return nChildren;
}


#include "consts.xsh"

// translate POINT p from pixels to mickeys
void ScreenToMouseplane(POINT *p)
{
  p->x = MulDiv(p->x, 0x10000, GetSystemMetrics(SM_CXSCREEN));
  p->y = MulDiv(p->y, 0x10000, GetSystemMetrics(SM_CYSCREEN));
}

// mouse operations in pixels
void mouse_button(int x, int y, char *ops)
{
  POINT p;
  int b = 0, sb = GetSystemMetrics(SM_SWAPBUTTON);
  p.x = x;  p.y = y;
  ScreenToMouseplane(&p);
  while (*ops)
    {
      switch (*ops)
        {
        case 'm':
          mouse_event(MOUSEEVENTF_ABSOLUTE | MOUSEEVENTF_MOVE, 
                      p.x, p.y, 0, 0);
          break;
        case 'd':
          b = sb ? MOUSEEVENTF_RIGHTDOWN: MOUSEEVENTF_LEFTDOWN;
          mouse_event(MOUSEEVENTF_ABSOLUTE | MOUSEEVENTF_MOVE | b, 
                      p.x, p.y, 0, 0);
          break;
        case 'u':
          b = sb ? MOUSEEVENTF_RIGHTUP: MOUSEEVENTF_LEFTUP;
          mouse_event(MOUSEEVENTF_ABSOLUTE | MOUSEEVENTF_MOVE | b, 
                      p.x, p.y, 0, 0);
          break;
        case 'D':
          b = sb ? MOUSEEVENTF_LEFTDOWN: MOUSEEVENTF_RIGHTDOWN;
          mouse_event(MOUSEEVENTF_ABSOLUTE | MOUSEEVENTF_MOVE | b, 
                      p.x, p.y, 0, 0);
          break;
        case 'U':
          b = sb ? MOUSEEVENTF_LEFTUP: MOUSEEVENTF_RIGHTUP;
          mouse_event(MOUSEEVENTF_ABSOLUTE | MOUSEEVENTF_MOVE | b, 
                      p.x, p.y, 0, 0);
          break;
        }
      ops++;
    }
}

char *packageForRole(int r)
{
  char *rv = "Win32::ActAcc::AO";
  switch (r) 
    {
#define ROLECONST2PACKAGENAME(C,P) case C:  rv = "Win32::ActAcc::" P; break
      ROLECONST2PACKAGENAME(ROLE_SYSTEM_TITLEBAR, "Titlebar");
      ROLECONST2PACKAGENAME(ROLE_SYSTEM_MENUBAR, "Menubar");
      ROLECONST2PACKAGENAME(ROLE_SYSTEM_SCROLLBAR, "Scrollbar");
      ROLECONST2PACKAGENAME(ROLE_SYSTEM_GRIP, "Grip");
      ROLECONST2PACKAGENAME(ROLE_SYSTEM_SOUND, "Sound");
      ROLECONST2PACKAGENAME(ROLE_SYSTEM_CURSOR, "Cursor");
      ROLECONST2PACKAGENAME(ROLE_SYSTEM_CARET, "Caret");
      ROLECONST2PACKAGENAME(ROLE_SYSTEM_ALERT, "Alert");
      ROLECONST2PACKAGENAME(ROLE_SYSTEM_WINDOW, "Window");
      ROLECONST2PACKAGENAME(ROLE_SYSTEM_CLIENT, "Client");
      ROLECONST2PACKAGENAME(ROLE_SYSTEM_MENUPOPUP, "MenuPopup");
      ROLECONST2PACKAGENAME(ROLE_SYSTEM_MENUITEM, "MenuItem");
      ROLECONST2PACKAGENAME(ROLE_SYSTEM_TOOLTIP, "Tooltip");
      ROLECONST2PACKAGENAME(ROLE_SYSTEM_APPLICATION, "Application");
      ROLECONST2PACKAGENAME(ROLE_SYSTEM_DOCUMENT, "Document");
      ROLECONST2PACKAGENAME(ROLE_SYSTEM_PANE, "Pane");
      ROLECONST2PACKAGENAME(ROLE_SYSTEM_CHART, "Chart");
      ROLECONST2PACKAGENAME(ROLE_SYSTEM_DIALOG, "Dialog");
      ROLECONST2PACKAGENAME(ROLE_SYSTEM_BORDER, "Border");
      ROLECONST2PACKAGENAME(ROLE_SYSTEM_GROUPING, "Grouping");
      ROLECONST2PACKAGENAME(ROLE_SYSTEM_SEPARATOR, "Separator");
      ROLECONST2PACKAGENAME(ROLE_SYSTEM_TOOLBAR, "Toolbar");
      ROLECONST2PACKAGENAME(ROLE_SYSTEM_STATUSBAR, "StatusBar");
      ROLECONST2PACKAGENAME(ROLE_SYSTEM_TABLE, "Table");
      ROLECONST2PACKAGENAME(ROLE_SYSTEM_COLUMNHEADER, "ColumnHeader");
      ROLECONST2PACKAGENAME(ROLE_SYSTEM_ROWHEADER, "RowHeader");
      ROLECONST2PACKAGENAME(ROLE_SYSTEM_COLUMN, "Column");
      ROLECONST2PACKAGENAME(ROLE_SYSTEM_ROW, "Row");
      ROLECONST2PACKAGENAME(ROLE_SYSTEM_CELL, "Cell");
      ROLECONST2PACKAGENAME(ROLE_SYSTEM_LINK, "Link");
      ROLECONST2PACKAGENAME(ROLE_SYSTEM_HELPBALLOON, "HelpBalloon");
      ROLECONST2PACKAGENAME(ROLE_SYSTEM_CHARACTER, "Character");
      ROLECONST2PACKAGENAME(ROLE_SYSTEM_LIST, "List");
      ROLECONST2PACKAGENAME(ROLE_SYSTEM_LISTITEM, "ListItem");
      ROLECONST2PACKAGENAME(ROLE_SYSTEM_OUTLINE, "Outline");
      ROLECONST2PACKAGENAME(ROLE_SYSTEM_OUTLINEITEM, "OutlineItem");
      ROLECONST2PACKAGENAME(ROLE_SYSTEM_PAGETAB, "PageTab");
      ROLECONST2PACKAGENAME(ROLE_SYSTEM_PROPERTYPAGE, "PropertyPage");
      ROLECONST2PACKAGENAME(ROLE_SYSTEM_INDICATOR, "Indicator");
      ROLECONST2PACKAGENAME(ROLE_SYSTEM_GRAPHIC, "Graphic");
      ROLECONST2PACKAGENAME(ROLE_SYSTEM_STATICTEXT, "StaticText");
      ROLECONST2PACKAGENAME(ROLE_SYSTEM_TEXT, "Text");
      ROLECONST2PACKAGENAME(ROLE_SYSTEM_PUSHBUTTON, "Pushbutton");
      ROLECONST2PACKAGENAME(ROLE_SYSTEM_CHECKBUTTON, "Checkbox");
      ROLECONST2PACKAGENAME(ROLE_SYSTEM_RADIOBUTTON, "Radiobutton");
      ROLECONST2PACKAGENAME(ROLE_SYSTEM_COMBOBOX, "Combobox");
      ROLECONST2PACKAGENAME(ROLE_SYSTEM_DROPLIST, "DropList");
      ROLECONST2PACKAGENAME(ROLE_SYSTEM_PROGRESSBAR, "ProgressBar");
      ROLECONST2PACKAGENAME(ROLE_SYSTEM_DIAL, "Dial");
      ROLECONST2PACKAGENAME(ROLE_SYSTEM_HOTKEYFIELD, "HotKeyField");
      ROLECONST2PACKAGENAME(ROLE_SYSTEM_SLIDER, "Slider");
      ROLECONST2PACKAGENAME(ROLE_SYSTEM_SPINBUTTON, "SpinButton");
      ROLECONST2PACKAGENAME(ROLE_SYSTEM_DIAGRAM, "Diagram");
      ROLECONST2PACKAGENAME(ROLE_SYSTEM_ANIMATION, "Animation");
      ROLECONST2PACKAGENAME(ROLE_SYSTEM_EQUATION, "Equation");
      ROLECONST2PACKAGENAME(ROLE_SYSTEM_BUTTONDROPDOWN, "ButtonDropDown");
      ROLECONST2PACKAGENAME(ROLE_SYSTEM_BUTTONMENU, "ButtonMenu");
      ROLECONST2PACKAGENAME(ROLE_SYSTEM_BUTTONDROPDOWNGRID, "ButtonDropDownGrid");
      ROLECONST2PACKAGENAME(ROLE_SYSTEM_WHITESPACE, "Whitespace");
      ROLECONST2PACKAGENAME(ROLE_SYSTEM_PAGETABLIST, "PageTabList");
      ROLECONST2PACKAGENAME(ROLE_SYSTEM_CLOCK, "Clock");
    }
  return rv;
}

char *packageForAO(ActAcc *p) 
{
  char *rv = NULL;
  HRESULT hr = S_OK;
  VARIANT childid;
  VARIANT vrole;
  croakIfNullIAccessible(p);
  childid.vt=VT_I4;
  childid.lVal=p->id;
  VariantInit(&vrole);
  hr = IAccessible_get_accRole(p->ia, childid, &vrole);
  if (SUCCEEDED(hr) && (vrole.vt==VT_I4))
    {
      SetLastError(0);
      rv = packageForRole(vrole.lVal);
    }
  else
    {
      WARN_ABOUT_WINERROR();
      rv = "Win32::ActAcc::AO";
    }
  VariantClear(&childid);
  VariantClear(&vrole);
  return rv;
}

MODULE = Win32::ActAcc		PACKAGE = Win32::ActAcc		

INCLUDE: ActAcc.xsh



MODULE = Win32::ActAcc		PACKAGE = Win32::ActAcc::AO		

INCLUDE: AO.xsh



MODULE = Win32::ActAcc		PACKAGE = Win32::ActAcc::EventMonitor

INCLUDE: EM.xsh
