#define PERL_NO_GET_CONTEXT
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include <libversion/version.h>

MODULE = Version::libversion::XS    PACKAGE = Version::libversion::XS   PREFIX = lib_

PROTOTYPES: DISABLE

BOOT:
{
    HV *stash;

    stash = gv_stashpv("Version::libversion::XS", TRUE);

    newCONSTSUB(stash, "VERSIONFLAG_P_IS_PATCH", newSViv(VERSIONFLAG_P_IS_PATCH));
    newCONSTSUB(stash, "VERSIONFLAG_ANY_IS_PATCH", newSViv(VERSIONFLAG_ANY_IS_PATCH));
    newCONSTSUB(stash, "VERSIONFLAG_LOWER_BOUND", newSViv(VERSIONFLAG_LOWER_BOUND));
    newCONSTSUB(stash, "VERSIONFLAG_UPPER_BOUND", newSViv(VERSIONFLAG_UPPER_BOUND));

    newCONSTSUB(stash, "LIBVERSION_VERSION", newSVpvs(LIBVERSION_VERSION));

    newCONSTSUB(stash, "P_IS_PATCH", newSViv(VERSIONFLAG_P_IS_PATCH));
    newCONSTSUB(stash, "ANY_IS_PATCH", newSViv(VERSIONFLAG_ANY_IS_PATCH));
    newCONSTSUB(stash, "LOWER_BOUND", newSViv(VERSIONFLAG_LOWER_BOUND));
    newCONSTSUB(stash, "UPPER_BOUND", newSViv(VERSIONFLAG_UPPER_BOUND));
}

int
lib_version_compare(v1, v2, ...)
    const char *v1
    const char *v2
    PREINIT:
        int v1_flags = 0;
        int v2_flags = 0;
    CODE:
    {
        if( items > 2 ) {
            v1_flags = SvNV(ST(2));
            v2_flags = SvNV(ST(3));
        }
        RETVAL = version_compare4(v1, v2, v1_flags, v2_flags);
    }
    OUTPUT:
        RETVAL

int
lib_version_compare2(v1, v2)
    const char *v1
    const char *v2
    CODE:
        RETVAL = version_compare2(v1, v2);
    OUTPUT:
        RETVAL

int
lib_version_compare4(v1, v2, v1_flags, v2_flags)
    const char *v1
    const char *v2
    int v1_flags
    int v2_flags
    CODE:
        RETVAL = version_compare4(v1, v2, v1_flags, v2_flags);
    OUTPUT:
        RETVAL
