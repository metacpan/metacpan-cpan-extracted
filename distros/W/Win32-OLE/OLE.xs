/* OLE.xs
 *
 *  (c) 1995 Microsoft Corporation. All rights reserved.
 *  Developed by ActiveWare Internet Corp., now known as
 *  ActiveState Tool Corp., http://www.ActiveState.com
 *
 *  Other modifications Copyright (c) 1997-1999 by Gurusamy Sarathy
 *  <gsar@ActiveState.com> and Jan Dubois <jand@ActiveState.com>
 *
 *  You may distribute under the terms of either the GNU General Public
 *  License or the Artistic License, as specified in the README file.
 *
 *
 * File contents:
 *
 * - C helper routines
 * - Package Win32::OLE             Constructor and method invocation
 * - Package Win32::OLE::Tie        Implements properties as tied hash
 * - Package Win32::OLE::Const      Load application constants from type library
 * - Package Win32::OLE::Enum       OLE collection enumeration
 * - Package Win32::OLE::Variant    Implements Perl VARIANT objects
 * - Package Win32::OLE::NLS        National Language Support
 * - Package Win32::OLE::TypeLib    Type library access
 * - Package Win32::OLE::TypeInfo   Type info access
 *
 */

#ifdef __GNUC__
#   pragma GCC diagnostic ignored "-Wwrite-strings"
#endif

// #define _DEBUG

#define register /* be gone */

#define MY_VERSION "Win32::OLE(" XS_VERSION ")"

#include <math.h>	/* this hack gets around VC-5.0 brainmelt */
#define _WIN32_DCOM
#include <windows.h>
#include <ocidl.h>

#ifdef _DEBUG
#   include <crtdbg.h>
#   define DEBUGBREAK _CrtDbgBreak()
#else
#   define DEBUGBREAK
#endif

// MingW is missing these 2 macros
#ifndef V_RECORD
#   ifdef NONAMELESSUNION
#       define V_RECORDINFO(X) ((X)->__VARIANT_NAME_1.__VARIANT_NAME_2.__VARIANT_NAME_3.__VARIANT_NAME_4.pRecInfo)
#       define V_RECORD(X)     ((X)->__VARIANT_NAME_1.__VARIANT_NAME_2.__VARIANT_NAME_3.__VARIANT_NAME_4.pvRecord)
#   else
#       define V_RECORDINFO(X) ((X)->pRecInfo)
#       define V_RECORD(X)     ((X)->pvRecord)
#   endif
#endif

