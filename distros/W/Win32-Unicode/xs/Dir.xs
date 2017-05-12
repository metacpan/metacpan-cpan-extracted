#define PERL_NO_GET_CONTEXT
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "ppport.h"

#include <windows.h>

MODULE = Win32::Unicode::Dir    PACKAGE  = Win32::Unicode::Dir

PROTOTYPES: DISABLE

bool
create_directory(WCHAR *dirname)
    CODE:
        RETVAL = CreateDirectoryW(dirname, NULL);
    OUTPUT:
        RETVAL

SV*
get_current_directory()
    CODE:
        WCHAR cur[MAX_PATH];

        GetCurrentDirectoryW(sizeof(cur), cur);
        RETVAL = newSVpvn((char *)cur, wcslen(cur) * sizeof(WCHAR));
    OUTPUT:
        RETVAL

bool
set_current_directory(WCHAR *dirname)
    CODE:
        RETVAL = SetCurrentDirectoryW(dirname);
    OUTPUT:
        RETVAL

bool
remove_directory(WCHAR *dirname)
    CODE:
        RETVAL = RemoveDirectoryW(dirname);
    OUTPUT:
        RETVAL

void
find_first_file(SV* self, WCHAR *dirname)
    CODE:
        WIN32_FIND_DATAW info;

        HANDLE handle = FindFirstFileW(dirname, &info);
        HV* hv = (HV*)SvRV(self);
        hv_stores(hv, "handle", newSVuv((DWORD)handle));
        hv_stores(hv, "first", newSVpvn(info.cFileName, wcslen(info.cFileName) * sizeof(WCHAR)));

SV*
find_next_file(SV* self)
    CODE:
        WIN32_FIND_DATAW info;

        HV* hv = (HV*)SvRV(self);
        HANDLE handle = (HANDLE)SvUVx(*hv_fetchs(hv, "handle", 1));

        if(FindNextFileW(handle, &info) == 0) {
            XSRETURN_EMPTY;
        }

        RETVAL = newSVpvn((char *)info.cFileName, wcslen(info.cFileName) * sizeof(WCHAR));
    OUTPUT:
        RETVAL

bool
find_close(SV* self)
    CODE:
        HV* hv = (HV*)SvRV(self);
        HANDLE handle = (HANDLE)SvUVx(*hv_fetchs(hv, "handle", 1));
        RETVAL = FindClose(handle);
    OUTPUT:
        RETVAL
