#define PERL_NO_GET_CONTEXT
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "subreaper_impl.h"

MODULE = Test2::Harness2::ChildSubReaper   PACKAGE = Test2::Harness2::ChildSubReaper

int
have_subreaper_support()
    CODE:
        RETVAL = H2_SUBREAPER_HAVE;
    OUTPUT:
        RETVAL

SV *
subreaper_mechanism()
    CODE:
#if H2_SUBREAPER_HAVE
        RETVAL = newSVpv(H2_SUBREAPER_MECHANISM, 0);
#else
        RETVAL = newSV(0); /* fresh undef */
#endif
    OUTPUT:
        RETVAL

int
set_child_subreaper(on)
    int on
    CODE:
        RETVAL = h2_subreaper_set(on);
    OUTPUT:
        RETVAL
