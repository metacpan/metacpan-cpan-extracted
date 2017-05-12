#define PERL_NO_GET_CONTEXT
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "ppport.h"

#include <windows.h>
#define BUFF_SIZE 1024

MODULE = Win32::Unicode::Error  PACKAGE = Win32::Unicode::Error

PROTOTYPES: DISABLE

DWORD
get_last_error()
    CODE:
        RETVAL = GetLastError();
    OUTPUT:
        RETVAL

DWORD
set_last_error(long error_code)
    CODE:
        SetLastError(error_code);
        RETVAL = error_code;
    OUTPUT:
        RETVAL

SV*
foramt_message()
    CODE:
        WCHAR buff[BUFF_SIZE];

        FormatMessageW(
            FORMAT_MESSAGE_FROM_SYSTEM | FORMAT_MESSAGE_IGNORE_INSERTS,
            NULL,
            GetLastError(),
            LANG_USER_DEFAULT,
            buff,
            BUFF_SIZE,
            NULL
        );

        RETVAL = newSVpvn(buff, wcslen(buff) * sizeof(WCHAR));
     OUTPUT:
        RETVAL