extern "C" {
#ifndef GUIDKIND_DEFAULT_SOURCE_DISP_IID
#   define GUIDKIND_DEFAULT_SOURCE_DISP_IID 1
#endif

#ifdef __CYGWIN__
#   undef WIN32			/* don't use with Cygwin & Perl */
#   include <netdb.h>
#   include <sys/socket.h>
#   include <unistd.h>

#   ifndef strrev
#     define strrev my_strrev

static char *
my_strrev(char *str)
{
    char *left = str;
    char *right = left + strlen(left) - 1;
    while (left < right) {
        char temp = *left;
        *left++ = *right;
        *right-- = temp;
    }
    return str;
}

#   endif /* strrev */
#endif

#define PERL_NO_GET_CONTEXT
#define NO_XSLOCKS
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"
#include "patchlevel.h"

#undef WORD
typedef unsigned short WORD;

#ifndef _WIN64
#  define DWORD_PTR	DWORD
#endif

#if PERL_VERSION < 6
#   error Win32::OLE requires Perl 5.6.0 or later
#endif

#ifdef USE_5005THREADS
#   error Win32::OLE is incompatible with 5.005 style threads
#endif

#if PERL_VERSION > 6
#   define my_utf8_to_uv(s) utf8_to_uvuni(s, NULL)
#else
#   if PERL_SUBVERSION > 0
#      define my_utf8_to_uv(s) utf8_to_uv_simple(s, NULL)
#   else
#      define my_utf8_to_uv(s) utf8_to_uv(s, NULL)
#   endif
#endif

#ifndef _DEBUG
#   define DBG(a)
#else
#   define DBG(a)  MyDebug a
void
MyDebug(const char *pat, ...)
{
    DWORD thread = GetCurrentThreadId();
    void *context = PERL_GET_CONTEXT;
    char szBuffer[512];
    char *szMessage = szBuffer + sprintf(szBuffer, "[%d:%p] ", thread, context);
    va_list args;
    va_start(args, pat);
    vsprintf(szMessage, pat, args);
    OutputDebugString(szBuffer);
    va_end(args);
}
#endif

/* constants */
static const DWORD WINOLE_MAGIC = 0x12344321;
static const DWORD WINOLEENUM_MAGIC = 0x12344322;
static const DWORD WINOLEVARIANT_MAGIC = 0x12344323;
static const DWORD WINOLETYPELIB_MAGIC = 0x12344324;
static const DWORD WINOLETYPEINFO_MAGIC = 0x12344325;

static const LCID lcidSystemDefault = 2 << 10;
/* static const LCID lcidDefault = 0; language neutral */
static const LCID lcidDefault = lcidSystemDefault;
static const UINT cpDefault = CP_ACP;
static const BOOL varDefault = FALSE;
static char PERL_OLE_ID[] = "___Perl___OleObject___";
static const int PERL_OLE_IDLEN = sizeof(PERL_OLE_ID)-1;

static const int OLE_BUF_SIZ = 256;

/* class names */
static char szUNICODESTRING[] = "Unicode::String";
static char szWINOLE[] = "Win32::OLE";
static char szWINOLEENUM[] = "Win32::OLE::Enum";
static char szWINOLEVARIANT[] = "Win32::OLE::Variant";
static char szWINOLETIE[] = "Win32::OLE::Tie";
static char szWINOLETYPELIB[] = "Win32::OLE::TypeLib";
static char szWINOLETYPEINFO[] = "Win32::OLE::TypeInfo";

/* class variable names */
static char LCID_NAME[] = "LCID";
static const int LCID_LEN = sizeof(LCID_NAME)-1;
static char CP_NAME[] = "CP";
static const int CP_LEN = sizeof(CP_NAME)-1;
static char VAR_NAME[] = "Variant";
static const int VAR_LEN = sizeof(VAR_NAME)-1;
static char WARN_NAME[] = "Warn";
static const int WARN_LEN = sizeof(WARN_NAME)-1;
static char _NEWENUM_NAME[] = "_NewEnum";
static const int _NEWENUM_LEN = sizeof(_NEWENUM_NAME)-1;
static char _UNIQUE_NAME[] = "_Unique";
static const int _UNIQUE_LEN = sizeof(_UNIQUE_NAME)-1;
static char LASTERR_NAME[] = "LastError";
static const int LASTERR_LEN = sizeof(LASTERR_NAME)-1;
static char TIE_NAME[] = "Tie";
static const int TIE_LEN = sizeof(TIE_NAME)-1;

#define COINIT_OLEINITIALIZE -1
#define COINIT_NO_INITIALIZE -2

typedef HRESULT (STDAPICALLTYPE FNCOINITIALIZEEX)(LPVOID, DWORD);
typedef void (STDAPICALLTYPE FNCOUNINITIALIZE)(void);
typedef HRESULT (STDAPICALLTYPE FNCOCREATEINSTANCEEX)
    (REFCLSID, IUnknown*, DWORD, COSERVERINFO*, DWORD, MULTI_QI*);

typedef HWND (WINAPI FNHTMLHELP)(HWND hwndCaller, LPCSTR pszFile,
				 UINT uCommand, DWORD dwData);

typedef struct _tagOBJECTHEADER OBJECTHEADER;

/* per interpreter variables */
typedef struct
{
    CRITICAL_SECTION CriticalSection;
    OBJECTHEADER *pObj;
    BOOL bInitialized;
    HV *hv_unique;

    /* DCOM function addresses are resolved dynamically */
    HINSTANCE hOLE32;
    FNCOINITIALIZEEX     *pfnCoInitializeEx;
    FNCOUNINITIALIZE     *pfnCoUninitialize;
    FNCOCREATEINSTANCEEX *pfnCoCreateInstanceEx;

    /* HTML Help Control loaded dynamically */
    HINSTANCE hHHCTRL;
    FNHTMLHELP *pfnHtmlHelp;

}   PERINTERP;

#ifdef PERL_IMPLICIT_CONTEXT
#    define dPERINTERP                                                 \
        SV **pinterp = hv_fetch(PL_modglobal, MY_VERSION,              \
                                sizeof(MY_VERSION)-1, FALSE);          \
        if (!pinterp || !*pinterp || !SvIOK(*pinterp))		       \
            warn(MY_VERSION ": Per-interpreter data not initialized"); \
        PERINTERP *pInterp = INT2PTR(PERINTERP*, SvIV(*pinterp))
#    define INTERP pInterp
#else
static PERINTERP Interp;
#   define dPERINTERP extern int errno
#   define INTERP (&Interp)
#endif

#define g_pObj            (INTERP->pObj)
#define g_bInitialized    (INTERP->bInitialized)
#define g_CriticalSection (INTERP->CriticalSection)
#define g_hv_unique       (INTERP->hv_unique)

#define g_hOLE32                (INTERP->hOLE32)
#define g_pfnCoInitializeEx     (INTERP->pfnCoInitializeEx)
#define g_pfnCoUninitialize     (INTERP->pfnCoUninitialize)
#define g_pfnCoCreateInstanceEx (INTERP->pfnCoCreateInstanceEx)

#define g_hHHCTRL               (INTERP->hHHCTRL)
#define g_pfnHtmlHelp           (INTERP->pfnHtmlHelp)

/* common object header */
typedef struct _tagOBJECTHEADER
{
    long lMagic;
    OBJECTHEADER *pNext;
    OBJECTHEADER *pPrevious;
#ifdef PERL_IMPLICIT_CONTEXT
    PERINTERP    *pInterp;
#endif
}   OBJECTHEADER;

#define OBJFLAG_DESTROYED 0x01
#define OBJFLAG_UNIQUE    0x02

/* Win32::OLE object */
class EventSink;
typedef struct
{
    OBJECTHEADER header;

    UV flags;
    IDispatch *pDispatch;
    ITypeInfo *pTypeInfo;
    IEnumVARIANT *pEnum;
    EventSink *pEventSink;

    HV *self;
    HV *hashTable;
    SV *destroy;

    unsigned short cFuncs;
    unsigned short cVars;
    unsigned int   PropIndex;

}   WINOLEOBJECT;

/* Win32::OLE::Enum object */
typedef struct
{
    OBJECTHEADER header;

    IEnumVARIANT *pEnum;

}   WINOLEENUMOBJECT;

/* Win32::OLE::Variant object */
typedef struct
{
    OBJECTHEADER header;

    VARIANT variant;
    VARIANT byref;

}   WINOLEVARIANTOBJECT;

/* Win32::OLE::TypeLib object */
typedef struct
{
    OBJECTHEADER header;

    ITypeLib  *pTypeLib;
    TLIBATTR  *pTLibAttr;

}   WINOLETYPELIBOBJECT;

/* Win32::OLE::TypeInfo object */
typedef struct
{
    OBJECTHEADER header;

    ITypeInfo *pTypeInfo;
    TYPEATTR  *pTypeAttr;

}   WINOLETYPEINFOOBJECT;

/* EventSink class */
class EventSink : public IDispatch
{
 public:
    // IUnknown methods
    STDMETHOD(QueryInterface)(REFIID riid, LPVOID *ppvObj);
    STDMETHOD_(ULONG, AddRef)(void);
    STDMETHOD_(ULONG, Release)(void);

    // IDispatch methods
    STDMETHOD(GetTypeInfoCount)(UINT *pctinfo);
    STDMETHOD(GetTypeInfo)(
      UINT itinfo,
      LCID lcid,
      ITypeInfo **pptinfo);
    STDMETHOD(GetIDsOfNames)(
      REFIID riid,
      OLECHAR **rgszNames,
      UINT cNames,
      LCID lcid,
      DISPID *rgdispid);
    STDMETHOD(Invoke)(
      DISPID dispidMember,
      REFIID riid,
      LCID lcid,
      WORD wFlags,
      DISPPARAMS *pdispparams,
      VARIANT *pvarResult,
      EXCEPINFO *pexcepinfo,
      UINT *puArgErr);

    EventSink(pTHX_ WINOLEOBJECT *pObj, SV *events,
	      REFIID riid, ITypeInfo *pTypeInfo);
    ~EventSink(void);
    HRESULT Advise(IConnectionPoint *pConnectionPoint);
    void Unadvise(void);

 private:
    int m_refcount;
    WINOLEOBJECT *m_pObj;
    IConnectionPoint *m_pConnectionPoint;
    DWORD m_dwCookie;

    SV *m_events;
    IID m_iid;
    ITypeInfo *m_pTypeInfo;
#ifdef PERL_IMPLICIT_CONTEXT
    pTHX;
#endif
};

/* Forwarder class */
class Forwarder : public IDispatch
{
 public:
    // IUnknown methods
    STDMETHOD(QueryInterface)(REFIID riid, LPVOID *ppvObj);
    STDMETHOD_(ULONG, AddRef)(void);
    STDMETHOD_(ULONG, Release)(void);

    // IDispatch methods
    STDMETHOD(GetTypeInfoCount)(UINT *pctinfo);
    STDMETHOD(GetTypeInfo)(
      UINT itinfo,
      LCID lcid,
      ITypeInfo **pptinfo);
    STDMETHOD(GetIDsOfNames)(
      REFIID riid,
      OLECHAR **rgszNames,
      UINT cNames,
      LCID lcid,
      DISPID *rgdispid);
    STDMETHOD(Invoke)(
      DISPID dispidMember,
      REFIID riid,
      LCID lcid,
      WORD wFlags,
      DISPPARAMS *pdispparams,
      VARIANT *pvarResult,
      EXCEPINFO *pexcepinfo,
      UINT *puArgErr);

    Forwarder(pTHX_ HV *stash, SV *method);
    ~Forwarder(void);

 private:
    int m_refcount;
    HV *m_stash;
    SV *m_method;
#ifdef PERL_IMPLICIT_CONTEXT
    pTHX;
#endif
};

/* forward declarations */
HRESULT SetSVFromVariantEx(pTHX_ VARIANTARG *pVariant, SV* sv, HV *stash,
			   BOOL bByRefObj=FALSE);
HRESULT SetVariantFromSVEx(pTHX_ SV* sv, VARIANT *pVariant, UINT cp,
			   LCID lcid);
HRESULT AssignVariantFromSV(pTHX_ SV* sv, VARIANT *pVariant,
			    UINT cp, LCID lcid);

//------------------------------------------------------------------------

void
MagicGet(pTHX_ SV *sv)
{
    if (SvGMAGICAL(sv)) {
        mg_get(sv);

        // If the sv has lvalue magic (e.g. substr), it will stay magical
        // and mg_get() will *not* set the public flags.  We try to work
        // around this here for at least the "substr" and "vec" cases.
        //
        // Setting the public POK flag should be safe because this function
        // is only called on function arguments, which will be discarded
        // once the function returns.

        if (SvGMAGICAL(sv) && SvPOKp(sv))
            SvPOK_on(sv);
    }
}

BOOL
StartsWithAlpha(pTHX_ SV *sv)
{
    char *str = SvPV_nolen(sv);
    if (SvUTF8(sv))
        return isALPHA_uni(my_utf8_to_uv((U8*)str));
    else
        return isALPHA(*str);
}

inline void
SpinMessageLoop(void)
{
    MSG msg;

    DBG(("SpinMessageLoop\n"));
    while (PeekMessage(&msg, NULL, 0, 0, PM_REMOVE)) {
	TranslateMessage(&msg);
	DispatchMessage(&msg);
    }

}   /* SpinMessageLoop */

BOOL
IsLocalMachine(pTHX_ SV *host)
{
    char szComputerName[MAX_COMPUTERNAME_LENGTH+1];
    DWORD dwSize = sizeof(szComputerName);
    char *pszMachine = SvPV_nolen(host);
    char *pszName = pszMachine;

    while (*pszName == '\\')
	++pszName;

    if (*pszName == '\0')
	return TRUE;

    /* Check against local computer name (from registry) */
    if (GetComputerNameA(szComputerName, &dwSize)
        && stricmp(pszName, szComputerName) == 0)
    {
        return TRUE;
    }

    /* gethostname(), gethostbyname() and inet_addr() all call proxy functions
     * in the Perl socket layer wrapper in win32sck.c. Therefore calling
     * WSAStartup() here is not necessary.
     */

    /* Determine main host name of local machine */
    char szBuffer[200];
    if (gethostname(szBuffer, sizeof(szBuffer)) != 0)
	return FALSE;

    /* Copy list of addresses for local machine */
    struct hostent *pHostEnt = gethostbyname(szBuffer);
    if (!pHostEnt)
	return FALSE;

    if (pHostEnt->h_addrtype != PF_INET || pHostEnt->h_length != 4) {
	warn(MY_VERSION ": IsLocalMachine() gethostbyname failure");
	return FALSE;
    }

    int index;
    int count = 0;
    char *pLocal;
    while (pHostEnt->h_addr_list[count])
	++count;

    New(0, pLocal, 4*count, char);
    for (index = 0; index < count; ++index)
	memcpy(pLocal+4*index, pHostEnt->h_addr_list[index], 4);

    /* Determine addresses of remote machine */
    unsigned long ulRemoteAddr;
    char *pRemote[2] = {NULL, NULL};
    char **ppRemote = &pRemote[0];

    if (isdigit(*pszMachine)) {
	/* Convert numeric dotted address */
	ulRemoteAddr = inet_addr(pszMachine);
	if (ulRemoteAddr != INADDR_NONE)
	    pRemote[0] = (char*)&ulRemoteAddr;
    }
    else {
	/* Lookup addresses for remote host name */
	pHostEnt = gethostbyname(pszMachine);
	if (pHostEnt)
	    if (pHostEnt->h_addrtype == PF_INET && pHostEnt->h_length == 4)
		ppRemote = pHostEnt->h_addr_list;
    }

    /* Compare list of addresses of remote machine against local addresses */
    while (*ppRemote) {
	for (index = 0; index < count; ++index)
	    if (memcmp(pLocal+4*index, *ppRemote, 4) == 0) {
		Safefree(pLocal);
		return TRUE;
	    }
	++ppRemote;
    }

    Safefree(pLocal);
    return FALSE;

}   /* IsLocalMachine */

HRESULT
CLSIDFromRemoteRegistry(pTHX_ SV *host, SV *progid, CLSID *pCLSID)
{
    HKEY hKeyLocalMachine;
    HKEY hKeyProgID;
    LONG err;
    HRESULT hr = S_OK;

    err = RegConnectRegistryA(SvPV_nolen(host), HKEY_LOCAL_MACHINE, &hKeyLocalMachine);
    if (err != ERROR_SUCCESS)
	return HRESULT_FROM_WIN32(err);

    SV *subkey = sv_2mortal(newSVpv("SOFTWARE\\Classes\\", 0));
    sv_catsv(subkey, progid);
    sv_catpv(subkey, "\\CLSID");

    err = RegOpenKeyExA(hKeyLocalMachine, SvPV_nolen(subkey), 0, KEY_READ,
                        &hKeyProgID);
    if (err != ERROR_SUCCESS)
	hr = HRESULT_FROM_WIN32(err);
    else {
	DWORD dwType;
	char szCLSID[100];
	DWORD dwLength = sizeof(szCLSID);

	err = RegQueryValueEx(hKeyProgID, "", NULL, &dwType,
			      (unsigned char*)&szCLSID, &dwLength);
	if (err != ERROR_SUCCESS)
	    hr = HRESULT_FROM_WIN32(err);
	else if (dwType == REG_SZ) {
	    OLECHAR wszCLSID[sizeof(szCLSID)];

	    MultiByteToWideChar(CP_ACP, 0, szCLSID, -1,
				wszCLSID, sizeof(szCLSID));
	    hr = CLSIDFromString(wszCLSID, pCLSID);
	}
	else /* XXX maybe there is a more appropriate error code? */
	    hr = HRESULT_FROM_WIN32(ERROR_CANTREAD);

	RegCloseKey(hKeyProgID);
    }

    RegCloseKey(hKeyLocalMachine);
    return hr;

}   /* CLSIDFromRemoteRegistry */

/* The following strategy is used to avoid the limitations of hardcoded
 * buffer sizes: Conversion between wide char and multibyte strings
 * is performed by GetMultiByte and GetWideChar respectively. The
 * caller passes a default buffer and size. If the buffer is too small
 * then the conversion routine allocates a new buffer that is big enough.
 * The caller must free this buffer using the ReleaseBuffer function. */

inline void
ReleaseBuffer(pTHX_ void *pszHeap, void *pszStack)
{
    if (pszHeap != pszStack && pszHeap)
	Safefree(pszHeap);
}

char *
GetMultiByteEx(pTHX_ OLECHAR *wide, int *pcch, char *psz, int len, UINT cp)
{
    int count;

    if (psz) {
	if (!wide || !*pcch) {
 fail:
	    *psz = (char)0;
            *pcch = 0;
	    return psz;
	}
	count = WideCharToMultiByte(cp, 0, wide, *pcch, psz, len, NULL, NULL);
	if (count > 0)
            goto succeed;
    }
    else if (!wide || !*pcch) {
	Newz(0, psz, 1, char);
        *pcch = 0;
	return psz;
    }

    count = WideCharToMultiByte(cp, 0, wide, *pcch, NULL, 0, NULL, NULL);
    if (count == 0) { /* should never happen */
	warn(MY_VERSION ": GetMultiByte() failure: %lu", GetLastError());
	DEBUGBREAK;
	if (!psz)
	    New(0, psz, 1, char);
        goto fail;
    }

    Newz(0, psz, count, char);
    WideCharToMultiByte(cp, 0, wide, *pcch, psz, count, NULL, NULL);

 succeed:
    if (*pcch == -1)
        *pcch = count - 1; /* because count includes the trailing '\0' */
    else
        *pcch = count;
    return psz;

}   /* GetMultiByteEx */

char *
GetMultiByte(pTHX_ OLECHAR *wide, char *psz, int len, UINT cp)
{
    int cch = -1;
    return GetMultiByteEx(aTHX_ wide, &cch, psz, len, cp);
}

SV *
sv_setbstr(pTHX_ SV *sv, BSTR bstr, UINT cp)
{
    if (!bstr) {
        if (sv)
            sv_setpvn(sv, "", 0);
        else
            sv = newSVpvn("", 0);
        return sv;
    }

    int len = WideCharToMultiByte(cp, 0, bstr, SysStringLen(bstr),
                                  NULL, 0, NULL, NULL);
    if (sv)
        sv_grow(sv, len+1);
    else
        sv = newSV(len+1);

    WideCharToMultiByte(cp, 0, bstr, SysStringLen(bstr),
                        SvPVX(sv), len, NULL, NULL);
    SvPOK_on(sv);
    SvPVX(sv)[len] = '\0';
    SvCUR_set(sv, len);

    if (cp == CP_UTF8) {
        SvUTF8_on(sv);
        sv_utf8_downgrade(sv, TRUE);
    }
    return sv;
}

OLECHAR *
GetWideChar(pTHX_ SV *sv, OLECHAR *wide, int len, UINT cp)
{
    /* Note: len is number of OLECHARs, not bytes! */
    int count;
    STRLEN strlen;
    char *str = NULL;

    if (sv) {
        str = SvPV(sv, strlen);
        ++strlen; // include trailing '\0' character
        if (cp == CP_UTF8 && !SvUTF8(sv))
            cp = CP_ACP;
    }

    if (wide) {
	if (!str) {
	    *wide = (OLECHAR) 0;
	    return wide;
	}
	count = MultiByteToWideChar(cp, 0, str, (int)strlen, wide, len);
	if (count > 0)
	    return wide;
    }
    else if (!str) {
	Newz(0, wide, 1, OLECHAR);
	return wide;
    }

    count = MultiByteToWideChar(cp, 0, str, (int)strlen, NULL, 0);
    if (count == 0) {
	warn(MY_VERSION ": GetWideChar() failure: %lu", GetLastError());
	DEBUGBREAK;
	if (!wide)
	    New(0, wide, 1, OLECHAR);
	*wide = (OLECHAR) 0;
	return wide;
    }

    Newz(0, wide, count, OLECHAR);
    MultiByteToWideChar(cp, 0, str, (int)strlen, wide, count);
    return wide;

}   /* GetWideChar */

HV *
GetStash(pTHX_ SV *sv)
{
    if (sv_isobject(sv))
	return SvSTASH(SvRV(sv));
    else if (SvPOK(sv))
	return gv_stashsv(sv, TRUE);
    else
	return (HV*)&PL_sv_undef;

}   /* GetStash */

HV *
GetWin32OleStash(pTHX_ SV *sv)
{
    SV *pkg;

    if (sv_isobject(sv))
	pkg = newSVpv(HvNAME(SvSTASH(SvRV(sv))), 0);
    else if (SvPOK(sv))
	pkg = newSVpv(SvPVX(sv), SvCUR(sv));
    else
	pkg = newSVpv(szWINOLE, 0); /* should never happen */

    char *pszColon = strrchr(SvPVX(pkg), ':');
    if (pszColon) {
	--pszColon;
	while (pszColon > SvPVX(pkg) && *pszColon == ':')
	    --pszColon;
	SvCUR_set(pkg, pszColon - SvPVX(pkg) + 1);
	SvPVX(pkg)[SvCUR(pkg)] = '\0';
    }

    HV *stash = gv_stashsv(pkg, TRUE);
    SvREFCNT_dec(pkg);
    return stash;

}   /* GetWin32OleStash */

IV
QueryPkgVar(pTHX_ HV *stash, char *var, STRLEN len, IV def=0)
{
    SV *sv;
    GV **gv = (GV**)hv_fetch(stash, var, (I32)len, FALSE);

    if (gv && (sv = GvSV(*gv)) != NULL && SvIOK(sv)) {
	DBG(("QueryPkgVar(%s::%s) returns %d\n", HvNAME(stash), var, SvIV(sv)));
	return SvIV(sv);
    }

    DBG(("QueryPkgVar(%s::%s) default %d\n", HvNAME(stash), var, def));
    return def;
}

void
SetLastOleError(pTHX_ HV *stash, HRESULT hr=S_OK, char *pszMsg=NULL)
{
    /* Find $Win32::OLE::LastError */
    SV *sv = sv_2mortal(newSVpv(HvNAME(stash), 0));
    sv_catpvn(sv, "::", 2);
    sv_catpvn(sv, LASTERR_NAME, LASTERR_LEN);
    SV *lasterr = perl_get_sv(SvPV_nolen(sv), TRUE);
    if (!lasterr) {
	warn(MY_VERSION ": SetLastOleError: couldnot create variable %s",
	     LASTERR_NAME);
	DEBUGBREAK;
	return;
    }

    sv_setiv(lasterr, (IV)hr);
    if (pszMsg) {
	sv_setpv(lasterr, pszMsg);
	SvIOK_on(lasterr);
    }
}

void
ReportOleError(pTHX_ HV *stash, HRESULT hr, EXCEPINFO *pExcep=NULL,
	       SV *svAdd=NULL)
{
    dSP;

    SV *sv;
    IV warnlvl = QueryPkgVar(aTHX_ stash, WARN_NAME, WARN_LEN);
    GV **pgv = (GV**)hv_fetch(stash, WARN_NAME, WARN_LEN, FALSE);
    CV *cv = Nullcv;

    if (pgv && (sv = GvSV(*pgv)) && SvROK(sv) && SvTYPE(SvRV(sv)) == SVt_PVCV)
	cv = (CV*)sv;

    sv = sv_2mortal(newSV(200));
    SvPOK_on(sv);

    /* start with exception info */
    if (pExcep && (pExcep->bstrSource || pExcep->bstrDescription)) {
	char szSource[80] = "<Unknown Source>";
	char szDesc[200] = "<No description provided>";

	char *pszSource = szSource;
	char *pszDesc = szDesc;

	UINT cp = (UINT)QueryPkgVar(aTHX_ stash, CP_NAME, CP_LEN, cpDefault);
	if (pExcep->bstrSource)
	    pszSource = GetMultiByte(aTHX_ pExcep->bstrSource,
				     szSource, sizeof(szSource), cp);

	if (pExcep->bstrDescription)
	    pszDesc = GetMultiByte(aTHX_ pExcep->bstrDescription,
				   szDesc, sizeof(szDesc), cp);

	sv_setpvf(sv, "OLE exception from \"%s\":\n\n%s\n\n",
		  pszSource, pszDesc);

	ReleaseBuffer(aTHX_ pszSource, szSource);
	ReleaseBuffer(aTHX_ pszDesc, szDesc);
	/* SysFreeString accepts NULL too */
	SysFreeString(pExcep->bstrSource);
	SysFreeString(pExcep->bstrDescription);
	SysFreeString(pExcep->bstrHelpFile);
    }

    /* always include OLE error code */
    sv_catpvf(sv, MY_VERSION " error 0x%08x", hr);

    /* try to append ': "error text"' from message catalog */
    char *pszMsgText;
    DWORD dwCount;
    dwCount = FormatMessageA(FORMAT_MESSAGE_ALLOCATE_BUFFER |
                             FORMAT_MESSAGE_FROM_SYSTEM |
                             FORMAT_MESSAGE_IGNORE_INSERTS,
                             NULL, hr, lcidSystemDefault,
                             (LPSTR)&pszMsgText, 0, NULL);
    if (dwCount > 0) {
	sv_catpv(sv, ": \"");
	/* remove trailing dots and CRs/LFs from message */
	while (dwCount > 0 &&
	       (pszMsgText[dwCount-1] < ' ' || pszMsgText[dwCount-1] == '.'))
	    pszMsgText[--dwCount] = '\0';

	/* skip carriage returns in message text */
	char *psz = pszMsgText;
	char *pCR;
	while ((pCR = strchr(psz, '\r')) != NULL) {
	    sv_catpvn(sv, psz, pCR-psz);
	    psz = pCR+1;
	}
	if (*psz != '\0')
	    sv_catpv(sv, psz);
	sv_catpv(sv, "\"");
	LocalFree(pszMsgText);
    }

    /* add additional error details */
    if (svAdd) {
	sv_catpv(sv, "\n    ");
	sv_catsv(sv, svAdd);
    }

    /* try to keep linelength of description below 80 chars. */
    char *pLastBlank = NULL;
    char *pch = SvPVX(sv);
    int  cch;

    for (cch = 0; *pch; ++pch, ++cch) {
	if (*pch == ' ') {
	    pLastBlank = pch;
	}
	else if (*pch == '\n') {
	    pLastBlank = pch;
	    cch = 0;
	}

	if (cch > 76 && pLastBlank) {
	    *pLastBlank = '\n';
	    cch = (int)(pch - pLastBlank);
	}
    }

    SetLastOleError(aTHX_ stash, hr, SvPVX(sv));

    DBG(("ReportOleError: hr=0x%08x warnlvl=%d\n%s", hr, warnlvl, SvPVX(sv)));

    if (!cv && (warnlvl > 1 || (warnlvl == 1 && (PL_dowarn & G_WARN_ON)))) {
	if (warnlvl < 3) {
	    cv = perl_get_cv("Carp::carp", FALSE);
	    if (!cv)
		warn(SvPVX(sv));
	}
	else {
	    cv = perl_get_cv("Carp::croak", FALSE);
	    if (!cv)
		croak(SvPVX(sv));
	}
    }

    if (cv) {
        ENTER;
        SAVETMPS;
        PUSHMARK(sp);
        XPUSHs(sv);
        PUTBACK;
        perl_call_sv((SV*)cv, G_DISCARD|G_EVAL);
        FREETMPS;
        LEAVE;
        if (SvTRUE(ERRSV)) {
#if defined(ACTIVEPERL_CHANGELIST) || (PERL_VERSION > 6 || PERL_SUBVERSION > 0)
            if (sv_isobject(ERRSV))
                croak(Nullch); /* rethrow exception */
            else
                croak("%s", SvPV_nolen(ERRSV));
#else
            croak("%s", SvPV_nolen(ERRSV));
#endif
        }
    }

}   /* ReportOleError */

inline BOOL
CheckOleError(pTHX_ HV *stash, HRESULT hr, EXCEPINFO *pExcep=NULL,
	      SV *svAdd=NULL)
{
    if (FAILED(hr)) {
	ReportOleError(aTHX_ stash, hr, pExcep, svAdd);
	return TRUE;
    }
    return FALSE;
}

SV *
CheckDestroyFunction(pTHX_ SV *sv, char *szMethod)
{
    /* undef */
    if (!SvOK(sv))
	return NULL;

    /* method name or CODE ref */
    if (SvPOK(sv) || (SvROK(sv) && SvTYPE(SvRV(sv)) == SVt_PVCV))
	return sv;

    warn("%s(): DESTROY must be a method name or a CODE reference", szMethod);
    DEBUGBREAK;
    return NULL;
}

void
AddToObjectChain(pTHX_ OBJECTHEADER *pHeader, long lMagic)
{
    dPERINTERP;
    DBG(("AddToObjectChain(0x%08x) lMagic=0x%08x", pHeader, lMagic));

    EnterCriticalSection(&g_CriticalSection);
    pHeader->lMagic = lMagic;
    pHeader->pPrevious = NULL;
    pHeader->pNext = g_pObj;

#ifdef PERL_IMPLICIT_CONTEXT
    pHeader->pInterp = INTERP;
#endif

    if (g_pObj)
	g_pObj->pPrevious = pHeader;
    g_pObj = pHeader;
    LeaveCriticalSection(&g_CriticalSection);
}

void
RemoveFromObjectChain(pTHX_ OBJECTHEADER *pHeader)
{
    DBG(("RemoveFromObjectChain(0x%08x) lMagic=0x%08x\n", pHeader,
	 pHeader ? pHeader->lMagic : 0));

    if (!pHeader)
	return;

#ifdef PERL_IMPLICIT_CONTEXT
    PERINTERP *pInterp = pHeader->pInterp;
#endif

    EnterCriticalSection(&g_CriticalSection);
    if (!pHeader->pPrevious) {
	g_pObj = pHeader->pNext;
	if (g_pObj)
	    g_pObj->pPrevious = NULL;
    }
    else if (!pHeader->pNext)
	pHeader->pPrevious->pNext = NULL;
    else {
	pHeader->pPrevious->pNext = pHeader->pNext;
	pHeader->pNext->pPrevious = pHeader->pPrevious;
    }
    pHeader->lMagic = 0;
    LeaveCriticalSection(&g_CriticalSection);
}

SV *
CreatePerlObject(pTHX_ HV *stash, IDispatch *pDispatch, SV *destroy)
{
    dPERINTERP;

    /* returns a mortal reference to a new Perl OLE object */

    IV unique = QueryPkgVar(aTHX_ stash, _UNIQUE_NAME, _UNIQUE_LEN);
    if (unique) {
        IUnknown *punk; // XXX check error?
        pDispatch->QueryInterface(IID_IUnknown, (void**)&punk);
        SV **svp = hv_fetch(g_hv_unique, (char*)&punk, sizeof(punk), FALSE);
        DBG(("hv_fetch(%08x) returned %08x", punk, svp));
        punk->Release();
        if (svp)
            return sv_2mortal(sv_bless(newRV(INT2PTR(SV*, SvIV(*svp))), stash));
    }

    if (!pDispatch) {
	warn(MY_VERSION ": CreatePerlObject() No IDispatch interface");
	DEBUGBREAK;
	return &PL_sv_undef;
    }

    WINOLEOBJECT *pObj;
    HV *hvinner = newHV();
    SV *inner;
    SV *sv;
    GV **gv = (GV**)hv_fetch(stash, TIE_NAME, TIE_LEN, FALSE);
    char *szTie = szWINOLETIE;

    if (gv && (sv = GvSV(*gv)) != NULL && SvPOK(sv))
	szTie = SvPV_nolen(sv);

    New(0, pObj, 1, WINOLEOBJECT);
    pObj->flags = 0;
    pObj->pDispatch = pDispatch;
    pObj->pTypeInfo = NULL;
    pObj->pEnum = NULL;
    pObj->pEventSink = NULL;
    pObj->hashTable = newHV();
    pObj->self = newHV();

    pObj->destroy = NULL;
    if (destroy) {
	if (SvPOK(destroy))
	    pObj->destroy = newSVsv(destroy);
	else if (SvROK(destroy) && SvTYPE(SvRV(destroy)) == SVt_PVCV)
	    pObj->destroy = newRV_inc(SvRV(destroy));
    }

    if (unique) {
        IUnknown *punk; // XXX check error?
        pDispatch->QueryInterface(IID_IUnknown, (void**)&punk);
        /* use XIV as a weak reference */
        SV **svp = hv_store(g_hv_unique, (char*)&punk, sizeof(punk),
                            newSViv(PTR2IV(pObj->self)), 0);
        DBG(("hv_store(%08x) returned %08x", punk, svp));
        punk->Release();
        pObj->flags |= OBJFLAG_UNIQUE;
    }

    AddToObjectChain(aTHX_ &pObj->header, WINOLE_MAGIC);

    DBG(("CreatePerlObject=|%lx| Class=%s Tie=%s pDispatch=0x%x\n", pObj,
	 HvNAME(stash), szTie, pDispatch));

    hv_store(hvinner, PERL_OLE_ID, PERL_OLE_IDLEN, newSViv(PTR2IV(pObj)), 0);
    inner = sv_bless(newRV_noinc((SV*)hvinner), gv_stashpv(szTie, TRUE));
    sv_magic((SV*)pObj->self, inner, 'P', Nullch, 0);
    SvREFCNT_dec(inner);

    return sv_2mortal(sv_bless(newRV_noinc((SV*)pObj->self), stash));

}   /* CreatePerlObject */

void
ReleasePerlObject(pTHX_ WINOLEOBJECT *pObj)
{
    dSP;
    HV *stash = SvSTASH(pObj->self);

    DBG(("ReleasePerlObject |%lx|", pObj));

    if (!pObj)
	return;

    /* ReleasePerlObject may be called multiple times for a single object:
     * first by Uninitialize() and then by Win32::OLE::DESTROY.
     * Make sure nothing is cleaned up twice!
     */

    if (pObj->destroy) {
	SV *self = sv_2mortal(newRV_inc((SV*)pObj->self));

	/* honour OVERLOAD setting */
	if (Gv_AMG(stash))
	    SvAMAGIC_on(self);

	DBG((" Calling destroy method for object |%lx|\n", pObj));
	ENTER;
        SAVETMPS;
	if (SvPOK(pObj->destroy)) {
	    /* $self->Dispatch($destroy,$retval); */
	    EXTEND(SP, 3);
	    PUSHMARK(sp);
	    PUSHs(self);
	    PUSHs(pObj->destroy);
	    PUSHs(sv_newmortal());
	    PUTBACK;
	    perl_call_method("Dispatch", G_DISCARD);
	}
	else {
	    /* &$destroy($self); */
	    PUSHMARK(sp);
	    XPUSHs(self);
	    PUTBACK;
	    perl_call_sv(pObj->destroy, G_DISCARD);
	}
        FREETMPS;
	LEAVE;
	DBG((" Returned from destroy method for 0x%08x\n", pObj));

	SvREFCNT_dec(pObj->destroy);
	pObj->destroy = NULL;
    }

    if (pObj->pEventSink) {
	DBG((" Unadvise connection |%lx|", pObj));
	pObj->pEventSink->Unadvise();
	pObj->pEventSink = NULL;
    }

    if (pObj->pDispatch) {
        if (pObj->flags & OBJFLAG_UNIQUE) {
            dPERINTERP;
            IUnknown *punk; // XXX check error?
            pObj->pDispatch->QueryInterface(IID_IUnknown, (void**)&punk);
            hv_delete(g_hv_unique, (char*)&punk, sizeof(punk), G_DISCARD);
            DBG((" hv_delete(%08x)", punk));
            punk->Release();
        }
	DBG((" Release pDispatch"));
	pObj->pDispatch->Release();
	pObj->pDispatch = NULL;
    }

    if (pObj->pTypeInfo) {
	DBG((" Release pTypeInfo"));
	pObj->pTypeInfo->Release();
	pObj->pTypeInfo = NULL;
    }

    if (pObj->pEnum) {
	DBG((" Release pEnum"));
	pObj->pEnum->Release();
	pObj->pEnum = NULL;
    }

    if (pObj->destroy) {
	DBG((" destroy(%d)", SvREFCNT(pObj->destroy)));
	SvREFCNT_dec(pObj->destroy);
	pObj->destroy = NULL;
    }

    if (pObj->hashTable) {
	DBG((" hashTable(%d)", SvREFCNT(pObj->hashTable)));
	SvREFCNT_dec(pObj->hashTable);
	pObj->hashTable = NULL;
    }

    DBG(("\n"));

}   /* ReleasePerlObject */

WINOLEOBJECT *
GetOleObject(pTHX_ SV *sv, BOOL bDESTROY=FALSE)
{
    if (sv_isobject(sv) && SvTYPE(SvRV(sv)) == SVt_PVHV) {
	SV **psv = hv_fetch((HV*)SvRV(sv), PERL_OLE_ID, PERL_OLE_IDLEN, 0);

	/* Win32::OLE::Tie::DESTROY called before Win32::OLE::DESTROY? */
	if (!psv && bDESTROY)
	    return NULL;

	if (psv)
	    MagicGet(aTHX_ *psv);

	if (psv && SvIOK(*psv)) {
	    WINOLEOBJECT *pObj = INT2PTR(WINOLEOBJECT*, SvIV(*psv));

	    DBG(("GetOleObject = |%lx|\n", pObj));
	    if (pObj && pObj->header.lMagic == WINOLE_MAGIC)
		if (pObj->pDispatch || bDESTROY)
		    return pObj;
	}
    }
    warn(MY_VERSION ": GetOleObject() Not a %s object", szWINOLE);
    DEBUGBREAK;
    return (WINOLEOBJECT*)NULL;
}

WINOLEENUMOBJECT *
GetOleEnumObject(pTHX_ SV *sv, BOOL bDESTROY=FALSE)
{
    if (sv_isobject(sv) && sv_derived_from(sv, szWINOLEENUM)) {
	WINOLEENUMOBJECT *pEnumObj = INT2PTR(WINOLEENUMOBJECT*, SvIV(SvRV(sv)));

	if (pEnumObj && pEnumObj->header.lMagic == WINOLEENUM_MAGIC)
	    if (pEnumObj->pEnum || bDESTROY)
		return pEnumObj;
    }
    warn(MY_VERSION ": GetOleEnumObject() Not a %s object", szWINOLEENUM);
    DEBUGBREAK;
    return (WINOLEENUMOBJECT*)NULL;
}

WINOLEVARIANTOBJECT *
GetOleVariantObject(pTHX_ SV *sv, BOOL bWarn=TRUE)
{
    if (sv_isobject(sv) && sv_derived_from(sv, szWINOLEVARIANT)) {
	WINOLEVARIANTOBJECT *pVarObj = INT2PTR(WINOLEVARIANTOBJECT*, SvIV(SvRV(sv)));

	if (pVarObj && pVarObj->header.lMagic == WINOLEVARIANT_MAGIC)
	    return pVarObj;
    }
    if (bWarn) {
	warn(MY_VERSION ": GetOleVariantObject() Not a %s object",
	     szWINOLEVARIANT);
	DEBUGBREAK;
    }
    return (WINOLEVARIANTOBJECT*)NULL;
}

SV *
CreateTypeLibObject(pTHX_ ITypeLib *pTypeLib, TLIBATTR *pTLibAttr)
{
    WINOLETYPELIBOBJECT *pObj;
    New(0, pObj, 1, WINOLETYPELIBOBJECT);

    pObj->pTypeLib = pTypeLib;
    pObj->pTLibAttr = pTLibAttr;

    AddToObjectChain(aTHX_ (OBJECTHEADER*)pObj, WINOLETYPELIB_MAGIC);

    return sv_bless(newRV_noinc(newSViv(PTR2IV(pObj))),
		    gv_stashpv(szWINOLETYPELIB, TRUE));
}

WINOLETYPELIBOBJECT *
GetOleTypeLibObject(pTHX_ SV *sv)
{
    if (sv_isobject(sv) && sv_derived_from(sv, szWINOLETYPELIB)) {
	WINOLETYPELIBOBJECT *pObj = INT2PTR(WINOLETYPELIBOBJECT*, SvIV(SvRV(sv)));

	if (pObj && pObj->header.lMagic == WINOLETYPELIB_MAGIC)
	    return pObj;
    }
    warn(MY_VERSION ": GetOleTypeLibObject() Not a %s object", szWINOLETYPELIB);
    DEBUGBREAK;
    return (WINOLETYPELIBOBJECT*)NULL;
}

SV *
CreateTypeInfoObject(pTHX_ ITypeInfo *pTypeInfo, TYPEATTR *pTypeAttr)
{
    WINOLETYPEINFOOBJECT *pObj;
    New(0, pObj, 1, WINOLETYPEINFOOBJECT);

    pObj->pTypeInfo = pTypeInfo;
    pObj->pTypeAttr = pTypeAttr;

    AddToObjectChain(aTHX_ (OBJECTHEADER*)pObj, WINOLETYPEINFO_MAGIC);

    return sv_bless(newRV_noinc(newSViv(PTR2IV(pObj))),
		    gv_stashpv(szWINOLETYPEINFO, TRUE));
}

WINOLETYPEINFOOBJECT *
GetOleTypeInfoObject(pTHX_ SV *sv)
{
    if (sv_isobject(sv) && sv_derived_from(sv, szWINOLETYPEINFO)) {
	WINOLETYPEINFOOBJECT *pObj = INT2PTR(WINOLETYPEINFOOBJECT*, SvIV(SvRV(sv)));

	if (pObj && pObj->header.lMagic == WINOLETYPEINFO_MAGIC)
	    return pObj;
    }
    warn(MY_VERSION ": GetOleTypeInfoObject() Not a %s object",
	 szWINOLETYPEINFO);
    DEBUGBREAK;
    return (WINOLETYPEINFOOBJECT*)NULL;
}

BSTR
AllocOleString(pTHX_ char* pStr, int length, UINT cp)
{
    int count = MultiByteToWideChar(cp, 0, pStr, length, NULL, 0);
    BSTR bstr = SysAllocStringLen(NULL, count);
    MultiByteToWideChar(cp, 0, pStr, length, bstr, count);
    return bstr;
}

BSTR
AllocOleStringFromSV(pTHX_ SV *sv, UINT cp)
{
    STRLEN len;

    if (SvROK(sv) && sv_derived_from(sv, szUNICODESTRING)) {
        sv = SvRV(sv);
        U16 *pus = (U16*)SvPV(sv, len);
        BSTR bstr = SysAllocStringLen(NULL, (UINT)(len/2));
        for (STRLEN i=0; i < len; ++i)
            bstr[i] = ntohs(pus[i]);
        return bstr;
    }

    if (cp == CP_UTF8 && !SvUTF8(sv))
        cp = CP_ACP;

    char *str = SvPV(sv, len);
    int count = MultiByteToWideChar(cp, 0, str, (int)len, NULL, 0);
    BSTR bstr = SysAllocStringLen(NULL, count);
    MultiByteToWideChar(cp, 0, str, (int)len, bstr, count);
    return bstr;
}

HRESULT
GetHashedDispID(pTHX_ WINOLEOBJECT *pObj, SV *sv,
		DISPID &dispID, LCID lcid, UINT cp)
{
    HRESULT hr;

    if (!SvPOK(sv) || !SvLEN(sv)) {
	dispID = DISPID_VALUE;
	return S_OK;
    }

    HE *he = hv_fetch_ent(pObj->hashTable, sv, TRUE, 0);
    if (SvIOK(HeVAL(he))) {
	dispID = (DISPID)SvIV(HeVAL(he));
	return S_OK;
    }

    /* not there so get info and add it */
    DISPID id;
    OLECHAR Buffer[OLE_BUF_SIZ];
    OLECHAR *pBuffer;

    pBuffer = GetWideChar(aTHX_ sv, Buffer, OLE_BUF_SIZ, cp);
    hr = pObj->pDispatch->GetIDsOfNames(IID_NULL, &pBuffer, 1, lcid, &id);
    ReleaseBuffer(aTHX_ pBuffer, Buffer);
    /* Don't call CheckOleError! Caller might retry the "unnamed" method */
    if (SUCCEEDED(hr)) {
        sv_setiv(HeVAL(he), id);
	dispID = id;
    }
    return hr;

}   /* GetHashedDispID */

void
FetchTypeInfo(pTHX_ WINOLEOBJECT *pObj)
{
    unsigned int count;
    ITypeInfo *pTypeInfo;
    TYPEATTR  *pTypeAttr;
    HV *stash = SvSTASH(pObj->self);

    if (pObj->pTypeInfo)
	return;

    HRESULT hr = pObj->pDispatch->GetTypeInfoCount(&count);
    if (hr == E_NOTIMPL || count == 0) {
	DBG(("GetTypeInfoCount returned %u (count=%d)", hr, count));
	return;
    }

    if (CheckOleError(aTHX_ stash, hr)) {
	warn(MY_VERSION ": FetchTypeInfo() GetTypeInfoCount failed");
	DEBUGBREAK;
	return;
    }

    LCID lcid = (LCID)QueryPkgVar(aTHX_ stash, LCID_NAME, LCID_LEN, lcidDefault);
    hr = pObj->pDispatch->GetTypeInfo(0, lcid, &pTypeInfo);
    if (CheckOleError(aTHX_ stash, hr))
	return;

    hr = pTypeInfo->GetTypeAttr(&pTypeAttr);
    if (FAILED(hr)) {
	pTypeInfo->Release();
	ReportOleError(aTHX_ stash, hr);
	return;
    }

    if (pTypeAttr->typekind != TKIND_DISPATCH) {
	int cImplTypes = pTypeAttr->cImplTypes;
	pTypeInfo->ReleaseTypeAttr(pTypeAttr);
	pTypeAttr = NULL;

	for (int i=0; i < cImplTypes; ++i) {
	    HREFTYPE hreftype;
	    ITypeInfo *pRefTypeInfo;

	    hr = pTypeInfo->GetRefTypeOfImplType(i, &hreftype);
	    if (FAILED(hr))
		break;

	    hr = pTypeInfo->GetRefTypeInfo(hreftype, &pRefTypeInfo);
	    if (FAILED(hr))
		break;

	    hr = pRefTypeInfo->GetTypeAttr(&pTypeAttr);
	    if (FAILED(hr)) {
		pRefTypeInfo->Release();
		break;
	    }

	    if (pTypeAttr->typekind == TKIND_DISPATCH) {
		pTypeInfo->Release();
		pTypeInfo = pRefTypeInfo;
		break;
	    }

	    pRefTypeInfo->ReleaseTypeAttr(pTypeAttr);
	    pRefTypeInfo->Release();
	    pTypeAttr = NULL;
	}
    }

    if (FAILED(hr)) {
	pTypeInfo->Release();
	ReportOleError(aTHX_ stash, hr);
	return;
    }

    if (pTypeAttr) {
	if (pTypeAttr->typekind == TKIND_DISPATCH) {
	    pObj->cFuncs = pTypeAttr->cFuncs;
	    pObj->cVars = pTypeAttr->cVars;
	    pObj->PropIndex = 0;
	    pObj->pTypeInfo = pTypeInfo;
	}

	pTypeInfo->ReleaseTypeAttr(pTypeAttr);
	if (!pObj->pTypeInfo)
	    pTypeInfo->Release();
    }

}   /* FetchTypeInfo */

SV *
NextPropertyName(pTHX_ WINOLEOBJECT *pObj)
{
    HRESULT hr;
    unsigned int cName;
    BSTR bstr;

    if (!pObj->pTypeInfo)
	return NULL;

    HV *stash = SvSTASH(pObj->self);
    UINT cp = (UINT)QueryPkgVar(aTHX_ stash, CP_NAME, CP_LEN, cpDefault);
    int newenum = (int)QueryPkgVar(aTHX_ stash, _NEWENUM_NAME, _NEWENUM_LEN);

    while (pObj->PropIndex < (UINT)(pObj->cFuncs+pObj->cVars)) {
	ULONG index = pObj->PropIndex++;
	/* Try all the INVOKE_PROPERTYGET functions first */
	if (index < pObj->cFuncs) {
	    FUNCDESC *pFuncDesc;

	    hr = pObj->pTypeInfo->GetFuncDesc(index, &pFuncDesc);
	    if (CheckOleError(aTHX_ stash, hr))
		continue;

            if (newenum && pFuncDesc->memid == DISPID_NEWENUM)
                return newSVpv("_NewEnum", 8);

	    if (!(pFuncDesc->funckind & FUNC_DISPATCH) ||
		!(pFuncDesc->invkind & INVOKE_PROPERTYGET) ||
	        (pFuncDesc->wFuncFlags & (FUNCFLAG_FRESTRICTED |
					  FUNCFLAG_FHIDDEN |
					  FUNCFLAG_FNONBROWSABLE)))
	    {
		pObj->pTypeInfo->ReleaseFuncDesc(pFuncDesc);
		continue;
	    }

	    hr = pObj->pTypeInfo->GetNames(pFuncDesc->memid, &bstr, 1, &cName);
	    pObj->pTypeInfo->ReleaseFuncDesc(pFuncDesc);
	    if (CheckOleError(aTHX_ stash, hr) || cName == 0 || !bstr)
		continue;

	    SV *sv = sv_setbstr(aTHX_ NULL, bstr, cp);
	    SysFreeString(bstr);
	    return sv;
	}
	/* Now try the VAR_DISPATCH kind variables used by older OLE versions */
	else {
	    VARDESC *pVarDesc;

	    index -= pObj->cFuncs;
	    hr = pObj->pTypeInfo->GetVarDesc(index, &pVarDesc);
	    if (CheckOleError(aTHX_ stash, hr))
		continue;

	    if (!(pVarDesc->varkind & VAR_DISPATCH) ||
		(pVarDesc->wVarFlags & (VARFLAG_FRESTRICTED |
					VARFLAG_FHIDDEN |
					VARFLAG_FNONBROWSABLE)))
	    {
		pObj->pTypeInfo->ReleaseVarDesc(pVarDesc);
		continue;
	    }

	    hr = pObj->pTypeInfo->GetNames(pVarDesc->memid, &bstr, 1, &cName);
	    pObj->pTypeInfo->ReleaseVarDesc(pVarDesc);
	    if (CheckOleError(aTHX_ stash, hr) || cName == 0 || !bstr)
		continue;

	    SV *sv = sv_setbstr(aTHX_ NULL, bstr, cp);
	    SysFreeString(bstr);
	    return sv;
	}
    }
    return NULL;

}   /* NextPropertyName */

HV *
GetDocumentation(pTHX_ BSTR bstrName, BSTR bstrDocString,
		 DWORD dwHelpContext, BSTR bstrHelpFile)
{
    HV *hv = newHV();
    char szStr[OLE_BUF_SIZ];
    char *pszStr;
    // XXX use correct codepage ???
    UINT cp = CP_ACP;

    pszStr = GetMultiByte(aTHX_ bstrName, szStr, sizeof(szStr), cp);
    hv_store(hv, "Name", 4, newSVpv(pszStr, 0), 0);
    ReleaseBuffer(aTHX_ pszStr, szStr);
    SysFreeString(bstrName);

    pszStr = GetMultiByte(aTHX_ bstrDocString, szStr, sizeof(szStr), cp);
    hv_store(hv, "DocString", 9, newSVpv(pszStr, 0), 0);
    ReleaseBuffer(aTHX_ pszStr, szStr);
    SysFreeString(bstrDocString);

    pszStr = GetMultiByte(aTHX_ bstrHelpFile, szStr, sizeof(szStr), cp);
    hv_store(hv, "HelpFile", 8, newSVpv(pszStr, 0), 0);
    ReleaseBuffer(aTHX_ pszStr, szStr);
    SysFreeString(bstrHelpFile);

    hv_store(hv, "HelpContext", 11, newSViv(dwHelpContext), 0);

    return hv;

}   /* GetDocumentation */

HRESULT
TranslateTypeDesc(pTHX_ TYPEDESC *pTypeDesc, WINOLETYPEINFOOBJECT *pObj,
		  AV *av)
{
    HRESULT hr = S_OK;
    SV *sv = NULL;

    if (pTypeDesc->vt == VT_USERDEFINED) {
	ITypeInfo *pTypeInfo;
	TYPEATTR  *pTypeAttr;
	hr = pObj->pTypeInfo->GetRefTypeInfo(pTypeDesc->hreftype, &pTypeInfo);
	if (SUCCEEDED(hr)) {
	    hr = pTypeInfo->GetTypeAttr(&pTypeAttr);
	    if (SUCCEEDED(hr))
		sv = CreateTypeInfoObject(aTHX_ pTypeInfo, pTypeAttr);
	    else
		pTypeInfo->Release();
	}
	if (!sv)
	    sv = newSVsv(&PL_sv_undef);

    }
    else if (pTypeDesc->vt == VT_CARRAY) {
	// XXX to be done
	sv = newSViv(pTypeDesc->vt);
    }
    else
	sv = newSViv(pTypeDesc->vt);

    av_push(av, sv);

    if (pTypeDesc->vt == VT_PTR || pTypeDesc->vt == VT_SAFEARRAY)
	hr = TranslateTypeDesc(aTHX_ pTypeDesc->lptdesc, pObj, av);

    return hr;
}

HV *
TranslateElemDesc(pTHX_ ELEMDESC *pElemDesc, WINOLETYPEINFOOBJECT *pObj,
		  HV *olestash)
{
    HV *hv = newHV();

    AV *av = newAV();
    TranslateTypeDesc(aTHX_  &pElemDesc->tdesc, pObj, av);
    hv_store(hv, "vt", 2, newRV_noinc((SV*)av), 0);

    USHORT wParamFlags = pElemDesc->paramdesc.wParamFlags;
    hv_store(hv, "wParamFlags", 11, newSViv(wParamFlags), 0);

    USHORT wMask = PARAMFLAG_FOPT|PARAMFLAG_FHASDEFAULT;
    if ((wParamFlags & wMask) == wMask) {
	PARAMDESCEX *pParamDescEx = pElemDesc->paramdesc.pparamdescex;
	hv_store(hv, "cBytes", 6, newSViv(pParamDescEx->cBytes), 0);
	// XXX should be stored as a Win32::OLE::Variant object ?
	SV *sv = newSV(0);
	// XXX check return code
	SetSVFromVariantEx(aTHX_ &pParamDescEx->varDefaultValue,
			   sv, olestash);
	hv_store(hv, "varDefaultValue", 15, sv, 0);
    }

    return hv;

}   /* TranslateElemDesc */

HRESULT
FindIID(pTHX_ WINOLEOBJECT *pObj, char *pszItf, IID *piid,
	ITypeInfo **ppTypeInfo, UINT cp, LCID lcid)
{
    ITypeInfo *pTypeInfo;
    ITypeLib *pTypeLib;

    if (ppTypeInfo)
	*ppTypeInfo = NULL;

    // Determine containing type library
    HRESULT hr = pObj->pDispatch->GetTypeInfo(0, lcid, &pTypeInfo);
    DBG(("  GetTypeInfo: 0x%08x\n", hr));
    if (FAILED(hr))
	return hr;

    unsigned int index;
    hr = pTypeInfo->GetContainingTypeLib(&pTypeLib, &index);
    pTypeInfo->Release();
    DBG(("  GetContainingTypeLib: 0x%08x\n", hr));
    if (FAILED(hr))
	return hr;

    // piid maybe already set by IProvideClassInfo2::GetGUID
    if (!pszItf) {
	hr = pTypeLib->GetTypeInfoOfGuid(*piid, ppTypeInfo);
	DBG(("  GetTypeInfoOfGuid: 0x%08x\n", hr));
	pTypeLib->Release();
	return hr;
    }

    // Walk through all type definitions in the library
    BOOL bFound = FALSE;
    unsigned int count = pTypeLib->GetTypeInfoCount();
    for (index = 0; index < count; ++index) {
	TYPEATTR *pTypeAttr;

	hr = pTypeLib->GetTypeInfo(index, &pTypeInfo);
	if (FAILED(hr))
	    break;

	hr = pTypeInfo->GetTypeAttr(&pTypeAttr);
	if (FAILED(hr)) {
	    pTypeInfo->Release();
	    break;
	}

	// DBG(("  TypeInfo %d typekind %d\n", index, pTypeAttr->typekind));

	// Look into all COCLASSes
	if (pTypeAttr->typekind == TKIND_COCLASS) {

	    // Walk through all implemented types
	    for (unsigned int type=0; type < pTypeAttr->cImplTypes; ++type) {
		HREFTYPE RefType;
		ITypeInfo *pImplTypeInfo;

		hr = pTypeInfo->GetRefTypeOfImplType(type, &RefType);
		if (FAILED(hr))
		    break;

		hr = pTypeInfo->GetRefTypeInfo(RefType, &pImplTypeInfo);
		if (FAILED(hr))
		    break;

		BSTR bstr;
		hr = pImplTypeInfo->GetDocumentation(-1, &bstr, NULL,
						     NULL, NULL);
		if (FAILED(hr)) {
		    pImplTypeInfo->Release();
		    break;
		}

		char szStr[OLE_BUF_SIZ];
		char *pszStr = GetMultiByte(aTHX_ bstr, szStr,
					    sizeof(szStr), cp);
		if (strEQ(pszItf, pszStr)) {
		    TYPEATTR *pImplTypeAttr;

		    hr = pImplTypeInfo->GetTypeAttr(&pImplTypeAttr);
		    if (SUCCEEDED(hr)) {
			bFound = TRUE;
			*piid = pImplTypeAttr->guid;
			if (ppTypeInfo) {
			    *ppTypeInfo = pImplTypeInfo;
			    (*ppTypeInfo)->AddRef();
			}
			pImplTypeInfo->ReleaseTypeAttr(pImplTypeAttr);
		    }
		}

		ReleaseBuffer(aTHX_ pszStr, szStr);
		pImplTypeInfo->Release();
		if (bFound || FAILED(hr))
		    break;
	    }
	}

	pTypeInfo->ReleaseTypeAttr(pTypeAttr);
	pTypeInfo->Release();
	if (bFound || FAILED(hr))
	    break;
    }

    pTypeLib->Release();
    DBG(("  after loop: 0x%08x\n", hr));
    if (FAILED(hr))
	return hr;

    if (!bFound) {
	warn(MY_VERSION "FindIID: Interface '%s' not found", pszItf);
	return E_NOINTERFACE;
    }

#ifdef _DEBUG
    OLECHAR wszGUID[80];
    int len = StringFromGUID2(*piid, wszGUID, sizeof(wszGUID)/sizeof(OLECHAR));
    char szStr[OLE_BUF_SIZ];
    char *pszStr = GetMultiByte(aTHX_ wszGUID, szStr, sizeof(szStr), cp);
    DBG(("FindIID: %s is %s", pszItf, pszStr));
    ReleaseBuffer(aTHX_ pszStr, szStr);
#endif

    return S_OK;

}   /* FindIID */

HRESULT
FindDefaultSource(pTHX_ WINOLEOBJECT *pObj, IID *piid,
		  ITypeInfo **ppTypeInfo, UINT cp, LCID lcid)
{
    HRESULT hr;
    *ppTypeInfo = NULL;

    // Try IProvideClassInfo2 interface first
    IProvideClassInfo2 *pProvideClassInfo2;
    hr = pObj->pDispatch->QueryInterface(IID_IProvideClassInfo2,
					 (void**)&pProvideClassInfo2);
    DBG(("QueryInterface(IProvideClassInfo2): hr=0x%08x\n", hr));
    if (SUCCEEDED(hr)) {
	hr = pProvideClassInfo2->GetGUID(GUIDKIND_DEFAULT_SOURCE_DISP_IID,
					 piid);
	pProvideClassInfo2->Release();
	DBG(("GetGUID: hr=0x%08x\n", hr));
	return FindIID(aTHX_ pObj, NULL, piid, ppTypeInfo, cp, lcid);
    }

    IProvideClassInfo *pProvideClassInfo;
    hr = pObj->pDispatch->QueryInterface(IID_IProvideClassInfo,
					 (void**)&pProvideClassInfo);
    DBG(("QueryInterface(IProvideClassInfo): hr=0x%08x\n", hr));
    if (FAILED(hr))
	return hr;

    // Get ITypeInfo* for COCLASS of this object
    ITypeInfo *pTypeInfo;
    hr = pProvideClassInfo->GetClassInfo(&pTypeInfo);
    pProvideClassInfo->Release();
    DBG(("GetClassInfo: hr=0x%08x\n", hr));
    if (FAILED(hr))
	return hr;

    // Get Type Attributes
    TYPEATTR *pTypeAttr;
    hr = pTypeInfo->GetTypeAttr(&pTypeAttr);
    DBG(("GetTypeAttr: hr=0x%08x\n", hr));
    if (FAILED(hr)) {
	pTypeInfo->Release();
	return hr;
    }

    UINT i;
    int iFlags;

    // Enumerate all implemented types of the COCLASS
    for (i=0; i < pTypeAttr->cImplTypes; i++) {
	hr = pTypeInfo->GetImplTypeFlags(i, &iFlags);
	DBG(("GetImplTypeFlags: hr=0x%08x i=%d iFlags=%d\n", hr, i, iFlags));
	if (FAILED(hr))
	    continue;

	// looking for the [default] [source]
	// we just hope that it is a dispinterface :-)
	if ((iFlags & IMPLTYPEFLAG_FDEFAULT) &&
	    (iFlags & IMPLTYPEFLAG_FSOURCE))
	{
	    HREFTYPE hRefType = 0;

	    hr = pTypeInfo->GetRefTypeOfImplType(i, &hRefType);
	    DBG(("GetRefTypeOfImplType: hr=0x%08x\n", hr));
	    if (FAILED(hr))
		continue;
	    hr = pTypeInfo->GetRefTypeInfo(hRefType, ppTypeInfo);
	    DBG(("GetRefTypeInfo: hr=0x%08x\n", hr));
	    if (SUCCEEDED(hr))
		break;
	}
    }

    pTypeInfo->ReleaseTypeAttr(pTypeAttr);
    pTypeInfo->Release();

    // Now that would be a bad surprise, if we didn't find it, wouldn't it?
    if (!*ppTypeInfo) {
	if (SUCCEEDED(hr))
	    hr = E_UNEXPECTED;
	return hr;
    }

    // Determine IID of default source interface
    hr = (*ppTypeInfo)->GetTypeAttr(&pTypeAttr);
    if (SUCCEEDED(hr)) {
	*piid = pTypeAttr->guid;
	(*ppTypeInfo)->ReleaseTypeAttr(pTypeAttr);
    }
    else
	(*ppTypeInfo)->Release();

    return hr;

}   /* FindDefaultSource */

IEnumVARIANT *
CreateEnumVARIANT(pTHX_ WINOLEOBJECT *pObj)
{
    unsigned int argErr;
    EXCEPINFO excepinfo;
    DISPPARAMS dispParams;
    VARIANT result;
    HRESULT hr;
    IEnumVARIANT *pEnum = NULL;

    VariantInit(&result);
    dispParams.rgvarg = NULL;
    dispParams.rgdispidNamedArgs = NULL;
    dispParams.cNamedArgs = 0;
    dispParams.cArgs = 0;

    HV *stash = SvSTASH(pObj->self);
    LCID lcid = (LCID)QueryPkgVar(aTHX_ stash, LCID_NAME, LCID_LEN, lcidDefault);

    Zero(&excepinfo, 1, EXCEPINFO);
    hr = pObj->pDispatch->Invoke(DISPID_NEWENUM, IID_NULL,
			    lcid, DISPATCH_METHOD | DISPATCH_PROPERTYGET,
			    &dispParams, &result, &excepinfo, &argErr);
    if (SUCCEEDED(hr)) {
	if (V_VT(&result) == VT_UNKNOWN)
	    hr = V_UNKNOWN(&result)->QueryInterface(IID_IEnumVARIANT,
						    (void**)&pEnum);
	else if (V_VT(&result) == VT_DISPATCH)
	    hr = V_DISPATCH(&result)->QueryInterface(IID_IEnumVARIANT,
						     (void**)&pEnum);
    }
    VariantClear(&result);
    CheckOleError(aTHX_ stash, hr, &excepinfo);
    return pEnum;

}   /* CreateEnumVARIANT */

SV *
NextEnumElement(pTHX_ IEnumVARIANT *pEnum, HV *stash)
{
    SV *sv = NULL;
    VARIANT variant;

    VariantInit(&variant);
    if (pEnum->Next(1, &variant, NULL) == S_OK) {
	sv = newSV(0);
	HRESULT hr = SetSVFromVariantEx(aTHX_ &variant, sv, stash);
        if (FAILED(hr)) {
            SvREFCNT_dec(sv);
            sv = NULL;
            ReportOleError(aTHX_ stash, hr);
        }
        VariantClear(&variant);
    }
    return sv;

}   /* NextEnumElement */

//------------------------------------------------------------------------

EventSink::EventSink(pTHX_ WINOLEOBJECT *pObj, SV *events,
		     REFIID riid, ITypeInfo *pTypeInfo)
{
    DBG(("EventSink::EventSink\n"));
    m_pObj = pObj;
    m_events = newSVsv(events);
    m_iid = riid;
    m_pTypeInfo = pTypeInfo;
    m_refcount = 1;
#ifdef PERL_IMPLICIT_CONTEXT
    this->aTHX = aTHX;
#endif
}

EventSink::~EventSink(void)
{
#ifdef PERL_IMPLICIT_CONTEXT
    pTHX = PERL_GET_THX;
    PERL_SET_THX(this->aTHX);
#endif

    DBG(("EventSink::~EventSink\n"));
    if (m_pTypeInfo)
	m_pTypeInfo->Release();
    SvREFCNT_dec(m_events);

#ifdef PERL_IMPLICIT_CONTEXT
    PERL_SET_THX(aTHX);
#endif
}

HRESULT
EventSink::Advise(IConnectionPoint *pConnectionPoint)
{
    HRESULT hr = pConnectionPoint->Advise((IUnknown*)this, &m_dwCookie);
    if (SUCCEEDED(hr)) {
	m_pConnectionPoint = pConnectionPoint;
	m_pConnectionPoint->AddRef();
    }
    return hr;
}

void
EventSink::Unadvise(void)
{
    if (m_pConnectionPoint) {
	m_pConnectionPoint->Unadvise(m_dwCookie);
	m_pConnectionPoint->Release();
    }
    m_pConnectionPoint = NULL;
    Release();
}

STDMETHODIMP
EventSink::QueryInterface(REFIID iid, void **ppv)
{
#ifdef _DEBUG
#   ifdef PERL_IMPLICIT_CONTEXT
    pTHX = PERL_GET_THX;
    PERL_SET_THX(this->aTHX);
#   endif

    OLECHAR wszGUID[80];
    int len = StringFromGUID2(iid, wszGUID, sizeof(wszGUID)/sizeof(OLECHAR));
    char szStr[OLE_BUF_SIZ];
    char *pszStr = GetMultiByte(aTHX_ wszGUID, szStr, sizeof(szStr), CP_ACP);
    DBG(("***QueryInterface %s\n", pszStr));
    ReleaseBuffer(aTHX_ pszStr, szStr);

#   ifdef PERL_IMPLICIT_CONTEXT
    PERL_SET_THX(aTHX);
#   endif
#endif

    if (iid == IID_IUnknown || iid == IID_IDispatch || iid == m_iid)
	*ppv = this;
    else {
	DBG(("  failed\n"));
	*ppv = NULL;
	return E_NOINTERFACE;
    }
    DBG(("  succeeded\n"));
    AddRef();
    return S_OK;
}

STDMETHODIMP_(ULONG)
EventSink::AddRef(void)
{
    ++m_refcount;
    DBG(("***AddRef refcount=%d\n", m_refcount));
    return m_refcount;
}

STDMETHODIMP_(ULONG)
EventSink::Release(void)
{
    --m_refcount;
    DBG(("***Release refcount=%d\n", m_refcount));
    if (m_refcount)
	return m_refcount;
    delete this;
    return 0;
}

STDMETHODIMP
EventSink::GetTypeInfoCount(UINT *pctinfo)
{
    DBG(("***GetTypeInfoCount\n"));
    *pctinfo = 0;
    return S_OK;
}

STDMETHODIMP
EventSink::GetTypeInfo(UINT itinfo, LCID lcid, ITypeInfo **pptinfo)
{
    DBG(("***GetTypeInfo\n"));
    *pptinfo = NULL;
    return DISP_E_BADINDEX;
}

STDMETHODIMP
EventSink::GetIDsOfNames(
    REFIID riid,
    OLECHAR **rgszNames,
    UINT cNames,
    LCID lcid,
    DISPID *rgdispid)
{
    DBG(("***GetIDsOfNames\n"));
    // XXX Set all DISPIDs to DISPID_UNKNOWN
    return DISP_E_UNKNOWNNAME;
}

STDMETHODIMP
EventSink::Invoke(
    DISPID dispidMember,
    REFIID riid,
    LCID lcid,
    WORD wFlags,
    DISPPARAMS *pdispparams,
    VARIANT *pvarResult,
    EXCEPINFO *pexcepinfo,
    UINT *puArgErr)
{
#ifdef PERL_IMPLICIT_CONTEXT
    pTHX = PERL_GET_THX;
    PERL_SET_THX(this->aTHX);
#endif

    DBG(("***Invoke dispid=%d args=%d\n", dispidMember, pdispparams->cArgs));
    BSTR bstr;
    unsigned int count;
    HRESULT hr;
    SV *event = Nullsv;

    if (m_pTypeInfo) {
	hr = m_pTypeInfo->GetNames(dispidMember, &bstr, 1, &count);
	if (FAILED(hr)) {
	    DBG(("  GetNames failed: 0x%08x\n", hr));
#ifdef PERL_IMPLICIT_CONTEXT
            PERL_SET_THX(aTHX);
#endif
	    return S_OK;
	}

	event = sv_2mortal(sv_setbstr(aTHX_ NULL, bstr, CP_ACP));
	SysFreeString(bstr);
    }
    else {
	DBG(("  No type library available\n"));
	STRLEN n_a;
	event = sv_2mortal(newSViv(dispidMember));
	SvPV_force(event, n_a);
    }

    DBG(("  Event %s\n", SvPVX(event)));

    SV *callback = NULL;
    BOOL pushname = FALSE;

    if (SvROK(m_events) && SvTYPE(SvRV(m_events)) == SVt_PVCV) {
	callback = m_events;
	pushname = TRUE;
    }
    else if (SvPOK(m_events)) {
	HV *stash = gv_stashsv(m_events, FALSE);
	if (stash) {
	    GV **pgv = (GV**)hv_fetch(stash, SvPVX(event), (I32)SvCUR(event), FALSE);
	    if (pgv && GvCV(*pgv))
		callback = (SV*)GvCV(*pgv);
	}
    }

    if (callback) {
	dSP;
	SV *self = newRV_inc((SV*)m_pObj->self);
	if (Gv_AMG(SvSTASH(m_pObj->self)))
	    SvAMAGIC_on(self);

	ENTER;
	SAVETMPS;
	PUSHMARK(sp);
	XPUSHs(sv_2mortal(self));
	if (pushname)
	    XPUSHs(event);
	for (unsigned int i=0; i < pdispparams->cArgs; ++i) {
	    VARIANT *pVariant = &pdispparams->rgvarg[pdispparams->cArgs-i-1];
	    DBG(("   Arg %d vt=0x%04x\n", i, V_VT(pVariant)));
	    SV *sv = sv_newmortal();
	    // XXX Check return code
	    SetSVFromVariantEx(aTHX_ pVariant, sv, SvSTASH(m_pObj->self), TRUE);
	    XPUSHs(sv);
	}
	PUTBACK;
	perl_call_sv(callback, G_DISCARD);
	SPAGAIN;
	FREETMPS;
	LEAVE;
    }

#ifdef PERL_IMPLICIT_CONTEXT
    PERL_SET_THX(aTHX);
#endif
    return S_OK;
}

//------------------------------------------------------------------------

Forwarder::Forwarder(pTHX_ HV *stash, SV *method)
{
    m_stash = stash; // XXX refcount?
    m_method = newSVsv(method);
    m_refcount = 1;
#ifdef PERL_IMPLICIT_CONTEXT
    this->aTHX = aTHX;
#endif
}

Forwarder::~Forwarder(void)
{
#ifdef PERL_IMPLICIT_CONTEXT
    pTHX = PERL_GET_THX;
    PERL_SET_THX(this->aTHX);
#endif

    SvREFCNT_dec(m_method);

#ifdef PERL_IMPLICIT_CONTEXT
    PERL_SET_THX(aTHX);
#endif
}

STDMETHODIMP
Forwarder::QueryInterface(REFIID iid, void **ppv)
{
    if (iid == IID_IUnknown || iid == IID_IDispatch) {
	*ppv = this;
	AddRef();
	return S_OK;
    }
    *ppv = NULL;
    return E_NOINTERFACE;
}

STDMETHODIMP_(ULONG)
Forwarder::AddRef(void)
{
    return ++m_refcount;
}

STDMETHODIMP_(ULONG)
Forwarder::Release(void)
{
    if (--m_refcount)
	return m_refcount;
    delete this;
    return 0;
}

STDMETHODIMP
Forwarder::GetTypeInfoCount(UINT *pctinfo)
{
    *pctinfo = 0;
    return S_OK;
}

STDMETHODIMP
Forwarder::GetTypeInfo(UINT itinfo, LCID lcid, ITypeInfo **pptinfo)
{
    *pptinfo = NULL;
    return DISP_E_BADINDEX;
}

STDMETHODIMP
Forwarder::GetIDsOfNames(
    REFIID riid,
    OLECHAR **rgszNames,
    UINT cNames,
    LCID lcid,
    DISPID *rgdispid)
{
    DBG(("Forwarder::GetIDsOfNames cNames=%d\n", cNames));
    // XXX Set all DISPIDs to DISPID_UNKNOWN
    return DISP_E_UNKNOWNNAME;
}

STDMETHODIMP
Forwarder::Invoke(
    DISPID dispidMember,
    REFIID riid,
    LCID lcid,
    WORD wFlags,
    DISPPARAMS *pdispparams,
    VARIANT *pvarResult,
    EXCEPINFO *pexcepinfo,
    UINT *puArgErr)
{
#ifdef PERL_IMPLICIT_CONTEXT
    pTHX = PERL_GET_THX;
    PERL_SET_THX(this->aTHX);
#endif

    DBG(("Forwarder::Invoke dispid=%d args=%d\n",
	 dispidMember, pdispparams->cArgs));
    dSP;
    ENTER;
    SAVETMPS;
    PUSHMARK(sp);
    for (unsigned int i=0; i < pdispparams->cArgs; ++i) {
	VARIANT *pVariant = &pdispparams->rgvarg[pdispparams->cArgs-i-1];
	DBG(("   Arg %d vt=0x%04x\n", i, V_VT(pVariant)));
	SV *sv = sv_newmortal();
	// XXX Check return code
	SetSVFromVariantEx(aTHX_ pVariant, sv, m_stash, TRUE);
	XPUSHs(sv);
    }
    PUTBACK;
    perl_call_sv(m_method, G_DISCARD);
    SPAGAIN;
    FREETMPS;
    LEAVE;

#ifdef PERL_IMPLICIT_CONTEXT
    PERL_SET_THX(aTHX);
#endif

    return S_OK;
}

//------------------------------------------------------------------------

HRESULT
MyVariantCopy(VARIANTARG *dest, VARIANTARG *src)
{
    // VariantCopy() doesn't preserve vbNullString semantics
    if (V_VT(src) == VT_BSTR && V_BSTR(src) == NULL) {
        VariantClear(dest);
        V_VT(dest) = VT_BSTR;
        V_BSTR(dest) = NULL;
        return S_OK;
    }

    return VariantCopy(dest, src);
}

void
ClearVariantObject(WINOLEVARIANTOBJECT *pVarObj)
{
    if (!pVarObj)
        return;

    VARIANT *pVariant = &pVarObj->variant;
    VARTYPE vt = V_VT(pVariant);

    if (vt & VT_BYREF) {
        switch (vt & ~VT_BYREF) {
        case VT_BSTR:
            SysFreeString(*V_BSTRREF(pVariant));
            break;
        case VT_DISPATCH:
            if (*V_DISPATCHREF(pVariant))
                (*V_DISPATCHREF(pVariant))->Release();
            break;
        case VT_UNKNOWN:
            if (*V_UNKNOWNREF(pVariant))
                (*V_UNKNOWNREF(pVariant))->Release();
            break;
        }
        VariantInit(pVariant);
    }
    else
        VariantClear(pVariant);
}

SV *
SetSVFromGUID(pTHX_ REFGUID rguid)
{
    dSP;
    SV *sv = newSVsv(&PL_sv_undef);
    CV *cv = perl_get_cv("Win32::COM::GUID::new", FALSE);

    if (cv) {
	EXTEND(SP, 2);
	PUSHMARK(sp);
	PUSHs(sv_2mortal(newSVpv("Win32::COM::GUID", 0)));
	PUSHs(sv_2mortal(newSVpv((char*)&rguid, sizeof(GUID))));
	PUTBACK;
	int count = perl_call_sv((SV*)cv, G_SCALAR);
	SPAGAIN;
	if (count == 1)
	    sv_setsv(sv, POPs);
	PUTBACK;
    }
    else {
	OLECHAR wszGUID[80];
	int len = StringFromGUID2(rguid, wszGUID,
				  sizeof(wszGUID)/sizeof(OLECHAR));
	if (len > 3) {
            BSTR bstr = SysAllocStringLen(wszGUID+1, len-3);
	    sv_setbstr(aTHX_ sv, bstr, CP_ACP);
            SysFreeString(bstr);
	}
    }
    return sv;
}

HRESULT
SetSafeArrayFromAV(pTHX_ AV* av, VARTYPE vt, SAFEARRAY *psa,
		   int cDims, UINT cp, LCID lcid)
{
    HRESULT hr = SafeArrayLock(psa);
    if (FAILED(hr))
	return hr;

    if (cDims == 0)
	cDims = SafeArrayGetDim(psa);

    AV **pav;
    LONG *pix;
    long *plen;

    New(0, pav, cDims, AV*);
    New(0, pix, cDims, LONG);
    New(0, plen, cDims, long);

    pav[0] = av;
    plen[0] = av_len(pav[0])+1;
    Zero(pix, cDims, LONG);

    VARIANT variant;
    VARIANT *pElement = &variant;
    if (vt != VT_VARIANT)
	V_VT(pElement) = vt | VT_BYREF;

    for (int index = 0; index >= 0; ) {
	SV **psv = av_fetch(pav[index], pix[index], FALSE);

	if (psv) {
	    if (SvROK(*psv) && SvTYPE(SvRV(*psv)) == SVt_PVAV) {
		if (++index >= cDims) {
		    warn(MY_VERSION ": SetSafeArrayFromAV unexpected failure");
		    hr = E_UNEXPECTED;
		    break;
		}
		pav[index] = (AV*)SvRV(*psv);
		pix[index] = 0;
		plen[index] = av_len(pav[index])+1;
		continue;
	    }

	    if (SvOK(*psv)) {
		if (index+1 != cDims) {
		    warn(MY_VERSION ": SetSafeArrayFromAV wrong dimension");
		    hr = DISP_E_BADINDEX;
		    break;
		}
		if (vt == VT_VARIANT) {
		    hr = SafeArrayPtrOfIndex(psa, pix, (void**)&pElement);
		    if (SUCCEEDED(hr))
			hr = SetVariantFromSVEx(aTHX_ *psv, pElement, cp, lcid);
		}
		else {
		    hr = SafeArrayPtrOfIndex(psa, pix, &V_BYREF(pElement));
		    if (SUCCEEDED(hr))
			hr = AssignVariantFromSV(aTHX_ *psv, pElement,
						 cp, lcid);
		}
		if (hr == DISP_E_BADINDEX)
		    warn(MY_VERSION ": SetSafeArrayFromAV bad index");
		if (FAILED(hr))
		    break;
	    }
	}

	while (index >= 0) {
	    if (++pix[index] < plen[index])
		break;
	    pix[index--] = 0;
	}
    }

    SafeArrayUnlock(psa);

    Safefree(pav);
    Safefree(pix);
    Safefree(plen);

    return hr;
}

HRESULT
SetVariantFromSVEx(pTHX_ SV* sv, VARIANT *pVariant, UINT cp, LCID lcid)
{
    HRESULT hr = S_OK;
    VariantClear(pVariant);

    /* XXX requirement to call mg_get() may change in Perl > 5.005 */
    MagicGet(aTHX_ sv);

    /* Objects */
    if (SvROK(sv)) {
	if (sv_derived_from(sv, szWINOLE)) {
	    WINOLEOBJECT *pObj = GetOleObject(aTHX_ sv);
	    if (pObj) {
		pObj->pDispatch->AddRef();
		V_VT(pVariant) = VT_DISPATCH;
		V_DISPATCH(pVariant) = pObj->pDispatch;
		return S_OK;
	    }
	    return E_POINTER;
	}

	if (sv_derived_from(sv, szWINOLEVARIANT)) {
	    WINOLEVARIANTOBJECT *pVarObj =
		GetOleVariantObject(aTHX_ sv);

	    if (pVarObj) {
		/* XXX Should we use VariantCopyInd? */
                hr = MyVariantCopy(pVariant, &pVarObj->variant);
	    }
	    else
		hr = E_POINTER;
	    return hr;
	}

	if (sv_derived_from(sv, szUNICODESTRING)) {
            V_VT(pVariant) = VT_BSTR;
            V_BSTR(pVariant) = AllocOleStringFromSV(aTHX_ sv, cp);
            return S_OK;
        }

	sv = SvRV(sv);
    }

    /* Arrays */
    if (SvTYPE(sv) == SVt_PVAV) {
	IV index;
	IV dim = 1;
	IV maxdim = 2;
	AV **pav;
	ULONG *pix;
	unsigned long *plen;
	SAFEARRAYBOUND *psab;

	New(0, pav, maxdim, AV*);
	New(0, pix, maxdim, ULONG);
	New(0, plen, maxdim, unsigned long);
	New(0, psab, maxdim, SAFEARRAYBOUND);

	pav[0] = (AV*)sv;
	pix[0] = 0;
	plen[0] = av_len(pav[0])+1;
	psab[0].cElements = plen[0];
	psab[0].lLbound = 0;

	/* Depth first walk through to determine number of dimensions */
	for (index = 0; index >= 0; ) {
	    SV **psv = av_fetch(pav[index], pix[index], FALSE);

	    if (psv && SvROK(*psv) && SvTYPE(SvRV(*psv)) == SVt_PVAV) {
		if (++index >= maxdim) {
		    maxdim *= 2;
		    Renew(pav, maxdim, AV*);
		    Renew(pix, maxdim, ULONG);
		    Renew(plen, maxdim, unsigned long);
		    Renew(psab, maxdim, SAFEARRAYBOUND);
		}

		pav[index] = (AV*)SvRV(*psv);
		pix[index] = 0;
		plen[index] = av_len(pav[index])+1;

		if (index < dim) {
		    if (plen[index] > psab[index].cElements)
			psab[index].cElements = plen[index];
		}
		else {
		    dim = index+1;
		    psab[index].cElements = plen[index];
		    psab[index].lLbound = 0;
		}
		continue;
	    }

	    while (index >= 0) {
		if (++pix[index] < plen[index])
		    break;
		--index;
	    }
	}

	/* Create and fill VARIANT array */
	SAFEARRAY *psa = SafeArrayCreate(VT_VARIANT, (UINT)dim, psab);
	if (psa)
	    hr = SetSafeArrayFromAV(aTHX_ (AV*)sv, VT_VARIANT, psa, (int)dim,
				    cp, lcid);
	else
	    hr = E_OUTOFMEMORY;

	Safefree(pav);
	Safefree(pix);
	Safefree(plen);
	Safefree(psab);

	if (SUCCEEDED(hr)) {
	    V_VT(pVariant) = VT_VARIANT | VT_ARRAY;
	    V_ARRAY(pVariant) = psa;
	}
	else if (psa)
	    SafeArrayDestroy(psa);

	return hr;
    }

    /* Scalars */
    if (SvIOK(sv)) {
	V_VT(pVariant) = VT_I4;
	V_I4(pVariant) = (LONG)SvIV(sv);
    }
    else if (SvNOK(sv)) {
	V_VT(pVariant) = VT_R8;
	V_R8(pVariant) = SvNV(sv);
    }
    else if (SvPOK(sv)) {
	V_VT(pVariant) = VT_BSTR;
	V_BSTR(pVariant) = AllocOleStringFromSV(aTHX_ sv, cp);
    }

    return hr;

}   /* SetVariantFromSVEx */

HRESULT
SetVariantFromSV(pTHX_ SV* sv, VARIANT *pVariant, UINT cp)
{
    /* old API for PerlScript compatibility */
    return SetVariantFromSVEx(aTHX_ sv, pVariant, cp, lcidDefault);
}   /* SetVariantFromSV */

HRESULT
AssignVariantFromSV(pTHX_ SV* sv, VARIANT *pVariant, UINT cp, LCID lcid)
{
    /* This function is similar to SetVariantFromSVEx except that
     * it does NOT choose the variant type itself.
     */
    HRESULT hr = S_OK;
    VARTYPE vt = V_VT(pVariant);
    /* sv must NOT be Nullsv unless vt is VT_EMPTY, VT_NULL, VT_BSTR,
     * VT_DISPATCH or VT_VARIANT
    */

#   define ASSIGN(vartype,perltype,ctype)                            \
        if (vt & VT_BYREF) {                                         \
            *V_##vartype##REF(pVariant) = (ctype)Sv##perltype (sv);  \
        } else {                                                     \
            V_##vartype(pVariant) = (ctype)Sv##perltype (sv);        \
        }

    /* XXX requirement to call mg_get() may change in Perl > 5.005 */
    if (sv)
        MagicGet(aTHX_ sv);

    if (vt & VT_ARRAY) {
	SAFEARRAY *psa;
	if (V_ISBYREF(pVariant))
	    psa = *V_ARRAYREF(pVariant);
	else
	    psa = V_ARRAY(pVariant);

	UINT cDims = SafeArrayGetDim(psa);
	if ((vt & VT_TYPEMASK) != VT_UI1 || cDims != 1 || !sv || !SvPOK(sv)) {
	    warn(MY_VERSION ": AssignVariantFromSV() cannot assign to "
		 "VT_ARRAY variant");
	    return E_INVALIDARG;
	}

	char *pDest;
	STRLEN len;
	char *pSrc = SvPV(sv, len);
	HRESULT hr = SafeArrayAccessData(psa, (void**)&pDest);
	if (SUCCEEDED(hr)) {
	    LONG lLower, lUpper;
	    SafeArrayGetLBound(psa, 1, &lLower);
	    SafeArrayGetUBound(psa, 1, &lUpper);

	    unsigned long lLength = 1 + lUpper-lLower;
	    len = (len < lLength ? len : lLength);
	    memcpy(pDest, pSrc, len);
	    if (lLength > len)
		memset(pDest+len, 0, lLength-len);

	    SafeArrayUnaccessData(psa);
	}
	return hr;
    }

    VARTYPE vt_base = vt & VT_TYPEMASK;

    switch (vt_base) {
    case VT_EMPTY:
    case VT_NULL:
	break;

    case VT_I2:
	ASSIGN(I2, IV, short);
	break;

    case VT_I4:
	ASSIGN(I4, IV, int);
	break;

    case VT_R4:
	ASSIGN(R4, NV, float);
	break;

    case VT_R8:
	ASSIGN(R8, NV, double);
	break;

    case VT_CY:
    case VT_DATE:
    {
	VARIANT variant;
	if (SvIOK(sv)) {
	    V_VT(&variant) = VT_I4;
	    V_I4(&variant) = (LONG)SvIV(sv);
	}
	else if (SvNOK(sv)) {
	    V_VT(&variant) = VT_R8;
	    V_R8(&variant) = SvNV(sv);
	}
	else {
	    V_VT(&variant) = VT_BSTR;
	    V_BSTR(&variant) = AllocOleStringFromSV(aTHX_ sv, cp);
	}

	hr = VariantChangeTypeEx(&variant, &variant, lcid, 0, vt_base);
	if (SUCCEEDED(hr)) {
	    if (vt_base == VT_CY) {
		if (vt & VT_BYREF)
		    *V_CYREF(pVariant) = V_CY(&variant);
		else
		    V_CY(pVariant) = V_CY(&variant);
	    }
	    else {
		if (vt & VT_BYREF)
		    *V_DATEREF(pVariant) = V_DATE(&variant);
		else
		    V_DATE(pVariant) = V_DATE(&variant);
	    }
	}
	VariantClear(&variant);
	break;
    }

    case VT_BSTR:
    {
	BSTR bstr = sv ? AllocOleStringFromSV(aTHX_ sv, cp) : NULL;

	if (vt & VT_BYREF) {
	    SysFreeString(*V_BSTRREF(pVariant));
	    *V_BSTRREF(pVariant) = bstr;
	}
	else {
	    SysFreeString(V_BSTR(pVariant));
	    V_BSTR(pVariant) = bstr;
	}
	break;
    }

    case VT_DISPATCH:
	if (vt & VT_BYREF) {
	    if (*V_DISPATCHREF(pVariant))
		(*V_DISPATCHREF(pVariant))->Release();
	    *V_DISPATCHREF(pVariant) = NULL;
	}
	else {
	    if (V_DISPATCH(pVariant))
		V_DISPATCH(pVariant)->Release();
	    V_DISPATCH(pVariant) = NULL;
	}
	if (sv_isobject(sv)) {
	    /* Argument MUST be a valid Perl OLE object! */
	    WINOLEOBJECT *pObj = GetOleObject(aTHX_ sv);
	    if (pObj) {
		pObj->pDispatch->AddRef();
		if (vt & VT_BYREF)
		    *V_DISPATCHREF(pVariant) = pObj->pDispatch;
		else
		    V_DISPATCH(pVariant) = pObj->pDispatch;
	    }
	}
	break;

    case VT_ERROR:
	ASSIGN(ERROR, IV, unsigned short);
	break;

    case VT_BOOL:
	if (vt & VT_BYREF)
	    *V_BOOLREF(pVariant) = SvTRUE(sv) ? VARIANT_TRUE : VARIANT_FALSE;
	else
	    V_BOOL(pVariant) = SvTRUE(sv) ? VARIANT_TRUE : VARIANT_FALSE;
	break;

    case VT_VARIANT:
	if (vt & VT_BYREF)
            if (sv)
                hr = SetVariantFromSVEx(aTHX_ sv, V_VARIANTREF(pVariant), cp, lcid);
            else
                VariantClear(V_VARIANTREF(pVariant));
	else {
	    warn(MY_VERSION ": AssignVariantFromSV() with invalid type: "
		 "VT_VARIANT without VT_BYREF");
	    hr = E_INVALIDARG;
	}
	break;

    case VT_UNKNOWN:
    {
	/* Argument MUST be a valid Perl OLE object! */
	/* Query IUnknown interface to allow identity tests */
	WINOLEOBJECT *pObj = GetOleObject(aTHX_ sv);
	if (pObj) {
	    IUnknown *punk;
	    hr = pObj->pDispatch->QueryInterface(IID_IUnknown, (void**)&punk);
	    if (SUCCEEDED(hr)) {
		if (vt & VT_BYREF) {
		    if (*V_UNKNOWNREF(pVariant))
			(*V_UNKNOWNREF(pVariant))->Release();
		    *V_UNKNOWNREF(pVariant) = punk;
		}
		else {
		    if (V_UNKNOWN(pVariant))
			V_UNKNOWN(pVariant)->Release();
		    V_UNKNOWN(pVariant) = punk;
		}
	    }
	}
	break;
    }

    case VT_DECIMAL:
    {
	VARIANT variant;
	VariantInit(&variant);
	V_VT(&variant) = VT_BSTR;
	V_BSTR(&variant) = AllocOleStringFromSV(aTHX_ sv, cp);

	hr = VariantChangeTypeEx(&variant, &variant, lcid, 0, VT_DECIMAL);
	if (SUCCEEDED(hr)) {
	    if (vt & VT_BYREF)
		*V_DECIMALREF(pVariant) = V_DECIMAL(&variant);
	    else
		V_DECIMAL(pVariant) = V_DECIMAL(&variant);
	}
	VariantClear(&variant);
	break;
    }

    case VT_UI1:
	if (SvIOK(sv)) {
	    ASSIGN(UI1, IV, unsigned char);
	}
	else {
	    char *ptr = SvPV_nolen(sv);
	    if (vt & VT_BYREF)
		*V_UI1REF(pVariant) = *ptr;
	    else
		V_UI1(pVariant) = *ptr;
	}
	break;

    default:
	warn(MY_VERSION " AssignVariantFromSV() cannot assign to "
	     "vt=0x%x", vt);
	hr = E_INVALIDARG;
    }

    return hr;
#   undef ASSIGN
}   /* AssignVariantFromSV */

HRESULT
SetSVFromVariantEx(pTHX_ VARIANTARG *pVariant, SV* sv, HV *stash,
		   BOOL bByRefObj)
{
    HRESULT hr = S_OK;
    VARTYPE vt = V_VT(pVariant);

#   define SET(perltype,vartype)                                 \
        if (vt & VT_BYREF) {                                     \
            sv_set##perltype (sv, *V_##vartype##REF(pVariant));  \
        } else {                                                 \
            sv_set##perltype (sv, V_##vartype (pVariant));       \
        }

    sv_setsv(sv, &PL_sv_undef);

    if (V_ISBYREF(pVariant) && bByRefObj) {
	WINOLEVARIANTOBJECT *pVarObj;
	Newz(0, pVarObj, 1, WINOLEVARIANTOBJECT);
	VariantInit(&pVarObj->variant);
	VariantInit(&pVarObj->byref);
	hr = VariantCopy(&pVarObj->variant, pVariant);
	if (FAILED(hr)) {
	    Safefree(pVarObj);
            return hr;
	}

	AddToObjectChain(aTHX_ (OBJECTHEADER*)pVarObj, WINOLEVARIANT_MAGIC);
	SV *classname = newSVpv(HvNAME(stash), 0);
	sv_catpvn(classname, "::Variant", 9);
	sv_setref_pv(sv, SvPVX(classname), pVarObj);
	SvREFCNT_dec(classname);
	return hr;
    }

    while (vt == (VT_VARIANT|VT_BYREF)) {
	pVariant = V_VARIANTREF(pVariant);
	vt = V_VT(pVariant);
    }

    if (V_ISARRAY(pVariant)) {
        VARTYPE vt_base = vt & VT_TYPEMASK;
	SAFEARRAY *psa = V_ISBYREF(pVariant) ? *V_ARRAYREF(pVariant)
	                                     : V_ARRAY(pVariant);
	int dim = SafeArrayGetDim(psa);

	/* convert 1-dim UI1 ARRAY to simple SvPV */
	if (vt_base == VT_UI1 && dim == 1) {
	    char *pStr;
	    LONG lLower, lUpper;

	    SafeArrayGetLBound(psa, 1, &lLower);
	    SafeArrayGetUBound(psa, 1, &lUpper);
	    hr = SafeArrayAccessData(psa, (void**)&pStr);
	    if (SUCCEEDED(hr)) {
		sv_setpvn(sv, pStr, lUpper-lLower+1);
		SafeArrayUnaccessData(psa);
	    }

	    return hr;
	}

	AV **pav;
	LONG *pArrayIndex, *pLowerBound, *pUpperBound;

	New(0, pav,         dim, AV*);
	New(0, pArrayIndex, dim, LONG);
	New(0, pLowerBound, dim, LONG);
	New(0, pUpperBound, dim, LONG);

	IV index;
	for (index = 0; index < dim; ++index) {
	    pav[index] = newAV();
	    SafeArrayGetLBound(psa, (UINT)(index+1), &pLowerBound[index]);
	    SafeArrayGetUBound(psa, (UINT)(index+1), &pUpperBound[index]);
	}

	Copy(pLowerBound, pArrayIndex, dim, long);

	hr = SafeArrayLock(psa);
	if (SUCCEEDED(hr)) {
            VARIANT variant;
            VariantInit(&variant);
            if (vt_base == VT_RECORD) {
                hr = SafeArrayGetRecordInfo(psa, &V_RECORDINFO(&variant));
                if (SUCCEEDED(hr))
                    V_VT(&variant) = VT_RECORD;
            }
            else
                V_VT(&variant) = vt_base | VT_BYREF;

            if (SUCCEEDED(hr)) {
                while (index >= 0) {
                    if (vt_base == VT_RECORD)
                        hr = SafeArrayPtrOfIndex(psa, pArrayIndex, &V_RECORD(&variant));
                    else
                        hr = SafeArrayPtrOfIndex(psa, pArrayIndex, &V_BYREF(&variant));
                    if (FAILED(hr))
                        break;

                    SV *val = newSV(0);
                    hr = SetSVFromVariantEx(aTHX_ &variant, val, stash);
                    if (FAILED(hr)) {
                        SvREFCNT_dec(val);
                        break;
                    }
                    av_push(pav[dim-1], val);

                    for (index = dim-1; index >= 0; --index) {
                        if (++pArrayIndex[index] <= pUpperBound[index])
                            break;

                        pArrayIndex[index] = pLowerBound[index];
                        if (index > 0) {
                            av_push(pav[index-1], newRV_noinc((SV*)pav[index]));
                            pav[index] = newAV();
                        }
                    }
                }
            }

	    /* preserve previous error code */
	    HRESULT hr2 = SafeArrayUnlock(psa);
	    if (SUCCEEDED(hr))
		hr = hr2;
	}

	for (index = 1; index < dim; ++index)
	    SvREFCNT_dec((SV*)pav[index]);

	if (SUCCEEDED(hr))
	    sv_setsv(sv, sv_2mortal(newRV_noinc((SV*)*pav)));
	else
	    SvREFCNT_dec((SV*)*pav);

	Safefree(pArrayIndex);
	Safefree(pLowerBound);
	Safefree(pUpperBound);
	Safefree(pav);

	return hr;
    }

    switch (vt & ~VT_BYREF) {
    case VT_VARIANT: /* invalid, should never happen */
    case VT_EMPTY:
    case VT_NULL:
	/* return "undef" */
	break;

    case VT_UI1:
	SET(iv, UI1);
	break;

    case VT_I2:
	SET(iv, I2);
	break;

    case VT_I4:
	SET(iv, I4);
	break;

    case VT_R4:
	SET(nv, R4);
	break;

    case VT_R8:
	SET(nv, R8);
	break;

    case VT_BSTR:
    {
	UINT cp = (UINT)QueryPkgVar(aTHX_ stash, CP_NAME, CP_LEN, cpDefault);

	if (V_ISBYREF(pVariant))
	    sv_setbstr(aTHX_ sv, *V_BSTRREF(pVariant), cp);
	else
	    sv_setbstr(aTHX_ sv, V_BSTR(pVariant), cp);
	break;
    }

    case VT_ERROR:
    case VT_DATE:
    {
 ConvertToVariant:
	SV *classname;
	WINOLEVARIANTOBJECT *pVarObj;
	Newz(0, pVarObj, 1, WINOLEVARIANTOBJECT);
	VariantInit(&pVarObj->variant);
	VariantInit(&pVarObj->byref);
	hr = VariantCopy(&pVarObj->variant, pVariant);
	if (FAILED(hr)) {
	    Safefree(pVarObj);
            break;
	}

	AddToObjectChain(aTHX_ (OBJECTHEADER*)pVarObj, WINOLEVARIANT_MAGIC);
	classname = newSVpv(HvNAME(stash), 0);
	sv_catpvn(classname, "::Variant", 9);
	sv_setref_pv(sv, SvPVX(classname), pVarObj);
	SvREFCNT_dec(classname);
 	break;
    }

    case VT_BOOL:
	if (V_ISBYREF(pVariant))
	    sv_setiv(sv, *V_BOOLREF(pVariant) ? 1 : 0);
	else
	    sv_setiv(sv, V_BOOL(pVariant) ? 1 : 0);
	break;

    case VT_DISPATCH:
    {
	IDispatch *pDispatch;

	if (V_ISBYREF(pVariant))
	    pDispatch = *V_DISPATCHREF(pVariant);
	else
	    pDispatch = V_DISPATCH(pVariant);

	if (pDispatch) {
	    pDispatch->AddRef();
	    sv_setsv(sv, CreatePerlObject(aTHX_ stash, pDispatch, NULL));
	}
	break;
    }

    case VT_UNKNOWN:
    {
	IUnknown *punk;
	IDispatch *pDispatch;

	if (V_ISBYREF(pVariant))
	    punk = *V_UNKNOWNREF(pVariant);
	else
	    punk = V_UNKNOWN(pVariant);

	if (punk &&
	    SUCCEEDED(punk->QueryInterface(IID_IDispatch, (void**)&pDispatch)))
	{
	    sv_setsv(sv, CreatePerlObject(aTHX_ stash, pDispatch, NULL));
	}
	break;
    }

    case VT_DECIMAL:
    {
	BOOL var = (BOOL)QueryPkgVar(aTHX_ stash, VAR_NAME, VAR_LEN, varDefault);
        if (var)
            goto ConvertToVariant;

	VARIANT variant;
	VariantInit(&variant);
	hr = VariantChangeTypeEx(&variant, pVariant, lcidDefault, 0, VT_R8);
	if (SUCCEEDED(hr) && V_VT(&variant) == VT_R8)
            sv_setnv(sv, V_R8(&variant));
	VariantClear(&variant);
	break;
    }

    case VT_RECORD:
    {
	UINT cp = (UINT)QueryPkgVar(aTHX_ stash, CP_NAME, CP_LEN, cpDefault);
        IRecordInfo *pinfo = V_RECORDINFO(pVariant);
        void *pRecord = V_RECORD(pVariant);

        ULONG count = 0;
        hr = pinfo->GetFieldNames(&count, NULL);
	if (FAILED(hr) || count == 0)
            break;

        BSTR *names;
        Newz(0, names, count, BSTR);
        hr = pinfo->GetFieldNames(&count, names);
	if (FAILED(hr)) {
            Safefree(names);
            break;
        }

        HV *hv = newHV();
        ULONG i;
        for (i=0; i<count; ++i) {
            VARIANT variant;
            void *pData = NULL;
            VariantInit(&variant);
            hr = pinfo->GetFieldNoCopy(pRecord, names[i], &variant, &pData);
            if (FAILED(hr))
                break;

            SV *value = newSV(0);
            hr = SetSVFromVariantEx(aTHX_ &variant, value, stash, FALSE);
            if (FAILED(hr)) {
                SvREFCNT_dec(value);
                break;
            }
	    SV *name = sv_setbstr(aTHX_ NULL, names[i], cp);
            hv_store_ent(hv, name, value, 0);
            SvREFCNT_dec(name);
        }

        for (i=0; i<count; ++i)
            SysFreeString(names[i]);
        Safefree(names);

	if (SUCCEEDED(hr))
	    sv_setsv(sv, sv_2mortal(newRV_noinc((SV*)hv)));
	else
	    SvREFCNT_dec((SV*)hv);

        break;
    }

    case VT_CY:
    default:
    {
	BOOL var = (BOOL)QueryPkgVar(aTHX_ stash, VAR_NAME, VAR_LEN, varDefault);
        if (var)
            goto ConvertToVariant;

	LCID lcid = (LCID)QueryPkgVar(aTHX_ stash, LCID_NAME, LCID_LEN, lcidDefault);
	UINT cp = (UINT)QueryPkgVar(aTHX_ stash, CP_NAME, CP_LEN, cpDefault);
	VARIANT variant;

	VariantInit(&variant);
	hr = VariantChangeTypeEx(&variant, pVariant, lcid, 0, VT_BSTR);
	if (SUCCEEDED(hr) && V_VT(&variant) == VT_BSTR)
	    sv_setbstr(aTHX_ sv, V_BSTR(&variant), cp);
	VariantClear(&variant);
	break;
    }
    }

    return hr;
#   undef SET
}   /* SetSVFromVariantEx */

HRESULT
SetSVFromVariant(pTHX_ VARIANTARG *pVariant, SV* sv, HV *stash)
{
    return SetSVFromVariantEx(aTHX_ pVariant, sv, stash);
}

IV
GetLocaleNumber(pTHX_ HV *hv, char *key, LCID lcid, LCTYPE lctype)
{
    if (hv) {
	SV **psv = hv_fetch(hv, key, (I32)strlen(key), FALSE);
	if (psv)
	    return SvIV(*psv);
    }

    IV number;
    char *info;
    int len = GetLocaleInfoA(lcid, lctype, NULL, 0);
    New(0, info, len, char);
    GetLocaleInfoA(lcid, lctype, info, len);
    number = atol(info);
    Safefree(info);
    return number;
}

char *
GetLocaleString(pTHX_ HV *hv, char *key, LCID lcid, LCTYPE lctype)
{
    if (hv) {
	SV **psv = hv_fetch(hv, key, (I32)strlen(key), FALSE);
	if (psv)
	    return SvPV_nolen(*psv);
    }

    int len = GetLocaleInfoA(lcid, lctype, NULL, 0);
    SV *sv = sv_2mortal(newSV(len));
    GetLocaleInfoA(lcid, lctype, SvPVX(sv), len);
    return SvPVX(sv);
}

void
Initialize(pTHX_ HV *stash, DWORD dwCoInit=COINIT_MULTITHREADED)
{
    dPERINTERP;

    DBG(("Initialize\n"));
    EnterCriticalSection(&g_CriticalSection);

    if (!g_bInitialized)
    {
	HRESULT hr = S_OK;

	g_pfnCoUninitialize = NULL;
	g_bInitialized = TRUE;

	DBG(("Initialize dwCoInit=%d\n", dwCoInit));

	if (dwCoInit == COINIT_OLEINITIALIZE) {
	    hr = OleInitialize(NULL);
	    if (SUCCEEDED(hr))
		g_pfnCoUninitialize = &OleUninitialize;
	}
	else if (dwCoInit != COINIT_NO_INITIALIZE) {
	    if (g_pfnCoInitializeEx)
		hr = g_pfnCoInitializeEx(NULL, dwCoInit);
	    else
		hr = CoInitialize(NULL);

	    if (SUCCEEDED(hr))
		g_pfnCoUninitialize = &CoUninitialize;
	}

	if (FAILED(hr) && hr != RPC_E_CHANGED_MODE)
	    ReportOleError(aTHX_ stash, hr);
    }

    LeaveCriticalSection(&g_CriticalSection);

}   /* Initialize */

void
Uninitialize(pTHX_ PERINTERP *pInterp)
{
    DBG(("Uninitialize\n"));
    EnterCriticalSection(&g_CriticalSection);
    if (g_bInitialized) {
	OBJECTHEADER *pHeader = g_pObj;
	while (pHeader) {
	    DBG(("Zombiefy object |%lx| lMagic=%lx\n",
		 pHeader, pHeader->lMagic));

	    switch (pHeader->lMagic) {
	    case WINOLE_MAGIC:
		ReleasePerlObject(aTHX_ (WINOLEOBJECT*)pHeader);
		break;

	    case WINOLEENUM_MAGIC: {
		WINOLEENUMOBJECT *pEnumObj = (WINOLEENUMOBJECT*)pHeader;
		if (pEnumObj->pEnum) {
		    pEnumObj->pEnum->Release();
		    pEnumObj->pEnum = NULL;
		}
		break;
	    }

	    case WINOLEVARIANT_MAGIC: {
		WINOLEVARIANTOBJECT *pVarObj = (WINOLEVARIANTOBJECT*)pHeader;
                ClearVariantObject(pVarObj);
		break;
	    }

	    case WINOLETYPELIB_MAGIC: {
		WINOLETYPELIBOBJECT *pObj = (WINOLETYPELIBOBJECT*)pHeader;
		if (pObj->pTypeLib) {
		    pObj->pTypeLib->Release();
		    pObj->pTypeLib = NULL;
		}
		break;
	    }

	    case WINOLETYPEINFO_MAGIC: {
		WINOLETYPEINFOOBJECT *pObj = (WINOLETYPEINFOOBJECT*)pHeader;
		if (pObj->pTypeInfo) {
		    pObj->pTypeInfo->Release();
		    pObj->pTypeInfo = NULL;
		}
		break;
	    }

	    default:
		DBG(("Unknown magic number: %08lx", pHeader->lMagic));
		break;
	    }
	    pHeader = pHeader->pNext;
	}

	DBG(("CoUninitialize\n"));
	if (g_pfnCoUninitialize)
	    g_pfnCoUninitialize();
	g_bInitialized = FALSE;
    }
    LeaveCriticalSection(&g_CriticalSection);

}   /* Uninitialize */

static void
AtExit(pTHX_ void *pVoid)
{
    PERINTERP *pInterp = (PERINTERP*)pVoid;

    DeleteCriticalSection(&g_CriticalSection);
    if (g_hOLE32)
	FreeLibrary(g_hOLE32);
    if (g_hHHCTRL)
	FreeLibrary(g_hHHCTRL);
#ifdef PERL_IMPLICIT_CONTEXT
    Safefree(pInterp);
#endif
    DBG(("AtExit done\n"));

}   /* AtExit */

void
Bootstrap(pTHX)
{
    dSP;
#ifdef PERL_IMPLICIT_CONTEXT
    PERINTERP *pInterp;
    New(0, pInterp, 1, PERINTERP);
    SV *sv = *hv_fetch(PL_modglobal, MY_VERSION, sizeof(MY_VERSION)-1, TRUE);

    if (SvOK(sv))
	warn(MY_VERSION ": Per-interpreter data already set");

    sv_setiv(sv, PTR2IV(pInterp));
#endif

    g_pObj = NULL;
    g_bInitialized = FALSE;
    g_hv_unique = newHV();
    InitializeCriticalSection(&g_CriticalSection);

    g_hOLE32 = LoadLibrary("OLE32");
    g_pfnCoInitializeEx = NULL;
    g_pfnCoCreateInstanceEx = NULL;
    if (g_hOLE32) {
	g_pfnCoInitializeEx = (FNCOINITIALIZEEX*)
	    GetProcAddress(g_hOLE32, "CoInitializeEx");
	g_pfnCoCreateInstanceEx = (FNCOCREATEINSTANCEEX*)
	    GetProcAddress(g_hOLE32, "CoCreateInstanceEx");
    }

    g_hHHCTRL = NULL;
    g_pfnHtmlHelp = NULL;

    SV *cmd = newSVpv("", 0);
    sv_setpvf(cmd, "END { %s->Uninitialize(%d); }", szWINOLE, WINOLE_MAGIC );

    PUSHMARK(sp);
    perl_eval_sv(cmd, G_DISCARD);
    SPAGAIN;

    SvREFCNT_dec(cmd);
    perl_atexit(AtExit, INTERP);

}   /* Bootstrap */

BOOL
CallObjectMethod(pTHX_ SV **mark, I32 ax, I32 items, char *pszMethod)
{
    /* If the 1st arg on the stack is a Win32::OLE object then the method
     * is called as an object method through Win32::OLE::Dispatch (like
     * the AUTOLOAD does) and CallObjectMethod returns TRUE. In this case
     * the caller should return immediately. Otherwise it should check the
     * parameters on the stack and implement its class method functionality.
     */
    dSP;

    if (items == 0)
	return FALSE;

    if (!sv_isobject(ST(0)) || !sv_derived_from(ST(0), szWINOLE))
	return FALSE;

    SV *retval = sv_newmortal();

    /* Dispatch must be called as: Dispatch($self,$method,$retval,@params),
     * so move all stack entries after the object ref up to make room for
     * the method name and return value.
     */
    PUSHMARK(mark);
    EXTEND(SP, 2);
    for (I32 item = 1; item < items; ++item)
	ST(2+items-item) = ST(items-item);
    sp += 2;

    ST(1) = sv_2mortal(newSVpv(pszMethod,0));
    ST(2) = retval;

    PUTBACK;
    perl_call_method("Dispatch", G_DISCARD);
    SPAGAIN;

    PUSHs(retval);
    PUTBACK;

    return TRUE;

}   /* CallObjectMethod */

}   /* extern "C" */

