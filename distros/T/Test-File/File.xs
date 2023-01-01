/* Bare copy of a part of Win32.xs */
#define WIN32_LEAN_AND_MEAN
#define _WIN32_WINNT 0x0500
#include <windows.h>

#define PERL_NO_GET_CONTEXT
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#define GETPROC(fn) pfn##fn = (PFN##fn)GetProcAddress(module, #fn)

typedef LONG (WINAPI *PFNRegGetValueA)(HKEY, LPCSTR, LPCSTR, DWORD, LPDWORD, PVOID, LPDWORD);

/* Use explicit struct definition because wSuiteMask and
 * wProductType are not defined in the VC++ 6.0 headers.
 * WORD type has been replaced by unsigned short because
 * WORD is already used by Perl itself.
 */
struct g_osver_t {
    DWORD dwOSVersionInfoSize;
    DWORD dwMajorVersion;
    DWORD dwMinorVersion;
    DWORD dwBuildNumber;
    DWORD dwPlatformId;
    CHAR  szCSDVersion[128];
    unsigned short wServicePackMajor;
    unsigned short wServicePackMinor;
    unsigned short wSuiteMask;
    BYTE  wProductType;
    BYTE  wReserved;
} g_osver = {0, 0, 0, 0, 0, "", 0, 0, 0, 0, 0};
BOOL g_osver_ex = TRUE;

XS(w32_GetOSVersion)
{
    dXSARGS;
    if (items)
	Perl_croak(aTHX_ "usage: Win32::GetOSVersion()");

    if (GIMME_V == G_SCALAR) {
        XSRETURN_IV(g_osver.dwPlatformId);
    }
    XPUSHs(sv_2mortal(newSVpvn(g_osver.szCSDVersion, strlen(g_osver.szCSDVersion))));

    XPUSHs(sv_2mortal(newSViv(g_osver.dwMajorVersion)));
    XPUSHs(sv_2mortal(newSViv(g_osver.dwMinorVersion)));
    XPUSHs(sv_2mortal(newSViv(g_osver.dwBuildNumber)));
    XPUSHs(sv_2mortal(newSViv(g_osver.dwPlatformId)));
    if (g_osver_ex) {
        XPUSHs(sv_2mortal(newSViv(g_osver.wServicePackMajor)));
        XPUSHs(sv_2mortal(newSViv(g_osver.wServicePackMinor)));
        XPUSHs(sv_2mortal(newSViv(g_osver.wSuiteMask)));
        XPUSHs(sv_2mortal(newSViv(g_osver.wProductType)));
    }
    PUTBACK;
}

XS(w32_GetProcessPrivileges)
{
    dXSARGS;
    BOOL ret;
    HV *priv_hv;
    HANDLE proc_handle, token;
    char *priv_name = NULL;
    TOKEN_PRIVILEGES *privs = NULL;
    DWORD i, pid, priv_name_len = 100, privs_len = 300;

    if (items > 1)
        Perl_croak(aTHX_ "usage: Win32::GetProcessPrivileges([$pid])");

    if (items == 0) {
        EXTEND(SP, 1);
        pid = GetCurrentProcessId();
    }
    else {
        pid = (DWORD)SvUV(ST(0));
    }

    proc_handle = OpenProcess(PROCESS_QUERY_INFORMATION, FALSE, pid);

    if (!proc_handle)
        XSRETURN_NO;

    ret = OpenProcessToken(proc_handle, TOKEN_QUERY, &token);
    CloseHandle(proc_handle);

    if (!ret)
        XSRETURN_NO;

    do {
        Renewc(privs, privs_len, char, TOKEN_PRIVILEGES);
        ret = GetTokenInformation(
            token, TokenPrivileges, privs, privs_len, &privs_len
        );
    } while (!ret && GetLastError() == ERROR_INSUFFICIENT_BUFFER);

    CloseHandle(token);

    if (!ret) {
        Safefree(privs);
        XSRETURN_NO;
    }

    priv_hv = newHV();
    New(0, priv_name, priv_name_len, char);

    for (i = 0; i < privs->PrivilegeCount; ++i) {
        DWORD ret_len = 0;
        LUID_AND_ATTRIBUTES *priv = &privs->Privileges[i];
        BOOL is_enabled = !!(priv->Attributes & SE_PRIVILEGE_ENABLED);

        if (priv->Attributes & SE_PRIVILEGE_REMOVED)
            continue;

        do {
            ret_len = priv_name_len;
            ret = LookupPrivilegeNameA(
                NULL, &priv->Luid, priv_name, &ret_len
            );

            if (ret_len > priv_name_len) {
                priv_name_len = ret_len + 1;
                Renew(priv_name, priv_name_len, char);
            }
        } while (!ret && GetLastError() == ERROR_INSUFFICIENT_BUFFER);

        if (!ret) {
            SvREFCNT_dec((SV*)priv_hv);
            Safefree(privs);
            Safefree(priv_name);
            XSRETURN_NO;
        }

        hv_store(priv_hv, priv_name, ret_len, newSViv(is_enabled), 0);
    }

    Safefree(privs);
    Safefree(priv_name);

    ST(0) = sv_2mortal(newRV_noinc((SV*)priv_hv));
    XSRETURN(1);
}

XS(w32_IsDeveloperModeEnabled)
{
    dXSARGS;
    LONG status;
    DWORD val, val_size = sizeof(val);
    PFNRegGetValueA pfnRegGetValueA;
    HMODULE module;

    if (items)
        Perl_croak(aTHX_ "usage: Win32::IsDeveloperModeEnabled()");

    EXTEND(SP, 1);

    /* developer mode was introduced in Windows 10 */
    if (g_osver.dwMajorVersion < 10)
        XSRETURN_NO;

    module = GetModuleHandleA("advapi32.dll");
    GETPROC(RegGetValueA);
    if (!pfnRegGetValueA)
        XSRETURN_NO;

    status = pfnRegGetValueA(
        HKEY_LOCAL_MACHINE,
        "SOFTWARE\\Microsoft\\Windows\\CurrentVersion\\AppModelUnlock",
        "AllowDevelopmentWithoutDevLicense",
        RRF_RT_REG_DWORD | KEY_WOW64_64KEY,
        NULL,
        &val,
        &val_size
    );

    if (status == ERROR_SUCCESS && val == 1)
        XSRETURN_YES;

    XSRETURN_NO;
}

MODULE = Test::File            PACKAGE = Test::File::Win32

PROTOTYPES: DISABLE

BOOT:
{
    const char *file = __FILE__;

    if (g_osver.dwOSVersionInfoSize == 0) {
        g_osver.dwOSVersionInfoSize = sizeof(g_osver);
        if (!GetVersionExA((OSVERSIONINFOA*)&g_osver)) {
            g_osver_ex = FALSE;
            g_osver.dwOSVersionInfoSize = sizeof(OSVERSIONINFOA);
            GetVersionExA((OSVERSIONINFOA*)&g_osver);
        }
    }

    newXS("Test::File::Win32::GetOSVersion", w32_GetOSVersion, file);
    newXS("Test::File::Win32::GetProcessPrivileges", w32_GetProcessPrivileges, file);
    newXS("Test::File::Win32::IsDeveloperModeEnabled", w32_IsDeveloperModeEnabled, file);
    XSRETURN_YES;
}
