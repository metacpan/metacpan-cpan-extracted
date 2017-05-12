#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

XS(boot_Win32__ShellExt)
{
    dXSARGS;
    char *file = __FILE__;

    XSRETURN_YES;
}