/*##########################################################################*/

MODULE = Win32::OLE		PACKAGE = Win32::OLE

PROTOTYPES: DISABLE

BOOT:
    Bootstrap(aTHX);

void
Initialize(...)
ALIAS:
    Uninitialize = 1
    SpinMessageLoop = 2
    MessageLoop = 3
    QuitMessageLoop = 4
    FreeUnusedLibraries = 5
    _Unique = 6
PPCODE:
{
    char *paszMethod[] = {"Initialize", "Uninitialize", "SpinMessageLoop",
                          "MessageLoop", "QuitMessageLoop",
			  "FreeUnusedLibraries", "_Unique"};

    if (CallObjectMethod(aTHX_ mark, ax, items, paszMethod[ix]))
	return;

    DBG(("Win32::OLE->%s()\n", paszMethod[ix]));

    if (items == 0) {
        warn("Win32::OLE->%s must be called as class method", paszMethod[ix]);
	XSRETURN_EMPTY;
    }

    HV *stash = gv_stashsv(ST(0), TRUE);
    SetLastOleError(aTHX_ stash);

    switch (ix) {
    case 0: {		// Initialize
	DWORD dwCoInit = COINIT_MULTITHREADED;
	if (items > 1 && SvOK(ST(1)))
	    dwCoInit = (DWORD)SvIV(ST(1));

	Initialize(aTHX_ gv_stashsv(ST(0), TRUE), dwCoInit);
	break;
    }
    case 1: {		// Uninitialize
	dPERINTERP;
	Uninitialize(aTHX_ INTERP);
	break;
    }
    case 2:		// SpinMessageLoop
	SpinMessageLoop();
	break;

    case 3: {		// MessageLoop
	MSG msg;
	DBG(("MessageLoop\n"));
	while (GetMessage(&msg, NULL, 0, 0)) {
	    if (msg.hwnd == NULL && msg.message == WM_USER)
		break;
	    TranslateMessage(&msg);
	    DispatchMessage(&msg);
	}
	break;
    }
    case 4:		// QuitMessageLoop
	PostThreadMessage(GetCurrentThreadId(), WM_USER, 0, 0);
	break;

    case 5:		// FreeUnusedLibraries
	CoFreeUnusedLibraries();
	break;

    case 6: {		// _Unique
        dPERINTERP;
	hv_undef(g_hv_unique);
	break;
    }
    }

    XSRETURN_EMPTY;
}

