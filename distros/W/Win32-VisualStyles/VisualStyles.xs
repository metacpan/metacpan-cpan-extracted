#define WIN32_MEAN_AND_LEAN
#define STRICT
#define WINVER 0x0400       /* NOT 0x0501 for VC6 compatibility */
#define _WIN32_WINNT 0x0400 /* NOT 0x0501 for VC6 compatibility */

#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "ppport.h"

#include <Windows.h>
#include <shlwapi.h>

/* ------------------ Compatibility ------------------- */
/* Stuff that we use that would usually be included by
 * setting WINVER and _WIN32_WINNT to 0x0501
 */

#if defined(_WIN64)
 typedef unsigned __int64 ULONG_PTR;
#else
 typedef unsigned long ULONG_PTR;
#endif

#ifndef WM_THEMECHANGED
#define WM_THEMECHANGED 0x031A
#endif

#if !defined(RC_INVOKED) /* RC complains about long symbols in #ifs */
#if !defined(ACTIVATION_CONTEXT_BASIC_INFORMATION_DEFINED)

typedef struct _ACTIVATION_CONTEXT_BASIC_INFORMATION {
    HANDLE hActCtx;
    DWORD  dwFlags;
} ACTIVATION_CONTEXT_BASIC_INFORMATION;

#define ACTIVATION_CONTEXT_BASIC_INFORMATION_DEFINED 1

#endif
#endif

#ifndef QUERY_ACTCTX_FLAG_ACTCTX_IS_ADDRESS
#define QUERY_ACTCTX_FLAG_ACTCTX_IS_ADDRESS (0x00000010)
#endif
#ifndef QUERY_ACTCTX_FLAG_NO_ADDREF
#define QUERY_ACTCTX_FLAG_NO_ADDREF         (0x80000000)
#endif

/* This is actually an enum in WinNT.h */
#define ActivationContextBasicInformation 1

/* ---------------- End Compatibility ----------------- */

STATIC
FARPROC K32_GetProcAddress(LPCSTR lpFuncName)
{
    static HMODULE hModK32;

    /* We can use GetModuelHandle, rather than LoadLibrary here, as
     * we know Kernel32 is loaded */
    if(!hModK32) {
        hModK32 = GetModuleHandleA("Kernel32");
        if(!hModK32) {
            return NULL;
        }
    }

    return GetProcAddress(hModK32, lpFuncName);
}

STATIC
BOOL WINAPI MyQueryActCtxW(DWORD dwFlags, HANDLE hActCtx,
                           PVOID pvSubInstance, ULONG ulInfoClass,
                           PVOID pvBuffer, SIZE_T cbBuffer,
                           SIZE_T *pcbWrittenOrRequired)
{
    typedef BOOL (WINAPI* PFN)(DWORD dwFlags, HANDLE hActCtx,
                               PVOID pvSubInstance, ULONG ulInfoClass,
                               PVOID pvBuffer, SIZE_T cbBuffer,
                               SIZE_T *pcbWrittenOrRequired);
    static PFN s_pfn;
    if (s_pfn == NULL)
    {
        s_pfn = (PFN)K32_GetProcAddress("QueryActCtxW");
        if (s_pfn == NULL)
            return FALSE;
    }
    return s_pfn(dwFlags, hActCtx, pvSubInstance, ulInfoClass,
                   pvBuffer, cbBuffer, pcbWrittenOrRequired);
}

STATIC
BOOL WINAPI MyActivateActCtx(HANDLE hActCtx, ULONG_PTR *lpCookie)
{
    typedef BOOL (WINAPI* PFN)(HANDLE hActCtx, ULONG_PTR *lpCookie);
    static PFN s_pfn;

    if (s_pfn == NULL) {
        s_pfn = (PFN)K32_GetProcAddress("ActivateActCtx");
        if (s_pfn == NULL) {
            return FALSE;
        }
    }
    return s_pfn(hActCtx, lpCookie);
}

