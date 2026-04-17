#define PERL_NO_GET_CONTEXT
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include <errno.h>

#if defined(__linux__)
#  include <sys/prctl.h>
#  ifdef PR_SET_CHILD_SUBREAPER
#    define HARNESS_HAVE_SUBREAPER 1
#  endif
#endif

#ifndef HARNESS_HAVE_SUBREAPER
#  define HARNESS_HAVE_SUBREAPER 0
#endif

MODULE = Test2::Harness2::ChildSubReaper   PACKAGE = Test2::Harness2::ChildSubReaper

int
have_subreaper_support()
    CODE:
        RETVAL = HARNESS_HAVE_SUBREAPER;
    OUTPUT:
        RETVAL

int
set_child_subreaper(on)
    int on
    CODE:
#if HARNESS_HAVE_SUBREAPER
        RETVAL = (prctl(PR_SET_CHILD_SUBREAPER, on ? 1 : 0, 0, 0, 0) == 0) ? 1 : 0;
#else
        PERL_UNUSED_VAR(on);
        errno = ENOSYS;
        RETVAL = 0;
#endif
    OUTPUT:
        RETVAL