void
new(...)
PPCODE:
{
    CLSID clsid;
    IDispatch *pDispatch = NULL;
    OLECHAR Buffer[OLE_BUF_SIZ];
    OLECHAR *pBuffer;
    HRESULT hr;

    if (CallObjectMethod(aTHX_ mark, ax, items, "new"))
	return;

    if (items < 2 || items > 3) {
	warn("Usage: Win32::OLE->new(PROGID[,DESTROY])");
	XSRETURN_EMPTY;
    }

    SV *self = ST(0);
    HV *stash = gv_stashsv(self, TRUE);
    SV *progid = ST(1);
    SV *destroy = NULL;
    UINT cp = (UINT)QueryPkgVar(aTHX_ stash, CP_NAME, CP_LEN, cpDefault);

    Initialize(aTHX_ stash);
    SetLastOleError(aTHX_ stash);

    if (items == 3)
	destroy = CheckDestroyFunction(aTHX_ ST(2), "Win32::OLE->new");

    ST(0) = &PL_sv_undef;

    /* normal case: no DCOM */
    if (!SvROK(progid) || SvTYPE(SvRV(progid)) != SVt_PVAV) {
	pBuffer = GetWideChar(aTHX_ progid, Buffer, OLE_BUF_SIZ, cp);
	if (StartsWithAlpha(aTHX_ progid))
	    hr = CLSIDFromProgID(pBuffer, &clsid);
	else
	    hr = CLSIDFromString(pBuffer, &clsid);
	ReleaseBuffer(aTHX_ pBuffer, Buffer);
	if (SUCCEEDED(hr)) {
	    hr = CoCreateInstance(clsid, NULL, CLSCTX_SERVER,
				  IID_IDispatch, (void**)&pDispatch);
            /* The tlbinf32.dll from Microsoft fails this call.
             * It however supports instantiating an IUnknown interface
             * and then querying that one for IDispatch...
             */
            if (hr == E_NOINTERFACE) {
                IUnknown *punk;
                hr = CoCreateInstance(clsid, NULL, CLSCTX_SERVER,
                                      IID_IUnknown, (void**)&punk);
                if (SUCCEEDED(hr)) {
                    hr = punk->QueryInterface(IID_IDispatch, (void**)&pDispatch);
                    punk->Release();
                }
            }
        }

	if (!CheckOleError(aTHX_ stash, hr)) {
	    ST(0) = CreatePerlObject(aTHX_ stash, pDispatch, destroy);
	    DBG(("Win32::OLE::new |%lx| |%lx|\n", ST(0), pDispatch));
	}
	XSRETURN(1);
    }

    /* DCOM might not exist on Win95 (and does not on NT 3.5) */
    dPERINTERP;
    if (!g_pfnCoCreateInstanceEx) {
	hr = HRESULT_FROM_WIN32(ERROR_SERVICE_DOES_NOT_EXIST);
	ReportOleError(aTHX_ stash, hr);
	XSRETURN(1);
    }

    /* DCOM spec: ['Servername', 'Program.ID'] */
    AV *av = (AV*)SvRV(progid);
    if (av_len(av) != 1) {
	warn("Win32::OLE->new: for DCOM use ['Machine', 'Prog.Id']");
	XSRETURN(1);
    }
    SV *host = *av_fetch(av, 0, FALSE);
    progid = *av_fetch(av, 1, FALSE);

    /* determine hostname */
    if (SvPOK(host) && IsLocalMachine(aTHX_ host))
        host = NULL;

    /* determine CLSID */
    pBuffer = GetWideChar(aTHX_ progid, Buffer, OLE_BUF_SIZ, cp);
    if (StartsWithAlpha(aTHX_ progid)) {
	hr = CLSIDFromProgID(pBuffer, &clsid);
	if (FAILED(hr) && host)
	    hr = CLSIDFromRemoteRegistry(aTHX_ host, progid, &clsid);
    }
    else
        hr = CLSIDFromString(pBuffer, &clsid);
    ReleaseBuffer(aTHX_ pBuffer, Buffer);
    if (FAILED(hr)) {
	ReportOleError(aTHX_ stash, hr);
	XSRETURN(1);
    }

    /* setup COSERVERINFO & MULTI_QI parameters */
    DWORD clsctx = CLSCTX_REMOTE_SERVER;
    COSERVERINFO ServerInfo;
    OLECHAR ServerName[OLE_BUF_SIZ];
    MULTI_QI multi_qi;

    Zero(&ServerInfo, 1, COSERVERINFO);
    if (host)
	ServerInfo.pwszName = GetWideChar(aTHX_ host, ServerName,
					  OLE_BUF_SIZ, cp);
    else
	clsctx = CLSCTX_SERVER;

    Zero(&multi_qi, 1, MULTI_QI);
    multi_qi.pIID = &IID_IDispatch;

    /* create instance on remote server */
    hr = g_pfnCoCreateInstanceEx(clsid, NULL, clsctx, &ServerInfo,
				  1, &multi_qi);
    ReleaseBuffer(aTHX_ ServerInfo.pwszName, ServerName);
    if (!CheckOleError(aTHX_ stash, hr)) {
	pDispatch = (IDispatch*)multi_qi.pItf;
	ST(0) = CreatePerlObject(aTHX_ stash, pDispatch, destroy);
	DBG(("Win32::OLE::new |%lx| |%lx|\n", ST(0), pDispatch));
    }
    XSRETURN(1);
}

