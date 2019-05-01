#define PERL_NO_GET_CONTEXT
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include <unistd.h>

MODULE = Unix::Pledge		PACKAGE = Unix::Pledge		

void
pledge(promises, ...)
    const char *promises
PROTOTYPE: $;$
INIT:
    const char *execpromises = NULL;
    if (items == 2) {
        execpromises = (const char *)SvPV_nolen(ST(1));
    }
CODE:
    if (pledge(promises, execpromises) == -1) {
        croak("unable to pledge: %s", strerror(errno));
    }

void
unveil(...)
PROTOTYPE: ;$$
INIT:
    const char *path = NULL;
    const char *permissions = NULL;
    if (items == 2) {
        path = (const char *)SvPV_nolen(ST(0));
        permissions = (const char *)SvPV_nolen(ST(1));
    }
CODE:
    if (unveil(path, permissions) == -1) {
        croak("unable to unveil: %s", strerror(errno));
    }
