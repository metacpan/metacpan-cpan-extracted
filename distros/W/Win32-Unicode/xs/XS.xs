#define PERL_NO_GET_CONTEXT
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "ppport.h"

#define WIN32_UNICODE_CALL_BOOT(name) STMT_START {  \
            EXTERN_C XS(CAT2(boot_, name));         \
            PUSHMARK(SP);                           \
            CALL_FPTR(CAT2(boot_, name))(aTHX_ cv); \
        } STMT_END

MODULE = Win32::Unicode

BOOT:
    WIN32_UNICODE_CALL_BOOT(Win32__Unicode__Dir);
    WIN32_UNICODE_CALL_BOOT(Win32__Unicode__File);
    WIN32_UNICODE_CALL_BOOT(Win32__Unicode__Error);
    WIN32_UNICODE_CALL_BOOT(Win32__Unicode__Console);
    WIN32_UNICODE_CALL_BOOT(Win32__Unicode__Process);
    WIN32_UNICODE_CALL_BOOT(Win32__Unicode__Native);
    WIN32_UNICODE_CALL_BOOT(Win32__Unicode__Util);