void
DESTROY(self)
    SV *self
PPCODE:
{
    WINOLEOBJECT *pObj = GetOleObject(aTHX_ self, TRUE);
    DBG(("Win32::OLE::DESTROY |%lx| |%lx|\n", pObj,
	 pObj ? pObj->pDispatch : NULL));
    if (pObj) {
	ReleasePerlObject(aTHX_ pObj);
	pObj->flags |= OBJFLAG_DESTROYED;
    }
    XSRETURN_EMPTY;
}

void
Dispatch(self,method,retval,...)
    SV *self
    SV *method
    SV *retval
PPCODE:
{
    char *buffer = "";
    size_t length;
    unsigned int argErr;
    unsigned int index;
    I32 len;
    WINOLEOBJECT *pObj;
    EXCEPINFO excepinfo;
    DISPID dispID = DISPID_VALUE;
    DISPID dispIDParam = DISPID_PROPERTYPUT;
    USHORT wFlags = DISPATCH_METHOD | DISPATCH_PROPERTYGET;
    VARIANT result;
    DISPPARAMS dispParams;
    SV *curitem, *sv;
    HE **rghe = NULL; /* named argument names */

    SV *err = NULL; /* error details */
    HRESULT hr = S_OK;

    ST(0) = &PL_sv_no;
    Zero(&excepinfo, 1, EXCEPINFO);
    VariantInit(&result);

    if (!sv_isobject(self)) {
	warn("Win32::OLE::Dispatch: Cannot be called as class method");
	DEBUGBREAK;
	XSRETURN(1);
    }

    pObj = GetOleObject(aTHX_ self);
    if (!pObj) {
	XSRETURN(1);
    }

    HV *stash = SvSTASH(pObj->self);
    SetLastOleError(aTHX_ stash);

    LCID lcid = (LCID)QueryPkgVar(aTHX_ stash, LCID_NAME, LCID_LEN, lcidDefault);
    UINT cp = (UINT)QueryPkgVar(aTHX_ stash, CP_NAME, CP_LEN, cpDefault);

    /* allow [wFlags, 'Method'] instead of 'Method' */
    if (SvROK(method) && (sv = SvRV(method)) &&	SvTYPE(sv) == SVt_PVAV &&
	!SvOBJECT(sv) && av_len((AV*)sv) == 1)
    {
	wFlags = (USHORT)SvIV(*av_fetch((AV*)sv, 0, FALSE));
	method = *av_fetch((AV*)sv, 1, FALSE);
    }

    if (SvIOK(method)) {
        /* XXX this will NOT work with named parameters */
        dispID = (DISPID)SvIV(method);
    }
    else if (SvPOK(method)) {
	buffer = SvPV(method, length);
	if (length > 0) {
            int newenum = (int)QueryPkgVar(aTHX_ stash, _NEWENUM_NAME, _NEWENUM_LEN);
            if (newenum && strEQ(buffer, "_NewEnum")) {
                AV *av = newAV();
                PUSHMARK(sp);
                PUSHs(sv_2mortal(newSVpv(szWINOLEENUM, 0)));
                PUSHs(self);
                PUTBACK;
                items = perl_call_method("All", G_ARRAY);
                SPAGAIN;
                for (index=0; index < (unsigned int)items; ++index)
                    av_push(av, newSVsv(ST(index)));
                sv_setsv(retval, sv_2mortal(newRV_noinc((SV*)av)));
		XSRETURN_YES;
            }

	    hr = GetHashedDispID(aTHX_ pObj, method, dispID, lcid, cp);
	    if (FAILED(hr)) {
		if (PL_hints & HINT_STRICT_SUBS) {
		    err = newSVpvf(" in GetIDsOfNames of \"%s\"", buffer);
		    ReportOleError(aTHX_ stash, hr, NULL, sv_2mortal(err));
		}
		XSRETURN_EMPTY;
	    }
	}
    }

    DBG(("Dispatch \"%s\"\n", buffer));

    dispParams.rgvarg = NULL;
    dispParams.rgdispidNamedArgs = NULL;
    dispParams.cNamedArgs = 0;
    dispParams.cArgs = items - 3;

    /* last arg is ref to a non-object-hash => named arguments */
    curitem = ST(items-1);
    if (SvROK(curitem) && (sv = SvRV(curitem)) &&
	SvTYPE(sv) == SVt_PVHV && !SvOBJECT(sv))
    {
	if (wFlags & (DISPATCH_PROPERTYPUT|DISPATCH_PROPERTYPUTREF)) {
	    warn("Win32::OLE->Dispatch: named arguments not supported "
		 "for PROPERTYPUT");
	    DEBUGBREAK;
	    XSRETURN_EMPTY;
	}

	OLECHAR **rgszNames;
	DISPID  *rgdispids;
	HV      *hv = (HV*)sv;

	dispParams.cNamedArgs = (UINT)HvKEYS(hv);
	dispParams.cArgs += dispParams.cNamedArgs - 1;

	New(0, rghe, dispParams.cNamedArgs, HE*);
	New(0, dispParams.rgdispidNamedArgs, dispParams.cNamedArgs, DISPID);
	New(0, dispParams.rgvarg, dispParams.cArgs, VARIANTARG);
	for (index = 0; index < dispParams.cArgs; ++index)
	    VariantInit(&dispParams.rgvarg[index]);

	New(0, rgszNames, 1+dispParams.cNamedArgs, OLECHAR*);
	New(0, rgdispids, 1+dispParams.cNamedArgs, DISPID);

	rgszNames[0] = AllocOleString(aTHX_ buffer, (int)length, cp);
	hv_iterinit(hv);
	for (index = 0; index < dispParams.cNamedArgs; ++index) {
	    rghe[index] = hv_iternext(hv);
	    char *pszName = hv_iterkey(rghe[index], &len);
	    rgszNames[1+index] = AllocOleString(aTHX_ pszName, len, cp);
	}

	hr = pObj->pDispatch->GetIDsOfNames(IID_NULL, rgszNames,
			      1+dispParams.cNamedArgs, lcid, rgdispids);

	if (SUCCEEDED(hr)) {
	    for (index = 0; index < dispParams.cNamedArgs; ++index) {
		dispParams.rgdispidNamedArgs[index] = rgdispids[index+1];
		hr = SetVariantFromSVEx(aTHX_ hv_iterval(hv, rghe[index]),
					&dispParams.rgvarg[index], cp, lcid);
		if (FAILED(hr))
		    break;
	    }
	}
	else {
	    unsigned int cErrors = 0;
	    unsigned int error = 0;

	    for (index = 1; index <= dispParams.cNamedArgs; ++index)
		if (rgdispids[index] == DISPID_UNKNOWN)
		   ++cErrors;

	    err = sv_2mortal(newSVpv("",0));
	    for (index = 1; index <= dispParams.cNamedArgs; ++index)
		if (rgdispids[index] == DISPID_UNKNOWN) {
		    if (error++ > 0)
			sv_catpv(err, error == cErrors ? " and " : ", ");
		    sv_catpvf(err, "\"%s\"", hv_iterkey(rghe[index-1], &len));
		}
	    sv_catpvf(err, " in GetIDsOfNames for \"%s\"", buffer);
	}

	for (index = 0; index <= dispParams.cNamedArgs; ++index)
	    SysFreeString(rgszNames[index]);
	Safefree(rgszNames);
	Safefree(rgdispids);

	if (FAILED(hr))
	    goto Cleanup;

	--items;
    }

    if (dispParams.cArgs > dispParams.cNamedArgs) {
	if (!dispParams.rgvarg) {
	    New(0, dispParams.rgvarg, dispParams.cArgs, VARIANTARG);
	    for (index = 0; index < dispParams.cArgs; ++index)
		VariantInit(&dispParams.rgvarg[index]);
	}

	for (index = dispParams.cNamedArgs; index < dispParams.cArgs; ++index) {
	    SV *sv = ST(items-1-(index-dispParams.cNamedArgs));
            VARIANT *pVariant = &dispParams.rgvarg[index];

            /* XXX requirement to call mg_get() may change in Perl > 5.005 */
            MagicGet(aTHX_ sv);

            if (SvOK(sv)) {
                hr = SetVariantFromSVEx(aTHX_ sv, pVariant, cp, lcid);
                if (FAILED(hr))
                    goto Cleanup;
            }
            else {
                V_VT(pVariant) = VT_ERROR;
                V_ERROR(pVariant) = DISP_E_PARAMNOTFOUND;
            }
	}
    }

    if (wFlags & (DISPATCH_PROPERTYPUT|DISPATCH_PROPERTYPUTREF)) {
	Safefree(dispParams.rgdispidNamedArgs);
	dispParams.rgdispidNamedArgs = &dispIDParam;
	dispParams.cNamedArgs = 1;
    }

    hr = pObj->pDispatch->Invoke(dispID, IID_NULL, lcid, wFlags,
				  &dispParams, &result, &excepinfo, &argErr);
    if (FAILED(hr)) {
	/* mega kludge. if a method in WORD is called and we ask
	 * for a result when one is not returned then
	 * hResult == DISP_E_EXCEPTION. this only happens on
	 * functions whose DISPID > 0x8000 */

	if (hr == DISP_E_EXCEPTION && dispID > 0x8000) {
	    Zero(&excepinfo, 1, EXCEPINFO);
	    hr = pObj->pDispatch->Invoke(dispID, IID_NULL, lcid, wFlags,
				  &dispParams, NULL, &excepinfo, &argErr);
	}
    }

    if (SUCCEEDED(hr)) {
	if (sv_isobject(retval) && sv_derived_from(retval, szWINOLEVARIANT)) {
	    WINOLEVARIANTOBJECT *pVarObj = GetOleVariantObject(aTHX_ retval);
	    if (pVarObj) {
		ClearVariantObject(pVarObj);
		MyVariantCopy(&pVarObj->variant, &result);
		ST(0) = &PL_sv_yes;
	    }
	}
	else {
	    hr = SetSVFromVariantEx(aTHX_ &result, retval, stash);
            if (SUCCEEDED(hr))
                ST(0) = &PL_sv_yes;
	}
    }

    if (FAILED(hr)) {
	/* use more specific error code from exception when available */
	if (hr == DISP_E_EXCEPTION && FAILED(excepinfo.scode))
	    hr = excepinfo.scode;

	char *pszDelim = "";
	err = sv_newmortal();
	sv_setpvf(err, "in ");

	if (wFlags&DISPATCH_METHOD) {
	    sv_catpv(err, "METHOD");
	    pszDelim = "/";
	}
	if (wFlags&DISPATCH_PROPERTYGET) {
	    sv_catpvf(err, "%sPROPERTYGET", pszDelim);
	    pszDelim = "/";
	}
	if (wFlags&DISPATCH_PROPERTYPUT) {
	    sv_catpvf(err, "%sPROPERTYPUT", pszDelim);
	    pszDelim = "/";
	}
	if (wFlags&DISPATCH_PROPERTYPUTREF)
	    sv_catpvf(err, "%sPROPERTYPUTREF", pszDelim);

	sv_catpvf(err, " \"%s\"", buffer);

	if (hr == DISP_E_TYPEMISMATCH || hr == DISP_E_PARAMNOTFOUND) {
	    if (rghe && argErr < dispParams.cNamedArgs)
		sv_catpvf(err, " argument \"%s\"",
			  hv_iterkey(rghe[argErr], &len));
	    else
		sv_catpvf(err, " argument %d", dispParams.cArgs - argErr);
	}
    }

 Cleanup:
    VariantClear(&result);
    if (dispParams.cArgs != 0 && dispParams.rgvarg) {
	for (index = 0; index < dispParams.cArgs; ++index)
	    VariantClear(&dispParams.rgvarg[index]);
	Safefree(dispParams.rgvarg);
    }
    Safefree(rghe);
    if (dispParams.rgdispidNamedArgs != &dispIDParam)
	Safefree(dispParams.rgdispidNamedArgs);

    CheckOleError(aTHX_ stash, hr, &excepinfo, err);

    XSRETURN(1);
}

void
GetIDsOfNames(self, method)
    SV *self
    SV *method
PPCODE:
{
    DISPID dispID;

    WINOLEOBJECT *pObj = GetOleObject(aTHX_ self);
    if (!pObj)
	XSRETURN_EMPTY;

    HV *stash = SvSTASH(pObj->self);
    SetLastOleError(aTHX_ stash);

    LCID lcid = (LCID)QueryPkgVar(aTHX_ stash, LCID_NAME, LCID_LEN, lcidDefault);
    UINT cp = (UINT)QueryPkgVar(aTHX_ stash, CP_NAME, CP_LEN, cpDefault);

    HRESULT hr = GetHashedDispID(aTHX_ pObj, method, dispID, lcid, cp);
    if (FAILED(hr))
        XSRETURN_EMPTY;

    XSRETURN_IV(dispID);
}

void
EnumAllObjects(...)
PPCODE:
{
    if (CallObjectMethod(aTHX_ mark, ax, items, "EnumAllObjects"))
	return;

    if (items > 2) {
	warn("Usage: Win32::OLE->EnumAllObjects([CALLBACK])");
	XSRETURN_EMPTY;
    }

    if (items == 2 && (!SvROK(ST(1)) || SvTYPE(SvRV(ST(1))) != SVt_PVCV)) {
	warn(MY_VERSION "Win32::OLE->EnumAllObjects: "
	     "CALLBACK must be a CODE ref");
	XSRETURN_EMPTY;
    }

    dPERINTERP;
    IV count = 0;
    OBJECTHEADER *pHeader = g_pObj;
    SV *callback = (items == 2) ? ST(1) : NULL;

    while (pHeader) {
	if (pHeader->lMagic == WINOLE_MAGIC) {
	    ++count;
	    if (callback) {
		WINOLEOBJECT *pObj = (WINOLEOBJECT*)pHeader;;
		SV *self = newRV_inc((SV*)pObj->self);
		if (Gv_AMG(SvSTASH(pObj->self)))
		    SvAMAGIC_on(self);

		ENTER;
		SAVETMPS;
		PUSHMARK(sp);
		XPUSHs(sv_2mortal(self));
		PUTBACK;
		perl_call_sv(callback, G_DISCARD);
		SPAGAIN;
		FREETMPS;
		LEAVE;
	    }
	}
	pHeader = pHeader->pNext;
    }
    XSRETURN_IV(count);
}

void
Forward(...)
PPCODE:
{
    if (CallObjectMethod(aTHX_ mark, ax, items, "Forward"))
	return;

    if (items != 2) {
	warn("Usage: Win32::OLE->Forward(METHOD)");
	XSRETURN_EMPTY;
    }

    SV *self = ST(0);
    SV *method = ST(1);

    if (!SvROK(method) || SvTYPE(SvRV(method)) != SVt_PVCV) {
	warn("Win32::OLE->Forward: method must be a CODE ref");
	XSRETURN_EMPTY;
    }

    HV *stash = gv_stashsv(self, TRUE);
    IDispatch *pDispatch = new Forwarder(aTHX_ stash, method);
    ST(0) = CreatePerlObject(aTHX_ stash, pDispatch, NULL);
    XSRETURN(1);
}

void
GetActiveObject(...)
PPCODE:
{
    CLSID clsid;
    OLECHAR Buffer[OLE_BUF_SIZ];
    OLECHAR *pBuffer;
    HRESULT hr;
    IUnknown *pUnknown;
    IDispatch *pDispatch;

    if (CallObjectMethod(aTHX_ mark, ax, items, "GetActiveObject"))
	return;

    if (items < 2 || items > 3) {
	warn("Usage: Win32::OLE->GetActiveObject(PROGID[,DESTROY])");
	XSRETURN_EMPTY;
    }

    SV *self = ST(0);
    HV *stash = gv_stashsv(self, TRUE);
    SV *progid = ST(1);
    SV *destroy = NULL;
    UINT cp = (UINT)QueryPkgVar(aTHX_ stash, CP_NAME, CP_LEN, cpDefault);

    Initialize(aTHX_ stash);
    SetLastOleError(aTHX_ stash);

    if (items == 3)
	destroy = CheckDestroyFunction(aTHX_ ST(2),
				       "Win32::OLE->GetActiveObject");

    pBuffer = GetWideChar(aTHX_ progid, Buffer, OLE_BUF_SIZ, cp);
    if (isalpha(SvPV_nolen(progid)[0]))
        hr = CLSIDFromProgID(pBuffer, &clsid);
    else
        hr = CLSIDFromString(pBuffer, &clsid);
    ReleaseBuffer(aTHX_ pBuffer, Buffer);
    if (CheckOleError(aTHX_ stash, hr))
	XSRETURN_EMPTY;

    hr = GetActiveObject(clsid, 0, &pUnknown);
    /* Don't call CheckOleError! Return "undef" for "Server not running" */
    if (FAILED(hr))
	XSRETURN_EMPTY;

    hr = pUnknown->QueryInterface(IID_IDispatch, (void**)&pDispatch);
    pUnknown->Release();
    if (CheckOleError(aTHX_ stash, hr))
	XSRETURN_EMPTY;

    ST(0) = CreatePerlObject(aTHX_ stash, pDispatch, destroy);
    DBG(("Win32::OLE::GetActiveObject |%lx| |%lx|\n", ST(0), pDispatch));
    XSRETURN(1);
}

void
GetObject(...)
PPCODE:
{
    IBindCtx *pBindCtx;
    IMoniker *pMoniker;
    IDispatch *pDispatch;
    OLECHAR Buffer[OLE_BUF_SIZ];
    OLECHAR *pBuffer;
    ULONG ulEaten;
    HRESULT hr;

    if (CallObjectMethod(aTHX_ mark, ax, items, "GetObject"))
	return;

    if (items < 2 || items > 3) {
	warn("Usage: Win32::OLE->GetObject(PATHNAME[,DESTROY])");
	XSRETURN_EMPTY;
    }

    SV *self = ST(0);
    HV *stash = gv_stashsv(self, TRUE);
    SV *pathname = ST(1);
    SV *destroy = NULL;
    UINT cp = (UINT)QueryPkgVar(aTHX_ stash, CP_NAME, CP_LEN, cpDefault);

    Initialize(aTHX_ stash);
    SetLastOleError(aTHX_ stash);

    if (items == 3)
	destroy = CheckDestroyFunction(aTHX_ ST(2), "Win32::OLE->GetObject");

    hr = CreateBindCtx(0, &pBindCtx);
    if (CheckOleError(aTHX_ stash, hr))
	XSRETURN_EMPTY;

    pBuffer = GetWideChar(aTHX_ pathname, Buffer, OLE_BUF_SIZ, cp);
    hr = MkParseDisplayName(pBindCtx, pBuffer, &ulEaten, &pMoniker);
    ReleaseBuffer(aTHX_ pBuffer, Buffer);
    if (FAILED(hr)) {
	pBindCtx->Release();
	SV *sv = sv_newmortal();
	sv_setpvf(sv, "after character %lu in \"%s\"", ulEaten, SvPV_nolen(pathname));
	ReportOleError(aTHX_ stash, hr, NULL, sv);
	XSRETURN_EMPTY;
    }

    hr = pMoniker->BindToObject(pBindCtx, NULL, IID_IDispatch,
				 (void**)&pDispatch);
    pBindCtx->Release();
    pMoniker->Release();
    if (CheckOleError(aTHX_ stash, hr))
	XSRETURN_EMPTY;

    ST(0) = CreatePerlObject(aTHX_ stash, pDispatch, destroy);
    XSRETURN(1);
}

void
GetTypeInfo(self)
    SV *self
PPCODE:
{
    WINOLEOBJECT *pObj = GetOleObject(aTHX_ self);
    if (!pObj)
	XSRETURN_EMPTY;

    ITypeInfo *pTypeInfo;
    TYPEATTR  *pTypeAttr;

    HV *stash = gv_stashsv(self, TRUE);
    LCID lcid = (LCID)QueryPkgVar(aTHX_ stash, LCID_NAME, LCID_LEN, lcidDefault);

    SetLastOleError(aTHX_ stash);
    HRESULT hr = pObj->pDispatch->GetTypeInfo(0, lcid, &pTypeInfo);
    if (CheckOleError(aTHX_ stash, hr))
	XSRETURN_EMPTY;

    hr = pTypeInfo->GetTypeAttr(&pTypeAttr);
    if (FAILED(hr)) {
	pTypeInfo->Release();
	ReportOleError(aTHX_ stash, hr);
	XSRETURN_EMPTY;
    }

    ST(0) = sv_2mortal(CreateTypeInfoObject(aTHX_ pTypeInfo, pTypeAttr));
    XSRETURN(1);
}

void
QueryInterface(self,itf)
    SV *self
    SV *itf
PPCODE:
{
    WINOLEOBJECT *pObj = GetOleObject(aTHX_ self);
    if (!pObj)
	XSRETURN_EMPTY;

    IID iid;

    // XXX support GUIDs in addition to names too
    char *pszItf = SvPV_nolen(itf);

    DBG(("QueryInterface(%s)\n", pszItf));
    HV *stash = SvSTASH(pObj->self);
    LCID lcid = (LCID)QueryPkgVar(aTHX_ stash, LCID_NAME, LCID_LEN, lcidDefault);
    UINT cp = (UINT)QueryPkgVar(aTHX_ stash, CP_NAME, CP_LEN, cpDefault);

    SetLastOleError(aTHX_ stash);

    HRESULT hr = FindIID(aTHX_ pObj, pszItf, &iid, NULL, cp, lcid);
    if (CheckOleError(aTHX_ stash, hr))
	XSRETURN_EMPTY;

    IUnknown *pUnknown;
    hr = pObj->pDispatch->QueryInterface(iid, (void**)&pUnknown);
    DBG(("  QueryInterface(iid): 0x%08x\n", hr));
    if (CheckOleError(aTHX_ stash, hr))
        XSRETURN_EMPTY;

    IDispatch *pDispatch;
    hr = pUnknown->QueryInterface(IID_IDispatch, (void**)&pDispatch);
    DBG(("  QueryInterface(IDispatch): 0x%08x\n", hr));
    pUnknown->Release();
    if (CheckOleError(aTHX_ stash, hr))
        XSRETURN_EMPTY;

    ST(0) = CreatePerlObject(aTHX_ stash, pDispatch, NULL);
    DBG(("Win32::OLE::QueryInterface |%lx| |%lx|\n", ST(0), pDispatch));
    XSRETURN(1);
}

void
QueryObjectType(...)
PPCODE:
{
    if (CallObjectMethod(aTHX_ mark, ax, items, "QueryObjectType"))
	return;

    if (items != 2) {
	warn("Usage: Win32::OLE->QueryObjectType(OBJECT)");
	XSRETURN_EMPTY;
    }

    SV *object = ST(1);

    if (!sv_isobject(object) || !sv_derived_from(object, szWINOLE)) {
	warn("Win32::OLE->QueryObjectType: object is not a Win32::OLE object");
	XSRETURN_EMPTY;
    }

    WINOLEOBJECT *pObj = GetOleObject(aTHX_ object);
    if (!pObj)
	XSRETURN_EMPTY;

    ITypeInfo *pTypeInfo;
    ITypeLib *pTypeLib;
    unsigned int count;
    BSTR bstr;

    HRESULT hr = pObj->pDispatch->GetTypeInfoCount(&count);
    if (FAILED(hr) || count == 0)
	XSRETURN_EMPTY;

    HV *stash = gv_stashsv(ST(0), TRUE);
    LCID lcid = (LCID)QueryPkgVar(aTHX_ stash, LCID_NAME, LCID_LEN, lcidDefault);
    UINT cp = (UINT)QueryPkgVar(aTHX_ stash, CP_NAME, CP_LEN, cpDefault);

    SetLastOleError(aTHX_ stash);
    hr = pObj->pDispatch->GetTypeInfo(0, lcid, &pTypeInfo);
    if (CheckOleError(aTHX_ stash, hr))
	XSRETURN_EMPTY;

    /* Return ('TypeLib Name', 'Class Name') in array context */
    if (GIMME_V == G_ARRAY) {
	hr = pTypeInfo->GetContainingTypeLib(&pTypeLib, &count);
	if (FAILED(hr)) {
	    pTypeInfo->Release();
	    ReportOleError(aTHX_ stash, hr);
	    XSRETURN_EMPTY;
	}

	hr = pTypeLib->GetDocumentation(-1, &bstr, NULL, NULL, NULL);
	pTypeLib->Release();
	if (FAILED(hr)) {
	    pTypeInfo->Release();
	    ReportOleError(aTHX_ stash, hr);
	    XSRETURN_EMPTY;
	}

	PUSHs(sv_2mortal(sv_setbstr(aTHX_ NULL, bstr, cp)));
	SysFreeString(bstr);
    }

    hr = pTypeInfo->GetDocumentation(MEMBERID_NIL, &bstr, NULL, NULL, NULL);
    pTypeInfo->Release();
    if (CheckOleError(aTHX_ stash, hr))
	XSRETURN_EMPTY;

    PUSHs(sv_2mortal(sv_setbstr(aTHX_ NULL, bstr, cp)));
    SysFreeString(bstr);
}

