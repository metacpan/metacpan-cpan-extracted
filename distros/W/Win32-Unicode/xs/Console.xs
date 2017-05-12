#define PERL_NO_GET_CONTEXT
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "ppport.h"

#include <windows.h>

MODULE = Win32::Unicode::Console    PACKAGE = Win32::Unicode::Console

PROTOTYPES: DISABLE

HANDLE
get_std_handle(DWORD std_handle)
    CODE:
        RETVAL = GetStdHandle(std_handle);
    OUTPUT:
        RETVAL

bool
write_console(HANDLE handle, WCHAR *buff)
    CODE:
        DWORD write_size;

        RETVAL = WriteConsoleW(handle, buff, wcslen(buff), &write_size, NULL);
    OUTPUT:
        RETVAL

bool
is_console(HANDLE handle)
    CODE:
        CONSOLE_SCREEN_BUFFER_INFO info;

        RETVAL = GetConsoleScreenBufferInfo(handle, &info);
    OUTPUT:
        RETVAL