STATIC
BOOL WINAPI MyDeactivateActCtx(DWORD dwFlags, ULONG_PTR ulCookie)
{
    typedef BOOL (WINAPI* PFN)(DWORD dwFlags, ULONG_PTR ulCookie);
    static PFN s_pfn;

    if (s_pfn == NULL) {
        s_pfn = (PFN)K32_GetProcAddress("DeactivateActCtx");
        if (s_pfn == NULL) {
            return FALSE;
        }
    }
    return s_pfn(dwFlags, ulCookie);
}

STATIC
FARPROC UXT_GetProcAddress(LPCSTR lpFuncName)
{
    static HMODULE hModUXT;

    if(!hModUXT) {
        hModUXT = LoadLibraryA("uxtheme");
        if(!hModUXT) {
            return NULL;
        }
    }

    return GetProcAddress(hModUXT, lpFuncName);
}

STATIC
BOOL MyIsThemeActive()
{
    typedef BOOL (WINAPI* PFN)();
    static PFN s_pfn;

    if (s_pfn == NULL) {
        s_pfn = (PFN)UXT_GetProcAddress("IsThemeActive");
        if (s_pfn == NULL) {
            return FALSE;
        }
    }
    return s_pfn();
}

STATIC
BOOL MyIsAppThemed()
{
    typedef BOOL (WINAPI* PFN)();
    static PFN s_pfn;

    if (s_pfn == NULL) {
        s_pfn = (PFN)UXT_GetProcAddress("IsAppThemed");
        if (s_pfn == NULL) {
            return FALSE;
        }
    }
    return s_pfn();
}

STATIC
BOOL MySetThemeAppProperties(DWORD dwFlags)
{
    typedef void (WINAPI* PFN)(DWORD dwFlags);
    static PFN s_pfn;

    if (s_pfn == NULL) {
        s_pfn = (PFN)UXT_GetProcAddress("SetThemeAppProperties");
        if (s_pfn == NULL) {
            return FALSE;
        }
    }
    s_pfn(dwFlags);
    return TRUE;
}

STATIC
DWORD MyGetThemeAppProperties()
{
    typedef DWORD (WINAPI* PFN)();
    static PFN s_pfn;

    if (s_pfn == NULL) {
        s_pfn = (PFN)UXT_GetProcAddress("GetThemeAppProperties");
        if (s_pfn == NULL) {
            return 0;
        }
    }
    return s_pfn();
}

BOOL CALLBACK ChildThemeChanged(HWND hwnd, LPARAM lParam)
{
    SendMessageA(hwnd, WM_THEMECHANGED, 0, 0); /* XXX: Use PostMessage? */
    return TRUE;
}

BOOL CALLBACK TopLevelThemeChanged(HWND hwnd, LPARAM lParam)
{
    DWORD wtid, wpid;

    wtid = GetWindowThreadProcessId(hwnd, &wpid);

    if((DWORD)lParam == wpid) {
        SendMessageA(hwnd, WM_THEMECHANGED, 0, 0); /* XXX: Use PostMessage? */
        EnumChildWindows(hwnd, ChildThemeChanged, 0);

        /* It appears that sending a WM_THEMECHANGED message isn't
         * enough to get the windows to redraw in all cases, so
         * force it
         */
        RedrawWindow(hwnd, NULL, NULL, RDW_FRAME | RDW_INVALIDATE |
                                       RDW_ALLCHILDREN | RDW_UPDATENOW);
    }

    return TRUE;
}

/* Send a WM_THEMECHANGED message to every window belonging to
 * the current process
 */
void SendThemeChangedMessage()
{
    DWORD pid = GetCurrentProcessId();
    EnumWindows(TopLevelThemeChanged, (LPARAM)pid);
    return;
}