void
WithEvents(...)
PPCODE:
{
    if (CallObjectMethod(aTHX_ mark, ax, items, "WithEvents"))
	return;

    if (items < 2) {
	warn("Usage: Win32::OLE->WithEvents(OBJECT [, HANDLER [, INTERFACE]])");
	XSRETURN_EMPTY;
    }

    WINOLEOBJECT *pObj = GetOleObject(aTHX_ ST(1));
    if (!pObj)
	XSRETURN_EMPTY;

    // disconnect previous event handler
    if (pObj->pEventSink) {
	pObj->pEventSink->Unadvise();
	pObj->pEventSink = NULL;
    }

    if (items == 2)
	XSRETURN_EMPTY;

    SV *handler = ST(2);
    HV *stash = SvSTASH(pObj->self);

    // make sure we are running in a single threaded apartment
    HRESULT hr = CoInitialize(NULL);
    if (CheckOleError(aTHX_ stash, hr))
	XSRETURN_EMPTY;
    CoUninitialize();

    LCID lcid = (LCID)QueryPkgVar(aTHX_ stash, LCID_NAME, LCID_LEN, lcidDefault);
    UINT cp = (UINT)QueryPkgVar(aTHX_ stash, CP_NAME, CP_LEN, cpDefault);
    SetLastOleError(aTHX_ stash);

    IID iid;
    ITypeInfo *pTypeInfo = NULL;

    // Interfacename specified?
    if (items > 3) {
	SV *itf = ST(3);
	if (sv_isobject(itf) && sv_derived_from(itf, szWINOLETYPEINFO)) {
	    WINOLETYPEINFOOBJECT *pObj = GetOleTypeInfoObject(aTHX_ itf);
	    if (!pObj)
		XSRETURN_EMPTY;

	    if (pObj->pTypeAttr->typekind == TKIND_DISPATCH) {
		iid = (IID)pObj->pTypeAttr->guid;
		pTypeInfo = pObj->pTypeInfo;
		pTypeInfo->AddRef();
	    }
	    else if (pObj->pTypeAttr->typekind == TKIND_COCLASS) {
		// Enumerate all implemented types of the COCLASS
		for (UINT i=0; i < pObj->pTypeAttr->cImplTypes; i++) {
		    int iFlags;
		    hr = pObj->pTypeInfo->GetImplTypeFlags(i, &iFlags);
		    DBG(("GetImplTypeFlags: hr=0x%08x i=%d iFlags=%d\n", hr, i, iFlags));
		    if (FAILED(hr))
			continue;

		    // looking for the [default] [source]
		    // we just hope that it is a dispinterface :-)
		    if ((iFlags & IMPLTYPEFLAG_FDEFAULT) &&
			(iFlags & IMPLTYPEFLAG_FSOURCE))
		    {
			HREFTYPE hRefType = 0;
			hr = pObj->pTypeInfo->GetRefTypeOfImplType(i, &hRefType);
			DBG(("GetRefTypeOfImplType: hr=0x%08x\n", hr));
			if (FAILED(hr))
			    continue;
			hr = pObj->pTypeInfo->GetRefTypeInfo(hRefType, &pTypeInfo);
			DBG(("GetRefTypeInfo: hr=0x%08x\n", hr));
			if (SUCCEEDED(hr))
			    break;
		    }
		}

		// Now that would be a bad surprise, if we didn't find it, wouldn't it?
		if (!pTypeInfo) {
		    if (SUCCEEDED(hr))
			hr = E_UNEXPECTED;
		}
		else {
		    // Determine IID of default source interface
		    TYPEATTR *pTypeAttr;
		    hr = pTypeInfo->GetTypeAttr(&pTypeAttr);
		    if (SUCCEEDED(hr)) {
			iid = pTypeAttr->guid;
			pTypeInfo->ReleaseTypeAttr(pTypeAttr);
		    }
		    else
			pTypeInfo->Release();
		}
	    }
	    else {
		XSRETURN_EMPTY; /* set hr instead XXX error message */
	    }
	}
	else { /* interface _not_ a Win32::OLE::TypeInfo object */
	    char *pszItf = SvPV_nolen(itf);
	    if (isalpha(pszItf[0]))
		hr = FindIID(aTHX_ pObj, pszItf, &iid, &pTypeInfo, cp, lcid);
	    else {
		OLECHAR Buffer[OLE_BUF_SIZ];
		OLECHAR *pBuffer = GetWideChar(aTHX_ itf, Buffer, OLE_BUF_SIZ, cp);
		hr = IIDFromString(pBuffer, &iid);
		ReleaseBuffer(aTHX_ pBuffer, Buffer);
	    }
	}
    }
    else
	hr = FindDefaultSource(aTHX_ pObj, &iid, &pTypeInfo, cp, lcid);

    if (CheckOleError(aTHX_ stash, hr))
	XSRETURN_EMPTY;

    // Get IConnectionPointContainer interface
    IConnectionPointContainer *pContainer;
    hr = pObj->pDispatch->QueryInterface(IID_IConnectionPointContainer,
					 (void**)&pContainer);
    DBG(("QueryInterFace(IConnectionPointContainer): hr=0x%08x\n", hr));
    if (FAILED(hr)) {
	pTypeInfo->Release();
	ReportOleError(aTHX_ stash, hr);
        XSRETURN_EMPTY;
    }

    // Find default source connection point
    IConnectionPoint *pConnectionPoint;
    hr = pContainer->FindConnectionPoint(iid, &pConnectionPoint);
    pContainer->Release();
    DBG(("FindConnectionPoint: hr=0x%08x\n", hr));
    if (FAILED(hr)) {
	if (pTypeInfo)
	    pTypeInfo->Release();
	ReportOleError(aTHX_ stash, hr);
        XSRETURN_EMPTY;
    }

    // Connect our EventSink object to it
    pObj->pEventSink = new EventSink(aTHX_ pObj, handler, iid, pTypeInfo);
    hr = pObj->pEventSink->Advise(pConnectionPoint);
    pConnectionPoint->Release();
    DBG(("Advise: hr=0x%08x\n", hr));
    if (FAILED(hr)) {
	if (pTypeInfo)
	    pTypeInfo->Release();
	pObj->pEventSink->Release();
	pObj->pEventSink = NULL;
	ReportOleError(aTHX_ stash, hr);
    }

 #ifdef _DEBUG
    // Get IOleControl interface
    IOleControl *pOleControl;
    hr = pObj->pDispatch->QueryInterface(IID_IOleControl, (void**)&pOleControl);
    DBG(("QueryInterface(IOleControl): 0x%08x\n", hr));
    if (SUCCEEDED(hr)) {
	pOleControl->FreezeEvents(TRUE);
	pOleControl->FreezeEvents(FALSE);
	pOleControl->Release();
    }
 #endif

    XSRETURN_EMPTY;
}

##############################################################################

MODULE = Win32::OLE		PACKAGE = Win32::OLE::Tie

void
DESTROY(self)
    SV *self
PPCODE:
{
    WINOLEOBJECT *pObj = GetOleObject(aTHX_ self, TRUE);
    DBG(("Win32::OLE::Tie::DESTROY |%lx| |%lx|\n", pObj,
	 pObj ? pObj->pDispatch : NULL));

    if (pObj) {
	/* objects may be destroyed in the wrong order during global cleanup */
	if (!(pObj->flags & OBJFLAG_DESTROYED)) {
	    DBG(("Win32::OLE::Tie::DESTROY: OLE object not yet destroyed\n"));
	    if (pObj->pDispatch) {
		/* make sure the reference to the tied hash is still valid */
		sv_unmagic((SV*)pObj->self, 'P');
		sv_magic((SV*)pObj->self, self, 'P', Nullch, 0);
		ReleasePerlObject(aTHX_ pObj);
	    }
	    /* untie hash because we free the object *right now* */
	    sv_unmagic((SV*)pObj->self, 'P');
	}
	RemoveFromObjectChain(aTHX_ (OBJECTHEADER*)pObj);
	Safefree(pObj);
    }
    DBG(("End of Win32::OLE::Tie::DESTROY\n"));
    XSRETURN_EMPTY;
}

void
Fetch(self,key,def)
    SV *self
    SV *key
    SV *def
PPCODE:
{
    char *buffer;
    STRLEN length;
    unsigned int argErr;
    EXCEPINFO excepinfo;
    DISPPARAMS dispParams;
    VARIANT result;
    VARIANTARG propName;
    DISPID dispID = DISPID_VALUE;
    HRESULT hr;

    buffer = SvPV(key, length);
    if (strEQ(buffer, PERL_OLE_ID)) {
	DBG(("Win32::OLE::Tie::Fetch(0x%08x,'%s')\n", self, buffer));
	ST(0) = *hv_fetch((HV*)SvRV(self), PERL_OLE_ID, PERL_OLE_IDLEN, 0);
	XSRETURN(1);
    }

    WINOLEOBJECT *pObj = GetOleObject(aTHX_ self);
    DBG(("Win32::OLE::Tie::Fetch(0x%08x,'%s')\n", pObj, buffer));
    if (!pObj)
	XSRETURN_EMPTY;

    HV *stash = SvSTASH(pObj->self);
    SetLastOleError(aTHX_ stash);

    ST(0) = &PL_sv_undef;
    VariantInit(&result);
    VariantInit(&propName);

    LCID lcid = (LCID)QueryPkgVar(aTHX_ stash, LCID_NAME, LCID_LEN, lcidDefault);
    UINT cp = (UINT)QueryPkgVar(aTHX_ stash, CP_NAME, CP_LEN, cpDefault);

    dispParams.cArgs = 0;
    dispParams.rgvarg = NULL;
    dispParams.cNamedArgs = 0;
    dispParams.rgdispidNamedArgs = NULL;

    hr = GetHashedDispID(aTHX_ pObj, key, dispID, lcid, cp);
    if (FAILED(hr)) {
	if (!SvTRUE(def)) {
	    SV *err = newSVpvf(" in GetIDsOfNames \"%s\"", buffer);
	    ReportOleError(aTHX_ stash, hr, NULL, sv_2mortal(err));
	    XSRETURN(1);
	}

	/* default method call: $self->{Key} ---> $self->Item('Key') */
	V_VT(&propName) = VT_BSTR;
	V_BSTR(&propName) = AllocOleStringFromSV(aTHX_ key, cp);
	dispParams.cArgs = 1;
	dispParams.rgvarg = &propName;
    }

    Zero(&excepinfo, 1, EXCEPINFO);

    hr = pObj->pDispatch->Invoke(dispID, IID_NULL,
		    lcid, DISPATCH_METHOD | DISPATCH_PROPERTYGET,
		    &dispParams, &result, &excepinfo, &argErr);
    VariantClear(&propName);

    if (FAILED(hr)) {
	SV *sv = sv_newmortal();
	sv_setpvf(sv, "in METHOD/PROPERTYGET \"%s\"", buffer);
	VariantClear(&result);
	ReportOleError(aTHX_ stash, hr, &excepinfo, sv);
    }
    else {
	ST(0) = sv_newmortal();
	hr = SetSVFromVariantEx(aTHX_ &result, ST(0), stash);
	VariantClear(&result);
	CheckOleError(aTHX_ stash, hr);
    }

    XSRETURN(1);
}

void
Store(self,key,value,def)
    SV *self
    SV *key
    SV *value
    SV *def
PPCODE:
{
    unsigned int argErr;
    STRLEN length;
    char *buffer;
    unsigned int index;
    HRESULT hr;
    EXCEPINFO excepinfo;
    DISPID dispID = DISPID_VALUE;
    DISPID dispIDParam = DISPID_PROPERTYPUT;
    DISPPARAMS dispParams;
    VARIANTARG propertyValue[2];
    SV *err = NULL;

    WINOLEOBJECT *pObj = GetOleObject(aTHX_ self);
    if (!pObj)
	XSRETURN_EMPTY;

    HV *stash = SvSTASH(pObj->self);
    SetLastOleError(aTHX_ stash);

    LCID lcid = (LCID)QueryPkgVar(aTHX_ stash, LCID_NAME, LCID_LEN, lcidDefault);
    UINT cp = (UINT)QueryPkgVar(aTHX_ stash, CP_NAME, CP_LEN, cpDefault);

    dispParams.rgdispidNamedArgs = &dispIDParam;
    dispParams.rgvarg = propertyValue;
    dispParams.cNamedArgs = 1;
    dispParams.cArgs = 1;

    VariantInit(&propertyValue[0]);
    VariantInit(&propertyValue[1]);
    Zero(&excepinfo, 1, EXCEPINFO);

    buffer = SvPV(key, length);
    hr = GetHashedDispID(aTHX_ pObj, key, dispID, lcid, cp);
    if (FAILED(hr)) {
	if (!SvTRUE(def)) {
	    SV *err = newSVpvf(" in GetIDsOfNames \"%s\"", buffer);
	    ReportOleError(aTHX_ stash, hr, NULL, sv_2mortal(err));
	    XSRETURN_EMPTY;
	}

	dispParams.cArgs = 2;
	V_VT(&propertyValue[1]) = VT_BSTR;
	V_BSTR(&propertyValue[1]) = AllocOleStringFromSV(aTHX_ key, cp);
    }

    hr = SetVariantFromSVEx(aTHX_ value, &propertyValue[0], cp, lcid);
    if (SUCCEEDED(hr)) {
	USHORT wFlags = DISPATCH_PROPERTYPUT;

	/* objects are passed by reference */
	VARTYPE vt = V_VT(&propertyValue[0]) & VT_TYPEMASK;
	if (vt == VT_DISPATCH || vt == VT_UNKNOWN)
	    wFlags = DISPATCH_PROPERTYPUTREF;

	hr = pObj->pDispatch->Invoke(dispID, IID_NULL, lcid, wFlags,
                                     &dispParams, NULL, &excepinfo, &argErr);
	if (FAILED(hr)) {
	    err = sv_newmortal();
	    sv_setpvf(err, "in PROPERTYPUT%s \"%s\"",
		      (wFlags == DISPATCH_PROPERTYPUTREF ? "REF" : ""), buffer);
	}
    }

    for (index = 0; index < dispParams.cArgs; ++index)
	VariantClear(&propertyValue[index]);

    if (CheckOleError(aTHX_ stash, hr, &excepinfo, err))
	XSRETURN_EMPTY;

    XSRETURN_YES;
}

void
FIRSTKEY(self,...)
    SV *self
ALIAS:
    NEXTKEY   = 1
    FIRSTENUM = 2
    NEXTENUM  = 3
PPCODE:
{
    /* NEXTKEY has an additional "lastkey" arg, which is not needed here */
    WINOLEOBJECT *pObj = GetOleObject(aTHX_ self);
    char *paszMethod[] = {"FIRSTKEY", "NEXTKEY", "FIRSTENUM", "NEXTENUM"};

    DBG(("%s called, pObj=%p\n", paszMethod[ix], pObj));
    if (!pObj)
	XSRETURN_EMPTY;

    HV *stash = SvSTASH(pObj->self);
    SetLastOleError(aTHX_ stash);

    SV *sv = NULL;
    switch (ix) {
    case 0: /* FIRSTKEY */
	FetchTypeInfo(aTHX_ pObj);
	pObj->PropIndex = 0;
    case 1: /* NEXTKEY */
	sv = NextPropertyName(aTHX_ pObj);
	break;

    case 2: /* FIRSTENUM */
	if (pObj->pEnum)
	    pObj->pEnum->Release();
	pObj->pEnum = CreateEnumVARIANT(aTHX_ pObj);
    case 3: /* NEXTENUM */
	sv = NextEnumElement(aTHX_ pObj->pEnum, stash);
	if (!sv) {
	    pObj->pEnum->Release();
	    pObj->pEnum = NULL;
	}
	break;
    }

    if (!sv)
        sv = &PL_sv_undef;
    else if (!SvIMMORTAL(sv))
	sv_2mortal(sv);

    ST(0) = sv;
    XSRETURN(1);
}

##############################################################################

MODULE = Win32::OLE		PACKAGE = Win32::OLE::Const

void
_LoadRegTypeLib(classid,major,minor,locale,typelib,codepage)
    SV *classid
    IV major
    IV minor
    SV *locale
    SV *typelib
    SV *codepage
PPCODE:
{
    ITypeLib *pTypeLib;
    TLIBATTR *pTLibAttr;
    CLSID clsid;
    OLECHAR Buffer[OLE_BUF_SIZ];
    OLECHAR *pBuffer;
    HRESULT hr;
    LCID lcid = SvIOK(locale) ? (LCID)SvIV(locale) : lcidDefault;
    UINT cp = SvIOK(codepage) ? (UINT)SvIV(codepage) : cpDefault;
    HV *stash = gv_stashpv(szWINOLE, TRUE);

    Initialize(aTHX_ stash);
    SetLastOleError(aTHX_ stash);

    pBuffer = GetWideChar(aTHX_ classid, Buffer, OLE_BUF_SIZ, cp);
    hr = CLSIDFromString(pBuffer, &clsid);
    ReleaseBuffer(aTHX_ pBuffer, Buffer);
    if (CheckOleError(aTHX_ stash, hr))
	XSRETURN_EMPTY;

    hr = LoadRegTypeLib(clsid, (USHORT)major, (USHORT)minor, lcid, &pTypeLib);
    if (FAILED(hr) && SvPOK(typelib)) {
	/* typelib not registerd, try to read from file "typelib" */
	pBuffer = GetWideChar(aTHX_ typelib, Buffer, OLE_BUF_SIZ, cp);
	hr = LoadTypeLibEx(pBuffer, REGKIND_NONE, &pTypeLib);
	ReleaseBuffer(aTHX_ pBuffer, Buffer);
    }
    if (CheckOleError(aTHX_ stash, hr))
	XSRETURN_EMPTY;

    hr = pTypeLib->GetLibAttr(&pTLibAttr);
    if (FAILED(hr)) {
	pTypeLib->Release();
	ReportOleError(aTHX_ stash, hr);
	XSRETURN_EMPTY;
    }

    ST(0) = sv_2mortal(CreateTypeLibObject(aTHX_ pTypeLib, pTLibAttr));
    XSRETURN(1);
}

void
_Constants(typelib,caller)
    SV *typelib
    SV *caller
PPCODE:
{
    HRESULT hr;
    UINT cp = cpDefault;
    HV *stash = gv_stashpv(szWINOLE, TRUE);
    HV *hv;
    unsigned int count;

    WINOLETYPELIBOBJECT *pObj = GetOleTypeLibObject(aTHX_ typelib);
    if (!pObj)
	XSRETURN_EMPTY;

    if (SvOK(caller)) {
	/* we'll define inlineable functions returning a const */
        hv = gv_stashsv(caller, TRUE);
	ST(0) = &PL_sv_undef;
    }
    else {
	/* we'll return ref to hash with constant name => value pairs */
	hv = newHV();
        ST(0) = sv_2mortal(newRV_noinc((SV*)hv));
    }

    /* loop through all objects in type lib */
    count = pObj->pTypeLib->GetTypeInfoCount();
    for (unsigned int index=0; index < count; ++index) {
	ITypeInfo *pTypeInfo;
	TYPEATTR  *pTypeAttr;

	hr = pObj->pTypeLib->GetTypeInfo(index, &pTypeInfo);
	if (CheckOleError(aTHX_ stash, hr))
	    continue;

	hr = pTypeInfo->GetTypeAttr(&pTypeAttr);
	if (FAILED(hr)) {
	    pTypeInfo->Release();
	    ReportOleError(aTHX_ stash, hr);
	    continue;
	}

        if (!(pTypeAttr->wTypeFlags & (TYPEFLAG_FHIDDEN |
                                       TYPEFLAG_FRESTRICTED)))
        {
            for (int iVar=0; iVar < pTypeAttr->cVars; ++iVar) {
                VARDESC *pVarDesc;

                hr = pTypeInfo->GetVarDesc(iVar, &pVarDesc);
                /* XXX LEAK alert */
                if (CheckOleError(aTHX_ stash, hr))
                    continue;

                if (pVarDesc->varkind == VAR_CONST &&
                    !(pVarDesc->wVarFlags & (VARFLAG_FHIDDEN |
                                             VARFLAG_FRESTRICTED |
                                             VARFLAG_FNONBROWSABLE)))
                {
                    unsigned int cName;
                    BSTR bstr;
                    char szName[64];

                    hr = pTypeInfo->GetNames(pVarDesc->memid, &bstr, 1, &cName);
                    if (CheckOleError(aTHX_ stash, hr) || cName == 0 || !bstr)
                        continue;

                    char *pszName = GetMultiByte(aTHX_ bstr, szName, sizeof(szName), cp);
                    SV *sv = newSV(0);
                    /* XXX LEAK alert */
                    hr = SetSVFromVariantEx(aTHX_ pVarDesc->lpvarValue,
                                            sv, stash);
                    if (!CheckOleError(aTHX_ stash, hr)) {
                        if (SvOK(caller)) {
                            /* XXX check for valid symbol name */
                            newCONSTSUB(hv, pszName, sv);
                        }
                        else
                            hv_store(hv, pszName, (I32)strlen(pszName), sv, 0);
                    }
                    SysFreeString(bstr);
                    ReleaseBuffer(aTHX_ pszName, szName);
                }
                pTypeInfo->ReleaseVarDesc(pVarDesc);
            }
        }

	pTypeInfo->ReleaseTypeAttr(pTypeAttr);
	pTypeInfo->Release();
    }
    XSRETURN(1);
}

void
_Typelibs(self,typelib)
    SV *self
    SV *typelib
PPCODE:
{
    HKEY hKeyTypelib;
    FILETIME ft;
    LONG err = RegOpenKeyExA(HKEY_CLASSES_ROOT, SvPV_nolen(typelib),
                             0, KEY_READ, &hKeyTypelib);
    if (err != ERROR_SUCCESS)
	XSRETURN_NO;

    EXTEND(SP, 5);

    // Enumerate all Clsids
    for (DWORD dwClsid=0;; ++dwClsid) {
	HKEY hKeyClsid;
	char szClsid[200];
        DWORD cbClsid = sizeof(szClsid);
        err = RegEnumKeyExA(hKeyTypelib, dwClsid, szClsid, &cbClsid,
                            NULL, NULL, NULL, &ft);
        if (err != ERROR_SUCCESS)
            break;

        err = RegOpenKeyExA(hKeyTypelib, szClsid, 0, KEY_READ, &hKeyClsid);
        if (err != ERROR_SUCCESS)
            continue;

	// Enumerate versions for current clsid
	for (DWORD dwVersion=0;; ++dwVersion) {
	    HKEY hKeyVersion;
	    char szVersion[20];
            DWORD cbVersion = sizeof(szVersion);

            err = RegEnumKeyExA(hKeyClsid, dwVersion, szVersion, &cbVersion,
                                NULL, NULL, NULL, &ft);
            if (err != ERROR_SUCCESS)
                break;

            err = RegOpenKeyExA(hKeyClsid, szVersion, 0, KEY_READ, &hKeyVersion);
            if (err != ERROR_SUCCESS)
                continue;

	    char szTitle[600];
            LONG cbTitle = sizeof(szTitle);
            err = RegQueryValueA(hKeyVersion, NULL, szTitle, &cbTitle);
            if (err != ERROR_SUCCESS || cbTitle <= 1)
                continue;

	    // Enumerate languages
	    for (DWORD dwLangid=0;; ++dwLangid) {
		char szLangid[20];
		DWORD cbLangid = sizeof(szLangid);
                err = RegEnumKeyExA(hKeyVersion, dwLangid, szLangid, &cbLangid,
                                    NULL, NULL, NULL, &ft);
                if (err != ERROR_SUCCESS)
                    break;

		// Language ids must be strictly numeric
		char *psz=szLangid;
		while (isDIGIT(*psz))
		    ++psz;
		if (*psz)
		    continue;

		HKEY hKeyLangid;
                err = RegOpenKeyExA(hKeyVersion, szLangid, 0, KEY_READ,
                                    &hKeyLangid);
                if (err != ERROR_SUCCESS)
                    continue;

		// Retrieve filename of type library
		char szFile[MAX_PATH+1];
		LONG cbFile = sizeof(szFile);
                err = RegQueryValueA(hKeyLangid, "win32", szFile, &cbFile);
		if (err == ERROR_SUCCESS && cbFile > 1) {
                    ENTER;
                    SAVETMPS;
                    PUSHMARK(SP);
		    PUSHs(sv_2mortal(newSVpv(szClsid, cbClsid)));
		    PUSHs(sv_2mortal(newSVpv(szTitle, cbTitle-1)));
		    PUSHs(sv_2mortal(newSVpv(szVersion, cbVersion)));
		    PUSHs(sv_2mortal(newSVpv(szLangid, cbLangid)));
		    PUSHs(sv_2mortal(newSVpv(szFile, cbFile-1)));
                    PUTBACK;
                    perl_call_pv("Win32::OLE::Const::_Typelib", G_DISCARD);
                    SPAGAIN;
                    FREETMPS;
                    LEAVE;
		}

		RegCloseKey(hKeyLangid);
	    }
	    RegCloseKey(hKeyVersion);
	}
	RegCloseKey(hKeyClsid);
    }
    RegCloseKey(hKeyTypelib);
    XSRETURN_YES;
}

void
_ShowHelpContext(helpfile,context)
    char *helpfile
    IV context
PPCODE:
{
    HWND hwnd;
    dPERINTERP;

    if (!g_hHHCTRL) {
	g_hHHCTRL = LoadLibrary("HHCTRL.OCX");
	if (g_hHHCTRL)
	    g_pfnHtmlHelp = (FNHTMLHELP*)GetProcAddress(g_hHHCTRL, "HtmlHelpA");
    }

    if (!g_pfnHtmlHelp) {
	warn(MY_VERSION ": HtmlHelp control unavailable");
	XSRETURN_EMPTY;
    }

    // HH_HELP_CONTEXT 0x0F: display mapped numeric value in dwData
    hwnd = g_pfnHtmlHelp(GetDesktopWindow(), helpfile, 0x0f, (DWORD)context);

    if (hwnd == 0 && context == 0) // try HH_DISPLAY_TOPIC 0x0
	g_pfnHtmlHelp(GetDesktopWindow(), helpfile, 0, (DWORD)context);
}

##############################################################################

MODULE = Win32::OLE		PACKAGE = Win32::OLE::Enum

void
new(self,object)
    SV *self
    SV *object
ALIAS:
    Clone = 1
PPCODE:
{
    WINOLEENUMOBJECT *pEnumObj;
    New(0, pEnumObj, 1, WINOLEENUMOBJECT);

    if (ix == 0) { /* new */
	WINOLEOBJECT *pObj = GetOleObject(aTHX_ object);
	if (pObj) {
	    HV *olestash = GetWin32OleStash(aTHX_ object);
	    SetLastOleError(aTHX_ olestash);
	    pEnumObj->pEnum = CreateEnumVARIANT(aTHX_ pObj);
	}
    }
    else { /* Clone */
	WINOLEENUMOBJECT *pOriginal = GetOleEnumObject(aTHX_ self);
	if (pOriginal) {
	    HV *olestash = GetWin32OleStash(aTHX_ self);
	    SetLastOleError(aTHX_ olestash);

	    HRESULT hr = pOriginal->pEnum->Clone(&pEnumObj->pEnum);
	    CheckOleError(aTHX_ olestash, hr);
	}
    }

    if (!pEnumObj->pEnum) {
	Safefree(pEnumObj);
	XSRETURN_EMPTY;
    }

    AddToObjectChain(aTHX_ (OBJECTHEADER*)pEnumObj, WINOLEENUM_MAGIC);

    SV *sv = newSViv(PTR2IV(pEnumObj));
    ST(0) = sv_2mortal(sv_bless(newRV_noinc(sv), GetStash(aTHX_ self)));
    XSRETURN(1);
}

void
DESTROY(self)
    SV *self
PPCODE:
{
    WINOLEENUMOBJECT *pEnumObj = GetOleEnumObject(aTHX_ self, TRUE);
    if (pEnumObj) {
	RemoveFromObjectChain(aTHX_ (OBJECTHEADER*)pEnumObj);
	if (pEnumObj->pEnum)
	    pEnumObj->pEnum->Release();
	Safefree(pEnumObj);
    }
    XSRETURN_EMPTY;
}

void
All(self,...)
    SV *self
ALIAS:
    Next = 1
PPCODE:
{
    int count = 1;
    if (ix == 0) { /* All */
	/* my @list = Win32::OLE::Enum->All($Excel->Workbooks); */
	if (!sv_isobject(self) && items > 1) {
	    /* $self = $self->new(shift); */
	    SV *obj = ST(1);
	    PUSHMARK(sp);
	    PUSHs(self);
	    PUSHs(obj);
	    PUTBACK;
	    items = perl_call_method("new", G_SCALAR);
	    SPAGAIN;
	    if (items == 1)
		self = POPs;
	    PUTBACK;
	}
    }
    else { /* Next */
	if (items > 1)
	    count = (int)SvIV(ST(1));
	if (count < 1) {
	    warn(MY_VERSION ": Win32::OLE::Enum::Next: invalid Count %ld",
		 count);
	    DEBUGBREAK;
	    count = 1;
	}
    }

    WINOLEENUMOBJECT *pEnumObj = GetOleEnumObject(aTHX_ self);
    if (!pEnumObj)
	XSRETURN_EMPTY;

    HV *olestash = GetWin32OleStash(aTHX_ self);
    SetLastOleError(aTHX_ olestash);

    while (ix == 0 || count-- > 0) {
	SV *sv = NextEnumElement(aTHX_ pEnumObj->pEnum, olestash);
	if (!sv)
	    break;
	if (!SvIMMORTAL(sv))
	    sv_2mortal(sv);
        XPUSHs(sv);
    }
}

