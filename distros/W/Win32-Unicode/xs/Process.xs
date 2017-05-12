#define PERL_NO_GET_CONTEXT
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "ppport.h"

#include <windows.h>

MODULE = Win32::Unicode::Process  PACKAGE = Win32::Unicode::Process

PROTOTYPES: DISABLE

long
wait_for_single_object(HANDLE handle)
    CODE:
        RETVAL = WaitForSingleObject(handle, INFINITE);
    OUTPUT:
        RETVAL

long
wait_for_input_idle(HANDLE handle)
    CODE:
        RETVAL = WaitForInputIdle(handle, INFINITE);
    OUTPUT:
        RETVAL

void
create_process(WCHAR *shell, WCHAR* cmd)
    CODE:
        STARTUPINFOW        si;
        PROCESS_INFORMATION pi;
        HV* hv    = newHV();
        SV* hvref = sv_2mortal(newRV_noinc((SV *)hv));

        ZeroMemory(&si,sizeof(si));
        si.cb=sizeof(si);

        if (CreateProcessW(
            shell,
            cmd,
            NULL,
            NULL,
            FALSE,
            NORMAL_PRIORITY_CLASS,
            NULL,
            NULL,
            &si,
            &pi
        ) == 0) {
            XSRETURN_EMPTY;
        }

        hv_stores(hv, "thread_handle", newSViv((long)pi.hThread));
        hv_stores(hv, "process_handle", newSViv((long)pi.hProcess));

        ST(0) = hvref;
        XSRETURN(1);

bool
get_exit_code(HANDLE handle)
    CODE:
        DWORD exit_code;
        if (GetExitCodeProcess(handle, &exit_code) == 0) {
            XSRETURN_EMPTY;
        }
        RETVAL = exit_code;
    OUTPUT:
        RETVAL