/* Determine if a V6 context is currently active using one of the following
 * methods:
 * (1) LoadLibrary("Comctl32"), GetProcAddress("DllGetVersion")
 *     as per http://msdn.microsoft.com/en-us/library/bb776779(VS.85).aspx
 * (2) Search the activation context using FindActCxtSectionString.
 * (3) Use GetClassInfo to get the associated module handle for a
 *     redirected class (e.g. Button).  If a V6 context is loaded it will
 *     be the same module handle as Comctl32, else it will same module
 *     handle as User32.
 *
 * 1 seems easiest and least prone to error, so use that until it is
 * shown not to work.
 */
BOOL
_v6_context_active()
{
    HINSTANCE hinstDll = LoadLibraryA("Comctl32");
    
    if(hinstDll) {
        DLLGETVERSIONPROC pDllGetVersion;
        pDllGetVersion = (DLLGETVERSIONPROC)GetProcAddress(hinstDll, 
                          "DllGetVersion");

        /* Because older system DLLs might not implement this function,
         * we assume that if it's not present we're earlier than v6
         */
        if(pDllGetVersion) {
            DLLVERSIONINFO dvi;

            ZeroMemory(&dvi, sizeof(dvi));
            dvi.cbSize = sizeof(dvi);

            if(SUCCEEDED((*pDllGetVersion)(&dvi)) && dvi.dwMajorVersion > 5) {
                return TRUE;
            }
        }
        FreeLibrary(hinstDll);
    }
    return FALSE;
}

MODULE = Win32::VisualStyles        PACKAGE = Win32::VisualStyles

PROTOTYPES: ENABLE

void
_SetActivationContext()
PREINIT:
    ACTIVATION_CONTEXT_BASIC_INFORMATION actCtxBasicInfo;
    ULONG_PTR cookie;
PPCODE:
    /* Check is the current activation context uses v6 Comctl32.dll.
     * If so then we're done.
     */
    if(_v6_context_active()) {
        XSRETURN_NO;
    }

    /* Attempt to retrieve the context from this dll.
     * This relies on the presence of a manifest in
     * the resource table of this dll with ID=2
     * (ISOLATION_AWARE_MANIFEST_ID) - when this
     * library is loaded the OS creates an activation
     * context from the manifest and stores it (but
     * doesn't activate it).
     * See WinBase.h and WinBase.Inl for details.
     */
    if (!MyQueryActCtxW(
          QUERY_ACTCTX_FLAG_ACTCTX_IS_ADDRESS |
          QUERY_ACTCTX_FLAG_NO_ADDREF,          /* Undocumented */
          MyQueryActCtxW,
          NULL,
          ActivationContextBasicInformation,    /* Undocumented */
          &actCtxBasicInfo,
          sizeof(actCtxBasicInfo),
          NULL
      ))
    {
        XSRETURN_NO;
    }

    if (actCtxBasicInfo.hActCtx == NULL) {
        XSRETURN_NO;
    }

    /* Activate the retrieved context */
    if(!MyActivateActCtx(actCtxBasicInfo.hActCtx, &cookie)) {
        XSRETURN_NO;
    }

    /* Need to ensure that the v6 Comctl32 dll is loaded */
    if(!LoadLibraryA("Comctl32")) {
        MyDeactivateActCtx(0, cookie); /* Fail back to process context */
        XSRETURN_NO;
    }

    XSRETURN_YES;

void
SetThemeAppProperties(dwFlags)
    DWORD dwFlags
PPCODE:
    if(MySetThemeAppProperties(dwFlags)) {
        SendThemeChangedMessage();
    }
    XSRETURN_YES;

DWORD
GetThemeAppProperties()
CODE:
    RETVAL = MyGetThemeAppProperties();
OUTPUT:
    RETVAL

BOOL
IsAppThemed()
CODE:
    RETVAL = MyIsAppThemed();
OUTPUT:
    RETVAL

BOOL
IsThemeActive()
CODE:
    RETVAL = MyIsThemeActive();
OUTPUT:
    RETVAL

BOOL
_v6_context_active()