void
Reset(self)
    SV *self
PPCODE:
{
    WINOLEENUMOBJECT *pEnumObj = GetOleEnumObject(aTHX_ self);
    if (!pEnumObj)
	XSRETURN_NO;

    HV *olestash = GetWin32OleStash(aTHX_ self);
    SetLastOleError(aTHX_ olestash);

    HRESULT hr = pEnumObj->pEnum->Reset();
    CheckOleError(aTHX_ olestash, hr);
    ST(0) = boolSV(hr == S_OK);
    XSRETURN(1);
}

void
Skip(self,...)
    SV *self
PPCODE:
{
    WINOLEENUMOBJECT *pEnumObj = GetOleEnumObject(aTHX_ self);
    if (!pEnumObj)
	XSRETURN_NO;

    HV *olestash = GetWin32OleStash(aTHX_ self);
    SetLastOleError(aTHX_ olestash);
    int count = (items > 1) ? (int)SvIV(ST(1)) : 1;
    HRESULT hr = pEnumObj->pEnum->Skip(count);
    CheckOleError(aTHX_ olestash, hr);
    ST(0) = boolSV(hr == S_OK);
    XSRETURN(1);
}

##############################################################################

MODULE = Win32::OLE		PACKAGE = Win32::OLE::Variant

void
new(self,...)
    SV *self
PPCODE:
{
    HRESULT hr;
    WINOLEVARIANTOBJECT *pVarObj;
    VARTYPE vt = items < 2 ? VT_EMPTY : (VARTYPE)SvIV(ST(1));
    SV *data = items < 3 ? Nullsv : ST(2);

    // XXX Initialize should be superfluous here
    // Initialize();
    HV *olestash = GetWin32OleStash(aTHX_ self);
    SetLastOleError(aTHX_ olestash);

    VARTYPE vt_base = vt & VT_TYPEMASK;
    if (!data && vt_base != VT_NULL && vt_base != VT_EMPTY &&
	vt_base != VT_BSTR && vt_base != VT_DISPATCH && vt_base != VT_VARIANT)
    {
	warn(MY_VERSION ": Win32::OLE::Variant->new(vt, data): data may be"
	                " omitted only for VT_NULL, VT_EMPTY, VT_BSTR,"
                        " VT_DISPATCH or VT_VARIANT");
	XSRETURN_EMPTY;
    }

    Newz(0, pVarObj, 1, WINOLEVARIANTOBJECT);
    VARIANT *pVariant = &pVarObj->variant;
    VariantInit(pVariant);
    VariantInit(&pVarObj->byref);

    V_VT(pVariant) = vt;
    if (vt & VT_BYREF) {
	if ((vt & ~VT_BYREF) == VT_VARIANT)
	    V_VARIANTREF(pVariant) = &pVarObj->byref;
	else
	    V_BYREF(pVariant) = &V_UI1(&pVarObj->byref);
    }

    if (vt & VT_ARRAY) {
	UINT cDims = items - 2;
	SAFEARRAYBOUND *rgsabound;
	SV *sv = ST(items-1);

	if (cDims == 0) {
	    warn(MY_VERSION ": Win32::OLE::Variant->new() VT_ARRAY but "
		 "no array dimensions specified");
	    Safefree(pVarObj);
	    XSRETURN_EMPTY;
	}

	Newz(0, rgsabound, cDims, SAFEARRAYBOUND);
	for (unsigned int iDim=0; iDim < cDims; ++iDim) {
	    SV *sv = ST(2+iDim);

	    if (SvROK(sv) && SvTYPE(SvRV(sv)) == SVt_PVAV) {
		AV *av = (AV*)SvRV(sv);
		SV **elt = av_fetch(av, 0, FALSE);
		if (elt)
		    rgsabound[iDim].lLbound = (LONG)SvIV(*elt);
		rgsabound[iDim].cElements = 1;
		elt = av_fetch(av, 1, FALSE);
		if (elt)
		    rgsabound[iDim].cElements +=
			(ULONG)(SvIV(*elt) - rgsabound[iDim].lLbound);
	    }
	    else
		rgsabound[iDim].cElements = (ULONG)SvIV(sv);
	}

	SAFEARRAY *psa = SafeArrayCreate(vt_base, cDims, rgsabound);
	Safefree(rgsabound);
	if (!psa) {
	    /* XXX No HRESULT value available */
	    warn(MY_VERSION ": Win32::OLE::Variant->new() couldnot "
		 "allocate SafeArray");
	    Safefree(pVarObj);
	    XSRETURN_EMPTY;
	}

	if (vt & VT_BYREF)
	    *V_ARRAYREF(pVariant) = psa;
	else
	    V_ARRAY(pVariant) = psa;
    }
    else if (vt == VT_UI1 && SvPOK(data)) {
	/* Special case: VT_UI1 with string implies VT_ARRAY */
	unsigned char* pDest;
	STRLEN len;
	char *ptr = SvPV(data, len);
	V_ARRAY(pVariant) = SafeArrayCreateVector(VT_UI1, 0, (ULONG)len);
	if (V_ARRAY(pVariant)) {
	    V_VT(pVariant) = VT_UI1 | VT_ARRAY;
	    hr = SafeArrayAccessData(V_ARRAY(pVariant), (void**)&pDest);
	    if (FAILED(hr)) {
		VariantClear(pVariant);
		ReportOleError(aTHX_ olestash, hr);
	    }
	    else {
		memcpy(pDest, ptr, len);
		SafeArrayUnaccessData(V_ARRAY(pVariant));
	    }
	}
    }
    else {
	UINT cp = (UINT)QueryPkgVar(aTHX_ olestash, CP_NAME, CP_LEN, cpDefault);
	LCID lcid = (LCID)QueryPkgVar(aTHX_ olestash, LCID_NAME, LCID_LEN,
                                      lcidDefault);
	hr = AssignVariantFromSV(aTHX_ data, pVariant, cp, lcid);
	if (FAILED(hr)) {
	    Safefree(pVarObj);
	    ReportOleError(aTHX_ olestash, hr);
	    XSRETURN_EMPTY;
	}
    }

    AddToObjectChain(aTHX_ (OBJECTHEADER*)pVarObj, WINOLEVARIANT_MAGIC);

    HV *stash = GetStash(aTHX_ self);
    SV *sv = newSViv(PTR2IV(pVarObj));
    ST(0) = sv_2mortal(sv_bless(newRV_noinc(sv), stash));
    XSRETURN(1);
}

void
DESTROY(self)
    SV *self
PPCODE:
{
    WINOLEVARIANTOBJECT *pVarObj = GetOleVariantObject(aTHX_ self);
    if (pVarObj) {
	RemoveFromObjectChain(aTHX_ (OBJECTHEADER*)pVarObj);
        ClearVariantObject(pVarObj);
	Safefree(pVarObj);
    }

    XSRETURN_EMPTY;
}

void
As(self,type)
    SV *self
    IV type
PPCODE:
{
    WINOLEVARIANTOBJECT *pVarObj = GetOleVariantObject(aTHX_ self);
    if (!pVarObj)
	XSRETURN_EMPTY;

    HRESULT hr;
    VARIANT variant;
    HV *olestash = GetWin32OleStash(aTHX_ self);
    LCID lcid = (LCID)QueryPkgVar(aTHX_ olestash, LCID_NAME, LCID_LEN, lcidDefault);

    SV *sv = &PL_sv_undef;
    SetLastOleError(aTHX_ olestash);
    VariantInit(&variant);
    hr = VariantChangeTypeEx(&variant, &pVarObj->variant, lcid, 0, (VARTYPE)type);
    if (SUCCEEDED(hr)) {
	sv = sv_newmortal();
	hr = SetSVFromVariantEx(aTHX_ &variant, sv, olestash);
    }
    else if (V_VT(&pVarObj->variant) == VT_ERROR) {
	/* special handling for VT_ERROR */
	sv = sv_newmortal();
	V_VT(&variant) = VT_I4;
	V_I4(&variant) = V_ERROR(&pVarObj->variant);
	hr = SetSVFromVariantEx(aTHX_ &variant, sv, olestash, FALSE);
    }
    VariantClear(&variant);
    CheckOleError(aTHX_ olestash, hr);
    ST(0) = sv;
    XSRETURN(1);
}

void
ChangeType(self,type)
    SV *self
    IV type
PPCODE:
{
    WINOLEVARIANTOBJECT *pVarObj = GetOleVariantObject(aTHX_ self);
    if (!pVarObj)
	XSRETURN_EMPTY;

    HRESULT hr = E_INVALIDARG;
    HV *olestash = GetWin32OleStash(aTHX_ self);
    LCID lcid = (LCID)QueryPkgVar(aTHX_ olestash, LCID_NAME, LCID_LEN, lcidDefault);

    SetLastOleError(aTHX_ olestash);
    /* XXX: Does it work with VT_BYREF? */
    hr = VariantChangeTypeEx(&pVarObj->variant, &pVarObj->variant,
			     lcid, 0, (VARTYPE)type);
    CheckOleError(aTHX_ olestash, hr);
    ST(0) = SUCCEEDED(hr) ? self : &PL_sv_undef;

    XSRETURN(1);
}

void
Copy(self,...)
    SV *self
ALIAS:
    _Clone = 1
PPCODE:
{
    WINOLEVARIANTOBJECT *pVarObj = GetOleVariantObject(aTHX_ self);
    if (!pVarObj)
	XSRETURN_EMPTY;

    HRESULT hr;
    HV *olestash = GetWin32OleStash(aTHX_ self);

    VARIANT *pSource = &pVarObj->variant;
    VARIANT variant, byref;
    VariantInit(&variant);
    VariantInit(&byref);

    /* Copy(DIM) makes a copy of a SAFEARRAY element */
    if (items > 1) {
	if (ix != 0) {
	    warn(MY_VERSION ": Win32::OLE::Variant->_Clone doesn't support "
		 "array elements");
	    XSRETURN_EMPTY;
	}

	if (!V_ISARRAY(&pVarObj->variant)) {
	    warn(MY_VERSION ": Win32::OLE::Variant->Copy(): %d %s specified, "
		 "but variant is not a SAFEARRYA", items-1,
		 items > 2 ? "indices" : "index");
	    XSRETURN_EMPTY;
	}

	SAFEARRAY *psa = V_ISBYREF(pSource) ? *V_ARRAYREF(pSource)
	                                    : V_ARRAY(pSource);
	int cDims = SafeArrayGetDim(psa);
	if (items-1 != cDims) {
	    warn(MY_VERSION ": Win32::OLE::Variant->Copy() indices mismatch: "
		 "specified %d vs. required %d", items-1, cDims);
	    XSRETURN_EMPTY;
	}

	LONG *rgIndices;
	New(0, rgIndices, cDims, LONG);
	for (int iDim=0; iDim < cDims; ++iDim)
            rgIndices[iDim] = (long)SvIV(ST(1+iDim));

	VARTYPE vt_base = V_VT(pSource) & VT_TYPEMASK;
	V_VT(&variant) = vt_base | VT_BYREF;
	V_VT(&byref) = vt_base;
	if (vt_base == VT_VARIANT)
            V_VARIANTREF(&variant) = &byref;
	else
            V_BYREF(&variant) = &V_BYREF(&byref);

	hr = SafeArrayGetElement(psa, rgIndices, V_BYREF(&variant));
	Safefree(rgIndices);
	if (CheckOleError(aTHX_ olestash, hr))
	    XSRETURN_EMPTY;
	pSource = &variant;
    }

    WINOLEVARIANTOBJECT *pNewVar;
    Newz(0, pNewVar, 1, WINOLEVARIANTOBJECT);
    VariantInit(&pNewVar->variant);
    VariantInit(&pNewVar->byref);

    if (ix == 0)
	hr = VariantCopyInd(&pNewVar->variant, pSource);
    else
	hr = MyVariantCopy(&pNewVar->variant, pSource);

    VariantClear(&byref);
    if (FAILED(hr)) {
	Safefree(pNewVar);
	ReportOleError(aTHX_ olestash, hr);
	XSRETURN_EMPTY;
    }

    AddToObjectChain(aTHX_ (OBJECTHEADER*)pNewVar, WINOLEVARIANT_MAGIC);

    HV *stash = GetStash(aTHX_ self);
    SV *sv = newSViv(PTR2IV(pNewVar));
    ST(0) = sv_2mortal(sv_bless(newRV_noinc(sv), stash));
    XSRETURN(1);
}

void
Date(self,...)
    SV *self
ALIAS:
    Time = 1
PPCODE:
{
    WINOLEVARIANTOBJECT *pVarObj = GetOleVariantObject(aTHX_ self);
    if (!pVarObj)
	XSRETURN_EMPTY;

    if (items > 3) {
	char *method[] = {"Date", "Time"};
	warn("Usage: Win32::OLE::Variant::%s"
	      "(SELF [, FORMAT [, LCID]])", method[ix]);
	XSRETURN_EMPTY;
    }

    HV *olestash = GetWin32OleStash(aTHX_ self);
    SetLastOleError(aTHX_ olestash);

    char *fmt = NULL;
    DWORD dwFlags = 0;
    LCID lcid = lcidDefault;

    if (items > 1) {
	if (SvIOK(ST(1)))
	    dwFlags = (DWORD)SvIV(ST(1));
	else if SvPOK(ST(1))
	    fmt = SvPV_nolen(ST(1));
    }
    if (items > 2)
	lcid = (LCID)SvIV(ST(2));
    else
	lcid = (LCID)QueryPkgVar(aTHX_ olestash, LCID_NAME, LCID_LEN, lcidDefault);

    HRESULT hr;
    VARIANT variant;
    VariantInit(&variant);
    hr = VariantChangeTypeEx(&variant, &pVarObj->variant, lcid, 0, VT_DATE);
    if (CheckOleError(aTHX_ olestash, hr))
        XSRETURN_EMPTY;

    SYSTEMTIME systime;
    VariantTimeToSystemTime(V_DATE(&variant), &systime);

    int len;
    if (ix == 0)
        len = GetDateFormatA(lcid, dwFlags, &systime, fmt, NULL, 0);
    else
        len = GetTimeFormatA(lcid, dwFlags, &systime, fmt, NULL, 0);
    if (len > 1) {
        SV *sv = ST(0) = sv_2mortal(newSV(len));
        if (ix == 0)
            len = GetDateFormatA(lcid, dwFlags, &systime, fmt, SvPVX(sv), len);
        else
            len = GetTimeFormatA(lcid, dwFlags, &systime, fmt, SvPVX(sv), len);

        if (len > 1) {
            SvCUR_set(sv, len-1);
            SvPOK_on(sv);
	}
    }
    else
        ST(0) = &PL_sv_undef;

    VariantClear(&variant);
    XSRETURN(1);
}

void
Currency(self,...)
    SV *self
PPCODE:
{
    WINOLEVARIANTOBJECT *pVarObj = GetOleVariantObject(aTHX_ self);
    if (!pVarObj)
	XSRETURN_EMPTY;

    if (items > 3) {
	warn("Usage: Win32::OLE::Variant::Currency"
	      "(SELF [, CURRENCYFMT [, LCID]])");
	XSRETURN_EMPTY;
    }

    HV *olestash = GetWin32OleStash(aTHX_ self);
    SetLastOleError(aTHX_ olestash);

    HV *hv = NULL;
    DWORD dwFlags = 0;
    LCID lcid = lcidDefault;

    if (items > 1) {
	SV *format = ST(1);
	if (SvIOK(format))
	    dwFlags = (DWORD)SvIV(format);
	else if (SvROK(format) && SvTYPE(SvRV(format)) == SVt_PVHV)
	    hv = (HV*)SvRV(format);
	else {
	    croak("Win32::OLE::Variant::GetCurrencyFormat: "
		  "CURRENCYFMT must be a HASH reference");
	    XSRETURN_EMPTY;
	}
    }

    if (items > 2)
	lcid = (LCID)SvIV(ST(2));
    else
	lcid = (LCID)QueryPkgVar(aTHX_ olestash, LCID_NAME, LCID_LEN, lcidDefault);

    HRESULT hr;
    VARIANT variant;
    VariantInit(&variant);
    hr = VariantChangeTypeEx(&variant, &pVarObj->variant, lcid, 0, VT_CY);
    if (CheckOleError(aTHX_ olestash, hr))
	XSRETURN_EMPTY;

    CURRENCYFMTA afmt;
    Zero(&afmt, 1, CURRENCYFMTA);

    afmt.NumDigits        = (UINT)GetLocaleNumber(aTHX_ hv, "NumDigits",
                                                  lcid, LOCALE_IDIGITS);
    afmt.LeadingZero      = (UINT)GetLocaleNumber(aTHX_ hv, "LeadingZero",
                                                  lcid, LOCALE_ILZERO);
    afmt.Grouping         = (UINT)GetLocaleNumber(aTHX_ hv, "Grouping",
                                                  lcid, LOCALE_SMONGROUPING);
    afmt.NegativeOrder    = (UINT)GetLocaleNumber(aTHX_ hv, "NegativeOrder",
                                                  lcid, LOCALE_INEGCURR);
    afmt.PositiveOrder    = (UINT)GetLocaleNumber(aTHX_ hv, "PositiveOrder",
                                                  lcid, LOCALE_ICURRENCY);

    afmt.lpDecimalSep     = GetLocaleString(aTHX_ hv, "DecimalSep",
                                            lcid, LOCALE_SMONDECIMALSEP);
    afmt.lpThousandSep    = GetLocaleString(aTHX_ hv, "ThousandSep",
                                            lcid, LOCALE_SMONTHOUSANDSEP);
    afmt.lpCurrencySymbol = GetLocaleString(aTHX_ hv, "CurrencySymbol",
                                            lcid, LOCALE_SCURRENCY);

    int len = 0;
    int sign = 0;
    char amount[40];
    unsigned __int64 u64 = *(unsigned __int64*)&V_CY(&variant);

    if ((__int64)u64 < 0) {
	amount[len++] = '-';
	u64 = (unsigned __int64)(-(__int64)u64);
	sign = 1;
    }
    while (u64) {
	amount[len++] = (char)(u64%10 + '0');
	u64 /= 10;
    }
    if (len == sign)
	amount[len++] = '0';
    amount[len] = '\0';
    strrev(amount+sign);

    /* VT_CY has an implied decimal point before the last 4 digits */
    SV *number;
    if (len-sign < 5)
	number = newSVpvf("%.*s0.%.*s%s", sign, amount,
			  4-(len-sign), "000", amount+sign);
    else
	number = newSVpvf("%.*s.%s", len-4, amount, amount+len-4);

    DBG(("amount='%s' number='%s' len=%d sign=%d", amount, SvPVX(number),
	 len, sign));

    char* pNumber = SvPVX(number);
    len = GetCurrencyFormatA(lcid, dwFlags, pNumber, &afmt, NULL, 0);
    if (len > 1) {
        SV *sv = ST(0) = sv_2mortal(newSV(len));
        len = GetCurrencyFormatA(lcid, dwFlags, pNumber, &afmt,
                                 SvPVX(sv), len);
        if (len > 1) {
            SvCUR_set(sv, len-1);
            SvPOK_on(sv);
        }
    }
    else
	ST(0) = &PL_sv_undef;

    SvREFCNT_dec(number);
    VariantClear(&variant);
    XSRETURN(1);
}

void
Number(self,...)
    SV *self
PPCODE:
{
    WINOLEVARIANTOBJECT *pVarObj = GetOleVariantObject(aTHX_ self);
    if (!pVarObj)
	XSRETURN_EMPTY;

    if (items > 3) {
	warn("Usage: Win32::OLE::Variant::Number"
	      "(SELF [, NUMBERFMT [, LCID]])");
	XSRETURN_EMPTY;
    }

    HV *olestash = GetWin32OleStash(aTHX_ self);
    SetLastOleError(aTHX_ olestash);

    HV *hv = NULL;
    DWORD dwFlags = 0;
    LCID lcid = lcidDefault;

    if (items > 1) {
	SV *format = ST(1);
	if (SvIOK(format))
	    dwFlags = (DWORD)SvIV(format);
	else if (SvROK(format) && SvTYPE(SvRV(format)) == SVt_PVHV)
	    hv = (HV*)SvRV(format);
	else {
	    croak("Win32::OLE::Variant::GetNumberFormat: "
		  "NUMBERFMT must be a HASH reference");
	    XSRETURN_EMPTY;
	}
    }

    if (items > 2)
	lcid = (LCID)SvIV(ST(2));
    else
	lcid = (LCID)QueryPkgVar(aTHX_ olestash, LCID_NAME, LCID_LEN, lcidDefault);

    HRESULT hr;
    VARIANT variant;
    VariantInit(&variant);
    hr = VariantChangeTypeEx(&variant, &pVarObj->variant, lcid, 0, VT_R8);
    if (CheckOleError(aTHX_ olestash, hr))
	XSRETURN_EMPTY;

    UINT NumDigits;
    NUMBERFMTA afmt;

    Zero(&afmt, 1, NUMBERFMT);

    afmt.NumDigits     = (UINT)GetLocaleNumber(aTHX_ hv, "NumDigits",
                                               lcid, LOCALE_IDIGITS);
    afmt.LeadingZero   = (UINT)GetLocaleNumber(aTHX_ hv, "LeadingZero",
                                               lcid, LOCALE_ILZERO);
    afmt.Grouping      = (UINT)GetLocaleNumber(aTHX_ hv, "Grouping",
                                               lcid, LOCALE_SGROUPING);
    afmt.NegativeOrder = (UINT)GetLocaleNumber(aTHX_ hv, "NegativeOrder",
                                               lcid, LOCALE_INEGNUMBER);

    afmt.lpDecimalSep  = GetLocaleString(aTHX_ hv, "DecimalSep",
                                         lcid, LOCALE_SDECIMAL);
    afmt.lpThousandSep = GetLocaleString(aTHX_ hv, "ThousandSep",
                                         lcid, LOCALE_STHOUSAND);
    NumDigits = afmt.NumDigits;

    int len;
    SV *number = newSVpvf("%.*f", NumDigits, V_R8(&variant));
    char* pNumber = SvPVX(number);
    len = GetNumberFormatA(lcid, dwFlags, pNumber, &afmt, NULL, 0);
    if (len > 1) {
        SV *sv = ST(0) = sv_2mortal(newSV(len));
        len = GetNumberFormatA(lcid, dwFlags, pNumber, &afmt,
                               SvPVX(sv), len);
        if (len > 1) {
            SvCUR_set(sv, len-1);
            SvPOK_on(sv);
        }
    }
    else
	ST(0) = &PL_sv_undef;

    SvREFCNT_dec(number);
    VariantClear(&variant);
    XSRETURN(1);
}

void
Dim(self)
    SV *self
PPCODE:
{
    WINOLEVARIANTOBJECT *pVarObj = GetOleVariantObject(aTHX_ self);
    if (!pVarObj)
	XSRETURN_EMPTY;

    VARIANT *pVariant = &pVarObj->variant;
    while (V_VT(pVariant) == (VT_VARIANT | VT_BYREF))
        pVariant = V_VARIANTREF(pVariant);

    if (!V_ISARRAY(pVariant)) {
	warn(MY_VERSION ": Win32::OLE::Variant->Dim(): Variant type (0x%x) "
	     "is not an array", V_VT(pVariant));
	XSRETURN_EMPTY;
    }

    SAFEARRAY *psa;
    if (V_ISBYREF(pVariant))
	psa = *V_ARRAYREF(pVariant);
    else
	psa = V_ARRAY(pVariant);

    HRESULT hr = S_OK;
    int cDims = SafeArrayGetDim(psa);
    for (int iDim=0; iDim < cDims; ++iDim) {
	LONG lLBound, lUBound;
	hr = SafeArrayGetLBound(psa, 1+iDim, &lLBound);
	if (FAILED(hr))
	    break;
	hr = SafeArrayGetUBound(psa, 1+iDim, &lUBound);
	if (FAILED(hr))
	    break;
	AV *av = newAV();
	av_push(av, newSViv(lLBound));
	av_push(av, newSViv(lUBound));
	XPUSHs(sv_2mortal(newRV_noinc((SV*)av)));
    }

    HV *olestash = GetWin32OleStash(aTHX_ self);
    if (CheckOleError(aTHX_ olestash, hr))
	XSRETURN_EMPTY;

    /* return list of array refs on stack */
}

void
Get(self,...)
    SV *self
ALIAS:
    Put = 1
PPCODE:
{
    char *paszMethod[] = {"Get", "Put"};
    WINOLEVARIANTOBJECT *pVarObj = GetOleVariantObject(aTHX_ self);
    if (!pVarObj)
	XSRETURN_EMPTY;

    HV *olestash = GetWin32OleStash(aTHX_ self);
    VARIANT *pVariant = &pVarObj->variant;

    while (V_VT(pVariant) == (VT_VARIANT | VT_BYREF))
        pVariant = V_VARIANTREF(pVariant);

    if (!V_ISARRAY(pVariant)) {
	if (items-1 != ix) {
	    warn(MY_VERSION ": Win32::OLE::Variant->%s(): Wrong number of "
		 "arguments" , paszMethod[ix]);
	    XSRETURN_EMPTY;
	}
    scalar_mode:
	HRESULT hr;
        SV *sv;
	if (ix == 0) { /* Get */
	    sv = sv_newmortal();
	    hr = SetSVFromVariantEx(aTHX_ pVariant, sv, olestash);
	}
	else { /* Put */
	    UINT cp = (UINT)QueryPkgVar(aTHX_ olestash, CP_NAME, CP_LEN, cpDefault);
	    LCID lcid = (LCID)QueryPkgVar(aTHX_ olestash, LCID_NAME, LCID_LEN,
                                          lcidDefault);
	    sv = self;
	    hr = AssignVariantFromSV(aTHX_ ST(1), pVariant, cp, lcid);
	}
	CheckOleError(aTHX_ olestash, hr);
        ST(0) = sv;
	XSRETURN(1);
    }

    SAFEARRAY *psa = V_ISBYREF(pVariant) ? *V_ARRAYREF(pVariant)
	                                  : V_ARRAY(pVariant);
    int cDims = SafeArrayGetDim(psa);

    /* Special case for one-dimensional VT_UI1 arrays */
    VARTYPE vt_base = V_VT(pVariant) & VT_TYPEMASK;
    if (vt_base == VT_UI1 && cDims == 1 && items-1 == ix)
        goto scalar_mode;

    /* Array Put, e.g. $array->Put([ [11,12], [21,22] ]) */
    if (ix == 1 && items == 2 && SvROK(ST(1)) &&
	SvTYPE(SvRV(ST(1))) == SVt_PVAV)
    {
	UINT cp = (UINT)QueryPkgVar(aTHX_ olestash, CP_NAME, CP_LEN, cpDefault);
	LCID lcid = (LCID)QueryPkgVar(aTHX_ olestash, LCID_NAME, LCID_LEN,
                                      lcidDefault);
	HRESULT hr = SetSafeArrayFromAV(aTHX_ (AV*)SvRV(ST(1)), vt_base, psa,
					cDims, cp, lcid);
	CheckOleError(aTHX_ olestash, hr);
	ST(0) = self;
	XSRETURN(1);
    }

    if (items-1 != cDims+ix) {
	warn(MY_VERSION ": Win32::OLE::Variant->%s(): Wrong number of indices; "
	     " dimension of SafeArray is %d", paszMethod[ix], cDims);
	XSRETURN_EMPTY;
    }

    LONG *rgIndices;
    New(0, rgIndices, cDims, LONG);
    for (int iDim=0; iDim < cDims; ++iDim)
        rgIndices[iDim] = (long)SvIV(ST(1+iDim));

    VARIANT variant, byref;
    VariantInit(&variant);
    VariantInit(&byref);
    V_VT(&variant) = vt_base | VT_BYREF;
    V_VT(&byref) = vt_base;
    if (vt_base == VT_VARIANT)
        V_VARIANTREF(&variant) = &byref;
    else {
        V_BYREF(&variant) = &V_BYREF(&byref);
	if (vt_base == VT_BSTR)
	    V_BSTR(&byref) = NULL;
	else if (vt_base == VT_DISPATCH)
	    V_DISPATCH(&byref) = NULL;
	else if (vt_base == VT_UNKNOWN)
	    V_UNKNOWN(&byref) = NULL;
    }

    HRESULT hr = S_OK;
    SV *sv = &PL_sv_undef;
    if (ix == 0) { /* Get */
	hr = SafeArrayGetElement(psa, rgIndices, V_BYREF(&variant));
	if (SUCCEEDED(hr)) {
	    sv = sv_newmortal();
	    hr = SetSVFromVariantEx(aTHX_ &variant, sv, olestash);
	}
    }
    else { /* Put */
	UINT cp = (UINT)QueryPkgVar(aTHX_ olestash, CP_NAME, CP_LEN, cpDefault);
	LCID lcid = (LCID)QueryPkgVar(aTHX_ olestash, LCID_NAME, LCID_LEN,
                                      lcidDefault);
	hr = AssignVariantFromSV(aTHX_ ST(items-1), &variant, cp, lcid);
	if (SUCCEEDED(hr)) {
	    if (vt_base == VT_BSTR)
		hr = SafeArrayPutElement(psa, rgIndices, V_BSTR(&byref));
	    else if (vt_base == VT_DISPATCH)
		hr = SafeArrayPutElement(psa, rgIndices, V_DISPATCH(&byref));
	    else if (vt_base == VT_UNKNOWN)
		hr = SafeArrayPutElement(psa, rgIndices, V_UNKNOWN(&byref));
	    else
		hr = SafeArrayPutElement(psa, rgIndices, V_BYREF(&variant));
	}
	if (SUCCEEDED(hr))
	    sv = self;
    }
    VariantClear(&byref);
    Safefree(rgIndices);
    CheckOleError(aTHX_ olestash, hr);
    ST(0) = sv;
    XSRETURN(1);
}

void
LastError(self,...)
    SV *self
