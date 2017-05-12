#define PERL_NO_GET_CONTEXT
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "ppport.h"

#include <windows.h>
#include <shellapi.h>

MODULE = Win32::Unicode::Native  PACKAGE = Win32::Unicode::Native

PROTOTYPES: DISABLE

void
parse_argv()
    CODE:
        int argc;
        int i;
        LPWSTR *argv = CommandLineToArgvW(GetCommandLineW(), &argc);
        AV* av    = newAV();
        SV* avref = sv_2mortal(newRV_noinc((SV *)av));

        for (i = 0; i < argc; i++) {
            av_push(av, newSVpvn((char *)argv[i], wcslen(argv[i]) * sizeof(WCHAR)));
        }
        LocalFree(argv);

        ST(0) = avref;
        XSRETURN(1);
