#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include <windows.h>

#include "ppport.h"

MODULE = Win32::PerfCounter		PACKAGE = Win32::PerfCounter

void
frequency()
    INIT:
        LARGE_INTEGER lpFrequency;

    PPCODE:
        if (QueryPerformanceFrequency(&lpFrequency) != 0) {
            EXTEND(SP, 2);
            PUSHs(sv_2mortal(newSVnv(lpFrequency.HighPart)));
            PUSHs(sv_2mortal(newSVnv(lpFrequency.LowPart)));
        }

void
counter()
    INIT:
        LARGE_INTEGER lpFrequency;

    PPCODE:
        if (QueryPerformanceCounter(&lpFrequency) != 0) {
            EXTEND(SP, 2);
            PUSHs(sv_2mortal(newSVnv(lpFrequency.HighPart)));
            PUSHs(sv_2mortal(newSVnv(lpFrequency.LowPart)));
        }