PPCODE:
{
    // Win32::OLE::Variant->LastError() exists only for backward compatibility.
    // It is now just a proxy for Win32::OLE->LastError().

    HV *olestash = GetWin32OleStash(aTHX_ self);
    SV *sv = items == 1 ? NULL : ST(1);

    PUSHMARK(sp);
    PUSHs(sv_2mortal(newSVpv(HvNAME(olestash), 0)));
    if (sv)
	PUSHs(sv);
    PUTBACK;
    perl_call_method("LastError", GIMME_V);
    SPAGAIN;

    // return whatever Win32::OLE->LastError() returned
}

void
Type(self)
    SV *self
ALIAS:
    Value = 1
    _Value = 2
    _RefType = 3
    IsNullString = 4
    IsNothing = 5
PPCODE:
{
    WINOLEVARIANTOBJECT *pVarObj = GetOleVariantObject(aTHX_ self);

    SV *sv = &PL_sv_undef;
    if (pVarObj) {
        VARIANT *pVariant = &pVarObj->variant;
	HRESULT hr;
	HV *olestash = GetWin32OleStash(aTHX_ self);
	SetLastOleError(aTHX_ olestash);
	sv = sv_newmortal();
	if (ix == 0) /* Type */
	    sv_setiv(sv, V_VT(pVariant));
	else if (ix == 1) /* Value */
	    hr = SetSVFromVariantEx(aTHX_ pVariant, sv, olestash);
	else if (ix == 2) /* _Value, see also: _Clone (alias of Copy) */
	    hr = SetSVFromVariantEx(aTHX_ pVariant, sv, olestash,
				    TRUE);
	else if (ix == 3)  { /* _RefType */
	    while (V_VT(pVariant) == (VT_BYREF|VT_VARIANT))
		pVariant = V_VARIANTREF(pVariant);
	    sv_setiv(sv, V_VT(pVariant));
	}
	else if (ix == 4)  { /* IsNullString */
            if (V_VT(pVariant) == VT_BSTR && V_BSTR(pVariant) == NULL)
                sv = &PL_sv_yes;
            else
                sv = &PL_sv_no;
        }
	else if (ix == 5)  { /* IsNothing */
            if (V_VT(pVariant) == VT_DISPATCH && V_DISPATCH(pVariant) == NULL)
                sv = &PL_sv_yes;
            else
                sv = &PL_sv_no;
        }
	CheckOleError(aTHX_ olestash, hr);
    }
    ST(0) = sv;
    XSRETURN(1);
}

void
Unicode(self)
    SV *self
PPCODE:
{
    WINOLEVARIANTOBJECT *pVarObj = GetOleVariantObject(aTHX_ self);

    ST(0) = &PL_sv_undef;
    if (pVarObj) {
	VARIANT Variant;
	VARIANT *pVariant = &pVarObj->variant;
	HRESULT hr = S_OK;

	HV *olestash = GetWin32OleStash(aTHX_ self);
	SetLastOleError(aTHX_ olestash);
	VariantInit(&Variant);
	if ((V_VT(pVariant) & ~VT_BYREF) != VT_BSTR) {
	    LCID lcid = (LCID)QueryPkgVar(aTHX_ olestash,
                                          LCID_NAME, LCID_LEN, lcidDefault);

	    hr = VariantChangeTypeEx(&Variant, pVariant, lcid, 0, VT_BSTR);
	    pVariant = &Variant;
	}

	if (!CheckOleError(aTHX_ olestash, hr)) {
	    BSTR bstr = V_ISBYREF(pVariant) ? *V_BSTRREF(pVariant)
		                            : V_BSTR(pVariant);
	    STRLEN olecharlen = SysStringLen(bstr);
	    SV *sv = newSVpv((char*)bstr, 2*olecharlen);
	    U16 *pus = (U16*)SvPVX(sv);
	    for (STRLEN i=0; i < olecharlen; ++i)
		pus[i] = htons(pus[i]);

	    ST(0) = sv_2mortal(sv_bless(newRV_noinc(sv),
					gv_stashpv(szUNICODESTRING, TRUE)));
	}
	VariantClear(&Variant);
    }
    XSRETURN(1);
}

##############################################################################

MODULE = Win32::OLE		PACKAGE = Win32::OLE::NLS

void
CompareString(lcid,flags,str1,str2)
    IV lcid
    IV flags
    SV *str1
    SV *str2
PPCODE:
{
    STRLEN length1;
    STRLEN length2;
    char *string1 = SvPV(str1, length1);
    char *string2 = SvPV(str2, length2);

    IV res = CompareStringA((LCID)lcid, (DWORD)flags,
                            string1, (int)length1, string2, (int)length2);
    XSRETURN_IV(res);
}

void
LCMapString(lcid,flags,str)
    IV lcid
    IV flags
    SV *str
PPCODE:
{
    SV *sv;
    STRLEN length;
    char *string = SvPV(str, length);
    int len = LCMapStringA((LCID)lcid, (DWORD)flags, string, (int)length, NULL, 0);
    if (len > 0) {
        sv = sv_newmortal();
        SvUPGRADE(sv, SVt_PV);
        SvGROW(sv, (STRLEN)(len+1));
        SvCUR_set(sv, LCMapStringA((LCID)lcid, (DWORD)flags, string, (int)length,
                                   SvPVX(sv), (int)SvLEN(sv)));
        if (SvCUR(sv))
            SvPOK_on(sv);
    }
    else
	sv = sv_newmortal();

    ST(0) = sv;
    XSRETURN(1);
}

void
GetLocaleInfo(lcid,lctype)
    IV lcid
    IV lctype
PPCODE:
{
    SV *sv = sv_newmortal();
    int len = GetLocaleInfoA((LCID)lcid, (LCTYPE)lctype, NULL, 0);
    if (len > 0) {
        SvUPGRADE(sv, SVt_PV);
        SvGROW(sv, (STRLEN)len);
        len = GetLocaleInfoA((LCID)lcid, (LCTYPE)lctype, SvPVX(sv), (int)SvLEN(sv));
        if (len) {
            SvCUR_set(sv, len-1);
            SvPOK_on(sv);
        }
    }
    ST(0) = sv;
    XSRETURN(1);
}

void
GetStringType(lcid,type,str)
    IV lcid
    IV type
    SV *str
PPCODE:
{
    STRLEN len;
    char *string = SvPV(str, len);
    unsigned short *pCharType;

    New(0, pCharType, len, unsigned short);
    if (GetStringTypeA((LCID)lcid, (DWORD)type, string, (int)len, pCharType)) {
	EXTEND(SP, (IV)len);
	for (int i=0; i < (IV)len; ++i)
	    PUSHs(sv_2mortal(newSViv(pCharType[i])));
    }
    Safefree(pCharType);
}

void
GetSystemDefaultLangID()
PPCODE:
{
    LANGID langID = GetSystemDefaultLangID();
    if (langID != 0) {
	EXTEND(SP, 1);
	XSRETURN_IV(langID);
    }
}

void
GetSystemDefaultLCID()
PPCODE:
{
    LCID lcid = GetSystemDefaultLCID();
    if (lcid != 0) {
	EXTEND(SP, 1);
	XSRETURN_IV(lcid);
    }
}

void
GetUserDefaultLangID()
PPCODE:
{
    LANGID langID = GetUserDefaultLangID();
    if (langID != 0) {
	EXTEND(SP, 1);
	XSRETURN_IV(langID);
    }
}

void
GetUserDefaultLCID()
PPCODE:
{
    LCID lcid = GetUserDefaultLCID();
    if (lcid != 0) {
	EXTEND(SP, 1);
	XSRETURN_IV(lcid);
    }
}

void
SendSettingChange()
PPCODE:
{
    DWORD_PTR dwResult;

    SendMessageTimeout(HWND_BROADCAST, WM_SETTINGCHANGE, 0, 0,
		       SMTO_NORMAL, 5000, &dwResult);
    XSRETURN_EMPTY;
}

void
SetLocaleInfo(lcid,lctype,lcdata)
    IV lcid
    IV lctype
    char *lcdata
PPCODE:
{
    BOOL result = SetLocaleInfoA((LCID)lcid, (LCTYPE)lctype, lcdata);
    if (result)
	XSRETURN_YES;

    XSRETURN_EMPTY;
}


##############################################################################

MODULE = Win32::OLE		PACKAGE = Win32::OLE::TypeLib

void
new(self,object)
    SV *self
    SV *object
PPCODE:
{
    HRESULT hr;
    HV *stash = Nullhv;
    ITypeLib *pTypeLib;
    TLIBATTR *pTLibAttr;

    if (sv_isobject(object) && sv_derived_from(object, szWINOLE)) {
	WINOLEOBJECT *pOleObj = GetOleObject(aTHX_ object);
	if (!pOleObj)
	    XSRETURN_EMPTY;

	unsigned int count;
	hr = pOleObj->pDispatch->GetTypeInfoCount(&count);
	stash = SvSTASH(pOleObj->self);
	if (CheckOleError(aTHX_ stash, hr) || count == 0)
	    XSRETURN_EMPTY;

	ITypeInfo *pTypeInfo;
	hr = pOleObj->pDispatch->GetTypeInfo(0, lcidDefault, &pTypeInfo);
	if (CheckOleError(aTHX_ stash, hr))
	    XSRETURN_EMPTY;

	unsigned int index;
	hr = pTypeInfo->GetContainingTypeLib(&pTypeLib, &index);
	pTypeInfo->Release();
	if (CheckOleError(aTHX_ stash, hr))
	    XSRETURN_EMPTY;
    }
    else {
	stash = GetWin32OleStash(aTHX_ self);
	UINT cp = (UINT)QueryPkgVar(aTHX_ stash, CP_NAME, CP_LEN, cpDefault);

	OLECHAR Buffer[OLE_BUF_SIZ];
	OLECHAR *pBuffer = GetWideChar(aTHX_ object, Buffer, OLE_BUF_SIZ, cp);
	hr = LoadTypeLibEx(pBuffer, REGKIND_NONE, &pTypeLib);
	ReleaseBuffer(aTHX_ pBuffer, Buffer);
	if (CheckOleError(aTHX_ stash, hr))
	    XSRETURN_EMPTY;
    }

    hr = pTypeLib->GetLibAttr(&pTLibAttr);
    if (FAILED(hr)) {
	pTypeLib->Release();
	ReportOleError(aTHX_ stash, hr);
	XSRETURN_EMPTY;
    }

    ST(0) = sv_2mortal(CreateTypeLibObject(aTHX_ pTypeLib, pTLibAttr));
    XSRETURN(1);
}

void
DESTROY(self)
    SV *self
PPCODE:
{
    WINOLETYPELIBOBJECT *pObj = GetOleTypeLibObject(aTHX_ self);
    if (pObj) {
	RemoveFromObjectChain(aTHX_ (OBJECTHEADER*)pObj);
	if (pObj->pTypeLib) {
	    pObj->pTypeLib->ReleaseTLibAttr(pObj->pTLibAttr);
	    pObj->pTypeLib->Release();
	}
	Safefree(pObj);
    }
    XSRETURN_EMPTY;
}

void
_GetDocumentation(self,index=-1)
    SV *self
    IV index
PPCODE:
{
    WINOLETYPELIBOBJECT *pObj = GetOleTypeLibObject(aTHX_ self);
    if (!pObj)
	XSRETURN_EMPTY;

    DWORD dwHelpContext;
    BSTR bstrName, bstrDocString, bstrHelpFile;
    HRESULT hr = pObj->pTypeLib->GetDocumentation((INT)index, &bstrName,
			  &bstrDocString, &dwHelpContext, &bstrHelpFile);
    HV *olestash = GetWin32OleStash(aTHX_ self);
    if (CheckOleError(aTHX_ olestash, hr))
	XSRETURN_EMPTY;

    HV *hv = GetDocumentation(aTHX_ bstrName, bstrDocString,
			      dwHelpContext, bstrHelpFile);
    ST(0) = sv_2mortal(newRV_noinc((SV*)hv));
    XSRETURN(1);
}

void
_GetLibAttr(self)
    SV *self
PPCODE:
{
    WINOLETYPELIBOBJECT *pObj = GetOleTypeLibObject(aTHX_ self);
    if (!pObj)
	XSRETURN_EMPTY;

    TLIBATTR *p = pObj->pTLibAttr;
    HV *hv = newHV();

    hv_store(hv, "lcid",          4, newSViv(p->lcid), 0);
    hv_store(hv, "syskind",       7, newSViv(p->syskind), 0);
    hv_store(hv, "wLibFlags",     9, newSViv(p->wLibFlags), 0);
    hv_store(hv, "wMajorVerNum", 12, newSViv(p->wMajorVerNum), 0);
    hv_store(hv, "wMinorVerNum", 12, newSViv(p->wMinorVerNum), 0);
    hv_store(hv, "guid",          4, SetSVFromGUID(aTHX_ p->guid), 0);

    ST(0) = sv_2mortal(newRV_noinc((SV*)hv));
    XSRETURN(1);
}

void
_GetTypeInfoCount(self)
    SV *self
PPCODE:
{
    WINOLETYPELIBOBJECT *pObj = GetOleTypeLibObject(aTHX_ self);
    if (!pObj)
	XSRETURN_EMPTY;

    XSRETURN_IV(pObj->pTypeLib->GetTypeInfoCount());
}

void
_GetTypeInfo(self,index)
    SV *self
    IV index
PPCODE:
{
    WINOLETYPELIBOBJECT *pObj = GetOleTypeLibObject(aTHX_ self);
    if (!pObj)
	XSRETURN_EMPTY;

    ITypeInfo *pTypeInfo;
    TYPEATTR  *pTypeAttr;

    HV *olestash = GetWin32OleStash(aTHX_ self);
    HRESULT hr = pObj->pTypeLib->GetTypeInfo((UINT)index, &pTypeInfo);
    if (CheckOleError(aTHX_ olestash, hr))
	XSRETURN_EMPTY;

    hr = pTypeInfo->GetTypeAttr(&pTypeAttr);
    if (FAILED(hr)) {
	pTypeInfo->Release();
	ReportOleError(aTHX_ olestash, hr);
	XSRETURN_EMPTY;
    }

    ST(0) = sv_2mortal(CreateTypeInfoObject(aTHX_ pTypeInfo, pTypeAttr));
    XSRETURN(1);
}

void
GetTypeInfo(self,name,...)
    SV *self
    SV *name
PPCODE:
{
    WINOLETYPELIBOBJECT *pObj = GetOleTypeLibObject(aTHX_ self);
    if (!pObj)
	XSRETURN_EMPTY;

    ITypeInfo *pTypeInfo;
    TYPEATTR  *pTypeAttr;

    HV *olestash = GetWin32OleStash(aTHX_ self);

    if (SvIOK(name)) {
	HRESULT hr = pObj->pTypeLib->GetTypeInfo((UINT)SvIV(name), &pTypeInfo);
	if (CheckOleError(aTHX_ olestash, hr))
	    XSRETURN_EMPTY;

	hr = pTypeInfo->GetTypeAttr(&pTypeAttr);
	if (FAILED(hr)) {
	    pTypeInfo->Release();
	    ReportOleError(aTHX_ olestash, hr);
	    XSRETURN_EMPTY;
	}

	ST(0) = sv_2mortal(CreateTypeInfoObject(aTHX_ pTypeInfo, pTypeAttr));
	XSRETURN(1);
    }

    UINT cp = (UINT)QueryPkgVar(aTHX_ olestash, CP_NAME, CP_LEN, cpDefault);
    TYPEKIND tkind = items > 2 ? (TYPEKIND)SvIV(ST(2)) : TKIND_MAX;
    char *pszName = SvPV_nolen(name);
    int count = pObj->pTypeLib->GetTypeInfoCount();
    for (int index = 0; index < count; ++index) {
	HRESULT hr = pObj->pTypeLib->GetTypeInfo(index, &pTypeInfo);
	if (CheckOleError(aTHX_ olestash, hr))
	    XSRETURN_EMPTY;

	BSTR bstrName;
	hr = pTypeInfo->GetDocumentation(-1, &bstrName, NULL, NULL, NULL);
	char szStr[OLE_BUF_SIZ];
	char *pszStr = GetMultiByte(aTHX_ bstrName, szStr, sizeof(szStr), cp);
	int equal = strEQ(pszStr, pszName);
	ReleaseBuffer(aTHX_ pszStr, szStr);
	SysFreeString(bstrName);
	if (!equal) {
	    pTypeInfo->Release();
	    continue;
	}

	hr = pTypeInfo->GetTypeAttr(&pTypeAttr);
	if (FAILED(hr)) {
	    pTypeInfo->Release();
	    ReportOleError(aTHX_ olestash, hr);
	    XSRETURN_EMPTY;
	}

	if (tkind == TKIND_MAX || tkind == pTypeAttr->typekind) {
	    ST(0) = sv_2mortal(CreateTypeInfoObject(aTHX_ pTypeInfo, pTypeAttr));
	    XSRETURN(1);
	}

	pTypeInfo->ReleaseTypeAttr(pTypeAttr);
	pTypeInfo->Release();
    }
    XSRETURN_EMPTY;
}

##############################################################################

MODULE = Win32::OLE		PACKAGE = Win32::OLE::TypeInfo

void
_new(self,object)
    SV *self
    SV *object
PPCODE:
{
    ITypeInfo *pTypeInfo;
    TYPEATTR  *pTypeAttr;

    WINOLEOBJECT *pOleObj = GetOleObject(aTHX_ object);
    if (!pOleObj)
        XSRETURN_EMPTY;

    unsigned int count;
    HRESULT hr = pOleObj->pDispatch->GetTypeInfoCount(&count);
    HV *olestash = SvSTASH(pOleObj->self);
    if (CheckOleError(aTHX_ olestash, hr) || count == 0)
        XSRETURN_EMPTY;

    hr = pOleObj->pDispatch->GetTypeInfo(0, lcidDefault, &pTypeInfo);
    if (CheckOleError(aTHX_ olestash, hr))
        XSRETURN_EMPTY;

    hr = pTypeInfo->GetTypeAttr(&pTypeAttr);
    if (FAILED(hr)) {
	pTypeInfo->Release();
	ReportOleError(aTHX_ olestash, hr);
	XSRETURN_EMPTY;
    }

    ST(0) = sv_2mortal(CreateTypeInfoObject(aTHX_ pTypeInfo, pTypeAttr));
    XSRETURN(1);
}

void
DESTROY(self)
    SV *self
PPCODE:
{
    WINOLETYPEINFOOBJECT *pObj = GetOleTypeInfoObject(aTHX_ self);
    if (pObj) {
	RemoveFromObjectChain(aTHX_ (OBJECTHEADER*)pObj);
	if (pObj->pTypeInfo) {
	    pObj->pTypeInfo->ReleaseTypeAttr(pObj->pTypeAttr);
	    pObj->pTypeInfo->Release();
	}
	Safefree(pObj);
    }
    XSRETURN_EMPTY;
}

void
GetContainingTypeLib(self)
    SV *self
PPCODE:
{
    ITypeLib  *pTypeLib;
    TLIBATTR  *pTLibAttr;

    WINOLETYPEINFOOBJECT *pObj = GetOleTypeInfoObject(aTHX_ self);
    if (!pObj)
	XSRETURN_EMPTY;

    unsigned int index;
    HV *olestash = GetWin32OleStash(aTHX_ self);
    HRESULT hr = pObj->pTypeInfo->GetContainingTypeLib(&pTypeLib, &index);
    if (CheckOleError(aTHX_ olestash, hr))
        XSRETURN_EMPTY;

    hr = pTypeLib->GetLibAttr(&pTLibAttr);
    if (FAILED(hr)) {
	pTypeLib->Release();
	ReportOleError(aTHX_ olestash, hr);
	XSRETURN_EMPTY;
    }

    ST(0) = sv_2mortal(CreateTypeLibObject(aTHX_ pTypeLib, pTLibAttr));
    XSRETURN(1);
}

void
_GetDocumentation(self,memid=-1)
    SV *self
    IV memid
PPCODE:
{
    WINOLETYPEINFOOBJECT *pObj = GetOleTypeInfoObject(aTHX_ self);
    if (!pObj)
	XSRETURN_EMPTY;

    DWORD dwHelpContext;
    BSTR bstrName, bstrDocString, bstrHelpFile;
    HV *olestash = GetWin32OleStash(aTHX_ self);
    HRESULT hr = pObj->pTypeInfo->GetDocumentation((MEMBERID)memid, &bstrName,
			   &bstrDocString, &dwHelpContext, &bstrHelpFile);
    if (CheckOleError(aTHX_ olestash, hr))
	XSRETURN_EMPTY;

    HV *hv = GetDocumentation(aTHX_ bstrName, bstrDocString,
			      dwHelpContext, bstrHelpFile);
    ST(0) = sv_2mortal(newRV_noinc((SV*)hv));
    XSRETURN(1);
}

void
_GetFuncDesc(self,index)
    SV *self
    IV index
PPCODE:
{
    WINOLETYPEINFOOBJECT *pObj = GetOleTypeInfoObject(aTHX_ self);
    if (!pObj)
	XSRETURN_EMPTY;

    FUNCDESC *p;
    HV *olestash = GetWin32OleStash(aTHX_ self);
    HRESULT hr = pObj->pTypeInfo->GetFuncDesc((UINT)index, &p);
    if (CheckOleError(aTHX_ olestash, hr))
	XSRETURN_EMPTY;

    HV *hv = newHV();
    hv_store(hv, "memid",         5, newSViv(p->memid), 0);
    // /* [size_is] */ SCODE __RPC_FAR *lprgscode;
    hv_store(hv, "funckind",      8, newSViv(p->funckind), 0);
    hv_store(hv, "invkind",       7, newSViv(p->invkind), 0);
    hv_store(hv, "callconv",      8, newSViv(p->callconv), 0);
    hv_store(hv, "cParams",       7, newSViv(p->cParams), 0);
    hv_store(hv, "cParamsOpt",   10, newSViv(p->cParamsOpt), 0);
    hv_store(hv, "oVft",          4, newSViv(p->oVft), 0);
    hv_store(hv, "cScodes",       7, newSViv(p->cScodes), 0);
    hv_store(hv, "wFuncFlags",   10, newSViv(p->wFuncFlags), 0);

    HV *elemdesc = TranslateElemDesc(aTHX_ &p->elemdescFunc, pObj, olestash);
    hv_store(hv, "elemdescFunc", 12, newRV_noinc((SV*)elemdesc), 0);

    if (p->cParams > 0) {
	AV *av = newAV();

	for (int i = 0; i < p->cParams; ++i) {
	    elemdesc = TranslateElemDesc(aTHX_ &p->lprgelemdescParam[i],
					 pObj, olestash);
	    av_push(av, newRV_noinc((SV*)elemdesc));
	}
	hv_store(hv, "rgelemdescParam", 15, newRV_noinc((SV*)av), 0);
    }

    pObj->pTypeInfo->ReleaseFuncDesc(p);
    ST(0) = sv_2mortal(newRV_noinc((SV*)hv));
    XSRETURN(1);
}

void
_GetImplTypeFlags(self,index)
    SV *self
    IV index
PPCODE:
{
    WINOLETYPEINFOOBJECT *pObj = GetOleTypeInfoObject(aTHX_ self);
    if (!pObj)
	XSRETURN_EMPTY;

    int flags;
    HV *olestash = GetWin32OleStash(aTHX_ self);
    HRESULT hr = pObj->pTypeInfo->GetImplTypeFlags((UINT)index, &flags);
    if (CheckOleError(aTHX_ olestash, hr))
	XSRETURN_EMPTY;

    XSRETURN_IV(flags);
}

void
_GetImplTypeInfo(self,index)
    SV *self
    IV index
PPCODE:
{
    HREFTYPE  hRefType;
    ITypeInfo *pTypeInfo;
    TYPEATTR  *pTypeAttr;

    WINOLETYPEINFOOBJECT *pObj = GetOleTypeInfoObject(aTHX_ self);
    if (!pObj)
	XSRETURN_EMPTY;

    HV *olestash = GetWin32OleStash(aTHX_ self);
    HRESULT hr = pObj->pTypeInfo->GetRefTypeOfImplType((UINT)index, &hRefType);
    if (CheckOleError(aTHX_ olestash, hr))
	XSRETURN_EMPTY;

    hr = pObj->pTypeInfo->GetRefTypeInfo(hRefType, &pTypeInfo);
    if (CheckOleError(aTHX_ olestash, hr))
	XSRETURN_EMPTY;

    hr = pTypeInfo->GetTypeAttr(&pTypeAttr);
    if (FAILED(hr)) {
	pTypeInfo->Release();
	ReportOleError(aTHX_ olestash, hr);
	XSRETURN_EMPTY;
    }

    New(0, pObj, 1, WINOLETYPEINFOOBJECT);
    pObj->pTypeInfo = pTypeInfo;
    pObj->pTypeAttr = pTypeAttr;

    AddToObjectChain(aTHX_ (OBJECTHEADER*)pObj, WINOLETYPEINFO_MAGIC);

    SV *sv = newSViv(PTR2IV(pObj));
    ST(0) = sv_2mortal(sv_bless(newRV_noinc(sv), GetStash(aTHX_ self)));
    XSRETURN(1);
}

void
_GetNames(self,memid,count)
    SV *self
    IV memid
    IV count
PPCODE:
{
    WINOLETYPEINFOOBJECT *pObj = GetOleTypeInfoObject(aTHX_ self);
    if (!pObj)
	XSRETURN_EMPTY;

    BSTR *rgbstr;
    New(0, rgbstr, count, BSTR);
    unsigned int cNames;
    HV *olestash = GetWin32OleStash(aTHX_ self);
    HRESULT hr = pObj->pTypeInfo->GetNames((MEMBERID)memid, rgbstr, (UINT)count, &cNames);
    if (CheckOleError(aTHX_ olestash, hr))
	XSRETURN_EMPTY;

    AV *av = newAV();
    for (int i = 0; i < (int)cNames; ++i) {
	char szName[32];
	// XXX use correct codepage ???
	char *pszName = GetMultiByte(aTHX_ rgbstr[i],
				     szName, sizeof(szName), CP_ACP);
	SysFreeString(rgbstr[i]);
	av_push(av, newSVpv(pszName, 0));
	ReleaseBuffer(aTHX_ pszName, szName);
    }
    Safefree(rgbstr);

    ST(0) = sv_2mortal(newRV_noinc((SV*)av));
    XSRETURN(1);
}

void
_GetTypeAttr(self)
    SV *self
PPCODE:
{
    WINOLETYPEINFOOBJECT *pObj = GetOleTypeInfoObject(aTHX_ self);
    if (!pObj)
	XSRETURN_EMPTY;

    TYPEATTR *p = pObj->pTypeAttr;
    HV *hv = newHV();

    hv_store(hv, "guid",              4, SetSVFromGUID(aTHX_ p->guid), 0);
    hv_store(hv, "lcid",              4, newSViv(p->lcid), 0);
    hv_store(hv, "memidConstructor", 16, newSViv(p->memidConstructor), 0);
    hv_store(hv, "memidDestructor",  15, newSViv(p->memidDestructor), 0);
    hv_store(hv, "typekind",          8, newSViv(p->typekind), 0);
    hv_store(hv, "cFuncs",            6, newSViv(p->cFuncs), 0);
    hv_store(hv, "cVars",             5, newSViv(p->cVars), 0);
    hv_store(hv, "cImplTypes",       10, newSViv(p->cImplTypes), 0);
    hv_store(hv, "cbSizeVft",         9, newSViv(p->cbSizeVft), 0);
    hv_store(hv, "wTypeFlags",       10, newSViv(p->wTypeFlags), 0);
    hv_store(hv, "wMajorVerNum",     12, newSViv(p->wMajorVerNum), 0);
    hv_store(hv, "wMinorVerNum",     12, newSViv(p->wMinorVerNum), 0);
    //TYPEDESC tdescAlias;	  // If TypeKind == TKIND_ALIAS,
    //                            // specifies the type for which
    //                            // this type is an alias.
    //IDLDESC idldescType;	  // IDL attributes of the
    //                            // described type.


    ST(0) = sv_2mortal(newRV_noinc((SV*)hv));
    XSRETURN(1);
}

void
_GetVarDesc(self,index)
    SV *self
    IV index
PPCODE:
{
    WINOLETYPEINFOOBJECT *pObj = GetOleTypeInfoObject(aTHX_ self);
    if (!pObj)
	XSRETURN_EMPTY;

    VARDESC *p;
    HV *olestash = GetWin32OleStash(aTHX_ self);
    HRESULT hr = pObj->pTypeInfo->GetVarDesc((UINT)index, &p);
    if (CheckOleError(aTHX_ olestash, hr))
	XSRETURN_EMPTY;

    HV *hv = newHV();
    hv_store(hv, "memid",        5, newSViv(p->memid), 0);
    // LPOLESTR lpstrSchema;
    hv_store(hv, "wVarFlags",    9, newSViv(p->wVarFlags), 0);
    hv_store(hv, "varkind",      7, newSViv(p->varkind), 0);

    HV *elemdesc = TranslateElemDesc(aTHX_ &p->elemdescVar,
				     pObj, olestash);
    hv_store(hv, "elemdescVar", 11, newRV_noinc((SV*)elemdesc), 0);

    if (p->varkind == VAR_PERINSTANCE)
	hv_store(hv, "oInst",    5, newSViv(p->oInst), 0);

    if (p->varkind == VAR_CONST) {
	// XXX should be stored as a Win32::OLE::Variant object ?
	SV *sv = newSV(0);
	SetSVFromVariantEx(aTHX_ p->lpvarValue, sv, olestash);
	hv_store(hv, "varValue", 8, sv, 0);
    }

    pObj->pTypeInfo->ReleaseVarDesc(p);
    ST(0) = sv_2mortal(newRV_noinc((SV*)hv));
    XSRETURN(1);
}
